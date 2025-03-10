import 'dart:io';
import 'package:args/args.dart';
import 'package:flutterpy/flutterpy.dart';

/// Main entry point for the FlutterPy CLI
Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('python-version', 
      abbr: 'v', 
      help: 'Python version to use (e.g., 3.9, 3.10)',
      defaultsTo: '3.10')
    ..addFlag('force-download', 
      abbr: 'f', 
      help: 'Force download Python even if installed locally',
      defaultsTo: false)
    ..addOption('output-dir', 
      abbr: 'o', 
      help: 'Output directory for the Python environment',
      defaultsTo: null)
    ..addFlag('help', 
      abbr: 'h', 
      help: 'Show this help message',
      negatable: false);

  try {
    final results = parser.parse(args);
    
    if (results['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }
    
    final pythonVersion = results['python-version'] as String;
    final forceDownload = results['force-download'] as bool;
    
    print('Initializing Python $pythonVersion environment...');
    print('Force download: $forceDownload');
    
    await initializePython(
      pythonVersion: pythonVersion,
      forceDownload: forceDownload,
    );
    
    final envPath = getPythonEnvPath();
    print('Python environment initialized at: $envPath');
    
  } catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }
}

/// Prints the usage information
void _printUsage(ArgParser parser) {
  print('FlutterPy CLI - Initialize Python environment');
  print('');
  print('Usage: flutterpy [options]');
  print('');
  print('Options:');
  print(parser.usage);
} 