import SwiftUI

/// Route entry: builds the view model from the composition root.
struct ChatView: View {
    let chatId: Chat.ID?
    @Environment(\.container) private var container

    var body: some View {
        if let container {
            ChatScreen(viewModel: ChatViewModel(chatId: chatId, container: container))
        }
    }
}
