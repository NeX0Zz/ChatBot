import SwiftUI

/// Custom dark alert: title, message, optional text field and a Cancel / confirm button row.
struct AlertCard: View {
    enum ConfirmStyle {
        case primary
        case destructive
    }

    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var text: Binding<String>?
    var placeholder: LocalizedStringKey = ""
    let confirmTitle: LocalizedStringKey
    var confirmStyle: ConfirmStyle = .primary
    var isConfirmEnabled = true
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text(title)
                        .appFont(.alertTitle17Semibold)
                        .foregroundColor(AppColor.textPrimary)
                    Text(message)
                        .appFont(.caption13)
                        .foregroundColor(AppColor.textMuted)
                        .multilineTextAlignment(.center)
                }
                if let text {
                    field(text: text)
                }
            }
            .padding(EdgeInsets(top: 20, leading: 16, bottom: text == nil ? 18 : 16, trailing: 16))

            buttons
        }
        .frame(width: text == nil ? 270 : 296)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
        .background(AppColor.surface80, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
        .onAppear { isFieldFocused = text != nil }
    }

    private func field(text: Binding<String>) -> some View {
        TextField(
            "",
            text: text,
            prompt: Text(placeholder).foregroundColor(AppColor.textDisabled)
        )
        .appFont(.field15)
        .foregroundColor(AppColor.textPrimary)
        .tint(AppColor.brandStart)
        .focused($isFieldFocused)
        .submitLabel(.done)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppColor.backgroundDeep.opacity(0.8), in: RoundedRectangle(cornerRadius: AppRadius.field, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.field, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var buttons: some View {
        HStack(spacing: 0) {
            Button(action: onCancel) {
                Text("Cancel")
                    .appFont(.alertButton17)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .contentShape(Rectangle())
            }
            Rectangle().fill(AppColor.stroke).frame(width: 1)
            Button(action: onConfirm) {
                confirmLabel
                    .appFont(.alertTitle17Semibold)
                    .frame(maxWidth: .infinity, minHeight: 47)
                    .contentShape(Rectangle())
            }
            .disabled(!isConfirmEnabled)
        }
        .buttonStyle(.plain)
        .frame(height: 48)
        .overlay(alignment: .top) {
            Rectangle().fill(AppColor.stroke).frame(height: 1)
        }
    }

    @ViewBuilder
    private var confirmLabel: some View {
        if !isConfirmEnabled {
            Text(confirmTitle).foregroundColor(AppColor.textDisabled)
        } else if confirmStyle == .destructive {
            Text(confirmTitle).foregroundColor(AppColor.destructive)
        } else {
            Text(confirmTitle).foregroundStyle(AppGradient.brand)
        }
    }
}

extension View {
    /// Presents an `AlertCard` over a dimmed backdrop with a scale and fade transition.
    /// The card is laid out inside the keyboard-aware safe area, so it stays visible while typing.
    func alertCard(isPresented: Binding<Bool>, @ViewBuilder content: () -> AlertCard) -> some View {
        overlay {
            ZStack {
                if isPresented.wrappedValue {
                    AppColor.scrim
                        .ignoresSafeArea()
                        .onTapGesture { isPresented.wrappedValue = false }
                        .transition(.opacity)
                    content()
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented.wrappedValue)
        }
    }
}

struct AlertCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            AlertCard(
                title: "Delete chat?",
                message: "This chat will be removed from your history.",
                confirmTitle: "Delete",
                confirmStyle: .destructive,
                onCancel: {},
                onConfirm: {}
            )
            AlertCard(
                title: "Rename chat",
                message: "Enter a new name for this chat",
                text: .constant(""),
                placeholder: "Chat name",
                confirmTitle: "Save",
                isConfirmEnabled: false,
                onCancel: {},
                onConfirm: {}
            )
        }
        .padding()
        .background(AppColor.background)
    }
}
