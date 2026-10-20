import AVFoundation
import AVKit
import OSLog
import SwiftUI

/// Looping, chrome-less video surface.
///
/// Backed by `AVPlayerViewController` rather than a bare `AVPlayerLayer`: inside SwiftUI hierarchies the bare layer
/// stopped presenting new frames while the player kept running, so playback looked frozen and jumped on pause.
/// The controller owns the video layer's display pipeline and does not have that problem.
/// The background is transparent, so whatever sits underneath (a thumbnail) stays visible until the first frame.
struct LoopingVideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    var isPlaying: Bool
    var isMuted = true
    var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    /// Called on the main thread when the first frame becomes (or stops being) ready to display.
    var onReadyForDisplay: ((Bool) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.showsPlaybackControls = false
        controller.allowsPictureInPicturePlayback = false
        controller.updatesNowPlayingInfoCenter = false
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        controller.videoGravity = videoGravity
        context.coordinator.onReadyForDisplay = onReadyForDisplay
        context.coordinator.attach(to: controller)
        context.coordinator.load(url, into: controller)
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.onReadyForDisplay = onReadyForDisplay
        if coordinator.url != url {
            coordinator.load(url, into: controller)
        }
        if controller.videoGravity != videoGravity {
            controller.videoGravity = videoGravity
        }
        coordinator.setMuted(isMuted)
        coordinator.setPlaying(isPlaying)
    }

    static func dismantleUIViewController(_ controller: AVPlayerViewController, coordinator: Coordinator) {
        coordinator.teardown(controller)
    }

    @MainActor
    final class Coordinator {
        private(set) var url: URL?
        var onReadyForDisplay: ((Bool) -> Void)?

        private var player: AVQueuePlayer?
        private var looper: AVPlayerLooper?
        private var readyObservation: NSKeyValueObservation?
        private var lifecycleObservers: [NSObjectProtocol] = []
        private var isPlaying = false
        private var didConfigureAudio = false

        func attach(to controller: AVPlayerViewController) {
            observeResumeEvents()
            readyObservation = controller.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak self] controller, _ in
                let isReady = controller.isReadyForDisplay
                let coordinator = self
                Task { @MainActor in coordinator?.onReadyForDisplay?(isReady) }
            }
        }

        func load(_ url: URL, into controller: AVPlayerViewController) {
            stopPlayer()
            self.url = url
            let player = AVQueuePlayer()
            player.isMuted = true
            looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
            controller.player = player
            self.player = player
            isPlaying = false
        }

        func setMuted(_ isMuted: Bool) {
            guard let player, player.isMuted != isMuted else { return }
            player.isMuted = isMuted
            // A result being watched with sound keeps the screen awake; silent previews don't.
            player.preventsDisplaySleepDuringVideoPlayback = !isMuted
        }

        func setPlaying(_ shouldPlay: Bool) {
            guard let player, shouldPlay != isPlaying else { return }
            isPlaying = shouldPlay
            if shouldPlay {
                if !player.isMuted { configureAudioSessionOnce() }
                player.play()
            } else {
                player.pause()
            }
        }

        func teardown(_ controller: AVPlayerViewController) {
            readyObservation?.invalidate()
            readyObservation = nil
            lifecycleObservers.forEach(NotificationCenter.default.removeObserver)
            lifecycleObservers.removeAll()
            stopPlayer()
            controller.player = nil
            url = nil
        }

        /// The system pauses players when the app goes to the background or a call interrupts audio;
        /// a view that should still be playing resumes when the app is active again.
        private func observeResumeEvents() {
            let center = NotificationCenter.default
            let names: [Notification.Name] = [UIApplication.didBecomeActiveNotification, AVAudioSession.interruptionNotification]
            lifecycleObservers = names.map { name in
                center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated { self?.resumeIfNeeded() }
                }
            }
        }

        private func resumeIfNeeded() {
            guard isPlaying, let player, player.timeControlStatus == .paused,
                  UIApplication.shared.applicationState == .active else { return }
            player.play()
        }

        private func stopPlayer() {
            player?.pause()
            looper?.disableLooping()
            looper = nil
            player?.removeAllItems()
            player = nil
        }

        /// The default ambient session is silenced by the ringer switch; a result the user chose to play should be heard.
        /// Mixing keeps the user's music alive for the muted previews elsewhere in the app.
        private func configureAudioSessionOnce() {
            guard !didConfigureAudio else { return }
            didConfigureAudio = true
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: .mixWithOthers)
            } catch {
                Logger(subsystem: "com.labs.fviu", category: "playback")
                    .error("Audio session setup failed: \(error.localizedDescription)")
            }
        }
    }
}
