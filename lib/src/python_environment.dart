part of flutterpy;

/// Manages the Python environment for the application
class PythonEnvironment {
  static PythonEnvironment? _instance;
  
  /// Get the singleton instance of the Python environment
  static PythonEnvironment get instance {
    _instance ??= PythonEnvironment._();
    return _instance!;
  }
  
  bool _initialized = false;
  late String _pythonPath;
  late String _envPath;
  late String _pipPath;
  String _pythonVersion = '3.10';
  
  PythonEnvironment._();
  
  /// Ensures that the Python environment is initialized
  /// 
  /// [pythonVersion] - The Python version to use (e.g., '3.9', '3.10')
  /// [forceDownload] - Whether to force download Python even if it's installed locally
  /// [customEnvPath] - Optional custom path for the virtual environment
  Future<void> ensureInitialized({
    String? pythonVersion, 
    bool forceDownload = false,
    String? customEnvPath,
  }) async {
    if (_initialized) return;
    
    if (pythonVersion != null) {
      _pythonVersion = pythonVersion;
    }
    
    await _setupPythonEnvironment(
      forceDownload: forceDownload,
      customEnvPath: customEnvPath,
    );
    _initialized = true;
  }
  
  /// Sets up the Python environment
  Future<void> _setupPythonEnvironment({
    bool forceDownload = false,
    String? customEnvPath,
  }) async {
    if (customEnvPath != null) {
      _envPath = customEnvPath;
    } else {
      final appDir = await _getAppDirectory();
      _envPath = path.join(appDir.path, 'python_env');
    }
    
    // Create the directory if it doesn't exist
    final envDir = Directory(_envPath);
    if (!await envDir.exists()) {
      await envDir.create(recursive: true);
    }
    
    // Check if Python environment already exists
    if (await _isPythonEnvironmentValid()) {
      print('Python environment already exists at $_envPath');
      await _setPythonPaths();
      return;
    }
    
    print('Creating Python environment at $_envPath');
    
    // Check if Python is installed on the system and we're not forcing download
    final pythonInstalled = !forceDownload && await _isPythonInstalled();
    
    if (pythonInstalled) {
      print('Using system Python to create virtual environment');
      // Create virtual environment using system Python
      await _createVirtualEnvironment();
    } else {
      print('Downloading Python $_pythonVersion');
      // Download and install Python
      await _downloadAndInstallPython();
      // Create virtual environment using downloaded Python
      await _createVirtualEnvironmentWithDownloadedPython();
    }
    
    // Set Python paths
    await _setPythonPaths();
    
    // Install base packages
    await _installBasePackages();
  }
  
