import SwiftUI

struct SuggestionChip: View {
    /// `.regular` is the empty-chat chip, `.compact` the smaller onboarding demo chip.
    enum Size {
        case regular
        case compact
    }

    let title: String
    var size: Size = .regular
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(size == .regular ? .body14 : .caption13)
                .foregroundColor(AppColor.textPrimary.opacity(size == .regular ? 0.9 : 1))
                .padding(.horizontal, size == .regular ? 14 : 12)
                .padding(.vertical, size == .regular ? 10 : 8)
                .background(AppColor.surface80, in: Capsule())
                .overlay(Capsule().strokeBorder(AppColor.stroke, lineWidth: 1))
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

struct SuggestionChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SuggestionChip(title: "Explain simply", size: .compact) {}
            SuggestionChip(title: "Write an email") {}
        }
        .padding()
        .background(AppColor.background)
    }
}
