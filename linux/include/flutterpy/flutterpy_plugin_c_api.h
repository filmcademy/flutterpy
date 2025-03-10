#ifndef FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_C_API_H_

#include <flutter_linux/flutter_linux.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void flutterpy_plugin_c_api_register_with_registrar(
    FlPluginRegistrar* registrar);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_C_API_H_ 