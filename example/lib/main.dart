import 'package:flutter/material.dart';
import 'package:flutterpy/flutterpy.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get the support directory path for the custom virtual environment
  final appSupportDir = await getApplicationSupportDirectory();
  final customEnvPath = path.join(appSupportDir.path, 'python_venv');
  
  // Initialize Python with the custom environment path
  try {
    final result = await initializePython(
      customEnvPath: customEnvPath,
      forceDownload: false,
    );
    print('Python initialized: $result');
    print('Python environment path: $customEnvPath');
  } catch (e) {
    print('Failed to initialize Python: $e');
  }
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterPy Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FlutterPy Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isInitializing = false;
  bool _isInitialized = false;
  String _pythonVersion = '3.10';
  bool _forceDownload = false;
  String _output = '';
  String? _customEnvPath;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCustomEnvPath();
  }

  Future<void> _initCustomEnvPath() async {
    final appSupportDir = await getApplicationSupportDirectory();
    setState(() {
      _customEnvPath = path.join(appSupportDir.path, 'python_venv');
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initializePython() async {
    if (_customEnvPath == null) {
      await _initCustomEnvPath();
    }
    
    setState(() {
      _isInitializing = true;
      _output = 'Initializing Python $_pythonVersion in custom environment at $_customEnvPath...';
    });

    try {
      final result = await initializePython(
        pythonVersion: _pythonVersion,
        forceDownload: _forceDownload,
        customEnvPath: _customEnvPath,
      );
      
      final libPath = await getPythonLibraryPath();
      setState(() {
        _isInitialized = result;
        _isInitializing = false;
        _output = 'Python initialized: $result';
        if (libPath != null) {
          _output += '\nPython library path: $libPath';
        }
        _output += '\nPython environment path: $_customEnvPath';
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _output = 'Error: $e';
      });
    }
  }

  Future<void> _executeCode() async {
    if (!_isInitialized) {
      setState(() {
        _output = 'Please initialize Python first.';
      });
      return;
    }

    final code = _codeController.text;
    if (code.isEmpty) {
      setState(() {
        _output = 'Please enter some Python code.';
      });
      return;
    }

    try {
      // First, try to install numpy if needed
      if (code.contains('import numpy') || code.contains('import np')) {
        try {
          await _installPackage('numpy');
          print('NumPy installed successfully');
        } catch (e) {
          print('Error installing NumPy: $e');
        }
      }
      
      // Create a temporary file with the user's code
      final tempDir = await Directory.systemTemp.createTemp('flutter_py_');
      final userCodeFile = File('${tempDir.path}/user_code.py');
      await userCodeFile.writeAsString(code);
      
      // Get the absolute path to the user's code file
      final userCodePath = userCodeFile.path.replaceAll('\\', '\\\\');
      
      // Execute the code using Python's execfile equivalent
      String output = '';
      dynamic result;
      
      try {
        // Step 1: Create a simple script to execute the file and capture output
        final execScript = '''
import sys
from io import StringIO
import traceback

# Function to execute a file and return the output and last expression value
def run_file(file_path):
    # Capture stdout
    old_stdout = sys.stdout
    captured_output = StringIO()
    sys.stdout = captured_output
    
    try:
        # Create a namespace to capture variables
        namespace = {}
        
        # Execute the file in the namespace
        with open(file_path, 'r') as f:
            code = f.read()
        exec(code, namespace)
        
        # Get the output
        output = captured_output.getvalue()
        
        # Try to find a result - use the last defined variable
        result = None
        for var_name in list(namespace.keys()):
            if not var_name.startswith('__'):
                result = namespace[var_name]
        
        # Handle numpy arrays
        if result is not None and hasattr(result, 'tolist'):
            result = result.tolist()
            
        return {'success': True, 'output': output, 'result': result}
    except Exception as e:
        error_type = type(e).__name__
        error_msg = str(e)
        traceback_str = traceback.format_exc()
        return {
            'success': False, 
            'error': f"{error_type}: {error_msg}",
            'traceback': traceback_str,
            'output': captured_output.getvalue()
        }
    finally:
        # Restore stdout
        sys.stdout = old_stdout

# Run the file and print the result
result = run_file('$userCodePath')
print(result)
''';
        
        // Write the execution script to a file
        final execFile = File('${tempDir.path}/exec.py');
        await execFile.writeAsString(execScript);
        
        // Execute the script using a simple Python command
        // This avoids the evaluation issue by using a simple string
        final execResult = await "".py("exec(open('${execFile.path.replaceAll('\\', '\\\\')}').read())");
        
        // Parse the result
        if (execResult != null) {
          final resultStr = execResult.toString();
          
          // Try to extract a Python dictionary from the result
          final dictStart = resultStr.indexOf('{');
          final dictEnd = resultStr.lastIndexOf('}');
          
          if (dictStart >= 0 && dictEnd > dictStart) {
            final dictStr = resultStr.substring(dictStart, dictEnd + 1);
            
            try {
              // Replace Python True/False/None with JSON equivalents
              final jsonStr = dictStr
                  .replaceAll("'", '"')
                  .replaceAll('True', 'true')
                  .replaceAll('False', 'false')
                  .replaceAll('None', 'null');
              
              final resultMap = json.decode(jsonStr);
              
              if (resultMap['success'] == true) {
                output = resultMap['output'] ?? '';
                result = resultMap['result'];
              } else {
                // Handle error
                String errorOutput = 'Error: ${resultMap['error']}';
                if (resultMap.containsKey('traceback')) {
                  errorOutput += '\n\nTraceback:\n${resultMap['traceback']}';
                }
                if (resultMap.containsKey('output') && resultMap['output'].toString().isNotEmpty) {
                  errorOutput += '\n\nOutput:\n${resultMap['output']}';
                }
                setState(() {
                  _output = errorOutput;
                });
                return;
              }
            } catch (e) {
              print('Error parsing result: $e');
              setState(() {
                _output = 'Error parsing result: $e\nRaw output: $resultStr';
              });
              return;
            }
          } else {
            setState(() {
              _output = 'Raw output: $resultStr';
            });
            return;
          }
        }
      } catch (e) {
        setState(() {
          _output = 'Error executing Python code: $e';
        });
        return;
      } finally {
        // Clean up the temporary files
        try {
          await tempDir.delete(recursive: true);
        } catch (e) {
          print('Error cleaning up temporary files: $e');
        }
      }
      
      // Update the UI with the result
      setState(() {
        if (output.isNotEmpty && result != null) {
          _output = 'Output:\n$output\n\nResult:\n$result';
        } else if (output.isNotEmpty) {
          _output = output;
        } else if (result != null) {
          if (result is Map || result is List) {
            final encoder = JsonEncoder.withIndent('  ');
            _output = encoder.convert(result);
          } else {
            _output = result.toString();
          }
        } else {
          _output = 'Code executed successfully with no output';
        }
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    }
  }

  Future<void> _installPackage(String packageName) async {
    if (!_isInitialized) {
      setState(() {
        _output = 'Please initialize Python first.';
      });
      return;
    }

    setState(() {
      _output = 'Installing package: $packageName in custom environment at $_customEnvPath';
    });

    try {
      await "".pyInstall(packageName);
      setState(() {
        _output = 'Package $packageName installed successfully in $_customEnvPath.';
      });
    } catch (e) {
      setState(() {
        _output = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Python Environment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Python Version',
                              border: OutlineInputBorder(),
                            ),
                            value: _pythonVersion,
                            items: const [
                              DropdownMenuItem(
                                value: '3.8',
                                child: Text('Python 3.8'),
                              ),
                              DropdownMenuItem(
                                value: '3.9',
                                child: Text('Python 3.9'),
                              ),
                              DropdownMenuItem(
                                value: '3.10',
                                child: Text('Python 3.10'),
                              ),
                              DropdownMenuItem(
                                value: '3.11',
                                child: Text('Python 3.11'),
                              ),
                            ],
                            onChanged: _isInitializing
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _pythonVersion = value;
                                      });
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Force Download'),
                            value: _forceDownload,
                            onChanged: _isInitializing
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _forceDownload = value;
                                      });
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isInitializing ? null : _initializePython,
                      child: _isInitializing
                          ? const CircularProgressIndicator()
                          : const Text('Initialize Python'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execute Python Code',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Python Code',
                        hintText: 'import numpy as np\nnp.mean([1, 2, 3, 4, 5])',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInitialized ? _executeCode : null,
                            child: const Text('Execute'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInitialized
                                ? () => _installPackage('numpy')
                                : null,
                            child: const Text('Install NumPy'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInitialized
                                ? () => _installPackage('pandas')
                                : null,
                            child: const Text('Install Pandas'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_output),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 