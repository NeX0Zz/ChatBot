import SwiftUI

enum AppColor {
    // MARK: Backgrounds
    static let background = Color(hex: 0x0B070E)
    static let backgroundDeep = Color(hex: 0x0A080F)
    static let surface = Color(hex: 0x1F191F)
    static let surface40 = surface.opacity(0.4)
    static let surface50 = surface.opacity(0.5)
    static let surface60 = surface.opacity(0.6)
    static let surface80 = surface.opacity(0.8)
    static let scrim = Color.black.opacity(0.6)
    static let mediaOverlay = Color.black.opacity(0.4)

    // MARK: Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0x606060)
    static let textMuted = Color.white.opacity(0.6)
    static let textHint = Color.white.opacity(0.5)
    static let textDisabled = Color.white.opacity(0.28)

    // MARK: Strokes and fills on dark
    static let fillSubtle = Color.white.opacity(0.08)
    static let fillSelected = Color.white.opacity(0.06)
    static let strokeSubtle = Color.white.opacity(0.08)
    static let stroke = Color.white.opacity(0.12)
    static let strokeToast = Color.white.opacity(0.16)
    static let separator = Color.white.opacity(0.06)

    // MARK: Status
    static let success = Color(hex: 0x15CC68)
    static let error = Color(hex: 0xEC0D2A)
    static let errorSoft = Color(hex: 0xE2485D)
    static let destructive = Color(hex: 0xFF5C6E)
    static let generating = Color(hex: 0x99C7F7)
    static let failure = Color(hex: 0xFF5B49)

    // MARK: Swipe actions
    static let swipeRename = Color(hex: 0xFF8D28)
    static let swipeDelete = Color(hex: 0xFF383C)

    // MARK: Brand stops
    static let brandStart = Color(hex: 0x98C6F7)
    static let brandEnd = Color(hex: 0xEB5B92)
}
