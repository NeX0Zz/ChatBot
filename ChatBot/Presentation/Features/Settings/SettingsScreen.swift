import SwiftUI

struct SettingsScreen: View {
    @StateObject private var viewModel: SettingsViewModel

    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: @autoclosure @escaping () -> SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "Settings", onBack: router.pop)
            ScrollView {
                VStack(spacing: 28) {
                    supportSection
                    purchasesSection
                    infoSection
                }
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppColor.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.refresh() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { Task { await viewModel.refresh() } }
        }
        .sheet(isPresented: $viewModel.isShareSheetPresented) {
            ShareSheet(items: viewModel.shareItems)
        }
        .alertCard(isPresented: $viewModel.isClearConfirmationPresented) {
            AlertCard(
                title: "Clear cache?",
                message: "Downloaded videos and temporary files will be removed. Your history stays.",
                confirmTitle: "Clear",
                confirmStyle: .destructive,
                onCancel: { viewModel.isClearConfirmationPresented = false },
                onConfirm: {
                    viewModel.isClearConfirmationPresented = false
                    Task { await viewModel.clearCache() }
                }
            )
        }
        .alertMessage($viewModel.alert)
    }

    private var supportSection: some View {
        SettingsSection(title: "Support us") {
            VStack(spacing: 8) {
                SettingsRow(icon: "star", title: "Rate app", action: viewModel.requestReview)
                SettingsRow(icon: "square.and.arrow.up", title: "Share with friends") {
                    viewModel.isShareSheetPresented = true
                }
            }
        }
    }

    private var purchasesSection: some View {
        SettingsSection(title: "Purchases & Actions") {
            VStack(spacing: 8) {
                if !subscriptionManager.isPremium {
                    SettingsRow(icon: "sparkles", title: "Upgrade plan") { router.presentPaywall() }
                        .transition(.opacity)
                }
                SettingsRow(
                    icon: "bell",
                    title: "Notifications",
                    accessory: .switchState(viewModel.isNotificationsEnabled)
                ) {
                    Task { await viewModel.openNotifications { openURL($0) } }
                }
                SettingsRow(icon: "trash", title: "Clear cache", accessory: .detail(viewModel.cacheSize)) {
                    viewModel.isClearConfirmationPresented = true
                }
                SettingsRow(
                    icon: "arrow.clockwise.icloud",
                    title: "Restore purchases",
                    accessory: viewModel.isRestoring ? .loading : .chevron
                ) {
                    Task { await viewModel.restorePurchases() }
                }
                .disabled(viewModel.isRestoring)
            }
            .animation(.easeInOut(duration: 0.3), value: subscriptionManager.isPremium)
        }
    }

    private var infoSection: some View {
        SettingsSection(title: "Info & legal") {
            VStack(spacing: 8) {
                SettingsRow(icon: "doc.text", title: "Contact us", action: contact)
                SettingsRow(icon: "doc.text", title: "Privacy Policy") { open(AppConfig.Links.privacyPolicy) }
                SettingsRow(icon: "doc.text", title: "Usage Policy") { open(AppConfig.Links.usagePolicy) }
                Text("App Version: \(viewModel.appVersion)")
                    .appFont(.caption13)
                    .foregroundColor(AppColor.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(16)
            }
        }
    }

    private func contact() {
        guard let url = viewModel.contactURL else { return }
        openURL(url) { accepted in
            if !accepted { viewModel.reportMailUnavailable() }
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        openURL(url)
    }
}
