import SwiftUI

struct ChatHistoryRow: View {
    let chat: Chat

    var body: some View {
        HStack(spacing: 16) {
            Image("iconGenerate")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundStyle(AppGradient.brand)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.title)
                    .appFont(.button16Semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                Text(preview)
                    .appFont(.body14)
                    .foregroundColor(AppColor.textHint)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if chat.isPinned {
                Image("iconPin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                    .foregroundColor(AppColor.textPrimary.opacity(0.24))
                    .accessibilityLabel("Pinned")
            }
        }
        .padding(16)
        .background(AppColor.surface40, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .contentShape(Rectangle())
    }

    private var preview: String {
        chat.lastMessagePreview.split(whereSeparator: \.isNewline).joined(separator: " ")
    }
}
