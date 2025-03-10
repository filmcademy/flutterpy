//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutterpy/flutterpy_plugin_c_api.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) flutterpy_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "FlutterpyPluginCApi");
  flutterpy_plugin_c_api_register_with_registrar(flutterpy_registrar);
}
