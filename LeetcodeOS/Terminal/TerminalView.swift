import SwiftUI

struct TerminalView: View {
    @EnvironmentObject private var hostStore: HostStore
    @State private var reloadToken = 0
    @State private var isLoading = false
    @State private var loadFailed = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let url = hostStore.selectedHost?.url {
                    TerminalWebView(url: url,
                                    reloadToken: reloadToken,
                                    isLoading: $isLoading,
                                    loadFailed: $loadFailed)
                        .ignoresSafeArea(edges: .bottom)

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
            .navigationTitle(hostStore.selectedHost?.name ?? "Terminal")
            .navigationBarTitleDisplayMode(.inline)
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
                    Button {
                        reloadToken += 1
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}
