import SwiftUI
import SwiftData

struct AppointmentDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(ConfigurationManager.self) private var configManager
    @Bindable var appointment: Appointment
    @State private var showingReceipt = false
    @State private var receiptPDF: Data?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appointment.serviceLabel).font(Theme.titleFont)
                        Text(appointment.customer?.fullName ?? appointment.title)
                        Text("\(appointment.startDate.formatted()) \(appointment.startDate.timeFormatted()) – \(appointment.endDate.timeFormatted())")
                            .font(.caption).foregroundStyle(Theme.muted)
                        HStack {
                            MetricTile(title: "Revenue", value: appointment.baseRate.currencyFormatted())
                            MetricTile(title: "Transport", value: appointment.effectiveTransportCost.currencyFormatted())
                        }
                        MetricTile(title: "Net", value: appointment.netRevenue.currencyFormatted())
                    }
                }
                LuxuryButton(title: "Generate Receipt") { generateReceipt() }
                if let pdf = receiptPDF {
                    NavigationLink("Preview Receipt") {
                        ReceiptPreviewView(pdfData: pdf, receiptNumber: appointment.receipts.last?.receiptNumber ?? "")
                    }
                }
            }
            .padding()
        }
        .background(Theme.cream)
        .navigationTitle("Appointment")
    }

    private func generateReceipt() {
        guard let config = configManager.activeConfiguration else { return }
        let number = configManager.nextReceiptNumber()
        let receipt = Receipt(
            receiptNumber: number,
            subtotal: appointment.baseRate,
            travelFee: appointment.effectiveTransportCost,
            taxRate: appointment.taxRate,
            taxAmount: appointment.taxAmount,
            totalAmount: appointment.totalAmount,
            clientName: appointment.customer?.fullName ?? appointment.title,
            clientPhone: appointment.customer?.phoneNumber ?? ""
        )
        receipt.lineItems = [
            ReceiptLineItem(label: appointment.serviceLabel, unitPrice: appointment.baseRate)
        ]
        for addOn in appointment.addOns {
            receipt.lineItems.append(ReceiptLineItem(label: addOn.name, unitPrice: addOn.price, sortOrder: receipt.lineItems.count))
        }
        receipt.appointment = appointment
        receipt.customer = appointment.customer
        let pdf = ReceiptPDFGenerator.generate(
            receipt: receipt,
            appointment: appointment,
            config: config,
            logo: configManager.logoImage
        )
        receipt.pdfData = pdf
        receiptPDF = pdf
        appointment.receipts.append(receipt)
        context.insert(receipt)
        try? context.save()
    }
}

struct AppointmentFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(ConfigurationManager.self) private var configManager
    @Query private var clients: [CustomerProfile]
    @Query(sort: \ServiceCatalogItem.sortOrder) private var catalog: [ServiceCatalogItem]

    var initialDate: Date = .now
    @State private var selectedClient: CustomerProfile?
    @State private var selectedCatalog: ServiceCatalogItem?
    @State private var startDate = Date()
    @State private var durationHours = 1.0
    @State private var manualTransport = 0.0
    @State private var leadSource: LeadSource = .referral
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var venueAddress = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select").tag(nil as CustomerProfile?)
                        ForEach(clients) { c in Text(c.fullName).tag(c as CustomerProfile?) }
                    }
                }
                Section("Service") {
                    Picker("Service", selection: $selectedCatalog) {
                        Text("Select").tag(nil as ServiceCatalogItem?)
                        ForEach(catalog.filter { $0.isActive }) { item in
                            Text("\(item.displayName) — \(item.basePrice.currencyFormatted())").tag(item as ServiceCatalogItem?)
                        }
                    }
                }
                Section("Schedule") {
                    DatePicker("Start", selection: $startDate)
                    Stepper("Duration: \(durationHours, specifier: "%.1f")h", value: $durationHours, in: 0.5...8, step: 0.5)
                }
                Section("Logistics") {
                    TextField("Venue / House", text: $venueAddress)
                    TextField("Transport cost", value: $manualTransport, format: .number)
                    Picker("Lead Source", selection: $leadSource) {
                        ForEach(LeadSource.allCases) { Text($0.displayName).tag($0) }
                    }
                    Picker("Payment", selection: $paymentMethod) {
                        ForEach(PaymentMethod.allCases) { Text($0.displayName).tag($0) }
                    }
                }
            }
            .navigationTitle("New Appointment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear {
                startDate = initialDate
                if selectedCatalog == nil { selectedCatalog = catalog.first }
            }
        }
    }

    private func save() {
        guard let item = selectedCatalog else { return }
        let end = startDate.addingTimeInterval(durationHours * 3600)
        let appt = Appointment(
            title: item.displayName,
            appointmentType: item.serviceStyle == .bridalTrial ? .bridal : .event,
            status: .completed,
            startDate: startDate,
            endDate: end,
            venueAddress: venueAddress,
            baseRate: item.basePrice,
            manualTransportCost: manualTransport,
            serviceStyle: item.serviceStyle,
            headcountTier: item.headcountTier,
            leadSource: leadSource,
            durationHours: durationHours
        )
        appt.customer = selectedClient
        if let config = configManager.activeConfiguration, manualTransport <= 0 {
            TravelFeeCalculator.applyTravelFee(to: appt, config: config)
        } else {
            appt.recalculateTotals()
        }
        let payment = PaymentRecord(amount: item.basePrice, paymentType: .final, paymentMethod: paymentMethod, paidAt: startDate)
        payment.appointment = appt
        appt.payments.append(payment)
        context.insert(appt)
        context.insert(payment)
        if let client = selectedClient {
            CustomerProfileService.refreshMetrics(for: client, context: context)
        }
        try? context.save()
        dismiss()
    }
}
