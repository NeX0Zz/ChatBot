import CoreGraphics

/// Splits items into two columns of equal width, always appending to the shorter one,
/// so cards of different aspect ratios keep their proportions and the columns stay balanced.
enum VideoMasonry {
    static func columns<Item>(
        of items: [Item],
        aspectRatio: (Item) -> CGFloat
    ) -> (leading: [Item], trailing: [Item]) {
        var leading: [Item] = []
        var trailing: [Item] = []
        var leadingHeight: CGFloat = 0
        var trailingHeight: CGFloat = 0
        for item in items {
            let height = 1 / aspectRatio(item)
            if leadingHeight <= trailingHeight {
                leading.append(item)
                leadingHeight += height
            } else {
                trailing.append(item)
                trailingHeight += height
            }
        }
        return (leading, trailing)
    }
}
