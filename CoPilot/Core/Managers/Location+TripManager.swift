//
//  TripState.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import Foundation
import CoreLocation
import UserNotifications
import Combine
import SwiftData

enum TripState {
    case idle
    case detecting
    case inTrip
    case ending
}

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    // Add a reference to the AppBlockingManager
    private var appBlockingManager: AppBlockingManager?
    
    // Add a method to set the AppBlockingManager
    func setAppBlockingManager(_ manager: AppBlockingManager) {
        self.appBlockingManager = manager
    }
    
    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    // Published Properties
    @Published var currentSpeedMph: Double = 0.0
    @Published var tripState: TripState = .idle
    @Published var isStillDriving: Bool = false
    @Published var currentTrip: TripDataModel?
    @Published var tripProgress: Double = 0.0 // 0.0 to 1.0

    // Trip Management
    private var tripStartTime: Date?
    private var tripStartLocation: CLLocation?
    private var tripRoute: [CLLocation] = []
    private var speedHistory: [Double] = []
    private var lastLocation: CLLocation?
    
    // Detection Thresholds
    private let speedThreshold = 15.0
    private let stopThreshold = 5.0
    private let sustainedTimeRequired = 10.0
    private let stopTimeRequired = 10.0
    
    // Trip Distance
    private var totalTripDistance: Double = 0.0
    
    // Timers
    private var detectionTimer: Timer?
    private var stopTimer: Timer?

    // Add ModelContext property
    private var modelContext: ModelContext?
    
    // Add method to set ModelContext
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadTripState()
    }
    
    // Add trip state persistence methods
    private func saveTripState() {
        guard let context = modelContext else { return }
        
        // Find or create active trip
        let descriptor = FetchDescriptor<TripDataModel>(
            predicate: #Predicate { $0.isActiveTrip == true }
        )
        
        do {
            let activeTrips = try context.fetch(descriptor)
            let activeTrip: TripDataModel
            
            if let existing = activeTrips.first {
                activeTrip = existing
                // Update existing trip data
                activeTrip.startTime = tripStartTime ?? Date()
                activeTrip.distance = totalTripDistance
                activeTrip.maxSpeed = speedHistory.max() ?? 0
                activeTrip.startLatitude = tripStartLocation?.coordinate.latitude ?? 0
                activeTrip.startLongitude = tripStartLocation?.coordinate.longitude ?? 0
                activeTrip.routeLatitudes = tripRoute.map { $0.coordinate.latitude }
                activeTrip.routeLongitudes = tripRoute.map { $0.coordinate.longitude }
                activeTrip.appsBlocked = appBlockingManager?.blockedAppsCount ?? 0
            } else {
                // Create new active trip
                activeTrip = TripDataModel(
                    startTime: tripStartTime ?? Date(),
                    endTime: Date(),
                    duration: 0,
                    distance: totalTripDistance,
                    averageSpeed: 0,
                    maxSpeed: speedHistory.max() ?? 0,
                    startLocation: tripStartLocation ?? CLLocation(latitude: 0, longitude: 0),
                    endLocation: manager.location ?? CLLocation(latitude: 0, longitude: 0),
                    route: tripRoute,
                    appsBlocked: appBlockingManager?.blockedAppsCount ?? 0,
                    safetyScore: calculateSafetyScore(),
                    distractions: 0
                )
                activeTrip.isActiveTrip = true
                context.insert(activeTrip)
            }
            
            // Update trip state
            activeTrip.saveTripState(tripState, speedHistory: speedHistory)
            
            try context.save()
        } catch {
            print("Error saving trip state: \(error)")
        }
    }
    
    private func loadTripState() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<TripDataModel>(
            predicate: #Predicate { $0.isActiveTrip == true }
        )
        
        do {
            let activeTrips = try context.fetch(descriptor)
            if let activeTrip = activeTrips.first {
                let (state, speedHistory) = activeTrip.loadTripState()
                
                // Restore trip state
                tripState = state
                self.speedHistory = speedHistory
                
                if state == .inTrip || state == .detecting {
                    isStillDriving = true
                    tripStartTime = activeTrip.startTime
                    tripStartLocation = activeTrip.startLocation
                    totalTripDistance = activeTrip.distance
                    tripRoute = activeTrip.route
                    
                    // Restore app blocking if trip is active
                    if state == .inTrip {
                        appBlockingManager?.setShieldRestrictions()
                    }
                }
            }
        } catch {
            print("Error loading trip state: \(error)")
        }
    }
    
    override init() {
        super.init()
        configure()
    }

    private func configure() {
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.activityType = .automotiveNavigation
        manager.distanceFilter = 10 // meters - update every 10m
    }

    func requestPermissionsAndStart() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation() // Use continuous updates for route tracking
    }

    func resumeLocationUpdatesAfterTermination() {
        manager.startUpdatingLocation()
    }
    
    // MARK: - Trip State Management
    private func evaluateTripState(speed: Double) {
        switch tripState {
        case .idle:
            if speed > speedThreshold {
                startDetection()
            }
            
        case .detecting:
            if speed < stopThreshold {
                resetDetection()
            }
            
        case .inTrip:
            if speed < stopThreshold {
                startEnding()
            }
            
        case .ending:
            if speed > speedThreshold {
                // Resume trip
                tripState = .inTrip
                stopTimer?.invalidate()
            }
        }
    }
    
    private func startDetection() {
        tripState = .detecting
        saveTripState()
        detectionTimer = Timer.scheduledTimer(withTimeInterval: sustainedTimeRequired, repeats: false) { [weak self] _ in
            self?.startTrip()
        }
    }
    
    private func resetDetection() {
        tripState = .idle
        detectionTimer?.invalidate()
    }
    
    func startTrip() {
        tripState = .inTrip
        isStillDriving = true
        tripStartTime = Date()
        tripStartLocation = manager.location
        tripRoute.removeAll()
        totalTripDistance = 0.0
        
        // Use the injected AppBlockingManager
        if let blockingManager = appBlockingManager {
            print("Using injected AppBlockingManager")
            print("Selected apps: \(blockingManager.selectionToDiscourage.applications.count)")
            blockingManager.setShieldRestrictions()
        } else {
            print("No AppBlockingManager injected, using shared instance")
            AppBlockingManager.shared.setShieldRestrictions()
        }
        
        saveTripState()
        NotificationCenter.default.post(name: .tripStarted, object: nil)
    }
    
    // Add this public method to LocationManager class
    func startManualTrip() {
        startTrip()
    }
    
    func startEnding() {
        tripState = .ending
        stopTimer = Timer.scheduledTimer(withTimeInterval: stopTimeRequired, repeats: false) { [weak self] _ in
            self?.endTrip()
        }
    }
    
    func endTrip() {
        tripState = .idle
        isStillDriving = false
        
        guard let startTime = tripStartTime,
              let startLocation = tripStartLocation,
              let endLocation = manager.location else { return }
        
        let trip = createTripData(startTime: startTime, startLocation: startLocation, endLocation: endLocation)
        currentTrip = trip
        
        // Save completed trip to SwiftData
        saveCompletedTrip(trip)
        
        // Remove app blocking automatically
        appBlockingManager?.resetDiscouragedItems()
        
        // Reset trip blocking
        NotificationCenter.default.post(name: .tripEnded, object: nil)
        
        // Reset state
        tripStartTime = nil
        tripStartLocation = nil
        tripRoute.removeAll()
        totalTripDistance = 0.0
        tripProgress = 0.0
    }
    
    private func saveCompletedTrip(_ trip: TripDataModel) {
        guard let context = modelContext else { return }
        
        // Mark any existing active trip as inactive
        let descriptor = FetchDescriptor<TripDataModel>(
            predicate: #Predicate { $0.isActiveTrip == true }
        )
        
        do {
            let activeTrips = try context.fetch(descriptor)
            for activeTrip in activeTrips {
                context.delete(activeTrip) // Delete the active trip
            }
            
            // Insert the completed trip (with isActiveTrip = false)
            trip.isActiveTrip = false
            context.insert(trip)
            try context.save()
            
            print("Debug: Deleted \(activeTrips.count) active trips, inserted 1 completed trip")
        } catch {
            print("Error saving completed trip: \(error)")
        }
    }
    
    private func createTripData(startTime: Date, startLocation: CLLocation, endLocation: CLLocation) -> TripDataModel {
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let distance = totalTripDistance
        let averageSpeed = distance / duration * 2.23694 // Convert to mph
        
        return TripDataModel(
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            distance: distance,
            averageSpeed: averageSpeed,
            maxSpeed: speedHistory.max() ?? 0,
            startLocation: startLocation,
            endLocation: endLocation,
            route: tripRoute,
            appsBlocked: appBlockingManager?.blockedAppsCount ?? 0,
            safetyScore: calculateSafetyScore(),
            distractions: 0 // Will be tracked during trip
        )
    }
    
    private func calculateSafetyScore() -> Int {
        // Calculate based on speed consistency
        let speedVariance = calculateSpeedVariance()
        
        var score = 100
        
        // Penalize high speed variance
        if speedVariance > 20 { score -= 20 }
        else if speedVariance > 10 { score -= 10 }
        
        return max(0, score)
    }
    
    private func calculateSpeedVariance() -> Double {
        guard speedHistory.count > 1 else { return 0 }
        let mean = speedHistory.reduce(0, +) / Double(speedHistory.count)
        let squaredDifferences = speedHistory.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(speedHistory.count)
    }


    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let speed = max(0, location.speed)
        let speedMph = speed * 2.23694
        
        DispatchQueue.main.async {
            self.currentSpeedMph = speedMph
            self.speedHistory.append(speedMph)
            
            if self.speedHistory.count > 100 {
                self.speedHistory.removeFirst()
            }
        }
        
        
        // Evaluate trip state
        evaluateTripState(speed: speedMph)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed: \(error)")
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let tripStarted = Notification.Name("tripStarted")
    static let tripEnded = Notification.Name("tripEnded")
}
