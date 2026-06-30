import SwiftUI
import SwiftData

struct ClientDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var client: CustomerProfile
    @State private var showingEdit = false
    @State private var showingFaceChart = false
    @State private var showingTouchUp = false
    @State private var touchUpMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(client.fullName)
                            .font(Theme.titleFont)
                            .foregroundStyle(Theme.navy)
                        if !client.phoneNumber.isEmpty {
                            Label(client.phoneNumber, systemImage: "phone.fill")
                        }
                        if !client.instagramHandle.isEmpty {
                            Label("@\(client.instagramHandle)", systemImage: "camera.fill")
                        }
                        HStack {
                            MetricTile(title: "LTV", value: client.lifetimeValue.currencyFormatted())
                            MetricTile(title: "Visits", value: "\(client.totalAppointments)")
                        }
                    }
                }

                NavigationLink("Edit Profile") { ClientFormView(client: client) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.navy)

                if client.skinProfile == nil {
                    NavigationLink("Add Skin Profile") { SkinProfileEditorView(client: client) }
                } else if let skin = client.skinProfile {
                    NavigationLink("Skin Profile") { SkinProfileEditorView(client: client, skinProfile: skin) }
                }

                NavigationLink("Face Charts") { FaceChartCanvasView(client: client) }
                NavigationLink("Timeline") { TimelineView(client: client) }

                if let template = try? context.fetch(FetchDescriptor<TouchUpTemplate>()).first(where: { $0.isDefault }),
                   let chart = client.faceCharts.last {
                    LuxuryButton(title: "Generate Touch-Up Message") {
                        touchUpMessage = TouchUpMessageEngine.render(template: template, customer: client, faceChart: chart)
                        showingTouchUp = true
                        CustomerProfileService.addTimelineEntry(
                            customer: client, type: .touchUpSent,
                            title: "Touch-up guide sent", context: context
                        )
                    }
                }

                SectionHeader(title: "Recent Appointments")
                ForEach(client.appointments.sorted(by: { $0.startDate > $1.startDate }).prefix(5)) { appt in
                    GlassCard(padding: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(appt.serviceLabel).font(.headline)
                                Text(appt.startDate.formatted()).font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Text(appt.baseRate.currencyFormatted()).foregroundStyle(Theme.gold)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Theme.cream)
        .navigationTitle("Client")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Touch-Up Message", isPresented: $showingTouchUp) {
            Button("Copy", role: .none) { UIPasteboard.general.string = touchUpMessage }
            Button("OK", role: .cancel) {}
        } message: { Text(touchUpMessage) }
        .onAppear { CustomerProfileService.refreshMetrics(for: client, context: context) }
    }
}
