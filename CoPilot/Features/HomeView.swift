import SwiftUI
import FamilyControls
import ManagedSettings

struct SafeDrivingHomeView: View {
    @EnvironmentObject var appBlockingManager: AppBlockingManager
    @EnvironmentObject var model: MyModel
    @State private var isDriving = false
    @State private var isDiscouragedPresented = false
    @State private var tempSelection = FamilyActivitySelection()
    @State private var tempAppInfos: [BlockedAppInfo] = []
    
    // Mock data
    let recentTrips = [
        TripData(id: 1, date: "Today", duration: "25 min", appsBlocked: 3, score: 95),
        TripData(id: 2, date: "Yesterday", duration: "18 min", appsBlocked: 2, score: 88),
        TripData(id: 3, date: "Jun 17", duration: "42 min", appsBlocked: 7, score: 92)
    ]
    
    let weeklyStats = WeeklyStats(totalTrips: 12, totalTime: "4h 32m", averageScore: 91, appsBlocked: 34)
    
    var body: some View {
        NavigationView {
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
        }
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
                        .foregroundColor(isDriving ? .white : .blue)
                        .frame(width: 48, height: 48)
                        .background(isDriving ? Color.white.opacity(0.2) : Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isDriving ? "Driving Mode Active" : "Ready to Drive")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(isDriving ? .white : .primary)
                        
                        Text(isDriving ? "\(appBlockingManager.selectionToDiscourage.applications.count) apps blocked" : "Tap to start manual mode")
                            .font(.subheadline)
                            .foregroundColor(isDriving ? Color.white.opacity(0.8) : .secondary)
                    }
                }
                
                Spacer()
                
                if isDriving {
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
                    isDriving.toggle()
                    if isDriving {
                        appBlockingManager.setShieldRestrictions()
                    } else {
                        appBlockingManager.resetDiscouragedItems()
                    }
                }
            }) {
                Text(isDriving ? "End Driving Session" : "Start Driving Mode")
                    .font(.headline)
                    .foregroundColor(isDriving ? .white : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        isDriving ?
                        Color.white.opacity(0.2) :
                        Color.blue
                    )
                    .overlay(
                        isDriving ?
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1) :
                        nil
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(
            isDriving ?
            LinearGradient(colors: [Color.green, Color(red: 0.0, green: 0.7, blue: 0.4)], startPoint: .leading, endPoint: .trailing) :
                LinearGradient(colors: [Color.white, Color.white], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
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
                HStack(spacing: -8) {
                    let appTokens = Array(appBlockingManager.selectionToDiscourage.applicationTokens.prefix(5))

                    if appTokens.isEmpty {
                        // Show placeholder when no apps are selected
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 8)
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
                    Text("\(appBlockingManager.selectionToDiscourage.applications.count) apps")
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
                Text("Recent Trips")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    // View all action
                }) {
                    Text("View All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(recentTrips) { trip in
                    HStack(spacing: 12) {
                        Image(systemName: "car")
                            .font(.title3)
                            .foregroundColor(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trip.date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("\(trip.duration) • \(trip.appsBlocked) apps blocked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(trip.score)")
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
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Data Models
struct TripData: Identifiable {
    let id: Int
    let date: String
    let duration: String
    let appsBlocked: Int
    let score: Int
}

struct WeeklyStats {
    let totalTrips: Int
    let totalTime: String
    let averageScore: Int
    let appsBlocked: Int
}

// MARK: - Preview
struct SafeDrivingHomeView_Previews: PreviewProvider {
    static var previews: some View {
        SafeDrivingHomeView()
            .environmentObject(MyModel())
            .environmentObject(AppBlockingManager())
    }
}
