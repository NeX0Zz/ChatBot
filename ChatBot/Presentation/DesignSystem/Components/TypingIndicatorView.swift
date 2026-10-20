import SwiftUI

/// "Assistant is typing" bubble shown while a chat response is being generated.
struct TypingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(AppGradient.brand).frame(width: 19, height: 19).modifier(pulse(delay: 0))
            Circle().fill(Color.white.opacity(0.1)).frame(width: 15, height: 15).modifier(pulse(delay: 0.2))
            Circle().fill(Color.white.opacity(0.1)).frame(width: 10, height: 10).modifier(pulse(delay: 0.4))
        }
        .padding(16)
        .background(
            BubbleShape(topLeading: AppRadius.card, topTrailing: AppRadius.card, bottomTrailing: AppRadius.card, bottomLeading: 0)
                .fill(AppColor.surface50)
        )
        .onAppear { isAnimating = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generating response")
    }

    private func pulse(delay: Double) -> PulseModifier {
        PulseModifier(isAnimating: isAnimating, delay: delay)
    }
}

private struct PulseModifier: ViewModifier {
    let isAnimating: Bool
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 0.7 : 1)
            .opacity(isAnimating ? 0.5 : 1)
            .animation(
                isAnimating
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(delay)
                    : .default,
                value: isAnimating
            )
    }
}

struct TypingIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        TypingIndicatorView().padding().background(AppColor.background)
    }
}
