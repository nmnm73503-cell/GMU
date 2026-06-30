import SwiftUI
import SwiftData

struct TimelineView: View {
    let client: CustomerProfile

    var entries: [TimelineEntry] {
        client.timelineEntries.sorted { $0.occurredAt > $1.occurredAt }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(entries) { entry in
                    GlassCard(padding: 14) {
                        HStack(alignment: .top) {
                            Circle().fill(Theme.gold).frame(width: 8, height: 8).padding(.top, 6)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title).font(.headline).foregroundStyle(Theme.navy)
                                if !entry.detail.isEmpty {
                                    Text(entry.detail).font(.caption).foregroundStyle(Theme.muted)
                                }
                                Text(entry.occurredAt.formatted()).font(.caption2).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            if entry.amount > 0 {
                                Text(entry.amount.currencyFormatted()).font(.caption).foregroundStyle(Theme.gold)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.cream)
        .navigationTitle("Timeline")
    }
}
