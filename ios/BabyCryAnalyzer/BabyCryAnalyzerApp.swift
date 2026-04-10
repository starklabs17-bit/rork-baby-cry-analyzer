import SwiftUI
import RevenueCat

@main
struct BabyCryAnalyzerApp: App {
    @State private var authService: AuthService = AuthService()
    @State private var historyStore: CryHistoryStore = CryHistoryStore()
    @State private var storeVM: StoreViewModel = StoreViewModel()

    init() {
        #if DEBUG
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY)
        #else
        Purchases.configure(withAPIKey: Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                    }
                } else if authService.isAuthenticated {
                    ContentView(store: storeVM, authService: authService)
                        .environment(historyStore)
                } else {
                    SignInView(authService: authService)
                }
            }
            .animation(.smooth(duration: 0.3), value: authService.isAuthenticated)
            .animation(.smooth(duration: 0.3), value: authService.isLoading)
        }
    }
}
