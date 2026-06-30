import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(ConfigurationManager.self) private var configManager
    @Query(sort: \ImportMetadata.importedAt, order: .reverse) private var importHistory: [ImportMetadata]

    @State private var logoItem: PhotosPickerItem?
    @State private var importMessage = ""
    @State private var showImportAlert = false
    @State private var importError = ""
    @State private var showError = false

    private var config: StudioConfiguration? { configManager.activeConfiguration }

    var body: some View {
        NavigationStack {
            if let config {
                Form {
                    importSection
                    logoSection(config: config)
                    contactSection(config: config)
                    travelSection(config: config)
                    incomeSplitSection(config: config)
                    receiptSection(config: config)
                    catalogSection
                    customFieldsSection(config: config)
                    cancellationSection(config: config)
                    bridalSection
                }
                .navigationTitle("Settings")
                .onChange(of: logoItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self) {
                            configManager.updateLogo(data: data, context: context)
                        }
                    }
                }
                .onDisappear {
                    config.updatedAt = .now
                    try? context.save()
                }
            } else {
                ProgressView("Loading settings…")
            }
        }
        .alert("Import Complete", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: { Text(importMessage) }
        .alert("Import Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: { Text(importError) }
    }

    @ViewBuilder
    private var importSection: some View {
        Section("Career Data Import") {
            if let meta = importHistory.first {
                Text("Last import: \(meta.importedAt.formatted())")
                Text("\(meta.clientCount) clients, \(meta.appointmentCount) services, \(meta.expenseCount) expenses")
                    .font(.caption)
            }
            Button("Import from My Career") { reimport() }
            Button("Replace All Career Data", role: .destructive) { reimport(replace: true) }
        }
    }

    @ViewBuilder
    private func logoSection(config: StudioConfiguration) -> some View {
        Section("Logo & Branding") {
            if let logo = configManager.logoImage {
                Image(uiImage: logo).resizable().scaledToFit().frame(height: 80)
            }
            PhotosPicker(selection: $logoItem, matching: .images) {
                Label("Choose Logo for Receipts", systemImage: "photo")
            }
            Button("Remove Logo", role: .destructive) { configManager.clearLogo(context: context) }
            TextField("Business Name", text: Bindable(config).businessName)
            TextField("Artist Name", text: Bindable(config).artistName)
            TextField("Tagline", text: Bindable(config).tagline)
            TextField("Primary Color Hex", text: Bindable(config).primaryColorHex)
            TextField("Accent Color Hex", text: Bindable(config).accentColorHex)
        }
    }

    @ViewBuilder
    private func contactSection(config: StudioConfiguration) -> some View {
        Section("Contact") {
            TextField("Phone", text: Bindable(config).phoneNumber)
            TextField("Email", text: Bindable(config).email)
            TextField("Instagram", text: Bindable(config).instagramHandle)
            TextField("TikTok", text: Bindable(config).tiktokHandle)
        }
    }

    @ViewBuilder
    private func travelSection(config: StudioConfiguration) -> some View {
        Section("Travel Fees") {
            TextField("Per km", value: Bindable(config).travelFeePerKm, format: .number)
            TextField("Minimum fee", value: Bindable(config).travelFeeMinimum, format: .number)
            TextField("Free radius km", value: Bindable(config).travelFeeFreeRadiusKm, format: .number)
        }
    }

    @ViewBuilder
    private func incomeSplitSection(config: StudioConfiguration) -> some View {
        Section("Income Split") {
            TextField("Savings %", value: Bindable(config).savingsAllocationPercent, format: .number)
            TextField("Business %", value: Bindable(config).businessAllocationPercent, format: .number)
            TextField("Personal %", value: Bindable(config).personalAllocationPercent, format: .number)
        }
    }

    @ViewBuilder
    private func receiptSection(config: StudioConfiguration) -> some View {
        Section("Receipts") {
            TextField("Prefix", text: Bindable(config).receiptPrefix)
            TextField("Footer", text: Bindable(config).receiptFooterText, axis: .vertical)
            NavigationLink("Receipt History") { ReceiptListView() }
        }
    }

    private var catalogSection: some View {
        Section("Service Catalog") {
            NavigationLink("Manage Services") { ServiceCatalogSettingsView() }
        }
    }

    @ViewBuilder
    private func customFieldsSection(config: StudioConfiguration) -> some View {
        Section("Custom Fields") {
            NavigationLink("Unlimited Configuration") { CustomFieldsEditorView(config: config) }
        }
    }

    @ViewBuilder
    private func cancellationSection(config: StudioConfiguration) -> some View {
        Section("Cancellation Tiers") {
            ForEach(config.cancellationTiers.sorted(by: { $0.sortOrder < $1.sortOrder })) { tier in
                VStack(alignment: .leading) {
                    Text(tier.name)
                    Text("\(tier.feePercentage)% fee • \(tier.hoursBeforeAppointment)h window").font(.caption)
                }
            }
        }
    }

    private var bridalSection: some View {
        Section("Bridal") {
            NavigationLink("Bridal Contracts") { BridalContractListView() }
        }
    }

    private func reimport(replace: Bool = false) {
        do {
            let result = try CareerDataSeeder.importFromBundle(context: context, replaceExisting: replace)
            importMessage = result.summary
            showImportAlert = true
        } catch {
            importError = error.localizedDescription
            showError = true
        }
    }
}

struct ServiceCatalogSettingsView: View {
    @Query(sort: \ServiceCatalogItem.sortOrder) private var items: [ServiceCatalogItem]

    var body: some View {
        List(items) { item in
            HStack {
                Text(item.displayName)
                Spacer()
                Text(item.basePrice.currencyFormatted()).foregroundStyle(Theme.gold)
            }
        }
        .navigationTitle("Service Catalog")
    }
}

struct CustomFieldsEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var config: StudioConfiguration
    @State private var label = ""
    @State private var key = ""
    @State private var scope: CustomFieldScope = .global
    @State private var fieldType: CustomFieldType = .text

    var body: some View {
        List {
            Section("Add Field") {
                TextField("Label", text: $label)
                TextField("Key", text: $key)
                Picker("Scope", selection: $scope) {
                    ForEach(CustomFieldScope.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Type", selection: $fieldType) {
                    ForEach(CustomFieldType.allCases) { Text($0.rawValue).tag($0) }
                }
                Button("Add Custom Field") { addField() }
            }
            Section("Existing") {
                ForEach(config.customFields.sorted(by: { $0.sortOrder < $1.sortOrder })) { field in
                    VStack(alignment: .leading) {
                        Text(field.label).font(.headline)
                        Text("\(field.scope.rawValue) • \(field.fieldType.rawValue)").font(.caption)
                    }
                }
                .onDelete { indexSet in
                    let sorted = config.customFields.sorted(by: { $0.sortOrder < $1.sortOrder })
                    for i in indexSet { context.delete(sorted[i]) }
                }
            }
        }
        .navigationTitle("Custom Fields")
    }

    private func addField() {
        let field = CustomConfigurationField(
            key: key.isEmpty ? label.lowercased().replacingOccurrences(of: " ", with: "_") : key,
            label: label,
            fieldType: fieldType,
            scope: scope,
            sortOrder: config.customFields.count
        )
        field.studioConfiguration = config
        config.customFields.append(field)
        context.insert(field)
        label = ""; key = ""
        try? context.save()
    }
}
