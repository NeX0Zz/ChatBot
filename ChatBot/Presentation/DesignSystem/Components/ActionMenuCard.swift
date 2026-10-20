import SwiftUI

/// Floating action list (Share / Pin / Delete) with separators between rows.
struct ActionMenuCard: View {
    let items: [ActionMenuItem]
    let onSelect: (ActionMenuItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                if index > 0 {
                    Rectangle().fill(AppColor.separator).frame(height: 1)
                }
                Button { onSelect(item) } label: {
                    HStack(spacing: 12) {
                        Text(item.title)
                            .appFont(.body16Medium)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(item.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .foregroundColor(item.role == .destructive ? AppColor.destructive : AppColor.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 230)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
        .background(AppColor.surface80, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
    }
}

extension View {
    /// Presents `ActionMenuCard` over a dimmed scrim, anchored to the top trailing corner.
    /// `topOffset` is measured from the top safe area, so the menu sits just under a header.
    func actionMenu(isPresented: Binding<Bool>, items: [ActionMenuItem], topOffset: CGFloat = 73) -> some View {
        overlay {
            ZStack(alignment: .topTrailing) {
                if isPresented.wrappedValue {
                    AppColor.scrim
                        .ignoresSafeArea()
                        .onTapGesture { isPresented.wrappedValue = false }
                        .transition(.opacity)
                    ActionMenuCard(items: items) { item in
                        isPresented.wrappedValue = false
                        item.action()
                    }
                    .padding(.top, topOffset)
                    .padding(.trailing, AppSpacing.sideInset)
                    .transition(.scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented.wrappedValue)
        }
    }
}

struct ActionMenuCard_Previews: PreviewProvider {
    static var previews: some View {
        ActionMenuCard(
            items: [
                ActionMenuItem(title: "Share", icon: "iconShare") {},
                ActionMenuItem(title: "Pin chat", icon: "iconPin") {},
                ActionMenuItem(title: "Delete chat", icon: "iconDelete", role: .destructive) {}
            ],
            onSelect: { _ in }
        )
        .padding()
        .background(AppColor.background)
    }
}
