import SwiftUI

struct PreviewParameterRow: View {
    let title: LocalizedStringKey
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .appFont(.body16Medium)
                    .foregroundColor(AppColor.textMuted)
                Spacer(minLength: 12)
                Text(value)
                    .appFont(.body16Medium)
                    .foregroundColor(AppColor.textPrimary)
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(AppColor.surface50, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(value)
    }
}
