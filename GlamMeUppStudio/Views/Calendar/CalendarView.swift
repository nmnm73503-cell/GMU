import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query(sort: \Appointment.startDate) private var appointments: [Appointment]
    @State private var selectedDate = Date()
    @State private var mode: CalendarMode = .month
    @State private var showingForm = false

    enum CalendarMode: String, CaseIterable { case month, day }

    var filtered: [Appointment] {
        appointments.filter { Calendar.current.isDate($0.startDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $mode) {
                    ForEach(CalendarMode.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                DatePicker("", selection: $selectedDate, displayedComponents: mode == .month ? [.date] : [.date, .hourAndMinute])
                    .datePickerStyle(mode == .month ? .graphical : .compact)
                    .padding(.horizontal)

                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filtered) { appt in
                            NavigationLink(destination: AppointmentDetailView(appointment: appt)) {
                                GlassCard(padding: 14) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(appt.serviceLabel).font(.headline)
                                            Text(appt.customer?.fullName ?? appt.title).font(.subheadline)
                                            Text("\(appt.startDate.timeFormatted()) – \(appt.endDate.timeFormatted())")
                                                .font(.caption).foregroundStyle(Theme.muted)
                                        }
                                        Spacer()
                                        Text(appt.status.displayName)
                                            .font(.caption)
                                            .padding(6)
                                            .background(Theme.gold.opacity(0.2))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .background(Theme.cream)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingForm = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showingForm) {
                AppointmentFormView(initialDate: selectedDate)
            }
        }
    }
}
