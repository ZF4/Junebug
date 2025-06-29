//
//  TripData.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/26/25.
//
import Foundation
import CoreLocation

struct TripDataModel: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    let distance: Double
    let averageSpeed: Double
    let maxSpeed: Double
    let startLocation: CLLocation
    let endLocation: CLLocation
    let route: [CLLocation]
    let appsBlocked: Int
    let safetyScore: Int
    let distractions: Int
}

//struct TripDetail {
//    let id: String
//    let date: String
//    let startTime: String
//    let endTime: String
//    let duration: String
//    let distance: String
//    let averageSpeed: String
//    let safetyScore: Int
//    let blockedAttempts: Int
//    let timeSaved: String
//    let streak: Int
//    let startLocation: String
//    let endLocation: String
//    let route: [CLLocationCoordinate2D]
//    let blockedApps: [BlockedApp]
//    let blockAttempts: [BlockAttempt]
//}
