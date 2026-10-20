import SwiftUI

/// Chat tab of History: pinned and dated sections, swipe to rename or delete, empty state.
struct ChatHistoryListView: View {
    @Environment(\.container) private var container

    var body: some View {
        if let container {
            ChatHistoryScreen(viewModel: ChatHistoryViewModel(container: container))
        }
    }
}

private struct ChatHistoryScreen: View {
    @StateObject private var viewModel: ChatHistoryViewModel

    init(viewModel: @autoclosure @escaping () -> ChatHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .alertCard(isPresented: $viewModel.isRenamePresented) {
                AlertCard(
                    title: "Rename chat",
                    message: "Enter a new name for this chat",
                    text: $viewModel.renameText,
                    placeholder: "Chat name",
                    confirmTitle: "Save",
                    isConfirmEnabled: viewModel.isRenameConfirmEnabled,
                    onCancel: { viewModel.isRenamePresented = false },
                    onConfirm: viewModel.confirmRename
                )
            }
            .alertCard(isPresented: $viewModel.isDeletePresented) {
                AlertCard(
                    title: "Delete chat?",
                    message: "This chat will be removed from your history.",
                    confirmTitle: "Delete",
                    confirmStyle: .destructive,
                    onCancel: { viewModel.isDeletePresented = false },
                    onConfirm: { withAnimation(.easeInOut(duration: 0.3)) { viewModel.confirmDelete() } }
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.isLoaded {
            ProgressView().tint(AppColor.textPrimary)
        } else if viewModel.sections.isEmpty {
            EmptyStateView(
                icon: "iconEmptyChat",
                title: "No chats yet",
                subtitle: "Start a conversation to see\nyour history here"
            )
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(viewModel.sections) { section in
                    VStack(alignment: .leading, spacing: 16) {
                        Text(section.title)
                            .appFont(.title20Semibold)
                            .foregroundColor(AppColor.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        VStack(spacing: 12) {
                            ForEach(section.chats) { chat in
                                row(for: chat)
                                    .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sideInset)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private func row(for chat: Chat) -> some View {
        ChatSwipeRow(
            isOpen: viewModel.openRowId == chat.id,
            onOpenChange: { isOpen in viewModel.openRowId = isOpen ? chat.id : nil },
            onTap: { viewModel.open(chat) },
            onRename: { viewModel.requestRename(chat) },
            onDelete: { viewModel.requestDelete(chat) }
        ) {
            ChatHistoryRow(chat: chat)
        }
    }
}
