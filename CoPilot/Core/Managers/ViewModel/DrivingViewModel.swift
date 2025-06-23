//
//  DrivingViewModel.swift
//  CoPilot
//
//  Created by Zachary Farmer on 5/26/25.
//


import Foundation

class DrivingViewModel: ObservableObject {
    init() {
        LocationManager.shared.requestPermissionsAndStart()
    }
}
