import SwiftUI

enum AppTab: Hashable {
    case terminal, plan, leetcode, settings
}

@MainActor
final class AppModel: ObservableObject {
    @Published var tab: AppTab = .terminal
    @Published var pendingCommand: String?

    func solveInTerminal(day: Int) {
        pendingCommand = String(format: "cd ~/leetcode30/day%02d 2>/dev/null && ls || echo 'day %d not set up yet'", day, day)
        tab = .terminal
    }
}

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView(selection: $appModel.tab) {
            TerminalView()
                .tabItem { Label("Terminal", systemImage: "terminal.fill") }
                .tag(AppTab.terminal)

            StudyPlanView()
                .tabItem { Label("30 Days", systemImage: "calendar") }
                .tag(AppTab.plan)

            LeetCodeView()
                .tabItem { Label("LeetCode", systemImage: "chevron.left.forwardslash.chevron.right") }
                .tag(AppTab.leetcode)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(Color(red: 1.0, green: 0.63, blue: 0.09))
    }
}
