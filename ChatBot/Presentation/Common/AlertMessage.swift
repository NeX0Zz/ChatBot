import Foundation

/// A title + message alert shown through `.alert(item:)`-style bindings.
struct AlertMessage: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
