import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var router: AppRouter
    @State private var selectedTab: HistoryTab

    init(initialTab: HistoryTab) {
        _selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            VStack(spacing: 0) {
                NavigationHeader(title: "History", onBack: router.pop)
                SegmentedSwitch(options: [HistoryTab.chats, .videos], selection: $selectedTab) { tab in
                    tab == .chats ? "Chat" : "Video"
                }
                .padding(.horizontal, AppSpacing.sideInset)
                .padding(.top, 4)
                .padding(.bottom, 8)

                ZStack {
                    switch selectedTab {
                    case .chats:
                        ChatHistoryListView().transition(.opacity)
                    case .videos:
                        VideoHistoryView().transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
