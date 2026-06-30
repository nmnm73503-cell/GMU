import SwiftUI
import SwiftData
import Charts

struct AnalyticsDashboardView: View {
    @Query private var appointments: [Appointment]
    @Query private var clients: [CustomerProfile]
    @Query private var expenses: [Expense]
    @Query private var payments: [PaymentRecord]

    @State private var period: AnalyticsPeriod = .month
    @State private var customStart = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customEnd = Date.now

    private var report: AnalyticsReport {
        AnalyticsEngine.generateReport(
            period: period,
            customStart: customStart,
            customEnd: customEnd,
            appointments: appointments,
            clients: clients,
            expenses: expenses,
            payments: payments
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    summaryTiles
                    IncomeChartView(data: report.revenueOverTime)
                    serviceBreakdownChart
                    paymentBreakdownSection
                    ClientGrowthChartView(data: report.clientGrowth)
                    frequentClientsSection
                    leadSourcesSection
                    wellnessSection
                    InstagramInsightsView()
                }
                .padding()
            }
            .background(Theme.cream)
            .navigationTitle("Analytics")
        }
    }

    private var periodPicker: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Time Period").font(Theme.headlineFont)
                Picker("Period", selection: $period) {
                    ForEach(AnalyticsPeriod.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .pickerStyle(.segmented)
                if period == .custom {
                    DatePicker("From", selection: $customStart, displayedComponents: .date)
                    DatePicker("To", selection: $customEnd, displayedComponents: .date)
                }
            }
        }
    }

    private var summaryTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Revenue", value: report.totalRevenue.currencyFormatted())
            MetricTile(title: "Appointments", value: "\(report.totalAppointments)")
            MetricTile(title: "Avg Booking", value: report.averageBookingValue.currencyFormatted())
            MetricTile(title: "Top Month", value: report.topRevenueMonth)
            MetricTile(title: "New Clients", value: "\(report.newClientCount)")
            MetricTile(title: "Returning", value: "\(report.returningClientCount)")
        }
    }

    private var serviceBreakdownChart: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Revenue by Service")
                if report.serviceBreakdown.isEmpty {
                    Text("No data in period").foregroundStyle(Theme.muted)
                } else {
                    Chart(report.serviceBreakdown) { item in
                        BarMark(
                            x: .value("Revenue", item.amount),
                            y: .value("Service", item.name)
                        )
                        .foregroundStyle(Theme.gold.gradient)
                    }
                    .frame(height: CGFloat(max(120, report.serviceBreakdown.count * 36)))
                }
            }
        }
    }

    private var paymentBreakdownSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Payment Types")
                LabeledContent("Deposits", value: report.paymentBreakdown.deposits.currencyFormatted())
                LabeledContent("Final", value: report.paymentBreakdown.finalPayments.currencyFormatted())
                LabeledContent("Partial", value: report.paymentBreakdown.partialPayments.currencyFormatted())
                LabeledContent("Cancellation Fees", value: report.paymentBreakdown.cancellationFees.currencyFormatted())
            }
        }
    }

    private var frequentClientsSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Most Frequent Clients")
                ForEach(report.frequentClients.prefix(5)) { client in
                    HStack {
                        Text(client.name)
                        Spacer()
                        Text("\(client.visits) visits")
                            .font(.caption)
                        Text(client.revenue.currencyFormatted())
                            .foregroundStyle(Theme.gold)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var leadSourcesSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Lead Sources")
                ForEach(report.leadSources) { stat in
                    HStack {
                        Text(stat.source)
                        Spacer()
                        Text("\(stat.count) • \(stat.revenue.currencyFormatted())")
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                    }
                }
            }
        }
    }

    private var wellnessSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Wellness & Business Health")
                LabeledContent("Appts / Week", value: String(format: "%.1f", report.wellness.appointmentsPerWeek))
                LabeledContent("Busiest Day", value: report.wellness.busiestWeekday)
                LabeledContent("Profit Margin", value: String(format: "%.1f%%", report.wellness.profitMargin))
                LabeledContent("Expense Ratio", value: String(format: "%.1f%%", report.wellness.expenseRatio))
                LabeledContent("Kit Restock", value: report.wellness.kitRestockSpend.currencyFormatted())
                LabeledContent("Avg Travel", value: String(format: "%.1f km", report.wellness.averageTravelKm))
            }
        }
    }
}
