import SwiftUI

struct VideoTemplatesView: View {
    @Environment(\.container) private var container

    var body: some View {
        if let container {
            VideoTemplatesScreen(viewModel: VideoTemplatesViewModel(store: container.templatesStore))
        }
    }
}

private struct VideoTemplatesScreen: View {
    @StateObject private var viewModel: VideoTemplatesViewModel
    @EnvironmentObject private var router: AppRouter

    init(viewModel: @autoclosure @escaping () -> VideoTemplatesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                NavigationHeader(title: "AI Video", icon: "iconImageToImage", onBack: router.pop)
                categoryChips
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    CategoryChip(title: category, isSelected: category == viewModel.selectedCategory) {
                        withAnimation(.easeInOut(duration: 0.25)) { viewModel.select(category) }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.sideInset)
        }
        .padding(.top, 40)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            TemplateGridSkeleton().transition(.opacity)
        case let .failed(message):
            TemplatesMessageView(
                title: "Couldn’t load templates",
                message: message,
                retryTitle: "Retry",
                onRetry: { Task { await viewModel.reload() } }
            )
        case .loaded:
            if viewModel.visibleTemplates.isEmpty {
                TemplatesMessageView(title: "No templates in this category")
            } else {
                TemplateGridView(templates: viewModel.visibleTemplates) { template in
                    router.push(.templatePreview(templateId: template.id, category: viewModel.selectedCategory))
                }
                .id(viewModel.selectedCategory)
                .transition(.opacity)
            }
        }
    }
}
