import SwiftUI

struct VideoHistoryBadge: View {
    enum Kind {
        case new
        case inProgress
        case error

        var title: LocalizedStringKey {
            switch self {
            case .new: "New"
            case .inProgress: "In progress"
            case .error: "Error"
            }
        }

        var color: Color {
            switch self {
            case .new: AppColor.success
            case .inProgress: AppColor.generating
            case .error: AppColor.failure
            }
        }
    }

    let kind: Kind

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(kind.color)
                .frame(width: 6, height: 6)
            Text(kind.title)
                .appFont(.caption12Medium)
                .foregroundColor(kind.color)
        }
        .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 10))
        .background(AppColor.backgroundDeep.opacity(0.7), in: Capsule())
        .overlay(Capsule().strokeBorder(kind.color.opacity(0.5), lineWidth: 1))
    }
}
