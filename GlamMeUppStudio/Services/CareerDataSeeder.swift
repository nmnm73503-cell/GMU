import Foundation

struct CareerSeedFile: Codable {
    let version: Int
    let source: String
    let exportedAt: String
    let clients: [CareerSeedClient]
    let serviceLog: [CareerSeedServiceEntry]
    let expenses: [CareerSeedExpense]
    let incomeAllocations: [CareerSeedAllocation]
    let monthlySummary: [CareerSeedMonthlySummary]
}

struct CareerSeedClient: Codable {
    let name: String
    let leadSource: String
}

struct CareerSeedServiceEntry: Codable {
    let date: String
    let month: String
    let day: String
    let clientName: String
    let service: String
    let startTime: String
    let endTime: String
    let durationHours: Double
    let revenue: Double
    let transportCost: Double
    let paymentMethod: String
    let leadSource: String
    let status: String
    let serviceStyle: String
    let headcountTier: String
}

struct CareerSeedExpense: Codable {
    let date: String?
    let month: String
    let category: String
    let amount: Double
    let description: String
}

struct CareerSeedAllocation: Codable {
    let date: String?
    let totalEarned: Double
    let savings: Double
    let business: Double
    let personal: Double
    let drawings: Double
    let expenses: Double
}

struct CareerSeedMonthlySummary: Codable {
    let month: String
    let totalRevenue: Double
    let totalExpenses: Double
    let netProfit: Double
}

struct CareerImportResult {
    let clientsCreated: Int
    let appointmentsCreated: Int
    let expensesCreated: Int
    let allocationsCreated: Int
    let houseGroupsCreated: Int
    let paymentsCreated: Int
    let skippedDuplicates: Int

    var summary: String {
        """
        Imported \(clientsCreated) clients, \(appointmentsCreated) appointments, \
        \(expensesCreated) expenses, \(allocationsCreated) income allocations, \
        \(houseGroupsCreated) house visits, \(paymentsCreated) payments.
        """
    }
}

enum CareerDataSeeder {
    static let seedFilename = "career_seed"
    static let userDefaultsImportedKey = "careerDataImported"

