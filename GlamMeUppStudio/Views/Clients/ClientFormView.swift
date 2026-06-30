import SwiftUI
import SwiftData

struct ClientFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var client: CustomerProfile?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var instagram = ""
    @State private var notes = ""
    @State private var leadSource: LeadSource = .referral
    @State private var cardLastFour = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone", text: $phone).keyboardType(.phonePad)
                    TextField("Email", text: $email).keyboardType(.emailAddress)
                    TextField("Instagram", text: $instagram)
                }
                Section("Acquisition") {
                    Picker("Lead Source", selection: $leadSource) {
                        ForEach(LeadSource.allCases) { source in
                            Text(source.displayName).tag(source)
                        }
                    }
                }
                Section("Payment Vault") {
                    TextField("Card Last 4 (vault ref)", text: $cardLastFour).keyboardType(.numberPad)
                }
                Section("Notes") {
                    TextEditor(text: $notes).frame(minHeight: 80)
                }
            }
            .navigationTitle(client == nil ? "New Client" : "Edit Client")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let client else { return }
        firstName = client.firstName
        lastName = client.lastName
        phone = client.phoneNumber
        email = client.email
        instagram = client.instagramHandle
        notes = client.notes
        leadSource = client.leadSource
        cardLastFour = client.cardLastFour
    }

    private func save() {
        let profile = client ?? CustomerProfile()
        profile.firstName = firstName
        profile.lastName = lastName
        profile.phoneNumber = phone
        profile.email = email
        profile.instagramHandle = instagram
        profile.notes = notes
        profile.leadSource = leadSource
        profile.cardLastFour = cardLastFour
        profile.updatedAt = .now
        if client == nil {
            context.insert(profile)
            CustomerProfileService.addTimelineEntry(
                customer: profile, type: .note, title: "Client created", context: context
            )
        }
        try? context.save()
        dismiss()
    }
}
