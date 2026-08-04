import SwiftUI

@main
struct LeetcodeOSApp: App {
    @StateObject private var hostStore = HostStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(hostStore)
                .preferredColorScheme(.dark)
        }
    }
}
