import Foundation
import Testing
@testable import ChatBot

@Suite("VideoGenerationPersistenceMapper")
struct VideoGenerationPersistenceMapperTests {
    @Test("Round trip preserves every status", arguments: [
        VideoGeneration.Status.inProgress,
        .succeeded(videoURL: Fixtures.remoteVideoURL),
        .failed(message: "Boom")
    ])
    func roundTrip(status: VideoGeneration.Status) {
        let generation = Fixtures.generation(
            remoteId: "job-1",
            templateId: 12,
            templateName: "Dance",
            sourceImageFileName: "a.jpg",
            format: .square,
            quality: .p1080,
            status: status,
            isNew: false
        )

        let restored = VideoGenerationPersistenceMapper.toDomain(VideoGenerationPersistenceMapper.toStored(generation))

        #expect(restored == generation)
    }

    @Test("Stored status keys and payloads")
    func storedKeys() {
        let progress = VideoGenerationPersistenceMapper.toStored(Fixtures.generation(status: .inProgress))
        let success = VideoGenerationPersistenceMapper.toStored(Fixtures.generation(status: .succeeded(videoURL: Fixtures.remoteVideoURL)))
        let failure = VideoGenerationPersistenceMapper.toStored(Fixtures.generation(status: .failed(message: "Oops")))

        #expect(progress.status == "inProgress")
        #expect(progress.videoURL == nil && progress.errorMessage == nil)
        #expect(success.status == "succeeded")
        #expect(success.videoURL == Fixtures.remoteVideoURL)
        #expect(failure.status == "failed")
        #expect(failure.errorMessage == "Oops")
    }

    @Test("Stored format and quality use raw values")
    func storedRawValues() {
        let stored = VideoGenerationPersistenceMapper.toStored(Fixtures.generation(format: .landscape, quality: .p360))

        #expect(stored.format == "16:9")
        #expect(stored.quality == "360p")
    }

    @Test("Succeeded record without a URL degrades to failed")
    func succeededWithoutURL() {
        var stored = VideoGenerationPersistenceMapper.toStored(Fixtures.generation(status: .succeeded(videoURL: Fixtures.remoteVideoURL)))
        stored = StoredVideoGeneration(
            id: stored.id, remoteId: stored.remoteId, templateId: stored.templateId, templateName: stored.templateName,
            sourceImageFileName: stored.sourceImageFileName, format: stored.format, quality: stored.quality,
            status: "succeeded", videoURL: nil, errorMessage: nil, isNew: stored.isNew, createdAt: stored.createdAt
        )

        #expect(VideoGenerationPersistenceMapper.toDomain(stored).status == .failed(message: ""))
    }

    @Test("Unknown status, format and quality fall back to safe defaults")
    func unknownValues() {
        let stored = StoredVideoGeneration(
            id: UUID(), remoteId: nil, templateId: 1, templateName: "T", sourceImageFileName: "a.jpg",
            format: "21:9", quality: "8k", status: "weird", videoURL: nil, errorMessage: nil,
            isNew: true, createdAt: Fixtures.referenceDate
        )

        let generation = VideoGenerationPersistenceMapper.toDomain(stored)

        #expect(generation.status == .inProgress)
        #expect(generation.format == .portrait)
        #expect(generation.quality == .p720)
    }

    @Test("Failed record without a message gets an empty message")
    func failedWithoutMessage() {
        let stored = StoredVideoGeneration(
            id: UUID(), remoteId: nil, templateId: 1, templateName: "T", sourceImageFileName: "a.jpg",
            format: "9:16", quality: "720p", status: "failed", videoURL: nil, errorMessage: nil,
            isNew: false, createdAt: Fixtures.referenceDate
        )

        #expect(VideoGenerationPersistenceMapper.toDomain(stored).status == .failed(message: ""))
    }
}
