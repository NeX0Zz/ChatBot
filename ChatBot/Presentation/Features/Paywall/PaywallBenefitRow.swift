import SwiftUI

struct PaywallBenefitRow: View {
    let icon: String
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .foregroundStyle(AppGradient.brand)
                .accessibilityHidden(true)
            Text(title)
                .appFont(.body16Medium)
                .foregroundColor(AppColor.textPrimary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
