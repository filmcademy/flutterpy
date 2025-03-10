library flutterpy;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

part 'src/python_function.dart';
part 'src/python_bridge.dart';
part 'src/python_types.dart';
part 'src/python_environment.dart';
/// Main extension on Object to provide Python functionality to any Dart class
extension FlutterPy on Object {
  /// Executes a Python function and returns the result
  /// 
  /// Example:
  /// ```dart
  /// final result = myObject.py('numpy.array([1, 2, 3])');
  /// ```
  Future<dynamic> py(String pythonCode) async {
    final bridge = PythonBridge.instance;
    await bridge.ensureInitialized();
    return bridge.executeCode(pythonCode);
  }
  
  /// Calls a Python function with arguments and returns the result
  /// 
  /// Example:
  /// ```dart
  /// final result = myObject.pyCall('numpy.mean', [1, 2, 3, 4]);
  /// ```
  Future<dynamic> pyCall(String functionName, List<dynamic> args) async {
    final bridge = PythonBridge.instance;
    await bridge.ensureInitialized();
    return bridge.callFunction(functionName, args);
  }
  
  /// Imports a Python module and makes it available for use
  /// 
  /// Example:
  /// ```dart
  /// await myObject.pyImport('numpy');
  /// final mean = await myObject.pyCall('numpy.mean', [1, 2, 3, 4]);
  /// ```
  Future<void> pyImport(String moduleName) async {
    final bridge = PythonBridge.instance;
    await bridge.ensureInitialized();
    await bridge.importModule(moduleName);
  }
  
  /// Installs a Python package using pip
  /// 
  /// Example:
  /// ```dart
  /// await myObject.pyInstall('numpy');
  /// ```
  Future<void> pyInstall(String packageName) async {
    final env = PythonEnvironment.instance;
    await env.ensureInitialized();
    await env.installPackage(packageName);
  }
}

/// Initializes the Python environment with specific configuration
/// 
/// [pythonVersion] - The Python version to use (e.g., '3.9', '3.10')
/// [forceDownload] - Whether to force download Python even if it's installed locally
/// 
/// Example:
/// ```dart
/// await initializePython(pythonVersion: '3.9', forceDownload: true);
/// ```
Future<void> initializePython({String? pythonVersion, bool forceDownload = false}) async {
  final env = PythonEnvironment.instance;
  await env.ensureInitialized(pythonVersion: pythonVersion, forceDownload: forceDownload);
}

/// Gets the path to the Python environment
String getPythonEnvPath() {
  final env = PythonEnvironment.instance;
  return env.envPath;
}

/// Annotation to mark a class as Python-enabled
class PyEnabled {
  const PyEnabled();
}

/// Annotation to mark a method as a Python function
class PyFunction {
  final String pythonCode;
  
  const PyFunction(this.pythonCode);
}

/// Annotation to mark a field as a Python variable
class PyVar {
  final String pythonExpression;
  
  const PyVar(this.pythonExpression);
} 