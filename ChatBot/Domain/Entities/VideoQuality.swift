import Foundation

enum VideoQuality: String, CaseIterable, Sendable {
    case p360 = "360p"
    case p540 = "540p"
    case p720 = "720p"
    case p1080 = "1080p"

    var title: String { rawValue }
}
