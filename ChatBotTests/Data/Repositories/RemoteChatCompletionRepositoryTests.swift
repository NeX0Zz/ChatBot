import Foundation
import Testing
@testable import ChatBot

@Suite("RemoteChatCompletionRepository")
struct RemoteChatCompletionRepositoryTests {
    private let baseURL = URL(string: "https://example.com/root") ?? URL(fileURLWithPath: "/")

    @Test("Posts the message to the chat path and returns the assistant text")
    func reply() async throws {
        let client = FakeAPIClient(json: #"{"chat_id":"abc","assistant_message":"Hello!"}"#)
        let repository = RemoteChatCompletionRepository(client: client, baseURL: baseURL)

        let reply = try await repository.reply(to: "Hi", chatId: "abc")

        #expect(reply == "Hello!")
        let endpoint = try #require(client.endpoints.first)
        #expect(client.endpoints.count == 1)
        #expect(endpoint.path == "dola/chats/abc/messages")
        #expect(endpoint.method == .post)
        #expect(endpoint.baseURL == baseURL)
        let body = try #require(endpoint.jsonBody)
        #expect(try JSONSerialization.jsonObject(with: body) as? [String: String] == ["message": "Hi"])
    }

    @Test("Uses the given chat id in the path")
    func chatIdInPath() async throws {
        let client = FakeAPIClient(json: #"{"chat_id":"x","assistant_message":"ok"}"#)
        let repository = RemoteChatCompletionRepository(client: client, baseURL: baseURL)

        _ = try await repository.reply(to: "Hi", chatId: "11111111-2222-3333-4444-555555555555")

        #expect(client.endpoints.first?.path == "dola/chats/11111111-2222-3333-4444-555555555555/messages")
    }

    @Test("Sends user context with the request")
    func includesUserContext() async throws {
        let client = FakeAPIClient(json: #"{"chat_id":"x","assistant_message":"ok"}"#)

        _ = try await RemoteChatCompletionRepository(client: client, baseURL: baseURL).reply(to: "Hi", chatId: "x")

        #expect(client.endpoints.first?.includesUserContext == true)
    }

    @Test("Propagates client errors")
    func propagatesError() async {
        let client = FakeAPIClient(error: APIError.offline)
        let repository = RemoteChatCompletionRepository(client: client, baseURL: baseURL)

        await #expect(throws: APIError.offline) {
            _ = try await repository.reply(to: "Hi", chatId: "abc")
        }
    }

    @Test("Maps a malformed payload to a decoding failure")
    func malformedPayload() async {
        let client = FakeAPIClient(json: #"{"chat_id":"abc"}"#)
        let repository = RemoteChatCompletionRepository(client: client, baseURL: baseURL)

        await #expect(throws: DecodingError.self) {
            _ = try await repository.reply(to: "Hi", chatId: "abc")
        }
    }

    @Test("Keeps an empty assistant reply as is")
    func emptyReply() async throws {
        let client = FakeAPIClient(json: #"{"chat_id":"abc","assistant_message":""}"#)

        let reply = try await RemoteChatCompletionRepository(client: client, baseURL: baseURL).reply(to: "Hi", chatId: "abc")

        #expect(reply == "")
    }
}
