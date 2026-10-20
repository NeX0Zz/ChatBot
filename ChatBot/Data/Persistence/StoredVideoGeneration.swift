import Foundation

struct StoredVideoGeneration: Codable, Sendable {
    let id: UUID
    let remoteId: String?
    let templateId: Int
    let templateName: String
    let sourceImageFileName: String
    let format: String
    let quality: String
    /// One of `inProgress`, `succeeded`, `failed`.
    let status: String
    let videoURL: URL?
    let errorMessage: String?
    let isNew: Bool
    let createdAt: Date
}
