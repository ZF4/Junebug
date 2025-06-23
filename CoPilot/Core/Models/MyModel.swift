import Foundation
import FamilyControls
import ManagedSettings
import UIKit
import ManagedSettingsUI

private let _MyModel = MyModel()

class MyModel: ObservableObject {
    let store = ManagedSettingsStore()
    
    @Published var selectionToDiscourage: FamilyActivitySelection
    
    init() {
        selectionToDiscourage = FamilyActivitySelection()
    }
    
    class var shared: MyModel {
        return _MyModel
    }
    
    func resetDiscouragedItems() {
        store.shield.applicationCategories = nil
        store.shield.applications = nil
    }

    
    func setShieldRestrictions() {
        store.shield.applications = selectionToDiscourage.applicationTokens.isEmpty ? nil : selectionToDiscourage.applicationTokens
        store.shield.applicationCategories = selectionToDiscourage.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selectionToDiscourage.categoryTokens)
        // Apply the application configuration as needed
    }
    
}
