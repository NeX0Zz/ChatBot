import Combine
import Foundation

@MainActor
final class VideoResultViewModel: ObservableObject {
    enum Phase {
        case unavailable
        case downloading
        case failed(String)
        case ready(URL)
    }

    @Published private(set) var phase: Phase
    @Published private(set) var isSaving = false
    @Published private(set) var isPlaying = false

    let format: VideoFormat

    private let generation: VideoGeneration?
    private let coordinator: VideoGenerationCoordinator
    private let fileCache: VideoFileCache
    private let photoLibrary: PhotoLibraryService
    private let templatesStore: VideoTemplatesStore
    private let toastCenter: ToastCenter

    init(
        generationId: VideoGeneration.ID,
        coordinator: VideoGenerationCoordinator,
        fileCache: VideoFileCache,
        photoLibrary: PhotoLibraryService,
        templatesStore: VideoTemplatesStore,
        toastCenter: ToastCenter
    ) {
        let generation = coordinator.generation(id: generationId)
        self.generation = generation
        self.coordinator = coordinator
        self.fileCache = fileCache
        self.photoLibrary = photoLibrary
        self.templatesStore = templatesStore
        self.toastCenter = toastCenter
        format = generation?.format ?? .portrait
        phase = generation?.videoURL == nil ? .unavailable : .downloading
    }

    var localFile: URL? {
        if case let .ready(url) = phase { return url }
        return nil
    }

    func markViewed() {
        if let generation {
            coordinator.markViewed(generation.id)
        }
    }

    /// Downloads the result once; safe to call again after a failure.
    func loadVideo() async {
        guard let remoteURL = generation?.videoURL else { return }
        if case .ready = phase { return }
        phase = .downloading
        do {
            phase = .ready(try await fileCache.localFile(for: remoteURL))
        } catch is CancellationError {
            return
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func togglePlayback() {
        guard localFile != nil else { return }
        isPlaying.toggle()
    }

    func pause() {
        isPlaying = false
    }

    func save() async {
        guard let file = localFile, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await photoLibrary.saveVideo(at: file)
            toastCenter.show(.videoSaved)
        } catch {
            toastCenter.show(.saveFailed)
        }
    }

    /// Looks the generation's template up in the catalog, loading the catalog first if needed.
    func templateIdForReplace() async -> VideoTemplate.ID? {
        guard let generation else { return nil }
        await templatesStore.loadIfNeeded()
        let template = templatesStore.templates.first { $0.templateId == generation.templateId }
        if template == nil {
            toastCenter.show(Toast(style: .failure, title: String(localized: "Template is unavailable")))
        }
        return template?.id
    }
}
