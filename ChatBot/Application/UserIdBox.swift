import Foundation

/// Thread-safe holder for the current user id read by the network layer off the main actor.
final class UserIdBox: @unchecked Sendable {
    private let lock = NSLock()
    private var storage = ""

    var value: String {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }
}
