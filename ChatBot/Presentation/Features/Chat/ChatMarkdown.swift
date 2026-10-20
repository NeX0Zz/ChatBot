import Foundation
import SwiftUI

/// Turns an assistant reply into styled text. Block syntax that `Text` cannot lay out (lists, headings)
/// is reduced to plain lines first, so line breaks and bullets survive.
enum ChatMarkdown {
    static func attributedString(from text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard var result = try? AttributedString(markdown: normalizedBlocks(in: text), options: options) else {
            return AttributedString(text)
        }
        for run in result.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            result[run.range].font = AppFont.button16Semibold.font
            result[run.range].foregroundColor = AppColor.textPrimary
        }
        return result
    }

    private static func normalizedBlocks(in text: String) -> String {
        text
            .components(separatedBy: "\n")
            .map(normalizedLine)
            .joined(separator: "\n")
    }

    private static func normalizedLine(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if let heading = headingText(in: trimmed) {
            return "**\(heading)**"
        }
        for marker in ["- ", "* ", "+ "] where trimmed.hasPrefix(marker) {
            return "• " + trimmed.dropFirst(marker.count)
        }
        return line
    }

    private static func headingText(in line: String) -> String? {
        let hashes = line.prefix { $0 == "#" }
        guard (1...6).contains(hashes.count) else { return nil }
        let rest = line.dropFirst(hashes.count)
        guard rest.first == " " else { return nil }
        return rest.trimmingCharacters(in: .whitespaces)
    }
}
