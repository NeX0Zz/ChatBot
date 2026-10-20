import SwiftUI

/// "Turn Photo into Video" entry card of the main screen.
struct MainPhotoVideoCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image("iconImageToImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15), in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Turn Photo\ninto Video")
                        .appFont(.title20Medium)
                    HStack(spacing: 8) {
                        Text("Animate")
                        Circle().frame(width: 4, height: 4)
                        Text("Templates")
                    }
                    .appFont(.body14)
                    .opacity(0.7)
                }
                .foregroundColor(AppColor.textPrimary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .topLeading) { artwork }
            .overlay(alignment: .topTrailing) { readyTag.padding(20) }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            // The offset artwork overflows the card; clipping hides it but doesn't stop it from taking taps
            // meant for the "Ask anything" field above.
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Turn Photo into Video")
    }

    private var artwork: some View {
        ZStack(alignment: .topLeading) {
            AppGradient.brand80
            Image("imageMainCardTurnPhoto")
                .resizable()
                .frame(width: 240, height: 360)
                .opacity(0.5)
                .offset(x: 132, y: -69)
        }
    }

    private var readyTag: some View {
        HStack(spacing: 8) {
            Text("Ready in seconds").appFont(.caption12)
            Image(systemName: "play.fill").font(.system(size: 10))
        }
        .foregroundColor(AppColor.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Color.white.opacity(0.3), in: Capsule())
    }
}
