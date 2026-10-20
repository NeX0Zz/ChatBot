import Foundation

final class LocalVideoHistoryRepository: VideoHistoryRepository {
    private let store: FileStore<PersistenceEnvelope<StoredVideoGeneration>>
    private let imagesDirectory: URL

    init(
        store: FileStore<PersistenceEnvelope<StoredVideoGeneration>> = FileStore(fileName: "video-generations.json"),
        imagesDirectory: URL = StorageLocation.sourceImages
    ) {
        self.store = store
        self.imagesDirectory = imagesDirectory
    }

    func loadGenerations() async throws -> [VideoGeneration] {
        let envelope = try await store.load()
        return (envelope?.items ?? []).map(VideoGenerationPersistenceMapper.toDomain)
    }

    func saveGenerations(_ generations: [VideoGeneration]) async throws {
        try await store.save(PersistenceEnvelope(items: generations.map(VideoGenerationPersistenceMapper.toStored)))
    }

    func storeSourceImage(_ data: Data) async throws -> String {
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        let fileName = "\(UUID().uuidString).jpg"
        try data.write(to: imagesDirectory.appendingPathComponent(fileName), options: .atomic)
        return fileName
    }

    func sourceImage(named fileName: String) async throws -> Data {
        try Data(contentsOf: imagesDirectory.appendingPathComponent(fileName))
    }

    func removeSourceImage(named fileName: String) async {
        // A missing file is fine here: the record is being dropped anyway.
        try? FileManager.default.removeItem(at: imagesDirectory.appendingPathComponent(fileName))
    }
}
