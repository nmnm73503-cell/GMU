import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var receiptNumber: String
    var issuedAt: Date
    var subtotal: Double
    var travelFee: Double
    var taxRate: Double
    var taxAmount: Double
    var totalAmount: Double
    var notes: String
    var pdfData: Data?
    var clientName: String
    var clientEmail: String
    var clientPhone: String

    var appointment: Appointment?
    var customer: CustomerProfile?

    @Relationship(deleteRule: .cascade, inverse: \ReceiptLineItem.receipt)
    var lineItems: [ReceiptLineItem]

    init(
        receiptNumber: String = "",
        issuedAt: Date = .now,
        subtotal: Double = 0,
        travelFee: Double = 0,
        taxRate: Double = 0,
        taxAmount: Double = 0,
        totalAmount: Double = 0,
        notes: String = "",
        pdfData: Data? = nil,
        clientName: String = "",
        clientEmail: String = "",
        clientPhone: String = "",
        lineItems: [ReceiptLineItem] = []
    ) {
        self.id = UUID()
        self.receiptNumber = receiptNumber
        self.issuedAt = issuedAt
        self.subtotal = subtotal
        self.travelFee = travelFee
        self.taxRate = taxRate
        self.taxAmount = taxAmount
        self.totalAmount = totalAmount
        self.notes = notes
        self.pdfData = pdfData
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
        self.lineItems = lineItems
    }
}

@Model
final class ReceiptLineItem {
    var id: UUID
    var label: String
    var quantity: Int
    var unitPrice: Double
    var sortOrder: Int

    var receipt: Receipt?

    var lineTotal: Double { Double(quantity) * unitPrice }

    init(label: String, quantity: Int = 1, unitPrice: Double = 0, sortOrder: Int = 0) {
        self.id = UUID()
        self.label = label
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.sortOrder = sortOrder
    }
}
