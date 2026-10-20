import SwiftUI

struct CircleIconButton: View {
    private let icon: String
    private let label: LocalizedStringKey
    private let action: () -> Void

    init(icon: String, label: LocalizedStringKey, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                .foregroundColor(AppColor.textPrimary)
                .frame(width: AppSpacing.controlHeight, height: AppSpacing.controlHeight)
                .background(AppColor.fillSubtle, in: Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(label)
    }
}

struct CircleIconButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CircleIconButton(icon: "iconHistory", label: "History") {}
            CircleIconButton(icon: "iconSettings", label: "Settings") {}
            CircleIconButton(icon: "iconMore", label: "More") {}
        }
        .padding()
        .background(AppColor.background)
    }
}
