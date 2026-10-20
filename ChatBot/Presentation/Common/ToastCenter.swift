import Combine
import Foundation

@MainActor
final class ToastCenter: ObservableObject {
    @Published private(set) var current: Toast?

    private var dismissTask: Task<Void, Never>?
    private let displayDuration: UInt64 = 2_000_000_000

    func show(_ toast: Toast) {
        dismissTask?.cancel()
        current = toast
        dismissTask = Task { [weak self, displayDuration] in
            try? await Task.sleep(nanoseconds: displayDuration)
            guard !Task.isCancelled else { return }
            self?.current = nil
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        current = nil
    }
}
