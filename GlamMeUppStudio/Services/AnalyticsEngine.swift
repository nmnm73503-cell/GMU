import Foundation
import SwiftData

enum AnalyticsEngine {
    static func generateReport(
        period: AnalyticsPeriod,
        customStart: Date,
        customEnd: Date,
        appointments: [Appointment],
        clients: [CustomerProfile],
        expenses: [Expense],
        payments: [PaymentRecord],
        reference: Date = .now
    ) -> AnalyticsReport {
        let range = period.dateRange(customStart: customStart, customEnd: customEnd, reference: reference)
        let filtered = appointments.filter {
            $0.startDate >= range.start && $0.startDate <= range.end &&
            $0.status != .cancelled && $0.serviceStyle != .cancelled
        }
        let filteredExpenses = expenses.filter { $0.expenseDate >= range.start && $0.expenseDate <= range.end }
        let filteredPayments = payments.filter { $0.paidAt >= range.start && $0.paidAt <= range.end }

        let revenueOverTime = bucketRevenue(filtered, start: range.start, end: range.end, period: period)
        let serviceBreakdown = breakdownByService(filtered)
        let paymentBreakdown = breakdownPayments(filteredPayments)
        let totalRevenue = filtered.reduce(0) { $0 + $1.baseRate }
        let avgBooking = filtered.isEmpty ? 0 : totalRevenue / Double(filtered.count)

        let monthBuckets = Dictionary(grouping: filtered) { appt -> String in
            let f = DateFormatter()
            f.dateFormat = "MMMM yyyy"
            return f.string(from: appt.startDate)
        }
        let topMonth = monthBuckets.max { a, b in
            a.value.reduce(0) { $0 + $1.baseRate } < b.value.reduce(0) { $0 + $1.baseRate }
        }

        let clientGrowth = clientGrowthSeries(clients: clients, appointments: filtered, start: range.start, end: range.end)
        let newCount = clientGrowth.reduce(0) { $0 + $1.newClients }
        let returnCount = clientGrowth.reduce(0) { $0 + $1.returningClients }

        return AnalyticsReport(
            period: period,
            startDate: range.start,
            endDate: range.end,
            revenueOverTime: revenueOverTime,
            serviceBreakdown: serviceBreakdown,
            paymentBreakdown: paymentBreakdown,
            averageBookingValue: avgBooking,
            topRevenueMonth: topMonth?.key ?? "—",
            topRevenueMonthAmount: topMonth?.value.reduce(0) { $0 + $1.baseRate } ?? 0,
            clientGrowth: clientGrowth,
            newClientCount: newCount,
            returningClientCount: returnCount,
            ltvDistribution: ltvBuckets(clients: clients),
            frequentClients: frequentClients(from: filtered),
            leadSources: leadSourceStats(filtered),
            wellness: wellnessMetrics(appointments: filtered, expenses: filteredExpenses),
            totalRevenue: totalRevenue,
            totalAppointments: filtered.count
        )
    }

    private static func bucketRevenue(
        _ appointments: [Appointment],
        start: Date,
        end: Date,
        period: AnalyticsPeriod
    ) -> [RevenueDataPoint] {
        let calendar = Calendar.current
        let component: Calendar.Component
        let step: Int
        switch period {
        case .week: component = .day; step = 1
        case .month: component = .day; step = 1
        case .halfYear: component = .weekOfYear; step = 1
        case .year: component = .month; step = 1
        case .custom:
            let days = calendar.dateComponents([.day], from: start, to: end).day ?? 30
            component = days > 60 ? .month : .day
            step = 1
        }

        var points: [RevenueDataPoint] = []
        var cursor = start.startOfDay
        while cursor <= end {
            let next: Date
            if component == .day {
                next = calendar.date(byAdding: .day, value: step, to: cursor) ?? end
            } else if component == .weekOfYear {
                next = calendar.date(byAdding: .weekOfYear, value: step, to: cursor) ?? end
            } else {
                next = calendar.date(byAdding: .month, value: step, to: cursor) ?? end
            }
            let amount = appointments.filter { $0.startDate >= cursor && $0.startDate < next }
                .reduce(0) { $0 + $1.baseRate }
            let label: String
            if component == .month {
                let f = DateFormatter(); f.dateFormat = "MMM"; label = f.string(from: cursor)
            } else {
                let f = DateFormatter(); f.dateFormat = "d MMM"; label = f.string(from: cursor)
            }
            points.append(RevenueDataPoint(date: cursor, amount: amount, label: label))
            cursor = next
        }
        return points
    }

    private static func breakdownByService(_ appointments: [Appointment]) -> [ServiceBreakdownItem] {
        var map: [String: (amount: Double, count: Int)] = [:]
        for appt in appointments {
            let key = appt.serviceLabel
            var entry = map[key] ?? (0, 0)
            entry.amount += appt.baseRate
            entry.count += 1
            map[key] = entry
        }
        return map.map { ServiceBreakdownItem(name: $0.key, amount: $0.value.amount, count: $0.value.count) }
            .sorted { $0.amount > $1.amount }
    }

