import SwiftUI

@main
struct BabyCryAnalyzerApp: App {
    @State private var historyStore = CryHistoryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(historyStore)
        }
    }
}
