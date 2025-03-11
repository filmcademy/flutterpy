library flutterpy;

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

import 'src/platform/platform.dart';

export 'src/platform/platform.dart';

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
    // Use the platform adapter for executing Python code
    final platformSetup = getPlatformSetup();
    try {
      return await platformSetup.executePythonCode(pythonCode);
    } catch (e) {
      print('Error executing Python code: $e');
      rethrow;
    }
  }
  
  /// Calls a Python function with arguments and returns the result
  /// 
  /// Example:
  /// ```dart
  /// final result = myObject.pyCall('numpy.mean', [1, 2, 3, 4]);
  /// ```
  Future<dynamic> pyCall(String functionName, List<dynamic> args) async {
    // Convert arguments to Python code
    final pythonArgs = args.map(_convertToPythonLiteral).join(', ');
    
    // Create the Python code to execute
    final pythonCode = '$functionName($pythonArgs)';
    
    return py(pythonCode);
  }
  
  /// Loads and executes a Python file
  /// 
  /// Example:
  /// ```dart
  /// final result = await myObject.pyFile('/path/to/script.py', functionName: 'my_function', args: [1, 2, 3]);
  /// ```
  Future<dynamic> pyFile(String filePath, {String? functionName, List<dynamic>? args}) async {
    final bridge = PythonBridge.instance;
    await bridge.ensureInitialized();
    return bridge.loadPythonFile(filePath, functionName: functionName, args: args);
  }
  
  /// Imports a Python module and makes it available for use
  /// 
  /// Example:
  /// ```dart
  /// await myObject.pyImport('numpy');
  /// final mean = await myObject.pyCall('numpy.mean', [1, 2, 3, 4]);
  /// ```
  Future<void> pyImport(String moduleName) async {
    // Import the module using py()
    await py('import $moduleName');
  }
  
  /// Installs a Python package using pip
  /// 
  /// Example:
  /// ```dart
  /// await myObject.pyInstall('numpy');
  /// ```
  Future<void> pyInstall(String packageName) async {
    // Use the platform adapter for installing packages
    final platformSetup = getPlatformSetup();
    try {
      await platformSetup.installPackage(packageName);
    } catch (e) {
      print('Error installing Python package: $e');
      rethrow;
    }
  }
  
  /// Installs Python packages from a requirements.txt file
  /// 
  /// Example:
  /// ```dart
  /// await myObject.pyInstallRequirements('/path/to/requirements.txt');
  /// ```
  Future<void> pyInstallRequirements(String requirementsFilePath) async {
    final bridge = PythonBridge.instance;
    await bridge.ensureInitialized();
    
    // Check if the file exists
    final file = File(requirementsFilePath);
    if (!await file.exists()) {
      throw FileSystemException('Requirements file not found', requirementsFilePath);
    }
    
    // Use pip to install packages from the requirements file
    final env = PythonEnvironment.instance;
    final result = await env.executePythonScript('''
import subprocess
import sys

try:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', '$requirementsFilePath'])
    print('{"result": "success"}')
except Exception as e:
    print('{"error": {"type": "InstallError", "message": str(e), "traceback": ""}}')
''');
    
    if (result.exitCode != 0) {
      throw Exception('Failed to install requirements: ${result.stderr}');
    }
    
    final output = result.stdout.toString().trim();
    if (output.contains('"error"')) {
      final jsonResult = json.decode(output);
      final error = jsonResult['error'];
      throw Exception('Failed to install requirements: ${error['message']}');
    }
  }
  
  /// Converts a Dart value to a Python literal
  String _convertToPythonLiteral(dynamic value) {
    if (value == null) {
      return 'None';
    } else if (value is bool) {
      return value ? 'True' : 'False';
    } else if (value is num) {
      return value.toString();
    } else if (value is String) {
      return "'${value.replaceAll("'", "\\'")}'";
    } else if (value is List) {
      final elements = value.map(_convertToPythonLiteral).join(', ');
      return '[$elements]';
    } else if (value is Map) {
      final entries = value.entries.map((e) => 
        '${_convertToPythonLiteral(e.key)}: ${_convertToPythonLiteral(e.value)}'
      ).join(', ');
      return '{$entries}';
    } else {
      return value.toString();
    }
  }
}

/// Initialize Python for the current platform
Future<bool> initializePython({
  String? pythonVersion,
  bool forceDownload = false,
  Map<String, String>? environmentVariables,
  String? customEnvPath,
}) async {
  final platformSetup = getPlatformSetup();
  return platformSetup.initialize(
    pythonVersion: pythonVersion,
    forceDownload: forceDownload,
    environmentVariables: environmentVariables,
    customEnvPath: customEnvPath,
  );
}

/// Dispose Python resources
Future<void> disposePython() async {
  final platformSetup = getPlatformSetup();
  return platformSetup.dispose();
}

/// Get the path to the Python library
Future<String?> getPythonLibraryPath() async {
  final platformSetup = getPlatformSetup();
  return platformSetup.getPythonLibraryPath();
}

/// Check if Python is properly set up
Future<bool> isPythonSetup() async {
  final platformSetup = getPlatformSetup();
  return platformSetup.isPythonSetup();
}

/// Get platform-specific setup instructions
String getPlatformSetupInstructions() {
  return getPlatformInstructions();
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