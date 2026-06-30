import SwiftUI
import SwiftData
import Charts

struct InstagramInsightsView: View {
    @Environment(\.modelContext) private var context
    @State private var igService = InstagramInsightsService.shared
    @State private var manualFollowers = ""
    @State private var manualPosts = ""
    @State private var showManual = false

    private var snapshots: [AnalyticsSnapshot] {
        igService.snapshots(context: context)
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Instagram @glam.me.upp")

                if let profile = igService.lastProfile {
                    HStack {
                        MetricTile(title: "Followers", value: "\(profile.followerCount)")
                        MetricTile(title: "Posts", value: "\(profile.postCount)")
                    }
                    Text("Updated \(profile.fetchedAt.formatted())")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                } else if let latest = igService.latestSnapshot(context: context) {
                    HStack {
                        MetricTile(title: "Followers", value: "\(latest.followerCount)")
                        MetricTile(title: "Posts", value: "\(latest.postCount)")
                    }
                    Text("Cached \(latest.capturedAt.formatted()) • \(latest.source)")
                        .font(.caption)
                        .foregroundStyle(Theme.muted)
                }

                if let error = igService.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if snapshots.count > 1 {
                    Chart(snapshots) { snap in
                        LineMark(
                            x: .value("Date", snap.capturedAt),
                            y: .value("Followers", snap.followerCount)
                        )
                        .foregroundStyle(Theme.gold)
                    }
                    .frame(height: 140)
                }

                HStack {
                    LuxuryButton(title: igService.isLoading ? "Loading…" : "Refresh IG Stats") {
                        Task { await igService.fetchAndSnapshot(username: "glam.me.upp", context: context) }
                    }
                    .disabled(igService.isLoading)
                    Button("Manual Entry") { showManual = true }
                        .font(.caption)
                }
            }
        }
        .task {
            if igService.lastProfile == nil {
                await igService.fetchAndSnapshot(username: "glam.me.upp", context: context)
            }
        }
        .alert("Manual IG Stats", isPresented: $showManual) {
            TextField("Followers", text: $manualFollowers).keyboardType(.numberPad)
            TextField("Posts", text: $manualPosts).keyboardType(.numberPad)
            Button("Save") {
                igService.saveManualSnapshot(
                    username: "glam.me.upp",
                    followers: Int(manualFollowers) ?? 0,
                    following: 0,
                    posts: Int(manualPosts) ?? 0,
                    averageLikes: 0,
                    context: context
                )
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
