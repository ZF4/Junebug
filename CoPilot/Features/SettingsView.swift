//
//  SettingsView.swift
//  CoPilot
//
//  Created by Zachary Farmer on 7/5/25.
//

import SwiftUI

enum SettingsSelections {
    case deleteData
    case unblockApps
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = PermissionsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Beta Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer(minLength: 0)
                
                Button {
                    /// Dismissing Sheet
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundStyle(Color.gray, Color.primary.opacity(0.1))
                }
            }
            .padding(.bottom, 10)
            
            
            //MARK: Permissions
            Text("Permissions")
                .foregroundStyle(Color.gray)
            
            VStack(spacing: 0) {
                ForEach(PermissionType.allCases) { permission in
                    PermissionsToggle(
                        permission: permission,
                        isOn: Binding(
                            get: { viewModel.toggles[permission] ?? false },
                            set: { viewModel.toggles[permission] = $0 }
                        )
                    )
                }
            }
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            //MARK: Permissions
            Text("Application")
                .foregroundStyle(Color.gray)
            
            VStack(spacing: 0) {
                ForEach(ResetButtonType.allCases) { button in
                    ResetButtons(
                        resetButtonType: button
                    )
                }

            }
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text("This app is designed to block your selected apps if it has been terminated. To ensure accurate data and uninterrupted functionality, please keep this app running in the background. We’re actively working on a better solution. In the meantime, you can tap the 'Unblock All' button to prevent unintended blocking when this app closes.")
                .foregroundStyle(Color.secondary)
                .font(.system(size: 13))
            
            Text("This app is still in early beta. Please report any bugs or suggestions to the developer at: zf.codes@gmail.com")
                .foregroundStyle(Color.secondary)
                .font(.system(size: 13))
            
            Text("v1.0 beta")
                .font(.caption)
                .foregroundStyle(.gray)
            
        }
    }
}

struct PermissionsToggle: View {
    let permission: PermissionType
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: permission.iconName)
                    .foregroundColor(.white)
            }

            Text(permission.rawValue)
                .foregroundColor(.white)
                .fontWeight(.semibold)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}


enum PermissionType: String, CaseIterable, Identifiable {
    case pushNotifications = "Push Notifications"
    case locationTracking = "Foreground Location"
    case cameraAccess = "Background Location"
    case microphoneAccess = "Screen Time Access"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .pushNotifications: return "bell"
        case .locationTracking: return "location.fill"
        case .cameraAccess: return "location"
        case .microphoneAccess: return "inset.filled.rectangle.and.person.filled"
        }
    }
}

struct ResetButtons: View {
    let resetButtonType: ResetButtonType
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: resetButtonType.iconName)
                    .foregroundColor(.white)
            }
            Text(resetButtonType.rawValue)
            
            Spacer()
            
            Button(action: {}) {
                Text(resetButtonType.buttonLabel)
                    .foregroundStyle(Color.white)
            }
            .frame(width: 75)
            .padding(10)
            .background(Color.red.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .padding()
    }
}

enum ResetButtonType: String, CaseIterable, Identifiable {
    case resetStats = "Reset stats"
    case unblockApps = "Unblock apps"
    
    var id: String { rawValue }
    
    var buttonLabel: String {
        switch self {
        case .resetStats: return "Reset"
        case .unblockApps: return "Unblock"
        }
    }
    
    var iconName: String {
        switch self {
        case .resetStats: return "xmark.square"
        case .unblockApps: return "lifepreserver"
        }
    }
}


#Preview {
    SafeDrivingHomeView()
        .environmentObject(AppBlockingManager())
}
