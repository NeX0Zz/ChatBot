import SwiftUI

struct VideoGeneratingView: View {
    let generationId: VideoGeneration.ID

    @Environment(\.container) private var container

    var body: some View {
        if let container {
            VideoGeneratingScreen(
                viewModel: VideoGeneratingViewModel(
                    generationId: generationId,
                    coordinator: container.videoCoordinator,
                    premiumGate: container.premiumGate
                ),
                generationId: generationId
            )
        }
    }
}

private struct VideoGeneratingScreen: View {
    @StateObject private var viewModel: VideoGeneratingViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var isOnScreen = false

    private let generationId: VideoGeneration.ID

    init(viewModel: @autoclosure @escaping () -> VideoGeneratingViewModel, generationId: VideoGeneration.ID) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.generationId = generationId
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                NavigationHeader(title: "", onBack: router.pop)
                Group {
                    switch viewModel.phase {
                    case .inProgress, .succeeded:
                        progress
                    case let .failed(message):
                        failure(message)
                    }
                }
                .transition(.opacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.phase)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            isOnScreen = true
            showResultIfReady()
        }
        .onDisappear { isOnScreen = false }
        .onChange(of: viewModel.phase) { _ in showResultIfReady() }
    }

    private var progress: some View {
        VStack(spacing: 40) {
            GenerationLoaderView(size: 200)
            VStack(spacing: 8) {
                Text("Generating…")
                    .appFont(.title20Semibold)
                    .foregroundColor(AppColor.textPrimary)
                Text("We’re creating the best result for you")
                    .appFont(.body16)
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, AppSpacing.sideInset)
        .padding(.bottom, 40)
        .accessibilityElement(children: .combine)
    }

    private func failure(_ message: String) -> some View {
        TemplatesMessageView(
            title: "Generation failed",
            message: message,
            retryTitle: "Try again",
            onRetry: viewModel.retry
        )
    }

    private func showResultIfReady() {
        guard isOnScreen, viewModel.phase == .succeeded else { return }
        isOnScreen = false
        viewModel.markViewed()
        router.replaceTop(with: .videoResult(generationId: generationId))
    }
}
