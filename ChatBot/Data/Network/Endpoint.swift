import Foundation

/// Describes a single API call. Concrete endpoints are built by the `*Endpoints` factories.
struct Endpoint: Sendable {
    let baseURL: URL
    let path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var body: RequestBody = .none
    /// Adds `user_id` and `app_id` query parameters required by the generation API.
    var includesUserContext = true
}
