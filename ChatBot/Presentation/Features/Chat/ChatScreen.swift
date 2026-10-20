import SwiftUI

struct ChatScreen: View {
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject private var router: AppRouter

    init(viewModel: @autoclosure @escaping () -> ChatViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView(
                dateText: viewModel.dateText,
                isPinned: viewModel.isPinned,
                showsMenu: viewModel.hasMessages,
                onBack: { router.pop() },
                onMenu: { viewModel.isMenuPresented = true }
            )
            .background(AppColor.surface40.ignoresSafeArea(edges: .top))
            content
        }
        .background(AppColor.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ChatInputBar(
                draft: viewModel.draft,
                placeholder: viewModel.hasMessages ? "How can I help you?" : "Ask anything...",
                isSendAllowed: !viewModel.isGenerating,
                autofocus: viewModel.isNewChat,
                onSend: viewModel.send
            )
        }
        .toolbar(.hidden, for: .navigationBar)
        .actionMenu(isPresented: $viewModel.isMenuPresented, items: menuItems)
        .alertCard(isPresented: $viewModel.isDeleteAlertPresented) {
            AlertCard(
                title: "Delete chat?",
                message: "This chat will be removed from your history.",
                confirmTitle: "Delete",
                confirmStyle: .destructive,
                onCancel: { viewModel.isDeleteAlertPresented = false },
                onConfirm: {
                    viewModel.isDeleteAlertPresented = false
                    viewModel.deleteChat()
                }
            )
        }
        .sheet(isPresented: $viewModel.isSharePresented) {
            ShareSheet(items: [viewModel.transcript])
                .presentationDetents([.medium, .large])
        }
        .onDisappear { viewModel.cancel() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.hasMessages {
            ChatMessagesView(
                messages: viewModel.messages,
                phase: viewModel.phase,
                regenerableMessageId: viewModel.regenerableMessageId,
                onCopy: viewModel.copy,
                onRegenerate: viewModel.regenerate,
                onRetry: viewModel.retry
            )
        } else {
            ChatEmptyStateView { suggestion in
                viewModel.draft.text = suggestion.prompt
            }
            .transition(.opacity)
        }
    }

    private var menuItems: [ActionMenuItem] {
        [
            ActionMenuItem(title: "Share", icon: "iconShare") { viewModel.isSharePresented = true },
            ActionMenuItem(title: viewModel.isPinned ? "Unpin chat" : "Pin chat", icon: "iconPin") { viewModel.togglePin() },
            ActionMenuItem(title: "Delete chat", icon: "iconDelete", role: .destructive) { viewModel.isDeleteAlertPresented = true }
        ]
    }
}
