import CoreGraphics

struct PopoverOption<ID: Hashable>: Identifiable {
    let id: ID
    let title: String
    var subtitle: String?
    /// Width / height of the aspect-ratio glyph shown before the title; `nil` hides it.
    var aspectRatio: CGFloat?
}
