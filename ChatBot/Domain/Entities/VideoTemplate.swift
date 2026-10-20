import Foundation

struct VideoTemplate: Identifiable, Hashable, Sendable {
    let id: Int
    let templateId: Int
    let name: String
    let category: String
    let prompt: String
    let previewURL: URL?
    let duration: Int
    let qualities: [VideoQuality]
}
