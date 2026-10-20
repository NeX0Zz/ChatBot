import SwiftUI

struct ActionMenuItem: Identifiable {
    enum Role {
        case regular
        case destructive
    }

    let id = UUID()
    let title: LocalizedStringKey
    let icon: String
    var role: Role = .regular
    let action: () -> Void
}
