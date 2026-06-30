import Foundation
import SwiftData

enum CustomerProfileService {
    static func refreshMetrics(for customer: CustomerProfile, context: ModelContext) {
        let completed = customer.appointments.filter { $0.status == .completed }
        customer.totalAppointments = completed.count
        customer.lifetimeValue = completed.reduce(0) { $0 + $1.baseRate }
        customer.updatedAt = .now
        try? context.save()
    }

    static func addTimelineEntry(
        customer: CustomerProfile,
        type: TimelineEventType,
        title: String,
        detail: String = "",
        amount: Double = 0,
        context: ModelContext
    ) {
        let entry = TimelineEntry(eventType: type, title: title, detail: detail, amount: amount)
        entry.customer = customer
        customer.timelineEntries.append(entry)
        context.insert(entry)
        try? context.save()
    }

    static func logFormulaChange(
        customer: CustomerProfile,
        appointment: Appointment?,
        previous: String,
        newFormula: String,
        reason: String,
        products: String,
        context: ModelContext
    ) {
        let log = FormulaChangeLog(
            previousFormula: previous,
            newFormula: newFormula,
            reason: reason,
            productsUsed: products
        )
        log.customer = customer
        log.appointment = appointment
        customer.formulaLogs.append(log)
        context.insert(log)
        addTimelineEntry(
            customer: customer,
            type: .formulaChange,
            title: "Formula updated",
            detail: newFormula,
            context: context
        )
    }
}
