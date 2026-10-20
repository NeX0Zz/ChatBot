import SwiftUI

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case chat
    case video

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .chat: "Ask AI anything"
        case .video: "Turn photos into videos"
        }
    }

    var subtitle: LocalizedStringKey {
        switch self {
        case .chat: "Answers, emails, ideas and plans in seconds"
        case .video: "Pick a template — AI animates your photo"
        }
    }
}
