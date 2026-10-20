import Foundation

/// Top notification shown for 2 seconds; can be swiped up to dismiss earlier.
struct Toast: Identifiable, Equatable {
    enum Style: Equatable {
        case success
        case failure
    }

    let id = UUID()
    let style: Style
    let title: String
    var message: String?

    static var copied: Toast { Toast(style: .success, title: String(localized: "Copied")) }
    static var copyFailed: Toast { Toast(style: .failure, title: String(localized: "Copy failed")) }
    static var uploadFailed: Toast { Toast(style: .failure, title: String(localized: "Upload failed")) }
    static var videoSaved: Toast {
        Toast(style: .success, title: String(localized: "Video saved"), message: String(localized: "You can find it in your Photos"))
    }
    static var saveFailed: Toast {
        Toast(style: .failure, title: String(localized: "Couldn’t save video"), message: String(localized: "Please try again"))
    }
}
