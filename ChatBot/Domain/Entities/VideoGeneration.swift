import Foundation

struct VideoGeneration: Identifiable, Hashable, Sendable {
    enum Status: Hashable, Sendable {
        case inProgress
        case succeeded(videoURL: URL)
        case failed(message: String)
    }

    let id: UUID
    var remoteId: String?
    let templateId: Int
    let templateName: String
    /// File name of the prepared source frame inside the generations folder; kept for "Try again".
    let sourceImageFileName: String
    let format: VideoFormat
    let quality: VideoQuality
    var status: Status
    /// The result has not been opened yet; drives the "New" badge in History.
    var isNew: Bool
    let createdAt: Date

    var isInProgress: Bool {
        if case .inProgress = status { return true }
        return false
    }

    var videoURL: URL? {
        if case let .succeeded(url) = status { return url }
        return nil
    }
}
