//
//  PermissionsViewModel.swift
//  CoPilot
//
//  Created by Zachary Farmer on 7/10/25.
//
import Foundation

class PermissionsViewModel: ObservableObject {
    @Published var toggles: [PermissionType: Bool] = {
        var initial = [PermissionType: Bool]()
        for permission in PermissionType.allCases {
            initial[permission] = false
        }
        return initial
    }()
}
