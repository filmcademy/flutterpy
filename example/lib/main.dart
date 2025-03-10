import 'package:flutter/material.dart';
import 'package:flutterpy/flutterpy.dart';
import 'dart:convert';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Python
  try {
    final result = await initializePython();
    print('Python initialized: $result');
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
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _initializePython() async {
    setState(() {
      _isInitializing = true;
      _output = 'Initializing Python $_pythonVersion...';
    });

    try {
      final result = await initializePython(
        pythonVersion: _pythonVersion,
        forceDownload: _forceDownload,
      );
      
      final libPath = await getPythonLibraryPath();
      setState(() {
        _isInitialized = result;
        _isInitializing = false;
        _output = 'Python initialized: $result';
        if (libPath != null) {
          _output += '\nPython library path: $libPath';
        }
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
      final result = await "".py(code);
      setState(() {
        // Only show the result, not the execution log
        if (result != null) {
          if (result is Map || result is List) {
            // Use JsonEncoder for pretty printing complex objects
            final encoder = JsonEncoder.withIndent('  ');
            _output = encoder.convert(result);
          } else {
            _output = result.toString();
          }
        } else {
          _output = 'null';
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
      _output = 'Installing package: $packageName';
    });

    try {
      await "".pyInstall(packageName);
      setState(() {
        _output = 'Package $packageName installed successfully.';
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