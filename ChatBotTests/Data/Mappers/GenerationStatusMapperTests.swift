import Foundation
import Testing
@testable import ChatBot

@Suite("GenerationStatusMapper")
struct GenerationStatusMapperTests {
    private let url = "https://cdn.example.com/video.mp4"

    private func map(_ status: String, url: String?) -> RemoteGenerationStatus {
        GenerationStatusMapper.map(GenerationStatusDTO(status: status, videoUrl: url))
    }

    @Test("Success statuses with a URL succeed", arguments: ["success", "succeeded", "completed", "done", "SUCCESS", "Done"])
    func success(status: String) {
        #expect(map(status, url: url) == .succeeded(videoURL: Fixtures.remoteVideoURL))
    }

    @Test("Success without a URL is a failure", arguments: ["success", "completed"])
    func successWithoutURL(status: String) {
        #expect(map(status, url: nil) == .failed)
    }

    @Test("Error statuses fail", arguments: ["error", "failed", "failure", "ERROR"])
    func failure(status: String) {
        #expect(map(status, url: nil) == .failed)
    }

    @Test("Error status ignores a URL", arguments: ["error", "failed"])
    func failureWithURL(status: String) {
        #expect(map(status, url: url) == .failed)
    }

    @Test("In-flight and unknown statuses keep generating", arguments: ["generating", "pending", "queued", "processing", "", "???"])
    func generating(status: String) {
        #expect(map(status, url: nil) == .generating)
    }

    @Test("A video URL on an in-flight status is not enough to finish")
    func generatingWithURL() {
        #expect(map("generating", url: url) == .generating)
    }
}
