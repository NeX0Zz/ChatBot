import Foundation
import Testing
@testable import ChatBot

@Suite("VideoTemplateMapper")
struct VideoTemplateMapperTests {
    private func dto(
        id: Int = 1,
        templateId: Int = 11,
        name: String = "Name",
        category: String? = "Cat",
        prompt: String? = "Prompt",
        duration: Int? = 8,
        qualities: [String]? = ["720p"],
        previewSmall: String? = nil,
        previewLarge: String? = nil,
        isActive: Bool? = true
    ) -> TemplateDTO {
        TemplateDTO(
            id: id,
            templateId: templateId,
            name: name,
            category: category,
            prompt: prompt,
            duration: duration,
            qualities: qualities,
            previewSmall: previewSmall,
            previewLarge: previewLarge,
            isActive: isActive
        )
    }

    @Test("Copies scalar fields")
    func copiesFields() {
        let template = VideoTemplateMapper.map(dto(id: 3, templateId: 33, name: "Dance", prompt: "Make it dance", duration: 10))

        #expect(template.id == 3)
        #expect(template.templateId == 33)
        #expect(template.name == "Dance")
        #expect(template.prompt == "Make it dance")
        #expect(template.duration == 10)
    }

    @Test("Strips the leading emoji from categories", arguments: [
        ("📈 Trending", "Trending"),
        ("✨ Other", "Other"),
        ("🎬  Movie Scenes", "Movie Scenes"),
        ("Plain", "Plain"),
        ("3D Effects", "3D Effects"),
        ("Fun 🎉", "Fun 🎉")
    ])
    func stripsEmoji(raw: String, expected: String) {
        #expect(VideoTemplateMapper.cleanCategory(raw) == expected)
    }

    @Test("Strips an emoji that carries a variation selector")
    func stripsEmojiWithVariationSelector() {
        #expect(VideoTemplateMapper.cleanCategory("❤️ Love") == "Love")
    }

    @Test("Missing or empty category becomes Other", arguments: [nil, ""] as [String?])
    func defaultCategory(raw: String?) {
        #expect(VideoTemplateMapper.cleanCategory(raw) == "Other")
    }

    @Test("A category made only of symbols is kept as is")
    func symbolOnlyCategory() {
        #expect(VideoTemplateMapper.cleanCategory("🔥") == "🔥")
    }

    @Test("Category in the mapped template is cleaned")
    func mapsCategory() {
        #expect(VideoTemplateMapper.map(dto(category: "📈 Trending")).category == "Trending")
        #expect(VideoTemplateMapper.map(dto(category: nil)).category == "Other")
    }

    @Test("Large preview wins over small")
    func prefersLargePreview() {
        let template = VideoTemplateMapper.map(dto(previewSmall: "https://x.test/s.mp4", previewLarge: "https://x.test/l.mp4"))

        #expect(template.previewURL?.absoluteString == "https://x.test/l.mp4")
    }

    @Test("Falls back to the small preview")
    func fallsBackToSmallPreview() {
        let template = VideoTemplateMapper.map(dto(previewSmall: "https://x.test/s.mp4", previewLarge: nil))

        #expect(template.previewURL?.absoluteString == "https://x.test/s.mp4")
    }

    @Test("No previews means no preview URL")
    func noPreview() {
        #expect(VideoTemplateMapper.map(dto()).previewURL == nil)
    }

    @Test("Unknown qualities are dropped and order is kept")
    func dropsUnknownQualities() {
        let template = VideoTemplateMapper.map(dto(qualities: ["1080p", "4k", "360p", "", "720p"]))

        #expect(template.qualities == [.p1080, .p360, .p720])
    }

    @Test("Missing qualities map to an empty list")
    func missingQualities() {
        #expect(VideoTemplateMapper.map(dto(qualities: nil)).qualities.isEmpty)
    }

    @Test("Duration defaults to five seconds")
    func defaultDuration() {
        #expect(VideoTemplateMapper.map(dto(duration: nil)).duration == 5)
    }

    @Test("Missing prompt becomes an empty string")
    func defaultPrompt() {
        #expect(VideoTemplateMapper.map(dto(prompt: nil)).prompt == "")
    }
}
