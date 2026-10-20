import SwiftUI

struct TemplateCardSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            .fill(AppColor.surface60)
            .aspectRatio(TemplateCardView.aspectRatio, contentMode: .fit)
            .shimmer()
            .accessibilityHidden(true)
    }
}
