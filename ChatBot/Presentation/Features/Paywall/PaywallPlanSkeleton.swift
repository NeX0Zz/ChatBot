import SwiftUI

/// Placeholder row shown while the plans are loading.
struct PaywallPlanSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            .fill(AppColor.surface40)
            .frame(height: 72)
            .shimmer()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .accessibilityHidden(true)
    }
}
