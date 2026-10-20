struct GenerationStatusDTO: Decodable, Sendable {
    let status: String
    let videoUrl: String?

    enum CodingKeys: String, CodingKey {
        case status
        case videoUrl = "video_url"
    }
}
