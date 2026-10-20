import Lottie
import SwiftUI

/// Looping loader from the design (`Resources/Animations/Loader.json`) shown while media is being prepared
/// or generated. It is a progress indicator, so it keeps moving under Reduce Motion like the system spinner.
struct GenerationLoaderView: View {
    var size: CGFloat = 200

    var body: some View {
        LottieView(animation: .named("Loader"))
            .playing(loopMode: .loop)
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct GenerationLoaderView_Previews: PreviewProvider {
    static var previews: some View {
        GenerationLoaderView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColor.background)
    }
}