    static func loadSeedFromBundle() -> CareerSeedFile? {
        guard let url = Bundle.main.url(forResource: seedFilename, withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(CareerSeedFile.self, from: data)
    }

    static func shouldAutoImport(context: ModelContext) -> Bool {
        let imported = UserDefaults.standard.bool(forKey: userDefaultsImportedKey)
        if imported { return false }
        let clientCount = (try? context.fetchCount(FetchDescriptor<CustomerProfile>())) ?? 0
        let apptCount = (try? context.fetchCount(FetchDescriptor<Appointment>())) ?? 0
        return clientCount == 0 && apptCount == 0
    }

    @discardableResult
    static func importFromBundle(context: ModelContext, replaceExisting: Bool = false) throws -> CareerImportResult {
        guard let seed = loadSeedFromBundle() else {
            throw CareerImportError.seedFileNotFound
        }
        return try importSeed(seed, context: context, replaceExisting: replaceExisting)
    }

    @discardableResult
    static func importSeed(
        _ seed: CareerSeedFile,
        context: ModelContext,
        replaceExisting: Bool = false
    ) throws -> CareerImportResult {
        if replaceExisting {
            try clearImportedData(context: context)
        }

        var clientMap: [String: CustomerProfile] = [:]
        var clientsCreated = 0
        var skipped = 0

        let existingClients = try context.fetch(FetchDescriptor<CustomerProfile>())
        for existing in existingClients {
            clientMap[existing.fullName.lowercased()] = existing
        }

        for entry in seed.clients {
            let key = entry.name.lowercased()
            if clientMap[key] != nil {
                skipped += 1
                continue
            }
            let parts = entry.name.split(separator: " ", maxSplits: 1).map(String.init)
            let profile = CustomerProfile(
                firstName: parts.first ?? entry.name,
                lastName: parts.count > 1 ? parts[1] : "",
                leadSource: mapLeadSource(entry.leadSource)
            )
            context.insert(profile)
            clientMap[key] = profile
            clientsCreated += 1
        }

        var houseGroupMap: [String: HouseVisitGroup] = [:]
        var houseGroupsCreated = 0
        var appointmentsCreated = 0
        var paymentsCreated = 0

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        for entry in seed.serviceLog {
            let clientKey = entry.clientName.lowercased()
            let client: CustomerProfile
            if let existing = clientMap[clientKey] {
                client = existing
            } else {
                let parts = entry.clientName.split(separator: " ", maxSplits: 1).map(String.init)
                client = CustomerProfile(
                    firstName: parts.first ?? entry.clientName,
                    lastName: parts.count > 1 ? parts[1] : "",
                    leadSource: mapLeadSource(entry.leadSource)
                )
                context.insert(client)
                clientMap[clientKey] = client
                clientsCreated += 1
            }

            guard let dayString = entry.date, let day = dateFormatter.date(from: dayString) else { continue }

            let start = combine(date: day, timeString: entry.startTime) ?? day
            let end = combine(date: day, timeString: entry.endTime) ?? start.addingTimeInterval(entry.durationHours * 3600)

            let houseKey = "\(entry.clientName.lowercased())|\(dayString)"
            let houseGroup: HouseVisitGroup
            if let existing = houseGroupMap[houseKey] {
                houseGroup = existing
            } else {
                houseGroup = HouseVisitGroup(
                    houseLabel: entry.clientName,
                    visitDate: day,
                    venueAddress: entry.clientName,
                    sharedTransportCost: entry.transportCost
                )
                context.insert(houseGroup)
                houseGroupMap[houseKey] = houseGroup
                houseGroupsCreated += 1
            }
            if entry.transportCost > houseGroup.sharedTransportCost {
                houseGroup.sharedTransportCost = entry.transportCost
            }

            let style = MakeupServiceStyle(rawValue: entry.serviceStyle) ?? .soft
            let tier = HeadcountTier(rawValue: entry.headcountTier) ?? .oneToTwo
            let status: AppointmentStatus = entry.status.lowercased() == "cancelled" ? .cancelled : .completed

            let appointment = Appointment(
                title: entry.service,
                appointmentType: style == .bridalTrial ? .bridal : .event,
                status: status,
                startDate: start,
                endDate: end,
                venueName: entry.clientName,
                venueAddress: entry.clientName,
                travelFee: 0,
                baseRate: entry.revenue,
                manualTransportCost: entry.transportCost,
                serviceStyle: style,
                headcountTier: tier,
                leadSource: mapLeadSource(entry.leadSource),
                durationHours: entry.durationHours,
                serviceLogStatus: entry.status.lowercased()
            )
            appointment.customer = client
            appointment.houseVisitGroup = houseGroup
            houseGroup.appointments.append(appointment)
            client.appointments.append(appointment)
            appointment.recalculateTotals()
            context.insert(appointment)
            appointmentsCreated += 1

            if entry.revenue > 0 && status == .completed {
                let payment = PaymentRecord(
                    amount: entry.revenue,
                    paymentType: .final,
                    paymentMethod: mapPaymentMethod(entry.paymentMethod),
                    paidAt: start
                )
                payment.appointment = appointment
                appointment.payments.append(payment)
                appointment.depositPaid = entry.revenue
                context.insert(payment)
                paymentsCreated += 1
            }

            CustomerProfileService.addTimelineEntry(
                customer: client,
                type: .appointment,
                title: entry.service,
                detail: dayString,
                amount: entry.revenue,
                context: context
            )
        }

        for client in clientMap.values {
            CustomerProfileService.refreshMetrics(for: client, context: context)
        }

        var expensesCreated = 0
        for entry in seed.expenses {
            guard let dayString = entry.date, let day = dateFormatter.date(from: dayString) else { continue }
            let expense = Expense(
                title: entry.description.isEmpty ? entry.category : entry.description,
                category: mapExpenseCategory(entry.category),
                amount: entry.amount,
                expenseDescription: entry.description,
                expenseDate: day
            )
            context.insert(expense)
            expensesCreated += 1
        }

        var allocationsCreated = 0
        for entry in seed.incomeAllocations {
            guard let dayString = entry.date, let day = dateFormatter.date(from: dayString) else { continue }
            let allocation = IncomeAllocationEntry(
                allocationDate: day,
                totalEarned: entry.totalEarned,
                savingsPercentage: 33,
                businessPercentage: 33,
                personalPercentage: 34,
                drawings: entry.drawings,
                expensesDeducted: entry.expenses
            )
            allocation.savingsAmount = entry.savings
            allocation.businessAmount = entry.business
            allocation.personalAmount = entry.personal
            context.insert(allocation)
            allocationsCreated += 1
        }

        let metadata = ImportMetadata(
            sourceFile: seed.source,
            clientCount: clientsCreated,
            appointmentCount: appointmentsCreated,
            expenseCount: expensesCreated,
            allocationCount: allocationsCreated,
            version: seed.version
        )
        context.insert(metadata)
        try context.save()
        UserDefaults.standard.set(true, forKey: userDefaultsImportedKey)

        return CareerImportResult(
            clientsCreated: clientsCreated,
            appointmentsCreated: appointmentsCreated,
            expensesCreated: expensesCreated,
            allocationsCreated: allocationsCreated,
            houseGroupsCreated: houseGroupsCreated,
            paymentsCreated: paymentsCreated,
            skippedDuplicates: skipped
        )
    }

    static func clearImportedData(context: ModelContext) throws {
        try context.fetch(FetchDescriptor<PaymentRecord>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<Appointment>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<HouseVisitGroup>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<Expense>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<IncomeAllocationEntry>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<ImportMetadata>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<TimelineEntry>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<ReceiptLineItem>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<Receipt>()).forEach { context.delete($0) }
        try context.fetch(FetchDescriptor<CustomerProfile>()).forEach { context.delete($0) }
        try context.save()
        UserDefaults.standard.set(false, forKey: userDefaultsImportedKey)
    }

    private static func combine(date: Date, timeString: String) -> Date? {
        guard !timeString.isEmpty, timeString != "-" else { return nil }
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        let formats = ["hh:mm a", "h:mm a", "HH:mm"]
        for fmt in formats {
            let tf = DateFormatter()
            tf.dateFormat = fmt
            tf.locale = Locale(identifier: "en_US_POSIX")
            if let timeOnly = tf.date(from: trimmed) {
                let cal = Calendar.current
                let comps = cal.dateComponents([.hour, .minute], from: timeOnly)
                return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: date)
            }
        }
        return nil
    }

    private static func mapLeadSource(_ raw: String) -> LeadSource {
        switch raw.lowercased() {
        case "referral": return .referral
        case "instagram": return .instagram
        case "tiktok": return .tiktok
        default: return .referral
        }
    }

    private static func mapPaymentMethod(_ raw: String) -> PaymentMethod {
        switch raw.lowercased() {
        case "cash": return .cash
        case "m-pesa", "mpesa": return .mpesa
        case "card": return .card
        default: return .cash
        }
    }

    private static func mapExpenseCategory(_ raw: String) -> ExpenseCategory {
        let lower = raw.lowercased()
        if lower.contains("product") { return .productRestock }
        if lower.contains("travel") || lower.contains("transport") { return .travelFuel }
        if lower.contains("education") { return .education }
        if lower.contains("marketing") { return .marketing }
        if lower.contains("studio") { return .studio }
        if lower.contains("disposable") { return .disposables }
        return .other
    }
}

enum CareerImportError: LocalizedError {
    case seedFileNotFound
    case decodeFailed

    var errorDescription: String? {
        switch self {
        case .seedFileNotFound: return "Career seed file not found in app bundle."
        case .decodeFailed: return "Could not decode career seed data."
        }
    }
}
