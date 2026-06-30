import Foundation
import SwiftData

@Model
final class CustomerProfile {
    var id: UUID
    var firstName: String
    var lastName: String
    var phoneNumber: String
    var email: String
    var instagramHandle: String
    var notes: String
    var cardLastFour: String
    var cardVaultToken: String
    var lifetimeValue: Double
    var totalAppointments: Int
    var preferredContactMethod: String
    var leadSourceRaw: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \SkinProfile.customer)
    var skinProfile: SkinProfile?

    @Relationship(deleteRule: .cascade, inverse: \Appointment.customer)
    var appointments: [Appointment]

    @Relationship(deleteRule: .cascade, inverse: \FaceChart.customer)
    var faceCharts: [FaceChart]

    @Relationship(deleteRule: .cascade, inverse: \MediaAsset.customer)
    var mediaAssets: [MediaAsset]

    @Relationship(deleteRule: .cascade, inverse: \FormulaChangeLog.customer)
    var formulaLogs: [FormulaChangeLog]

    @Relationship(deleteRule: .cascade, inverse: \TimelineEntry.customer)
    var timelineEntries: [TimelineEntry]

    @Relationship(deleteRule: .nullify, inverse: \BridalPartyMember.linkedCustomer)
    var bridalMemberships: [BridalPartyMember]

    var fullName: String {
        [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var leadSource: LeadSource {
        get { LeadSource(rawValue: leadSourceRaw) ?? .referral }
        set { leadSourceRaw = newValue.rawValue }
    }

    init(
        firstName: String = "",
        lastName: String = "",
        phoneNumber: String = "",
        email: String = "",
        instagramHandle: String = "",
        notes: String = "",
        cardLastFour: String = "",
        cardVaultToken: String = "",
        lifetimeValue: Double = 0,
        totalAppointments: Int = 0,
        preferredContactMethod: String = "call",
        leadSource: LeadSource = .referral,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        skinProfile: SkinProfile? = nil,
        appointments: [Appointment] = [],
        faceCharts: [FaceChart] = [],
        mediaAssets: [MediaAsset] = [],
        formulaLogs: [FormulaChangeLog] = [],
        timelineEntries: [TimelineEntry] = [],
        bridalMemberships: [BridalPartyMember] = []
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.instagramHandle = instagramHandle
        self.notes = notes
        self.cardLastFour = cardLastFour
        self.cardVaultToken = cardVaultToken
        self.lifetimeValue = lifetimeValue
        self.totalAppointments = totalAppointments
        self.preferredContactMethod = preferredContactMethod
        self.leadSourceRaw = leadSource.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.skinProfile = skinProfile
        self.appointments = appointments
        self.faceCharts = faceCharts
        self.mediaAssets = mediaAssets
        self.formulaLogs = formulaLogs
        self.timelineEntries = timelineEntries
        self.bridalMemberships = bridalMemberships
    }
}

@Model
final class SkinProfile {
    var id: UUID
    var fitzpatrickRaw: String
    var hydrationBaselineRaw: String
    var oilinessLevel: Int
    var undertone: String
    var hypersensitivityNotes: String
    var latexAllergy: Bool
    var carmineAllergy: Bool
    var fragranceSensitivity: Bool
    var customAllergenNotes: String
    var preferredFinish: String
    var lastPatchTestDate: Date?
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \AllergenTag.skinProfile)
    var allergenTags: [AllergenTag]

    var customer: CustomerProfile?

    var fitzpatrick: FitzpatrickType {
        get { FitzpatrickType(rawValue: fitzpatrickRaw) ?? .typeIII }
        set { fitzpatrickRaw = newValue.rawValue }
    }

    var hydrationBaseline: SkinHydrationBaseline {
        get { SkinHydrationBaseline(rawValue: hydrationBaselineRaw) ?? .normal }
        set { hydrationBaselineRaw = newValue.rawValue }
    }

    init(
        fitzpatrick: FitzpatrickType = .typeIII,
        hydrationBaseline: SkinHydrationBaseline = .normal,
        oilinessLevel: Int = 3,
        undertone: String = "neutral",
        hypersensitivityNotes: String = "",
        latexAllergy: Bool = false,
        carmineAllergy: Bool = false,
        fragranceSensitivity: Bool = false,
        customAllergenNotes: String = "",
        preferredFinish: String = "natural",
        lastPatchTestDate: Date? = nil,
        updatedAt: Date = .now,
        allergenTags: [AllergenTag] = []
    ) {
        self.id = UUID()
        self.fitzpatrickRaw = fitzpatrick.rawValue
        self.hydrationBaselineRaw = hydrationBaseline.rawValue
        self.oilinessLevel = oilinessLevel
        self.undertone = undertone
        self.hypersensitivityNotes = hypersensitivityNotes
        self.latexAllergy = latexAllergy
        self.carmineAllergy = carmineAllergy
        self.fragranceSensitivity = fragranceSensitivity
        self.customAllergenNotes = customAllergenNotes
        self.preferredFinish = preferredFinish
        self.lastPatchTestDate = lastPatchTestDate
        self.updatedAt = updatedAt
        self.allergenTags = allergenTags
    }
}

@Model
final class AllergenTag {
    var id: UUID
    var name: String
    var severity: String

    var skinProfile: SkinProfile?

    init(name: String, severity: String = "moderate") {
        self.id = UUID()
        self.name = name
        self.severity = severity
    }
}

@Model
final class FormulaChangeLog {
    var id: UUID
    var previousFormula: String
    var newFormula: String
    var reason: String
    var productsUsed: String
    var recordedAt: Date

    var customer: CustomerProfile?
    var appointment: Appointment?

    init(
        previousFormula: String = "",
        newFormula: String = "",
        reason: String = "",
        productsUsed: String = "",
        recordedAt: Date = .now
    ) {
        self.id = UUID()
        self.previousFormula = previousFormula
        self.newFormula = newFormula
        self.reason = reason
        self.productsUsed = productsUsed
        self.recordedAt = recordedAt
    }
}

@Model
final class TimelineEntry {
    var id: UUID
    var eventTypeRaw: String
    var title: String
    var detail: String
    var amount: Double
    var occurredAt: Date

    var customer: CustomerProfile?

    var eventType: TimelineEventType {
        get { TimelineEventType(rawValue: eventTypeRaw) ?? .note }
        set { eventTypeRaw = newValue.rawValue }
    }

    init(
        eventType: TimelineEventType,
        title: String,
        detail: String = "",
        amount: Double = 0,
        occurredAt: Date = .now
    ) {
        self.id = UUID()
        self.eventTypeRaw = eventType.rawValue
        self.title = title
        self.detail = detail
        self.amount = amount
        self.occurredAt = occurredAt
    }
}
