import SwiftUI

struct ContentView: View {
    var store: StoreViewModel
    var authService: AuthService

    var body: some View {
        TabView {
            Tab("Listen", systemImage: "waveform") {
                ListenView(store: store)
            }
            Tab("History", systemImage: "clock") {
                HistoryView()
            }
            Tab("Profile", systemImage: "person.circle") {
                ProfileView(store: store, authService: authService)
            }
        }
        .tint(Color(.label))
    }
}
