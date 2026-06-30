import Foundation
import SwiftData

struct InstagramPublicProfile {
    let username: String
    let fullName: String
    let followerCount: Int
    let followingCount: Int
    let postCount: Int
    let biography: String
    let fetchedAt: Date
}

@Observable
final class InstagramInsightsService {
    static let shared = InstagramInsightsService()
    var lastProfile: InstagramPublicProfile?
    var lastError: String?
    var isLoading = false

    func fetchAndSnapshot(username: String, context: ModelContext) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            let profile = try await fetchPublicProfile(username: username)
            lastProfile = profile
            let snapshot = AnalyticsSnapshot(
                capturedAt: .now,
                instagramUsername: username,
                followerCount: profile.followerCount,
                followingCount: profile.followingCount,
                postCount: profile.postCount,
                averageLikes: 0,
                source: "api"
            )
            context.insert(snapshot)
            try context.save()
        } catch {
            lastError = error.localizedDescription
            if let cached = latestSnapshot(context: context, username: username) {
                lastProfile = InstagramPublicProfile(
                    username: username,
                    fullName: "Nawal | Makeup Artist",
                    followerCount: cached.followerCount,
                    followingCount: cached.followingCount,
                    postCount: cached.postCount,
                    biography: "",
                    fetchedAt: cached.capturedAt
                )
            }
        }
    }

    func latestSnapshot(context: ModelContext, username: String = "glam.me.upp") -> AnalyticsSnapshot? {
        var descriptor = FetchDescriptor<AnalyticsSnapshot>(
            predicate: #Predicate { $0.instagramUsername == username },
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func snapshots(context: ModelContext, username: String = "glam.me.upp") -> [AnalyticsSnapshot] {
        let descriptor = FetchDescriptor<AnalyticsSnapshot>(
            predicate: #Predicate { $0.instagramUsername == username },
            sortBy: [SortDescriptor(\.capturedAt)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func saveManualSnapshot(
        username: String,
        followers: Int,
        following: Int,
        posts: Int,
        averageLikes: Double,
        context: ModelContext
    ) {
        let snapshot = AnalyticsSnapshot(
            instagramUsername: username,
            followerCount: followers,
            followingCount: following,
            postCount: posts,
            averageLikes: averageLikes,
            source: "manual"
        )
        context.insert(snapshot)
        try? context.save()
        lastProfile = InstagramPublicProfile(
            username: username,
            fullName: "Manual Entry",
            followerCount: followers,
            followingCount: following,
            postCount: posts,
            biography: "",
            fetchedAt: .now
        )
    }

    private func fetchPublicProfile(username: String) async throws -> InstagramPublicProfile {
        guard let url = URL(string: "https://www.instagram.com/api/v1/users/web_profile_info/?username=\(username)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.setValue("936619743392459", forHTTPHeaderField: "X-IG-App-ID")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        struct IGResponse: Decodable {
            struct DataWrapper: Decodable {
                struct User: Decodable {
                    let username: String
                    let full_name: String
                    let biography: String
                    struct Count { let count: Int }
                    let edge_followed_by: Count
                    let edge_follow: Count
                    let edge_owner_to_timeline_media: Count
                }
                let user: User
            }
            let data: DataWrapper
        }

        let decoded = try JSONDecoder().decode(IGResponse.self, from: data)
        let user = decoded.data.user
        return InstagramPublicProfile(
            username: user.username,
            fullName: user.full_name,
            followerCount: user.edge_followed_by.count,
            followingCount: user.edge_follow.count,
            postCount: user.edge_owner_to_timeline_media.count,
            biography: user.biography,
            fetchedAt: .now
        )
    }
}
