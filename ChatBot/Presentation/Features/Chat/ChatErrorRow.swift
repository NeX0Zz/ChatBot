import SwiftUI

/// Inline failure notice under the last user message.
struct ChatErrorRow: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(AppColor.failure)
                .accessibilityHidden(true)
            Text(message)
                .appFont(.caption13)
                .foregroundColor(AppColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: onRetry) {
                Text("Try again")
                    .appFont(.caption13Semibold)
                    .foregroundStyle(AppGradient.brand)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
}

struct ChatErrorRow_Previews: PreviewProvider {
    static var previews: some View {
        ChatErrorRow(message: "No internet connection. Check your network and try again.", onRetry: {})
            .padding()
            .background(AppColor.background)
    }
}
