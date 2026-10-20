import Foundation

struct ChatSuggestion: Identifiable, Hashable {
    let title: String
    let prompt: String

    var id: String { title }

    static let all: [ChatSuggestion] = [
        ChatSuggestion(title: String(localized: "Help me write an email"), prompt: String(localized: "Help me write a professional email")),
        ChatSuggestion(title: String(localized: "Explain it simply"), prompt: String(localized: "Explain this in simple terms: ")),
        ChatSuggestion(title: String(localized: "Translate a text"), prompt: String(localized: "Translate this text into English: ")),
        ChatSuggestion(title: String(localized: "Plan my day"), prompt: String(localized: "Help me plan my day"))
    ]
}
