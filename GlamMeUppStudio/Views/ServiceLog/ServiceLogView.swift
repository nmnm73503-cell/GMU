import SwiftUI
import SwiftData

struct ServiceLogView: View {
    @Query(sort: \Appointment.startDate, order: .reverse) private var appointments: [Appointment]
    @State private var filterMonth = Date()

    var filtered: [Appointment] {
        appointments.filter {
            Calendar.current.isDate($0.startDate, equalTo: filterMonth, toGranularity: .month)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Month", selection: $filterMonth, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding(.horizontal)

                List(filtered) { appt in
                    NavigationLink(destination: AppointmentDetailView(appointment: appt)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(appt.customer?.fullName ?? appt.title)
                                    .font(.headline)
                                Spacer()
                                Text(appt.baseRate.currencyFormatted())
                                    .foregroundStyle(Theme.gold)
                            }
                            Text(appt.serviceLabel)
                                .font(.subheadline)
                                .foregroundStyle(Theme.muted)
                            HStack {
                                Text(appt.startDate.formatted())
                                Text("•")
                                Text(appt.startDate.timeFormatted())
                                if appt.effectiveTransportCost > 0 {
                                    Text("• Transport \(appt.effectiveTransportCost.currencyFormatted())")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(Theme.muted)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(Theme.cream)
            .navigationTitle("Service Log")
        }
    }
}
