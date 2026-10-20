import Combine
import Foundation

@MainActor
final class VideoHistoryViewModel: ObservableObject {
    @Published private(set) var leadingColumn: [VideoGeneration] = []
    @Published private(set) var trailingColumn: [VideoGeneration] = []
    @Published private(set) var isEmpty = true

    private let coordinator: VideoGenerationCoordinator
    private let premiumGate: PremiumGate
    private var cancellable: AnyCancellable?

    init(coordinator: VideoGenerationCoordinator, premiumGate: PremiumGate) {
        self.coordinator = coordinator
        self.premiumGate = premiumGate
        apply(coordinator.generations)
        cancellable = coordinator.$generations
            .removeDuplicates()
            .sink { [weak self] generations in self?.apply(generations) }
    }

    func retry(_ generation: VideoGeneration) {
        guard premiumGate.allowsPaidAction() else { return }
        coordinator.retry(generation.id)
    }

    private func apply(_ generations: [VideoGeneration]) {
        isEmpty = generations.isEmpty
        let columns = VideoMasonry.columns(of: generations) { $0.format.aspectRatio }
        leadingColumn = columns.leading
        trailingColumn = columns.trailing
    }
}
