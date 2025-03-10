// Example of using FlutterPy with JAX's FFI capabilities

import 'package:flutterpy/flutterpy.dart';

void main() async {
  print('FlutterPy JAX FFI Example');
  print('------------------------');
  
  try {
    // Initialize the Python environment
    print('Initializing Python environment...');
    final env = PythonEnvironment.instance;
    await env.ensureInitialized();
    print('Python environment initialized successfully.');
    
    // Install JAX
    print('\nInstalling JAX...');
    await "".pyInstall('jax[cpu]');
    print('JAX installed successfully.');
    
    // Create a C function using JAX's FFI
    print('\nCreating a C function using JAX\'s FFI...');
    final result = await "".py('''
import jax
import jax.numpy as jnp
from jax.ffi import capi
import ctypes
import numpy as np
import os
import tempfile

# Define a simple JAX function
def jax_function(x):
    return jnp.sin(x) + jnp.cos(x)

# Compile the function to XLA
jitted_function = jax.jit(jax_function)

# Create some test data
x = jnp.array([1.0, 2.0, 3.0, 4.0, 5.0])

# Get the compiled result for testing
jax_result = jitted_function(x)

# Create a C function using JAX's FFI
c_function = capi.export(jitted_function, [capi.f32[:]])

# Create a temporary directory for the shared library
temp_dir = tempfile.mkdtemp()
lib_path = os.path.join(temp_dir, 'libjax_function.so')

# Compile the C function to a shared library
c_function.compile(lib_path)

# Load the shared library using ctypes
lib = ctypes.CDLL(lib_path)

# Define the function signature
lib.jax_function.argtypes = [
    np.ctypeslib.ndpointer(dtype=np.float32, ndim=1, flags='C_CONTIGUOUS'),
    np.ctypeslib.ndpointer(dtype=np.float32, ndim=1, flags='C_CONTIGUOUS'),
    ctypes.c_int
]
lib.jax_function.restype = None

# Create input and output arrays
input_array = np.array(x, dtype=np.float32)
output_array = np.zeros_like(input_array)
n = len(input_array)

# Call the C function
lib.jax_function(input_array, output_array, n)

return {
    'input': input_array.tolist(),
    'jax_result': jax_result.tolist(),
    'c_result': output_array.tolist(),
    'lib_path': lib_path
}
''');
    
    print('Input: ${result['input']}');
    print('JAX result: ${result['jax_result']}');
    print('C function result: ${result['c_result']}');
    print('Shared library path: ${result['lib_path']}');
    
    // Use the shared library from Dart
    print('\nUsing the shared library from Dart...');
    final libPath = result['lib_path'];
    
    // Create a Dart FFI wrapper for the shared library
    final dartResult = await "".py('''
import ctypes
import numpy as np

# Load the shared library
lib_path = '$libPath'
lib = ctypes.CDLL(lib_path)

# Define the function signature
lib.jax_function.argtypes = [
    np.ctypeslib.ndpointer(dtype=np.float32, ndim=1, flags='C_CONTIGUOUS'),
    np.ctypeslib.ndpointer(dtype=np.float32, ndim=1, flags='C_CONTIGUOUS'),
    ctypes.c_int
]
lib.jax_function.restype = None

# Create new input and output arrays
input_array = np.array([0.5, 1.5, 2.5, 3.5, 4.5], dtype=np.float32)
output_array = np.zeros_like(input_array)
n = len(input_array)

# Call the C function
lib.jax_function(input_array, output_array, n)

return {
    'new_input': input_array.tolist(),
    'new_output': output_array.tolist()
}
''');
    
    print('New input: ${dartResult['new_input']}');
    print('New output: ${dartResult['new_output']}');
    
    print('\nExiting FlutterPy JAX FFI example.');
  } catch (e) {
    print('Error: $e');
  }
} 