    private static func breakdownPayments(_ payments: [PaymentRecord]) -> PaymentBreakdown {
        var result = PaymentBreakdown(deposits: 0, finalPayments: 0, cancellationFees: 0, partialPayments: 0)
        for p in payments {
            switch p.paymentType {
            case .deposit: result.deposits += p.amount
            case .final: result.finalPayments += p.amount
            case .cancellationFee: result.cancellationFees += p.amount
            case .partial: result.partialPayments += p.amount
            case .refund: break
            }
        }
        return result
    }

    private static func clientGrowthSeries(
        clients: [CustomerProfile],
        appointments: [Appointment],
        start: Date,
        end: Date
    ) -> [ClientGrowthPoint] {
        let calendar = Calendar.current
        var cursor = start.startOfMonth
        var points: [ClientGrowthPoint] = []
        while cursor <= end {
            let next = calendar.date(byAdding: .month, value: 1, to: cursor) ?? end
            let monthAppts = appointments.filter { $0.startDate >= cursor && $0.startDate < next }
            var newClients = 0
            var returning = 0
            let seen = Set(monthAppts.compactMap { $0.customer?.id })
            for id in seen {
                guard let client = clients.first(where: { $0.id == id }) else { continue }
                let firstAppt = client.appointments.min(by: { $0.startDate < $1.startDate })
                if let first = firstAppt, first.startDate >= cursor && first.startDate < next {
                    newClients += 1
                } else {
                    returning += 1
                }
            }
            points.append(ClientGrowthPoint(date: cursor, newClients: newClients, returningClients: returning))
            cursor = next
        }
        return points
    }

    private static func ltvBuckets(clients: [CustomerProfile]) -> [LTVBucket] {
        let ranges = [(0, 100_000, "0–100K"), (100_000, 300_000, "100–300K"), (300_000, 600_000, "300–600K"), (600_000, Int.max, "600K+")]
        return ranges.map { low, high, label in
            let count = clients.filter { $0.lifetimeValue >= Double(low) && $0.lifetimeValue < Double(high) }.count
            return LTVBucket(rangeLabel: label, count: count)
        }
    }

    private static func frequentClients(from appointments: [Appointment]) -> [FrequentClient] {
        var map: [String: (visits: Int, revenue: Double)] = [:]
        for appt in appointments {
            let name = appt.customer?.fullName ?? appt.title
            var e = map[name] ?? (0, 0)
            e.visits += 1
            e.revenue += appt.baseRate
            map[name] = e
        }
        return map.map { FrequentClient(name: $0.key, visits: $0.value.visits, revenue: $0.value.revenue) }
            .sorted { $0.visits > $1.visits }
            .prefix(10)
            .map { $0 }
    }

    private static func leadSourceStats(_ appointments: [Appointment]) -> [LeadSourceStat] {
        var map: [String: (count: Int, revenue: Double)] = [:]
        for appt in appointments {
            let key = appt.leadSource.displayName
            var e = map[key] ?? (0, 0)
            e.count += 1
            e.revenue += appt.baseRate
            map[key] = e
        }
        return map.map { LeadSourceStat(source: $0.key, count: $0.value.count, revenue: $0.value.revenue) }
            .sorted { $0.revenue > $1.revenue }
    }

    private static func wellnessMetrics(appointments: [Appointment], expenses: [Expense]) -> WellnessMetrics {
        let income = appointments.reduce(0) { $0 + $1.baseRate }
        let expenseTotal = expenses.reduce(0) { $0 + $1.amount }
        let transport = appointments.reduce(0) { $0 + $1.effectiveTransportCost }
        let kitSpend = expenses.filter { $0.category == .productRestock }.reduce(0) { $0 + $1.amount }
        let km = appointments.reduce(0) { $0 + $1.travelDistanceKm }
        let weeks = max(1, Double(Calendar.current.dateComponents([.weekOfYear], from: appointments.first?.startDate ?? .now, to: .now).weekOfYear ?? 1))

        var weekdayCounts: [Int: Int] = [:]
        for appt in appointments {
            let wd = Calendar.current.component(.weekday, from: appt.startDate)
            weekdayCounts[wd, default: 0] += 1
        }
        let busiest = weekdayCounts.max(by: { $0.value < $1.value })?.key ?? 1
        let weekdaySymbols = Calendar.current.weekdaySymbols

        return WellnessMetrics(
            appointmentsPerWeek: Double(appointments.count) / weeks,
            busiestWeekday: weekdaySymbols[busiest - 1],
            averageTravelKm: appointments.isEmpty ? 0 : km / Double(appointments.count),
            totalTravelKm: km,
            profitMargin: income > 0 ? ((income - expenseTotal - transport) / income) * 100 : 0,
            expenseRatio: income > 0 ? (expenseTotal / income) * 100 : 0,
            kitRestockSpend: kitSpend,
            incomeTotal: income,
            expenseTotal: expenseTotal + transport
        )
    }
}
