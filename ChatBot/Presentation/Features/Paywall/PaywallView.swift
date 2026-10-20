import SwiftUI

/// Route entry: builds the view model from the container and hands it to the screen.
struct PaywallView: View {
    let onClose: () -> Void

    @Environment(\.container) private var container

    var body: some View {
        if let container {
            PaywallScreen(
                viewModel: PaywallViewModel(subscriptionManager: container.subscriptionManager),
                onClose: onClose
            )
        }
    }
}
