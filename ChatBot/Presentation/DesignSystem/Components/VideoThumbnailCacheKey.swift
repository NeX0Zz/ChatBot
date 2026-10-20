import SwiftUI

private struct VideoThumbnailCacheKey: EnvironmentKey {
    static let defaultValue = VideoThumbnailCache()
}

extension EnvironmentValues {
    var thumbnailCache: VideoThumbnailCache {
        get { self[VideoThumbnailCacheKey.self] }
        set { self[VideoThumbnailCacheKey.self] = newValue }
    }
}
