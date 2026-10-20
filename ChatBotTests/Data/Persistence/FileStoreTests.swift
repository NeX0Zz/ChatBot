import Foundation
import Testing
@testable import ChatBot

@Suite("FileStore")
struct FileStoreTests {
    private struct Sample: Codable, Sendable, Equatable {
        var name: String
        var date: Date
        var values: [Int]
    }

    private let sample = Sample(name: "one", date: Fixtures.referenceDate, values: [1, 2, 3])

    @Test("Load returns nil when nothing was saved")
    func loadMissing() async throws {
        try await withTemporaryDirectory { directory in
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)

            let result1 = try await store.load()
            #expect(result1 == nil)
        }
    }

    @Test("Saved value is loaded back, including ISO 8601 dates")
    func roundTrip() async throws {
        try await withTemporaryDirectory { directory in
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)

            try await store.save(sample)

            let result2 = try await store.load()
            #expect(result2 == sample)
        }
    }

    @Test("A second store on the same file sees the data")
    func persistsAcrossInstances() async throws {
        try await withTemporaryDirectory { directory in
            try await FileStore<Sample>(fileName: "sample.json", directory: directory).save(sample)

            let loaded = try await FileStore<Sample>(fileName: "sample.json", directory: directory).load()

            #expect(loaded == sample)
        }
    }

    @Test("Save overwrites the previous value")
    func overwrite() async throws {
        try await withTemporaryDirectory { directory in
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)
            try await store.save(sample)
            var updated = sample
            updated.values = [9]

            try await store.save(updated)

            let result3 = try await store.load()
            #expect(result3 == updated)
        }
    }

    @Test("Save creates missing intermediate directories")
    func createsDirectory() async throws {
        try await withTemporaryDirectory { directory in
            let nested = directory.appendingPathComponent("a/b", isDirectory: true)
            let store = FileStore<Sample>(fileName: "sample.json", directory: nested)

            try await store.save(sample)

            #expect(FileManager.default.fileExists(atPath: nested.appendingPathComponent("sample.json").path))
        }
    }

    @Test("Different file names do not interfere")
    func isolatedFiles() async throws {
        try await withTemporaryDirectory { directory in
            let first = FileStore<Sample>(fileName: "first.json", directory: directory)
            let second = FileStore<Sample>(fileName: "second.json", directory: directory)

            try await first.save(sample)

            let result4 = try await second.load()
            #expect(result4 == nil)
        }
    }

    @Test("A corrupted file is moved aside as .corrupt and load returns nil")
    func corruptedFileIsMovedAside() async throws {
        try await withTemporaryDirectory { directory in
            let file = directory.appendingPathComponent("sample.json")
            let backup = directory.appendingPathComponent("sample.json.corrupt")
            try Data("not json".utf8).write(to: file)
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)

            let loaded = try await store.load()

            #expect(loaded == nil)
            #expect(FileManager.default.fileExists(atPath: file.path) == false)
            #expect(try Data(contentsOf: backup) == Data("not json".utf8))
        }
    }

    @Test("After a corrupted load the store is usable again and keeps the backup")
    func saveAfterCorruption() async throws {
        try await withTemporaryDirectory { directory in
            try Data("broken".utf8).write(to: directory.appendingPathComponent("sample.json"))
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)
            _ = try await store.load()

            try await store.save(sample)

            let loaded = try await store.load()
            #expect(loaded == sample)
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("sample.json.corrupt").path))
        }
    }

    @Test("A newer corrupted file replaces the previous backup")
    func backupIsReplaced() async throws {
        try await withTemporaryDirectory { directory in
            let file = directory.appendingPathComponent("sample.json")
            let backup = directory.appendingPathComponent("sample.json.corrupt")
            try Data("old".utf8).write(to: backup)
            try Data("new".utf8).write(to: file)
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)

            _ = try await store.load()

            #expect(try Data(contentsOf: backup) == Data("new".utf8))
        }
    }

    @Test("A valid file of the wrong shape is treated as corrupted")
    func wrongShapeIsCorrupted() async throws {
        try await withTemporaryDirectory { directory in
            try Data(#"{"unexpected": true}"#.utf8).write(to: directory.appendingPathComponent("sample.json"))
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)

            let loaded = try await store.load()

            #expect(loaded == nil)
            #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("sample.json.corrupt").path))
        }
    }

    @Test("Concurrent saves leave a readable, complete value")
    func concurrentSaves() async throws {
        try await withTemporaryDirectory { directory in
            let store = FileStore<Sample>(fileName: "sample.json", directory: directory)
            let base = sample

            await withTaskGroup(of: Void.self) { group in
                for index in 0..<20 {
                    group.addTask {
                        var value = base
                        value.values = [index]
                        try? await store.save(value)
                    }
                }
            }

            let loaded = try #require(try await store.load())
            #expect(loaded.values.count == 1)
            #expect((0..<20).contains(loaded.values[0]))
        }
    }
}
