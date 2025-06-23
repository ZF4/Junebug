//
//  ContentView.swift
//  LockBox
//
//  Created by Brett Nguyen  on 3/14/24.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var isDiscouragedPresented = false
    @State private var isTimerSettingPresented = false
    @StateObject private var locationManager = LocationManager()
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var model: MyModel

    var body: some View {
        VStack(spacing: 10) {
            VStack(spacing: 30) {
                Text("Current Speed:")
                    .font(.headline)
                Text(String(format: "%.2f mph", locationManager.currentSpeedMph))
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(locationManager.speedThresholdReached ? .red : .primary)

                if locationManager.speedThresholdReached {
                    Text("🚨 You're going at least 15 mph!")
                        .foregroundColor(.red)
                        .font(.headline)
                    Text("Apps Blocked: \(model.selectionToDiscourage.applications.count )")
                } else {
                    Text("🟢 Below speed threshold")
                        .foregroundColor(.green)
                        .font(.headline)
                }
            }
            .padding()
            
            Button("Select Apps to Discourage") {
                isDiscouragedPresented = true
            }
            .frame(width: 300)
            .padding()
            .background(colorScheme == .dark ? Color.gray.opacity(0.6) : Color.white)
            .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            .cornerRadius(10)
            .shadow(radius: 1)
            
            
            Button("Stop Block") {
                MyModel.shared.resetDiscouragedItems()
            }
            .frame(width: 300)
            .padding()
            .background(colorScheme == .dark ? Color.gray.opacity(0.6) : Color.white)
            .foregroundStyle(colorScheme == .dark ? Color.white : Color.black)
            .cornerRadius(10)
            .shadow(radius: 1)
        }
        .familyActivityPicker(isPresented: $isDiscouragedPresented, selection: $model.selectionToDiscourage)
        .onChange(of: locationManager.speedThresholdReached) { oldValue, newValue in
            if newValue == true {
                MyModel.shared.setShieldRestrictions()
            }
        }
        .onAppear {
            locationManager.requestPermissionsAndStart()
        }
    }
}







struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MyModel())
    }
}
