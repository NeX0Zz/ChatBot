import SwiftUI

struct PhotoSlotView: View {
    let state: PhotoSlotState
    let onAdd: () -> Void
    let onRemove: () -> Void

    private let side: CGFloat = 100
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: AppRadius.tile, style: .continuous)
    }

    var body: some View {
        ZStack {
            switch state {
            case .empty:
                addButton.transition(.opacity)
            case .preparing:
                preparing.transition(.opacity)
            case let .ready(image):
                photo(image).transition(.opacity)
            }
        }
        .frame(width: side, height: side)
        .animation(.easeInOut(duration: 0.25), value: stateKey)
    }

    private var stateKey: Int {
        switch state {
        case .empty: 0
        case .preparing: 1
        case .ready: 2
        }
    }

    private var addButton: some View {
        Button(action: onAdd) {
            Image("iconPlus")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(AppColor.textPrimary)
                .frame(width: side, height: side)
                .overlay(shape.strokeBorder(AppGradient.brand, lineWidth: 1))
                .contentShape(shape)
        }
        .buttonStyle(PressScaleButtonStyle())
        .accessibilityLabel("Add photo")
    }

    private var preparing: some View {
        shape
            .fill(AppColor.surface40)
            .overlay { GenerationLoaderView(size: 32) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Uploading photo")
    }

    private func photo(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: side, height: side)
            .clipShape(shape)
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    Image("iconRemovePhoto")
                        .resizable()
                        .scaledToFit()
                        .frame(width: AppSpacing.iconSize, height: AppSpacing.iconSize)
                        .foregroundStyle(AppGradient.brand)
                        .frame(width: 32, height: 32)
                        .background(AppColor.textPrimary, in: Circle())
                        .contentShape(Circle().inset(by: -6))
                }
                .buttonStyle(PressScaleButtonStyle())
                .offset(x: 8, y: -8)
                .accessibilityLabel("Remove photo")
            }
            .accessibilityElement(children: .contain)
    }
}
