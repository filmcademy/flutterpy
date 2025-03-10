// Export all platform-specific implementations
export 'platform_adapter.dart';

// Re-export platform-specific files
import 'dart:io' show Platform;

// Import platform-specific classes
import 'platform_adapter.dart';

/// Get the appropriate platform setup
PythonPlatformSetup getPlatformSetup() {
  return PythonPlatformFactory.create();
}

/// Check if the current platform is supported
bool isPlatformSupported() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

/// Get installation instructions for the current platform
String getPlatformInstructions() {
  if (Platform.isMacOS) {
    return '''
macOS Platform Setup:

1. Ensure your app has the necessary entitlements:
   - com.apple.security.app-sandbox
   - com.apple.security.cs.allow-jit
   - com.apple.security.network.client
   - com.apple.security.network.server
   - com.apple.security.files.user-selected.read-write
   - com.apple.security.files.downloads.read-only

2. Use the Podfile template provided by flutterpy

3. Make sure Python 3.11 is installed on your development machine
''';
  } else if (Platform.isWindows) {
    return 'Windows platform support is coming soon.';
  } else if (Platform.isLinux) {
    return '''
Linux Platform Setup:

1. Make sure Python 3.8 or later is installed on your system:
   - sudo apt-get install python3 python3-pip python3-dev (for Debian/Ubuntu)
   - sudo dnf install python3 python3-pip python3-devel (for Fedora)

2. Ensure the following packages are installed:
   - libpython3-dev (for Debian/Ubuntu)
   - python3-devel (for Fedora/RHEL)

3. Add the following to your pubspec.yaml:
   dependencies:
     flutterpy: ^latest_version
''';
  } else {
    return 'Your platform is not supported by flutterpy.';
  }
} 