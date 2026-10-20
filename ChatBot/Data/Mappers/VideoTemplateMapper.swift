import Foundation

enum VideoTemplateMapper {
    static func map(_ dto: TemplateDTO) -> VideoTemplate {
        VideoTemplate(
            id: dto.id,
            templateId: dto.templateId,
            name: dto.name,
            category: cleanCategory(dto.category),
            prompt: dto.prompt ?? "",
            previewURL: (dto.previewLarge ?? dto.previewSmall).flatMap(URL.init(string:)),
            duration: dto.duration ?? 5,
            qualities: (dto.qualities ?? []).compactMap(VideoQuality.init(rawValue:))
        )
    }

    /// Catalog categories come with a leading emoji ("📈 Trending"); the chips show plain titles.
    static func cleanCategory(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Other" }
        // Emoji may carry a variation selector (U+FE0F), which counts as alphanumeric, so test letters and digits explicitly.
        let scalars = raw.unicodeScalars.drop { !$0.properties.isAlphabetic && !CharacterSet.decimalDigits.contains($0) }
        let title = String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? raw : title
    }
}
