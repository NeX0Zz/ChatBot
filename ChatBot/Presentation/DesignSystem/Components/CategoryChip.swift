import SwiftUI

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .appFont(.body14)
                .foregroundColor(AppColor.textPrimary.opacity(isSelected ? 1 : 0.5))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(background)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            Capsule().fill(AppGradient.brand)
        } else {
            Capsule().fill(AppColor.surface60)
        }
    }
}

struct CategoryChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            CategoryChip(title: "Popular", isSelected: true) {}
            CategoryChip(title: "Funny", isSelected: false) {}
        }
        .padding()
        .background(AppColor.background)
    }
}
