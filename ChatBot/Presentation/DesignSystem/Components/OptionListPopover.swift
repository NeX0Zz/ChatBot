import SwiftUI

/// Dropdown list with a checkmark on the selected option (Format / Quality pickers).
struct OptionListPopover<ID: Hashable>: View {
    let options: [PopoverOption<ID>]
    let selection: ID
    let onSelect: (ID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(options) { option in
                let isSelected = option.id == selection
                Button { onSelect(option.id) } label: {
                    row(option, isSelected: isSelected)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .frame(width: 220)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
        .background(AppColor.surface80, in: RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.popover, style: .continuous))
    }

    private func row(_ option: PopoverOption<ID>, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            if let ratio = option.aspectRatio {
                ratioGlyph(ratio, isSelected: isSelected)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(option.title)
                    .appFont(.body16Medium)
                    .foregroundColor(AppColor.textPrimary.opacity(isSelected ? 1 : 0.85))
                if let subtitle = option.subtitle {
                    Text(subtitle)
                        .appFont(.caption12)
                        .foregroundColor(AppColor.textPrimary.opacity(0.45))
                }
            }
            Spacer(minLength: 0)
            if isSelected {
                Image("iconCheckmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(AppGradient.brand)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? AppColor.fillSelected : .clear)
        .contentShape(Rectangle())
    }

    private func ratioGlyph(_ ratio: CGFloat, isSelected: Bool) -> some View {
        let long: CGFloat = 18
        let size = ratio >= 1 ? CGSize(width: long, height: long / ratio) : CGSize(width: long * ratio, height: long)
        return RoundedRectangle(cornerRadius: 3)
            .strokeBorder(AppColor.textPrimary.opacity(isSelected ? 1 : 0.6), lineWidth: 1.5)
            .frame(width: size.width, height: size.height)
            .frame(width: 22, height: 22)
    }
}

extension View {
    /// Shows an `OptionListPopover` over this view; a tap outside closes it.
    /// Apply it to a full-screen container so `alignment` and `insets` are relative to the screen.
    func optionListPopover<ID: Hashable>(
        isPresented: Binding<Bool>,
        options: [PopoverOption<ID>],
        selection: ID,
        alignment: Alignment = .bottomTrailing,
        insets: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: AppSpacing.sideInset),
        onSelect: @escaping (ID) -> Void
    ) -> some View {
        overlay {
            ZStack(alignment: alignment) {
                if isPresented.wrappedValue {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { isPresented.wrappedValue = false }
                    OptionListPopover(options: options, selection: selection) { id in
                        isPresented.wrappedValue = false
                        onSelect(id)
                    }
                    .padding(insets)
                    .transition(.scale(scale: 0.95, anchor: .bottomTrailing).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: isPresented.wrappedValue)
        }
    }
}

struct OptionListPopover_Previews: PreviewProvider {
    static var previews: some View {
        OptionListPopover(
            options: [
                PopoverOption(id: "16:9", title: "16:9", subtitle: "Landscape", aspectRatio: 16.0 / 9),
                PopoverOption(id: "9:16", title: "9:16", subtitle: "Portrait · Stories", aspectRatio: 9.0 / 16),
                PopoverOption(id: "1:1", title: "1:1", subtitle: "Square", aspectRatio: 1)
            ],
            selection: "16:9",
            onSelect: { _ in }
        )
        .padding()
        .background(AppColor.background)
    }
}
