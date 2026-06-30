import SwiftUI
import SwiftData

struct SkinProfileEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let client: CustomerProfile
    var skinProfile: SkinProfile?

    @State private var fitzpatrick: FitzpatrickType = .typeIII
    @State private var hydration: SkinHydrationBaseline = .normal
    @State private var oiliness = 3
    @State private var undertone = "neutral"
    @State private var latexAllergy = false
    @State private var carmineAllergy = false
    @State private var fragranceSensitivity = false
    @State private var hypersensitivityNotes = ""
    @State private var customAllergenNotes = ""
    @State private var preferredFinish = "natural"
    @State private var newAllergen = ""

    var body: some View {
        Form {
            Section("Fitzpatrick & Baseline") {
                Picker("Skin Type", selection: $fitzpatrick) {
                    ForEach(FitzpatrickType.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Hydration", selection: $hydration) {
                    ForEach(SkinHydrationBaseline.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                Stepper("Oiliness: \(oiliness)", value: $oiliness, in: 1...5)
                TextField("Undertone", text: $undertone)
                TextField("Preferred Finish", text: $preferredFinish)
            }
            Section("Allergen Blacklist") {
                Toggle("Latex", isOn: $latexAllergy)
                Toggle("Carmine", isOn: $carmineAllergy)
                Toggle("Fragrance Sensitivity", isOn: $fragranceSensitivity)
                TextField("Other allergens / notes", text: $customAllergenNotes, axis: .vertical)
                TextField("Hypersensitivity notes", text: $hypersensitivityNotes, axis: .vertical)
            }
        }
        .navigationTitle("Skin Profile")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
        }
        .onAppear { load() }
    }

    private func load() {
        guard let skin = skinProfile ?? client.skinProfile else { return }
        fitzpatrick = skin.fitzpatrick
        hydration = skin.hydrationBaseline
        oiliness = skin.oilinessLevel
        undertone = skin.undertone
        latexAllergy = skin.latexAllergy
        carmineAllergy = skin.carmineAllergy
        fragranceSensitivity = skin.fragranceSensitivity
        hypersensitivityNotes = skin.hypersensitivityNotes
        customAllergenNotes = skin.customAllergenNotes
        preferredFinish = skin.preferredFinish
    }

    private func save() {
        let skin = skinProfile ?? client.skinProfile ?? SkinProfile()
        skin.fitzpatrick = fitzpatrick
        skin.hydrationBaseline = hydration
        skin.oilinessLevel = oiliness
        skin.undertone = undertone
        skin.latexAllergy = latexAllergy
        skin.carmineAllergy = carmineAllergy
        skin.fragranceSensitivity = fragranceSensitivity
        skin.hypersensitivityNotes = hypersensitivityNotes
        skin.customAllergenNotes = customAllergenNotes
        skin.preferredFinish = preferredFinish
        skin.updatedAt = .now
        if client.skinProfile == nil {
            client.skinProfile = skin
            context.insert(skin)
        }
        try? context.save()
        dismiss()
    }
}
