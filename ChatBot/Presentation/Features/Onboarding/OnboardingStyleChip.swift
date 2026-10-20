import SwiftUI

/// Decorative template style chip of the video demo; the selected one gets a brand outline.
struct OnboardingStyleChip: View {
    let title: String
    var isSelected = false

    var body: some View {
        Text(title)
            .appFont(.caption13)
            .foregroundColor(AppColor.textPrimary.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppColor.textPrimary.opacity(0.1) : AppColor.surface80, in: Capsule())
            .overlay(outline)
    }

    @ViewBuilder
    private var outline: some View {
        if isSelected {
            Capsule().strokeBorder(AppGradient.brand, lineWidth: 1)
        } else {
            Capsule().strokeBorder(AppColor.stroke, lineWidth: 1)
        }
    }
}
