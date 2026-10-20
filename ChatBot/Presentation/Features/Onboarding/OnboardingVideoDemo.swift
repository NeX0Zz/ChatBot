import SwiftUI

/// Page 2: photo cards with the "Your photo" circle (cut from the exported frame) and style chips.
struct OnboardingVideoDemo: View {
    let isActive: Bool

    /// Region of the 390x844 exported frame that holds the cards, the circle and their badges.
    private let cropTop: CGFloat = 205
    private let cropBottom: CGFloat = 622
    private let frameSize = CGSize(width: 390, height: 844)

    var body: some View {
        VStack(spacing: 20) {
            cards.onboardingAppear(isActive: isActive)
            chips.onboardingAppear(isActive: isActive, delay: 0.2)
        }
        .padding(.top, 22)
    }

    private var cards: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / frameSize.width
            Image("imageOnboarding2Background")
                .resizable()
                .frame(width: proxy.size.width, height: frameSize.height * scale)
                .offset(y: -cropTop * scale)
        }
        .aspectRatio(frameSize.width / (cropBottom - cropTop), contentMode: .fit)
        .clipped()
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.05),
                    .init(color: .black, location: 0.95),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .accessibilityLabel("Photo cards turned into AI videos")
    }

    private var chips: some View {
        HStack(spacing: 8) {
            OnboardingStyleChip(title: "Clay")
            OnboardingStyleChip(title: "Cinematic")
            OnboardingStyleChip(title: "Cartoon", isSelected: true)
            OnboardingStyleChip(title: "Anime")
        }
        .accessibilityHidden(true)
    }
}
