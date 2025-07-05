import SwiftUI
import FamilyControls
import ManagedSettings

//// First, create a view to display individual app icons
struct AppIconView: View {
    let token: ApplicationToken
    
    var body: some View {
        // Use the FamilyControls Label initializer that takes an ApplicationToken
        Label(token)
            .labelStyle(.iconOnly)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
