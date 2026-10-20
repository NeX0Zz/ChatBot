import SwiftUI

struct RootView: View {
    let container: AppContainer

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var flow: AppFlow = .splash
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var autoplaySlots = AutoplaySlots()

    var body: some View {
        ZStack {
            switch flow {
            case .splash:
                SplashView(onFinish: finishSplash)
                    .transition(.opacity)
            case .onboarding:
                OnboardingView(onFinish: { setFlow(.onboardingPaywall) })
                    .transition(.opacity)
            case .onboardingPaywall:
                PaywallView(onClose: {
                    hasCompletedOnboarding = true
                    setFlow(.main)
                })
                .transition(.opacity)
            case .main:
                MainFlowView(router: container.router)
                    .transition(.opacity)
            }
        }
        .environment(\.container, container)
        .environment(\.thumbnailCache, container.thumbnailCache)
        .environmentObject(container.router)
        .environmentObject(container.subscriptionManager)
        .environmentObject(container.toastCenter)
        .environmentObject(autoplaySlots)
        .task {
            await container.chatStore.load()
            await container.videoCoordinator.load()
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .background else { return }
            Task { await container.chatStore.flush() }
        }
    }

    private func finishSplash() {
        setFlow(hasCompletedOnboarding ? .main : .onboarding)
        // Asked right after launch, once the app is active and the first real screen is visible.
        Task { await container.requestTrackingAuthorization() }
    }

    private func setFlow(_ newFlow: AppFlow) {
        withAnimation(.easeInOut(duration: 0.35)) {
            flow = newFlow
        }
    }
}
