import SwiftUI

/// Centered message with an optional retry button, shared by the error and empty states of the template screens.
struct TemplatesMessageView: View {
    let title: LocalizedStringKey
    var message: String?
    var retryTitle: LocalizedStringKey?
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(title)
                    .appFont(.title20Semibold)
                    .foregroundColor(AppColor.textPrimary)
                if let message {
                    Text(message)
                        .appFont(.body16)
                        .foregroundColor(AppColor.textHint)
                }
            }
            .multilineTextAlignment(.center)

            if let retryTitle, let onRetry {
                PrimaryGradientButton(retryTitle, action: onRetry)
                    .frame(width: 180)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
