import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ClientListView()
                .tabItem { Label("Clients", systemImage: "person.2.fill") }
                .tag(0)

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)

            ServiceLogView()
                .tabItem { Label("Service Log", systemImage: "list.bullet.rectangle") }
                .tag(2)

            AnalyticsDashboardView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }
                .tag(3)

            ExpenseListView()
                .tabItem { Label("Expenses", systemImage: "creditcard") }
                .tag(4)

            KitInventoryView()
                .tabItem { Label("Kit", systemImage: "case.fill") }
                .tag(5)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(6)
        }
        .tint(Theme.gold)
    }
}
