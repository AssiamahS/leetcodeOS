import SwiftUI
import WebKit

private let terminalBackground = UIColor(red: 0x0d / 255, green: 0x11 / 255, blue: 0x17 / 255, alpha: 1)

struct TerminalWebView: UIViewRepresentable {
    let url: URL
    let reloadToken: Int
    let controller: TerminalController
    @Binding var isLoading: Bool
    @Binding var loadFailed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = terminalBackground
        webView.scrollView.backgroundColor = terminalBackground
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.isScrollEnabled = false
        webView.allowsBackForwardNavigationGestures = false

        // Any tap in the terminal should summon the keyboard (user gesture => allowed).
        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap))
        tap.delegate = context.coordinator
        webView.addGestureRecognizer(tap)

        controller.webView = webView
        context.coordinator.load(url, token: reloadToken, in: webView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        controller.webView = webView
        if context.coordinator.lastURL != url || context.coordinator.lastToken != reloadToken {
            context.coordinator.load(url, token: reloadToken, in: webView)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, WKNavigationDelegate, UIGestureRecognizerDelegate {
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

        @objc func handleTap() {
            Task { @MainActor in
                self.parent.controller.focus()
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
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
