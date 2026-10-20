import SwiftUI

enum AppGradient {
    static let brand = brand(opacity: 1)
    static let brand90 = brand(opacity: 0.9)
    static let brand80 = brand(opacity: 0.8)
    static let brand30 = brand(opacity: 0.3)

    /// Fades the surface color out towards the top edge.
    static let surfaceFade = LinearGradient(
        colors: [AppColor.surface.opacity(0.6), AppColor.surface.opacity(0)],
        startPoint: .bottom,
        endPoint: .top
    )

    /// Darkens content scrolling under a header or behind an empty state.
    static let backgroundFade = LinearGradient(
        colors: [AppColor.background.opacity(0.9), AppColor.background],
        startPoint: .top,
        endPoint: .bottom
    )

    private static func brand(opacity: Double) -> LinearGradient {
        LinearGradient(
            colors: [AppColor.brandStart.opacity(opacity), AppColor.brandEnd.opacity(opacity)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
