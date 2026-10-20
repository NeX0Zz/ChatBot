import Foundation
import Testing
@testable import ChatBot

@Suite("URLSessionAPIClient")
struct URLSessionAPIClientTests {
    private struct Pong: Decodable, Equatable {
        let value: String
    }

    private func makeClient(_ server: StubServer) -> URLSessionAPIClient {
        URLSessionAPIClient(
            configuration: .init(bearerToken: "secret-token", applicationId: "com.app.id", timeout: 7),
            session: server.session,
            userIdProvider: { "user-42" }
        )
    }

    private func okServer(_ json: String = #"{"value":"pong"}"#) -> StubServer {
        StubServer { _ in .json(json) }
    }

    // MARK: - Request building

    @Test("Adds Bearer token, Accept header, method and timeout")
    func buildsHeaders() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping", method: .post)

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.header("Authorization") == "Bearer secret-token")
        #expect(request.header("Accept") == "application/json")
        #expect(request.method == "POST")
        #expect(request.request.timeoutInterval == 7)
    }

    @Test("Multipart uploads use the upload timeout, JSON calls the regular one")
    func uploadTimeout() async throws {
        let server = okServer()
        let client = URLSessionAPIClient(
            configuration: .init(bearerToken: "t", applicationId: "app", timeout: 7, uploadTimeout: 99),
            session: server.session,
            userIdProvider: { "u" }
        )
        var form = MultipartFormData()
        form.append("1", name: "a")

        _ = try await client.send(Endpoint(baseURL: server.baseURL, path: "upload", method: .post, body: .multipart(form)), as: Pong.self)
        _ = try await client.send(Endpoint(baseURL: server.baseURL, path: "ping"), as: Pong.self)

        #expect(server.requests.map(\.request.timeoutInterval) == [99, 7])
    }

    @Test("Multipart uploads fall back to the regular timeout when no upload timeout is set")
    func uploadTimeoutFallback() async throws {
        let server = okServer()
        var form = MultipartFormData()
        form.append("1", name: "a")

        _ = try await makeClient(server).send(Endpoint(baseURL: server.baseURL, path: "upload", method: .post, body: .multipart(form)), as: Pong.self)

        #expect(server.requests.first?.request.timeoutInterval == 7)
    }

    @Test("Appends the endpoint path to the base URL")
    func buildsPath() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "api/v1/status", includesUserContext: false)

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.url?.path == "/base/api/v1/status")
        #expect(request.method == "GET")
    }

    @Test("Adds user_id and app_id when the endpoint includes user context")
    func addsUserContext() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.queryValue("user_id") == "user-42")
        #expect(request.queryValue("app_id") == "com.app.id")
    }

    @Test("Keeps own query items next to the user context")
    func keepsExistingQueryItems() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "status", queryItems: [URLQueryItem(name: "id", value: "job-7")])

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.queryValue("id") == "job-7")
        #expect(request.queryValue("user_id") == "user-42")
        #expect(request.queryItems.count == 3)
    }

    @Test("Omits user context and query entirely when the endpoint opts out")
    func omitsUserContext() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "templates", includesUserContext: false)

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.queryItems.isEmpty)
        #expect(request.url?.query == nil)
    }

    @Test("Sends JSON body with Content-Type")
    func sendsJSONBody() async throws {
        let server = okServer()
        let payload = Data(#"{"message":"hi"}"#.utf8)
        let endpoint = Endpoint(baseURL: server.baseURL, path: "chat", method: .post, body: .json(payload))

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.header("Content-Type") == "application/json")
        #expect(request.body == payload)
    }

    @Test("Sends multipart body with the boundary in Content-Type")
    func sendsMultipartBody() async throws {
        let server = okServer()
        var form = MultipartFormData()
        form.append("42", name: "template_id")
        form.append(Data("IMG".utf8), name: "image", fileName: "photo.jpg", mimeType: "image/jpeg")
        let endpoint = Endpoint(baseURL: server.baseURL, path: "upload", method: .post, body: .multipart(form))

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.header("Content-Type") == "multipart/form-data; boundary=\(form.boundary)")
        #expect(request.body == form.encoded())
    }

    @Test("Requests without a body have no Content-Type")
    func noBodyNoContentType() async throws {
        let server = okServer()
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        _ = try await makeClient(server).send(endpoint, as: Pong.self)

        let request = try #require(server.requests.first)
        #expect(request.header("Content-Type") == nil)
        #expect(request.body == nil || request.body?.isEmpty == true)
    }

    // MARK: - Status mapping

    @Test("Decodes a 2xx response", arguments: [200, 201])
    func decodesSuccess(status: Int) async throws {
        let server = StubServer { _ in .json(status: status, #"{"value":"pong"}"#) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        let pong = try await makeClient(server).send(endpoint, as: Pong.self)

        #expect(pong == Pong(value: "pong"))
    }

    @Test("Maps HTTP status codes to APIError", arguments: [
        (401, APIError.unauthorized),
        (403, APIError.unauthorized),
        (402, APIError.insufficientBalance),
        (404, APIError.server(statusCode: 404)),
        (500, APIError.server(statusCode: 500)),
        (503, APIError.server(statusCode: 503))
    ])
    func mapsStatusCodes(status: Int, expected: APIError) async {
        let server = StubServer { _ in .json(status: status, #"{"value":"ignored"}"#) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: expected) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps malformed JSON to .decoding")
    func mapsInvalidJSON() async {
        let server = okServer("not json")
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.decoding) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps JSON of the wrong shape and an empty body to .decoding", arguments: [#"{"other":1}"#, ""])
    func mapsWrongShape(json: String) async {
        let server = okServer(json)
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.decoding) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps a non-HTTP response to .invalidResponse")
    func mapsNonHTTPResponse() async {
        let server = StubServer { _ in .nonHTTP }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.invalidResponse) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    // MARK: - Transport errors

    @Test("Maps connectivity errors to .offline", arguments: [
        URLError.Code.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost
    ])
    func mapsOffline(code: URLError.Code) async {
        let server = StubServer { _ in throw URLError(code) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.offline) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps timedOut to .timeout")
    func mapsTimeout() async {
        let server = StubServer { _ in throw URLError(.timedOut) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.timeout) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps cancelled to CancellationError")
    func mapsCancelled() async {
        let server = StubServer { _ in throw URLError(.cancelled) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: CancellationError.self) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Maps other URL errors to .invalidResponse")
    func mapsOtherURLErrors() async {
        let server = StubServer { _ in throw URLError(.badServerResponse) }
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        await #expect(throws: APIError.invalidResponse) {
            _ = try await makeClient(server).send(endpoint, as: Pong.self)
        }
    }

    @Test("Resolves the user id at send time")
    func resolvesUserIdLazily() async throws {
        let server = okServer()
        let currentUser = Locked("first")
        let client = URLSessionAPIClient(
            configuration: .init(bearerToken: "t", applicationId: "app", timeout: 5),
            session: server.session,
            userIdProvider: { currentUser.current }
        )
        let endpoint = Endpoint(baseURL: server.baseURL, path: "ping")

        _ = try await client.send(endpoint, as: Pong.self)
        currentUser.withLock { $0 = "second" }
        _ = try await client.send(endpoint, as: Pong.self)

        #expect(server.requests.map { $0.queryValue("user_id") } == ["first", "second"])
    }
}
