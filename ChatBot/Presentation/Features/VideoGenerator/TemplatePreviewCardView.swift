import SwiftUI

/// One page of the preview carousel. Only the current page creates a player, the rest show a cached first frame.
struct TemplatePreviewCardView: View {
    let template: VideoTemplate
    let size: CGSize
    let isPlaying: Bool

    var body: some View {
        ZStack {
            if let url = template.previewURL {
                VideoThumbnailView(url: url, targetSize: size)
                if isPlaying {
                    LoopingVideoPlayerView(url: url, isPlaying: true, isMuted: true)
                        .transition(.opacity)
                }
            } else {
                AppColor.surface60
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.tile, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(template.name)
    }
}
