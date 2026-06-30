import Foundation

enum TouchUpMessageEngine {
    static func render(
        template: TouchUpTemplate,
        customer: CustomerProfile,
        faceChart: FaceChart?
    ) -> String {
        var text = template.bodyTemplate
        let points = faceChart?.points ?? []
        let lip = points.first { $0.productCategory == .lip }
        let foundation = points.first { $0.productCategory == .foundation }
        let blush = points.first { $0.productCategory == .blush }

        let replacements: [String: String] = [
            "{{client_name}}": customer.firstName.isEmpty ? customer.fullName : customer.firstName,
            "{{lip_shade}}": lip?.shade ?? "your lip shade",
            "{{lip_brand}}": lip?.brand ?? "",
            "{{foundation_shade}}": foundation?.shade ?? "your foundation",
            "{{foundation_brand}}": foundation?.brand ?? "",
            "{{blush_shade}}": blush?.shade ?? "your blush",
            "{{setting_technique}}": faceChart?.settingTechnique ?? "pressed powder + setting spray"
        ]

        for (key, value) in replacements {
            text = text.replacingOccurrences(of: key, with: value)
        }
        return text
    }
}
