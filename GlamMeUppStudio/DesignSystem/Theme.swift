import SwiftUI

enum Theme {
    static let navy = Color(hex: "#1A1A2E")
    static let gold = Color(hex: "#C9A962")
    static let cream = Color(hex: "#FAF8F5")
    static let blush = Color(hex: "#F5E6E0")
    static let charcoal = Color(hex: "#2D2D3A")
    static let muted = Color(hex: "#8E8E9A")
    static let success = Color(hex: "#4A7C59")
    static let warning = Color(hex: "#C4841D")

    static let titleFont = Font.system(.title, design: .serif).weight(.semibold)
    static let headlineFont = Font.system(.headline, design: .serif)
    static let bodyFont = Font.system(.body, design: .default)
    static let captionFont = Font.system(.caption, design: .default)

    static let cardRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let padding: CGFloat = 20
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

extension Double {
    func currencyFormatted(code: String = "TZS") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let number = formatter.string(from: NSNumber(value: self)) ?? "0"
        return "\(number) \(code)"
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var startOfMonth: Date {
        let c = Calendar.current.dateComponents([.year, .month], from: self)
        return Calendar.current.date(from: c) ?? self
    }
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let f = DateFormatter()
        f.dateStyle = style
        f.timeStyle = .none
        return f.string(from: self)
    }
    func timeFormatted() -> String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f.string(from: self)
    }
}
