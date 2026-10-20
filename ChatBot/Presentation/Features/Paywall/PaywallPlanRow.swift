import SwiftUI

struct PaywallPlanRow: View {
    let plan: PaywallPlan
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        Text("\(plan.periodName) \(plan.weeklyPrice)").appFont(.body16Medium)
                        Text("/ week").appFont(.body16)
                    }
                    .foregroundColor(AppColor.textPrimary)
                    Text(plan.fullPrice)
                        .appFont(.body14)
                        .foregroundColor(AppColor.textSecondary)
                }
                Spacer(minLength: 0)
                if let percent = plan.savePercent {
                    Text("SAVE \(percent)%")
                        .appFont(.caption13Medium)
                        .foregroundColor(AppColor.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(AppGradient.brand, in: Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(outline)
            .contentShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: isSelected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var outline: some View {
        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
            .strokeBorder(
                isSelected ? AnyShapeStyle(AppGradient.brand) : AnyShapeStyle(AppColor.textPrimary.opacity(0.3)),
                lineWidth: 1
            )
    }
}
