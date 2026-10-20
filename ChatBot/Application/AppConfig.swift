import Foundation
import OSLog

/// Runtime configuration. Endpoints and keys are read from the app's Info.plist (Configuration/Info.plist).
enum AppConfig {
    enum API {
        static let chatBaseURL = url(for: "ChatAPIBaseURL")
        static let videoBaseURL = url(for: "VideoAPIBaseURL")
        static let applicationId = value(for: "APIApplicationID")
        static let bearerToken = value(for: "APIBearerToken")
        static let requestTimeout: TimeInterval = 60
        static let uploadTimeout: TimeInterval = 120
    }

    enum Apphud {
        static let apiKey = value(for: "ApphudAPIKey")
        static let paywallIdentifier = value(for: "ApphudPaywallID")
    }

    enum Links {
        static let privacyPolicy = URL(string: "https://www.apple.com/legal/privacy/")
        static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        static let usagePolicy = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        static let supportEmail = "support@example.com"
        static let appStore = URL(string: "https://apps.apple.com/app/id0000000000")
    }

    private static func value(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            Logger(subsystem: "com.labs.fviu", category: "config").fault("\(key) is missing from Info.plist")
            assertionFailure("\(key) is missing from Info.plist")
            return ""
        }
        return value
    }

    private static func url(for key: String) -> URL {
        guard let url = URL(string: value(for: key)) else {
            assertionFailure("\(key) is not a valid URL")
            return URL(fileURLWithPath: "/")
        }
        return url
    }
}
