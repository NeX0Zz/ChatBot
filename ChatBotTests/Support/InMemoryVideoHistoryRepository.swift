import Foundation
@testable import ChatBot

final class InMemoryVideoHistoryRepository: VideoHistoryRepository, @unchecked Sendable {
    private struct State {
        var generations: [VideoGeneration] = []
        var images: [String: Data] = [:]
        var saves: [[VideoGeneration]] = []
        var removedImages: [String] = []
        var loadError: Error?
        var storeError: Error?
        var imageCounter = 0
    }

    private let state = Locked(State())

    init(generations: [VideoGeneration] = [], loadError: Error? = nil, storeError: Error? = nil) {
        state.withLock {
            $0.generations = generations
            $0.loadError = loadError
            $0.storeError = storeError
        }
    }

    var saves: [[VideoGeneration]] { state.current.saves }
    var lastSave: [VideoGeneration]? { state.current.saves.last }
    var removedImages: [String] { state.current.removedImages }
    var storedImages: [String: Data] { state.current.images }

    func seed(_ generations: [VideoGeneration]) {
        state.withLock { $0.generations = generations }
    }

    func seedImage(_ data: Data, named name: String) {
        state.withLock { $0.images[name] = data }
    }

    func loadGenerations() async throws -> [VideoGeneration] {
        let (generations, error) = state.withLock { ($0.generations, $0.loadError) }
        if let error { throw error }
        return generations
    }

    func saveGenerations(_ generations: [VideoGeneration]) async throws {
        state.withLock {
            $0.saves.append(generations)
            $0.generations = generations
        }
    }

    func storeSourceImage(_ data: Data) async throws -> String {
        try state.withLock { state in
            if let error = state.storeError { throw error }
            state.imageCounter += 1
            let name = "image-\(state.imageCounter).jpg"
            state.images[name] = data
            return name
        }
    }

    func sourceImage(named fileName: String) async throws -> Data {
        guard let data = state.withLock({ $0.images[fileName] }) else { throw CocoaError(.fileNoSuchFile) }
        return data
    }

    func removeSourceImage(named fileName: String) async {
        state.withLock {
            $0.images[fileName] = nil
            $0.removedImages.append(fileName)
        }
    }
}
