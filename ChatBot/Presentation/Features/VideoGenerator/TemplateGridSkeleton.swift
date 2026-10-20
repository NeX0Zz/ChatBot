import SwiftUI

struct TemplateGridSkeleton: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<8, id: \.self) { _ in
                    TemplateCardSkeleton()
                }
            }
            .padding(.horizontal, AppSpacing.sideInset)
            .padding(.vertical, 24)
        }
        .scrollDisabled(true)
        .accessibilityLabel("Loading templates")
    }
}
