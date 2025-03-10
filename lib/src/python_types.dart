part of flutterpy;

/// Handles conversion between Dart and Python types
class PythonTypes {
  /// Converts a Python value to a Dart value
  static dynamic pythonToDart(dynamic pythonValue) {
    if (pythonValue == null) {
      return null;
    } else if (pythonValue is bool) {
      return pythonValue;
    } else if (pythonValue is num) {
      return pythonValue;
    } else if (pythonValue is String) {
      return pythonValue;
    } else if (pythonValue is List) {
      return pythonValue.map(pythonToDart).toList();
    } else if (pythonValue is Map) {
      return pythonValue.map(
        (key, value) => MapEntry(pythonToDart(key), pythonToDart(value)),
      );
    } else {
      return pythonValue.toString();
    }
  }
  
  /// Converts a Dart value to a Python value
  static String dartToPython(dynamic dartValue) {
    if (dartValue == null) {
      return 'None';
    } else if (dartValue is bool) {
      return dartValue ? 'True' : 'False';
    } else if (dartValue is num) {
      return dartValue.toString();
    } else if (dartValue is String) {
      return "'${dartValue.replaceAll("'", "\\'")}'";
    } else if (dartValue is List) {
      final elements = dartValue.map(dartToPython).join(', ');
      return '[$elements]';
    } else if (dartValue is Map) {
      final entries = dartValue.entries.map((e) => 
        '${dartToPython(e.key)}: ${dartToPython(e.value)}'
      ).join(', ');
      return '{$entries}';
    } else {
      return dartValue.toString();
    }
  }
}

/// Represents a Python object in Dart
class PyObject {
  final String _pythonExpression;
  final PythonBridge _bridge = PythonBridge.instance;
  
  /// Creates a new Python object
  PyObject(this._pythonExpression);
  
  /// Gets the Python expression
  String get pythonExpression => _pythonExpression;
  
  /// Calls a method on the Python object
  Future<dynamic> callMethod(String methodName, List<dynamic> args) async {
    await _bridge.ensureInitialized();
    
    // Convert arguments to Python code
    final pythonArgs = args.map(PythonTypes.dartToPython).join(', ');
    
    // Create the Python code to execute
    final pythonCode = '$_pythonExpression.$methodName($pythonArgs)';
    
    return _bridge.executeCode(pythonCode);
  }
  
  /// Gets an attribute of the Python object
  Future<dynamic> getAttr(String attributeName) async {
    await _bridge.ensureInitialized();
    
    // Create the Python code to execute
    final pythonCode = '$_pythonExpression.$attributeName';
    
    return _bridge.executeCode(pythonCode);
  }
  
  /// Sets an attribute of the Python object
  Future<void> setAttr(String attributeName, dynamic value) async {
    await _bridge.ensureInitialized();
    
    // Convert value to Python code
    final pythonValue = PythonTypes.dartToPython(value);
    
    // Create the Python code to execute
    final pythonCode = '$_pythonExpression.$attributeName = $pythonValue';
    
    await _bridge.executeCode(pythonCode);
  }
  
  /// Converts the Python object to a string
  @override
  String toString() {
    return 'PyObject($_pythonExpression)';
  }
}

/// Represents a Python module in Dart
class PyModule {
  final String _moduleName;
  final PythonBridge _bridge = PythonBridge.instance;
  
  /// Creates a new Python module
  PyModule(this._moduleName);
  
  /// Gets the module name
  String get moduleName => _moduleName;
  
  /// Imports the module
  Future<void> import() async {
    await _bridge.ensureInitialized();
    await _bridge.importModule(_moduleName);
  }
  
  /// Gets an attribute of the module
  Future<dynamic> getAttr(String attributeName) async {
    await _bridge.ensureInitialized();
    await import();
    
    // Create the Python code to execute
    final pythonCode = '$_moduleName.$attributeName';
    
    return _bridge.executeCode(pythonCode);
  }
  
  /// Calls a function in the module
  Future<dynamic> callFunction(String functionName, List<dynamic> args) async {
    await _bridge.ensureInitialized();
    await import();
    
    // Convert arguments to Python code
    final pythonArgs = args.map(PythonTypes.dartToPython).join(', ');
    
    // Create the Python code to execute
    final pythonCode = '$_moduleName.$functionName($pythonArgs)';
    
    return _bridge.executeCode(pythonCode);
  }
  
  /// Converts the Python module to a string
  @override
  String toString() {
    return 'PyModule($_moduleName)';
  }
} 