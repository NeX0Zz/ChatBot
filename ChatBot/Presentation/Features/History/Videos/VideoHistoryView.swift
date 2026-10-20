import SwiftUI

struct VideoHistoryView: View {
    @Environment(\.container) private var container

    var body: some View {
        if let container {
            VideoHistoryScreen(viewModel: VideoHistoryViewModel(coordinator: container.videoCoordinator, premiumGate: container.premiumGate))
        }
    }
}

private struct VideoHistoryScreen: View {
    @StateObject private var viewModel: VideoHistoryViewModel
    @EnvironmentObject private var router: AppRouter

    init(viewModel: @autoclosure @escaping () -> VideoHistoryViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        Group {
            if viewModel.isEmpty {
                EmptyStateView(
                    icon: "iconEmptyVideo",
                    title: "No videos yet",
                    subtitle: "Create your first video to see it here"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 44)
                .transition(.opacity)
            } else {
                grid.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isEmpty)
    }

    private var grid: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 8) {
                column(viewModel.leadingColumn)
                column(viewModel.trailingColumn)
            }
            .padding(.horizontal, AppSpacing.sideInset)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    private func column(_ generations: [VideoGeneration]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(generations) { generation in
                VideoHistoryCardView(
                    generation: generation,
                    onOpen: { open(generation) },
                    onRetry: { viewModel.retry(generation) }
                )
            }
        }
    }

    private func open(_ generation: VideoGeneration) {
        switch generation.status {
        case .inProgress:
            router.push(.videoGenerating(generationId: generation.id))
        case .succeeded:
            router.push(.videoResult(generationId: generation.id))
        case .failed:
            break
        }
    }
}
