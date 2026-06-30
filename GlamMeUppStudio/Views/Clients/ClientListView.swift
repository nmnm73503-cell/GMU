import SwiftUI
import SwiftData

struct ClientListView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<CustomerProfile> { !$0.isArchived }, sort: \CustomerProfile.updatedAt, order: .reverse)
    private var clients: [CustomerProfile]
    @State private var showingForm = false
    @State private var search = ""

    var filtered: [CustomerProfile] {
        guard !search.isEmpty else { return clients }
        return clients.filter {
            $0.fullName.localizedCaseInsensitiveContains(search) ||
            $0.phoneNumber.contains(search)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.cream.ignoresSafeArea()
                if filtered.isEmpty {
                    EmptyStateView(icon: "person.crop.circle.badge.plus", title: "No Clients Yet", message: "Add your first client to start building unified profiles.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { client in
                                NavigationLink(destination: ClientDetailView(client: client)) {
                                    GlassCard(padding: 16) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(client.fullName.isEmpty ? "Unnamed Client" : client.fullName)
                                                    .font(Theme.headlineFont)
                                                    .foregroundStyle(Theme.navy)
                                                Text(client.leadSource.displayName)
                                                    .font(Theme.captionFont)
                                                    .foregroundStyle(Theme.muted)
                                                Text("LTV: \(client.lifetimeValue.currencyFormatted())")
                                                    .font(.caption)
                                                    .foregroundStyle(Theme.gold)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(Theme.muted)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $search, prompt: "Search clients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingForm = true } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.gold)
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                ClientFormView()
            }
        }
    }
}
