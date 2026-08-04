import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var hostStore: HostStore
    @AppStorage("leetcodeUsername") private var username = ""
    @State private var newHostName = ""
    @State private var newHostURL = ""
    @State private var showingAddHost = false

    var body: some View {
        NavigationStack {
            Form {
                Section("LeetCode") {
                    TextField("Username (public profile)", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("No sign-in needed — stats come from your public profile.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Terminal Hosts") {
                    ForEach(hostStore.hosts) { host in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(host.name)
                            Text(host.urlString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { hostStore.delete(at: $0) }

                    Button {
                        showingAddHost = true
                    } label: {
                        Label("Add Host", systemImage: "plus")
                    }
                }

                Section {
                    Text("Terminal connects over Tailscale to a ttyd server (like slyterm on your Mac). Make sure Tailscale is on.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .alert("Add Terminal Host", isPresented: $showingAddHost) {
                TextField("Name", text: $newHostName)
                TextField("URL (http://host:port)", text: $newHostURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add") {
                    let trimmedURL = newHostURL.trimmingCharacters(in: .whitespaces)
                    let trimmedName = newHostName.trimmingCharacters(in: .whitespaces)
                    if !trimmedURL.isEmpty {
                        hostStore.add(name: trimmedName.isEmpty ? trimmedURL : trimmedName,
                                      urlString: trimmedURL)
                    }
                    newHostName = ""
                    newHostURL = ""
                }
                Button("Cancel", role: .cancel) {
                    newHostName = ""
                    newHostURL = ""
                }
            }
        }
    }
}
