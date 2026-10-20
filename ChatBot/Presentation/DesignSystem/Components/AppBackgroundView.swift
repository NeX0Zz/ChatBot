import SwiftUI

/// App background with the blurred brand-gradient glow behind the top of a screen.
/// Geometry comes from the Main/Paywall frames (390 pt wide); `glowHeight` is the bottom edge of the glow.
struct AppBackgroundView: View {
    var glowHeight: CGFloat = 333
    var glowOpacity: Double = 0.3

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / 390
            ZStack(alignment: .topLeading) {
                AppColor.background

                Ellipse()
                    .fill(AppGradient.brand)
                    .frame(width: 600 * scale, height: 340 * scale)
                    .rotationEffect(.degrees(18))
                    .opacity(glowOpacity)
                    .blur(radius: 100)
                    .offset(x: -45 * scale, y: -90 * scale)

                shade(width: 383, height: 237, x: -18.5, y: 96.5, scale: scale)
                shade(width: 315, height: 236, x: 316, y: 147, scale: scale)
            }
            .drawingGroup()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func shade(width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat, scale: CGFloat) -> some View {
        Ellipse()
            .fill(AppColor.background)
            .frame(width: width * scale, height: height * scale)
            .blur(radius: 108)
            .offset(x: x * scale, y: (y + glowHeight - 333) * scale)
    }
}

struct AppBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        AppBackgroundView()
    }
}
