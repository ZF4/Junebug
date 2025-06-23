import Foundation
import CoreLocation
import UserNotifications
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Can still use it statically
    
    private let manager = CLLocationManager()

    // 🔄 Published Properties for SwiftUI binding
    @Published var currentSpeedMph: Double = 0.0
    @Published var speedThresholdReached: Bool = false

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .automotiveNavigation
    }

    func requestPermissionsAndStart() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        manager.requestAlwaysAuthorization()
        manager.startMonitoringSignificantLocationChanges()
    }

    func resumeLocationUpdatesAfterTermination() {
        manager.startMonitoringSignificantLocationChanges()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let speed = max(0, location.speed) // prevent negative speeds
        let speedMph = speed * 2.23694
        DispatchQueue.main.async {
            self.currentSpeedMph = speedMph
            self.speedThresholdReached = speedMph > 15
        }

        if speedMph > 15 {
            triggerDrivingDetected()
        }
    }

    private func triggerDrivingDetected() {
        let content = UNMutableNotificationContent()
        content.title = "Driving Detected"
        content.body = "You're going over 15 mph."

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
