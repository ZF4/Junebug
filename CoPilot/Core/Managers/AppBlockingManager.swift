//
//  AppBlockingManager.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import FamilyControls
import ManagedSettings
import UIKit

private let _blockingManager = AppBlockingManager()

class AppBlockingManager: ObservableObject {
    @Published var selectionToDiscourage = FamilyActivitySelection()
    @Published var blockedAppsInfo: [BlockedAppInfo] = []
    private let store = ManagedSettingsStore()
    
    init() {
        selectionToDiscourage = FamilyActivitySelection()
    }
    
    class var shared: AppBlockingManager {
        return _blockingManager
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
    
    // Get blocked apps count
    var blockedAppsCount: Int {
        return blockedAppsInfo.count
    }
}

