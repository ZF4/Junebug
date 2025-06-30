import SwiftUI
import SwiftData
import FamilyControls
import ManagedSettings
import CoreLocation

struct SafeDrivingHomeView: View {
    @EnvironmentObject var appBlockingManager: AppBlockingManager
    @StateObject private var locationManager = LocationManager.shared
    
    // SwiftData integration
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserModel]
    @Query(sort: \TripDataModel.startTime, order: .reverse) private var allTrips: [TripDataModel]
    
    @State private var isDiscouragedPresented = false
    @State private var showingAlert = false
    @State private var viewAllClicked = false
    @State private var tempSelection = FamilyActivitySelection()
    @State private var tempAppInfos: [BlockedAppModel] = []
    
    var appOrApps: String {
        if appBlockingManager.blockedAppsCount == 1 {
            return "app"
        } else {
            return "apps"
        }
    }
    
    // Computed property for recent trips (non-active trips)
    private var recentTrips: [TripDataModel] {
        allTrips.filter { !$0.isActiveTrip }
    }
    
    // Computed property for current active trip
    private var activeTrip: TripDataModel? {
        allTrips.first { $0.isActiveTrip }
    }
    
    @State private var weeklyStats = WeeklyStatsModel(totalTrips: 0, totalTime: "0h 0m", averageScore: 0, appsBlocked: 0)
    
    // Computed property to get or create the user
    private var currentUser: UserModel {
        if let user = users.first {
            return user
        } else {
            let newUser = UserModel()
            modelContext.insert(newUser)
            try? modelContext.save()
            return newUser
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Driving Status Card
                        drivingStatusCard
                        
                        // Quick Stats
                        quickStatsView
                        
                        // Blocked Apps Section
                        blockedAppsView
                        
                        // Recent Trips
                        recentTripsView
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                }
                .familyActivityPicker(isPresented: $isDiscouragedPresented, selection: $appBlockingManager.selectionToDiscourage)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.97, green: 0.98, blue: 1.0), Color(red: 0.93, green: 0.94, blue: 0.99)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .navigationBarHidden(true)
                .onAppear {
                    locationManager.requestPermissionsAndStart()
                    locationManager.setAppBlockingManager(appBlockingManager)
                    locationManager.setModelContext(modelContext)
                    
                    loadUserData()
                    calculateWeeklyStats()
                }
                .onChange(of: allTrips) { _, _ in
                    calculateWeeklyStats()
                }
                .onReceive(NotificationCenter.default.publisher(for: .tripStarted)) { _ in
                    // Trip started - app blocking is handled by LocationManager
                }
                .onReceive(NotificationCenter.default.publisher(for: .tripEnded)) { _ in
                    // Trip ended - stats will update automatically via onChange
                }
            }
        }
    }
    
    // MARK: - SwiftData Methods
    private func setupAppBlockingManager() {
        // Inject the ModelContext into AppBlockingManager
        appBlockingManager.setModelContext(modelContext)
    }
    
    private func loadUserData() {
        // Data loading is now handled by AppBlockingManager
        setupAppBlockingManager()
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Junebug")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Stay focused, drive safe")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                // Settings action
            }) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
        .padding(.top, 8)
    }
    
    private var drivingStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "car")
                        .font(.title2)
                        .foregroundColor(locationManager.isStillDriving ? .white : .blue)
                        .frame(width: 48, height: 48)
                        .background(locationManager.isStillDriving ? Color.white.opacity(0.2) : Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(drivingStatusText)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(locationManager.isStillDriving ? .white : .primary)
                        
                        Text(drivingStatusSubtext)
                            .font(.subheadline)
                            .foregroundColor(locationManager.isStillDriving ? Color.white.opacity(0.8) : .secondary)
                    }
                }
                
                Spacer()
                
                if locationManager.isStillDriving {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.checkered")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if locationManager.isStillDriving {
                        // End current trip
                        locationManager.endTrip()
                    } else {
                        // Start manual mode
                        locationManager.startManualTrip()
                    }
                }
            }) {
                Text(locationManager.isStillDriving ? "End Driving Session" : "Start Manual Mode")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        locationManager.isStillDriving ?
                        Color.white.opacity(0.2) : Color.blue
                    )
                    .overlay(
                        locationManager.isStillDriving ?
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1) : nil
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(
            locationManager.isStillDriving ?
            LinearGradient(colors: [Color.green, Color(red: 0.0, green: 0.7, blue: 0.4)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    private var drivingStatusText: String {
        switch locationManager.tripState {
        case .idle:
            return "Ready to Drive"
        case .detecting:
            return "Detecting Driving..."
        case .inTrip:
            return "Driving Mode Active"
        case .ending:
            return "Ending Trip..."
        }
    }
    
    private var drivingStatusSubtext: String {
        switch locationManager.tripState {
        case .idle:
            return "Tap to start manual mode"
        case .detecting:
            return "Speed: \(String(format: "%.0f", locationManager.currentSpeedMph)) mph"
        case .inTrip:
            return "\(appBlockingManager.selectionToDiscourage.applications.count) \(appOrApps) blocked"
        case .ending:
            return "Stopping soon..."
        }
    }
    
    private var quickStatsView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("This Week")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text("\(weeklyStats.totalTrips)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("trips")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "shield.checkered")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text("Safety Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Text("\(weeklyStats.averageScore)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("avg score")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
        }
    }
    
    private var blockedAppsView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Blocked Apps")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    isDiscouragedPresented = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.subheadline)
                        Text("Manage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: -3) {
                    let appTokens = Array(appBlockingManager.selectionToDiscourage.applicationTokens.prefix(5))
                    
                    if appTokens.isEmpty {
                        // Show placeholder when no apps are selected
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.gray)
                                )
                        }
                    } else {
                        ForEach(Array(appTokens.enumerated()), id: \.offset) { index, token in
                            AppIconView(token: token)
                        }
                        
                        // Show +X more indicator if there are more than 5 apps
                        if appBlockingManager.selectionToDiscourage.applicationTokens.count > 5 {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                
                                Text("+\(appBlockingManager.selectionToDiscourage.applicationTokens.count - 5)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(appBlockingManager.selectionToDiscourage.applications.count) \(appOrApps)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("will be blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    private var recentTripsView: some View {
        VStack(spacing: 16) {
            HStack {
                HStack {
                    Text("Recent Trips")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    viewAllClicked.toggle()
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            if recentTrips.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "car")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                    
                    Text("No trips yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Your driving trips will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(Color.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTrips.prefix(viewAllClicked ? recentTrips.count : 3), id: \.startTime) { trip in
                        HStack(spacing: 12) {
                            Image(systemName: "car")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(formatTripDate(trip.startTime))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Text("\(formatDuration(trip.duration)) • \(trip.appsBlocked) \(appOrApps) blocked")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(trip.safetyScore)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("score")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    if viewAllClicked {
                        Text("Only the last 30 trips are saved")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
    
    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklyTrips = allTrips.filter { 
            $0.startTime >= weekAgo && !$0.isActiveTrip 
        }
        
        print("Debug: Total trips in database: \(allTrips.count)")
        print("Debug: Weekly trips: \(weeklyTrips.count)")
        print("Debug: Active trips: \(allTrips.filter { $0.isActiveTrip }.count)")
        
        let totalTrips = weeklyTrips.count
        let totalTime = weeklyTrips.reduce(0) { $0 + $1.duration }
        let averageScore = weeklyTrips.isEmpty ? 0 : weeklyTrips.reduce(0) { $0 + $1.safetyScore } / weeklyTrips.count
        let appsBlocked = weeklyTrips.reduce(0) { $0 + $1.appsBlocked }
        
        weeklyStats = WeeklyStatsModel(
            totalTrips: totalTrips,
            totalTime: formatDuration(totalTime),
            averageScore: averageScore,
            appsBlocked: appsBlocked
        )
    }
    
    private func formatTripDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview
struct SafeDrivingHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SafeDrivingHomeView()
            .environmentObject(AppBlockingManager())
    }
}
