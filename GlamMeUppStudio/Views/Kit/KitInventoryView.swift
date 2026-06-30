import SwiftUI
import SwiftData

struct KitInventoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \KitItem.name) private var items: [KitItem]
    @State private var showingForm = false

    private var alerts: [KitAlert] { KitInventoryService.alerts(for: items) }

    var body: some View {
        NavigationStack {
            List {
                if !alerts.isEmpty {
                    Section("Alerts") {
                        ForEach(alerts) { alert in
                            HStack {
                                Image(systemName: alert.severity == .critical ? "exclamationmark.triangle.fill" : "bell.fill")
                                    .foregroundStyle(alert.severity == .critical ? .red : Theme.warning)
                                Text(alert.message).font(.caption)
                            }
                        }
                    }
                }
                ForEach(items) { item in
                    NavigationLink(item.name) { KitItemFormView(item: item) }
                }
            }
            .navigationTitle("Kit Inventory")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingForm = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showingForm) { KitItemFormView() }
        }
    }
}

struct KitItemFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var item: KitItem?

    @State private var name = ""
    @State private var brand = ""
    @State private var quantity = 1
    @State private var paoMonths = 6
    @State private var category: ProductCategory = .mascara
    @State private var markOpened = false

    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Brand", text: $brand)
            Stepper("Quantity: \(quantity)", value: $quantity, in: 0...99)
            Picker("Category", selection: $category) {
                ForEach(ProductCategory.allCases) { Text($0.rawValue).tag($0) }
            }
            Stepper("PAO months: \(paoMonths)", value: $paoMonths, in: 1...36)
            Toggle("Mark as opened today", isOn: $markOpened)
        }
        .navigationTitle(item == nil ? "New Kit Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
        .onAppear {
            guard let item else { return }
            name = item.name; brand = item.brand; quantity = item.quantity
            paoMonths = item.periodAfterOpeningMonths; category = item.category
        }
    }

    private func save() {
        let kit = item ?? KitItem()
        kit.name = name; kit.brand = brand; kit.quantity = quantity
        kit.periodAfterOpeningMonths = paoMonths; kit.category = category
        if markOpened { kit.markOpened() }
        kit.refreshStatus()
        if item == nil { context.insert(kit) }
        try? context.save()
        dismiss()
    }
}
