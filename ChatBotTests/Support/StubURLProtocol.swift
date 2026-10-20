import Foundation

struct CapturedRequest: Sendable {
    let request: URLRequest
    let body: Data?

    var url: URL? { request.url }
    var method: String? { request.httpMethod }

    func header(_ name: String) -> String? {
        request.value(forHTTPHeaderField: name)
    }

    var queryItems: [URLQueryItem] {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return [] }
        return components.queryItems ?? []
    }

    func queryValue(_ name: String) -> String? {
        queryItems.first { $0.name == name }?.value
    }
}

enum StubResponse: Sendable {
    case http(status: Int, body: Data = Data())
    case nonHTTP

    static func json(status: Int = 200, _ body: String) -> StubResponse {
        .http(status: status, body: Data(body.utf8))
    }
}

/// An isolated fake backend: each instance owns a unique host, so parallel tests never share handlers.
final class StubServer: @unchecked Sendable {
    typealias Handler = @Sendable (CapturedRequest) throws -> StubResponse

    let host = "stub-\(UUID().uuidString.lowercased()).test"
    private let handler: Handler
    private let captured = Locked<[CapturedRequest]>([])

    init(_ handler: @escaping Handler) {
        self.handler = handler
        StubURLProtocol.register(self)
    }

    deinit {
        StubURLProtocol.unregister(host: host)
    }

    var baseURL: URL {
        URL(string: "https://\(host)/base") ?? URL(fileURLWithPath: "/")
    }

    var requests: [CapturedRequest] { captured.current }

    var session: URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    fileprivate func respond(to request: CapturedRequest) throws -> StubResponse {
        captured.withLock { $0.append(request) }
        return try handler(request)
    }
}

final class StubURLProtocol: URLProtocol {
    private static let servers = Locked<[String: StubServer]>([:])

    fileprivate static func register(_ server: StubServer) {
        servers.withLock { $0[server.host] = server }
    }

    fileprivate static func unregister(host: String) {
        servers.withLock { $0[host] = nil }
    }

    private static func server(for request: URLRequest) -> StubServer? {
        guard let host = request.url?.host else { return nil }
        return servers.withLock { $0[host] }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        server(for: request) != nil
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let server = Self.server(for: request), let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let captured = CapturedRequest(request: request, body: Self.bodyData(of: request))
        do {
            switch try server.respond(to: captured) {
            case let .http(status, body):
                guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil) else {
                    client?.urlProtocol(self, didFailWithError: URLError(.cannotParseResponse))
                    return
                }
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: body)
            case .nonHTTP:
                let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// URLSession turns `httpBody` into a stream before it reaches a protocol.
    private static func bodyData(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return data
    }
}
