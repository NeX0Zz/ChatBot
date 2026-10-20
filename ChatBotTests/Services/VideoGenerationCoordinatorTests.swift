import Foundation
import Testing
@testable import ChatBot

@MainActor
@Suite("VideoGenerationCoordinator")
struct VideoGenerationCoordinatorTests {
    private let imageData = Data([0xFF, 0xD8, 0x01])
    private let resultURL = Fixtures.remoteVideoURL

    private struct SUT {
        let coordinator: VideoGenerationCoordinator
        let backend: FakeVideoGenerationRepository
        let history: InMemoryVideoHistoryRepository
    }

    private func makeSUT(
        start: [Result<String, Error>] = [.success("job-1")],
        status: [Result<RemoteGenerationStatus, Error>] = [.success(.generating)],
        history: InMemoryVideoHistoryRepository = InMemoryVideoHistoryRepository(),
        maxPollingDuration: TimeInterval = 60
    ) -> SUT {
        let backend = FakeVideoGenerationRepository(startResults: start, statusResults: status)
        let coordinator = VideoGenerationCoordinator(
            generationRepository: backend,
            historyRepository: history,
            pollingInterval: 0.01,
            maxPollingDuration: maxPollingDuration
        )
        return SUT(coordinator: coordinator, backend: backend, history: history)
    }

    @discardableResult
    private func begin(
        _ sut: SUT,
        template: VideoTemplate = Fixtures.template(id: 1, templateId: 42, name: "Dance"),
        format: VideoFormat = .square,
        quality: VideoQuality = .p540
    ) async throws -> VideoGeneration.ID {
        try await sut.coordinator.startGeneration(template: template, imageData: imageData, format: format, quality: quality)
    }

    // MARK: - Start

    @Test("startGeneration inserts an in-progress record marked new before the backend answers")
    func startInsertsRecord() async throws {
        let sut = makeSUT()
        let gate = AsyncGate()
        sut.backend.setStartGate(gate)

        let id = try await begin(sut)

        let generation = try #require(sut.coordinator.generation(id: id))
        #expect(generation.status == .inProgress)
        #expect(generation.isNew)
        #expect(generation.remoteId == nil)
        #expect(generation.templateId == 42)
        #expect(generation.templateName == "Dance")
        #expect(generation.format == .square)
        #expect(generation.quality == .p540)
        #expect(sut.coordinator.generations.map(\.id) == [id])
        gate.open()
    }

    @Test("New generations are inserted at the top")
    func newestFirst() async throws {
        let sut = makeSUT()

        let first = try await begin(sut)
        let second = try await begin(sut)

        #expect(sut.coordinator.generations.map(\.id) == [second, first])
    }

    @Test("The source image is stored and the record references it")
    func storesSourceImage() async throws {
        let sut = makeSUT()

        let id = try await begin(sut)

        let generation = try #require(sut.coordinator.generation(id: id))
        #expect(sut.history.storedImages[generation.sourceImageFileName] == imageData)
    }

    @Test("The backend receives the template id, image bytes and quality once")
    func submitsToBackend() async throws {
        let sut = makeSUT()

        try await begin(sut)
        await waitUntil { !sut.backend.startCalls.isEmpty }

        #expect(sut.backend.startCalls == [.init(templateId: 42, imageData: imageData, quality: .p540)])
    }

    @Test("The new record is persisted")
    func persistsNewRecord() async throws {
        let sut = makeSUT()

        let id = try await begin(sut)
        await waitUntil { sut.history.lastSave?.contains { $0.id == id } == true }

        #expect(sut.history.saves.isEmpty == false)
    }

    @Test("A source-image failure throws and creates no record")
    func storeImageFailure() async {
        let sut = makeSUT(history: InMemoryVideoHistoryRepository(storeError: StubError("disk full")))

        await #expect(throws: StubError.self) {
            try await begin(sut)
        }

