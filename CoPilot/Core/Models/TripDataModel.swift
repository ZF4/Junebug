//
//  TripData.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/26/25.
//
import Foundation
import CoreLocation
import SwiftData

@Model
final class TripDataModel {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var distance: Double
    var averageSpeed: Double
    var maxSpeed: Double
    
    // Store coordinates as separate properties
    var startLatitude: Double
    var startLongitude: Double
    var endLatitude: Double
    var endLongitude: Double
    
    // Store route as coordinate arrays
    var routeLatitudes: [Double]
    var routeLongitudes: [Double]
    
    var appsBlocked: Int
    var safetyScore: Int
    var distractions: Int
    
    // Trip state persistence
    var tripState: String // "idle", "detecting", "inTrip", "ending"
    var isActiveTrip: Bool // Whether this is the current active trip
    var speedHistoryData: Data? // Store speed history as JSON
    
    init(startTime: Date, endTime: Date, duration: TimeInterval, distance: Double,
         averageSpeed: Double, maxSpeed: Double, startLocation: CLLocation,
         endLocation: CLLocation, route: [CLLocation], appsBlocked: Int,
         safetyScore: Int, distractions: Int) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.distance = distance
        self.averageSpeed = averageSpeed
        self.maxSpeed = maxSpeed
        self.startLatitude = startLocation.coordinate.latitude
        self.startLongitude = startLocation.coordinate.longitude
        self.endLatitude = endLocation.coordinate.latitude
        self.endLongitude = endLocation.coordinate.longitude
        self.routeLatitudes = route.map { $0.coordinate.latitude }
        self.routeLongitudes = route.map { $0.coordinate.longitude }
        self.appsBlocked = appsBlocked
        self.safetyScore = safetyScore
        self.distractions = distractions
        self.tripState = "idle"
        self.isActiveTrip = false
        self.speedHistoryData = nil
    }
    
    // Computed properties for easy access
    var startLocation: CLLocation {
        CLLocation(latitude: startLatitude, longitude: startLongitude)
    }
    
    var endLocation: CLLocation {
        CLLocation(latitude: endLatitude, longitude: endLongitude)
    }
    
    var route: [CLLocation] {
        zip(routeLatitudes, routeLongitudes).map {
            CLLocation(latitude: $0, longitude: $1)
        }
    }
    
    // Trip state methods
    func saveTripState(_ state: TripState, speedHistory: [Double] = []) {
        self.tripState = state.rawValue
        self.speedHistoryData = try? JSONEncoder().encode(speedHistory)
    }
    
    func loadTripState() -> (state: TripState, speedHistory: [Double]) {
        let state = TripState(rawValue: tripState) ?? .idle
        let speedHistory = (try? JSONDecoder().decode([Double].self, from: speedHistoryData ?? Data())) ?? []
        return (state, speedHistory)
    }
}

extension TripState: RawRepresentable {
    public typealias RawValue = String
    
    public init?(rawValue: String) {
        switch rawValue {
        case "idle": self = .idle
        case "detecting": self = .detecting
        case "inTrip": self = .inTrip
        case "ending": self = .ending
        default: return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .idle: return "idle"
        case .detecting: return "detecting"
        case .inTrip: return "inTrip"
        case .ending: return "ending"
        }
    }
}
