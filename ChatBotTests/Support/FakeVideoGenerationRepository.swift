import Foundation
@testable import ChatBot

/// Scripted backend: results are consumed in order and the last one repeats.
final class FakeVideoGenerationRepository: VideoGenerationRepository, @unchecked Sendable {
    struct StartCall: Equatable {
        let templateId: Int
        let imageData: Data
        let quality: VideoQuality
    }

    private struct State {
        var startResults: [Result<String, Error>] = [.success("job-1")]
        var statusResults: [Result<RemoteGenerationStatus, Error>] = [.success(.generating)]
        var startCalls: [StartCall] = []
        var statusCalls: [String] = []
        var startGate: AsyncGate?
        var statusGate: AsyncGate?
    }

    private let state = Locked(State())

    init(
        startResults: [Result<String, Error>] = [.success("job-1")],
        statusResults: [Result<RemoteGenerationStatus, Error>] = [.success(.generating)]
    ) {
        state.withLock {
            $0.startResults = startResults
            $0.statusResults = statusResults
        }
    }

    var startCalls: [StartCall] { state.current.startCalls }
    var statusCalls: [String] { state.current.statusCalls }

    func setStartGate(_ gate: AsyncGate?) {
        state.withLock { $0.startGate = gate }
    }

    func setStatusGate(_ gate: AsyncGate?) {
        state.withLock { $0.statusGate = gate }
    }

    func setStartResults(_ results: [Result<String, Error>]) {
        state.withLock { $0.startResults = results }
    }

    func startGeneration(templateId: Int, imageData: Data, quality: VideoQuality) async throws -> String {
        let (result, gate) = state.withLock { state -> (Result<String, Error>, AsyncGate?) in
            state.startCalls.append(StartCall(templateId: templateId, imageData: imageData, quality: quality))
            let result = state.startResults.count > 1 ? state.startResults.removeFirst() : state.startResults[0]
            return (result, state.startGate)
        }
        try await gate?.wait()
        return try result.get()
    }

    func status(ofJob jobId: String) async throws -> RemoteGenerationStatus {
        let (result, gate) = state.withLock { state -> (Result<RemoteGenerationStatus, Error>, AsyncGate?) in
            state.statusCalls.append(jobId)
            let result = state.statusResults.count > 1 ? state.statusResults.removeFirst() : state.statusResults[0]
            return (result, state.statusGate)
        }
        try await gate?.wait()
        return try result.get()
    }
}
