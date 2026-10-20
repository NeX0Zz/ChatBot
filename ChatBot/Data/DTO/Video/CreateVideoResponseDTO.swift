struct CreateVideoResponseDTO: Decodable, Sendable {
    let videoId: String

    enum CodingKeys: String, CodingKey {
        case videoId = "video_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // The backend may return the id either as a number or as a string.
        if let intId = try? container.decode(Int.self, forKey: .videoId) {
            videoId = String(intId)
        } else {
            videoId = try container.decode(String.self, forKey: .videoId)
        }
    }
}
