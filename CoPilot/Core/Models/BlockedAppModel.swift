// CoPilot/Core/Models/BlockedAppInfo.swift

import FamilyControls
import UIKit
import ManagedSettings

struct BlockedAppModel: Identifiable, Codable {
    var id = UUID()
    let token: ApplicationToken
    let displayName: String
    let bundleIdentifier: String
    // Store icon as Data for Codable compliance
    let iconData: Data?
    let timeStamp: Date?
    
    var icon: UIImage? {
        guard let iconData else { return nil }
        return UIImage(data: iconData)
    }
}
