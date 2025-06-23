//
//  AppBlockingManager.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import FamilyControls
import ManagedSettings
import UIKit

class AppBlockingManager: ObservableObject {
    @Published var familySelection = FamilyActivitySelection()
    @Published var blockedAppsInfo: [BlockedAppInfo] = []
    private let store = ManagedSettingsStore()
    
    func saveBlockedApps(selection: FamilyActivitySelection, appInfos: [BlockedAppInfo]) {
        familySelection = selection
        blockedAppsInfo = appInfos
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }
    
    // Get blocked apps count
    var blockedAppsCount: Int {
        return blockedAppsInfo.count
    }
}

