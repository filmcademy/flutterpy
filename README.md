# FlutterPy

A Flutter package that provides seamless integration with Python. FlutterPy automatically creates a Python environment and makes Python functions accessible from Dart.

## Features

- Automatic Python environment setup
- Download and install Python if not available locally
- Specify the Python version to use
- Execute Python code directly from Dart
- Call Python functions with Dart arguments
- Import Python modules
- Install Python packages
- Annotate Dart methods to be implemented in Python
- Convert between Dart and Python types
- Command-line tool for initializing Python environments

## Getting Started

### Prerequisites

- Flutter 2.0.0 or higher
- Python 3.8 or higher installed on the system (optional - FlutterPy can download Python if not available)

### Installation

Add FlutterPy to your `pubspec.yaml`:

```yaml
dependencies:
  flutterpy: ^0.1.0
```

Then run:

```bash
flutter pub get
```

### Platform Setup

#### macOS Setup

FlutterPy offers two approaches for macOS:

### 1. Simple Non-Sandboxed Setup (Recommended for Development)

For macOS applications that don't need to be distributed through the Mac App Store:

```bash
# Run the setup tool with sandbox disabled (default)
dart run flutterpy --setup-macos
```

This will:
- Create necessary entitlements files with sandbox disabled
- Create a simplified Podfile without Python bundling
- Set macOS 10.15 as the minimum deployment target
- Automatically update all Xcode configuration files
- Fix project settings to ensure compatibility

Benefits:
- ✅ Simpler setup
- ✅ Full file system access
- ✅ Uses system Python
- ✅ Smaller app size
- ✅ Single command setup

Limitations:
- ❌ Not suitable for Mac App Store distribution

### 2. Sandboxed Setup (for Mac App Store)

For macOS applications that need to be distributed through the Mac App Store:

```bash
# Run the setup tool with sandbox enabled
dart run flutterpy --setup-macos --sandbox
```

This will:
- Create necessary entitlements files with sandbox enabled
- Set up Python bundling with your app
- Configure proper permissions
- Set macOS 10.15 as the minimum deployment target

After setup, install the pods:

```bash
cd macos && pod install
```

In both cases, initialize Python in your app:

```dart
import 'package:flutterpy/flutterpy.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Python
  await initializePython();
  
  // Run the app
  runApp(MyApp());
}
```

## Usage

### Basic Usage

```dart
import 'package:flutterpy/flutterpy.dart';

void main() async {
  // Initialize Python with specific version (optional)
  await initializePython(pythonVersion: '3.10', forceDownload: true);
  
  // Execute Python code
  final result = await "".py('1 + 1');
  print(result); // 2
  
  // Import a module
  await "".pyImport('numpy');
  
  // Call a function
  final mean = await "".pyCall('numpy.mean', [[1, 2, 3, 4, 5]]);
  print(mean); // 3.0
  
  // Install a package
  await "".pyInstall('pandas');
}
```

### Python Environment Configuration

FlutterPy can automatically download and install Python if it's not available on the system:

```dart
// Use a specific Python version and force download even if Python is installed
await initializePython(pythonVersion: '3.9', forceDownload: true);

// Use the default Python version (3.10) and only download if Python is not installed
await initializePython();

// Get the path to the Python environment
final envPath = await getPythonLibraryPath();
print('Python library is at: $envPath');
```

### Working with Python Modules

```dart
import 'package:flutterpy/flutterpy.dart';

void main() async {
  // Create a Python module
  final numpy = PyModule('numpy');
  
  // Import the module
  await numpy.import();
  
  // Call a function
  final array = await numpy.callFunction('array', [[1, 2, 3]]);
  final mean = await numpy.callFunction('mean', [array]);
  
  print(mean); // 2.0
}
```

## How It Works

FlutterPy creates a Python virtual environment in your application's directory and manages the installation of Python packages. It uses Foreign Function Interface (FFI) to communicate between Dart and Python.

For macOS apps:
1. The package adds necessary entitlements to your app
2. It configures a build script to bundle Python with your app
3. At runtime, it initializes Python and makes it available to your Flutter app

## Command-Line Tool

FlutterPy comes with a command-line tool for setting up your Flutter app:

```bash
# Install the package globally
dart pub global activate flutterpy

# Set up macOS configuration
dart run flutterpy --setup-macos

# Set up macOS with a specific Python version
dart run flutterpy --setup-macos --python-version 3.9

# Show help
dart run flutterpy --help
```

The CLI tool supports the following options:

- `--setup-macos`: Set up macOS platform configuration
- `--python-version`, `-v`: Python version to use (e.g., 3.9, 3.11)
- `--output-dir`, `-o`: Output directory for platform configuration files
- `--help`, `-h`: Show help message

## License

This project is licensed under the MIT License - see the LICENSE file for details. 