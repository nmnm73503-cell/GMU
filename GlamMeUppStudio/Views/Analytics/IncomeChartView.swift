import SwiftUI
import Charts

struct IncomeChartView: View {
    let data: [RevenueDataPoint]

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Revenue Over Time")
                if data.isEmpty {
                    Text("No revenue data").foregroundStyle(Theme.muted)
                } else {
                    Chart(data) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Revenue", point.amount)
                        )
                        .foregroundStyle(Theme.navy)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Revenue", point.amount)
                        )
                        .foregroundStyle(Theme.gold.opacity(0.2).gradient)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 220)
                }
            }
        }
    }
}
