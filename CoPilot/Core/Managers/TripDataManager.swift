//
//  TripDataManager.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import Foundation
import CoreData

class TripDataManager: ObservableObject {
    static let shared = TripDataManager()
    
    @Published var recentTrips: [TripDataModel] = []
    
    private init() {
        loadRecentTrips()
    }
    
    func saveTrip(_ trip: TripDataModel) {
        // Save to Core Data
        recentTrips.insert(trip, at: 0)
        
        // Keep only last 50 trips
        if recentTrips.count > 50 {
            recentTrips = Array(recentTrips.prefix(50))
        }
    }
    
    private func loadRecentTrips() {
        // Load from Core Data
        // Implementation depends on your Core Data setup
    }
}
