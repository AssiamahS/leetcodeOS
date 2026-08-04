import Foundation
import WebKit

/// Bridge from native UI into the ttyd page's `window.term` (xterm.js).
@MainActor
final class TerminalController: ObservableObject {
    weak var webView: WKWebView?

    /// Send raw bytes to the shell (arrow keys, control chars, typed macros).
    func send(_ text: String) {
        run("window.term && window.term.input(\(jsString(text)))")
    }

    /// Paste through xterm's paste path so bracketed paste works in vim/claude.
    func pasteClipboard() {
        guard let text = UIPasteboard.general.string else { return }
        run("window.term && window.term.paste(\(jsString(text)))")
    }

    func focus() {
        run("window.term && window.term.focus()")
    }

    func fit() {
        run("window.term && window.term.fit && window.term.fit()")
    }

    private func run(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private func jsString(_ s: String) -> String {
        let data = try? JSONEncoder().encode([s])
        guard let json = data.flatMap({ String(data: $0, encoding: .utf8) }) else { return "\"\"" }
        return String(json.dropFirst().dropLast())
    }
}

enum TermKey {
    static let esc = "\u{1b}"
    static let tab = "\t"
    static let ctrlC = "\u{03}"
    static let ctrlD = "\u{04}"
    static let ctrlL = "\u{0c}"
    static let ctrlZ = "\u{1a}"
    static let up = "\u{1b}[A"
    static let down = "\u{1b}[B"
    static let right = "\u{1b}[C"
    static let left = "\u{1b}[D"
}
