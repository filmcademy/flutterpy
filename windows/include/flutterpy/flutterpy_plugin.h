#ifndef FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_H_

// Use a more specific include path that should be available in the Flutter Windows environment
#include <flutter/plugin_registrar_windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterpyPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FLUTTERPY_PLUGIN_H_