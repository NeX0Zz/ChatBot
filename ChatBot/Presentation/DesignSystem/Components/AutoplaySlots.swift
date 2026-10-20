import Combine
import Foundation

/// Hands out a fixed number of autoplay slots to grid cells, so a scrolling grid keeps at most
/// `limit` video decoders alive; cells without a slot show their still frame.
@MainActor
final class AutoplaySlots: ObservableObject {
    @Published private(set) var owners: [UUID] = []

    private let limit: Int

    init(limit: Int = 4) {
        self.limit = limit
    }

    func request(_ owner: UUID) {
        guard !owners.contains(owner), owners.count < limit else { return }
        owners.append(owner)
    }

    func release(_ owner: UUID) {
        owners.removeAll { $0 == owner }
    }

    func holds(_ owner: UUID) -> Bool {
        owners.contains(owner)
    }
}