        #expect(sut.coordinator.generations.isEmpty)
        #expect(sut.backend.startCalls.isEmpty)
    }

    // MARK: - Polling outcomes

    @Test("Success path: remote id is saved and the result URL is set")
    func successPath() async throws {
        let sut = makeSUT(status: [.success(.generating), .success(.generating), .success(.succeeded(videoURL: resultURL))])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }

        let generation = try #require(sut.coordinator.generation(id: id))
        #expect(generation.status == .succeeded(videoURL: resultURL))
        #expect(generation.remoteId == "job-1")
        #expect(sut.backend.statusCalls == ["job-1", "job-1", "job-1"])
        await waitUntil { sut.history.lastSave?.first?.videoURL == resultURL }
    }

    @Test("Backend failure marks the generation failed")
    func backendFailure() async throws {
        let sut = makeSUT(status: [.success(.generating), .success(.failed)])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        let generation = try #require(sut.coordinator.generation(id: id))
        #expect(generation.status.failureMessage?.isEmpty == false)
        #expect(generation.remoteId == "job-1")
    }

    @Test("Submit error marks the generation failed with the error message")
    func submitError() async throws {
        let sut = makeSUT(start: [.failure(APIError.insufficientBalance)])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.coordinator.generation(id: id)?.status == .failed(message: APIError.insufficientBalance.localizedDescription))
        #expect(sut.backend.statusCalls.isEmpty)
    }

    @Test("A failed submit is persisted")
    func failureIsPersisted() async throws {
        let sut = makeSUT(start: [.failure(StubError("nope"))])

        let id = try await begin(sut)
        await waitUntil { sut.history.lastSave?.first { $0.id == id }?.status == .failed(message: "nope") }
    }

    @Test("Offline and timeout during polling keep the job alive until it succeeds")
    func transientNetworkErrors() async throws {
        let sut = makeSUT(status: [
            .success(.generating),
            .failure(APIError.offline),
            .failure(APIError.timeout),
            .failure(APIError.offline),
            .success(.succeeded(videoURL: resultURL))
        ])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }

        #expect(sut.backend.statusCalls.count == 5)
        #expect(sut.coordinator.generation(id: id)?.status == .succeeded(videoURL: resultURL))
    }

    @Test("A non-transient polling error fails the job")
    func fatalPollingError() async throws {
        let sut = makeSUT(status: [.failure(APIError.unauthorized)])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.coordinator.generation(id: id)?.status == .failed(message: APIError.unauthorized.localizedDescription))
        #expect(sut.backend.statusCalls.count == 1)
    }

    @Test("A job running longer than the allowed duration fails")
    func pollingTimeout() async throws {
        let sut = makeSUT(status: [.success(.generating)], maxPollingDuration: 0)

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.coordinator.generation(id: id)?.status.failureMessage?.isEmpty == false)
    }

    // MARK: - Idempotency

    @Test("Retrying an in-flight generation does not submit it twice")
    func retryWhileInProgress() async throws {
        let sut = makeSUT()
        let gate = AsyncGate()
        sut.backend.setStartGate(gate)

        let id = try await begin(sut)
        await waitUntil { gate.waiterCount == 1 }
        sut.coordinator.retry(id)
        sut.coordinator.retry(id)
        gate.open()
        await waitUntil { sut.coordinator.generation(id: id)?.remoteId == "job-1" }

        #expect(sut.backend.startCalls.count == 1)
    }

    @Test("Concurrent starts of different generations submit each exactly once")
    func independentJobs() async throws {
        let sut = makeSUT()

        try await begin(sut)
        try await begin(sut)
        await waitUntil { sut.backend.startCalls.count == 2 }

        #expect(sut.coordinator.generations.count == 2)
    }

    // MARK: - Retry

    @Test("Retry resets a failed generation to in-progress and resubmits it")
    func retryFailed() async throws {
        let sut = makeSUT(
            start: [.failure(StubError("first")), .success("job-2")],
            status: [.success(.succeeded(videoURL: resultURL))]
        )
        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }
        sut.coordinator.markViewed(id)
        #expect(sut.coordinator.generation(id: id)?.isNew == false)

        sut.coordinator.retry(id)

        let afterRetry = try #require(sut.coordinator.generation(id: id))
        #expect(afterRetry.status == .inProgress)
        #expect(afterRetry.remoteId == nil)
        #expect(afterRetry.isNew)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }
        #expect(sut.backend.startCalls.count == 2)
        #expect(sut.backend.startCalls.last?.imageData == imageData)
        #expect(sut.coordinator.generation(id: id)?.remoteId == "job-2")
        #expect(sut.backend.statusCalls == ["job-2"])
    }

    @Test("Retry of an unknown id does nothing")
    func retryUnknown() {
        let sut = makeSUT()

        sut.coordinator.retry(UUID())

        #expect(sut.coordinator.generations.isEmpty)
        #expect(sut.backend.startCalls.isEmpty)
    }

    // MARK: - markViewed

    @Test("markViewed clears the new flag and persists it")
    func markViewed() async throws {
        let sut = makeSUT(start: [.failure(StubError())])
        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        sut.coordinator.markViewed(id)

        #expect(sut.coordinator.generation(id: id)?.isNew == false)
        await waitUntil { sut.history.lastSave?.first?.isNew == false }
    }

    @Test("markViewed on an already viewed or unknown generation does not save again")
    func markViewedIsIdempotent() async throws {
        let sut = makeSUT(start: [.failure(StubError())])
        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }
        sut.coordinator.markViewed(id)
        await waitUntil { sut.history.lastSave?.first?.isNew == false }
        let savesBefore = sut.history.saves.count

        sut.coordinator.markViewed(id)
        sut.coordinator.markViewed(UUID())
        sut.coordinator.delete(UUID())
        // Saves are chained in order, so this marker write lands after any write the calls above might have caused.
        let gate = AsyncGate()
        sut.backend.setStartGate(gate)
        try await begin(sut)
        await waitUntil { sut.history.saves.count > savesBefore }

        #expect(sut.history.saves.count == savesBefore + 1)
        gate.open()
    }

    // MARK: - load

    @Test("load publishes persisted generations")
    func loadPublishes() async {
        let done = Fixtures.generation(status: .succeeded(videoURL: resultURL), isNew: false)
        let failed = Fixtures.generation(status: .failed(message: "x"))
        let sut = makeSUT(history: InMemoryVideoHistoryRepository(generations: [done, failed]))

        await sut.coordinator.load()

        #expect(sut.coordinator.generations == [done, failed])
        #expect(sut.backend.startCalls.isEmpty)
        #expect(sut.backend.statusCalls.isEmpty)
    }

    @Test("load resumes polling for in-progress jobs that already have a remote id")
    func loadResumesPolling() async throws {
        let pending = Fixtures.generation(remoteId: "remote-9", status: .inProgress, createdAt: Date())
        let sut = makeSUT(
            status: [.success(.generating), .success(.succeeded(videoURL: resultURL))],
            history: InMemoryVideoHistoryRepository(generations: [pending])
        )

        await sut.coordinator.load()
        await waitUntil { sut.coordinator.generation(id: pending.id)?.videoURL != nil }

        #expect(sut.backend.startCalls.isEmpty)
        #expect(Set(sut.backend.statusCalls) == ["remote-9"])
    }

    @Test("load resubmits in-progress jobs that never reached the backend")
    func loadResubmits() async throws {
        let history = InMemoryVideoHistoryRepository()
        history.seedImage(imageData, named: "saved.jpg")
        let orphan = Fixtures.generation(
            remoteId: nil, templateId: 77, sourceImageFileName: "saved.jpg", quality: .p1080, status: .inProgress
        )
        history.seed([orphan])
        let sut = makeSUT(start: [.success("job-new")], status: [.success(.succeeded(videoURL: resultURL))], history: history)

        await sut.coordinator.load()
        await waitUntil { sut.coordinator.generation(id: orphan.id)?.videoURL != nil }

        #expect(sut.backend.startCalls == [.init(templateId: 77, imageData: imageData, quality: .p1080)])
        #expect(sut.coordinator.generation(id: orphan.id)?.remoteId == "job-new")
    }

    @Test("A resubmitted job whose source image is gone fails instead of hanging")
    func loadResubmitMissingImage() async {
        let orphan = Fixtures.generation(remoteId: nil, sourceImageFileName: "missing.jpg", status: .inProgress)
        let sut = makeSUT(history: InMemoryVideoHistoryRepository(generations: [orphan]))

        await sut.coordinator.load()
        await waitUntil { sut.coordinator.generation(id: orphan.id)?.status.isFailed == true }

        #expect(sut.backend.startCalls.isEmpty)
    }

    @Test("A resumed job older than the maximum duration fails on its next unfinished poll")
    func resumedJobPastDeadline() async {
        let stale = Fixtures.generation(remoteId: "remote-old", status: .inProgress, createdAt: Date().addingTimeInterval(-3600))
        let sut = makeSUT(
            status: [.success(.generating)],
            history: InMemoryVideoHistoryRepository(generations: [stale]),
            maxPollingDuration: 60
        )

        await sut.coordinator.load()
        await waitUntil { sut.coordinator.generation(id: stale.id)?.status.isFailed == true }

        #expect(sut.backend.statusCalls == ["remote-old"])
    }

    @Test("A resumed job that finished in the meantime still succeeds even past the deadline")
    func resumedJobPastDeadlineButFinished() async {
        let stale = Fixtures.generation(remoteId: "remote-old", status: .inProgress, createdAt: Date().addingTimeInterval(-3600))
        let sut = makeSUT(
            status: [.success(.succeeded(videoURL: resultURL))],
            history: InMemoryVideoHistoryRepository(generations: [stale]),
            maxPollingDuration: 60
        )

        await sut.coordinator.load()
        await waitUntil { sut.coordinator.generation(id: stale.id)?.videoURL != nil }

        #expect(sut.coordinator.generation(id: stale.id)?.status == .succeeded(videoURL: resultURL))
    }

    // MARK: - Transient polling errors

    @Test("Transient API errors are retried and the job still succeeds", arguments: [
        APIError.server(statusCode: 503), .invalidResponse, .decoding, .timeout
    ])
    func transientErrorsAreRetried(error: APIError) async throws {
        let sut = makeSUT(status: [
            .failure(error),
            .failure(error),
            .success(.generating),
            .success(.succeeded(videoURL: resultURL))
        ])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }

        #expect(sut.backend.statusCalls.count == 4)
    }

    @Test("Four transient errors in a row are tolerated, the fifth fails the job")
    func transientLimit() async throws {
        let error = APIError.server(statusCode: 500)
        let errors: [Result<RemoteGenerationStatus, Error>] = Array(repeating: .failure(error), count: 4)
        let sut = makeSUT(status: errors + [.success(.succeeded(videoURL: resultURL))])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }
        #expect(sut.backend.statusCalls.count == 5)

        let failing = makeSUT(status: [.failure(error)])
        let failingId = try await begin(failing)
        await waitUntil { failing.coordinator.generation(id: failingId)?.status.isFailed == true }

        #expect(failing.backend.statusCalls.count == 5)
        #expect(failing.coordinator.generation(id: failingId)?.status == .failed(message: error.localizedDescription))
    }

    @Test("A successful poll resets the consecutive error counter")
    func successResetsCounter() async throws {
        let error = APIError.server(statusCode: 500)
        let sut = makeSUT(status: [
            .failure(error), .failure(error), .failure(error), .failure(error),
            .success(.generating),
            .failure(error), .failure(error), .failure(error), .failure(error),
            .success(.succeeded(videoURL: resultURL))
        ])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }

        #expect(sut.backend.statusCalls.count == 10)
    }

    @Test("Offline answers do not count towards the error limit")
    func offlineIsNotCounted() async throws {
        let offline: [Result<RemoteGenerationStatus, Error>] = Array(repeating: .failure(APIError.offline), count: 12)
        let sut = makeSUT(status: offline + [.success(.succeeded(videoURL: resultURL))])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.videoURL != nil }

        #expect(sut.backend.statusCalls.count == 13)
    }

    @Test("Offline answers in between do not reset the transient counter")
    func offlineDoesNotResetCounter() async throws {
        let error = APIError.timeout
        let sut = makeSUT(status: [
            .failure(error), .failure(APIError.offline), .failure(error), .failure(APIError.offline),
            .failure(error), .failure(error), .failure(error)
        ])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.backend.statusCalls.count == 7)
    }

    @Test("Permanent API errors fail the job immediately", arguments: [
        APIError.unauthorized, .insufficientBalance, .server(statusCode: 404)
    ])
    func permanentErrors(error: APIError) async throws {
        let sut = makeSUT(status: [.failure(error)])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.backend.statusCalls.count == 1)
    }

    @Test("Unknown (non-API) polling errors fail the job immediately")
    func unknownPollingError() async throws {
        let sut = makeSUT(status: [.failure(StubError("weird"))])

        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }

        #expect(sut.coordinator.generation(id: id)?.status == .failed(message: "weird"))
        #expect(sut.backend.statusCalls.count == 1)
    }

    @Test("Calling load twice does not duplicate work")
    func loadIsIdempotent() async {
        let pending = Fixtures.generation(remoteId: "remote-1", status: .inProgress, createdAt: Date())
        let gate = AsyncGate()
        let sut = makeSUT(history: InMemoryVideoHistoryRepository(generations: [pending]))
        sut.backend.setStatusGate(gate)

        await sut.coordinator.load()
        await sut.coordinator.load()
        await waitUntil { gate.waiterCount == 1 }

        #expect(sut.coordinator.generations.count == 1)
        #expect(sut.backend.statusCalls.count == 1)
        gate.open()
    }

    @Test("load survives a history failure")
    func loadFailure() async {
        let sut = makeSUT(history: InMemoryVideoHistoryRepository(loadError: StubError()))

        await sut.coordinator.load()

        #expect(sut.coordinator.generations.isEmpty)
    }

    // MARK: - delete

    @Test("Delete removes the record, persists it and removes the source image")
    func deleteRemoves() async throws {
        let sut = makeSUT(start: [.failure(StubError())])
        let id = try await begin(sut)
        await waitUntil { sut.coordinator.generation(id: id)?.status.isFailed == true }
        let fileName = try #require(sut.coordinator.generation(id: id)?.sourceImageFileName)

        sut.coordinator.delete(id)

        #expect(sut.coordinator.generation(id: id) == nil)
        await waitUntil { sut.history.removedImages == [fileName] }
        await waitUntil { sut.history.lastSave?.isEmpty == true }
    }

    @Test("Delete cancels polling")
    func deleteCancelsPolling() async throws {
        let sut = makeSUT()
        let gate = AsyncGate()
        sut.backend.setStatusGate(gate)
        let id = try await begin(sut)
        await waitUntil { gate.waiterCount == 1 }

        sut.coordinator.delete(id)

        await waitUntil { gate.cancelledCount == 1 }
        #expect(sut.coordinator.generations.isEmpty)
    }

    @Test("Delete during submit cancels it and never produces a failure")
    func deleteCancelsSubmit() async throws {
        let sut = makeSUT()
        let gate = AsyncGate()
        sut.backend.setStartGate(gate)
        let id = try await begin(sut)
        await waitUntil { gate.waiterCount == 1 }

        sut.coordinator.delete(id)

        await waitUntil { gate.cancelledCount == 1 }
        #expect(sut.coordinator.generations.isEmpty)
        #expect(sut.backend.statusCalls.isEmpty)
    }

    @Test("Deleting one generation leaves the others polling")
    func deleteKeepsOthers() async throws {
        let sut = makeSUT(start: [.success("job-a"), .success("job-b")])
        let first = try await begin(sut)
        let second = try await begin(sut)
        await waitUntil { Set(sut.backend.statusCalls) == ["job-a", "job-b"] }

        sut.coordinator.delete(first)

        #expect(sut.coordinator.generations.map(\.id) == [second])
    }
}
