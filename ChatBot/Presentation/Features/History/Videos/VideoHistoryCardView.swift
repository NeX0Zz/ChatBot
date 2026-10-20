import SwiftUI

struct VideoHistoryCardView: View {
    let generation: VideoGeneration
    let onOpen: () -> Void
    let onRetry: () -> Void

    private let shape = RoundedRectangle(cornerRadius: AppRadius.tile, style: .continuous)

    var body: some View {
        card
            .animation(.easeInOut(duration: 0.3), value: generation.status)
            .animation(.easeInOut(duration: 0.3), value: generation.isNew)
    }

    @ViewBuilder
    private var card: some View {
        if case .failed = generation.status {
            media
        } else {
            Button(action: onOpen) { media }
                .buttonStyle(PressScaleButtonStyle())
                .accessibilityLabel(accessibilityTitle)
        }
    }

    private var media: some View {
        Color.clear
            .aspectRatio(generation.format.aspectRatio, contentMode: .fit)
            .overlay { content }
            .overlay(alignment: .topLeading) { badge.padding(8) }
            .clipShape(shape)
            .contentShape(shape)
    }

    @ViewBuilder
    private var content: some View {
        switch generation.status {
        case let .succeeded(url):
            AutoplayVideoPreview(url: url, targetSize: thumbnailSize)
                .transition(.opacity)
        case .inProgress:
            placeholder {
                VStack(spacing: 8) {
                    GenerationLoaderView(size: 32)
                    Text("Generating…")
                        .appFont(.caption13Medium)
                        .foregroundColor(AppColor.textPrimary.opacity(0.85))
                }
            }
        case let .failed(message):
            placeholder {
                VStack(spacing: 8) {
                    Text(message)
                        .appFont(.caption13Medium)
                        .foregroundColor(AppColor.textPrimary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Button(action: onRetry) {
                        Text("Try again")
                            .appFont(.caption13Semibold)
                            .foregroundColor(AppColor.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(AppColor.textPrimary.opacity(0.14), in: Capsule())
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var badge: some View {
        switch generation.status {
        case .inProgress:
            VideoHistoryBadge(kind: .inProgress)
        case .failed:
            VideoHistoryBadge(kind: .error)
        case .succeeded:
            if generation.isNew {
                VideoHistoryBadge(kind: .new)
            }
        }
    }

    private func placeholder<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack {
            AppColor.surface
            content().padding(.horizontal, 16)
        }
    }

    private var thumbnailSize: CGSize {
        CGSize(width: 175, height: 175 / generation.format.aspectRatio)
    }

    private var accessibilityTitle: String {
        generation.templateName
    }
}
