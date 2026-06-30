import Foundation
import SwiftData

@Model
final class Appointment {
    var id: UUID
    var title: String
    var appointmentTypeRaw: String
    var statusRaw: String
    var startDate: Date
    var endDate: Date
    var isMultiDay: Bool
    var venueName: String
    var venueAddress: String
    var venueLatitude: Double
    var venueLongitude: Double
    var travelDistanceKm: Double
    var travelFee: Double
    var baseRate: Double
    var taxRate: Double
    var taxAmount: Double
    var totalAmount: Double
    var depositRequired: Double
    var depositPaid: Double
    var balanceDue: Double
    var cancellationFeeApplied: Double
    var cardVaultConfirmed: Bool
    var notes: String
    var seasonTag: String
    var humidityLevel: String
    var serviceStyleRaw: String
    var headcountTierRaw: String
    var leadSourceRaw: String
    var durationHours: Double
    var manualTransportCost: Double
    var serviceLogStatus: String
    var createdAt: Date
    var updatedAt: Date

    var customer: CustomerProfile?
    var houseVisitGroup: HouseVisitGroup?
    var serviceCatalogItem: ServiceCatalogItem?

    @Relationship(deleteRule: .cascade, inverse: \AppointmentAddOn.appointment)
    var addOns: [AppointmentAddOn]

    @Relationship(deleteRule: .cascade, inverse: \PaymentRecord.appointment)
    var payments: [PaymentRecord]

    @Relationship(deleteRule: .cascade, inverse: \FaceChart.appointment)
    var faceCharts: [FaceChart]

    @Relationship(deleteRule: .cascade, inverse: \MediaAsset.appointment)
    var mediaAssets: [MediaAsset]

    @Relationship(deleteRule: .nullify, inverse: \Receipt.appointment)
    var receipts: [Receipt]

    @Relationship(deleteRule: .nullify, inverse: \BridalPartyMember.appointment)
    var bridalMembers: [BridalPartyMember]

    var appointmentType: AppointmentType {
        get { AppointmentType(rawValue: appointmentTypeRaw) ?? .other }
        set { appointmentTypeRaw = newValue.rawValue }
    }

    var status: AppointmentStatus {
        get { AppointmentStatus(rawValue: statusRaw) ?? .inquiry }
        set { statusRaw = newValue.rawValue }
    }

    var serviceStyle: MakeupServiceStyle {
        get { MakeupServiceStyle(rawValue: serviceStyleRaw) ?? .soft }
        set { serviceStyleRaw = newValue.rawValue }
    }

    var headcountTier: HeadcountTier {
        get { HeadcountTier(rawValue: headcountTierRaw) ?? .oneToTwo }
        set { headcountTierRaw = newValue.rawValue }
    }

    var leadSource: LeadSource {
        get { LeadSource(rawValue: leadSourceRaw) ?? .referral }
        set { leadSourceRaw = newValue.rawValue }
    }

    var serviceLabel: String {
        "\(serviceStyle.displayName) (\(headcountTier.displayName))"
    }

    init(
        title: String = "",
        appointmentType: AppointmentType = .event,
        status: AppointmentStatus = .inquiry,
        startDate: Date = .now,
        endDate: Date = .now.addingTimeInterval(3600 * 2),
        isMultiDay: Bool = false,
        venueName: String = "",
        venueAddress: String = "",
        venueLatitude: Double = 0,
        venueLongitude: Double = 0,
        travelDistanceKm: Double = 0,
        travelFee: Double = 0,
        baseRate: Double = 0,
        taxRate: Double = 0,
        taxAmount: Double = 0,
        totalAmount: Double = 0,
        depositRequired: Double = 0,
        depositPaid: Double = 0,
        balanceDue: Double = 0,
        cancellationFeeApplied: Double = 0,
        cardVaultConfirmed: Bool = false,
        notes: String = "",
        seasonTag: String = "",
        humidityLevel: String = "",
        serviceStyle: MakeupServiceStyle = .soft,
        headcountTier: HeadcountTier = .oneToTwo,
        leadSource: LeadSource = .referral,
        durationHours: Double = 1,
        manualTransportCost: Double = 0,
        serviceLogStatus: String = "completed",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        addOns: [AppointmentAddOn] = [],
        payments: [PaymentRecord] = [],
        faceCharts: [FaceChart] = [],
        mediaAssets: [MediaAsset] = [],
        receipts: [Receipt] = [],
        bridalMembers: [BridalPartyMember] = []
    ) {
        self.id = UUID()
        self.title = title
        self.appointmentTypeRaw = appointmentType.rawValue
        self.statusRaw = status.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.isMultiDay = isMultiDay
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.venueLatitude = venueLatitude
        self.venueLongitude = venueLongitude
        self.travelDistanceKm = travelDistanceKm
        self.travelFee = travelFee
        self.baseRate = baseRate
        self.taxRate = taxRate
        self.taxAmount = taxAmount
        self.totalAmount = totalAmount
        self.depositRequired = depositRequired
        self.depositPaid = depositPaid
        self.balanceDue = balanceDue
        self.cancellationFeeApplied = cancellationFeeApplied
        self.cardVaultConfirmed = cardVaultConfirmed
        self.notes = notes
        self.seasonTag = seasonTag
        self.humidityLevel = humidityLevel
        self.serviceStyleRaw = serviceStyle.rawValue
        self.headcountTierRaw = headcountTier.rawValue
        self.leadSourceRaw = leadSource.rawValue
        self.durationHours = durationHours
        self.manualTransportCost = manualTransportCost
        self.serviceLogStatus = serviceLogStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.addOns = addOns
        self.payments = payments
        self.faceCharts = faceCharts
        self.mediaAssets = mediaAssets
        self.receipts = receipts
        self.bridalMembers = bridalMembers
    }

    func recalculateTotals() {
        let addOnTotal = addOns.reduce(0) { $0 + $1.price }
        let transport = manualTransportCost > 0 ? manualTransportCost : travelFee
        let subtotal = baseRate + addOnTotal + transport
        taxAmount = subtotal * (taxRate / 100)
        totalAmount = subtotal + taxAmount
        balanceDue = max(0, totalAmount - depositPaid)
    }

    var effectiveTransportCost: Double {
        manualTransportCost > 0 ? manualTransportCost : travelFee
    }

    var netRevenue: Double {
        baseRate - effectiveTransportCost
    }
}

@Model
final class AppointmentAddOn {
    var id: UUID
    var name: String
    var price: Double
    var durationMinutes: Int

    var appointment: Appointment?

    init(name: String, price: Double, durationMinutes: Int = 30) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.durationMinutes = durationMinutes
    }
}

@Model
final class PaymentRecord {
    var id: UUID
    var amount: Double
    var paymentTypeRaw: String
    var paymentMethodRaw: String
    var transactionReference: String
    var cardLastFour: String
    var paidAt: Date
    var notes: String

    var appointment: Appointment?
    var bridalContract: BridalContract?

    var paymentType: PaymentType {
        get { PaymentType(rawValue: paymentTypeRaw) ?? .partial }
        set { paymentTypeRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    init(
        amount: Double,
        paymentType: PaymentType = .partial,
        paymentMethod: PaymentMethod = .cash,
        transactionReference: String = "",
        cardLastFour: String = "",
        paidAt: Date = .now,
        notes: String = ""
    ) {
        self.id = UUID()
        self.amount = amount
        self.paymentTypeRaw = paymentType.rawValue
        self.paymentMethodRaw = paymentMethod.rawValue
        self.transactionReference = transactionReference
        self.cardLastFour = cardLastFour
        self.paidAt = paidAt
        self.notes = notes
    }
}
