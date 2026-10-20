import SwiftUI

/// First frame of a video. Shows a cached frame immediately, a shimmer while decoding
/// and a static placeholder if the frame can't be produced.
struct VideoThumbnailView: View {
    let url: URL
    /// Largest size in points the thumbnail is rendered at; bounds the decoding cost.
    var targetSize = CGSize(width: 300, height: 300)

    @Environment(\.displayScale) private var displayScale
    @Environment(\.thumbnailCache) private var cache
    @State private var image: UIImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else if didFail {
                AppColor.surface60
            } else {
                AppColor.surface60.shimmer()
            }
        }
        .clipped()
        .task(id: url) {
            let pixelSide = max(targetSize.width, targetSize.height) * displayScale
            if let cached = cache.cachedImage(for: url, minPixelSide: pixelSide) {
                image = cached
                return
            }
            let thumbnail = await cache.thumbnail(for: url, maxPixelSide: pixelSide)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                image = thumbnail
                didFail = thumbnail == nil
            }
        }
    }
}
