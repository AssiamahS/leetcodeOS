import Foundation

struct PlanProblem: Identifiable {
    let day: Int
    let section: String
    let questionId: String
    let title: String
    let titleSlug: String
    let difficulty: String

    var id: String { titleSlug }
    var link: URL? {
        URL(string: "https://leetcode.com/problems/\(titleSlug)/?envType=study-plan-v2&envId=30-days-of-javascript")
    }
}

extension LeetCodeAPI {
    static func thirtyDaysOfJavaScript() async throws -> [PlanProblem] {
        let query = """
        query studyPlanV2Detail($slug: String!) {
          studyPlanV2Detail(planSlug: $slug) {
            name
            planSubGroups {
              name
              questions { questionFrontendId title titleSlug difficulty }
            }
          }
        }
        """
        let data = try await graphqlPublic(query: query, variables: ["slug": "30-days-of-javascript"])
        guard let plan = data["studyPlanV2Detail"] as? [String: Any],
              let groups = plan["planSubGroups"] as? [[String: Any]] else {
            throw LeetCodeError.badResponse
        }
        var problems: [PlanProblem] = []
        var day = 0
        for group in groups {
            let section = group["name"] as? String ?? ""
            for q in (group["questions"] as? [[String: Any]] ?? []) {
                day += 1
                problems.append(PlanProblem(
                    day: day,
                    section: section,
                    questionId: q["questionFrontendId"] as? String ?? "?",
                    title: q["title"] as? String ?? "?",
                    titleSlug: q["titleSlug"] as? String ?? "",
                    difficulty: (q["difficulty"] as? String ?? "EASY").capitalized
                ))
            }
        }
        return problems
    }
}

/// Locally tracked completion for the study plan.
@MainActor
final class PlanProgress: ObservableObject {
    private static let key = "planCompletedSlugs"

    @Published private(set) var completed: Set<String>

    init() {
        completed = Set(UserDefaults.standard.stringArray(forKey: Self.key) ?? [])
    }

    func toggle(_ slug: String) {
        if completed.contains(slug) {
            completed.remove(slug)
        } else {
            completed.insert(slug)
        }
        UserDefaults.standard.set(Array(completed), forKey: Self.key)
    }
}
