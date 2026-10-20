import Foundation
import OSLog

final class URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let configuration: Configuration
    private let userIdProvider: @Sendable () -> String
    private let decoder = JSONDecoder()
    private let logger = Logger(subsystem: "com.labs.fviu", category: "network")

    struct Configuration: Sendable {
        let bearerToken: String
        let applicationId: String
        let timeout: TimeInterval
        /// Multipart uploads carry a photo and get more time than plain JSON calls.
        var uploadTimeout: TimeInterval?
    }

    init(
        configuration: Configuration,
        session: URLSession = .shared,
        userIdProvider: @escaping @Sendable () -> String
    ) {
        self.configuration = configuration
        self.session = session
        self.userIdProvider = userIdProvider
    }

    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response {
        let request = try makeRequest(for: endpoint)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError {
            throw APIError(urlError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            logger.error("\(endpoint.method.rawValue) \(endpoint.path) failed with \(httpResponse.statusCode)")
            throw APIError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            logger.error("Decoding \(String(describing: Response.self)) failed: \(error.localizedDescription)")
            throw APIError.decoding
        }
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        let url = endpoint.baseURL.appendingPathComponent(endpoint.path)
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw APIError.invalidResponse
        }
        var queryItems = endpoint.queryItems
        if endpoint.includesUserContext {
            queryItems.append(URLQueryItem(name: "user_id", value: userIdProvider()))
            queryItems.append(URLQueryItem(name: "app_id", value: configuration.applicationId))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let requestURL = components.url else {
            throw APIError.invalidResponse
        }

        var request = URLRequest(url: requestURL, timeoutInterval: timeout(for: endpoint))
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(configuration.bearerToken)", forHTTPHeaderField: "Authorization")

        switch endpoint.body {
        case .none:
            break
        case let .json(data):
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = data
        case let .multipart(form):
            request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = form.encoded()
        }
        return request
    }

    private func timeout(for endpoint: Endpoint) -> TimeInterval {
        if case .multipart = endpoint.body, let uploadTimeout = configuration.uploadTimeout {
            return uploadTimeout
        }
        return configuration.timeout
    }
}
