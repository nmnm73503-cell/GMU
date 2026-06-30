import Foundation
import SwiftData

struct KitAlert: Identifiable {
    let id = UUID()
    let item: KitItem
    let message: String
    let severity: Severity

    enum Severity { case warning, critical }
}

enum KitInventoryService {
    static func alerts(for items: [KitItem]) -> [KitAlert] {
        var alerts: [KitAlert] = []
        for item in items {
            item.refreshStatus()
            if item.isExpired {
                alerts.append(KitAlert(item: item, message: "\(item.name) has expired — dispose before use.", severity: .critical))
            } else if let expiresAt = item.expiresAt {
                let days = Calendar.current.dateComponents([.day], from: .now, to: expiresAt).day ?? 0
                if days <= 14 && days >= 0 {
                    alerts.append(KitAlert(item: item, message: "\(item.name) expires in \(days) days (PAO).", severity: .warning))
                }
            }
            if item.isLowStock {
                alerts.append(KitAlert(item: item, message: "\(item.name) is low stock (\(item.quantity) left).", severity: .warning))
            }
        }
        return alerts.sorted { $0.severity == .critical && $1.severity != .critical }
    }
}
