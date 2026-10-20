import Foundation

extension VideoFormat {
    var subtitle: String {
        switch self {
        case .landscape: String(localized: "Landscape")
        case .portrait: String(localized: "Portrait · Stories")
        case .square: String(localized: "Square")
        }
    }

    static var popoverOptions: [PopoverOption<VideoFormat>] {
        allCases.map { PopoverOption(id: $0, title: $0.title, subtitle: $0.subtitle, aspectRatio: $0.aspectRatio) }
    }
}
