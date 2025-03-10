import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Utility class for setting up Python on Linux
class LinuxPythonSetup {
  static bool _pythonInitialized = false;
  static String? _pythonPath;

  /// Check if the app has the required permissions for Python
  static Future<bool> hasRequiredPermissions() async {
    // For Linux, we'll assume permissions are available
    return true;
  }
  
  /// Get the path to the Python dynamic library
  static Future<String?> getPythonLibraryPath() async {
    try {
      // For Linux environments, we can check common system locations
      final pythonPath = await _getPythonExecutablePath();
      if (pythonPath == null) return null;
      
      // Try to infer the library path from the executable path
      final pythonDir = path.dirname(pythonPath);
      final possibleLibPaths = [
        // Common paths for system Python installations
        path.join(pythonDir, '..', 'lib', 'libpython3.11.so'),
        path.join(pythonDir, '..', 'lib', 'libpython3.10.so'),
        path.join(pythonDir, '..', 'lib', 'libpython3.9.so'),
        path.join(pythonDir, '..', 'lib', 'libpython3.8.so'),
        '/usr/lib/x86_64-linux-gnu/libpython3.11.so',
        '/usr/lib/x86_64-linux-gnu/libpython3.10.so',
        '/usr/lib/x86_64-linux-gnu/libpython3.9.so',
        '/usr/lib/x86_64-linux-gnu/libpython3.8.so',
        '/usr/lib/libpython3.11.so',
        '/usr/lib/libpython3.10.so',
        '/usr/lib/libpython3.9.so',
        '/usr/lib/libpython3.8.so',
        // For portable Python builds
        path.join(await _getAppSupportDirectory(), 'python', 'lib', 'libpython3.11.so'),
        path.join(await _getAppSupportDirectory(), 'python', 'lib', 'libpython3.10.so'),
        path.join(await _getAppSupportDirectory(), 'python', 'lib', 'libpython3.9.so'),
        path.join(await _getAppSupportDirectory(), 'python', 'lib', 'libpython3.8.so'),
      ];
      
      for (final libPath in possibleLibPaths) {
        if (await File(libPath).exists()) {
          print('Found Python library at $libPath');
          return libPath;
        }
      }
    } catch (e) {
      print('Error getting Python library path: $e');
    }
    return null;
  }
  
  /// Get the Python executable path
  static Future<String?> _getPythonExecutablePath() async {
    if (_pythonPath != null) return _pythonPath;
    
    try {
      // Try to find Python in the PATH
      final result = await Process.run('which', ['python3']);
      if (result.exitCode == 0) {
        _pythonPath = (result.stdout as String).trim();
        return _pythonPath;
      }
      
      // Check common locations
      final commonPaths = [
        '/usr/bin/python3',
        '/usr/local/bin/python3',
      ];
      
      for (final pythonPath in commonPaths) {
        if (await File(pythonPath).exists()) {
          _pythonPath = pythonPath;
          return _pythonPath;
        }
      }
      
      // Check for portable Python installation
      final portablePythonPath = path.join(
        await _getAppSupportDirectory(), 'python', 'bin', 'python3');
      if (await File(portablePythonPath).exists()) {
        _pythonPath = portablePythonPath;
        return _pythonPath;
      }
    } catch (e) {
      print('Error finding Python executable: $e');
    }
    return null;
  }
  
  /// Get the app support directory
  static Future<String> _getAppSupportDirectory() async {
    final home = Platform.environment['HOME'];
    if (home == null) throw Exception('HOME environment variable not set');
    return path.join(home, '.local', 'share', 'flutterpy');
  }
  
  /// Set up Python for Linux
  static Future<bool> setupPython({bool force = false}) async {
    if (_pythonInitialized && !force) return true;
    
    try {
      // Check if Python is already installed
      final pythonPath = await _getPythonExecutablePath();
      if (pythonPath != null) {
        print('Found Python at $pythonPath');
        _pythonInitialized = true;
        return true;
      }
      
      // If not found, we could download and install a portable Python
      // This would be similar to the macOS implementation but with Linux-specific paths
      print('Python not found. Consider installing Python 3.8 or later.');
      return false;
    } catch (e) {
      print('Error setting up Python: $e');
      return false;
    }
  }
  
  /// Execute Python code
  static Future<dynamic> executePythonCode(String code) async {
    if (!_pythonInitialized) {
      final initialized = await setupPython();
      if (!initialized) {
        throw Exception('Python is not initialized');
      }
    }
    
    try {
      final pythonPath = await _getPythonExecutablePath();
      if (pythonPath == null) {
        throw Exception('Python executable not found');
      }
      
      // Create a temporary file with the Python code
      final tempDir = await Directory.systemTemp.createTemp('flutterpy_');
      final tempFile = File(path.join(tempDir.path, 'code.py'));
      await tempFile.writeAsString('''
import json
import sys
try:
    result = eval("""$code""")
    print(json.dumps(result))
    sys.exit(0)
except Exception as e:
    try:
        exec("""$code""")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)
''');
      
      // Execute the Python code
      final result = await Process.run(pythonPath, [tempFile.path]);
      
      // Clean up
      await tempDir.delete(recursive: true);
      
      if (result.exitCode != 0) {
        throw Exception('Python execution failed: ${result.stderr}');
      }
      
      // Parse the output
      final output = (result.stdout as String).trim();
      if (output.isEmpty) return null;
      
      try {
        return jsonDecode(output);
      } catch (e) {
        return output;
      }
    } catch (e) {
      print('Error executing Python code: $e');
      rethrow;
    }
  }
  
  /// Install a Python package
  static Future<void> installPackage(String packageName) async {
    if (!_pythonInitialized) {
      final initialized = await setupPython();
      if (!initialized) {
        throw Exception('Python is not initialized');
      }
    }
    
    try {
      final pythonPath = await _getPythonExecutablePath();
      if (pythonPath == null) {
        throw Exception('Python executable not found');
      }
      
      final pipPath = path.join(path.dirname(pythonPath), 'pip3');
      
      // Check if pip exists
      if (!await File(pipPath).exists()) {
        // Try to find pip in common locations
        final result = await Process.run('which', ['pip3']);
        if (result.exitCode != 0) {
          throw Exception('pip3 not found');
        }
      }
      
      // Install the package
      final result = await Process.run(pipPath, ['install', packageName]);
      
      if (result.exitCode != 0) {
        throw Exception('Failed to install package: ${result.stderr}');
      }
      
      print('Package $packageName installed successfully');
    } catch (e) {
      print('Error installing package: $e');
      rethrow;
    }
  }
} 