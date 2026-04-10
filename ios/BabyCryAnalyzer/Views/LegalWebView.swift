import SwiftUI
import WebKit

struct LegalWebView: View {
    let title: String
    let url: URL

    var body: some View {
        NavigationStack {
            WebViewRepresentable(url: url)
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct WebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
