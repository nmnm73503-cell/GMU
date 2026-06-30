import Foundation
import SwiftData

@Model
final class StudioConfiguration {
    var id: UUID
    var businessName: String
    var artistName: String
    var tagline: String
    var logoImageData: Data?
    var logoImagePath: String?
    var primaryColorHex: String
    var accentColorHex: String
    var currencyCode: String
    var defaultTaxRate: Double
    var studioAddress: String
    var studioLatitude: Double
    var studioLongitude: Double
    var phoneNumber: String
    var email: String
    var instagramHandle: String
    var tiktokHandle: String
    var websiteURL: String
    var travelFeePerKm: Double
    var travelFeeMinimum: Double
    var travelFeeFreeRadiusKm: Double
    var depositPercentage: Double
    var requireCardVault: Bool
    var receiptFooterText: String
    var receiptPrefix: String
    var receiptNextNumber: Int
    var defaultCancellationHours: Int
    var savingsAllocationPercent: Double
    var businessAllocationPercent: Double
    var personalAllocationPercent: Double
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CustomConfigurationField.studioConfiguration)
    var customFields: [CustomConfigurationField]

    @Relationship(deleteRule: .cascade, inverse: \CancellationPolicyTier.studioConfiguration)
    var cancellationTiers: [CancellationPolicyTier]

    @Relationship(deleteRule: .cascade, inverse: \StudioLocation.studioConfiguration)
    var locations: [StudioLocation]

    init(
        businessName: String = "Glam Me Upp",
        artistName: String = "Nawal",
        tagline: String = "Dar es Salaam | Bridal • Event • Photoshoots",
        logoImageData: Data? = nil,
        logoImagePath: String? = nil,
        primaryColorHex: String = "#1A1A2E",
        accentColorHex: String = "#C9A962",
        currencyCode: String = "TZS",
        defaultTaxRate: Double = 0,
        studioAddress: String = "Dar es Salaam, Tanzania",
        studioLatitude: Double = -6.7924,
        studioLongitude: Double = 39.2083,
        phoneNumber: String = "",
        email: String = "",
        instagramHandle: String = "glam.me.upp",
        tiktokHandle: String = "glam.me.upp",
        websiteURL: String = "",
        travelFeePerKm: Double = 1500,
        travelFeeMinimum: Double = 0,
        travelFeeFreeRadiusKm: Double = 5,
        depositPercentage: Double = 50,
        requireCardVault: Bool = true,
        receiptFooterText: String = "Thank you for trusting me with your glam. Bookings via call.",
        receiptPrefix: String = "GMU",
        receiptNextNumber: Int = 1001,
        defaultCancellationHours: Int = 48,
        savingsAllocationPercent: Double = 33,
        businessAllocationPercent: Double = 33,
        personalAllocationPercent: Double = 34,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        customFields: [CustomConfigurationField] = [],
        cancellationTiers: [CancellationPolicyTier] = [],
        locations: [StudioLocation] = []
    ) {
        self.id = UUID()
        self.businessName = businessName
        self.artistName = artistName
        self.tagline = tagline
        self.logoImageData = logoImageData
        self.logoImagePath = logoImagePath
        self.primaryColorHex = primaryColorHex
        self.accentColorHex = accentColorHex
        self.currencyCode = currencyCode
        self.defaultTaxRate = defaultTaxRate
        self.studioAddress = studioAddress
        self.studioLatitude = studioLatitude
        self.studioLongitude = studioLongitude
        self.phoneNumber = phoneNumber
        self.email = email
        self.instagramHandle = instagramHandle
        self.tiktokHandle = tiktokHandle
        self.websiteURL = websiteURL
        self.travelFeePerKm = travelFeePerKm
        self.travelFeeMinimum = travelFeeMinimum
        self.travelFeeFreeRadiusKm = travelFeeFreeRadiusKm
        self.depositPercentage = depositPercentage
        self.requireCardVault = requireCardVault
        self.receiptFooterText = receiptFooterText
        self.receiptPrefix = receiptPrefix
        self.receiptNextNumber = receiptNextNumber
        self.defaultCancellationHours = defaultCancellationHours
        self.savingsAllocationPercent = savingsAllocationPercent
        self.businessAllocationPercent = businessAllocationPercent
        self.personalAllocationPercent = personalAllocationPercent
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.customFields = customFields
        self.cancellationTiers = cancellationTiers
        self.locations = locations
    }
}

@Model
final class CustomConfigurationField {
    var id: UUID
    var key: String
    var label: String
    var fieldTypeRaw: String
    var scopeRaw: String
    var stringValue: String
    var numberValue: Double
    var boolValue: Bool
    var dateValue: Date?
    var sortOrder: Int
    var isRequired: Bool
    var isVisibleOnReceipt: Bool
    var createdAt: Date

    var studioConfiguration: StudioConfiguration?

    var fieldType: CustomFieldType {
        get { CustomFieldType(rawValue: fieldTypeRaw) ?? .text }
        set { fieldTypeRaw = newValue.rawValue }
    }

    var scope: CustomFieldScope {
        get { CustomFieldScope(rawValue: scopeRaw) ?? .global }
        set { scopeRaw = newValue.rawValue }
    }

    init(
        key: String,
        label: String,
        fieldType: CustomFieldType = .text,
        scope: CustomFieldScope = .global,
        stringValue: String = "",
        numberValue: Double = 0,
        boolValue: Bool = false,
        dateValue: Date? = nil,
        sortOrder: Int = 0,
        isRequired: Bool = false,
        isVisibleOnReceipt: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.key = key
        self.label = label
        self.fieldTypeRaw = fieldType.rawValue
        self.scopeRaw = scope.rawValue
        self.stringValue = stringValue
        self.numberValue = numberValue
        self.boolValue = boolValue
        self.dateValue = dateValue
        self.sortOrder = sortOrder
        self.isRequired = isRequired
        self.isVisibleOnReceipt = isVisibleOnReceipt
        self.createdAt = createdAt
    }
}

@Model
final class CancellationPolicyTier {
    var id: UUID
    var name: String
    var hoursBeforeAppointment: Int
    var feePercentage: Double
    var flatFee: Double
    var sortOrder: Int

    var studioConfiguration: StudioConfiguration?

    init(
        name: String,
        hoursBeforeAppointment: Int,
        feePercentage: Double = 0,
        flatFee: Double = 0,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.hoursBeforeAppointment = hoursBeforeAppointment
        self.feePercentage = feePercentage
        self.flatFee = flatFee
        self.sortOrder = sortOrder
    }
}

@Model
final class StudioLocation {
    var id: UUID
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var isPrimary: Bool

    var studioConfiguration: StudioConfiguration?

    init(
        name: String,
        address: String,
        latitude: Double,
        longitude: Double,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.isPrimary = isPrimary
    }
}
