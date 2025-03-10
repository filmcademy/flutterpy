import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// A generator for the PyEnabled annotation
class PyEnabledGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final buffer = StringBuffer();
    
    // Find all classes with the PyEnabled annotation
    for (final classElement in library.classes) {
      if (_hasPyEnabledAnnotation(classElement)) {
        buffer.writeln('// Generated code for ${classElement.name}');
        buffer.writeln('extension ${classElement.name}PyExtension on ${classElement.name} {');
        
        // Process methods with PyFunction annotation
        for (final method in classElement.methods) {
          final pyFunctionAnnotation = _getPyFunctionAnnotation(method);
          if (pyFunctionAnnotation != null) {
            _generatePyFunctionMethod(buffer, method, pyFunctionAnnotation);
          }
        }
        
        // Process getters with PyVar annotation
        for (final accessor in classElement.accessors) {
          if (accessor.isGetter) {
            final pyVarAnnotation = _getPyVarAnnotation(accessor);
            if (pyVarAnnotation != null) {
              _generatePyVarGetter(buffer, accessor, pyVarAnnotation);
            }
          }
        }
        
        buffer.writeln('}');
      }
    }
    
    return buffer.toString();
  }
  
  /// Checks if the class has the PyEnabled annotation
  bool _hasPyEnabledAnnotation(ClassElement classElement) {
    return classElement.metadata.any((annotation) {
      final element = annotation.element;
      if (element is ConstructorElement) {
        final className = element.enclosingElement.name;
        return className == 'PyEnabled';
      }
      return false;
    });
  }
  
  /// Gets the PyFunction annotation from a method
  String? _getPyFunctionAnnotation(MethodElement method) {
    for (final annotation in method.metadata) {
      final element = annotation.element;
      if (element is ConstructorElement) {
        final className = element.enclosingElement.name;
        if (className == 'PyFunction') {
          // Extract the Python code from the annotation
          final pythonCode = annotation.computeConstantValue()?.getField('pythonCode')?.toStringValue();
          return pythonCode;
        }
      }
    }
    return null;
  }
  
  /// Gets the PyVar annotation from an accessor
  String? _getPyVarAnnotation(PropertyAccessorElement accessor) {
    for (final annotation in accessor.metadata) {
      final element = annotation.element;
      if (element is ConstructorElement) {
        final className = element.enclosingElement.name;
        if (className == 'PyVar') {
          // Extract the Python expression from the annotation
          final pythonExpression = annotation.computeConstantValue()?.getField('pythonExpression')?.toStringValue();
          return pythonExpression;
        }
      }
    }
    return null;
  }
  
  /// Generates a method implementation for a PyFunction annotation
  void _generatePyFunctionMethod(StringBuffer buffer, MethodElement method, String pythonCode) {
    final methodName = method.name;
    final returnType = method.returnType.getDisplayString(withNullability: true);
    final parameters = method.parameters.map((p) => '${p.type.getDisplayString(withNullability: true)} ${p.name}').join(', ');
    final parameterNames = method.parameters.map((p) => p.name).join(', ');
    
    buffer.writeln('  $returnType $methodName($parameters) async {');
    buffer.writeln('    final pythonFunction = PythonFunction("""');
    buffer.writeln(pythonCode);
    buffer.writeln('    """);');
    buffer.writeln('    return await pythonFunction.call([$parameterNames]);');
    buffer.writeln('  }');
  }
  
  /// Generates a getter implementation for a PyVar annotation
  void _generatePyVarGetter(StringBuffer buffer, PropertyAccessorElement accessor, String pythonExpression) {
    final getterName = accessor.name;
    final returnType = accessor.returnType.getDisplayString(withNullability: true);
    
    buffer.writeln('  $returnType get $getterName async {');
    buffer.writeln('    final bridge = PythonBridge.instance;');
    buffer.writeln('    await bridge.ensureInitialized();');
    buffer.writeln('    return await bridge.executeCode(\'$pythonExpression\');');
    buffer.writeln('  }');
  }
}

/// The builder factory for the PyEnabled generator
Builder pyEnabledGeneratorBuilder(BuilderOptions options) =>
    SharedPartBuilder([PyEnabledGenerator()], 'flutterpy_generator'); 