

import SwiftUI
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import UIKit
import CoreLocation
import SwiftData

@main
struct CoPilotApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @StateObject var appBlockingManager = AppBlockingManager()
    @StateObject var store = ManagedSettingsStore()
    

    
    var body: some Scene {
        WindowGroup {
            SafeDrivingHomeView()
                .environmentObject(store)
                .environmentObject(appBlockingManager)
        }
        .modelContainer(for: [UserModel.self, TripDataModel.self])
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // ✅ Request Family Controls Authorization
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            } catch {
                print("Error for Family Controls: \(error)")
            }
        }
        
        // ✅ Resume LocationManager if relaunched due to location event
//        if launchOptions?[.location] != nil {
//            LocationManager.shared.resumeLocationUpdatesAfterTermination()
//        }

        return true
    }
}



