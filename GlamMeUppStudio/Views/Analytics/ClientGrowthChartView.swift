import SwiftUI
import Charts

struct ClientGrowthChartView: View {
    let data: [ClientGrowthPoint]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Client Growth")
                if data.isEmpty {
                    Text("No client growth data").foregroundStyle(Theme.muted)
                } else {
                    Chart(data) { point in
                        BarMark(
                            x: .value("Month", point.date, unit: .month),
                            y: .value("New", point.newClients)
                        )
                        .foregroundStyle(Theme.gold)
                        BarMark(
                            x: .value("Month", point.date, unit: .month),
                            y: .value("Returning", point.returningClients)
                        )
                        .foregroundStyle(Theme.navy.opacity(0.7))
                    }
                    .frame(height: 200)
                }
            }
        }
    }
}
