import SwiftUI
import UIKit

/// A typographic style from the design spec: Inter face, size, line height and tracking.
struct AppFont {
    let postScriptName: String
    let size: CGFloat
    let lineHeight: CGFloat
    var tracking: CGFloat = 0
    var textStyle: Font.TextStyle = .body

    var font: Font {
        .custom(postScriptName, size: size, relativeTo: textStyle)
    }

    /// Extra leading needed to reach the Figma line height at the base size.
    var lineSpacing: CGFloat {
        guard let uiFont = UIFont(name: postScriptName, size: size) else { return 0 }
        return max(0, lineHeight - uiFont.lineHeight)
    }
}

extension AppFont {
    private enum Face {
        static let regular = "Inter-Regular"
        static let medium = "Inter-Medium"
        static let semibold = "Inter-SemiBold"
        static let bold = "Inter-Bold"
    }

    static let hero34Bold = AppFont(postScriptName: Face.bold, size: 34, lineHeight: 41.15, textStyle: .largeTitle)
    static let title28Bold = AppFont(postScriptName: Face.bold, size: 28, lineHeight: 33.89, tracking: 0.4, textStyle: .title)
    static let title20Semibold = AppFont(postScriptName: Face.semibold, size: 20, lineHeight: 24.2, textStyle: .title3)
    static let title20Medium = AppFont(postScriptName: Face.medium, size: 20, lineHeight: 24.2, textStyle: .title3)
    static let title18Semibold = AppFont(postScriptName: Face.semibold, size: 18, lineHeight: 21.78, textStyle: .headline)
    static let alertTitle17Semibold = AppFont(postScriptName: Face.semibold, size: 17, lineHeight: 20.57, textStyle: .headline)
    static let alertButton17 = AppFont(postScriptName: Face.regular, size: 17, lineHeight: 20.57, textStyle: .body)
    static let button16Semibold = AppFont(postScriptName: Face.semibold, size: 16, lineHeight: 19.36, textStyle: .body)
    static let body16Medium = AppFont(postScriptName: Face.medium, size: 16, lineHeight: 19.36, textStyle: .body)
    static let body16 = AppFont(postScriptName: Face.regular, size: 16, lineHeight: 19.36, textStyle: .body)
    static let field15 = AppFont(postScriptName: Face.regular, size: 15, lineHeight: 18.15, textStyle: .subheadline)
    static let body14 = AppFont(postScriptName: Face.regular, size: 14, lineHeight: 16.94, textStyle: .subheadline)
    static let label14Semibold = AppFont(postScriptName: Face.semibold, size: 14, lineHeight: 16.94, tracking: 0.56, textStyle: .subheadline)
    static let caption13 = AppFont(postScriptName: Face.regular, size: 13, lineHeight: 15.73, textStyle: .footnote)
    static let caption13Medium = AppFont(postScriptName: Face.medium, size: 13, lineHeight: 15.73, textStyle: .footnote)
    static let caption13Semibold = AppFont(postScriptName: Face.semibold, size: 13, lineHeight: 15.73, textStyle: .footnote)
    static let caption12 = AppFont(postScriptName: Face.regular, size: 12, lineHeight: 14.52, textStyle: .caption)
    static let caption12Medium = AppFont(postScriptName: Face.medium, size: 12, lineHeight: 14.52, textStyle: .caption)
}

extension View {
    func appFont(_ style: AppFont) -> some View {
        font(style.font)
            .lineSpacing(style.lineSpacing)
            .tracking(style.tracking)
    }
}
