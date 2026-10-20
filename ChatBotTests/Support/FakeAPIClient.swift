import Foundation
@testable import ChatBot

/// Records every endpoint and answers with canned JSON (decoded like the real client would) or an error.
final class FakeAPIClient: APIClient, @unchecked Sendable {
    private struct State {
        var endpoints: [Endpoint] = []
        var json = "{}"
        var error: Error?
    }

    private let state = Locked(State())

    var endpoints: [Endpoint] { state.current.endpoints }

    init(json: String = "{}", error: Error? = nil) {
        state.withLock {
            $0.json = json
            $0.error = error
        }
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let (json, error) = state.withLock { state -> (String, Error?) in
            state.endpoints.append(endpoint)
            return (state.json, state.error)
        }
        if let error { throw error }
        return try JSONDecoder().decode(Response.self, from: Data(json.utf8))
    }
}

extension Endpoint {
    var jsonBody: Data? {
        if case let .json(data) = body { return data }
        return nil
    }

    var multipartBody: String? {
        if case let .multipart(form) = body { return String(decoding: form.encoded(), as: UTF8.self) }
        return nil
    }
}
