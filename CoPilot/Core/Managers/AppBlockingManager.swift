//
//  AppBlockingManager.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import FamilyControls
import ManagedSettings
import UIKit
import SwiftData

private let _blockingManager = AppBlockingManager()

class AppBlockingManager: ObservableObject {
    @Published var selectionToDiscourage = FamilyActivitySelection() {
        didSet {
            // Save to SwiftData whenever selection changes
            saveSelectionToDatabase()
        }
    }
    @Published var blockedAppsInfo: [BlockedAppModel] = []
    private let store = ManagedSettingsStore()
    
    // SwiftData context - will be injected
    var modelContext: ModelContext?
    
    init() {
        selectionToDiscourage = FamilyActivitySelection()
    }
    
    class var shared: AppBlockingManager {
        return _blockingManager
    }
    
    // MARK: - SwiftData Integration
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSelectionFromDatabase()
    }
    
    private func saveSelectionToDatabase() {
        guard let context = modelContext else { return }
        
        do {
            let users = try context.fetch(FetchDescriptor<UserModel>())
            let user: UserModel
            
            if let existingUser = users.first {
                user = existingUser
            } else {
                user = UserModel()
                context.insert(user)
            }
            
            user.saveSelection(selectionToDiscourage)
            try context.save()
        } catch {
            print("Error saving selection to database: \(error)")
        }
    }
    
    private func loadSelectionFromDatabase() {
        guard let context = modelContext else { return }
        
        do {
            let users = try context.fetch(FetchDescriptor<UserModel>())
            if let user = users.first,
               let savedSelection = user.loadSelection() {
                DispatchQueue.main.async {
                    self.selectionToDiscourage = savedSelection
                    // Apply the loaded restrictions
//                    self.setShieldRestrictions()
                }
            }
        } catch {
            print("Error loading selection from database: \(error)")
        }
    }
    
    // MARK: - Existing Methods
    func resetDiscouragedItems() {
        store.shield.applicationCategories = nil
        store.shield.applications = nil
        
        // Clear the selection and save to database
//        selectionToDiscourage = FamilyActivitySelection()
    }
    
    func setShieldRestrictions() {
        store.shield.applications = selectionToDiscourage.applicationTokens.isEmpty ? nil : selectionToDiscourage.applicationTokens
        store.shield.applicationCategories = selectionToDiscourage.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selectionToDiscourage.categoryTokens)
        // Apply the application configuration as needed
    }
    
    // Get blocked apps count
    var blockedAppsCount: Int {
        return selectionToDiscourage.applicationTokens.count
    }
}
