import SwiftUI

/// Assistant reply with its Copy action and, for the final reply, Regenerate.
struct ChatAssistantBubble: View {
    let text: String
    let showsRegenerate: Bool
    let onCopy: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ChatMarkdown.attributedString(from: text))
                .appFont(.body16)
                .foregroundColor(AppColor.textPrimary.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            Rectangle()
                .fill(AppColor.fillSubtle)
                .frame(height: 1)
            HStack {
                actionButton(icon: "iconCopy", label: "Copy", action: onCopy)
                Spacer()
                if showsRegenerate {
                    actionButton(icon: "iconRegenerate", label: "Regenerate", action: onRegenerate)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 334, alignment: .leading)
        .background(
            BubbleShape(topLeading: AppRadius.card, topTrailing: AppRadius.card, bottomTrailing: AppRadius.card, bottomLeading: 0)
                .fill(AppColor.surface50)
        )
        .padding(.leading, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func actionButton(icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .foregroundColor(AppColor.textHint)
                .padding(10)
                .contentShape(Rectangle())
                .padding(-10)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(label)
    }
}
