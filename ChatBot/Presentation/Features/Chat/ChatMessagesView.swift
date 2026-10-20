import SwiftUI
import UIKit

/// Scrollable transcript. Sticks to the bottom as messages arrive and when the keyboard opens.
struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let phase: ChatViewModel.Phase
    let regenerableMessageId: ChatMessage.ID?
    let onCopy: (ChatMessage) -> Void
    let onRegenerate: () -> Void
    let onRetry: () -> Void

    private let bottomId = "chat-bottom"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(messages) { message in
                        ChatMessageRow(
                            message: message,
                            showsRegenerate: message.id == regenerableMessageId,
                            onCopy: onCopy,
                            onRegenerate: onRegenerate
                        )
                        .equatable()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    status
                    Color.clear.frame(height: 0).id(bottomId)
                }
                .padding(.horizontal, AppSpacing.sideInset)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .animation(.easeInOut(duration: 0.3), value: contentState)
            .onAppear { scrollToBottom(proxy, animated: false) }
            .onChange(of: contentState) { _ in scrollToBottom(proxy, animated: true) }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)) { _ in
                scrollToBottom(proxy, animated: true)
            }
        }
    }

    /// One value for "the bottom of the transcript changed", so a send that appends a message
    /// and starts generating triggers a single animation and a single scroll.
    private var contentState: ContentState {
        ContentState(messageCount: messages.count, phase: phase)
    }

    @ViewBuilder
    private var status: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .generating:
            TypingIndicatorView()
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        case let .failed(message):
            ChatErrorRow(message: message, onRetry: onRetry)
                .transition(.opacity)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        // Deferred to the next run loop: the new row must be laid out before it can be scrolled to.
        Task { @MainActor in
            if animated {
                withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(bottomId, anchor: .bottom) }
            } else {
                proxy.scrollTo(bottomId, anchor: .bottom)
            }
        }
    }
}

private struct ContentState: Equatable {
    let messageCount: Int
    let phase: ChatViewModel.Phase
}
