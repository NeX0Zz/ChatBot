import SwiftUI

/// Row that slides left to reveal round Rename / Delete buttons. `List.swipeActions` cannot draw
/// round buttons next to a floating card, so the gesture is handled here. Opening is driven by the parent.
struct ChatSwipeRow<Content: View>: View {
    let isOpen: Bool
    let onOpenChange: (Bool) -> Void
    let onTap: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var dragOffset: CGFloat = 0
    @State private var isHorizontalDrag: Bool?

    private let buttonSize: CGFloat = 50
    private let spacing: CGFloat = 12
    private var revealWidth: CGFloat { buttonSize * 2 + spacing * 2 }

    private var offset: CGFloat {
        min(0, max(-revealWidth, (isOpen ? -revealWidth : 0) + dragOffset))
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            actions
                .opacity(min(1, -offset / revealWidth))
                .allowsHitTesting(isOpen)
            content
                .offset(x: offset)
                .onTapGesture {
                    if isOpen { onOpenChange(false) } else { onTap() }
                }
                .simultaneousGesture(drag)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isOpen)
        .accessibilityAction(named: "Rename", onRename)
        .accessibilityAction(named: "Delete", onDelete)
    }

    private var actions: some View {
        HStack(spacing: spacing) {
            circleButton(systemName: "pencil", color: AppColor.swipeRename, label: "Rename", action: onRename)
            circleButton(systemName: "trash", color: AppColor.swipeDelete, label: "Delete", action: onDelete)
        }
    }

    private func circleButton(systemName: String, color: Color, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15))
                .foregroundColor(AppColor.textPrimary)
                .frame(width: buttonSize, height: buttonSize)
                .background(color, in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(label)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if isHorizontalDrag == nil {
                    isHorizontalDrag = abs(value.translation.width) > abs(value.translation.height)
                }
                guard isHorizontalDrag == true else { return }
                dragOffset = value.translation.width
            }
            .onEnded { value in
                defer {
                    isHorizontalDrag = nil
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { dragOffset = 0 }
                }
                guard isHorizontalDrag == true else { return }
                let projected = (isOpen ? -revealWidth : 0) + value.predictedEndTranslation.width
                onOpenChange(projected < -revealWidth / 2)
            }
    }
}
