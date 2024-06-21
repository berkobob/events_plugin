import Cocoa
import FlutterMacOS
import EventKit

public class EventsPlugin: NSObject, FlutterPlugin {
    
    let eventStore: EKEventStore = EKEventStore()
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "events_plugin", binaryMessenger: registrar.messenger)
    let instance = EventsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "hasAccess":
         result(hasAccess())
     case "requestAccess": requestAccess(result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
    
    func hasAccess() -> Bool {
        return EKEventStore.authorizationStatus(for: .event) == .authorized
    }
       
   func requestAccess(_ result: @escaping FlutterResult) {
       if hasAccess() { result(true) }
           eventStore.requestAccess(to: .event) { (success: Bool, error: (any Error)? ) in
           if let error = error { print (error) }
               result(success)
           }
       }
}
