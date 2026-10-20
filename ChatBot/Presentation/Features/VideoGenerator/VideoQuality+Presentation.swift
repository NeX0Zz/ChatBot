import Foundation

extension VideoQuality {
    var subtitle: String {
        switch self {
        case .p360: String(localized: "Draft")
        case .p540: String(localized: "Standard")
        case .p720: String(localized: "Faster generation")
        case .p1080: String(localized: "Recommended")
        }
    }

    static func popoverOptions(for qualities: [VideoQuality]) -> [PopoverOption<VideoQuality>] {
        qualities.map { PopoverOption(id: $0, title: $0.title, subtitle: $0.subtitle) }
    }
}
