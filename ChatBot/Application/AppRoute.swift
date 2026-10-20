import Foundation

/// Screens pushed onto the main navigation stack.
enum AppRoute: Hashable {
    case chat(id: Chat.ID?)
    case videoTemplates
    /// `category` is the list the user came from; the preview pages through it.
    case templatePreview(templateId: VideoTemplate.ID, category: String? = nil)
    case videoGenerating(generationId: VideoGeneration.ID)
    case videoResult(generationId: VideoGeneration.ID)
    case history(HistoryTab)
    case settings
}
