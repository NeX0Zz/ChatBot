import Foundation

struct ChatHistorySection: Identifiable {
    let id: String
    let title: String
    let chats: [Chat]

    /// "Pinned" first, then chats grouped by creation day: Today, Yesterday, then dated blocks.
    static func make(from chats: [Chat], calendar: Calendar = .current, now: Date = Date()) -> [ChatHistorySection] {
        var sections: [ChatHistorySection] = []
        let pinned = chats.filter(\.isPinned).sorted { $0.updatedAt > $1.updatedAt }
        if !pinned.isEmpty {
            sections.append(ChatHistorySection(id: "pinned", title: String(localized: "Pinned"), chats: pinned))
        }
        let unpinned = chats.filter { !$0.isPinned }
        let groups = Dictionary(grouping: unpinned) { calendar.startOfDay(for: $0.createdAt) }
        for day in groups.keys.sorted(by: >) {
            let dayChats = (groups[day] ?? []).sorted { $0.updatedAt > $1.updatedAt }
            sections.append(ChatHistorySection(
                id: "day-\(day.timeIntervalSince1970)",
                title: title(for: day, calendar: calendar, now: now),
                chats: dayChats
            ))
        }
        return sections
    }

    private static func title(for day: Date, calendar: Calendar, now: Date) -> String {
        if calendar.isDate(day, inSameDayAs: now) { return String(localized: "Today") }
        if calendar.isDateInYesterday(day) { return String(localized: "Yesterday") }
        let sameYear = calendar.isDate(day, equalTo: now, toGranularity: .year)
        return (sameYear ? dayFormatter : dayWithYearFormatter).string(from: day)
    }

    private static let dayFormatter = makeFormatter(template: "MMMMd")
    private static let dayWithYearFormatter = makeFormatter(template: "MMMMdyyyy")

    private static func makeFormatter(template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
