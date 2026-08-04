import Foundation
import Combine

struct TerminalHost: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var urlString: String

    var url: URL? { URL(string: urlString) }
}

@MainActor
final class HostStore: ObservableObject {
    private static let hostsKey = "terminalHosts"
    private static let selectedKey = "selectedHostID"

    @Published var hosts: [TerminalHost] {
        didSet { save() }
    }
    @Published var selectedID: UUID? {
        didSet {
            UserDefaults.standard.set(selectedID?.uuidString, forKey: Self.selectedKey)
        }
    }

    var selectedHost: TerminalHost? {
        hosts.first(where: { $0.id == selectedID }) ?? hosts.first
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.hostsKey),
           let decoded = try? JSONDecoder().decode([TerminalHost].self, from: data),
           !decoded.isEmpty {
            hosts = decoded
        } else {
            hosts = [
                TerminalHost(name: "slyterm (Mac)",
                             urlString: "http://saints-macbook-air.tail40af16.ts.net:7681")
            ]
        }
        if let raw = UserDefaults.standard.string(forKey: Self.selectedKey),
           let id = UUID(uuidString: raw) {
            selectedID = id
        }
    }

    func add(name: String, urlString: String) {
        hosts.append(TerminalHost(name: name, urlString: urlString))
    }

    func delete(at offsets: IndexSet) {
        hosts.remove(atOffsets: offsets)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(hosts) {
            UserDefaults.standard.set(data, forKey: Self.hostsKey)
        }
    }
}
