import Foundation
import SwiftData

@Model
final class BridalContract {
    var id: UUID
    var eventName: String
    var weddingDate: Date
    var venueName: String
    var venueAddress: String
    var masterContractTotal: Double
    var depositCollected: Double
    var balanceDue: Double
    var notes: String
    var createdAt: Date

    var brideCustomer: CustomerProfile?

    @Relationship(deleteRule: .cascade, inverse: \BridalPartyMember.contract)
    var partyMembers: [BridalPartyMember]

    @Relationship(deleteRule: .cascade, inverse: \PaymentRecord.bridalContract)
    var payments: [PaymentRecord]

    init(
        eventName: String = "",
        weddingDate: Date = .now,
        venueName: String = "",
        venueAddress: String = "",
        masterContractTotal: Double = 0,
        depositCollected: Double = 0,
        balanceDue: Double = 0,
        notes: String = "",
        createdAt: Date = .now,
        partyMembers: [BridalPartyMember] = [],
        payments: [PaymentRecord] = []
    ) {
        self.id = UUID()
        self.eventName = eventName
        self.weddingDate = weddingDate
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.masterContractTotal = masterContractTotal
        self.depositCollected = depositCollected
        self.balanceDue = balanceDue
        self.notes = notes
        self.createdAt = createdAt
        self.partyMembers = partyMembers
        self.payments = payments
    }

    func recalculateBalance() {
        let paid = payments.reduce(0) { $0 + $1.amount }
        depositCollected = paid
        balanceDue = max(0, masterContractTotal - paid)
    }
}

@Model
final class BridalPartyMember {
    var id: UUID
    var displayName: String
    var roleRaw: String
    var lookPreference: String
    var serviceRate: Double
    var isPaid: Bool
    var notes: String

    var contract: BridalContract?
    var linkedCustomer: CustomerProfile?
    var appointment: Appointment?

    var role: BridalPartyRole {
        get { BridalPartyRole(rawValue: roleRaw) ?? .other }
        set { roleRaw = newValue.rawValue }
    }

    init(
        displayName: String = "",
        role: BridalPartyRole = .bridesmaid,
        lookPreference: String = "",
        serviceRate: Double = 0,
        isPaid: Bool = false,
        notes: String = ""
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.roleRaw = role.rawValue
        self.lookPreference = lookPreference
        self.serviceRate = serviceRate
        self.isPaid = isPaid
        self.notes = notes
    }
}
