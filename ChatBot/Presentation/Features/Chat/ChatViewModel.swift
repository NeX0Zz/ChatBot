import Combine
import Foundation
import UIKit

@MainActor
final class ChatViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case generating
        case failed(String)
    }

    private static let maxTitleLength = 40
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    let draft = ChatDraft()
    let isNewChat: Bool

    @Published private(set) var messages: [ChatMessage]
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var isPinned: Bool
    @Published var isMenuPresented = false
    @Published var isDeleteAlertPresented = false
    @Published var isSharePresented = false

    private var chat: Chat
    private var replyTask: Task<Void, Never>?

    private let chatStore: ChatStore
    private let repository: ChatCompletionRepository
    private let premiumGate: PremiumGate
    private let router: AppRouter
    private let toastCenter: ToastCenter

    init(
        chatId: Chat.ID?,
        chatStore: ChatStore,
        repository: ChatCompletionRepository,
        premiumGate: PremiumGate,
        router: AppRouter,
        toastCenter: ToastCenter
    ) {
        self.chatStore = chatStore
        self.repository = repository
        self.premiumGate = premiumGate
        self.router = router
        self.toastCenter = toastCenter

        let stored = chatId.flatMap { chatStore.chat(id: $0) }
        let chat = stored ?? Chat(id: chatId ?? UUID(), title: "")
        self.chat = chat
        isNewChat = stored == nil
        messages = chat.messages
        isPinned = chat.isPinned
        if chat.messages.last?.role == .user {
            phase = .failed(String(localized: "The reply didn't arrive. Please try again."))
        }
    }

    convenience init(chatId: Chat.ID?, container: AppContainer) {
        self.init(
            chatId: chatId,
            chatStore: container.chatStore,
            repository: container.chatCompletionRepository,
            premiumGate: container.premiumGate,
            router: container.router,
            toastCenter: container.toastCenter
        )
    }

    var dateText: String {
        Self.dateFormatter.string(from: chat.createdAt)
    }

    var hasMessages: Bool {
        !messages.isEmpty
    }

    var isGenerating: Bool {
        phase == .generating
    }

    /// Regenerate is offered only under the final reply, and only while nothing else is running.
    var regenerableMessageId: ChatMessage.ID? {
        guard phase == .idle, let last = messages.last, last.role == .assistant else { return nil }
        return last.id
    }

    var transcript: String {
        messages
            .map { message in
                let speaker = message.role == .user ? String(localized: "You") : String(localized: "AI")
                return "\(speaker): \(message.text)"
            }
            .joined(separator: "\n\n")
    }

    // MARK: Sending

    func send() {
        guard !isGenerating, !draft.isEmpty else { return }
        guard premiumGate.allowsPaidAction() else { return }
        let prompt = draft.trimmedText
        draft.text = ""
        messages.append(ChatMessage(role: .user, text: prompt))
        if chat.title.isEmpty {
            chat.title = Self.title(from: prompt)
        }
        persist()
        requestReply(for: prompt)
    }

    func retry() {
        guard case .failed = phase, let prompt = lastUserPrompt, premiumGate.allowsPaidAction() else { return }
        requestReply(for: prompt)
    }

    func regenerate() {
        guard regenerableMessageId != nil, let prompt = lastUserPrompt, premiumGate.allowsPaidAction() else { return }
        messages.removeLast()
        requestReply(for: prompt)
    }

    /// Stops the in-flight request; messages that already arrived stay.
    func cancel() {
        replyTask?.cancel()
        replyTask = nil
        if isGenerating {
            phase = .failed(String(localized: "The reply didn't arrive. Please try again."))
        }
    }

    // MARK: Actions

    func copy(_ message: ChatMessage) {
        UIPasteboard.general.string = message.text
        let didCopy = UIPasteboard.general.string == message.text
        toastCenter.show(didCopy ? .copied : .copyFailed)
    }

    func togglePin() {
        isPinned.toggle()
        chat.isPinned = isPinned
        chatStore.setPinned(isPinned, id: chat.id)
    }

    func deleteChat() {
        cancel()
        chatStore.delete(id: chat.id)
        router.popToRoot()
    }

    // MARK: Private

    private var lastUserPrompt: String? {
        messages.last { $0.role == .user }?.text
    }

    private func requestReply(for prompt: String) {
        replyTask?.cancel()
        phase = .generating
        let repository = repository
        let remoteId = chat.remoteId
        replyTask = Task { [weak self] in
            do {
                let reply = try await repository.reply(to: prompt, chatId: remoteId)
                guard !Task.isCancelled else { return }
                self?.receive(reply)
            } catch {
                guard !Task.isCancelled else { return }
                self?.phase = .failed(error.localizedDescription)
            }
        }
    }

    private func receive(_ reply: String) {
        let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            phase = .failed(String(localized: "Something went wrong. Please try again."))
            return
        }
        messages.append(ChatMessage(role: .assistant, text: text))
        phase = .idle
        persist()
    }

    private func persist() {
        chat.messages = messages
        chat.updatedAt = Date()
        chatStore.upsert(chat)
    }

    private static func title(from prompt: String) -> String {
        let firstLine = prompt.split(whereSeparator: \.isNewline).first.map(String.init) ?? prompt
        guard firstLine.count > maxTitleLength else { return firstLine }
        return firstLine.prefix(maxTitleLength).trimmingCharacters(in: .whitespaces) + "…"
    }
}
