import ImageIO
import UIKit

/// Prepares the picked photo for template generation: center-crops it to the chosen format
/// (the template takes the aspect ratio from the source frame), downsizes and encodes as JPEG.
enum SourceImageProcessor {
    enum ProcessingError: LocalizedError {
        case unreadableImage

        var errorDescription: String? {
            String(localized: "Upload failed")
        }
    }

    static let maxPixelSide: CGFloat = 1536
    static let compressionQuality: CGFloat = 0.85

    /// Runs off the main actor; ImageIO decodes straight to the target size,
    /// so a 48 MP photo never lands in memory at full resolution.
    static func prepare(_ data: Data, format: VideoFormat) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            try encode(data, format: format)
        }.value
    }

    private static func encode(_ data: Data, format: VideoFormat) throws -> Data {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw ProcessingError.unreadableImage
        }
        // Decode a little larger than needed so the crop still fills `maxPixelSide`.
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSide * 2
        ] as CFDictionary
        guard let decoded = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else {
            throw ProcessingError.unreadableImage
        }
        let cropped = decoded.cropping(to: centerCropRect(for: decoded, aspectRatio: format.aspectRatio)) ?? decoded
        guard let jpeg = resize(cropped, maxSide: maxPixelSide).jpegData(compressionQuality: compressionQuality) else {
            throw ProcessingError.unreadableImage
        }
        return jpeg
    }

    private static func centerCropRect(for image: CGImage, aspectRatio: CGFloat) -> CGRect {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        if width / height > aspectRatio {
            let targetWidth = height * aspectRatio
            return CGRect(x: (width - targetWidth) / 2, y: 0, width: targetWidth, height: height)
        } else {
            let targetHeight = width / aspectRatio
            return CGRect(x: 0, y: (height - targetHeight) / 2, width: width, height: targetHeight)
        }
    }

    private static func resize(_ image: CGImage, maxSide: CGFloat) -> UIImage {
        let size = CGSize(width: image.width, height: image.height)
        let scale = min(1, maxSide / max(size.width, size.height))
        guard scale < 1 else { return UIImage(cgImage: image) }
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            UIImage(cgImage: image).draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
