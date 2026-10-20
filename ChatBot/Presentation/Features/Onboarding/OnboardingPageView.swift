import SwiftUI

struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            titleBlock
            demo
            Spacer(minLength: 0)
        }
        .padding(.top, 56)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text(page.title)
                .appFont(.title28Bold)
                .foregroundColor(AppColor.textPrimary)
            Text(page.subtitle)
                .appFont(.body16)
                .foregroundColor(AppColor.textMuted)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppSpacing.sideInset)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .onboardingAppear(isActive: isActive)
    }

    @ViewBuilder
    private var demo: some View {
        switch page {
        case .chat: OnboardingChatDemo(isActive: isActive)
        case .video: OnboardingVideoDemo(isActive: isActive)
        }
    }
}
