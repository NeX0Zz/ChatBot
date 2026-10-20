import SwiftUI

/// Greeting and quick prompts shown before the first message.
struct ChatEmptyStateView: View {
    let onSelect: (ChatSuggestion) -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                title
                Text("Pick a suggestion below or ask your own question")
                    .appFont(.body14)
                    .foregroundColor(AppColor.textHint)
                    .multilineTextAlignment(.center)
            }
            ChatFlowLayout(spacing: 8) {
                ForEach(ChatSuggestion.all) { suggestion in
                    SuggestionChip(title: suggestion.title, size: .regular) { onSelect(suggestion) }
                }
            }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: some View {
        HStack(spacing: 0) {
            Text("Your ")
            Text("AI assistant").foregroundStyle(AppGradient.brand)
            Text(" for anything")
        }
        .appFont(.title20Semibold)
        .foregroundColor(AppColor.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your AI assistant for anything")
        .accessibilityAddTraits(.isHeader)
    }
}

struct ChatEmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        ChatEmptyStateView { _ in }.background(AppColor.background)
    }
}
