import SwiftUI

/// Chat header: back, gradient badge, title with a pin mark and the creation date, and the ••• button.
/// `NavigationHeader` has no slot for the pin mark next to the title, hence the dedicated layout.
struct ChatHeaderView: View {
    let dateText: String
    let isPinned: Bool
    let showsMenu: Bool
    let onBack: () -> Void
    let onMenu: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            backButton
            badge.padding(.leading, 24)
            titleBlock.padding(.leading, 12)
            Spacer(minLength: 16)
            if showsMenu {
                menuButton.transition(.opacity)
            }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.vertical, 16)
        .animation(.easeInOut(duration: 0.25), value: showsMenu)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image("iconBack")
                .resizable()
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .foregroundColor(AppColor.textPrimary)
                .padding(.horizontal, 8)
                .frame(height: AppSpacing.controlHeight)
                .contentShape(Rectangle())
                .padding(.horizontal, -8)
        }
        .accessibilityLabel("Back")
    }

    private var badge: some View {
        Image("iconGenerate")
            .resizable()
            .scaledToFit()
            .foregroundColor(AppColor.textPrimary)
            .padding(4)
            .frame(width: 32, height: 32)
            .background(AppGradient.brand, in: Circle())
            .accessibilityHidden(true)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 10) {
                Text("AI Chat")
                    .appFont(.title18Semibold)
                    .foregroundColor(AppColor.textPrimary)
                    .lineLimit(1)
                if isPinned {
                    Image("iconPin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 8, height: 14)
                        .foregroundColor(AppColor.textHint)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Pinned")
                }
            }
            Text(dateText)
                .appFont(.body14)
                .foregroundColor(AppColor.textPrimary.opacity(0.3))
        }
        .animation(.easeInOut(duration: 0.25), value: isPinned)
    }

    private var menuButton: some View {
        Button(action: onMenu) {
            Image("iconMore")
                .resizable()
                .frame(width: AppSpacing.controlHeight, height: AppSpacing.controlHeight)
                .foregroundColor(AppColor.textPrimary)
                .background(AppColor.fillSubtle, in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("More")
    }
}

struct ChatHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChatHeaderView(dateText: "26.03.2026", isPinned: true, showsMenu: true, onBack: {}, onMenu: {})
            ChatHeaderView(dateText: "26.03.2026", isPinned: false, showsMenu: false, onBack: {}, onMenu: {})
            Spacer()
        }
        .background(AppColor.background)
    }
}
