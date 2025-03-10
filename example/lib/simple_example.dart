import 'package:flutter/material.dart';
import 'package:flutterpy/flutterpy.dart';

void main() {
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
  String _output = 'Press the button to initialize Python';
  bool _isLoading = false;

  Future<void> _initializePython() async {
    setState(() {
      _isLoading = true;
      _output = 'Initializing Python...';
    });

    try {
      await initializePython();
      setState(() {
        _output = 'Python initialized successfully!';
      });
      
      // Try a simple Python calculation
      final result = await "".py('1 + 1');
      setState(() {
        _output += '\n\nPython calculation: 1 + 1 = $result';
      });
    } catch (e) {
      setState(() {
        _output = 'Error initializing Python: $e';
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
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'FlutterPy Simple Example',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _output,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _initializePython,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Initialize Python'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 