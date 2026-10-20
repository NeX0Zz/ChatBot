import Foundation

/// The single place that knows which caches "Clear cache" in Settings covers.
final class MediaCacheCleaner: Sendable {
    private let videoFileCache: VideoFileCache
    private let thumbnailCache: VideoThumbnailCache

    init(videoFileCache: VideoFileCache, thumbnailCache: VideoThumbnailCache) {
        self.videoFileCache = videoFileCache
        self.thumbnailCache = thumbnailCache
    }

    func sizeInBytes() async -> Int64 {
        await videoFileCache.sizeInBytes() + Int64(URLCache.shared.currentDiskUsage)
    }

    func clear() async throws {
        await thumbnailCache.removeAll()
        URLCache.shared.removeAllCachedResponses()
        try await videoFileCache.clear()
    }
}
