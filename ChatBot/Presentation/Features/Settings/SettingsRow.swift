import SwiftUI

struct SettingsRow: View {
    enum Accessory {
        case chevron
        case detail(String)
        case switchState(Bool)
        case loading
    }

    let icon: String
    let title: LocalizedStringKey
    var accessory: Accessory = .chevron
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundStyle(AppGradient.brand)
                    .frame(width: 28)
                    .padding(.trailing, 8)
                    .accessibilityHidden(true)
                Text(title)
                    .appFont(.body16)
                    .foregroundColor(AppColor.textPrimary)
                Spacer(minLength: 8)
                trailing
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(AppColor.surface40, in: RoundedRectangle(cornerRadius: 40, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppSpacing.sideInset)
    }

    @ViewBuilder
    private var trailing: some View {
        switch accessory {
        case .chevron:
            chevron
        case let .detail(text):
            HStack(spacing: 16) {
                Text(text)
                    .appFont(.body16)
                    .foregroundColor(AppColor.textPrimary.opacity(0.4))
                chevron
            }
        case let .switchState(isOn):
            Toggle("", isOn: .constant(isOn))
                .labelsHidden()
                .tint(AppColor.brandEnd)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        case .loading:
            ProgressView().tint(.white)
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppGradient.brand)
            .accessibilityHidden(true)
    }
}
