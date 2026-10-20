import SwiftUI

/// Screen header: back arrow, title and an optional trailing control.
/// With an `icon` the title is left-aligned next to a gradient badge (chat, video templates),
/// otherwise it is centered.
struct NavigationHeader<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let icon: String?
    private let onBack: (() -> Void)?
    private let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.onBack = onBack
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                leading
                Spacer(minLength: 16)
                trailing
            }
            if icon == nil {
                titleBlock.padding(.horizontal, 56)
            }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.vertical, 8)
        .frame(minHeight: AppSpacing.headerContentHeight)
    }

    private var leading: some View {
        HStack(spacing: 24) {
            if let onBack {
                Button(action: onBack) {
                    Image("iconBack")
                        .resizable()
                        .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(width: AppSpacing.controlHeight, height: AppSpacing.controlHeight, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Back")
            }
            if let icon {
                HStack(spacing: 12) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(AppColor.textPrimary)
                        .padding(4)
                        .frame(width: 32, height: 32)
                        .background(AppGradient.brand, in: Circle())
                    titleBlock
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 2) {
            Text(title)
                .appFont(.title18Semibold)
                .foregroundColor(AppColor.textPrimary)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .appFont(.body14)
                    .foregroundColor(AppColor.textPrimary.opacity(0.3))
            }
        }
    }
}

extension NavigationHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, icon: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, icon: icon, onBack: onBack) { EmptyView() }
    }
}

struct NavigationHeader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            NavigationHeader(title: "Result", onBack: {})
            NavigationHeader(title: "AI Chat", subtitle: "26.03.2026", icon: "iconGenerate", onBack: {}) {
                CircleIconButton(icon: "iconMore", label: "More") {}
            }
            Spacer()
        }
        .background(AppColor.background)
    }
}
