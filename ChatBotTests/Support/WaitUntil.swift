import Foundation
import Testing

/// Polls `condition` on the main actor until it holds. Records an issue on timeout instead of hanging.
@MainActor
@discardableResult
func waitUntil(
    timeout: TimeInterval = 5,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ condition: @MainActor () -> Bool
) async -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            Issue.record("Condition was not met within \(timeout) s", sourceLocation: sourceLocation)
            return false
        }
        try? await Task.sleep(nanoseconds: 2_000_000)
    }
    return true
}
