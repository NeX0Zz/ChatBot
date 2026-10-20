import SwiftUI

struct TemplatePreviewView: View {
    let templateId: VideoTemplate.ID
    let category: String?

    @Environment(\.container) private var container

    var body: some View {
        if let container {
            TemplatePreviewScreen(
                viewModel: TemplatePreviewViewModel(
                    templateId: templateId,
                    category: category,
                    store: container.templatesStore,
                    coordinator: container.videoCoordinator,
                    photoLibrary: container.photoLibrary,
                    toastCenter: container.toastCenter,
                    premiumGate: container.premiumGate
                )
            )
        }
    }
}

private struct TemplatePreviewScreen: View {
    private enum Menu {
        case format
        case quality
    }

    private enum Layout {
        static let pagerHeight: CGFloat = 311
        static let buttonHeight = AppSpacing.buttonHeight
        static let bottomInset: CGFloat = 16
        static let buttonGap: CGFloat = 35
        static let rowHeight: CGFloat = 60
        static let rowGap: CGFloat = 8
        static let qualityMenuBottom = bottomInset + buttonHeight + buttonGap
        static let formatMenuBottom = qualityMenuBottom + rowHeight + rowGap - 4
    }

    @StateObject private var viewModel: TemplatePreviewViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var openMenu: Menu?
    @State private var isPickerPresented = false
    @State private var isAccessAlertPresented = false
    @State private var isOnScreen = false

    init(viewModel: @autoclosure @escaping () -> TemplatePreviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                NavigationHeader(title: viewModel.template?.name ?? "", onBack: router.pop)
                content
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isPickerPresented) {
            PhotoPicker(isPresented: $isPickerPresented, onPick: viewModel.photoPicked)
                .ignoresSafeArea()
        }
        .alertCard(isPresented: $isAccessAlertPresented) {
            AlertCard(
                title: "Photo access is off",
                message: "Allow access to your photos in Settings to choose an image.",
                confirmTitle: "Settings",
                onCancel: { isAccessAlertPresented = false },
                onConfirm: openSettings
            )
        }
        .onAppear { isOnScreen = true }
        .onDisappear {
            isOnScreen = false
            openMenu = nil
        }
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .ready:
            controls
        case .loading:
            Spacer()
            GenerationLoaderView(size: 56)
            Spacer()
        case let .failed(message):
            TemplatesMessageView(
                title: "Couldn’t load templates",
                message: message,
                retryTitle: "Retry",
                onRetry: { Task { await viewModel.reload() } }
            )
        case .unavailable:
            TemplatesMessageView(title: "This template is no longer available")
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            TemplatePagerView(
                templates: viewModel.templates,
                selection: viewModel.currentIndex,
                isPlaybackEnabled: isOnScreen,
                onSelect: viewModel.selectTemplate(at:)
            )
            .frame(maxHeight: Layout.pagerHeight)
            .padding(.top, 12)

            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 24) {
                PhotoSlotView(state: viewModel.photo, onAdd: addPhoto, onRemove: viewModel.removePhoto)
                VStack(spacing: Layout.rowGap) {
                    PreviewParameterRow(title: "Format", value: viewModel.format.title) { toggle(.format) }
                    PreviewParameterRow(title: "Quality", value: viewModel.quality.title) { toggle(.quality) }
                }
            }
            .padding(.horizontal, AppSpacing.sideInset)

            Spacer().frame(height: Layout.buttonGap)

            PrimaryGradientButton("Create", isLoading: viewModel.isStarting, action: create)
                .disabled(!viewModel.isPhotoReady)
                .padding(.horizontal, AppSpacing.sideInset)
        }
        .padding(.bottom, Layout.bottomInset)
        .optionListPopover(
            isPresented: menuBinding(.format),
            options: VideoFormat.popoverOptions,
            selection: viewModel.format,
            insets: EdgeInsets(top: 0, leading: 0, bottom: Layout.formatMenuBottom, trailing: AppSpacing.sideInset),
            onSelect: viewModel.selectFormat
        )
        .optionListPopover(
            isPresented: menuBinding(.quality),
            options: VideoQuality.popoverOptions(for: viewModel.availableQualities),
            selection: viewModel.quality,
            insets: EdgeInsets(top: 0, leading: 0, bottom: Layout.qualityMenuBottom, trailing: AppSpacing.sideInset),
            onSelect: viewModel.selectQuality
        )
    }

    private func menuBinding(_ menu: Menu) -> Binding<Bool> {
        Binding(
            get: { openMenu == menu },
            set: { isOpen in
                if !isOpen && openMenu == menu { openMenu = nil }
            }
        )
    }

    private func toggle(_ menu: Menu) {
        openMenu = openMenu == menu ? nil : menu
    }

    private func addPhoto() {
        Task {
            if await viewModel.requestPhotoAccess() {
                isPickerPresented = true
            } else {
                isAccessAlertPresented = true
            }
        }
    }

    private func create() {
        Task {
            // The user may have swiped back while the photo was being stored.
            guard let generationId = await viewModel.startGeneration(), isOnScreen else { return }
            router.push(.videoGenerating(generationId: generationId))
        }
    }

    private func openSettings() {
        isAccessAlertPresented = false
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
