import Foundation

struct DailyChallenge {
    let date: String
    let link: URL?
    let questionId: String
    let title: String
    let titleSlug: String
    let difficulty: String
    let acRate: Double
    let tags: [String]
}

struct UserStats {
    let username: String
    let ranking: Int?
    let easy: Int
    let medium: Int
    let hard: Int

    var total: Int { easy + medium + hard }
}

enum LeetCodeError: LocalizedError {
    case badResponse
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .badResponse: return "LeetCode returned an unexpected response."
        case .userNotFound: return "No LeetCode user with that username."
        }
    }
}

enum LeetCodeAPI {
    private static let endpoint = URL(string: "https://leetcode.com/graphql")!

    private static func graphql(query: String, variables: [String: Any] = [:]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "query": query,
            "variables": variables
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200,
              let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let payload = json["data"] as? [String: Any] else {
            throw LeetCodeError.badResponse
        }
        return payload
    }

    static func daily() async throws -> DailyChallenge {
        let query = """
        query questionOfToday {
          activeDailyCodingChallengeQuestion {
            date
            link
            question {
              questionFrontendId
              title
              titleSlug
              difficulty
              acRate
              topicTags { name }
            }
          }
        }
        """
        let data = try await graphql(query: query)
        guard let active = data["activeDailyCodingChallengeQuestion"] as? [String: Any],
              let question = active["question"] as? [String: Any],
              let title = question["title"] as? String else {
            throw LeetCodeError.badResponse
        }
        let linkPath = active["link"] as? String ?? ""
        let tags = (question["topicTags"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
        return DailyChallenge(
            date: active["date"] as? String ?? "",
            link: URL(string: "https://leetcode.com" + linkPath),
            questionId: question["questionFrontendId"] as? String ?? "?",
            title: title,
            titleSlug: question["titleSlug"] as? String ?? "",
            difficulty: question["difficulty"] as? String ?? "Unknown",
            acRate: question["acRate"] as? Double ?? 0,
            tags: tags
        )
    }

    static func stats(username: String) async throws -> UserStats {
        let query = """
        query userProfile($username: String!) {
          matchedUser(username: $username) {
            username
            profile { ranking }
            submitStatsGlobal {
              acSubmissionNum { difficulty count }
            }
          }
        }
        """
        let data = try await graphql(query: query, variables: ["username": username])
        guard let user = data["matchedUser"] as? [String: Any] else {
            throw LeetCodeError.userNotFound
        }
        let profile = user["profile"] as? [String: Any]
        let submissions = ((user["submitStatsGlobal"] as? [String: Any])?["acSubmissionNum"] as? [[String: Any]]) ?? []

        func count(_ difficulty: String) -> Int {
            submissions.first(where: { ($0["difficulty"] as? String) == difficulty })?["count"] as? Int ?? 0
        }

        return UserStats(
            username: user["username"] as? String ?? username,
            ranking: profile?["ranking"] as? Int,
            easy: count("Easy"),
            medium: count("Medium"),
            hard: count("Hard")
        )
    }
}
