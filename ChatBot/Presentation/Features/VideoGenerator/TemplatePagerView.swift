import SwiftUI

/// Horizontal carousel with the neighbouring pages peeking from both sides.
/// Keeps at most five lightweight pages alive; only the selected one plays video.
struct TemplatePagerView: View {
    static let cardInset: CGFloat = 59
    static let spacing: CGFloat = 16

    let templates: [VideoTemplate]
    let selection: Int
    let isPlaybackEnabled: Bool
    let onSelect: (Int) -> Void

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let cardSize = CGSize(width: proxy.size.width - Self.cardInset, height: proxy.size.height)
            let pitch = cardSize.width + Self.spacing
            ZStack {
                ForEach(visibleIndices, id: \.self) { index in
                    TemplatePreviewCardView(
                        template: templates[index],
                        size: cardSize,
                        isPlaying: isPlaybackEnabled && index == selection
                    )
                    .offset(x: CGFloat(index - selection) * pitch + dragOffset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture(pitch: pitch))
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: selection)
    }

    private var visibleIndices: [Int] {
        guard !templates.isEmpty else { return [] }
        let lower = max(0, selection - 2)
        let upper = min(templates.count - 1, selection + 2)
        return Array(lower...upper)
    }

    private func dragGesture(pitch: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                dragOffset = resisted(value.translation.width)
            }
            .onEnded { value in
                let projected = value.predictedEndTranslation.width
                var target = selection
                if projected < -pitch / 3 {
                    target += 1
                } else if projected > pitch / 3 {
                    target -= 1
                }
                target = min(max(target, 0), templates.count - 1)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    dragOffset = 0
                    onSelect(target)
                }
            }
    }

    /// Rubber-bands the drag when there is no page in that direction.
    private func resisted(_ translation: CGFloat) -> CGFloat {
        let isAtStart = selection == 0 && translation > 0
        let isAtEnd = selection == templates.count - 1 && translation < 0
        return isAtStart || isAtEnd ? translation / 3 : translation
    }
}
