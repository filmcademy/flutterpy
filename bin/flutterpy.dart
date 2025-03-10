#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Main entry point for the FlutterPy CLI
void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message')
    ..addFlag('setup-macos', negatable: false, help: 'Set up macOS platform configuration')
    ..addFlag('setup-windows', negatable: false, help: 'Set up Windows platform configuration')
    ..addFlag('setup-linux', negatable: false, help: 'Set up Linux platform configuration')
    ..addFlag('sandbox', negatable: true, defaultsTo: false, help: 'Use app sandbox (Mac App Store compatible)')
    ..addOption('output-dir', abbr: 'o', help: 'Output directory for platform configuration files')
    ..addOption('python-version', abbr: 'v', defaultsTo: '3.11', help: 'Python version to use');

  try {
    final results = parser.parse(args);
    
    if (results['help'] as bool) {
      _printUsage(parser);
      exit(0);
    }
    
    final outputDir = results['output-dir'] as String? ?? '.';
    final pythonVersion = results['python-version'] as String;
    final useSandbox = results['sandbox'] as bool;
    
    if (results['setup-macos'] as bool) {
      await _setupMacOS(outputDir, pythonVersion, useSandbox);
    } else if (results['setup-windows'] as bool) {
      print('Windows setup is not yet implemented.');
    } else if (results['setup-linux'] as bool) {
      await _setupLinux(outputDir, pythonVersion);
    } else {
      _printUsage(parser);
    }
  } catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }
}

/// Prints the usage information
void _printUsage(ArgParser parser) {
  print('flutterpy - Setup tool for FlutterPy package');
  print('');
  print('Usage: flutterpy [options]');
  print('');
  print(parser.usage);
}

