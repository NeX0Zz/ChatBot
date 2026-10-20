import SwiftUI

/// Renders `ToastCenter.current`: a capsule banner at the top for short messages,
/// a centered card over a scrim when the toast carries a secondary message.
struct ToastHost: View {
    @ObservedObject var center: ToastCenter

    var body: some View {
        ZStack {
            if let toast = center.current {
                if toast.message == nil {
                    banner(toast)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    card(toast)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: center.current)
    }

    private func banner(_ toast: Toast) -> some View {
        HStack(spacing: 12) {
            icon(for: toast, size: 24)
            Text(toast.title)
                .appFont(.button16Semibold)
                .foregroundColor(AppColor.textPrimary)
                .padding(.trailing, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: Capsule())
        .background(AppColor.surface40, in: Capsule())
        .overlay(Capsule().strokeBorder(AppColor.strokeToast, lineWidth: 1))
        .gesture(
            DragGesture(minimumDistance: 8).onEnded { value in
                if value.translation.height < -12 { center.dismiss() }
            }
        )
        .accessibilityElement(children: .combine)
    }

    private func card(_ toast: Toast) -> some View {
        ZStack {
            AppColor.scrim
                .ignoresSafeArea()
                .onTapGesture { center.dismiss() }
            VStack(spacing: 8) {
                icon(for: toast, size: 40)
                VStack(spacing: 4) {
                    Text(toast.title)
                        .appFont(.button16Semibold)
                        .foregroundColor(AppColor.textPrimary)
                    if let message = toast.message {
                        Text(message)
                            .appFont(.body14)
                            .foregroundColor(AppColor.textHint)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .frame(width: 239)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .background(AppColor.surface40, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private func icon(for toast: Toast, size: CGFloat) -> some View {
        Image(toast.style == .success ? "iconCheck" : "iconClose")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(color(for: toast, large: size > 24))
    }

    private func color(for toast: Toast, large: Bool) -> Color {
        switch toast.style {
        case .success: return large ? AppColor.textPrimary : AppColor.success
        case .failure: return large ? AppColor.errorSoft : AppColor.error
        }
    }
}

struct ToastHost_Previews: PreviewProvider {
    private struct Demo: View {
        @StateObject private var center = ToastCenter()
        var body: some View {
            ZStack {
                AppColor.background.ignoresSafeArea()
                VStack(spacing: 12) {
                    Button("Copied") { center.show(.copied) }
                    Button("Upload failed") { center.show(.uploadFailed) }
                    Button("Save failed") { center.show(.saveFailed) }
                }
                ToastHost(center: center)
            }
        }
    }

    static var previews: some View { Demo() }
}
