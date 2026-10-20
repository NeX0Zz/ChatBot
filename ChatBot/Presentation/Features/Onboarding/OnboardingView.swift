import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var page = OnboardingPage.chat
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            AppBackgroundView(glowOpacity: 0.5)
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(OnboardingPage.allCases) { item in
                        OnboardingPageView(page: item, isActive: hasAppeared && page == item)
                            .tag(item)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                bottomBar
            }
        }
        .onAppear { hasAppeared = true }
    }

    private var bottomBar: some View {
        VStack(spacing: 20) {
            OnboardingPagerIndicator(count: OnboardingPage.allCases.count, current: page.rawValue)
            PrimaryGradientButton("Continue", action: advance)
                .padding(.horizontal, AppSpacing.sideInset)
        }
    }

    private func advance() {
        guard let next = OnboardingPage(rawValue: page.rawValue + 1) else {
            onFinish()
            return
        }
        withAnimation(.easeInOut(duration: 0.3)) { page = next }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onFinish: {})
    }
}
