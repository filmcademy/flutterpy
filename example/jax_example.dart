// Example of using FlutterPy with JAX

import 'package:flutterpy/flutterpy.dart';

void main() async {
  print('FlutterPy JAX Example');
  print('--------------------');
  
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
    
    // Import JAX
    print('\nImporting JAX...');
    await "".pyImport('jax');
    await "".pyImport('jax.numpy');
    print('JAX imported successfully.');
    
    // Basic JAX example
    print('\nRunning basic JAX example:');
    final result = await "".py('''
import jax
import jax.numpy as jnp

# Define a simple function
def f(x):
    return jnp.sum(jnp.sin(x))

# Create a gradient function
grad_f = jax.grad(f)

# Create some data
x = jnp.array([1.0, 2.0, 3.0, 4.0, 5.0])

# Compute the gradient
gradient = grad_f(x)

return {
    'input': x.tolist(),
    'function_value': float(f(x)),
    'gradient': gradient.tolist()
}
''');
    
    print('Input: ${result['input']}');
    print('Function value: ${result['function_value']}');
    print('Gradient: ${result['gradient']}');
    
    // JAX with automatic vectorization (vmap)
    print('\nJAX with automatic vectorization (vmap):');
    final vmapResult = await "".py('''
import jax
import jax.numpy as jnp

# Define a function that operates on a single element
def f(x):
    return jnp.sin(x)

# Vectorize the function to operate on arrays
vf = jax.vmap(f)

# Create a batch of data
x = jnp.array([[1.0, 2.0, 3.0],
               [4.0, 5.0, 6.0],
               [7.0, 8.0, 9.0]])

# Apply the vectorized function
result = vf(x)

return {
    'input': x.tolist(),
    'output': result.tolist()
}
''');
    
    print('Input:');
    for (final row in vmapResult['input']) {
      print('  $row');
    }
    print('Output:');
    for (final row in vmapResult['output']) {
      print('  $row');
    }
    
    // JAX with JIT compilation
    print('\nJAX with JIT compilation:');
    final jitResult = await "".py('''
import jax
import jax.numpy as jnp
import time

# Define a function
def slow_f(x):
    # Simulate a complex computation
    for _ in range(10):
        x = jnp.sin(x)
    return x

# Create a JIT-compiled version
fast_f = jax.jit(slow_f)

# Create some data
x = jnp.array([1.0, 2.0, 3.0, 4.0, 5.0])

# Measure time for the regular function
start_time = time.time()
regular_result = slow_f(x)
regular_time = time.time() - start_time

# Warm up the JIT compilation
_ = fast_f(x)

# Measure time for the JIT-compiled function
start_time = time.time()
jit_result = fast_f(x)
jit_time = time.time() - start_time

return {
    'input': x.tolist(),
    'regular_result': regular_result.tolist(),
    'jit_result': jit_result.tolist(),
    'regular_time': regular_time,
    'jit_time': jit_time,
    'speedup': regular_time / jit_time if jit_time > 0 else float('inf')
}
''');
    
    print('Input: ${jitResult['input']}');
    print('Regular result: ${jitResult['regular_result']}');
    print('JIT result: ${jitResult['jit_result']}');
    print('Regular time: ${jitResult['regular_time']} seconds');
    print('JIT time: ${jitResult['jit_time']} seconds');
    print('Speedup: ${jitResult['speedup']}x');
    
    print('\nExiting FlutterPy JAX example.');
  } catch (e) {
    print('Error: $e');
  }
} 