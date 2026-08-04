import SwiftUI

private let termBg = Color(red: 0x0d / 255, green: 0x11 / 255, blue: 0x17 / 255)

private let termTheme = "{\"background\":\"#0d1117\",\"foreground\":\"#e6edf3\",\"cursor\":\"#ffa116\","
    + "\"cursorAccent\":\"#0d1117\",\"selectionBackground\":\"#264f78\",\"black\":\"#161b22\","
    + "\"red\":\"#ff7b72\",\"green\":\"#3fb950\",\"yellow\":\"#d29922\",\"blue\":\"#58a6ff\","
    + "\"magenta\":\"#bc8cff\",\"cyan\":\"#39c5cf\",\"white\":\"#b1bac4\",\"brightBlack\":\"#6e7681\","
    + "\"brightRed\":\"#ffa198\",\"brightGreen\":\"#56d364\",\"brightYellow\":\"#e3b341\","
    + "\"brightBlue\":\"#79c0ff\",\"brightMagenta\":\"#d2a8ff\",\"brightCyan\":\"#56d4dd\","
    + "\"brightWhite\":\"#f0f6fc\"}"

struct TerminalView: View {
    @EnvironmentObject private var hostStore: HostStore
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var controller = TerminalController()
    @AppStorage("terminalFontSize") private var fontSize = 15
    @State private var reloadToken = 0
    @State private var isLoading = false
    @State private var loadFailed = false

    /// ttyd parses URL query params as client options — fontSize, theme, etc.
    /// (parseOptsFromUrlQuery in ttyd's xterm wrapper.)
    private var terminalURL: URL? {
        guard let base = hostStore.selectedHost?.url,
              var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return nil }
        var items: [URLQueryItem] = comps.queryItems ?? []
        items.append(URLQueryItem(name: "fontSize", value: String(fontSize)))
        items.append(URLQueryItem(name: "theme", value: termTheme))
        items.append(URLQueryItem(name: "disableLeaveAlert", value: "true"))
        items.append(URLQueryItem(name: "disableResizeOverlay", value: "true"))
        items.append(URLQueryItem(name: "titleFixed", value: "leetcodeOS"))
        comps.queryItems = items
        return comps.url
    }

    var body: some View {
        NavigationStack {
            ZStack {
                termBg.ignoresSafeArea()

                if let url = terminalURL {
                    TerminalWebView(url: url,
                                    reloadToken: reloadToken,
                                    controller: controller,
                                    isLoading: $isLoading,
                                    loadFailed: $loadFailed)

                    if isLoading {
                        ProgressView("Connecting…")
                            .tint(.green)
                            .foregroundStyle(.green)
                    }

                    if loadFailed {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text("Can't reach \(hostStore.selectedHost?.name ?? "host")")
                                .foregroundStyle(.secondary)
                            Text("Check Tailscale is connected on this phone.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Button("Retry") { reloadToken += 1 }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                        }
                        .padding()
                        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    ContentUnavailableView("No terminal host",
                                           systemImage: "terminal",
                                           description: Text("Add a host in Settings."))
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) { keyBar }
            .navigationTitle(hostStore.selectedHost?.name ?? "Terminal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(termBg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(hostStore.hosts) { host in
                            Button {
                                hostStore.selectedID = host.id
                                reloadToken += 1
                            } label: {
                                if host.id == hostStore.selectedHost?.id {
                                    Label(host.name, systemImage: "checkmark")
                                } else {
                                    Text(host.name)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "server.rack")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Stepper("Font \(fontSize) pt", value: $fontSize, in: 10...24)
                        Button("Reconnect", systemImage: "arrow.clockwise") { reloadToken += 1 }
                    } label: {
                        Image(systemName: "textformat.size")
                    }
                }
            }
            .onChange(of: fontSize) { reloadToken += 1 }
            .onChange(of: appModel.pendingCommand) { runPendingCommand() }
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                runPendingCommand()
            }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }

    private func runPendingCommand() {
        guard let cmd = appModel.pendingCommand else { return }
        appModel.pendingCommand = nil
        // Small delay so a freshly opened tab has the socket up.
        Task {
            try? await Task.sleep(for: .seconds(isLoading ? 1.5 : 0.2))
            controller.send(cmd + "\n")
        }
    }

    private var keyBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                key("esc") { controller.send(TermKey.esc) }
                key("tab") { controller.send(TermKey.tab) }
                key("^C") { controller.send(TermKey.ctrlC) }
                key("^D") { controller.send(TermKey.ctrlD) }
                key("^L") { controller.send(TermKey.ctrlL) }
                key("^Z") { controller.send(TermKey.ctrlZ) }
                keyIcon("arrow.up") { controller.send(TermKey.up) }
                keyIcon("arrow.down") { controller.send(TermKey.down) }
                keyIcon("arrow.left") { controller.send(TermKey.left) }
                keyIcon("arrow.right") { controller.send(TermKey.right) }
                key("|") { controller.send("|") }
                key("~") { controller.send("~") }
                key("-") { controller.send("-") }
                key("/") { controller.send("/") }
                keyIcon("doc.on.clipboard") { controller.pasteClipboard() }
                keyIcon("keyboard") { controller.focus() }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(Color(red: 0x16 / 255, green: 0x1b / 255, blue: 0x22 / 255))
    }

    private func key(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color(red: 0.9, green: 0.93, blue: 0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func keyIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.9, green: 0.93, blue: 0.95))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
