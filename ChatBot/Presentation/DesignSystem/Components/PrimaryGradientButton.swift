import SwiftUI

struct PrimaryGradientButton: View {
    private let title: LocalizedStringKey
    private let isLoading: Bool
    private let action: () -> Void

    init(_ title: LocalizedStringKey, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).appFont(.button16Semibold)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryGradientButtonStyle())
        .disabled(isLoading)
    }
}

private struct PrimaryGradientButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppColor.textPrimary.opacity(isEnabled ? 1 : 0.3))
            .frame(height: AppSpacing.buttonHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }

    @ViewBuilder
    private var background: some View {
        if isEnabled {
            AppGradient.brand
        } else {
            AppColor.surface
        }
    }
}

struct PrimaryGradientButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            PrimaryGradientButton("Continue") {}
            PrimaryGradientButton("Create") {}.disabled(true)
            PrimaryGradientButton("Create", isLoading: true) {}
        }
        .padding(16)
        .background(AppColor.background)
    }
}
