import Combine
import Foundation

/// Keeps the composition root alive for the whole app lifetime.
@MainActor
final class AppModel: ObservableObject {
    let container = AppContainer()
}
