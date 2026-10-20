import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(spacing: 16) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundStyle(AppGradient.brand)
            VStack(spacing: 8) {
                Text(title)
                    .appFont(.title28Bold)
                    .foregroundColor(AppColor.textPrimary)
                Text(subtitle)
                    .appFont(.body16)
                    .foregroundColor(AppColor.textHint)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 23)
        .accessibilityElement(children: .combine)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(
            icon: "iconEmptyChat",
            title: "No chats yet",
            subtitle: "Start a conversation to see\nyour history here"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background)
    }
}
