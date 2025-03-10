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
final envPath = getPythonEnvPath();
print('Python environment is at: $envPath');
```

### Using Annotations

```dart
import 'package:flutterpy/flutterpy.dart';

@PyEnabled
class MyPythonClass {
  @PyFunction('''
  import numpy as np
  return np.mean(arg0)
  ''')
  Future<double> calculateMean(List<double> numbers) async {
    // This method will be implemented in Python
    throw UnimplementedError();
  }
  
  @PyVar('np.array([1, 2, 3])')
  List<int> get defaultArray => throw UnimplementedError();
}
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

FlutterPy creates a Python virtual environment in your application's directory and manages the installation of Python packages. It uses a combination of process execution and file I/O to communicate between Dart and Python.

When you call a Python function from Dart, FlutterPy:

1. Creates a temporary Python script
2. Executes the script with the Python interpreter
3. Captures the output and converts it to Dart types
4. Returns the result to your Dart code

## Limitations

- Python must be installed on the system
- Performance may be slower than native Dart code
- Not all Python types can be converted to Dart types
- Reflection-based annotations may not work on all platforms

## License

This project is licensed under the MIT License - see the LICENSE file for details.

### Command-Line Tool

FlutterPy comes with a command-line tool for initializing Python environments:

```bash
# Install the package globally
dart pub global activate flutterpy

# Initialize a Python environment with default settings
flutterpy

# Initialize a Python environment with a specific version
flutterpy --python-version 3.9

# Force download Python even if it's installed locally
flutterpy --force-download

# Show help
flutterpy --help
```

The CLI tool supports the following options:

- `--python-version`, `-v`: Python version to use (e.g., 3.9, 3.10)
- `--force-download`, `-f`: Force download Python even if installed locally
- `--output-dir`, `-o`: Output directory for the Python environment
- `--help`, `-h`: Show help message 