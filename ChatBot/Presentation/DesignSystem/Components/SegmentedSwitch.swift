import SwiftUI

struct SegmentedSwitch<Option: Hashable>: View {
    private let options: [Option]
    private let title: (Option) -> LocalizedStringKey
    @Binding private var selection: Option
    @Namespace private var selectionNamespace

    init(options: [Option], selection: Binding<Option>, title: @escaping (Option) -> LocalizedStringKey) {
        self.options = options
        self._selection = selection
        self.title = title
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        selection = option
                    }
                } label: {
                    Text(title(option))
                        .appFont(.button16Semibold)
                        .foregroundColor(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if option == selection {
                                Capsule()
                                    .fill(AppColor.fillSubtle)
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])
            }
        }
        .padding(4)
        .frame(height: AppSpacing.controlHeight)
        .background(AppColor.surface40, in: Capsule())
    }
}

struct SegmentedSwitch_Previews: PreviewProvider {
    private struct Demo: View {
        @State private var selection = "Chat"
        var body: some View {
            SegmentedSwitch(options: ["Chat", "Video"], selection: $selection) { LocalizedStringKey($0) }
                .padding(16)
                .background(AppColor.background)
        }
    }

    static var previews: some View { Demo() }
}
