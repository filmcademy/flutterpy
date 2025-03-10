// Example of using FlutterPy with code generation

import 'package:flutterpy/flutterpy.dart';

// In a real app, you would use build_runner to generate this file
// The following line would be uncommented after running build_runner
// part 'generated_example.g.dart';

// Mark the class with PyEnabled annotation
@PyEnabled()
class MyMathClass {
  // Define a method with Python implementation
  @PyFunction('return arg0 + arg1')
  Future<double> add(double a, double b) async {
    // This method would be implemented by the generated code
    // For now, we'll implement it manually for demonstration
    final pythonFunction = PythonFunction('return arg0 + arg1');
    return await pythonFunction.call([a, b]);
  }
  
  // Define another method with Python implementation
  @PyFunction('''
import numpy as np
return np.mean(arg0)
''')
  Future<double> calculateMean(List<double> numbers) async {
    // This method would be implemented by the generated code
    // For now, we'll implement it manually for demonstration
    final pythonFunction = PythonFunction('''
import numpy as np
return np.mean(arg0)
''');
    return await pythonFunction.call([numbers]);
  }
  
  // Define a variable with Python implementation
  @PyVar('np.array([1, 2, 3])')
  List<int> get defaultArray {
    // This getter would be implemented by the generated code
    // For now, we'll throw an error
    throw UnimplementedError('This would be implemented by code generation');
  }
}

void main() async {
  // Initialize Python
  await initializePython();
  
  try {
    // Create an instance of the class
    final math = MyMathClass();
    
    // Call the methods
    final sum = await math.add(2.5, 3.5);
    print('2.5 + 3.5 = $sum');
    
    final mean = await math.calculateMean([1, 2, 3, 4, 5]);
    print('Mean of [1, 2, 3, 4, 5] = $mean');
    
    // This would work if code generation was set up
    try {
      final array = math.defaultArray;
      print('Default array: $array');
    } catch (e) {
      print('Error getting default array: $e');
      print('This is expected because code generation is not set up.');
    }
  } catch (e) {
    print('Error: $e');
  }
  
  print('\nIn a real app with code generation, you would run:');
  print('flutter pub run build_runner build');
} 