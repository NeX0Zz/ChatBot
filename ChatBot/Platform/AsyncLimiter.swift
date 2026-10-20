/// Caps how many async operations run at once; extra callers wait in FIFO order.
actor AsyncLimiter {
    private let limit: Int
    private var running = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    init(limit: Int) {
        self.limit = limit
    }

    func run<T: Sendable>(_ operation: @Sendable () async -> T) async -> T {
        await acquire()
        let result = await operation()
        release()
        return result
    }

    private func acquire() async {
        guard running >= limit else {
            running += 1
            return
        }
        await withCheckedContinuation { waiters.append($0) }
    }

    private func release() {
        if waiters.isEmpty {
            running -= 1
        } else {
            waiters.removeFirst().resume()
        }
    }
}
