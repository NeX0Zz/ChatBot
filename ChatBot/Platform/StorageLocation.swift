import Foundation

enum StorageLocation {
    static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("Storage", isDirectory: true)
    }

    static var sourceImages: URL {
        root.appendingPathComponent("SourceImages", isDirectory: true)
    }

    /// First-frame thumbnails of template previews and results; regenerated when purged.
    static var thumbnails: URL {
        cachesRoot.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    /// Downloaded result videos. Lives in Caches: the system may purge it, the remote URL stays the source.
    static var videoCache: URL {
        cachesRoot.appendingPathComponent("Videos", isDirectory: true)
    }

    private static var cachesRoot: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }
}
