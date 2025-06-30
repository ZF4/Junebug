import Foundation
import ManagedSettings
import SwiftData
import FamilyControls

@Model
final class UserModel {
    @Attribute(.unique) var id: UUID
    var applicationTokensData: Data? // Store ApplicationToken array
    var categoryTokensData: Data? // Store ActivityCategoryToken array
    var lastUpdated: Date
    
    init() {
        self.id = UUID()
        self.applicationTokensData = nil
        self.categoryTokensData = nil
        self.lastUpdated = Date()
    }
    
    // Helper methods to work with FamilyActivitySelection
    func saveSelection(_ selection: FamilyActivitySelection) {
        self.applicationTokensData = try? JSONEncoder().encode(selection.applicationTokens)
        self.categoryTokensData = try? JSONEncoder().encode(selection.categoryTokens)
        self.lastUpdated = Date()
    }
    
    func loadSelection() -> FamilyActivitySelection? {
        var selection = FamilyActivitySelection()
        
        if let appTokensData = applicationTokensData {
            selection.applicationTokens = (try? JSONDecoder().decode(Set<ApplicationToken>.self, from: appTokensData)) ?? []
        }
        if let categoryTokensData = categoryTokensData {
            selection.categoryTokens = (try? JSONDecoder().decode(Set<ActivityCategoryToken>.self, from: categoryTokensData)) ?? []
        }
        
        return selection
    }
}
