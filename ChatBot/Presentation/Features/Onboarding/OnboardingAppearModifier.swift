import SwiftUI

/// Fades and lifts an onboarding element in when its page becomes active.
struct OnboardingAppearModifier: ViewModifier {
    let isActive: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive || reduceMotion ? 0 : 16)
            .animation(animation, value: isActive)
    }

    private var animation: Animation {
        if reduceMotion { return .easeInOut(duration: 0.25) }
        return isActive
            ? .spring(response: 0.55, dampingFraction: 0.85).delay(delay)
            : .easeOut(duration: 0.2)
    }
}

extension View {
    func onboardingAppear(isActive: Bool, delay: Double = 0) -> some View {
        modifier(OnboardingAppearModifier(isActive: isActive, delay: delay))
    }
}
