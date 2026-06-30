import Foundation
import SwiftData

enum IncomeAllocationService {
    static func createEntry(
        for date: Date,
        totalEarned: Double,
        expensesDeducted: Double,
        drawings: Double,
        config: StudioConfiguration,
        context: ModelContext
    ) -> IncomeAllocationEntry {
        let entry = IncomeAllocationEntry(
            allocationDate: date.startOfDay,
            totalEarned: totalEarned,
            savingsPercentage: config.savingsAllocationPercent,
            businessPercentage: config.businessAllocationPercent,
            personalPercentage: config.personalAllocationPercent,
            drawings: drawings,
            expensesDeducted: expensesDeducted
        )
        context.insert(entry)
        return entry
    }

    static func runningBalances(entries: [IncomeAllocationEntry]) -> (savings: Double, business: Double, personal: Double) {
        entries.reduce((0.0, 0.0, 0.0)) { result, entry in
            (
                result.0 + entry.savingsAmount,
                result.1 + entry.businessAmount,
                result.2 + entry.personalAmount
            )
        }
    }
}
