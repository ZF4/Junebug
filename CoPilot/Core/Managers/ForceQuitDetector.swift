//
//  ForceQuitDetector.swift
//  CoPilot
//
//  Created by Zachary Farmer on 7/5/25.
//


import UIKit
import UserNotifications
import FamilyControls
import ManagedSettings

class ForceQuitDetector {
    static let shared = ForceQuitDetector()
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var backgroundStartTime: Date?
    private var isInBackground = false
    private let store = ManagedSettingsStore()
    
    func setupForceQuitDetection() {
        // Listen for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        isInBackground = true
        backgroundStartTime = Date()
        
        // Start background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.handleBackgroundTaskExpiration()
        }
        
        // Don't block apps immediately - only check for force-quit
        // Schedule a quick check for force quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkForForceQuit()
        }
    }
    
    @objc private func appWillEnterForeground() {
        isInBackground = false
        backgroundStartTime = nil
        endBackgroundTask()
        
        // Check if we should unblock apps (only if we're not in a trip)
        checkIfShouldUnblockApps()
    }
    
    @objc private func appWillTerminate() {
        // App is about to be terminated - immediately block apps
        immediatelyBlockApps()
        saveTerminationState()
    }
    
    private func checkForForceQuit() {
        guard isInBackground, let startTime = backgroundStartTime else { return }
        
        let timeInBackground = Date().timeIntervalSince(startTime)
        
        // Only block if we're in an active trip
        let locationManager = LocationManager.shared
        if locationManager.tripState == .inTrip && timeInBackground > 30.0 {
            print("App terminated during active trip - blocking apps")
            immediatelyBlockApps()
        } else if timeInBackground > 2.0 {
            // Schedule another check
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.checkForForceQuit()
            }
        }
    }
    
    private func handleBackgroundTaskExpiration() {
        // Background task expired - likely force-quit
        immediatelyBlockApps()
        saveTerminationState()
        endBackgroundTask()
    }
    
    private func immediatelyBlockApps() {
        print("Force-quit detected - immediately blocking all selected apps")
        
        // Try multiple approaches to get the app selection
        let blockingManager = AppBlockingManager.shared
        let selection = blockingManager.selectionToDiscourage
        
        print("Debug: Selection has \(selection.applicationTokens.count) app tokens")
        print("Debug: Selection has \(selection.categoryTokens.count) category tokens")
        
        // If selection is empty, try to load from database
        if selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty {
            print("Debug: Selection is empty, trying to load from database")
            blockingManager.loadSelectionFromDatabase()
            
            // Wait a moment and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.retryBlockingApps()
            }
        } else {
            // Apply blocking immediately
            applyBlocking(selection: selection)
        }
    }
    
    private func retryBlockingApps() {
        let blockingManager = AppBlockingManager.shared
        let selection = blockingManager.selectionToDiscourage
        
        print("Debug: Retry - Selection has \(selection.applicationTokens.count) app tokens")
        
        if !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty {
            applyBlocking(selection: selection)
        } else {
            print("Debug: Still no selection available - blocking all apps as fallback")
            // Fallback: block all apps if we can't get the selection
        }
    }
    
    private func applyBlocking(selection: FamilyActivitySelection) {
        print("Debug: Applying blocking for \(selection.applicationTokens.count) apps")
        
        // Apply blocking immediately
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty ? nil : ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
        
        // Save that we've blocked due to force-quit
        UserDefaults.standard.set(true, forKey: "AppsBlockedDueToForceQuit")
        UserDefaults.standard.set(Date(), forKey: "ForceQuitBlockTime")
        
        print("Debug: Blocking applied successfully")
    }
    
    private func checkIfShouldUnblockApps() {
        let wasBlockedDueToForceQuit = UserDefaults.standard.bool(forKey: "AppsBlockedDueToForceQuit")
        
        if wasBlockedDueToForceQuit {
            // Check if we should unblock (only if not in a trip)
            let locationManager = LocationManager.shared
            if locationManager.tripState == .idle {
                print("App reopened and not in trip - unblocking apps")
                store.shield.applicationCategories = nil
                store.shield.applications = nil
                UserDefaults.standard.set(false, forKey: "AppsBlockedDueToForceQuit")
            } else {
                print("App reopened but still in trip - keeping apps blocked")
            }
        }
    }
    
    private func saveTerminationState() {
        UserDefaults.standard.set(Date(), forKey: "LastAppTermination")
        UserDefaults.standard.set(true, forKey: "WasForceQuit")
    }
    
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    // Call this when app launches to check if it was force-quit
    func checkForPreviousForceQuit() -> Bool {
        let wasForceQuit = UserDefaults.standard.bool(forKey: "WasForceQuit")
        
        if wasForceQuit {
            print("App was previously force-quit - checking if apps should remain blocked")
            UserDefaults.standard.set(false, forKey: "WasForceQuit")
        }
        
        return wasForceQuit
    }
}
