import Foundation

struct StubError: LocalizedError, Equatable {
    let message: String

    init(_ message: String = "stub failure") {
        self.message = message
    }

    var errorDescription: String? { message }
}
