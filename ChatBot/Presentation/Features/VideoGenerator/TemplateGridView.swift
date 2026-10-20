import SwiftUI

struct TemplateGridView: View {
    let templates: [VideoTemplate]
    let onSelect: (VideoTemplate) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(templates) { template in
                    TemplateCardView(template: template) { onSelect(template) }
                }
            }
            .padding(.horizontal, AppSpacing.sideInset)
            .padding(.vertical, 24)
        }
    }
}
