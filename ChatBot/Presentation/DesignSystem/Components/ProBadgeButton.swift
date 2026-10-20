import SwiftUI

struct ProBadgeButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.system(size: 14, weight: .semibold))
                Text("PRO").appFont(.label14Semibold)
            }
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: AppSpacing.controlHeight)
            .background(AppGradient.brand, in: Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Upgrade to PRO")
    }
}

struct ProBadgeButton_Previews: PreviewProvider {
    static var previews: some View {
        ProBadgeButton {}.padding().background(AppColor.background)
    }
}
