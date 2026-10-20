import SwiftUI

struct MainView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var subscriptionManager: SubscriptionManager

    var body: some View {
        ZStack {
            AppBackgroundView()
            VStack(spacing: 0) {
                header
                GeometryReader { proxy in
                    ScrollView {
                        content
                            .padding(.horizontal, AppSpacing.sideInset)
                            .padding(.vertical, 24)
                            .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        ZStack {
            HStack {
                CircleIconButton(icon: "iconHistory", label: "History") { router.push(.history(.chats)) }
                Spacer()
                CircleIconButton(icon: "iconSettings", label: "Settings") { router.push(.settings) }
            }
            if !subscriptionManager.isPremium {
                ProBadgeButton { router.presentPaywall() }
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.vertical, 8)
        .animation(.easeInOut(duration: 0.3), value: subscriptionManager.isPremium)
    }

    private var content: some View {
        VStack(spacing: 40) {
            VStack(spacing: 24) {
                Image("iconGenerate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(AppGradient.brand)
                    .accessibilityHidden(true)
                Text("Your AI tools,\nready to go")
                    .appFont(.title28Bold)
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                askField
            }
            MainPhotoVideoCard { router.push(.videoTemplates) }
        }
    }

    private var askField: some View {
        Button { router.push(.chat(id: nil)) } label: {
            HStack(spacing: 16) {
                Image("iconGenerate")
                    .resizable()
                    .scaledToFit()
                    .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                    .foregroundColor(AppColor.textPrimary)
                Text("Ask anything...")
                    .appFont(.body16)
                    .foregroundColor(AppColor.textHint)
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(AppColor.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppGradient.brand30, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ask anything")
    }
}
