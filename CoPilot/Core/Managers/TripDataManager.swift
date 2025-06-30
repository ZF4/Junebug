import Foundation
import SwiftData

class TripDataManager: ObservableObject {
    static let shared = TripDataManager()
    
    @Published var recentTrips: [TripDataModel] = []
    private var modelContext: ModelContext?
    
    private init() {}
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadRecentTrips()
    }
    
    func saveTrip(_ trip: TripDataModel) {
        guard let context = modelContext else { return }
        
        context.insert(trip)
        
        do {
            try context.save()
            loadRecentTrips() // Refresh the list
        } catch {
            print("Error saving trip: \(error)")
        }
    }
    
    private func loadRecentTrips() {
        guard let context = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<TripDataModel>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            recentTrips = try context.fetch(descriptor)
        } catch {
            print("Error loading trips: \(error)")
        }
    }
}
