import Combine
import Foundation

@MainActor
final class VideoGeneratingViewModel: ObservableObject {
    enum Phase: Equatable {
        case inProgress
        case succeeded
        case failed(String)
    }

    @Published private(set) var phase: Phase = .inProgress

    private let generationId: VideoGeneration.ID
    private let coordinator: VideoGenerationCoordinator
    private let premiumGate: PremiumGate
    private var cancellable: AnyCancellable?

    init(generationId: VideoGeneration.ID, coordinator: VideoGenerationCoordinator, premiumGate: PremiumGate) {
        self.generationId = generationId
        self.coordinator = coordinator
        self.premiumGate = premiumGate
        phase = Self.phase(of: coordinator.generation(id: generationId))
        cancellable = coordinator.$generations
            .map { $0.first { $0.id == generationId } }
            .removeDuplicates()
            .sink { [weak self] generation in self?.phase = Self.phase(of: generation) }
    }

    func retry() {
        guard premiumGate.allowsPaidAction() else { return }
        coordinator.retry(generationId)
    }

    func markViewed() {
        coordinator.markViewed(generationId)
    }

    private static func phase(of generation: VideoGeneration?) -> Phase {
        guard let generation else {
            return .failed(String(localized: "This video is no longer available."))
        }
        switch generation.status {
        case .inProgress: return .inProgress
        case .succeeded: return .succeeded
        case let .failed(message): return .failed(message)
        }
    }
}
