import Foundation

enum GenerationStatusMapper {
    static func map(_ dto: GenerationStatusDTO) -> RemoteGenerationStatus {
        switch dto.status.lowercased() {
        case "success", "succeeded", "completed", "done":
            guard let url = dto.videoUrl.flatMap(URL.init(string:)) else { return .failed }
            return .succeeded(videoURL: url)
        case "error", "failed", "failure":
            return .failed
        default:
            return .generating
        }
    }
}
