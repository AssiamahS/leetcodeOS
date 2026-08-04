import SwiftUI

struct StudyPlanView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var progress = PlanProgress()
    @State private var problems: [PlanProblem] = []
    @State private var errorMessage: String?

    private var doneCount: Int {
        problems.filter { progress.completed.contains($0.titleSlug) }.count
    }

    var body: some View {
        NavigationStack {
            List {
                if !problems.isEmpty {
                    Section {
                        HStack(spacing: 14) {
                            ProgressView(value: Double(doneCount), total: Double(problems.count))
                                .tint(.green)
                            Text("\(doneCount)/\(problems.count)")
                                .font(.subheadline.monospacedDigit().bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                ForEach(groupedSections, id: \.0) { section, items in
                    Section(section) {
                        ForEach(items) { problem in
                            row(problem)
                        }
                    }
                }

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("30 Days of JS")
            .overlay {
                if problems.isEmpty && errorMessage == nil {
                    ProgressView("Loading plan…")
                }
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private var groupedSections: [(String, [PlanProblem])] {
        var order: [String] = []
        var buckets: [String: [PlanProblem]] = [:]
        for p in problems {
            if buckets[p.section] == nil { order.append(p.section) }
            buckets[p.section, default: []].append(p)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    private func row(_ problem: PlanProblem) -> some View {
        let done = progress.completed.contains(problem.titleSlug)
        return HStack(spacing: 12) {
            Button {
                progress.toggle(problem.titleSlug)
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(done ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text("Day \(problem.day) · \(problem.questionId)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(problem.title)
                    .font(.subheadline)
                    .strikethrough(done, color: .secondary)
            }

            Spacer()

            Menu {
                Button("Solve in Terminal", systemImage: "terminal") {
                    appModel.solveInTerminal(day: problem.day)
                }
                if let link = problem.link {
                    Link(destination: link) {
                        Label("Open on LeetCode", systemImage: "safari")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func load() async {
        errorMessage = nil
        do {
            problems = try await LeetCodeAPI.thirtyDaysOfJavaScript()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
