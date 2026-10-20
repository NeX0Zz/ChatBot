import SwiftUI

struct PaywallScreen: View {
    @StateObject private var viewModel: PaywallViewModel
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var isCloseVisible = false

    init(viewModel: @autoclosure @escaping () -> PaywallViewModel, onClose: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onClose = onClose
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            AppBackgroundView(glowOpacity: 0.5)
            content
            closeButton
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .disabled(viewModel.isBusy)
        .animation(.easeInOut(duration: 0.3), value: viewModel.state.isLoading)
        .task { await viewModel.load() }
        .task { await revealCloseButton() }
        .onDisappear { viewModel.close() }
        .alertMessage($viewModel.alert)
    }

    // MARK: Content

    private var content: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    Image("imageOrb")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 143, height: 142)
                        .frame(width: 135, height: 92)
                        .accessibilityHidden(true)
                    VStack(spacing: 32) {
                        Text("Create anything\nyou want")
                            .appFont(.hero34Bold)
                            .foregroundColor(AppColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        benefits
                        plans
                    }
                }
                .padding(AppSpacing.sideInset)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .bottom)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 8) {
            PaywallBenefitRow(icon: "iconGenerate", title: "Get results in seconds")
            PaywallBenefitRow(icon: "iconMagicPencil", title: "Turn any text into better writing")
            PaywallBenefitRow(icon: "iconPrompt", title: "Simplify complex information")
            PaywallBenefitRow(icon: "iconImageToImage", title: "Create content with AI templates")
        }
    }

    @ViewBuilder
    private var plans: some View {
        VStack(spacing: 12) {
            switch viewModel.state {
            case .idle, .loading:
                PaywallPlanSkeleton()
                PaywallPlanSkeleton()
            case let .loaded(items):
                ForEach(items) { plan in
                    PaywallPlanRow(plan: plan, isSelected: plan.id == viewModel.selectedPlanID) {
                        viewModel.selectedPlanID = plan.id
                    }
                }
            case let .failed(message):
                failure(message)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func failure(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .appFont(.body14)
                .foregroundColor(AppColor.textMuted)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.retry() }
            } label: {
                Text("Try again")
                    .appFont(.button16Semibold)
                    .foregroundStyle(AppGradient.brand)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 156)
    }

    // MARK: Close

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 17))
                .foregroundColor(AppColor.textPrimary.opacity(0.7))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .padding(.leading, AppSpacing.sideInset - 10)
        .padding(.top, 6)
        .opacity(isCloseVisible ? 1 : 0)
        .allowsHitTesting(isCloseVisible)
        .accessibilityHidden(!isCloseVisible)
        .accessibilityLabel("Close")
    }

    private func revealCloseButton() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        guard !Task.isCancelled else { return }
        withAnimation(.easeInOut(duration: 0.4)) { isCloseVisible = true }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 12))
                    .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                Text("Cancel Anytime").appFont(.caption12)
            }
            .foregroundColor(AppColor.textSecondary)
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)

            PrimaryGradientButton("Unlock now", isLoading: viewModel.isBusy, action: purchase)
                .disabled(!viewModel.canPurchase)
                .padding(.horizontal, AppSpacing.sideInset)

            legalLinks
        }
        .frame(maxWidth: .infinity)
        .background(AppColor.background.ignoresSafeArea())
    }

    private var legalLinks: some View {
        HStack(spacing: 12) {
            linkButton("Privacy Policy", alignment: .leading) { open(AppConfig.Links.privacyPolicy) }
            linkButton("Restore Purchases", alignment: .center, action: restore)
            linkButton("Terms of Use", alignment: .trailing) { open(AppConfig.Links.termsOfUse) }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func linkButton(_ title: LocalizedStringKey, alignment: Alignment, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .appFont(.caption12)
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: alignment == .center ? nil : .infinity, alignment: alignment)
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func purchase() {
        Task {
            if await viewModel.purchaseSelectedPlan() { onClose() }
        }
    }

    private func restore() {
        Task {
            if await viewModel.restore() { onClose() }
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }
}
