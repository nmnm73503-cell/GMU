import SwiftUI
import SwiftData

struct FaceChartCanvasView: View {
    @Environment(\.modelContext) private var context
    let client: CustomerProfile
    @State private var selectedChart: FaceChart?
    @State private var showingEditor = false

    var body: some View {
        VStack {
            if client.faceCharts.isEmpty {
                EmptyStateView(icon: "face.smiling", title: "No Face Charts", message: "Create a chart to map products to facial zones.")
                LuxuryButton(title: "Create Face Chart") { createChart() }
                    .padding()
            } else {
                List(client.faceCharts) { chart in
                    NavigationLink(chart.title) {
                        FaceChartEditorView(chart: chart, client: client)
                    }
                }
                LuxuryButton(title: "New Chart") { createChart() }.padding()
            }
        }
        .navigationTitle("Face Charts")
    }

    private func createChart() {
        let chart = FaceChart(title: "Chart \(client.faceCharts.count + 1)")
        chart.customer = client
        client.faceCharts.append(chart)
        context.insert(chart)
        try? context.save()
    }
}

struct FaceChartEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var chart: FaceChart
    let client: CustomerProfile
    @State private var selectedZone: FaceZone = .fullFace
    @State private var brand = ""
    @State private var productName = ""
    @State private var shade = ""
    @State private var category: ProductCategory = .foundation
    @State private var tapX: Double = 0.5
    @State private var tapY: Double = 0.5

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                        .fill(Theme.blush.opacity(0.4))
                        .frame(height: 320)
                    Image(systemName: "face.smiling.inverse")
                        .font(.system(size: 120))
                        .foregroundStyle(Theme.navy.opacity(0.2))
                    ForEach(chart.points) { point in
                        Circle()
                            .fill(Theme.gold)
                            .frame(width: 14, height: 14)
                            .position(x: point.coordinateX * 300, y: point.coordinateY * 300)
                    }
                }
                .frame(width: 300, height: 300)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    tapX = min(1, max(0, location.x / 300))
                    tapY = min(1, max(0, location.y / 300))
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Setting technique", text: $chart.settingTechnique)
                        Stepper("Lighting \(chart.lightingKelvin)K", value: Binding(
                            get: { chart.lightingKelvin },
                            set: { chart.lightingKelvin = $0 }
                        ), in: 2700...6500, step: 100)
                        TextField("Camera", text: $chart.cameraType)
                        TextField("Lens", text: $chart.lensType)
                    }
                }

                GlassCard {
                    VStack(spacing: 8) {
                        Picker("Zone", selection: $selectedZone) {
                            ForEach(FaceZone.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Picker("Category", selection: $category) {
                            ForEach(ProductCategory.allCases) { Text($0.rawValue).tag($0) }
                        }
                        TextField("Brand", text: $brand)
                        TextField("Product", text: $productName)
                        TextField("Shade", text: $shade)
                        LuxuryButton(title: "Add Product Point") { addPoint() }
                    }
                }

                ForEach(chart.points) { point in
                    GlassCard(padding: 12) {
                        Text("\(point.zone.rawValue): \(point.brand) \(point.productName) — \(point.shade)")
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .background(Theme.cream)
        .navigationTitle(chart.title)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { try? context.save() }
            }
        }
    }

    private func addPoint() {
        let point = FaceChartPoint(
            zone: selectedZone,
            productCategory: category,
            brand: brand,
            productName: productName,
            shade: shade,
            coordinateX: tapX,
            coordinateY: tapY,
            sortOrder: chart.points.count
        )
        point.faceChart = chart
        chart.points.append(point)
        context.insert(point)
        brand = ""; productName = ""; shade = ""
        try? context.save()
    }
}
