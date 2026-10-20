import SwiftUI

struct VideoResultView: View {
    let generationId: VideoGeneration.ID

    @Environment(\.container) private var container

    var body: some View {
        if let container {
            VideoResultScreen(
                viewModel: VideoResultViewModel(
                    generationId: generationId,
                    coordinator: container.videoCoordinator,
                    fileCache: container.videoFileCache,
                    photoLibrary: container.photoLibrary,
                    templatesStore: container.templatesStore,
                    toastCenter: container.toastCenter
                )
            )
        }
    }
}

private struct VideoResultScreen: View {
    @StateObject private var viewModel: VideoResultViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var isOnScreen = false
    @State private var isShareSheetPresented = false

    init(viewModel: @autoclosure @escaping () -> VideoResultViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                NavigationHeader(title: "Result", onBack: router.pop)
                VStack(spacing: 16) {
                    video
                    actions
                }
                .padding(.horizontal, AppSpacing.sideInset)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShareSheetPresented) {
            if let file = viewModel.localFile {
                ShareSheet(items: [file]).ignoresSafeArea()
            }
        }
        .onAppear {
            isOnScreen = true
            viewModel.markViewed()
        }
        .onDisappear {
            isOnScreen = false
            viewModel.pause()
        }
        .task { await viewModel.loadVideo() }
    }

    private var video: some View {
        GeometryReader { proxy in
            ResultPlayerView(
                phase: viewModel.phase,
                isPlaying: viewModel.isPlaying,
                isActive: isOnScreen,
                onToggle: viewModel.togglePlayback,
                onReplace: replace,
                onRetry: { Task { await viewModel.loadVideo() } }
            )
            .frame(width: containerSize(in: proxy.size).width, height: containerSize(in: proxy.size).height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var actions: some View {
        HStack(spacing: 16) {
            SecondaryActionButton("Share") { isShareSheetPresented = true }
                .disabled(viewModel.localFile == nil)
            PrimaryGradientButton("Download", isLoading: viewModel.isSaving) {
                Task { await viewModel.save() }
            }
            .disabled(viewModel.localFile == nil)
        }
    }

    /// Full width, height follows the generation's format and never exceeds the free area.
    private func containerSize(in available: CGSize) -> CGSize {
        let height = min(available.width / viewModel.format.aspectRatio, available.height)
        return CGSize(width: available.width, height: height)
    }

    private func replace() {
        Task {
            guard let templateId = await viewModel.templateIdForReplace() else { return }
            router.replaceTop(with: .templatePreview(templateId: templateId))
        }
    }
}
