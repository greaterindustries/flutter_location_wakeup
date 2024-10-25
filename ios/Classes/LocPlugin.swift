import Flutter
import UIKit
import CoreLocation

public class LocPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    private let locationStreamHandler = LocationStreamHandler()
    private let visitStreamHandler = VisitStreamHandler()
    private var isMonitoringLocation = false
    private var isMonitoringVisits = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "loc", binaryMessenger: registrar.messenger())
        let locationEventChannel = FlutterEventChannel(name: "loc_stream", binaryMessenger: registrar.messenger())
        let visitEventChannel = FlutterEventChannel(name: "loc_visit_stream", binaryMessenger: registrar.messenger())
        
        let instance = LocPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        locationEventChannel.setStreamHandler(instance.locationStreamHandler)
        visitEventChannel.setStreamHandler(instance.visitStreamHandler)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startMonitoring":
            startMonitoring()
            result(nil)
        case "startVisitMonitoring":
            startVisitMonitoring()
            result(nil)
        case "stopMonitoring":
            stopMonitoring()
            result(nil)
        case "stopVisitMonitoring":
            stopVisitMonitoring()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startMonitoring() {
        guard CLLocationManager.significantLocationChangeMonitoringAvailable() else {
            locationStreamHandler.eventSink?(FlutterError(
                code: "SIGNIFICANT_LOCATION_MONITORING_UNAVAILABLE",
                message: "Significant location change monitoring is not available on this device",
                details: nil
            ))
            return
        }
        
        guard !isMonitoringLocation else { return }

        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
        isMonitoringLocation = true
    }
    
    private func startVisitMonitoring() {
        guard !isMonitoringVisits else { return }
        
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringVisits()
        isMonitoringVisits = true
    }

    private func stopMonitoring() {
        guard isMonitoringLocation else { return }
        
        locationManager.stopMonitoringSignificantLocationChanges()
        isMonitoringLocation = false
    }
    
    private func stopVisitMonitoring() {
        guard isMonitoringVisits else { return }
        
        locationManager.stopMonitoringVisits()
        isMonitoringVisits = false
    }
    
    // MARK: - CLLocationManagerDelegate Methods
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isMonitoringLocation,
              let location = locations.last,
              let eventSink = locationStreamHandler.eventSink else { return }
        
        let status = CLLocationManager.authorizationStatus()
        let permissionStatus = stringFromAuthorizationStatus(status: status)
        
        var locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "altitude": location.altitude,
            "horizontalAccuracy": location.horizontalAccuracy,
            "verticalAccuracy": location.verticalAccuracy,
            "course": location.course,
            "speed": location.speed,
            "timestamp": location.timestamp.timeIntervalSince1970,
            "permissionStatus": permissionStatus
        ]
        
        if let floor = location.floor {
            locationData["floorLevel"] = floor.level
        }
        
        eventSink(locationData)
    }
    
    public func locationManager(_ manager: CLLocationManager, didVisit visit: CLVisit) {
        guard isMonitoringVisits,
              let eventSink = visitStreamHandler.eventSink else { return }
        
        let status = CLLocationManager.authorizationStatus()
        let permissionStatus = stringFromAuthorizationStatus(status: status)
        
        let visitData: [String: Any] = [
            "arrivalDate": visit.arrivalDate.timeIntervalSince1970,
            "departureDate": visit.departureDate.timeIntervalSince1970,
            "latitude": visit.coordinate.latitude,
            "longitude": visit.coordinate.longitude,
            "horizontalAccuracy": visit.horizontalAccuracy,
            "permissionStatus": permissionStatus
        ]
        
        eventSink(visitData)
    }

    func stringFromAuthorizationStatus(status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways:
            return "granted"
        case .authorizedWhenInUse:
            //Not differentiating between when in use and always
            return "granted"
        case .denied:
            return "denied"
        case .restricted:
            return "restricted"
        case .notDetermined:
            return "notDetermined"
        @unknown default:
            return "unknown"
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let status = CLLocationManager.authorizationStatus()
        let permissionStatus = stringFromAuthorizationStatus(status: status)
        let errorDetails = ["permissionStatus": permissionStatus]
        
        // If we can't determine the error type, send to both if they're active
        if isMonitoringLocation {
            locationStreamHandler.eventSink?(FlutterError(
                code: "LOCATION_ERROR",
                message: error.localizedDescription,
                details: errorDetails
            ))
        }
        if isMonitoringVisits {
            visitStreamHandler.eventSink?(FlutterError(
                code: "VISIT_ERROR",
                message: error.localizedDescription,
                details: errorDetails
            ))
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Notify both handlers if they're active
        if isMonitoringLocation {
            handleAuthorizationChange(status: status, eventSink: locationStreamHandler.eventSink)
        }
        if isMonitoringVisits {
            handleAuthorizationChange(status: status, eventSink: visitStreamHandler.eventSink)
        }
        
        // If we're monitoring and status isn't determined yet, request authorization
        if (isMonitoringLocation || isMonitoringVisits) && (status == .notDetermined || status == .authorizedWhenInUse) {
            DispatchQueue.main.async {
                self.locationManager.requestAlwaysAuthorization()
            }
        }
    }

    private func handleAuthorizationChange(status: CLAuthorizationStatus, eventSink: FlutterEventSink?) {
        guard let eventSink = eventSink else { return }
        
        switch status {
        case .restricted:
            eventSink(FlutterError(
                code: "LOCATION_PERMISSION_DENIED",
                message: "Location permission restricted",
                details: ["permissionStatus": "restricted"]
            ))
        case .denied:
            eventSink(FlutterError(
                code: "LOCATION_PERMISSION_DENIED",
                message: "Location permission denied",
                details: ["permissionStatus": "denied"]
            ))
        case .authorizedAlways, .authorizedWhenInUse:
            break // Already authorized
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            break // Will handle this when requesting authorization
        @unknown default:
            eventSink(FlutterError(
                code: "UNKNOWN_LOCATION_ERROR",
                message: "Unknown location authorization status",
                details: nil
            ))
        }
    }
}

class LocationStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

class VisitStreamHandler: NSObject, FlutterStreamHandler {
    var eventSink: FlutterEventSink?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