  /// Checks if Python is installed on the system
  Future<bool> _isPythonInstalled() async {
    try {
      final result = await Process.run('python3', ['--version']);
      if (result.exitCode != 0) {
        final result2 = await Process.run('python', ['--version']);
        if (result2.exitCode != 0) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if the Python environment is valid
  Future<bool> _isPythonEnvironmentValid() async {
    final envDir = Directory(_envPath);
    if (!await envDir.exists()) return false;
    
    // Check for Python executable in the environment
    if (Platform.isWindows) {
      final pythonExe = File(path.join(_envPath, 'Scripts', 'python.exe'));
      return await pythonExe.exists();
    } else {
      final pythonExe = File(path.join(_envPath, 'bin', 'python'));
      return await pythonExe.exists();
    }
  }
  
  /// Downloads and installs Python
  Future<void> _downloadAndInstallPython() async {
    final pythonDir = path.join(_envPath, 'python');
    final pythonDirObj = Directory(pythonDir);
    if (!await pythonDirObj.exists()) {
      await pythonDirObj.create(recursive: true);
    }
    
    final downloadUrl = _getPythonDownloadUrl();
    final downloadPath = path.join(_envPath, 'python_installer');
    
    try {
      // Download Python installer
      print('Downloading Python from $downloadUrl');
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download Python: HTTP ${response.statusCode}');
      }
      
      // Save the installer
      final installerFile = File(downloadPath);
      await installerFile.writeAsBytes(response.bodyBytes);
      
      // Extract or install Python
      await _extractPython(downloadPath, pythonDir);
      
      // Clean up
      await installerFile.delete();
      
    } catch (e) {
      throw Exception('Failed to download and install Python: $e');
    }
  }
  
  /// Gets the Python download URL based on the platform and version
  String _getPythonDownloadUrl() {
    if (Platform.isWindows) {
      return 'https://www.python.org/ftp/python/$_pythonVersion.0/python-$_pythonVersion.0-embed-amd64.zip';
    } else if (Platform.isMacOS) {
      return 'https://www.python.org/ftp/python/$_pythonVersion.0/python-$_pythonVersion.0-macos11.pkg';
    } else if (Platform.isLinux) {
      // For Linux, we'll use a portable Python build
      return 'https://github.com/indygreg/python-build-standalone/releases/download/20230116/cpython-$_pythonVersion.0-x86_64-unknown-linux-gnu-install_only.tar.gz';
    } else {
      throw UnsupportedError('Unsupported platform for Python download');
    }
  }
  
  /// Extracts the Python installer
  Future<void> _extractPython(String installerPath, String targetDir) async {
    final file = File(installerPath);
    final bytes = await file.readAsBytes();
    
    if (installerPath.endsWith('.zip')) {
      // Extract ZIP archive
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outFile = File(path.join(targetDir, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(path.join(targetDir, filename)).create(recursive: true);
        }
      }
    } else if (installerPath.endsWith('.tar.gz')) {
      // Extract TAR.GZ archive
      final gzBytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(gzBytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final outFile = File(path.join(targetDir, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(path.join(targetDir, filename)).create(recursive: true);
        }
      }
    } else if (installerPath.endsWith('.pkg') && Platform.isMacOS) {
      // For macOS, we need to extract the pkg file
      // This is more complex and might require a different approach
      throw UnimplementedError('PKG extraction not implemented yet');
    } else {
      throw UnsupportedError('Unsupported installer format');
    }
    
    // Make Python executable
    if (!Platform.isWindows) {
      final pythonExe = path.join(targetDir, 'bin', 'python3');
      await Process.run('chmod', ['+x', pythonExe]);
    }
  }
  
  /// Creates a virtual environment using the system Python
  Future<void> _createVirtualEnvironment() async {
    try {
      // First try with python3
      var result = await Process.run('python3', ['-m', 'venv', _envPath]);
      if (result.exitCode != 0) {
        // Try with python if python3 fails
        result = await Process.run('python', ['-m', 'venv', _envPath]);
        if (result.exitCode != 0) {
          throw Exception('Failed to create virtual environment: ${result.stderr}');
        }
      }
      
      // Ensure pip is installed in the virtual environment
      await _ensurePipInVenv();
    } catch (e) {
      throw Exception('Failed to create virtual environment: $e');
    }
  }
  
  /// Creates a virtual environment using the downloaded Python
  Future<void> _createVirtualEnvironmentWithDownloadedPython() async {
    final pythonExe = Platform.isWindows 
        ? path.join(_envPath, 'python', 'python.exe')
        : path.join(_envPath, 'python', 'bin', 'python3');
    
    try {
      final result = await Process.run(pythonExe, ['-m', 'venv', _envPath]);
      if (result.exitCode != 0) {
        throw Exception('Failed to create virtual environment with downloaded Python: ${result.stderr}');
      }
      
      // Ensure pip is installed in the virtual environment
      await _ensurePipInVenv();
    } catch (e) {
      throw Exception('Failed to create virtual environment with downloaded Python: $e');
    }
  }
  
  /// Ensures pip is installed in the virtual environment
  Future<void> _ensurePipInVenv() async {
    try {
      // Set Python paths first so we can use the venv Python
      await _setPythonPaths();
      
      // Check if pip is available
      final checkResult = await Process.run(_pythonPath, ['-m', 'pip', '--version']);
      if (checkResult.exitCode == 0) {
        print('pip is already available in the virtual environment');
        return;
      }
      
      print('pip not found in virtual environment, installing it...');
      
      // Download get-pip.py
      final getpipUrl = 'https://bootstrap.pypa.io/get-pip.py';
      final response = await http.get(Uri.parse(getpipUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download get-pip.py: HTTP ${response.statusCode}');
      }
      
      // Save get-pip.py to a temporary file
      final tempDir = await Directory.systemTemp.createTemp('flutterpy_');
      final getpipPath = path.join(tempDir.path, 'get-pip.py');
      await File(getpipPath).writeAsBytes(response.bodyBytes);
      
      // Run get-pip.py with the virtual environment's Python
      final installResult = await Process.run(_pythonPath, [getpipPath]);
      
      // Clean up
      await tempDir.delete(recursive: true);
      
      if (installResult.exitCode != 0) {
        throw Exception('Failed to install pip: ${installResult.stderr}');
      }
      
      print('pip installed successfully in the virtual environment');
    } catch (e) {
      throw Exception('Failed to ensure pip in virtual environment: $e');
    }
  }
  
  /// Sets the Python paths
  Future<void> _setPythonPaths() async {
    if (Platform.isWindows) {
      _pythonPath = path.join(_envPath, 'Scripts', 'python.exe');
      _pipPath = path.join(_envPath, 'Scripts', 'pip.exe');
    } else {
      _pythonPath = path.join(_envPath, 'bin', 'python');
      _pipPath = path.join(_envPath, 'bin', 'pip');
    }
  }
  
  /// Installs base packages
  Future<void> _installBasePackages() async {
    // Upgrade pip first
    await _runPip(['install', '--upgrade', 'pip']);
    
    // Install base packages
    await installPackage('numpy');
    await installPackage('pandas');
  }
  
  /// Runs pip with the given arguments
  Future<void> _runPip(List<String> args) async {
    try {
      // First try using pip directly
      final result = await Process.run(_pipPath, args);
      if (result.exitCode != 0) {
        print('Direct pip execution failed, trying via Python module: ${result.stderr}');
        
        // If direct pip fails, try using python -m pip
        final modulePipResult = await Process.run(_pythonPath, ['-m', 'pip', ...args]);
        if (modulePipResult.exitCode != 0) {
          throw Exception('Pip command failed: ${modulePipResult.stderr}');
        }
      }
    } catch (e) {
      // If the first approach throws an exception (e.g., pip executable not found),
      // try using python -m pip
      try {
        print('Pip execution failed, trying via Python module: $e');
        final modulePipResult = await Process.run(_pythonPath, ['-m', 'pip', ...args]);
        if (modulePipResult.exitCode != 0) {
          throw Exception('Pip command failed: ${modulePipResult.stderr}');
        }
      } catch (e2) {
        throw Exception('Pip command failed with both methods: $e2');
      }
    }
  }
  
  /// Gets the application directory
  Future<Directory> _getAppDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile, use the application documents directory
      final appDocDir = await _getApplicationDocumentsDirectory();
      return appDocDir;
    } else {
      // For desktop, use the application support directory
      final appSupportDir = await _getApplicationSupportDirectory();
      return appSupportDir;
    }
  }
  
  /// Gets the application documents directory
  Future<Directory> _getApplicationDocumentsDirectory() async {
    // In a real implementation, we would use path_provider directly
    // For now, we'll use a simplified approach
    if (Platform.isAndroid) {
      return Directory('/data/data/com.example.app/app_flutter');
    } else if (Platform.isIOS) {
      return Directory(path.join(
        '/var/mobile/Containers/Data/Application',
        Platform.environment['APP_ID'] ?? '',
        'Documents',
      ));
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Gets the application support directory
  Future<Directory> _getApplicationSupportDirectory() async {
    // In a real implementation, we would use path_provider directly
    // For now, we'll use a simplified approach
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home == null) throw Exception('HOME environment variable not set');
      return Directory(path.join(home, 'Library', 'Application Support', 'flutterpy'));
    } else if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null) throw Exception('HOME environment variable not set');
      return Directory(path.join(home, '.local', 'share', 'flutterpy'));
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData == null) throw Exception('APPDATA environment variable not set');
      return Directory(path.join(appData, 'flutterpy'));
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
  
  /// Installs a Python package
  Future<void> installPackage(String packageName) async {
    try {
      print('Installing Python package: $packageName');
      await _runPip(['install', packageName]);
      print('Successfully installed Python package: $packageName');
    } catch (e) {
      throw Exception('Failed to install package $packageName: $e');
    }
  }
  
  /// Executes a Python script
  Future<ProcessResult> executePythonScript(String script) async {
    final tempFile = await _createTempPythonFile(script);
    try {
      return await Process.run(_pythonPath, [tempFile.path]);
    } finally {
      await tempFile.delete();
    }
  }
  
  /// Creates a temporary Python file
  Future<File> _createTempPythonFile(String content) async {
    final tempDir = await Directory.systemTemp.createTemp('flutterpy_');
    final file = File(path.join(tempDir.path, 'script.py'));
    await file.writeAsString(content);
    return file;
  }
  
  /// Gets the Python executable path
  String get pythonPath => _pythonPath;
  
  /// Gets the Python environment path
  String get envPath => _envPath;
}