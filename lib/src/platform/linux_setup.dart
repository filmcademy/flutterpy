import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:flutterpy/flutterpy.dart';

/// Utility class for setting up Python on Linux
class LinuxPythonSetup {
  static bool _pythonInitialized = false;
  static String? _pythonPath;
  static String? _embeddedPythonPath;
  static bool _usingEmbeddedPython = false;

  /// Check if the app has the required permissions for Python
  static Future<bool> hasRequiredPermissions() async {
    // For Linux, we'll assume permissions are available
    return true;
  }
  
  /// Get the path to the Python dynamic library
  static Future<String?> getPythonLibraryPath() async {
    try {
      // If we're using embedded Python, return its library path
      if (_usingEmbeddedPython && _embeddedPythonPath != null) {
        final libPath = path.join(_embeddedPythonPath!, 'lib', 'libpython3.so');
        if (await File(libPath).exists()) {
          return libPath;
        }
        
        // Try version-specific libraries
        final possibleEmbeddedLibs = [
          path.join(_embeddedPythonPath!, 'lib', 'libpython3.11.so'),
          path.join(_embeddedPythonPath!, 'lib', 'libpython3.10.so'),
          path.join(_embeddedPythonPath!, 'lib', 'libpython3.9.so'),
          path.join(_embeddedPythonPath!, 'lib', 'libpython3.8.so'),
        ];
        
        for (final libPath in possibleEmbeddedLibs) {
          if (await File(libPath).exists()) {
            return libPath;
          }
        }
      }
      
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
    // If we're using embedded Python, return its executable path
    if (_usingEmbeddedPython && _embeddedPythonPath != null) {
      final pythonExe = path.join(_embeddedPythonPath!, 'bin', 'python3');
      if (await File(pythonExe).exists()) {
        return pythonExe;
      }
    }
    
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
  
  /// Set up Python environment for Linux
  static Future<bool> setupPython({bool force = false, String? customEnvPath}) async {
    try {
      if (_pythonInitialized && !force) {
        print('Python already initialized, skipping setup');
        return true;
      }
      
      print('Setting up Python for Linux...');
      
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
      
      // Try to find system Python first
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
      
      // If Python is not found, download and set up embedded Python
      print('Python not found. Setting up embedded Python...');
      final success = await _downloadAndSetupEmbeddedPython();
      if (success) {
        _pythonInitialized = true;
        _usingEmbeddedPython = true;
        return true;
      }
      
      print('Failed to set up embedded Python. Please install Python 3.8 or later manually.');
      return false;
    } catch (e) {
      print('Error setting up Python: $e');
      return false;
    }
  }
  
  /// Download and set up embedded Python
  static Future<bool> _downloadAndSetupEmbeddedPython() async {
    try {
      // Create app support directory if it doesn't exist
      final appSupportDir = await _getAppSupportDirectory();
      final directory = Directory(appSupportDir);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // Get Python version - default to 3.10 if not specified
      const pythonVersion = '3.10';
      final downloadUrl = _getPythonDownloadUrl(pythonVersion);
      
      print('Downloading Python $pythonVersion from $downloadUrl');
      
      // Download Python
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        print('Failed to download Python: ${response.statusCode}');
        return false;
      }
      
      // Save the downloaded file
      final downloadPath = path.join(appSupportDir, 'python-$pythonVersion.tar.gz');
      await File(downloadPath).writeAsBytes(response.bodyBytes);
      print('Downloaded Python to $downloadPath');
      
      // Extract the archive
      final pythonDir = path.join(appSupportDir, 'python');
      final pythonDirObj = Directory(pythonDir);
      if (await pythonDirObj.exists()) {
        await pythonDirObj.delete(recursive: true);
      }
      await pythonDirObj.create();
      
      print('Extracting Python to $pythonDir');
      
      // Read the tar.gz file
      final bytes = await File(downloadPath).readAsBytes();
      final archive = TarDecoder().decodeBytes(GZipDecoder().decodeBytes(bytes));
      
      // Extract the contents
      for (final file in archive) {
        final filePath = path.join(pythonDir, file.name);
        if (file.isFile) {
          final fileData = file.content as List<int>;
          await File(filePath).create(recursive: true);
          await File(filePath).writeAsBytes(fileData);
          
          // Make executable files executable
          if (file.name.contains('/bin/')) {
            await Process.run('chmod', ['+x', filePath]);
          }
        } else {
          await Directory(filePath).create(recursive: true);
        }
      }
      
      // Clean up the downloaded file
      await File(downloadPath).delete();
      
      // Set the embedded Python path
      _embeddedPythonPath = pythonDir;
      
      // Verify the installation
      final pythonExe = path.join(pythonDir, 'bin', 'python3');
      if (await File(pythonExe).exists()) {
        // Make sure it's executable
        await Process.run('chmod', ['+x', pythonExe]);
        
        // Test the Python installation
        final result = await Process.run(pythonExe, ['--version']);
        if (result.exitCode == 0) {
          print('Embedded Python installed successfully: ${result.stdout}');
          
          // Install pip if needed
          await _ensurePipIsInstalled(pythonExe);
          
          return true;
        }
      }
      
      print('Failed to verify embedded Python installation');
      return false;
    } catch (e) {
      print('Error setting up embedded Python: $e');
      return false;
    }
  }
  
  /// Get the Python download URL for Linux
  static String _getPythonDownloadUrl(String pythonVersion) {
    // For Linux, we'll use a portable Python build
    return 'https://github.com/indygreg/python-build-standalone/releases/download/20230116/cpython-$pythonVersion.0-x86_64-unknown-linux-gnu-install_only.tar.gz';
  }
  
  /// Ensure pip is installed
  static Future<bool> _ensurePipIsInstalled(String pythonExe) async {
    try {
      // Check if pip is already installed
      final pipResult = await Process.run(pythonExe, ['-m', 'pip', '--version']);
      if (pipResult.exitCode == 0) {
        print('pip is already installed: ${pipResult.stdout}');
        return true;
      }
      
      // Install pip
      print('Installing pip...');
      final getpipUrl = 'https://bootstrap.pypa.io/get-pip.py';
      final response = await http.get(Uri.parse(getpipUrl));
      if (response.statusCode != 200) {
        print('Failed to download get-pip.py: ${response.statusCode}');
        return false;
      }
      
      // Save get-pip.py
      final tempDir = await Directory.systemTemp.createTemp('flutterpy_');
      final getpipPath = path.join(tempDir.path, 'get-pip.py');
      await File(getpipPath).writeAsBytes(response.bodyBytes);
      
      // Run get-pip.py
      final installResult = await Process.run(pythonExe, [getpipPath]);
      
      // Clean up
      await tempDir.delete(recursive: true);
      
      if (installResult.exitCode == 0) {
        print('pip installed successfully');
        return true;
      } else {
        print('Failed to install pip: ${installResult.stderr}');
        return false;
      }
    } catch (e) {
      print('Error installing pip: $e');
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
      
      // Use pip module directly with the Python executable
      final result = await Process.run(pythonPath, ['-m', 'pip', 'install', packageName]);
      
      if (result.exitCode != 0) {
        throw Exception('Failed to install package: ${result.stderr}');
      }
      
      print('Package $packageName installed successfully');
    } catch (e) {
      print('Error installing package: $e');
      rethrow;
    }
  }
  
  /// Find system Python installation
  static Future<String?> _findSystemPython() async {
    try {
      // Try to find Python in the PATH
      final result = await Process.run('which', ['python3']);
      if (result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty) {
        return result.stdout.toString().trim();
      }
      
      // Try alternative Python commands
      final result2 = await Process.run('which', ['python']);
      if (result2.exitCode == 0 && result2.stdout.toString().trim().isNotEmpty) {
        return result2.stdout.toString().trim();
      }
      
      // Check common locations
      final commonLocations = [
        '/usr/bin/python3',
        '/usr/local/bin/python3',
        '/opt/python/bin/python3',
      ];
      
      for (final location in commonLocations) {
        if (await File(location).exists()) {
          return location;
        }
      }
    } catch (e) {
      print('Error finding system Python: $e');
    }
    return null;
  }
} 