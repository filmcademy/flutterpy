part of flutterpy;

/// Manages communication between Dart and Python
class PythonBridge {
  static PythonBridge? _instance;
  
  /// Get the singleton instance of the Python bridge
  static PythonBridge get instance {
    _instance ??= PythonBridge._();
    return _instance!;
  }
  
  final PythonEnvironment _environment = PythonEnvironment.instance;
  final Map<String, dynamic> _variables = {};
  final Set<String> _importedModules = {};
  
  PythonBridge._();
  
  /// Ensures that the Python bridge is initialized
  /// 
  /// [pythonVersion] - The Python version to use (e.g., '3.9', '3.10')
  /// [forceDownload] - Whether to force download Python even if it's installed locally
  Future<void> ensureInitialized({String? pythonVersion, bool forceDownload = false}) async {
    await _environment.ensureInitialized(pythonVersion: pythonVersion, forceDownload: forceDownload);
  }
  
  /// Executes Python code and returns the result
  Future<dynamic> executeCode(String pythonCode) async {
    // Create a Python script that executes the code and serializes the result
    final script = '''
import json
import sys
import traceback

try:
    result = $pythonCode
    if result is not None:
        # Convert result to JSON
        import numpy as np
        
        class NumpyEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, np.ndarray):
                    return obj.tolist()
                if isinstance(obj, np.integer):
                    return int(obj)
                if isinstance(obj, np.floating):
                    return float(obj)
                if isinstance(obj, np.bool_):
                    return bool(obj)
                return json.JSONEncoder.default(self, obj)
        
        print(json.dumps({"result": result}, cls=NumpyEncoder))
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

    final result = await _environment.executePythonScript(script);
    
    if (result.exitCode != 0) {
      throw Exception('Python execution failed: ${result.stderr}');
    }
    
    // Parse the JSON result
    final output = result.stdout.toString().trim();
    if (output.isEmpty) {
      return null;
    }
    
    final jsonResult = json.decode(output);
    
    // Check for errors
    if (jsonResult.containsKey('error')) {
      final error = jsonResult['error'];
      throw PythonException(
        error['type'],
        error['message'],
        error['traceback'],
      );
    }
    
    return jsonResult['result'];
  }
  
  /// Loads and executes a Python file
  /// 
  /// [filePath] - The path to the Python file to load
  /// [functionName] - Optional function name to call from the loaded file
  /// [args] - Optional arguments to pass to the function
  Future<dynamic> loadPythonFile(String filePath, {String? functionName, List<dynamic>? args}) async {
    await _environment.ensureInitialized();
    
    // Check if the file exists
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('Python file not found', filePath);
    }
    
    // Create a Python script that loads the file and optionally calls a function
    final script = '''
import json
import sys
import traceback
import importlib.util
import os

try:
    # Get the directory of the Python file
    file_dir = os.path.dirname('$filePath')
    if file_dir:
        # Add the directory to sys.path if it's not already there
        if file_dir not in sys.path:
            sys.path.insert(0, file_dir)
    
    # Load the Python file as a module
    spec = importlib.util.spec_from_file_location("loaded_module", '$filePath')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    
    ${functionName != null ? '''
    # Call the specified function with arguments
    function = getattr(module, '$functionName')
    result = function(${args?.map(_convertToPythonLiteral).join(', ') ?? ''})
    ''' : 'result = None'}
    
    # Convert result to JSON
    if result is not None:
        import numpy as np
        
        class NumpyEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, np.ndarray):
                    return obj.tolist()
                if isinstance(obj, np.integer):
                    return int(obj)
                if isinstance(obj, np.floating):
                    return float(obj)
                if isinstance(obj, np.bool_):
                    return bool(obj)
                return json.JSONEncoder.default(self, obj)
        
        print(json.dumps({"result": result}, cls=NumpyEncoder))
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

    final result = await _environment.executePythonScript(script);
    
    if (result.exitCode != 0) {
      throw Exception('Python file execution failed: ${result.stderr}');
    }
    
    // Parse the JSON result
    final output = result.stdout.toString().trim();
    if (output.isEmpty) {
      return null;
    }
    
    try {
      final jsonResult = json.decode(output);
      
      // Check for errors
      if (jsonResult.containsKey('error')) {
        final error = jsonResult['error'];
        throw PythonException(
          error['type'],
          error['message'],
          error['traceback'],
        );
      }
      
      return jsonResult['result'];
    } catch (e) {
      // If JSON parsing fails, return the raw output
      return output;
    }
  }
  
  /// Calls a Python function with arguments and returns the result
  Future<dynamic> callFunction(String functionName, List<dynamic> args) async {
    // Convert arguments to Python code
    final pythonArgs = args.map(_convertToPythonLiteral).join(', ');
    
    // Create the Python code to execute
    final pythonCode = '$functionName($pythonArgs)';
    
    return executeCode(pythonCode);
  }
  
  /// Imports a Python module
  Future<void> importModule(String moduleName) async {
    if (_importedModules.contains(moduleName)) {
      return;
    }
    
    await executeCode('import $moduleName');
    _importedModules.add(moduleName);
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
  
  /// Sets a variable in the Python environment
  Future<void> setVariable(String name, dynamic value) async {
    final pythonValue = _convertToPythonLiteral(value);
    await executeCode('$name = $pythonValue');
    _variables[name] = value;
  }
  
  /// Gets a variable from the Python environment
  Future<dynamic> getVariable(String name) async {
    return executeCode(name);
  }
}

/// Exception thrown when Python code execution fails
class PythonException implements Exception {
  final String type;
  final String message;
  final String traceback;
  
  PythonException(this.type, this.message, this.traceback);
  
  @override
  String toString() {
    return 'PythonException: $type: $message\n$traceback';
  }
} 