//import SwiftUI
//import MapKit
//
//struct TripDetailView: View {
//    let trip: TripDetail
//    @Environment(\.dismiss) private var dismiss
//    @State private var selectedTab = 0
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 24) {
//                    // Trip Header
//                    tripHeaderView
//                    
//                    //Overview Content
//                    overviewContent
//                    
//                    Spacer(minLength: 20)
//                }
//                .padding(.horizontal, 16)
//            }
//            .background(Color(UIColor.systemGroupedBackground))
//            .navigationBarTitleDisplayMode(.inline)
//        }
//    }
//    
//    private var tripHeaderView: some View {
//        VStack(spacing: 16) {
//            // Score Circle
//            ZStack {
//                Circle()
//                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
//                    .frame(width: 120, height: 120)
//                
//                Circle()
//                    .trim(from: 0, to: CGFloat(trip.safetyScore) / 100)
//                    .stroke(
//                        LinearGradient(
//                            colors: scoreColors,
//                            startPoint: .topTrailing,
//                            endPoint: .bottomLeading
//                        ),
//                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
//                    )
//                    .frame(width: 120, height: 120)
//                    .rotationEffect(.degrees(-90))
//                    .animation(.easeInOut(duration: 1.0), value: trip.safetyScore)
//                
//                HStack {
//                    Spacer()
//                    VStack(spacing: 4) {
//                        Text("\(trip.safetyScore)")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .foregroundColor(.primary)
//                        
//                        Text("Safety Score")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                    }
//                    Spacer()
//                }
//            }
//            
//            // Trip Info
//            VStack(spacing: 8) {
//                Text(trip.date)
//                    .font(.title2)
//                    .fontWeight(.semibold)
//                    .foregroundColor(.primary)
//            }
//        }
//        .padding(24)
//        .background(Color(UIColor.secondarySystemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 16))
//    }
//    
//    private var overviewContent: some View {
//        VStack(spacing: 16) {
//            // Statistics Grid
//            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
//                StatCard(
//                    title: "Distance",
//                    value: trip.distance,
//                    icon: "location",
//                    color: .blue
//                )
//                
//                StatCard(
//                    title: "Duration",
//                    value: trip.duration,
//                    icon: "clock",
//                    color: .green
//                )
//                
//                StatCard(
//                    title: "Avg Speed",
//                    value: trip.averageSpeed,
//                    icon: "speedometer",
//                    color: .orange
//                )
//                
//                StatCard(
//                    title: "Apps Blocked",
//                    value: "\(trip.blockedAttempts)",
//                    icon: "shield.checkered",
//                    color: .purple
//                )
//            }
//            
//            // Timeline
//            timelineView
//        }
//    }
//    
//    private var appsContent: some View {
//        VStack(spacing: 16) {
//            // Blocked Apps Summary
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Blocked Apps")
//                    .font(.headline)
//                    .fontWeight(.semibold)
//                
//                Text("These apps were blocked during your drive to keep you focused.")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
//                    ForEach(trip.blockedApps, id: \.name) { app in
//                        VStack(spacing: 8) {
//                            // App icon placeholder
//                            RoundedRectangle(cornerRadius: 12)
//                                .fill(Color.gray.opacity(0.2))
//                                .frame(width: 50, height: 50)
//                                .overlay(
//                                    Image(systemName: "app")
//                                        .font(.title2)
//                                        .foregroundColor(.gray)
//                                )
//                            
//                            Text(app.name)
//                                .font(.caption)
//                                .lineLimit(1)
//                                .foregroundColor(.primary)
//                        }
//                    }
//                }
//            }
//            .padding(16)
//            .background(Color(UIColor.secondarySystemGroupedBackground))
//            .clipShape(RoundedRectangle(cornerRadius: 12))
//            
//            // Block Attempts
//            if !trip.blockAttempts.isEmpty {
//                VStack(alignment: .leading, spacing: 12) {
//                    Text("Block Attempts")
//                        .font(.headline)
//                        .fontWeight(.semibold)
//                    
//                    Text("Times you tried to use blocked apps during this trip.")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    ForEach(trip.blockAttempts, id: \.timestamp) { attempt in
//                        HStack {
//                            Image(systemName: "shield.fill")
//                                .foregroundColor(.red)
//                                .frame(width: 20)
//                            
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(attempt.appName)
//                                    .font(.subheadline)
//                                    .fontWeight(.medium)
//                                
//                                Text(formatTime(attempt.timestamp))
//                                    .font(.caption)
//                                    .foregroundColor(.secondary)
//                            }
//                            
//                            Spacer()
//                            
//                            Text("Blocked")
//                                .font(.caption)
//                                .fontWeight(.medium)
//                                .foregroundColor(.red)
//                                .padding(.horizontal, 8)
//                                .padding(.vertical, 4)
//                                .background(Color.red.opacity(0.1))
//                                .clipShape(RoundedRectangle(cornerRadius: 4))
//                        }
//                        .padding(.vertical, 8)
//                        
//                        if attempt.timestamp != trip.blockAttempts.last?.timestamp {
//                            Divider()
//                        }
//                    }
//                }
//                .padding(16)
//                .background(Color(UIColor.secondarySystemGroupedBackground))
//                .clipShape(RoundedRectangle(cornerRadius: 12))
//            }
//        }
//    }
//    
//    private var timelineView: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Trip Timeline")
//                .font(.headline)
//                .fontWeight(.semibold)
//            
//            VStack(spacing: 12) {
//                TimelineItem(
//                    time: trip.startTime,
//                    title: "Trip Started",
//                    subtitle: trip.startLocation,
//                    icon: "play.circle.fill",
//                    color: .green
//                )
//                
//                if trip.blockedAttempts > 0 {
//                    TimelineItem(
//                        time: "During trip",
//                        title: "Apps Blocked",
//                        subtitle: "\(trip.blockedAttempts) attempts blocked",
//                        icon: "shield.fill",
//                        color: .red
//                    )
//                }
//                
//                TimelineItem(
//                    time: trip.endTime,
//                    title: "Trip Ended",
//                    subtitle: trip.endLocation,
//                    icon: "stop.circle.fill",
//                    color: .red
//                )
//            }
//        }
//        .padding(16)
//        .background(Color(UIColor.secondarySystemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//    
//    private var scoreColors: [Color] {
//        if trip.safetyScore >= 90 {
//            return [.green, .mint]
//        } else if trip.safetyScore >= 70 {
//            return [.orange, .yellow]
//        } else {
//            return [.red, .pink]
//        }
//    }
//    
//    private func formatTime(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.timeStyle = .short
//        return formatter.string(from: date)
//    }
//}
//
//// MARK: - Supporting Views
//struct StatCard: View {
//    let title: String
//    let value: String
//    let icon: String
//    let color: Color
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            Image(systemName: icon)
//                .font(.title2)
//                .foregroundColor(color)
//                .frame(width: 40, height: 40)
//                .background(color.opacity(0.1))
//                .clipShape(Circle())
//            
//            Text(value)
//                .font(.title3)
//                .fontWeight(.bold)
//                .foregroundColor(.primary)
//            
//            Text(title)
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//        .frame(maxWidth: .infinity)
//        .padding(16)
//        .background(Color(UIColor.secondarySystemGroupedBackground))
//        .clipShape(RoundedRectangle(cornerRadius: 12))
//    }
//}
//
//struct TimelineItem: View {
//    let time: String
//    let title: String
//    let subtitle: String
//    let icon: String
//    let color: Color
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            Image(systemName: icon)
//                .font(.title3)
//                .foregroundColor(color)
//                .frame(width: 24)
//            
//            VStack(alignment: .leading, spacing: 2) {
//                Text(title)
//                    .font(.subheadline)
//                    .fontWeight(.medium)
//                    .foregroundColor(.primary)
//                
//                Text(subtitle)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            Text(time)
//                .font(.caption)
//                .foregroundColor(.secondary)
//        }
//    }
//}
//
//struct StatRow: View {
//    let label: String
//    let value: String
//    
//    var body: some View {
//        HStack {
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            Spacer()
//            
//            Text(value)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.primary)
//        }
//    }
//}
//
//struct MapView: UIViewRepresentable {
//    let route: [CLLocationCoordinate2D]
//    
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.isUserInteractionEnabled = false
//        return mapView
//    }
//    
//    func updateUIView(_ mapView: MKMapView, context: Context) {
//        if !route.isEmpty {
//            let polyline = MKPolyline(coordinates: route, count: route.count)
//            mapView.addOverlay(polyline)
//            
//            let region = MKCoordinateRegion(
//                center: route[route.count / 2],
//                latitudinalMeters: 5000,
//                longitudinalMeters: 5000
//            )
//            mapView.setRegion(region, animated: false)
//        }
//    }
//}
//
//// MARK: - Data Models
//
//
//struct BlockedApp {
//    let name: String
//    let icon: String?
//}
//
//struct BlockAttempt {
//    let appName: String
//    let timestamp: Date
//}
//
//// MARK: - Preview
//struct TripDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TripDetailView(trip: sampleTrip)
//    }
//    
//    static var sampleTrip: TripDetail {
//        TripDetail(
//            id: "1",
//            date: "Today, June 26",
//            startTime: "2:30 PM",
//            endTime: "3:15 PM",
//            duration: "45 min",
//            distance: "23.5 mi",
//            averageSpeed: "31 mph",
//            safetyScore: 92,
//            blockedAttempts: 7,
//            timeSaved: "12 min",
//            streak: 5,
//            startLocation: "Home",
//            endLocation: "Downtown",
//            route: [
//                CLLocationCoordinate2D(latitude: 33.5186, longitude: -86.8104),
//                CLLocationCoordinate2D(latitude: 33.5207, longitude: -86.8025)
//            ],
//            blockedApps: [
//                BlockedApp(name: "Instagram", icon: nil),
//                BlockedApp(name: "TikTok", icon: nil),
//                BlockedApp(name: "Messages", icon: nil),
//                BlockedApp(name: "Snapchat", icon: nil)
//            ],
//            blockAttempts: [
//                BlockAttempt(appName: "Instagram", timestamp: Date().addingTimeInterval(-1800)),
//                BlockAttempt(appName: "Messages", timestamp: Date().addingTimeInterval(-1200)),
//                BlockAttempt(appName: "TikTok", timestamp: Date().addingTimeInterval(-600))
//            ]
//        )
//    }
//}
