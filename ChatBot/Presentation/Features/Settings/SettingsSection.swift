import SwiftUI

struct SettingsSection<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .appFont(.button16Semibold)
                .foregroundColor(AppColor.textPrimary.opacity(0.3))
                .padding(.horizontal, AppSpacing.sideInset)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}
