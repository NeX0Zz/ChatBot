struct TemplateDTO: Decodable, Sendable {
    let id: Int
    let templateId: Int
    let name: String
    let category: String?
    let prompt: String?
    let duration: Int?
    let qualities: [String]?
    let previewSmall: String?
    let previewLarge: String?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case templateId = "template_id"
        case name
        case category
        case prompt
        case duration
        case qualities
        case previewSmall = "preview_small"
        case previewLarge = "preview_large"
        case isActive = "is_active"
    }
}
