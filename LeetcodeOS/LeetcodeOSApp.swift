import SwiftUI

@main
struct LeetcodeOSApp: App {
    @StateObject private var hostStore = HostStore()
    @StateObject private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostStore)
                .environmentObject(appModel)
                .preferredColorScheme(.dark)
        }
    }
}
