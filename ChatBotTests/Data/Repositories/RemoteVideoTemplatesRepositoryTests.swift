import Foundation
import Testing
@testable import ChatBot

@Suite("RemoteVideoTemplatesRepository")
struct RemoteVideoTemplatesRepositoryTests {
    private let baseURL = URL(string: "https://example.com/pixverse") ?? URL(fileURLWithPath: "/")

    private func repository(json: String = #"{"templates":[]}"#, error: Error? = nil) -> (RemoteVideoTemplatesRepository, FakeAPIClient) {
        let client = FakeAPIClient(json: json, error: error)
        return (RemoteVideoTemplatesRepository(client: client, baseURL: baseURL, applicationId: "com.test.test"), client)
    }

    @Test("Requests the catalog of the application without user context")
    func endpoint() async throws {
        let (repository, client) = repository()

        _ = try await repository.fetchTemplates()

        let endpoint = try #require(client.endpoints.first)
        #expect(client.endpoints.count == 1)
        #expect(endpoint.path == "api/v1/get_templates/com.test.test")
        #expect(endpoint.method == .get)
        #expect(endpoint.includesUserContext == false)
        #expect(endpoint.baseURL == baseURL)
    }

    @Test("Filters out inactive templates and keeps those without a flag")
    func filtersInactive() async throws {
        let json = """
        {"templates": [
          {"id": 1, "template_id": 11, "name": "Active", "is_active": true},
          {"id": 2, "template_id": 22, "name": "Hidden", "is_active": false},
          {"id": 3, "template_id": 33, "name": "Unflagged"}
        ]}
        """
        let (repository, _) = repository(json: json)

        let templates = try await repository.fetchTemplates()

        #expect(templates.map(\.id) == [1, 3])
    }

    @Test("Maps DTO fields into domain templates")
    func mapsTemplates() async throws {
        let json = """
        {"templates": [{"id": 1, "template_id": 11, "name": "Dance", "category": "📈 Trending", "prompt": "p",
          "duration": 9, "qualities": ["540p", "weird"], "preview_small": "https://x.test/s.mp4", "is_active": true}]}
        """
        let (repository, _) = repository(json: json)

        let template = try #require(try await repository.fetchTemplates().first)

        #expect(template.templateId == 11)
        #expect(template.category == "Trending")
        #expect(template.duration == 9)
        #expect(template.qualities == [.p540])
        #expect(template.previewURL?.absoluteString == "https://x.test/s.mp4")
    }

    @Test("Empty catalog gives an empty list")
    func emptyCatalog() async throws {
        let (repository, _) = repository()

        #expect(try await repository.fetchTemplates().isEmpty)
    }

    @Test("Propagates client errors")
    func propagatesError() async {
        let (repository, _) = repository(error: APIError.offline)

        await #expect(throws: APIError.offline) {
            _ = try await repository.fetchTemplates()
        }
    }

    @Test("A broken catalog payload fails instead of returning partial data")
    func brokenPayload() async {
        let (repository, _) = repository(json: #"{"templates":[{"id":1}]}"#)

        await #expect(throws: DecodingError.self) {
            _ = try await repository.fetchTemplates()
        }
    }
}
