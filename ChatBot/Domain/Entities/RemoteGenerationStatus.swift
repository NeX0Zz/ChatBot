import Foundation

/// Status of a generation job as reported by the backend.
enum RemoteGenerationStatus: Equatable, Sendable {
    case generating
    case succeeded(videoURL: URL)
    case failed
}
