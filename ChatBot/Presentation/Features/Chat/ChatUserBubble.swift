import SwiftUI

struct ChatUserBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .appFont(.body16)
            .foregroundColor(AppColor.textPrimary)
            .padding(16)
            .background(
                BubbleShape(topLeading: AppRadius.card, topTrailing: AppRadius.card, bottomTrailing: 0, bottomLeading: AppRadius.card)
                    .fill(AppGradient.brand90)
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityElement(children: .combine)
    }
}
