import SwiftUI

/// One message of the transcript. Equatable so unrelated updates (typing, scrolling) skip its body.
struct ChatMessageRow: View, Equatable {
    let message: ChatMessage
    let showsRegenerate: Bool
    let onCopy: (ChatMessage) -> Void
    let onRegenerate: () -> Void

    static func == (lhs: ChatMessageRow, rhs: ChatMessageRow) -> Bool {
        lhs.message == rhs.message && lhs.showsRegenerate == rhs.showsRegenerate
    }

    var body: some View {
        switch message.role {
        case .user:
            ChatUserBubble(text: message.text)
        case .assistant:
            ChatAssistantBubble(
                text: message.text,
                showsRegenerate: showsRegenerate,
                onCopy: { onCopy(message) },
                onRegenerate: onRegenerate
            )
        }
    }
}
