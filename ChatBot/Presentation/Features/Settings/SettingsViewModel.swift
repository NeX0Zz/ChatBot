import Combine
import Foundation
import StoreKit
import UIKit
import UserNotifications

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var cacheSize = ""
    @Published private(set) var isNotificationsEnabled = false
    @Published private(set) var isRestoring = false
    @Published var isClearConfirmationPresented = false
    @Published var isShareSheetPresented = false
    @Published var alert: AlertMessage?

    private let subscriptionManager: SubscriptionManager
    private let cacheCleaner: MediaCacheCleaner
    private let notificationCenter = UNUserNotificationCenter.current()

    init(subscriptionManager: SubscriptionManager, cacheCleaner: MediaCacheCleaner) {
        self.subscriptionManager = subscriptionManager
        self.cacheCleaner = cacheCleaner
    }

    var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var shareItems: [Any] {
        AppConfig.Links.appStore.map { [$0] } ?? []
    }

    var contactURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = AppConfig.Links.supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "ChatBot support"),
            URLQueryItem(name: "body", value: "\n\nApp version: \(appVersion)")
        ]
        return components.url
    }

    func refresh() async {
        let total = await cacheCleaner.sizeInBytes()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.allowsNonnumericFormatting = false
        cacheSize = formatter.string(fromByteCount: total)

        let settings = await notificationCenter.notificationSettings()
        isNotificationsEnabled = [.authorized, .provisional, .ephemeral].contains(settings.authorizationStatus)
    }

    func clearCache() async {
        do {
            try await cacheCleaner.clear()
        } catch {
            alert = AlertMessage(title: String(localized: "Couldn’t clear cache"), message: error.localizedDescription)
        }
        await refresh()
    }

    func restorePurchases() async {
        guard !isRestoring else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            _ = try await subscriptionManager.restore()
            alert = AlertMessage(
                title: String(localized: "Purchases restored"),
                message: String(localized: "Your subscription is active again.")
            )
        } catch {
            alert = AlertMessage(title: String(localized: "Restore failed"), message: error.localizedDescription)
        }
    }

    /// Asks for permission the first time, afterwards sends the user to the system settings.
    func openNotifications(openURL: (URL) -> Void) async {
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await refresh()
        } else if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            openURL(url)
        }
    }

    func requestReview() {
        let scene = UIApplication.shared.connectedScenes
            .first { $0.activationState == .foregroundActive } as? UIWindowScene
        guard let scene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    func reportMailUnavailable() {
        alert = AlertMessage(
            title: String(localized: "Mail isn’t set up"),
            message: String(localized: "Write to \(AppConfig.Links.supportEmail) from any mail app.")
        )
    }
}
