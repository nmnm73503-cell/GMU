import Foundation
import SwiftData
import SwiftUI
import UIKit

@Observable
final class ConfigurationManager {
    static let shared = ConfigurationManager()

    var activeConfiguration: StudioConfiguration?
    var logoImage: UIImage?

    func bootstrapIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<StudioConfiguration>()
        if let existing = try? context.fetch(descriptor).first {
            activeConfiguration = existing
            loadLogo(from: existing)
            ensureServiceCatalog(context: context)
            ensureTouchUpTemplate(context: context)
            if CareerDataSeeder.shouldAutoImport(context: context) {
                _ = try? CareerDataSeeder.importFromBundle(context: context)
            }
            return
        }

        let config = StudioConfiguration(
            businessName: "Glam Me Upp",
            artistName: "Nawal",
            tagline: "Dar es Salaam | Bridal • Event • Photoshoots",
            instagramHandle: "glam.me.upp",
            tiktokHandle: "glam.me.upp",
            studioAddress: "Dar es Salaam, Tanzania",
            phoneNumber: "",
            travelFeePerKm: 1500,
            depositPercentage: 50,
            receiptFooterText: "Thank you for trusting me with your glam. Bookings via call."
        )

        config.cancellationTiers = [
            CancellationPolicyTier(name: "48+ hours", hoursBeforeAppointment: 48, feePercentage: 0),
            CancellationPolicyTier(name: "24–48 hours", hoursBeforeAppointment: 24, feePercentage: 25),
            CancellationPolicyTier(name: "Under 24 hours", hoursBeforeAppointment: 0, feePercentage: 50, flatFee: 0),
            CancellationPolicyTier(name: "No Show", hoursBeforeAppointment: 0, feePercentage: 100)
        ]

        config.locations = [
            StudioLocation(
                name: "Home Studio",
                address: "Dar es Salaam, Tanzania",
                latitude: -6.7924,
                longitude: 39.2083,
                isPrimary: true
            )
        ]

        context.insert(config)
        activeConfiguration = config
        seedServiceCatalog(context: context)
        seedTouchUpTemplate(context: context)
        try? context.save()
        if CareerDataSeeder.shouldAutoImport(context: context) {
            _ = try? CareerDataSeeder.importFromBundle(context: context)
        }
    }

    func updateLogo(data: Data, context: ModelContext) {
        guard let config = activeConfiguration else { return }
        config.logoImageData = data
        config.updatedAt = .now
        logoImage = UIImage(data: data)
        try? context.save()
    }

    func clearLogo(context: ModelContext) {
        guard let config = activeConfiguration else { return }
        config.logoImageData = nil
        config.updatedAt = .now
        logoImage = nil
        try? context.save()
    }

    private func loadLogo(from config: StudioConfiguration) {
        if let data = config.logoImageData {
            logoImage = UIImage(data: data)
        }
    }

    private func seedServiceCatalog(context: ModelContext) {
        let catalog: [(MakeupServiceStyle, HeadcountTier, Double, Double)] = [
            (.simple, .oneToTwo, 70_000, 1),
            (.simple, .threePlus, 50_000, 0.5),
            (.soft, .oneToTwo, 80_000, 1),
            (.soft, .threePlus, 60_000, 1),
            (.dramatic, .oneToTwo, 90_000, 1),
            (.dramatic, .threePlus, 70_000, 1),
            (.bridalTrial, .oneToTwo, 70_000, 2)
        ]
        for (index, item) in catalog.enumerated() {
            let entry = ServiceCatalogItem(
                serviceStyle: item.0,
                headcountTier: item.1,
                basePrice: item.2,
                defaultDurationHours: item.3,
                sortOrder: index
            )
            context.insert(entry)
        }
    }

    private func ensureServiceCatalog(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<ServiceCatalogItem>())) ?? 0
        if count == 0 { seedServiceCatalog(context: context); try? context.save() }
    }

    private func seedTouchUpTemplate(context: ModelContext) {
        let template = TouchUpTemplate(isDefault: true)
        context.insert(template)
    }

    private func ensureTouchUpTemplate(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<TouchUpTemplate>())) ?? 0
        if count == 0 { seedTouchUpTemplate(context: context); try? context.save() }
    }

    func nextReceiptNumber() -> String {
        guard let config = activeConfiguration else { return "GMU-0001" }
        let number = config.receiptNextNumber
        config.receiptNextNumber += 1
        return "\(config.receiptPrefix)-\(number)"
    }
}
