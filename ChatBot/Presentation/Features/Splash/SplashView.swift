import SwiftUI

struct SplashView: View {
    let onFinish: () -> Void

    @State private var progress: CGFloat = 0

    private let duration: TimeInterval = 1.5
    private let trackWidth: CGFloat = 212

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image("imageOrb")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 143, height: 142)
                    .accessibilityHidden(true)
                progressBar
            }
        }
        .task {
            withAnimation(.easeInOut(duration: duration)) { progress = 1 }
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            onFinish()
        }
    }

    private var progressBar: some View {
        Capsule()
            .fill(AppColor.fillSubtle)
            .frame(width: trackWidth, height: 4)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(AppGradient.brand)
                    .frame(width: trackWidth * progress, height: 4)
            }
            .accessibilityElement()
            .accessibilityLabel("Loading")
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView(onFinish: {})
    }
}
