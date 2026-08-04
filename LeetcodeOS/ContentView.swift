import SwiftUI

enum AppTab: Hashable {
    case terminal, leetcode, settings
}

struct ContentView: View {
    @State private var tab: AppTab = .terminal

    var body: some View {
        TabView(selection: $tab) {
            TerminalView()
                .tabItem { Label("Terminal", systemImage: "terminal.fill") }
                .tag(AppTab.terminal)

            LeetCodeView(openTerminal: { tab = .terminal })
                .tabItem { Label("LeetCode", systemImage: "chevron.left.forwardslash.chevron.right") }
                .tag(AppTab.leetcode)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(Color(red: 1.0, green: 0.63, blue: 0.09))
    }
}
