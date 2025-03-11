import 'package:flutter/material.dart';
import 'package:flutterpy/flutterpy.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterPy Python File Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PythonFileExample(),
    );
  }
}

class PythonFileExample extends StatefulWidget {
  const PythonFileExample({Key? key}) : super(key: key);

  @override
  State<PythonFileExample> createState() => _PythonFileExampleState();
}

class _PythonFileExampleState extends State<PythonFileExample> {
  bool _isInitialized = false;
  bool _isLoading = false;
  String _output = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializePython();
  }

  Future<void> _initializePython() async {
    setState(() {
      _isLoading = true;
      _output = 'Initializing Python...';
    });

    try {
      final initialized = await initializePython();
      setState(() {
        _isInitialized = initialized;
        _output += '\nPython initialized: $initialized';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize Python: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runPythonFile() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'Python is not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Running Python file...';
      _error = '';
    });

    try {
      // Get the path to the main.py file
      final mainPyPath = path.join(Directory.current.path, 'main.py');
      
      // Execute the Python file and call the hello_from_python function
      final result = await this.pyFile(mainPyPath, functionName: 'hello_from_python');
      
      setState(() {
        _output = 'Python file executed successfully!\nResult: $result';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to run Python file: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _installRequirements() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'Python is not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Installing requirements...';
      _error = '';
    });

    try {
      // Get the path to the requirements.txt file
      final requirementsPath = path.join(Directory.current.path, 'requirements.txt');
      
      // Install the requirements
      await this.pyInstallRequirements(requirementsPath);
      
      setState(() {
        _output = 'Requirements installed successfully!';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to install requirements: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _callAddNumbers() async {
    if (!_isInitialized) {
      setState(() {
        _error = 'Python is not initialized';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _output = 'Calling add_numbers function...';
      _error = '';
    });

    try {
      // Get the path to the main.py file
      final mainPyPath = path.join(Directory.current.path, 'main.py');
      
      // Call the add_numbers function with arguments
      final result = await this.pyFile(mainPyPath, functionName: 'add_numbers', args: [5, 7]);
      
      setState(() {
        _output = 'Function called successfully!\n5 + 7 = $result';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to call function: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterPy Python File Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _runPythonFile,
              child: const Text('Run Python File'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _installRequirements,
              child: const Text('Install Requirements'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _callAddNumbers,
              child: const Text('Call add_numbers(5, 7)'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Output:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_output),
                      if (_error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Error:',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 