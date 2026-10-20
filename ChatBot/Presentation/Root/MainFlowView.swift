import SwiftUI

/// Main navigation stack. Every pushed screen is resolved from `AppRoute` here.
struct MainFlowView: View {
    @ObservedObject var router: AppRouter
    @EnvironmentObject private var toastCenter: ToastCenter

    var body: some View {
        NavigationStack(path: $router.path) {
            MainView()
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
        .fullScreenCover(isPresented: $router.isPaywallPresented) {
            PaywallView(onClose: { router.isPaywallPresented = false })
        }
        .overlay(alignment: .top) {
            ToastHost(center: toastCenter)
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case let .chat(id):
            ChatView(chatId: id)
        case .videoTemplates:
            VideoTemplatesView()
        case let .templatePreview(templateId, category):
            TemplatePreviewView(templateId: templateId, category: category)
        case let .videoGenerating(generationId):
            VideoGeneratingView(generationId: generationId)
        case let .videoResult(generationId):
            VideoResultView(generationId: generationId)
        case let .history(tab):
            HistoryView(initialTab: tab)
        case .settings:
            SettingsView()
        }
    }
}
