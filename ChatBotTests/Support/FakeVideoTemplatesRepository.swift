import Foundation
@testable import ChatBot

final class FakeVideoTemplatesRepository: VideoTemplatesRepository, @unchecked Sendable {
    private struct State {
        var result: Result<[VideoTemplate], Error> = .success([])
        var gate: AsyncGate?
        var fetchCount = 0
    }

    private let state = Locked(State())

    init(result: Result<[VideoTemplate], Error> = .success([]), gate: AsyncGate? = nil) {
        state.withLock {
            $0.result = result
            $0.gate = gate
        }
    }

    var fetchCount: Int { state.current.fetchCount }

    func setResult(_ result: Result<[VideoTemplate], Error>) {
        state.withLock { $0.result = result }
    }

    func fetchTemplates() async throws -> [VideoTemplate] {
        let (result, gate) = state.withLock { state -> (Result<[VideoTemplate], Error>, AsyncGate?) in
            state.fetchCount += 1
            return (state.result, state.gate)
        }
        try await gate?.wait()
        return try result.get()
    }
}
