#include "include/flutterpy/flutterpy_plugin_c_api.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include "include/flutterpy/flutterpy_plugin.h"

// This file implements the C API version of the plugin, which is used by the
// Dart side of the plugin. It forwards calls to the C++ implementation in
// flutterpy_plugin.cc.

void flutterpy_plugin_c_api_register_with_registrar(FlPluginRegistrar* registrar) {
  flutterpy_plugin_register_with_registrar(registrar);
} 