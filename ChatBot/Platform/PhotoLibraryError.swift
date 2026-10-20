import Foundation

enum PhotoLibraryError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        String(localized: "Allow access to Photos in Settings to save videos.")
    }
}
