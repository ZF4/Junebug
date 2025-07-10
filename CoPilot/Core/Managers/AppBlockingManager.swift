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
        print("Debug: Attempting to save selection to database")
        guard let context = modelContext else { 
            print("Debug: No model context available for saving")
            return 
        }
        
        do {
            let users = try context.fetch(FetchDescriptor<UserModel>())
            let user: UserModel
            
            if let existingUser = users.first {
                user = existingUser
                print("Debug: Using existing user")
            } else {
                user = UserModel()
                context.insert(user)
                print("Debug: Created new user")
            }
            
            print("Debug: Saving selection with \(selectionToDiscourage.applicationTokens.count) app tokens")
            user.saveSelection(selectionToDiscourage)
            try context.save()
            print("Debug: Successfully saved selection to database")
        } catch {
            print("Error saving selection to database: \(error)")
        }
    }
    
    public func loadSelectionFromDatabase() {
        print("Debug: Attempting to load selection from database")
        guard let context = modelContext else { 
            print("Debug: No model context available")
            return 
        }
        
        do {
            let users = try context.fetch(FetchDescriptor<UserModel>())
            print("Debug: Found \(users.count) users in database")
            
            if let user = users.first,
               let savedSelection = user.loadSelection() {
                print("Debug: Successfully loaded selection with \(savedSelection.applicationTokens.count) app tokens")
                DispatchQueue.main.async {
                    self.selectionToDiscourage = savedSelection
                    print("Debug: Updated selectionToDiscourage with \(self.selectionToDiscourage.applicationTokens.count) app tokens")
                    // Apply the loaded restrictions
//                    self.setShieldRestrictions()
                }
            } else {
                print("Debug: No saved selection found in database")
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
