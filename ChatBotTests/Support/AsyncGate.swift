import Foundation

/// Suspends callers until `open()` is called. Waiting is cancellable, which lets tests observe task cancellation.
final class AsyncGate: @unchecked Sendable {
    private struct State {
        var isOpen = false
        var waiters: [UUID: CheckedContinuation<Void, Error>] = [:]
        var cancelledBeforeWait: Set<UUID> = []
        var cancelledCount = 0
    }

    private let state = Locked(State())

    var waiterCount: Int { state.withLock { $0.waiters.count } }
    var cancelledCount: Int { state.withLock { $0.cancelledCount } }

    func wait() async throws {
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                enum Action { case resume, cancel, park }
                let action = state.withLock { state -> Action in
                    if state.isOpen { return .resume }
                    if state.cancelledBeforeWait.contains(id) { return .cancel }
                    state.waiters[id] = continuation
                    return .park
                }
                switch action {
                case .resume: continuation.resume()
                case .cancel: continuation.resume(throwing: CancellationError())
                case .park: break
                }
            }
        } onCancel: {
            let continuation = state.withLock { state -> CheckedContinuation<Void, Error>? in
                state.cancelledCount += 1
                guard let waiter = state.waiters.removeValue(forKey: id) else {
                    state.cancelledBeforeWait.insert(id)
                    return nil
                }
                return waiter
            }
            continuation?.resume(throwing: CancellationError())
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Error>] in
            state.isOpen = true
            defer { state.waiters = [:] }
            return Array(state.waiters.values)
        }
        waiters.forEach { $0.resume() }
    }
}
