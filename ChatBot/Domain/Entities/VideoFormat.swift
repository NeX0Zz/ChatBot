import CoreGraphics

/// Output aspect ratio. Template generation takes the ratio from the source frame,
/// so the picked photo is center-cropped to this ratio before upload.
enum VideoFormat: String, CaseIterable, Sendable {
    case landscape = "16:9"
    case portrait = "9:16"
    case square = "1:1"

    var title: String { rawValue }

    /// Width divided by height.
    var aspectRatio: CGFloat {
        switch self {
        case .landscape: 16.0 / 9.0
        case .portrait: 9.0 / 16.0
        case .square: 1
        }
    }
}
