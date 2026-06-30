import Foundation
import SwiftData

@Model
final class TouchUpTemplate {
    var id: UUID
    var name: String
    var subjectLine: String
    var bodyTemplate: String
    var includeLipShade: Bool
    var includeFoundationShade: Bool
    var includeBlushShade: Bool
    var isDefault: Bool
    var createdAt: Date

    init(
        name: String = "Post-Glam Care",
        subjectLine: String = "Your touch-up guide from Glam Me Upp",
        bodyTemplate: String = """
        Hi {{client_name}}! ✨

        Thank you for trusting me with your glam today. Here are your exact shades for mid-event touch-ups:

        💋 Lip: {{lip_shade}} ({{lip_brand}})
        🎨 Foundation: {{foundation_shade}} ({{foundation_brand}})
        🌸 Blush: {{blush_shade}}

        Setting technique: {{setting_technique}}

        Enjoy your event — you look stunning!
        — Nawal | @glam.me.upp
        """,
        includeLipShade: Bool = true,
        includeFoundationShade: Bool = true,
        includeBlushShade: Bool = true,
        isDefault: Bool = false,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.name = name
        self.subjectLine = subjectLine
        self.bodyTemplate = bodyTemplate
        self.includeLipShade = includeLipShade
        self.includeFoundationShade = includeFoundationShade
        self.includeBlushShade = includeBlushShade
        self.isDefault = isDefault
        self.createdAt = createdAt
    }
}
