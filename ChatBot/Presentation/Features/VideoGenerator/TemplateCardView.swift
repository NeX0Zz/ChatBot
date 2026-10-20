import SwiftUI

struct TemplateCardView: View {
    static let aspectRatio: CGFloat = 171.0 / 232.0

    let template: VideoTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Color.clear
                .aspectRatio(Self.aspectRatio, contentMode: .fit)
                .overlay { preview }
                .overlay { AppGradient.surfaceFade }
                .overlay(alignment: .bottom) {
                    Text(template.name)
                        .appFont(.body16)
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(1)
                        .padding(8)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel(template.name)
    }

    @ViewBuilder
    private var preview: some View {
        if let url = template.previewURL {
            AutoplayVideoPreview(url: url, targetSize: CGSize(width: 171, height: 232))
        } else {
            AppColor.surface60
        }
    }
}
