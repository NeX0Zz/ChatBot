import Foundation
import Testing
@testable import ChatBot

@Suite("APIError")
struct APIErrorTests {
    @Test("Every error has a human-readable description", arguments: [
        APIError.offline, .timeout, .unauthorized, .insufficientBalance, .server(statusCode: 500), .invalidResponse, .decoding
    ])
    func hasDescription(error: APIError) {
        #expect(error.errorDescription?.isEmpty == false)
        #expect(error.localizedDescription == error.errorDescription)
    }

    @Test("Technical failures share one generic message")
    func genericMessage() {
        let generic = APIError.invalidResponse.errorDescription
        #expect(APIError.decoding.errorDescription == generic)
        #expect(APIError.server(statusCode: 502).errorDescription == generic)
    }

    @Test("Server errors with different codes are different values")
    func serverCodesDiffer() {
        #expect(APIError.server(statusCode: 500) != APIError.server(statusCode: 502))
    }

    @Test("Transient errors are worth retrying", arguments: [
        APIError.offline, .timeout, .invalidResponse, .decoding, .server(statusCode: 500), .server(statusCode: 503)
    ])
    func transient(error: APIError) {
        #expect(error.isTransient)
    }

    @Test("Permanent errors are not retried", arguments: [
        APIError.unauthorized, .insufficientBalance, .server(statusCode: 404), .server(statusCode: 400)
    ])
    func permanent(error: APIError) {
        #expect(error.isTransient == false)
    }
}
