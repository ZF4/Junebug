//
//  UserModel.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/26/25.
//

import Foundation
import SwiftData

//@Model
final class UserModel {
//    @Attribute(.unique) var id: UUID
    var applicationTokens: Data? // Holds application tokens for blocked appps
    var categoryTokens: Data? // Holds category tokens for blocked apps 
    
    init(applicationTokens: Data? = nil, categoryTokens: Data? = nil) {
//        self.id = UUID()
        self.applicationTokens = applicationTokens
        self.categoryTokens = categoryTokens
    }
}
