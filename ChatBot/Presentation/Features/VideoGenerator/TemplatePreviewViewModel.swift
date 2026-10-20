import Combine
import UIKit

@MainActor
final class TemplatePreviewViewModel: ObservableObject {
    enum Phase {
        case loading
        case failed(String)
        case unavailable
        case ready
    }

    @Published private(set) var templates: [VideoTemplate] = []
    @Published private(set) var currentTemplateId: VideoTemplate.ID
    @Published private(set) var format: VideoFormat = .landscape
    @Published private(set) var quality: VideoQuality = .p720
    @Published private(set) var photo: PhotoSlotState = .empty
    @Published private(set) var phase: Phase = .loading
    @Published private(set) var isStarting = false

    private let store: VideoTemplatesStore
    private let coordinator: VideoGenerationCoordinator
    private let photoLibrary: PhotoLibraryService
    private let toastCenter: ToastCenter
    private var originalData: Data?
    private var preparedData: Data?
    private var prepareTask: Task<Void, Never>?
    private var cancellable: AnyCancellable?
    private let category: String?
    private let premiumGate: PremiumGate

    init(
        templateId: VideoTemplate.ID,
        category: String?,
        store: VideoTemplatesStore,
        coordinator: VideoGenerationCoordinator,
        photoLibrary: PhotoLibraryService,
        toastCenter: ToastCenter,
        premiumGate: PremiumGate
    ) {
        currentTemplateId = templateId
        self.category = category
        self.store = store
        self.coordinator = coordinator
        self.photoLibrary = photoLibrary
        self.toastCenter = toastCenter
        self.premiumGate = premiumGate
        cancellable = store.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshTemplates() }
        refreshTemplates()
    }

    deinit {
        prepareTask?.cancel()
    }

    var template: VideoTemplate? {
        templates.first { $0.id == currentTemplateId }
    }

    var currentIndex: Int {
        templates.firstIndex { $0.id == currentTemplateId } ?? 0
    }

    var availableQualities: [VideoQuality] {
        template?.qualities ?? []
    }

    var isPhotoReady: Bool { photo.isReady }

    func load() async {
        await store.loadIfNeeded()
    }

    func reload() async {
        await store.reload()
    }

    func selectTemplate(at index: Int) {
        guard templates.indices.contains(index), templates[index].id != currentTemplateId else { return }
        currentTemplateId = templates[index].id
        normalizeQuality()
    }

    func selectFormat(_ newFormat: VideoFormat) {
        guard newFormat != format else { return }
        format = newFormat
        if originalData != nil {
            startPreparing()
        }
    }

    func selectQuality(_ newQuality: VideoQuality) {
        quality = newQuality
    }

    func requestPhotoAccess() async -> Bool {
        await photoLibrary.requestReadAccess() == .granted
    }

    func photoPicked(_ result: Result<Data, Error>) {
        switch result {
        case let .success(data):
            originalData = data
            startPreparing()
        case .failure:
            toastCenter.show(.uploadFailed)
        }
    }

    func removePhoto() {
        prepareTask?.cancel()
        originalData = nil
        preparedData = nil
        photo = .empty
    }

    /// Stores the prepared photo and submits the job. Returns nil when it cannot start; ignores repeated calls.
    func startGeneration() async -> VideoGeneration.ID? {
        guard !isStarting, let template, let imageData = preparedData, photo.isReady,
              premiumGate.allowsPaidAction() else { return nil }
        isStarting = true
        defer { isStarting = false }
        do {
            return try await coordinator.startGeneration(
                template: template,
                imageData: imageData,
                format: format,
                quality: quality
            )
        } catch {
            toastCenter.show(.uploadFailed)
            return nil
        }
    }

    // MARK: - Private

    private func refreshTemplates() {
        if let current = store.template(id: currentTemplateId) {
            templates = store.templates(in: category ?? current.category)
            if !templates.contains(where: { $0.id == current.id }) {
                templates = [current]
            }
            normalizeQuality()
            phase = .ready
            return
        }
        guard templates.isEmpty else { return }
        switch store.state {
        case .idle, .loading: phase = .loading
        case let .failed(message): phase = .failed(message)
        case .loaded: phase = .unavailable
        }
    }

    private func normalizeQuality() {
        guard let template, !template.qualities.contains(quality) else { return }
        quality = template.qualities.contains(.p720) ? .p720 : (template.qualities.first ?? .p720)
    }

    private func startPreparing() {
        prepareTask?.cancel()
        guard let data = originalData else { return }
        preparedData = nil
        photo = .preparing
        let format = format
        prepareTask = Task { [weak self] in
            do {
                let prepared = try await SourceImageProcessor.prepare(data, format: format)
                let thumbnail = await UIImage(data: prepared)?.byPreparingThumbnail(ofSize: CGSize(width: 300, height: 300))
                guard !Task.isCancelled else { return }
                if let thumbnail {
                    self?.finishPreparing(prepared, thumbnail: thumbnail)
                } else {
                    self?.failPreparing()
                }
            } catch {
                guard !Task.isCancelled else { return }
                self?.failPreparing()
            }
        }
    }

    private func finishPreparing(_ data: Data, thumbnail: UIImage) {
        preparedData = data
        photo = .ready(thumbnail)
    }

    private func failPreparing() {
        originalData = nil
        preparedData = nil
        photo = .empty
        toastCenter.show(.uploadFailed)
    }
}
