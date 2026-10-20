import Foundation
import Testing
@testable import ChatBot

@Suite("LocalVideoHistoryRepository")
struct LocalVideoHistoryRepositoryTests {
    private typealias Store = FileStore<PersistenceEnvelope<StoredVideoGeneration>>

    private func makeRepository(in directory: URL) -> LocalVideoHistoryRepository {
        LocalVideoHistoryRepository(
            store: Store(fileName: "videos.json", directory: directory),
            imagesDirectory: directory.appendingPathComponent("images", isDirectory: true)
        )
    }

    @Test("Loads an empty list when nothing is stored")
    func emptyByDefault() async throws {
        try await withTemporaryDirectory { directory in
            let generations = try await makeRepository(in: directory).loadGenerations()

            #expect(generations.isEmpty)
        }
    }

    @Test("Generations in every status round-trip")
    func roundTrip() async throws {
        try await withTemporaryDirectory { directory in
            let repository = makeRepository(in: directory)
            let generations = [
                Fixtures.generation(remoteId: "j1", status: .inProgress),
                Fixtures.generation(remoteId: "j2", status: .succeeded(videoURL: Fixtures.remoteVideoURL), isNew: false),
                Fixtures.generation(status: .failed(message: "No luck"))
            ]

            try await repository.saveGenerations(generations)

            let result1 = try await repository.loadGenerations()
            #expect(result1 == generations)
        }
    }

    @Test("Stored source image can be read back")
    func storeAndReadImage() async throws {
        try await withTemporaryDirectory { directory in
            let repository = makeRepository(in: directory)
            let data = Data([1, 2, 3, 4])

            let name = try await repository.storeSourceImage(data)

            #expect(name.hasSuffix(".jpg"))
            let result2 = try await repository.sourceImage(named: name)
            #expect(result2 == data)
        }
    }

    @Test("Each stored image gets a unique file name")
    func uniqueNames() async throws {
        try await withTemporaryDirectory { directory in
            let repository = makeRepository(in: directory)

            let first = try await repository.storeSourceImage(Data([1]))
            let second = try await repository.storeSourceImage(Data([2]))

            #expect(first != second)
            let result3 = try await repository.sourceImage(named: first)
            #expect(result3 == Data([1]))
            let result4 = try await repository.sourceImage(named: second)
            #expect(result4 == Data([2]))
        }
    }

    @Test("Reading a missing image throws")
    func missingImage() async throws {
        try await withTemporaryDirectory { directory in
            let repository = makeRepository(in: directory)

            await #expect(throws: (any Error).self) {
                _ = try await repository.sourceImage(named: "nope.jpg")
            }
        }
    }

    @Test("Removing an image deletes only that file")
    func removeImage() async throws {
        try await withTemporaryDirectory { directory in
            let repository = makeRepository(in: directory)
            let removed = try await repository.storeSourceImage(Data([1]))
            let kept = try await repository.storeSourceImage(Data([2]))

            await repository.removeSourceImage(named: removed)

            await #expect(throws: (any Error).self) {
                _ = try await repository.sourceImage(named: removed)
            }
            let result5 = try await repository.sourceImage(named: kept)
            #expect(result5 == Data([2]))
        }
    }

    @Test("Removing an unknown image is a no-op")
    func removeUnknownImage() async throws {
        try await withTemporaryDirectory { directory in
            await makeRepository(in: directory).removeSourceImage(named: "ghost.jpg")
        }
    }

    @Test("A corrupted file loads as an empty list and is kept aside")
    func corruptedFile() async throws {
        try await withTemporaryDirectory { directory in
            try Data("oops".utf8).write(to: directory.appendingPathComponent("videos.json"))

            let generations = try await makeRepository(in: directory).loadGenerations()

            #expect(generations.isEmpty)
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("videos.json.corrupt").path))
        }
    }
}
