import SwiftUI
import SwiftData

struct BridalContractListView: View {
    @Query(sort: \BridalContract.weddingDate, order: .reverse) private var contracts: [BridalContract]
    @State private var showingForm = false

    var body: some View {
        List(contracts) { contract in
            NavigationLink(contract.eventName.isEmpty ? "Bridal Event" : contract.eventName) {
                BridalContractDetailView(contract: contract)
            }
        }
        .navigationTitle("Bridal Contracts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingForm = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingForm) {
            BridalContractFormView()
        }
    }
}

struct BridalContractDetailView: View {
    @Bindable var contract: BridalContract

    var body: some View {
        List {
            Section("Event") {
                Text(contract.eventName)
                Text(contract.weddingDate.formatted())
                Text(contract.venueAddress)
            }
            Section("Financials") {
                LabeledContent("Total", value: contract.masterContractTotal.currencyFormatted())
                LabeledContent("Paid", value: contract.depositCollected.currencyFormatted())
                LabeledContent("Balance", value: contract.balanceDue.currencyFormatted())
            }
            Section("Party (\(contract.partyMembers.count))") {
                ForEach(contract.partyMembers) { member in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(member.displayName)
                            Text(member.role.displayName).font(.caption)
                        }
                        Spacer()
                        Text(member.serviceRate.currencyFormatted())
                    }
                }
            }
        }
        .navigationTitle("Bridal Contract")
    }
}

struct BridalContractFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var eventName = ""
    @State private var weddingDate = Date()
    @State private var venue = ""
    @State private var total = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Event Name", text: $eventName)
                DatePicker("Wedding Date", selection: $weddingDate, displayedComponents: .date)
                TextField("Venue", text: $venue)
                TextField("Contract Total", value: $total, format: .number)
            }
            .navigationTitle("New Bridal Contract")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func save() {
        let contract = BridalContract(
            eventName: eventName,
            weddingDate: weddingDate,
            venueAddress: venue,
            masterContractTotal: total,
            balanceDue: total
        )
        context.insert(contract)
        try? context.save()
        dismiss()
    }
}
