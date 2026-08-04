import SwiftUI
import WebKit

struct TerminalWebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = false
        context.coordinator.load(url, token: reloadToken, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastURL != url || context.coordinator.lastToken != reloadToken {
            context.coordinator.load(url, token: reloadToken, in: webView)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let parent: TerminalWebView
        var lastURL: URL?
        var lastToken = -1

        init(_ parent: TerminalWebView) {
            self.parent = parent
        }

        func load(_ url: URL, token: Int, in webView: WKWebView) {
            lastURL = url
            lastToken = token
            parent.isLoading = true
            parent.loadFailed = false
            webView.load(URLRequest(url: url, timeoutInterval: 10))
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadFailed = true
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.loadFailed = true
        }
    }
}
