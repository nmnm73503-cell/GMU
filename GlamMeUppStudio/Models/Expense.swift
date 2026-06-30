import Foundation
import SwiftData

@Model
final class Expense {
    var id: UUID
    var title: String
    var categoryRaw: String
    var amount: Double
    var expenseDescription: String
    var vendor: String
    var isRecurring: Bool
    var isKitAmortized: Bool
    var amortizationMonths: Int
    var expenseDate: Date
    var createdAt: Date

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        title: String = "",
        category: ExpenseCategory = .other,
        amount: Double = 0,
        expenseDescription: String = "",
        vendor: String = "",
        isRecurring: Bool = false,
        isKitAmortized: Bool = false,
        amortizationMonths: Int = 12,
        expenseDate: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.amount = amount
        self.expenseDescription = expenseDescription
        self.vendor = vendor
        self.isRecurring = isRecurring
        self.isKitAmortized = isKitAmortized
        self.amortizationMonths = amortizationMonths
        self.expenseDate = expenseDate
        self.createdAt = createdAt
    }
}
