import Combine
import Foundation

/// Text typed into the input bar. Kept apart from the screen state so typing re-renders only the input bar.
@MainActor
final class ChatDraft: ObservableObject {
    @Published var text = ""

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmpty: Bool {
        trimmedText.isEmpty
    }
}
