import SwiftUI

/// Result video in a container that keeps the generation's aspect ratio.
/// Paused by default with a dimmed play overlay; a tap toggles playback.
struct ResultPlayerView: View {
    let phase: VideoResultViewModel.Phase
    let isPlaying: Bool
    let isActive: Bool
    let onToggle: () -> Void
    let onReplace: () -> Void
    let onRetry: () -> Void

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
    }

    var body: some View {
        ZStack {
            AppColor.surface60
            media
            if !isPlaying {
                controls.transition(.opacity)
            }
        }
        .clipShape(shape)
        .contentShape(shape)
        .onTapGesture(perform: onToggle)
        .animation(.easeInOut(duration: 0.25), value: isPlaying)
    }

    @ViewBuilder
    private var media: some View {
        switch phase {
        case let .ready(url):
            if isActive {
                LoopingVideoPlayerView(url: url, isPlaying: isPlaying, isMuted: false)
            }
        case .downloading:
            GenerationLoaderView(size: 56)
        case let .failed(message):
            TemplatesMessageView(title: "Couldn’t load video", message: message, retryTitle: "Retry", onRetry: onRetry)
        case .unavailable:
            TemplatesMessageView(title: "This video is no longer available")
        }
    }

    private var controls: some View {
        ZStack {
            if case .ready = phase {
                AppColor.mediaOverlay
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: Circle())
                    .accessibilityHidden(true)
            }
            ReplaceButton(action: onReplace)
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}
