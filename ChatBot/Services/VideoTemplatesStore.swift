import Combine
import Foundation

/// Template catalog shared by the grid and the preview pager, loaded once per app session.
@MainActor
final class VideoTemplatesStore: ObservableObject {
    static let popularCategory = "Popular"
    private static let hiddenCategories: Set<String> = ["Test"]

    @Published private(set) var state: Loadable<[VideoTemplate]> = .idle

    private let repository: VideoTemplatesRepository

    init(repository: VideoTemplatesRepository) {
        self.repository = repository
    }

    var templates: [VideoTemplate] { state.value ?? [] }

    /// "Popular" first, then catalog categories ordered by size.
    var categories: [String] {
        var counts: [String: Int] = [:]
        for template in templates where !Self.hiddenCategories.contains(template.category) {
            counts[template.category, default: 0] += 1
        }
        let sorted = counts.sorted { lhs, rhs in
            lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
        }
        return [Self.popularCategory] + sorted.map(\.key)
    }

    func templates(in category: String) -> [VideoTemplate] {
        let visible = templates.filter { !Self.hiddenCategories.contains($0.category) }
        guard category != Self.popularCategory else { return visible }
        return visible.filter { $0.category == category }
    }

    func template(id: VideoTemplate.ID) -> VideoTemplate? {
        templates.first { $0.id == id }
    }

    func loadIfNeeded() async {
        if state.value != nil || state.isLoading { return }
        await reload()
    }

    func reload() async {
        state = .loading
        do {
            state = .loaded(try await repository.fetchTemplates())
        } catch is CancellationError {
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
