import Foundation
import SwiftData

struct ServiceLogAnalytics {
    var totalRevenue: Double
    var totalExpenses: Double
    var netProfit: Double
    var totalHoursWorked: Double
    var hourlyRate: Double
    var totalCustomers: Int
    var totalHouses: Int
    var averagePeoplePerHouse: Double
    var averageProfitPerService: Double
    var averageRevenuePerHouse: Double
    var totalTransportCosts: Double
    var topClientName: String
    var bestSellerService: String
    var customerRetentionRate: Double
    var revenueConcentrationTopClient: Double
}

enum ServiceLogAnalyticsService {
    static func monthlyAnalytics(
        appointments: [Appointment],
        expenses: [Expense],
        houseGroups: [HouseVisitGroup],
        month: Date
    ) -> ServiceLogAnalytics {
        let calendar = Calendar.current
        let monthAppointments = appointments.filter {
            calendar.isDate($0.startDate, equalTo: month, toGranularity: .month) &&
            $0.status != .cancelled &&
            $0.serviceStyle != .cancelled
        }
        let monthExpenses = expenses.filter {
            calendar.isDate($0.expenseDate, equalTo: month, toGranularity: .month)
        }

        let revenue = monthAppointments.reduce(0) { $0 + $1.baseRate }
        let transport = monthAppointments.reduce(0) { $0 + $1.effectiveTransportCost }
        let expenseTotal = monthExpenses.reduce(0) { $0 + $1.amount }
        let hours = monthAppointments.reduce(0) { $0 + $1.durationHours }
        let net = revenue - transport - expenseTotal

        let customers = Set(monthAppointments.compactMap { $0.customer?.id })
        let houses = houseGroups.filter {
            calendar.isDate($0.visitDate, equalTo: month, toGranularity: .month)
        }

        var clientRevenue: [String: Double] = [:]
        for appt in monthAppointments {
            let name = appt.customer?.fullName ?? appt.title
            clientRevenue[name, default: 0] += appt.baseRate
        }
        let topClient = clientRevenue.max(by: { $0.value < $1.value })

        var serviceCounts: [String: Int] = [:]
        for appt in monthAppointments {
            serviceCounts[appt.serviceLabel, default: 0] += 1
        }
        let bestSeller = serviceCounts.max(by: { $0.value < $1.value })

        let repeatClients = monthAppointments.compactMap { $0.customer }.filter { $0.totalAppointments > 1 }.count
        let retention = customers.isEmpty ? 0 : Double(repeatClients) / Double(customers.count) * 100
        let concentration = revenue > 0 ? ((topClient?.value ?? 0) / revenue) * 100 : 0

        return ServiceLogAnalytics(
            totalRevenue: revenue,
            totalExpenses: expenseTotal + transport,
            netProfit: net,
            totalHoursWorked: hours,
            hourlyRate: hours > 0 ? net / hours : 0,
            totalCustomers: customers.count,
            totalHouses: houses.isEmpty ? Set(monthAppointments.map { $0.startDate.startOfDay }).count : houses.count,
            averagePeoplePerHouse: houses.isEmpty ? (customers.count > 0 ? Double(monthAppointments.count) / Double(max(1, Set(monthAppointments.map { $0.startDate.startOfDay }).count)) : 0) : (houses.isEmpty ? 0 : Double(monthAppointments.count) / Double(houses.count)),
            averageProfitPerService: monthAppointments.isEmpty ? 0 : net / Double(monthAppointments.count),
            averageRevenuePerHouse: houses.isEmpty ? revenue : revenue / Double(max(1, houses.count)),
            totalTransportCosts: transport,
            topClientName: topClient?.key ?? "—",
            bestSellerService: bestSeller?.key ?? "—",
            customerRetentionRate: retention,
            revenueConcentrationTopClient: concentration
        )
    }

    static func dailySummary(
        appointments: [Appointment],
        expenses: [Expense],
        date: Date
    ) -> DailyFinancialSummary {
        let day = date.startOfDay
        let dayAppointments = appointments.filter {
            Calendar.current.isDate($0.startDate, inSameDayAs: day) &&
            $0.serviceStyle != .cancelled
        }
        let dayExpenses = expenses.filter { Calendar.current.isDate($0.expenseDate, inSameDayAs: day) }

        let earned = dayAppointments.reduce(0) { $0 + $1.baseRate }
        let transport = dayAppointments.reduce(0) { $0 + $1.effectiveTransportCost }
        let expenseTotal = dayExpenses.reduce(0) { $0 + $1.amount }

        return DailyFinancialSummary(
            summaryDate: day,
            totalEarned: earned,
            totalExpenses: expenseTotal + transport,
            netProfit: earned - transport - expenseTotal,
            totalTransportCosts: transport,
            totalHoursWorked: dayAppointments.reduce(0) { $0 + $1.durationHours },
            serviceCount: dayAppointments.count,
            customerCount: Set(dayAppointments.compactMap { $0.customer?.id }).count,
            houseCount: Set(dayAppointments.map { $0.houseVisitGroup?.id.uuidString ?? $0.venueAddress }).count
        )
    }
}
