import Foundation

protocol APIClient: Sendable {
    func send<Response: Decodable>(_ endpoint: Endpoint, as type: Response.Type) async throws -> Response
}
