import AVFoundation
import CryptoKit
import UIKit

/// First-frame thumbnails for remote and local videos: memory cache, disk cache in Caches,
/// de-duplicated in-flight requests and a cap on concurrent decoders so a fast scroll
/// over the template grid doesn't open dozens of connections.
actor VideoThumbnailCache {
    private static let maxConcurrentDecoders = 4
    private static let memoryLimit = 96 * 1024 * 1024

    // NSCache is thread-safe; it is read synchronously so a cell re-entering the screen shows its image at once.
    private nonisolated(unsafe) let memory = NSCache<NSString, UIImage>()
    private let directory: URL
    private let limiter = AsyncLimiter(limit: maxConcurrentDecoders)
    private var inFlight: [String: Task<UIImage?, Never>] = [:]

    init(directory: URL = StorageLocation.thumbnails) {
        self.directory = directory
        memory.totalCostLimit = Self.memoryLimit
    }

    nonisolated func cachedImage(for url: URL, minPixelSide: CGFloat) -> UIImage? {
        guard let image = memory.object(forKey: url.absoluteString as NSString),
              Self.pixelSide(of: image) >= minPixelSide * 0.9 else { return nil }
        return image
    }

    func thumbnail(for url: URL, maxPixelSide: CGFloat) async -> UIImage? {
        if let cached = cachedImage(for: url, minPixelSide: maxPixelSide) { return cached }
        let key = url.absoluteString
        if let task = inFlight[key] { return await task.value }

        let fileURL = directory.appendingPathComponent(Self.fileName(for: url))
        let task = Task { [limiter] () -> UIImage? in
            if let stored = Self.loadFromDisk(fileURL), Self.pixelSide(of: stored) >= maxPixelSide * 0.9 {
                return stored
            }
            let generated = await limiter.run { await Self.generate(from: url, maxPixelSide: maxPixelSide) }
            if let generated { Self.saveToDisk(generated, at: fileURL) }
            return generated
        }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        if let image {
            memory.setObject(image, forKey: key as NSString, cost: Self.cost(of: image))
        }
        return image
    }

    func removeAll() {
        memory.removeAllObjects()
        try? FileManager.default.removeItem(at: directory) // Missing folder means there is nothing to clear.
    }

    private static let generationTimeout: UInt64 = 15_000_000_000

    /// A stalled remote read would hold a decoder slot forever, so generation is raced against a timeout.
    private static func generate(from url: URL, maxPixelSide: CGFloat) async -> UIImage? {
        let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSide, height: maxPixelSide)
        let image = await withTaskGroup(of: CGImage?.self) { group in
            group.addTask { try? await generator.image(at: .zero).image }
            group.addTask {
                try? await Task.sleep(nanoseconds: generationTimeout)
                generator.cancelAllCGImageGeneration()
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        return image.map(UIImage.init(cgImage:))
    }

    private static func loadFromDisk(_ fileURL: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }

    private static func saveToDisk(_ image: UIImage, at fileURL: URL) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic) // A failed write only costs a regeneration next launch.
    }

    private static func pixelSide(of image: UIImage) -> CGFloat {
        max(image.size.width, image.size.height) * image.scale
    }

    private static func cost(of image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }

    private static func fileName(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined() + ".jpg"
    }
}
