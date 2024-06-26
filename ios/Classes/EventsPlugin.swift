import Flutter
import UIKit
import EventKit

public class EventsPlugin: NSObject, FlutterPlugin {
      
  let eventStore: EKEventStore = EKEventStore()

  public static func register(with registrar: FlutterPluginRegistrar) {
    // let channel = FlutterMethodChannel(name: "events_plugin", binaryMessenger: registrar.messenger)
    let channel = FlutterMethodChannel(name: "events_plugin", binaryMessenger: registrar.messenger())
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
    case "getDefaultCalendar":  result(getDefaultCalendar())
    case "getCalendars": result(getCalendars())
        
    case "getEvents":
           if let args = call.arguments as? [String: String?] {
               if let id = args["id"] {
                   getEvents(id!, result)
               }
           }

   case "addEvent":
             if let args = call.arguments as? [String: Any?] {
                 result(addEvent(args))
             }
             
    case "deleteEvent":
        if let args = call.arguments as? [String: Any?] {
            if let id = args["id"] as? String {
                result(deleteEvent(id))
            }
        }
        
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
    
    func getDefaultCalendar() -> [String: String]? {
        let defaultList: EKCalendar? = self.eventStore.defaultCalendarForNewEvents
                guard let defaultList = defaultList else { return nil }
                return [
                    "id": defaultList.calendarIdentifier,
                    "title": defaultList.title
                ]
    }
    
    func getCalendars() -> [[String: String]]? {
        let lists: [EKCalendar] = eventStore.calendars(for: .event)
        return lists.map{ [
            "id": $0.calendarIdentifier,
            "title": $0.title
        ] }
    }
    
    func getEvents(_ id: String, _ result: @escaping FlutterResult) {
        let calendars = [eventStore.calendar(withIdentifier: id) ?? EKCalendar()]
        let oneYearAgo = Date(timeIntervalSinceNow: -365*24*60*60)
        let oneYearAfter = Date(timeIntervalSinceNow: 365*24*60*60)
        let predicate: NSPredicate = eventStore.predicateForEvents(withStart: oneYearAgo, end: oneYearAfter, calendars: calendars)
        
        var events: [[String: String]] = []
        eventStore.enumerateEvents(matching: predicate) { (event: EKEvent, stop) in
            events.append([
                "calendar": id,
                "id": event.calendarItemIdentifier,
                "title": event.title,
                "startDate": event.startDate.description,
                "endDate": event.endDate.description,
                "location": event.location ?? "",
                "isAllDay": event.isAllDay.description,
                "notes": event.notes ?? ""
            ])
        }
        result(events)
       }

 
    func addEvent(_ json: [String: Any?]) -> [String: String] {
        guard json["calendar"] != nil,
            let calendarID: String = json["calendar"] as? String,
            let calendar: EKCalendar = eventStore.calendar(withIdentifier: calendarID) else { return ["error": "Invalid calendar"] }
          
        let event: EKEvent = EKEvent(eventStore: eventStore)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          
        event.calendar = calendar
        event.title = json["title"] as? String
        event.startDate = isoFormatter.date(from: (json["startDate"] as? String)!)
        event.isAllDay = json["isAllDay"] as? Bool ?? false
        event.endDate = isoFormatter.date(from: (json["endDate"] as? String)!)
        event.notes = json["notes"] as? String
          
        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            print(event)
        } catch let error {
            return ["error": error.localizedDescription]
        }
        
        return ["success": event.calendarItemIdentifier]
      }
      
      func deleteEvent(_ id: String?) -> String? {
          guard
            let id = id,
            let event: EKEvent = eventStore.calendarItem(withIdentifier: id) as? EKEvent else { return nil}
          
          do {
              try eventStore.remove(event, span: .thisEvent, commit: true)
          } catch {
              print("Error deleting event \(event)")
              return error.localizedDescription
          }
          return nil
      }
}
