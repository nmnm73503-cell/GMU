import Foundation
import SwiftData

@Model
final class ServiceCatalogItem {
    var id: UUID
    var serviceStyleRaw: String
    var headcountTierRaw: String
    var displayName: String
    var basePrice: Double
    var defaultDurationHours: Double
    var isActive: Bool
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \Appointment.serviceCatalogItem)
    var appointments: [Appointment]

    var serviceStyle: MakeupServiceStyle {
        get { MakeupServiceStyle(rawValue: serviceStyleRaw) ?? .soft }
        set { serviceStyleRaw = newValue.rawValue }
    }

    var headcountTier: HeadcountTier {
        get { HeadcountTier(rawValue: headcountTierRaw) ?? .oneToTwo }
        set { headcountTierRaw = newValue.rawValue }
    }

    init(
        serviceStyle: MakeupServiceStyle,
        headcountTier: HeadcountTier,
        basePrice: Double,
        defaultDurationHours: Double = 1,
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.serviceStyleRaw = serviceStyle.rawValue
        self.headcountTierRaw = headcountTier.rawValue
        self.displayName = "\(serviceStyle.displayName) (\(headcountTier.displayName))"
        self.basePrice = basePrice
        self.defaultDurationHours = defaultDurationHours
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.appointments = []
    }
}

@Model
final class HouseVisitGroup {
    var id: UUID
    var houseLabel: String
    var visitDate: Date
    var venueAddress: String
    var venueLatitude: Double
    var venueLongitude: Double
    var sharedTransportCost: Double
    var notes: String

    @Relationship(deleteRule: .nullify, inverse: \Appointment.houseVisitGroup)
    var appointments: [Appointment]

    var clientCount: Int { appointments.count }
    var totalRevenue: Double { appointments.reduce(0) { $0 + $1.baseRate } }
    var averagePeoplePerHouse: Double {
        guard !appointments.isEmpty else { return 0 }
        return Double(appointments.count)
    }

    init(
        houseLabel: String = "",
        visitDate: Date = .now,
        venueAddress: String = "",
        venueLatitude: Double = 0,
        venueLongitude: Double = 0,
        sharedTransportCost: Double = 0,
        notes: String = "",
        appointments: [Appointment] = []
    ) {
        self.id = UUID()
        self.houseLabel = houseLabel
        self.visitDate = visitDate
        self.venueAddress = venueAddress
        self.venueLatitude = venueLatitude
        self.venueLongitude = venueLongitude
        self.sharedTransportCost = sharedTransportCost
        self.notes = notes
        self.appointments = appointments
    }
}

@Model
final class DailyFinancialSummary {
    var id: UUID
    var summaryDate: Date
    var totalEarned: Double
    var totalExpenses: Double
    var netProfit: Double
    var totalTransportCosts: Double
    var totalHoursWorked: Double
    var serviceCount: Int
    var customerCount: Int
    var houseCount: Int

    init(
        summaryDate: Date = .now,
        totalEarned: Double = 0,
        totalExpenses: Double = 0,
        netProfit: Double = 0,
        totalTransportCosts: Double = 0,
        totalHoursWorked: Double = 0,
        serviceCount: Int = 0,
        customerCount: Int = 0,
        houseCount: Int = 0
    ) {
        self.id = UUID()
        self.summaryDate = summaryDate
        self.totalEarned = totalEarned
        self.totalExpenses = totalExpenses
        self.netProfit = netProfit
        self.totalTransportCosts = totalTransportCosts
        self.totalHoursWorked = totalHoursWorked
        self.serviceCount = serviceCount
        self.customerCount = customerCount
        self.houseCount = houseCount
    }
}

@Model
final class IncomeAllocationEntry {
    var id: UUID
    var allocationDate: Date
    var totalEarned: Double
    var savingsAmount: Double
    var businessAmount: Double
    var personalAmount: Double
    var drawings: Double
    var expensesDeducted: Double
    var savingsPercentage: Double
    var businessPercentage: Double
    var personalPercentage: Double

    init(
        allocationDate: Date = .now,
        totalEarned: Double = 0,
        savingsPercentage: Double = 33,
        businessPercentage: Double = 33,
        personalPercentage: Double = 34,
        drawings: Double = 0,
        expensesDeducted: Double = 0
    ) {
        self.id = UUID()
        self.allocationDate = allocationDate
        self.totalEarned = totalEarned
        self.savingsPercentage = savingsPercentage
        self.businessPercentage = businessPercentage
        self.personalPercentage = personalPercentage
        self.drawings = drawings
        self.expensesDeducted = expensesDeducted
        let pool = max(0, totalEarned - expensesDeducted)
        self.savingsAmount = pool * (savingsPercentage / 100)
        self.businessAmount = pool * (businessPercentage / 100)
        self.personalAmount = pool * (personalPercentage / 100) - drawings
    }

    func recalculate() {
        let pool = max(0, totalEarned - expensesDeducted)
        savingsAmount = pool * (savingsPercentage / 100)
        businessAmount = pool * (businessPercentage / 100)
        personalAmount = pool * (personalPercentage / 100) - drawings
    }
}
