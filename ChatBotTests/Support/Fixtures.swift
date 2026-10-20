import Foundation
@testable import ChatBot

/// Whole-second dates: the file store uses ISO 8601 without fractions.
enum Fixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    static func message(
        id: UUID = UUID(),
        role: ChatMessage.Role = .user,
        text: String = "Hello",
        createdAt: Date = referenceDate
    ) -> ChatMessage {
        ChatMessage(id: id, role: role, text: text, createdAt: createdAt)
    }

    static func chat(
        id: UUID = UUID(),
        title: String = "Chat",
        isPinned: Bool = false,
        messages: [ChatMessage]? = nil,
        updatedAt: Date = referenceDate
    ) -> Chat {
        Chat(
            id: id,
            title: title,
            isPinned: isPinned,
            createdAt: referenceDate,
            updatedAt: updatedAt,
            messages: messages ?? [message()]
        )
    }

    static func template(
        id: Int = 1,
        templateId: Int? = nil,
        name: String = "Template",
        category: String = "Other",
        qualities: [VideoQuality] = [.p720]
    ) -> VideoTemplate {
        VideoTemplate(
            id: id,
            templateId: templateId ?? id + 100,
            name: name,
            category: category,
            prompt: "prompt",
            previewURL: nil,
            duration: 5,
            qualities: qualities
        )
    }

    static func generation(
        id: UUID = UUID(),
        remoteId: String? = nil,
        templateId: Int = 101,
        templateName: String = "Template",
        sourceImageFileName: String = "source.jpg",
        format: VideoFormat = .portrait,
        quality: VideoQuality = .p720,
        status: VideoGeneration.Status = .inProgress,
        isNew: Bool = true,
        createdAt: Date = referenceDate
    ) -> VideoGeneration {
        VideoGeneration(
            id: id,
            remoteId: remoteId,
            templateId: templateId,
            templateName: templateName,
            sourceImageFileName: sourceImageFileName,
            format: format,
            quality: quality,
            status: status,
            isNew: isNew,
            createdAt: createdAt
        )
    }

    static let videoURL = URL(fileURLWithPath: "/tmp/result.mp4")
    static let remoteVideoURL = URL(string: "https://cdn.example.com/video.mp4")!
}

extension Loadable {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
}

extension VideoGeneration.Status {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }

    var failureMessage: String? {
        if case let .failed(message) = self { return message }
        return nil
    }
}
