import Flutter
import UIKit
import EventKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    
    // Set up method channels for calendar access (to register permissions in Settings)
    let calendarChannel = FlutterMethodChannel(
      name: "com.innermirror.app/calendar",
      binaryMessenger: controller.binaryMessenger
    )
    
    calendarChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "getEvents" else {
        result(FlutterMethodNotImplemented)
        return
      }
      
      // Access EventKit to register calendar permission in Settings
      let eventStore = EKEventStore()
      let args = call.arguments as? [String: Any] ?? [:]
      let startTime = args["startTime"] as? Int ?? 0
      let endTime = args["endTime"] as? Int ?? 0
      
      let startDate = Date(timeIntervalSince1970: Double(startTime) / 1000.0)
      let endDate = Date(timeIntervalSince1970: Double(endTime) / 1000.0)
      
      // Request calendar access - this will register the permission in Settings
      eventStore.requestAccess(to: .event) { (granted, error) in
        if granted {
          // Query events to actually access the calendar
          let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
          let events = eventStore.events(matching: predicate)
          
          // Convert events to dictionaries
          let eventList = events.map { event in
            return [
              "title": event.title ?? "",
              "startDate": Int(event.startDate.timeIntervalSince1970 * 1000),
              "endDate": Int(event.endDate.timeIntervalSince1970 * 1000),
              "description": event.notes ?? "",
              "location": event.location ?? "",
              "attendees": [],
              "isAllDay": event.isAllDay,
              "recurring": event.recurrenceRules != nil && !event.recurrenceRules!.isEmpty
            ]
          }
          
          result(eventList)
        } else {
          result([])
        }
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
