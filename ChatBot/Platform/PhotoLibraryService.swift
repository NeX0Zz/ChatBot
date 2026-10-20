import Photos

/// Photo library access: read permission before picking a photo, add-only permission for saving videos.
@MainActor
final class PhotoLibraryService {
    enum AccessResult {
        case granted
        case denied
    }

    func requestReadAccess() async -> AccessResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch status {
        case .authorized, .limited: return .granted
        default: return .denied
        }
    }

    func saveVideo(at fileURL: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.accessDenied
        }
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }
    }
}
