import SwiftUI

/// Page 1: sample dialog with the orb, a user bubble, an assistant card and suggestion chips.
struct OnboardingChatDemo: View {
    let isActive: Bool

    var body: some View {
        VStack(spacing: 40) {
            Image("imageOrb")
                .resizable()
                .scaledToFit()
                .frame(width: 187, height: 187)
                .frame(width: 187, height: 127)
                .accessibilityHidden(true)
                .onboardingAppear(isActive: isActive)
            VStack(spacing: 12) {
                userBubble.onboardingAppear(isActive: isActive, delay: 0.15)
                assistantCard.onboardingAppear(isActive: isActive, delay: 0.3)
            }
            .frame(width: 326)
            chips.onboardingAppear(isActive: isActive, delay: 0.45)
        }
        .padding(.top, 76)
    }

    private var userBubble: some View {
        HStack {
            Spacer(minLength: 0)
            Text("Help me write a welcome email for a new teammate")
                .appFont(.field15)
                .foregroundColor(AppColor.textPrimary)
                .frame(maxWidth: 220, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    AppGradient.brand,
                    in: BubbleShape(topLeading: 20, topTrailing: 20, bottomTrailing: 6, bottomLeading: 20)
                )
        }
    }

    private var assistantCard: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColor.textPrimary)
                .frame(width: 28, height: 28)
                .background(AppGradient.brand, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome to the team, Alex!")
                    .appFont(.label14Semibold)
                    .foregroundStyle(AppGradient.brand)
                Text("We’re excited to have you on board. Here are a few tips for your first week…")
                    .appFont(.body14)
                    .foregroundColor(AppColor.textPrimary.opacity(0.85))
                    .frame(width: 230, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                AppColor.surface.opacity(0.9),
                in: BubbleShape(topLeading: 20, topTrailing: 20, bottomTrailing: 20, bottomLeading: 6)
            )
            .overlay(
                BubbleShape(topLeading: 20, topTrailing: 20, bottomTrailing: 20, bottomLeading: 6)
                    .strokeBorder(AppColor.strokeSubtle, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chips: some View {
        HStack(spacing: 8) {
            SuggestionChip(title: "Explain simply", size: .compact) {}
            SuggestionChip(title: "Plan my day", size: .compact) {}
            SuggestionChip(title: "Translate", size: .compact) {}
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
