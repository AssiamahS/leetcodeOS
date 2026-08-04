import SwiftUI

struct LeetCodeView: View {
    let openTerminal: () -> Void

    @AppStorage("leetcodeUsername") private var username = ""
    @State private var daily: DailyChallenge?
    @State private var stats: UserStats?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let daily {
                        dailyCard(daily)
                    } else if errorMessage == nil {
                        ProgressView("Loading daily challenge…")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    }

                    if let stats {
                        statsCard(stats)
                    } else if !username.isEmpty && errorMessage == nil {
                        ProgressView()
                    } else if username.isEmpty {
                        Text("Set your LeetCode username in Settings to see your solve stats.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding()
            }
            .navigationTitle("LeetCode")
            .refreshable { await load() }
            .task { await load() }
            .onChange(of: username) { Task { await load() } }
        }
    }

    private func dailyCard(_ daily: DailyChallenge) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Challenge")
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(daily.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(daily.questionId). \(daily.title)")
                .font(.title3.bold())

            HStack(spacing: 12) {
                Text(daily.difficulty)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(difficultyColor(daily.difficulty).opacity(0.2),
                                in: Capsule())
                    .foregroundStyle(difficultyColor(daily.difficulty))
                Text(String(format: "%.1f%% accepted", daily.acRate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !daily.tags.isEmpty {
                Text(daily.tags.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button {
                    openTerminal()
                } label: {
                    Label("Solve in Terminal", systemImage: "terminal")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                if let link = daily.link {
                    Link(destination: link) {
                        Label("Open", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statsCard(_ stats: UserStats) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stats.username)
                    .font(.headline)
                Spacer()
                if let ranking = stats.ranking {
                    Text("Rank #\(ranking)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 0) {
                statPill("Easy", stats.easy, .green)
                statPill("Medium", stats.medium, .orange)
                statPill("Hard", stats.hard, .red)
                statPill("Total", stats.total, .primary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statPill(_ label: String, _ value: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Hard": return .red
        default: return .secondary
        }
    }

    private func load() async {
        errorMessage = nil
        do {
            daily = try await LeetCodeAPI.daily()
        } catch {
            errorMessage = error.localizedDescription
        }
        guard !username.isEmpty else {
            stats = nil
            return
        }
        do {
            stats = try await LeetCodeAPI.stats(username: username)
        } catch {
            stats = nil
            errorMessage = error.localizedDescription
        }
    }
}
