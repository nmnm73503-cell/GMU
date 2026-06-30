import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Query(sort: \Expense.expenseDate, order: .reverse) private var expenses: [Expense]
    @State private var showingForm = false

    var total: Double { expenses.reduce(0) { $0 + $1.amount } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    GlassCard(padding: 14) {
                        HStack {
                            Text("Total Expenses")
                            Spacer()
                            Text(total.currencyFormatted()).foregroundStyle(Theme.gold)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                ForEach(expenses) { expense in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(expense.title).font(.headline)
                            Text(expense.category.displayName).font(.caption).foregroundStyle(Theme.muted)
                            Text(expense.expenseDate.formatted()).font(.caption2)
                        }
                        Spacer()
                        Text(expense.amount.currencyFormatted())
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingForm = true } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .sheet(isPresented: $showingForm) { ExpenseFormView() }
        }
    }
}

struct ExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var amount = 0.0
    @State private var category: ExpenseCategory = .other
    @State private var description = ""
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Category", selection: $category) {
                    ForEach(ExpenseCategory.allCases) { Text($0.displayName).tag($0) }
                }
                TextField("Amount", value: $amount, format: .number)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Description", text: $description, axis: .vertical)
            }
            .navigationTitle("New Expense")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func save() {
        let expense = Expense(title: title, category: category, amount: amount, expenseDescription: description, expenseDate: date)
        context.insert(expense)
        try? context.save()
        dismiss()
    }
}
