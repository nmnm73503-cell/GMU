import SwiftUI
import SwiftData

@main
struct GlamMeUppStudioApp: App {
    @State private var configurationManager = ConfigurationManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StudioConfiguration.self,
            CustomConfigurationField.self,
            CancellationPolicyTier.self,
            StudioLocation.self,
            CustomerProfile.self,
            SkinProfile.self,
            AllergenTag.self,
            Appointment.self,
            AppointmentAddOn.self,
            PaymentRecord.self,
            FaceChart.self,
            FaceChartPoint.self,
            MediaAsset.self,
            Expense.self,
            Receipt.self,
            ReceiptLineItem.self,
            KitItem.self,
            BridalContract.self,
            BridalPartyMember.self,
            FormulaChangeLog.self,
            TimelineEntry.self,
            TouchUpTemplate.self,
            ServiceCatalogItem.self,
            HouseVisitGroup.self,
            DailyFinancialSummary.self,
            IncomeAllocationEntry.self,
            AnalyticsSnapshot.self,
            ImportMetadata.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(configurationManager)
                .preferredColorScheme(.light)
                .onAppear {
                    configurationManager.bootstrapIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
