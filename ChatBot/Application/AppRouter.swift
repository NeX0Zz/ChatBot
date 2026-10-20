import Combine
import OSLog

/// Navigation state of the main flow plus the app-wide paywall presentation.
@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var isPaywallPresented = false

    private let logger = Logger(subsystem: "com.labs.fviu", category: "navigation")

    func push(_ route: AppRoute) {
        logger.debug("Push \(String(describing: route))")
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        logger.debug("Pop \(String(describing: self.path.last))")
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    /// Replaces the top screen, e.g. Generating → Result, so Back does not return to a finished state.
    func replaceTop(with route: AppRoute) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    func presentPaywall() {
        isPaywallPresented = true
    }
}
