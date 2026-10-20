import Foundation
import Testing
@testable import ChatBot

@Suite("RemoteVideoGenerationRepository")
struct RemoteVideoGenerationRepositoryTests {
    private let baseURL = URL(string: "https://example.com/pixverse") ?? URL(fileURLWithPath: "/")

    @Test("Uploads the template, quality and image as multipart")
    func startGeneration() async throws {
        let client = FakeAPIClient(json: #"{"video_id": 99}"#)
        let repository = RemoteVideoGenerationRepository(client: client, baseURL: baseURL)

        let jobId = try await repository.startGeneration(templateId: 7, imageData: Data("PIXELS".utf8), quality: .p1080)

        #expect(jobId == "99")
        let endpoint = try #require(client.endpoints.first)
        #expect(client.endpoints.count == 1)
        #expect(endpoint.path == "api/v1/template2video")
        #expect(endpoint.method == .post)
        #expect(endpoint.baseURL == baseURL)
        let body = try #require(endpoint.multipartBody)
        #expect(body.contains("name=\"template_id\"\r\n\r\n7\r\n"))
        #expect(body.contains("name=\"quality\"\r\n\r\n1080p\r\n"))
        #expect(body.contains("PIXELS"))
    }

    @Test("Accepts a string job id")
    func stringJobId() async throws {
        let client = FakeAPIClient(json: #"{"video_id": "job-abc"}"#)

        let jobId = try await RemoteVideoGenerationRepository(client: client, baseURL: baseURL)
            .startGeneration(templateId: 1, imageData: Data(), quality: .p720)

        #expect(jobId == "job-abc")
    }

    @Test("Start propagates client errors", arguments: [APIError.insufficientBalance, .unauthorized, .server(statusCode: 500)])
    func startError(error: APIError) async {
        let repository = RemoteVideoGenerationRepository(client: FakeAPIClient(error: error), baseURL: baseURL)

        await #expect(throws: error) {
            _ = try await repository.startGeneration(templateId: 1, imageData: Data(), quality: .p720)
        }
    }

    @Test("Status queries the job id and maps a finished job")
    func statusSucceeded() async throws {
        let client = FakeAPIClient(json: #"{"status":"success","video_url":"https://cdn.example.com/video.mp4"}"#)
        let repository = RemoteVideoGenerationRepository(client: client, baseURL: baseURL)

        let status = try await repository.status(ofJob: "job-5")

        #expect(status == .succeeded(videoURL: Fixtures.remoteVideoURL))
        let endpoint = try #require(client.endpoints.first)
        #expect(endpoint.path == "api/v1/status")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [URLQueryItem(name: "id", value: "job-5")])
    }

    @Test("Status maps running and failed jobs")
    func statusOtherStates() async throws {
        let running = RemoteVideoGenerationRepository(client: FakeAPIClient(json: #"{"status":"generating"}"#), baseURL: baseURL)
        let failed = RemoteVideoGenerationRepository(client: FakeAPIClient(json: #"{"status":"error"}"#), baseURL: baseURL)

        #expect(try await running.status(ofJob: "1") == .generating)
        #expect(try await failed.status(ofJob: "1") == .failed)
    }

    @Test("Status propagates client errors")
    func statusError() async {
        let repository = RemoteVideoGenerationRepository(client: FakeAPIClient(error: APIError.timeout), baseURL: baseURL)

        await #expect(throws: APIError.timeout) {
            _ = try await repository.status(ofJob: "1")
        }
    }
}
