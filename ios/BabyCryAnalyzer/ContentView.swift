import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Listen", systemImage: "waveform") {
                ListenView()
            }

            Tab("History", systemImage: "clock") {
                HistoryView()
            }
        }
        .tint(Color(.label))
    }
}
