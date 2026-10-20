import SwiftUI

struct ReplaceButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("iconReplace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                Text("Replace")
                    .appFont(.body14)
            }
            .foregroundColor(AppColor.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: AppSpacing.controlHeight)
            .background(.ultraThinMaterial, in: Capsule())
            .background(AppColor.surface40, in: Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Replace photo")
    }
}