Future<void> _setupMacOS(String outputDir, String pythonVersion, bool useSandbox) async {
  print('Setting up macOS platform configuration...');
  
  if (!useSandbox) {
    print('📝 Non-sandboxed mode selected. This setup will not work with Mac App Store distribution.');
  } else {
    print('📝 Sandboxed mode selected. This setup is compatible with Mac App Store distribution.');
    print('   Note: Sandboxed mode requires Python to be bundled with your app.');
  }
  
  // Get the package path
  final packagePath = _getPackagePath();
  if (packagePath == null) {
    print('Error: Could not find FlutterPy package.');
    exit(1);
  }
  
  // Create directories
  final macosDir = Directory(path.join(outputDir, 'macos'));
  if (!macosDir.existsSync()) {
    print('Error: macOS directory not found at ${macosDir.path}');
    print('Please run this command from your Flutter project root or specify the output directory.');
    exit(1);
  }
  
  final runnerDir = Directory(path.join(macosDir.path, 'Runner'));
  if (!runnerDir.existsSync()) {
    runnerDir.createSync();
  }
  
  // Step 1: Create the BaseConfig.xcconfig file for macOS deployment target
  final configsDir = Directory(path.join(runnerDir.path, 'Configs'));
  if (!configsDir.existsSync()) {
    configsDir.createSync();
  }
  
  final baseConfigPath = path.join(configsDir.path, 'BaseConfig.xcconfig');
  final baseConfigContent = '''
// Base configuration for all configurations
// Minimum macOS version
MACOSX_DEPLOYMENT_TARGET = 10.15
''';
  File(baseConfigPath).writeAsStringSync(baseConfigContent);
  print('✅ Created BaseConfig.xcconfig at $baseConfigPath');
  
  // Step 2: Update Debug.xcconfig and Release.xcconfig to include BaseConfig.xcconfig
  final debugConfigPath = path.join(configsDir.path, 'Debug.xcconfig');
  final releaseConfigPath = path.join(configsDir.path, 'Release.xcconfig');
  
  // Check if they exist and create/update them
  if (File(debugConfigPath).existsSync()) {
    String debugContent = File(debugConfigPath).readAsStringSync();
    if (!debugContent.contains('BaseConfig.xcconfig')) {
      debugContent = '#include "BaseConfig.xcconfig"\n' + debugContent;
      File(debugConfigPath).writeAsStringSync(debugContent);
      print('✅ Updated Debug.xcconfig to include BaseConfig.xcconfig');
    }
  } else {
    final debugContent = '''
#include "BaseConfig.xcconfig"
#include "../../Flutter/Flutter-Debug.xcconfig"
#include "Warnings.xcconfig"
''';
    File(debugConfigPath).writeAsStringSync(debugContent);
    print('✅ Created Debug.xcconfig at $debugConfigPath');
  }
  
  if (File(releaseConfigPath).existsSync()) {
    String releaseContent = File(releaseConfigPath).readAsStringSync();
    if (!releaseContent.contains('BaseConfig.xcconfig')) {
      releaseContent = '#include "BaseConfig.xcconfig"\n' + releaseContent;
      File(releaseConfigPath).writeAsStringSync(releaseContent);
      print('✅ Updated Release.xcconfig to include BaseConfig.xcconfig');
    }
  } else {
    final releaseContent = '''
#include "BaseConfig.xcconfig"
#include "../../Flutter/Flutter-Release.xcconfig"
#include "Warnings.xcconfig"
''';
    File(releaseConfigPath).writeAsStringSync(releaseContent);
    print('✅ Created Release.xcconfig at $releaseConfigPath');
  }
  
  // Step 3: Update the project.pbxproj file to use macOS 10.15
  final projectPath = path.join(macosDir.path, 'Runner.xcodeproj', 'project.pbxproj');
  if (File(projectPath).existsSync()) {
    try {
      String projectContent = File(projectPath).readAsStringSync();
      projectContent = projectContent.replaceAll(
        'MACOSX_DEPLOYMENT_TARGET = 10.14;', 
        'MACOSX_DEPLOYMENT_TARGET = 10.15;'
      );
      File(projectPath).writeAsStringSync(projectContent);
      print('✅ Updated Xcode project to use macOS 10.15 as deployment target');
    } catch (e) {
      print('⚠️ Warning: Failed to update Xcode project deployment target: $e');
    }
  } else {
    print('⚠️ Warning: Could not find Xcode project file at $projectPath');
  }
  
  // Step 4: Copy Podfile template
  final podfileTemplate = File(path.join(packagePath, 'macos', 'Resources', 'Podfile_template'));
  final podfile = File(path.join(macosDir.path, 'Podfile'));
  
  if (podfileTemplate.existsSync()) {
    String content = podfileTemplate.readAsStringSync();
    // Replace Python version if needed
    content = content.replaceAll('"3.11"', '"$pythonVersion"');
    podfile.writeAsStringSync(content);
    print('✅ Created Podfile at ${podfile.path}');
  } else {
    print('⚠️ Warning: Podfile template not found at ${podfileTemplate.path}');
  }
  
  // Step 5: Configure entitlements
  final debugEntitlementsTemplate = File(path.join(packagePath, 'macos', 'Resources', 'entitlements_template.xml'));
  final debugEntitlements = File(path.join(runnerDir.path, 'DebugProfile.entitlements'));
  final releaseEntitlements = File(path.join(runnerDir.path, 'Release.entitlements'));
  
  final String entitlementsContent = useSandbox 
    ? '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- App sandbox required for Mac App Store -->
	<key>com.apple.security.app-sandbox</key>
	<true/>
	
	<!-- Enable JIT for Python -->
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	
	<!-- Network access -->
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	
	<!-- File access permissions -->
	<key>com.apple.security.files.downloads.read-only</key>
	<true/>
	<key>com.apple.security.files.user-selected.read-write</key>
	<true/>
</dict>
</plist>'''
    : '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Set app-sandbox to false for non-sandboxed operation -->
	<key>com.apple.security.app-sandbox</key>
	<false/>
	
	<!-- Enable JIT for Python -->
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	
	<!-- Network access -->
	<key>com.apple.security.network.client</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
</dict>
</plist>''';
  
  // Check if files already exist and backup if necessary
  if (debugEntitlements.existsSync()) {
    final backupFile = File('${debugEntitlements.path}.backup');
    debugEntitlements.copySync(backupFile.path);
    print('ℹ️ Backed up existing DebugProfile.entitlements to ${backupFile.path}');
  }
  
  if (releaseEntitlements.existsSync()) {
    final backupFile = File('${releaseEntitlements.path}.backup');
    releaseEntitlements.copySync(backupFile.path);
    print('ℹ️ Backed up existing Release.entitlements to ${backupFile.path}');
  }
  
  // Write the entitlements files
  debugEntitlements.writeAsStringSync(entitlementsContent);
  print('✅ Created DebugProfile.entitlements at ${debugEntitlements.path}');
  
  // For release, remove JIT permission which is only for debug
  String releaseContent = entitlementsContent;
  releaseContent = releaseContent.replaceAll(
    '<key>com.apple.security.cs.allow-jit</key>\n\t<true/>',
    '<!-- JIT is not allowed in release mode -->'
  );
  releaseEntitlements.writeAsStringSync(releaseContent);
  print('✅ Created Release.entitlements at ${releaseEntitlements.path}');
  
  print('\n🎉 macOS setup complete!');
  print('\nNext steps:');
  print('1. Run "cd macos && pod install" to install dependencies');
  print('2. Add "await flutterpy.initializePython();" to your main() function');
  
  if (!useSandbox) {
    print('\n⚠️ Important Note for Non-Sandboxed Mode:');
    print('- Make sure Python 3.9+ is installed on the system: brew install python@$pythonVersion');
    print('- Your app will not be accepted in the Mac App Store with sandbox disabled');
    print('- The Podfile uses macOS 10.15 as the minimum deployment target');
  } else {
    print('\n⚠️ Important Note for Sandboxed Mode:');
    print('- Python will be bundled with your app, increasing its size');
    print('- Your app must request explicit permissions for file access');
    print('- The Podfile uses macOS 10.15 as the minimum deployment target');
  }
}

