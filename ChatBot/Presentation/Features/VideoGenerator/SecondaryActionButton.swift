import SwiftUI

struct SecondaryActionButton: View {
    private let title: LocalizedStringKey
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(.button16Semibold)
                .foregroundColor(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.buttonHeight)
                .background(AppColor.surface60, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .opacity(isEnabled ? 1 : 0.4)
    }
}
