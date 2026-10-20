import Combine
import Foundation
import OSLog

/// Owns video generation jobs for the whole app lifetime: starts them, polls their status,
/// resumes unfinished ones after relaunch and keeps the History list up to date.
/// Leaving the generating screen never cancels a job.
@MainActor
final class VideoGenerationCoordinator: ObservableObject {
    @Published private(set) var generations: [VideoGeneration] = []

    private let generationRepository: VideoGenerationRepository
    private let historyRepository: VideoHistoryRepository
    private let pollingInterval: UInt64
    private let maxPollingDuration: TimeInterval
    private let maxConsecutivePollingErrors = 5
    private var pollingTasks: [VideoGeneration.ID: Task<Void, Never>] = [:]
    private var isLoaded = false
    private var saveChain: Task<Void, Never>?
    private let logger = Logger(subsystem: "com.labs.fviu", category: "video-generation")

    init(
        generationRepository: VideoGenerationRepository,
        historyRepository: VideoHistoryRepository,
        pollingInterval: TimeInterval = 30,
        maxPollingDuration: TimeInterval = 30 * 60
    ) {
        self.generationRepository = generationRepository
        self.historyRepository = historyRepository
        self.pollingInterval = UInt64(pollingInterval * 1_000_000_000)
        self.maxPollingDuration = maxPollingDuration
    }

    deinit {
        pollingTasks.values.forEach { $0.cancel() }
    }

    /// Loads History and resumes polling for jobs that were still running when the app was closed.
    func load() async {
        guard !isLoaded else { return }
        isLoaded = true
        do {
            generations = try await historyRepository.loadGenerations()
        } catch {
            logger.error("Loading generations failed: \(error.localizedDescription)")
        }
        for generation in generations where generation.isInProgress {
            if generation.remoteId != nil {
                startPolling(generation.id)
            } else {
                // The app was killed before the job was created on the backend: submit it again.
                submit(generation.id)
            }
        }
    }

    func generation(id: VideoGeneration.ID) -> VideoGeneration? {
        generations.first { $0.id == id }
    }

    /// Creates a local record immediately (so History shows "In progress") and submits the job.
    @discardableResult
    func startGeneration(
        template: VideoTemplate,
        imageData: Data,
        format: VideoFormat,
        quality: VideoQuality
    ) async throws -> VideoGeneration.ID {
        let fileName = try await historyRepository.storeSourceImage(imageData)
        let generation = VideoGeneration(
            id: UUID(),
            remoteId: nil,
            templateId: template.templateId,
            templateName: template.name,
            sourceImageFileName: fileName,
            format: format,
            quality: quality,
            status: .inProgress,
            isNew: true,
            createdAt: Date()
        )
        generations.insert(generation, at: 0)
        persist()
        submit(generation.id)
        return generation.id
    }

    /// "Try again" for a failed card: same source frame and parameters, back to "In progress".
    func retry(_ id: VideoGeneration.ID) {
        guard let index = generations.firstIndex(where: { $0.id == id }),
              case .failed = generations[index].status else { return }
        generations[index].status = .inProgress
        generations[index].remoteId = nil
        generations[index].isNew = true
        persist()
        submit(id)
    }

    func markViewed(_ id: VideoGeneration.ID) {
        guard let index = generations.firstIndex(where: { $0.id == id }), generations[index].isNew else { return }
        generations[index].isNew = false
        persist()
    }

    func delete(_ id: VideoGeneration.ID) {
        pollingTasks[id]?.cancel()
        pollingTasks[id] = nil
        guard let index = generations.firstIndex(where: { $0.id == id }) else { return }
        let removed = generations.remove(at: index)
        persist()
        Task { [historyRepository] in
            await historyRepository.removeSourceImage(named: removed.sourceImageFileName)
        }
    }

    // MARK: - Job lifecycle

    private func submit(_ id: VideoGeneration.ID) {
        guard pollingTasks[id] == nil, let generation = generation(id: id) else { return }
        pollingTasks[id] = Task { [weak self] in
            guard let self else { return }
            do {
                let imageData = try await historyRepository.sourceImage(named: generation.sourceImageFileName)
                let remoteId = try await generationRepository.startGeneration(
                    templateId: generation.templateId,
                    imageData: imageData,
                    quality: generation.quality
                )
                logger.info("Generation \(id.uuidString) submitted as \(remoteId)")
                update(id) { $0.remoteId = remoteId }
                await poll(id, remoteId: remoteId)
            } catch is CancellationError {
                return
            } catch {
                logger.error("Submitting generation failed: \(error.localizedDescription)")
                finish(id, status: .failed(message: error.localizedDescription))
            }
        }
    }

    private func startPolling(_ id: VideoGeneration.ID) {
        guard pollingTasks[id] == nil, let remoteId = generation(id: id)?.remoteId else { return }
        pollingTasks[id] = Task { [weak self] in
            await self?.poll(id, remoteId: remoteId)
        }
    }

    private func poll(_ id: VideoGeneration.ID, remoteId: String) async {
        let startedAt = generation(id: id)?.createdAt ?? Date()
        let deadline = startedAt.addingTimeInterval(maxPollingDuration)
        var consecutiveErrors = 0
        while !Task.isCancelled {
            do {
                try await Task.sleep(nanoseconds: pollingInterval)
                let status = try await generationRepository.status(ofJob: remoteId)
                consecutiveErrors = 0
                switch status {
                case .generating:
                    if Date() > deadline {
                        finish(id, status: .failed(message: String(localized: "Generation is taking too long. Please try again.")))
                        return
                    }
                case let .succeeded(url):
                    logger.info("Generation \(remoteId) succeeded")
                    finish(id, status: .succeeded(videoURL: url))
                    return
                case .failed:
                    logger.error("Generation \(remoteId) failed on the backend")
                    finish(id, status: .failed(message: String(localized: "Something went wrong")))
                    return
                }
            } catch is CancellationError {
                return
            } catch let error as APIError where shouldKeepPolling(after: error, consecutiveErrors: consecutiveErrors) {
                // The job may still finish on the backend; failing it now would make "Try again" pay twice.
                // Being offline says nothing about the job, so it doesn't count towards the limit.
                if error != .offline { consecutiveErrors += 1 }
                logger.info("Polling \(remoteId) postponed (\(consecutiveErrors)): \(error.localizedDescription)")
            } catch {
                logger.error("Polling \(remoteId) failed: \(error.localizedDescription)")
                finish(id, status: .failed(message: error.localizedDescription))
                return
            }
        }
    }

    private func shouldKeepPolling(after error: APIError, consecutiveErrors: Int) -> Bool {
        error == .offline || (error.isTransient && consecutiveErrors < maxConsecutivePollingErrors - 1)
    }

    private func finish(_ id: VideoGeneration.ID, status: VideoGeneration.Status) {
        pollingTasks[id] = nil
        update(id) { $0.status = status }
    }

    private func update(_ id: VideoGeneration.ID, _ change: (inout VideoGeneration) -> Void) {
        guard let index = generations.firstIndex(where: { $0.id == id }) else { return }
        change(&generations[index])
        persist()
    }

    /// Writes are chained so an older snapshot can never overwrite a newer one.
    private func persist() {
        let snapshot = generations
        let previous = saveChain
        saveChain = Task { [historyRepository, logger] in
            await previous?.value
            do {
                try await historyRepository.saveGenerations(snapshot)
            } catch {
                logger.error("Saving generations failed: \(error.localizedDescription)")
            }
        }
    }
}
