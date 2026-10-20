import SwiftUI

/// Route entry: builds the view model from the container and hands it to the screen.
struct SettingsView: View {
    @Environment(\.container) private var container

    var body: some View {
        if let container {
            SettingsScreen(
                viewModel: SettingsViewModel(
                    subscriptionManager: container.subscriptionManager,
                    cacheCleaner: container.cacheCleaner
                )
            )
        }
    }
}
