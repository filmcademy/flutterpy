// A simple command-line example of FlutterPy

import 'dart:io';
import 'package:flutterpy/flutterpy.dart';

void main() async {
  print('FlutterPy Command-Line Example');
  print('------------------------------');
  
  try {
    // Initialize the Python environment
    print('Initializing Python environment...');
    final env = PythonEnvironment.instance;
    await env.ensureInitialized();
    print('Python environment initialized successfully.');
    
    // Basic Python execution
    print('\nRunning basic Python code:');
    final result = await "".py('1 + 1');
    print('1 + 1 = $result');
    
    // Install and import NumPy
    print('\nInstalling NumPy...');
    await "".pyInstall('numpy');
    print('NumPy installed successfully.');
    
    print('\nImporting NumPy...');
    await "".pyImport('numpy');
    print('NumPy imported successfully.');
    
    // Use NumPy
    print('\nUsing NumPy:');
    final npResult = await "".py('''
import numpy as np
arr = np.array([1, 2, 3, 4, 5])
return {
  'array': arr.tolist(),
  'mean': np.mean(arr),
  'std': np.std(arr),
  'min': np.min(arr),
  'max': np.max(arr)
}
''');
    
    print('Array: ${npResult['array']}');
    print('Mean: ${npResult['mean']}');
    print('Standard Deviation: ${npResult['std']}');
    print('Min: ${npResult['min']}');
    print('Max: ${npResult['max']}');
    
    // Interactive mode
    print('\nEntering interactive mode. Type Python code or "exit" to quit.');
    while (true) {
      stdout.write('>>> ');
      final input = stdin.readLineSync();
      
      if (input == null || input.toLowerCase() == 'exit') {
        break;
      }
      
      try {
        final result = await "".py(input);
        print(result);
      } catch (e) {
        print('Error: $e');
      }
    }
    
    print('\nExiting FlutterPy example.');
  } catch (e) {
    print('Error: $e');
  }
} 