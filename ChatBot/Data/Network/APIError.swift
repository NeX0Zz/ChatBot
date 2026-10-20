import Foundation

enum APIError: LocalizedError, Equatable {
    case offline
    case timeout
    case unauthorized
    case insufficientBalance
    case server(statusCode: Int)
    case invalidResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .offline:
            String(localized: "No internet connection. Check your network and try again.")
        case .timeout:
            String(localized: "The request timed out. Please try again.")
        case .unauthorized:
            String(localized: "Authorization failed. Please restart the app.")
        case .insufficientBalance:
            String(localized: "Generation limit reached. Please try again later.")
        case .server, .invalidResponse, .decoding:
            String(localized: "Something went wrong. Please try again.")
        }
    }

    /// Errors worth retrying on the next polling tick: the job may still be running on the backend.
    var isTransient: Bool {
        switch self {
        case .offline, .timeout, .invalidResponse, .decoding:
            true
        case let .server(statusCode):
            statusCode >= 500
        case .unauthorized, .insufficientBalance:
            false
        }
    }

    init(urlError: URLError) {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost:
            self = .offline
        case .timedOut:
            self = .timeout
        default:
            self = .invalidResponse
        }
    }

    init(statusCode: Int) {
        switch statusCode {
        case 401, 403: self = .unauthorized
        case 402: self = .insufficientBalance
        default: self = .server(statusCode: statusCode)
        }
    }
}
