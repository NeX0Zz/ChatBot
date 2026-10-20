import Foundation

enum VideoGenerationPersistenceMapper {
    private enum StatusKey {
        static let inProgress = "inProgress"
        static let succeeded = "succeeded"
        static let failed = "failed"
    }

    static func toStored(_ generation: VideoGeneration) -> StoredVideoGeneration {
        let statusKey: String
        var videoURL: URL?
        var errorMessage: String?
        switch generation.status {
        case .inProgress:
            statusKey = StatusKey.inProgress
        case let .succeeded(url):
            statusKey = StatusKey.succeeded
            videoURL = url
        case let .failed(message):
            statusKey = StatusKey.failed
            errorMessage = message
        }
        return StoredVideoGeneration(
            id: generation.id,
            remoteId: generation.remoteId,
            templateId: generation.templateId,
            templateName: generation.templateName,
            sourceImageFileName: generation.sourceImageFileName,
            format: generation.format.rawValue,
            quality: generation.quality.rawValue,
            status: statusKey,
            videoURL: videoURL,
            errorMessage: errorMessage,
            isNew: generation.isNew,
            createdAt: generation.createdAt
        )
    }

    static func toDomain(_ stored: StoredVideoGeneration) -> VideoGeneration {
        let status: VideoGeneration.Status
        switch stored.status {
        case StatusKey.succeeded:
            if let url = stored.videoURL {
                status = .succeeded(videoURL: url)
            } else {
                status = .failed(message: stored.errorMessage ?? "")
            }
        case StatusKey.failed:
            status = .failed(message: stored.errorMessage ?? "")
        default:
            status = .inProgress
        }
        return VideoGeneration(
            id: stored.id,
            remoteId: stored.remoteId,
            templateId: stored.templateId,
            templateName: stored.templateName,
            sourceImageFileName: stored.sourceImageFileName,
            format: VideoFormat(rawValue: stored.format) ?? .portrait,
            quality: VideoQuality(rawValue: stored.quality) ?? .p720,
            status: status,
            isNew: stored.isNew,
            createdAt: stored.createdAt
        )
    }
}
