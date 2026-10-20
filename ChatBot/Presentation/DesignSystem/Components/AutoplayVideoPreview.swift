import SwiftUI
import UIKit

/// Grid cell preview: the cached first frame, with the muted looping video faded in on top while the cell
/// holds one of the grid's autoplay slots. Follows the system "Auto-Play Video Previews" setting.
struct AutoplayVideoPreview: View {
    let url: URL
    var targetSize = CGSize(width: 300, height: 300)

    @EnvironmentObject private var slots: AutoplaySlots
    @Environment(\.scenePhase) private var scenePhase
    @State private var id = UUID()
    @State private var isAutoplayEnabled = UIAccessibility.isVideoAutoplayEnabled
    @State private var isVideoReady = false

    var body: some View {
        ZStack {
            VideoThumbnailView(url: url, targetSize: targetSize)
            if isAutoplayEnabled && scenePhase == .active && slots.holds(id) {
                LoopingVideoPlayerView(url: url, isPlaying: true, isMuted: true) { isReady in
                    withAnimation(.easeIn(duration: 0.2)) { isVideoReady = isReady }
                }
                .opacity(isVideoReady ? 1 : 0)
            }
        }
        .onAppear { slots.request(id) }
        .onDisappear {
            slots.release(id)
            isVideoReady = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.videoAutoplayStatusDidChangeNotification)) { _ in
            isAutoplayEnabled = UIAccessibility.isVideoAutoplayEnabled
        }
    }
}
