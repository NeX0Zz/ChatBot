import SwiftUI

/// Growing prompt field (up to 3 lines, then it scrolls) with a Send button pinned to the trailing edge.
struct ChatInputBar: View {
    @ObservedObject var draft: ChatDraft
    let placeholder: LocalizedStringKey
    let isSendAllowed: Bool
    let autofocus: Bool
    let onSend: () -> Void

    @FocusState private var isFocused: Bool

    private var isSendEnabled: Bool {
        isSendAllowed && !draft.isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            TextField(
                "",
                text: $draft.text,
                prompt: Text(placeholder).foregroundColor(AppColor.textSecondary),
                axis: .vertical
            )
            .appFont(.body16)
            .foregroundColor(AppColor.textPrimary)
            .tint(AppColor.textPrimary)
            .lineLimit(1...3)
            .focused($isFocused)
            .frame(minHeight: AppSpacing.controlHeight)
            sendButton
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.vertical, 24)
        .background(
            BubbleShape(topLeading: AppRadius.card, topTrailing: AppRadius.card, bottomTrailing: 0, bottomLeading: 0)
                .fill(AppColor.surface)
                .ignoresSafeArea(edges: .bottom)
        )
        .task {
            guard autofocus else { return }
            try? await Task.sleep(nanoseconds: 350_000_000)
            isFocused = true
        }
    }

    private var sendButton: some View {
        Button(action: onSend) {
            Image("iconSend")
                .resizable()
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .foregroundColor(AppColor.textPrimary)
                .frame(width: AppSpacing.controlHeight, height: AppSpacing.controlHeight)
                .background(AppGradient.brand, in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(!isSendEnabled)
        .opacity(isSendEnabled ? 1 : 0.3)
        .animation(.easeInOut(duration: 0.2), value: isSendEnabled)
        .accessibilityLabel("Send")
    }
}
