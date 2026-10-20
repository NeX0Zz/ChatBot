import SwiftUI

struct OnboardingPagerIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(AppGradient.brand) : AnyShapeStyle(Color.white.opacity(0.25)))
                    .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}
