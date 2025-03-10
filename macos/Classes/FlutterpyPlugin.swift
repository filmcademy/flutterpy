import Cocoa
import FlutterMacOS

public class FlutterpyPlugin: NSObject, FlutterPlugin {
  private var pythonSetupComplete = false
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutterpy", binaryMessenger: registrar.messenger)
    let instance = FlutterpyPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "setupPython":
      setupPython(call: call, result: result)
    case "isPythonSetup":
      result(pythonSetupComplete)
    case "getPythonResourcePath":
      getPythonResourcePath(result: result)
    case "executeScript":
      executeScript(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func executeScript(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let scriptPath = args["scriptPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    // In non-sandboxed mode, we can directly use system Python
    let pythonPath = "/usr/bin/python3"
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: pythonPath)
    task.arguments = [scriptPath]
    
    let outputPipe = Pipe()
    let errorPipe = Pipe()
    task.standardOutput = outputPipe
    task.standardError = errorPipe
    
    do {
      try task.run()
      task.waitUntilExit()
      
      let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
      let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
      let output = String(data: outputData, encoding: .utf8) ?? ""
      let error = String(data: errorData, encoding: .utf8) ?? ""
      
      if task.terminationStatus == 0 {
        result(["status": 0, "output": output, "error": error])
      } else {
        result(["status": task.terminationStatus, "output": output, "error": error])
      }
    } catch {
      result(FlutterError(code: "PROCESS_ERROR", message: "Failed to execute Python script: \(error.localizedDescription)", details: nil))
    }
  }
  
  private func getPythonResourcePath(result: @escaping FlutterResult) {
    // For non-sandboxed mode, just return the bundle path
    if let bundlePath = Bundle.main.resourcePath {
      result(bundlePath)
    } else {
      result(nil)
    }
  }
  
  private func setupPython(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // For non-sandboxed mode, we'll just check if system Python is available
    let pythonPath = "/usr/bin/python3"
    
    if FileManager.default.fileExists(atPath: pythonPath) {
      print("System Python found at \(pythonPath)")
      pythonSetupComplete = true
      result(true)
    } else {
      // Check common Homebrew locations
      let homebrewPaths = [
        "/opt/homebrew/bin/python3",
        "/usr/local/bin/python3"
      ]
      
      for path in homebrewPaths {
        if FileManager.default.fileExists(atPath: path) {
          print("System Python found at \(path)")
          pythonSetupComplete = true
          result(true)
          return
        }
      }
      
      print("Python not found. Please install Python 3.9+ on your system.")
      result(false)
    }
  }
} 