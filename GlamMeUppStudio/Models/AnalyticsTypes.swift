import Foundation

enum AnalyticsPeriod: String, CaseIterable, Identifiable {
    case week, month, halfYear, year, custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return "Weekly"
        case .month: return "Monthly"
        case .halfYear: return "6 Months"
        case .year: return "Yearly"
        case .custom: return "Custom"
        }
    }

    func dateRange(customStart: Date, customEnd: Date, reference: Date = .now) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        switch self {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: reference.startOfDay) ?? reference
            return (start, reference)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: reference) ?? reference
            return (start.startOfDay, reference)
        case .halfYear:
            let start = calendar.date(byAdding: .month, value: -6, to: reference) ?? reference
            return (start.startOfDay, reference)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: reference) ?? reference
            return (start.startOfDay, reference)
        case .custom:
            return (customStart.startOfDay, customEnd)
        }
    }
}

struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Double
    let label: String
}

struct ServiceBreakdownItem: Identifiable {
    let id = UUID()
    let name: String
    let amount: Double
    let count: Int
}

struct PaymentBreakdown {
    var deposits: Double
    var finalPayments: Double
    var cancellationFees: Double
    var partialPayments: Double
}

struct ClientGrowthPoint: Identifiable {
    let id = UUID()
    let date: Date
    let newClients: Int
    let returningClients: Int
}

struct LTVBucket: Identifiable {
    let id = UUID()
    let rangeLabel: String
    let count: Int
}

struct FrequentClient: Identifiable {
    let id = UUID()
    let name: String
    let visits: Int
    let revenue: Double
}

struct LeadSourceStat: Identifiable {
    let id = UUID()
    let source: String
    let count: Int
    let revenue: Double
}

struct WellnessMetrics {
    var appointmentsPerWeek: Double
    var busiestWeekday: String
    var averageTravelKm: Double
    var totalTravelKm: Double
    var profitMargin: Double
    var expenseRatio: Double
    var kitRestockSpend: Double
    var incomeTotal: Double
    var expenseTotal: Double
}

struct AnalyticsReport {
    let period: AnalyticsPeriod
    let startDate: Date
    let endDate: Date
    let revenueOverTime: [RevenueDataPoint]
    let serviceBreakdown: [ServiceBreakdownItem]
    let paymentBreakdown: PaymentBreakdown
    let averageBookingValue: Double
    let topRevenueMonth: String
    let topRevenueMonthAmount: Double
    let clientGrowth: [ClientGrowthPoint]
    let newClientCount: Int
    let returningClientCount: Int
    let ltvDistribution: [LTVBucket]
    let frequentClients: [FrequentClient]
    let leadSources: [LeadSourceStat]
    let wellness: WellnessMetrics
    let totalRevenue: Double
    let totalAppointments: Int
}
