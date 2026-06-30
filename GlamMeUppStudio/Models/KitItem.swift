import Foundation
import SwiftData

@Model
final class KitItem {
    var id: UUID
    var name: String
    var brand: String
    var categoryRaw: String
    var shade: String
    var quantity: Int
    var lowStockThreshold: Int
    var purchasePrice: Double
    var openedAt: Date?
    var periodAfterOpeningMonths: Int
    var expiresAt: Date?
    var statusRaw: String
    var notes: String
    var createdAt: Date

    var category: ProductCategory {
        get { ProductCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: KitItemStatus {
        get { KitItemStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < .now
    }

    var isLowStock: Bool {
        quantity <= lowStockThreshold
    }

    init(
        name: String = "",
        brand: String = "",
        category: ProductCategory = .other,
        shade: String = "",
        quantity: Int = 1,
        lowStockThreshold: Int = 1,
        purchasePrice: Double = 0,
        openedAt: Date? = nil,
        periodAfterOpeningMonths: Int = 6,
        expiresAt: Date? = nil,
        status: KitItemStatus = .active,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.categoryRaw = category.rawValue
        self.shade = shade
        self.quantity = quantity
        self.lowStockThreshold = lowStockThreshold
        self.purchasePrice = purchasePrice
        self.openedAt = openedAt
        self.periodAfterOpeningMonths = periodAfterOpeningMonths
        self.expiresAt = expiresAt
        self.statusRaw = status.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }

    func markOpened(on date: Date = .now) {
        openedAt = date
        if periodAfterOpeningMonths > 0 {
            expiresAt = Calendar.current.date(byAdding: .month, value: periodAfterOpeningMonths, to: date)
        }
        refreshStatus()
    }

    func refreshStatus() {
        if isExpired {
            status = .expired
        } else if isLowStock {
            status = .lowStock
        } else {
            status = .active
        }
    }
}