/// Set up Linux platform configuration
Future<void> _setupLinux(String outputDir, String pythonVersion) async {
  print('Setting up Linux platform configuration...');
  
  // Get the package path
  final packagePath = _getPackagePath();
  if (packagePath == null) {
    print('Error: Could not find FlutterPy package.');
    exit(1);
  }
  
  // Create directories
  final linuxDir = Directory(path.join(outputDir, 'linux'));
  if (!linuxDir.existsSync()) {
    print('Error: Linux directory not found at ${linuxDir.path}');
    print('Please run this command from your Flutter project root or specify the output directory.');
    exit(1);
  }
  
  // Step 1: Check if Python is installed
  bool pythonInstalled = false;
  try {
    final pythonResult = await Process.run('python3', ['--version']);
    if (pythonResult.exitCode == 0) {
      print('✅ Python is installed: ${pythonResult.stdout}');
      pythonInstalled = true;
    } else {
      print('⚠️ Python 3 not found. Will set up embedded Python.');
    }
  } catch (e) {
    print('⚠️ Failed to check Python installation: $e');
    print('   Will set up embedded Python.');
  }
  
  // Step 2: Check for required development packages if system Python is used
  if (pythonInstalled) {
    try {
      final lsResult = await Process.run('ls', ['/usr/include/python3*']);
      if (lsResult.exitCode == 0 && (lsResult.stdout as String).isNotEmpty) {
        print('✅ Python development headers found');
      } else {
        print('⚠️ Python development headers not found. Please install:');
        print('   - For Debian/Ubuntu: sudo apt-get install libpython3-dev');
        print('   - For Fedora/RHEL: sudo dnf install python3-devel');
        print('   Alternatively, the app will use embedded Python.');
      }
    } catch (e) {
      print('⚠️ Failed to check Python development headers: $e');
      print('   Will use embedded Python as fallback.');
    }
  }
  
  // Step 3: Create a script to download and set up embedded Python
  final setupScriptPath = path.join(linuxDir.path, 'setup_embedded_python.sh');
  final setupScriptContent = '''#!/bin/bash
# Script to download and set up embedded Python for Linux
# This script will be run during the build process if system Python is not available

set -e

PYTHON_VERSION="$pythonVersion"
DOWNLOAD_URL="https://github.com/indygreg/python-build-standalone/releases/download/20230116/cpython-\${PYTHON_VERSION}.0-x86_64-unknown-linux-gnu-install_only.tar.gz"
PYTHON_DIR="\${DESTDIR}/usr/lib/\${BINARY_NAME}/python"

# Create Python directory
mkdir -p "\${PYTHON_DIR}"

# Download Python
echo "Downloading Python \${PYTHON_VERSION}..."
curl -L "\${DOWNLOAD_URL}" -o python.tar.gz

# Extract Python
echo "Extracting Python..."
tar -xzf python.tar.gz -C "\${PYTHON_DIR}" --strip-components=1

# Clean up
rm python.tar.gz

echo "Embedded Python setup complete!"
''';
  
  File(setupScriptPath).writeAsStringSync(setupScriptContent);
  await Process.run('chmod', ['+x', setupScriptPath]);
  print('✅ Created embedded Python setup script at $setupScriptPath');
  
  // Step 4: Update CMakeLists.txt to include Python and the setup script
  final cmakeListsPath = path.join(linuxDir.path, 'CMakeLists.txt');
  if (File(cmakeListsPath).existsSync()) {
    try {
      String cmakeContent = File(cmakeListsPath).readAsStringSync();
      
      // Check if Python is already included
      if (!cmakeContent.contains('find_package(PythonLibs')) {
        // Add Python find package after the project declaration
        cmakeContent = cmakeContent.replaceFirst(
          'project(runner LANGUAGES CXX)',
          'project(runner LANGUAGES CXX)\n\n# Find Python package\nfind_package(PythonLibs ${pythonVersion} REQUIRED QUIET)\n\n# Set up embedded Python if system Python is not available\nif(NOT PYTHONLIBS_FOUND)\n  message(STATUS "System Python not found, will use embedded Python")\n  set(USE_EMBEDDED_PYTHON TRUE)\nelse()\n  set(USE_EMBEDDED_PYTHON FALSE)\nendif()'
        );
        
        // Add Python include directories and libraries
        // Use CMake variables with proper escaping for CMake syntax
        cmakeContent = cmakeContent.replaceFirst(
          'target_link_libraries(\${BINARY_NAME} PRIVATE flutter)',
          'if(USE_EMBEDDED_PYTHON)\n  target_link_libraries(\${BINARY_NAME} PRIVATE flutter "\${CMAKE_CURRENT_BINARY_DIR}/python/lib/libpython3.so")\nelse()\n  target_link_libraries(\${BINARY_NAME} PRIVATE flutter \${PYTHON_LIBRARIES})\nendif()'
        );
        
        cmakeContent = cmakeContent.replaceFirst(
          'target_include_directories(\${BINARY_NAME} PRIVATE',
          'if(USE_EMBEDDED_PYTHON)\n  target_include_directories(\${BINARY_NAME} PRIVATE\n    "\${CMAKE_CURRENT_BINARY_DIR}/python/include/python${pythonVersion}"\n  )\nelse()\n  target_include_directories(\${BINARY_NAME} PRIVATE\n    \${PYTHON_INCLUDE_DIRS}\n  )\nendif()\n\ntarget_include_directories(\${BINARY_NAME} PRIVATE'
        );
        
        // Add custom command to set up embedded Python during build
        if (!cmakeContent.contains('setup_embedded_python.sh')) {
          cmakeContent = cmakeContent.replaceFirst(
            'install(FILES "\${FLUTTER_ICU_DATA_FILE}" DESTINATION "\${INSTALL_BUNDLE_DATA_DIR}"',
            '# Set up embedded Python if needed\nif(USE_EMBEDDED_PYTHON)\n  add_custom_command(\n    TARGET \${BINARY_NAME} POST_BUILD\n    COMMAND \${CMAKE_COMMAND} -E make_directory "\${CMAKE_CURRENT_BINARY_DIR}/python"\n    COMMAND \${CMAKE_CURRENT_SOURCE_DIR}/setup_embedded_python.sh\n    WORKING_DIRECTORY \${CMAKE_CURRENT_BINARY_DIR}\n    COMMENT "Setting up embedded Python..."\n  )\n\n  install(DIRECTORY "\${CMAKE_CURRENT_BINARY_DIR}/python" DESTINATION "\${INSTALL_BUNDLE_LIB_DIR}")\nendif()\n\ninstall(FILES "\${FLUTTER_ICU_DATA_FILE}" DESTINATION "\${INSTALL_BUNDLE_DATA_DIR}"'
          );
        }
        
        File(cmakeListsPath).writeAsStringSync(cmakeContent);
        print('✅ Updated CMakeLists.txt to include Python and embedded Python support');
      } else {
        print('ℹ️ CMakeLists.txt already includes Python');
      }
    } catch (e) {
      print('⚠️ Failed to update CMakeLists.txt: $e');
    }
  } else {
    print('⚠️ CMakeLists.txt not found at $cmakeListsPath');
  }
  
  print('\n🎉 Linux setup complete!');
  print('\nNext steps:');
  print('1. If you have Python ${pythonVersion} installed on your system, it will be used automatically.');
  print('2. If not, an embedded Python will be downloaded and set up during the build process.');
  print('3. Run "flutter build linux" to build your application');
}

String? _getPackagePath() {
  // Try to find the package in various locations
  final candidates = [
    path.join('.', 'packages', 'flutterpy'),
    path.join('.dart_tool', 'pub', 'deps', 'flutterpy')
  ];
  
  for (final candidate in candidates) {
    if (Directory(candidate).existsSync()) {
      return candidate;
    }
  }
  
  return null;
} 