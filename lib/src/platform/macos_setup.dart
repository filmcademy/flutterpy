import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:flutterpy/flutterpy.dart';

/// Utility class for setting up Python on macOS
class MacOSPythonSetup {
  static bool _pythonInitialized = false;
  static String? _pythonPath;

  /// Check if the app has the required entitlements for Python
  static Future<bool> hasRequiredEntitlements() async {
    // Since we're always running outside sandbox, return true
    return true;
  }
  
  /// Get the path to the Python dynamic library
  static Future<String?> getPythonLibraryPath() async {
    try {
      // For non-sandboxed environments, we can just check common system locations
      final pythonPath = await _getPythonExecutablePath();
      if (pythonPath == null) return null;
      
      // Try to infer the library path from the executable path
      final pythonDir = path.dirname(pythonPath);
      final possibleLibPaths = [
        path.join(pythonDir, '..', 'lib', 'libpython3.11.dylib'),
        path.join(pythonDir, '..', 'lib', 'libpython3.10.dylib'),
        path.join(pythonDir, '..', 'lib', 'libpython3.9.dylib'),
        '/usr/local/lib/libpython3.11.dylib',
        '/usr/local/lib/libpython3.10.dylib',
        '/usr/local/lib/libpython3.9.dylib',
        '/opt/homebrew/lib/libpython3.11.dylib',
        '/opt/homebrew/lib/libpython3.10.dylib',
        '/opt/homebrew/lib/libpython3.9.dylib',
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
  
  /// Set up Python environment for macOS
  static Future<bool> setupPython({bool force = false, String? customEnvPath}) async {
    try {
      if (_pythonInitialized && !force) {
        print('Python already initialized, skipping setup');
        return true;
      }
      
      print('Setting up Python for macOS...');
      
      // If a custom environment path is provided, use it
      if (customEnvPath != null) {
        // Initialize the Python environment with the custom path
        final env = PythonEnvironment.instance;
        await env.ensureInitialized(
          forceDownload: force,
          customEnvPath: customEnvPath,
        );
        
        // Get the Python path from the environment
        _pythonPath = env.pythonPath;
        print('Using custom Python environment at $customEnvPath');
        _pythonInitialized = true;
        return true;
      }
      
      // For non-sandboxed environments, we only need to find system Python
      final pythonPath = await _findSystemPython();
      if (pythonPath != null) {
        _pythonPath = pythonPath;
        print('Found system Python at $_pythonPath');
        
        // Check Python version
        final versionResult = await Process.run(pythonPath, ['--version']);
        if (versionResult.exitCode == 0) {
          print('System Python version: ${versionResult.stdout}${versionResult.stderr}');
          
          // Check if pip is available
          final pipResult = await Process.run(pythonPath, ['-m', 'pip', '--version']);
          print('Pip check result: ${pipResult.exitCode}');
          print('Pip version: ${pipResult.stdout}${pipResult.stderr}');
          
          _pythonInitialized = true;
          return true;
        }
      }
      
      print('Could not find system Python, please install Python 3.9+');
      return false;
    } catch (e) {
      print('Error setting up Python: $e');
      return false;
    }
  }
  
  /// Clean up temporary files safely
  static Future<void> _cleanupTempDir(Directory tempDir) async {
    try {
      // Check if the directory exists before trying to delete it
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      print('Warning: Failed to delete temporary directory: $e');
    }
  }
  
  /// Execute Python code and return the result
  static Future<dynamic> executePythonCode(String code) async {
    // Ensure Python is initialized
    if (!_pythonInitialized) {
      print('Python not initialized, attempting setup');
      final success = await setupPython();
      if (!success) {
        return "Error: Python is not properly set up";
      }
    }
    
    // Create a temporary directory
    late Directory tempDir;
    try {
      tempDir = await Directory.systemTemp.createTemp('flutterpy_');
    } catch (e) {
      print('Error creating temporary directory: $e');
      return "Error: Could not create temporary directory";
    }
    
    final scriptFile = File(path.join(tempDir.path, 'script.py'));
    
    // Prepare the Python script with code to execute
    final scriptContent = '''
#!/usr/bin/env python3
import json
import sys
import traceback
import os

try:
    result = $code
    if result is not None:
        # Handle basic types for JSON serialization
        if hasattr(result, 'tolist'):  # For numpy arrays
            result = result.tolist()
        print(json.dumps({"result": result}))
    else:
        print(json.dumps({"result": None}))
except Exception as e:
    error_type = type(e).__name__
    error_msg = str(e)
    error_traceback = traceback.format_exc()
    print(json.dumps({
        "error": {
            "type": error_type,
            "message": error_msg,
            "traceback": error_traceback
        }
    }))
''';
    
    try {
      await scriptFile.writeAsString(scriptContent);
      await Process.run('chmod', ['+x', scriptFile.path]);
      
      // Execute the Python script
      if (_pythonPath == null) {
        _pythonPath = await _findSystemPython();
        if (_pythonPath == null) {
          await _cleanupTempDir(tempDir);
          return "Error: Could not find Python interpreter";
        }
      }
      
      print('Using Python at: $_pythonPath');
      print('Executing code: $code');
      
      final result = await Process.run(_pythonPath!, [scriptFile.path]);
      
      if (result.exitCode != 0) {
        print('Python execution failed: ${result.stderr}');
        await _cleanupTempDir(tempDir);
        return "Error: ${result.stderr}";
      }
      
      // Parse the output
      final output = result.stdout.toString().trim();
      print('Python output: $output');
      
      if (output.isEmpty) {
        await _cleanupTempDir(tempDir);
        return null;
      }
      
      // Find the JSON object in the output
      final jsonStart = output.lastIndexOf('{');
      final jsonEnd = output.lastIndexOf('}');
      
      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonString = output.substring(jsonStart, jsonEnd + 1);
        try {
          final jsonResult = json.decode(jsonString);
          
          // Check for errors
          if (jsonResult.containsKey('error')) {
            final error = jsonResult['error'];
            throw Exception('Python error: ${error['type']}: ${error['message']}');
          }
          
          await _cleanupTempDir(tempDir);
          return jsonResult['result'];
        } catch (e) {
          print('Failed to parse JSON: $e');
          print('JSON string was: $jsonString');
        }
      }
      
      // If no JSON found, just return the raw output
      await _cleanupTempDir(tempDir);
      return output;
    } catch (e) {
      print('Error executing Python code: $e');
      await _cleanupTempDir(tempDir);
      return "Error: $e";
    }
  }
  
  /// Find system Python in standard locations
  static Future<String?> _findSystemPython() async {
    try {
      // Use 'which' command to find Python
      final result = await Process.run('which', ['python3']);
      if (result.exitCode == 0) {
        final systemPythonPath = result.stdout.toString().trim();
        if (systemPythonPath.isNotEmpty) {
          return systemPythonPath;
        }
      }
      
      // If 'which' fails, check common locations
      final commonLocations = [
        '/usr/bin/python3',
        '/usr/local/bin/python3',
        '/opt/homebrew/bin/python3',
        '/opt/homebrew/bin/python3.11',
        '/opt/homebrew/bin/python3.10',
        '/opt/homebrew/bin/python3.9',
      ];
      
      for (final location in commonLocations) {
        if (await File(location).exists()) {
          return location;
        }
      }
      
      return null;
    } catch (e) {
      print('Error finding system Python: $e');
      return null;
    }
  }
  
  /// Get the path to the Python executable
  static Future<String?> _getPythonExecutablePath() async {
    if (_pythonPath != null) {
      return _pythonPath;
    }
    return _findSystemPython();
  }
  
  /// Install a Python package
  static Future<void> installPackage(String packageName) async {
    // Ensure Python is initialized
    if (!_pythonInitialized) {
      final success = await setupPython();
      if (!success) {
        throw Exception('Python is not properly set up');
      }
    }
    
    if (_pythonPath == null) {
      throw Exception('Python executable not found');
    }
    
    final pipArgs = ['-m', 'pip', 'install', packageName];
    
    try {
      // Install the package
      final result = await Process.run(_pythonPath!, pipArgs);
      
      if (result.exitCode != 0) {
        throw Exception('Failed to install package $packageName: ${result.stderr}');
      }
      
      print('Successfully installed package $packageName');
    } catch (e) {
      print('Error installing Python package: $e');
      rethrow;
    }
  }
  
  /// Generate instructions for setting up entitlements
  static String getEntitlementsInstructions() {
    return '''
To use Python in your macOS app outside the sandbox:

1. Make sure your app's entitlements are set to:
   - com.apple.security.app-sandbox: false
   - com.apple.security.cs.allow-jit: true (for JIT compilation)
   - com.apple.security.network.client: true (if you need network access)
   - com.apple.security.network.server: true (if you need to start a server)

2. You'll need to make sure Python 3.9+ is installed on the user's system
   - `brew install python@3.11` is recommended

Note: Running outside the sandbox means your app won't be acceptable on the Mac App Store.
''';
  }
  
  /// Instructions for setting up Python in a macOS app
  static String getMacOSSetupInstructions() {
    return '''
To set up Python in your non-sandboxed macOS app:

1. Make sure your entitlements are properly set up:
   - Set com.apple.security.app-sandbox to false

2. Initialize Python in your Flutter app:
   ```dart
   import 'package:flutterpy/flutterpy.dart';
   
   void main() async {
     await initializePython();
     runApp(MyApp());
   }
   ```

3. Make sure to inform your users that they need to have Python 3.9+ installed:
   - `brew install python@3.11` is recommended
''';
  }
} 