import SwiftUI

@main
struct ChatBotApp: App {
    @StateObject private var model = AppModel()

    init() {
        FontRegistrar.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView(container: model.container)
                .preferredColorScheme(.dark)
        }
    }
}
