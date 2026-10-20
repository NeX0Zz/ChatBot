import Foundation
import Testing
@testable import ChatBot

@Suite("VideoEndpoints and ChatEndpoints")
struct VideoEndpointsTests {
    private let baseURL = URL(string: "https://example.com/pixverse") ?? URL(fileURLWithPath: "/")

    @Test("Templates endpoint is a GET without user context")
    func templates() {
        let endpoint = VideoEndpoints.templates(applicationId: "com.test.test", baseURL: baseURL)

        #expect(endpoint.path == "api/v1/get_templates/com.test.test")
        #expect(endpoint.method == .get)
        #expect(endpoint.includesUserContext == false)
        #expect(endpoint.baseURL == baseURL)
    }

    @Test("Template-to-video endpoint is a multipart POST with user context")
    func templateToVideo() throws {
        let endpoint = VideoEndpoints.templateToVideo(templateId: 7, imageData: Data("IMG".utf8), quality: .p540, baseURL: baseURL)

        #expect(endpoint.path == "api/v1/template2video")
        #expect(endpoint.method == .post)
        #expect(endpoint.includesUserContext)
        let body = try #require(endpoint.multipartBody)
        #expect(body.contains("name=\"template_id\"\r\n\r\n7\r\n"))
        #expect(body.contains("name=\"quality\"\r\n\r\n540p\r\n"))
        #expect(body.contains("name=\"image\"; filename=\"photo.jpg\"\r\nContent-Type: image/jpeg\r\n\r\nIMG\r\n"))
    }

    @Test("Status endpoint carries the job id as a query item")
    func status() {
        let endpoint = VideoEndpoints.status(jobId: "job-9", baseURL: baseURL)

        #expect(endpoint.path == "api/v1/status")
        #expect(endpoint.method == .get)
        #expect(endpoint.queryItems == [URLQueryItem(name: "id", value: "job-9")])
        #expect(endpoint.includesUserContext)
    }

    @Test("Send-message endpoint posts a JSON message to the chat path")
    func sendMessage() throws {
        let endpoint = try ChatEndpoints.sendMessage("hello", chatId: "abc", baseURL: baseURL)

        #expect(endpoint.path == "dola/chats/abc/messages")
        #expect(endpoint.method == .post)
        let body = try #require(endpoint.jsonBody)
        let object = try JSONSerialization.jsonObject(with: body) as? [String: String]
        #expect(object == ["message": "hello"])
    }
}
