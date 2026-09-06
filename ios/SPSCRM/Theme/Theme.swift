import SwiftUI

enum SPSTheme {
    /// Tokens copied from `web/tailwind.config.js` (`theme.extend.colors.sps`).
    static let primary = Color(hex: 0x025C23) // green
    static let primaryDark = Color(hex: 0x014A1C) // green-dark
    static let bodyGreen = Color(hex: 0x418458) // green-body
    static let sage = Color(hex: 0x81AD8E) // green-sage
    static let pale = Color(hex: 0xC0D5C3) // green-pale
    static let greenLight = Color(hex: 0xE8F3EB) // green-light
    static let orange = Color(hex: 0xF58426)
    static let gold = orange // web alias: gold === orange
    static let cream = Color(hex: 0xFFFDF8)
    static let ink = Color(hex: 0x111111)
    static let muted = Color(hex: 0x6B7280)
    static let border = Color(hex: 0xE5E7EB)
    static let card = Color.white
    static let danger = Color(hex: 0xDC2626)

    static let societyName = SPSBrandAssets.societyEyebrow
    static let appName = SPSBrandAssets.productName
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

struct ShamrockMark: View {
    var size: CGFloat = 28
    var color: Color = SPSTheme.orange

    var body: some View {
        ShamrockShape()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Three-leaf mark matching the web empty-state shamrock.
struct ShamrockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        var path = Path()
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * s, y: rect.minY + y * s)
        }
        path.move(to: p(12, 3.2))
        path.addCurve(to: p(13.8, 8.7), control1: p(13.6, 5.4), control2: p(14.2, 7.3))
        path.addCurve(to: p(12, 10.9), control1: p(13.5, 9.7), control2: p(12.9, 10.4))
        path.addCurve(to: p(10.2, 8.7), control1: p(11.1, 10.4), control2: p(10.5, 9.7))
        path.addCurve(to: p(12, 3.2), control1: p(9.8, 7.3), control2: p(10.4, 5.4))
        path.closeSubpath()

        path.move(to: p(6.2, 9.4))
        path.addCurve(to: p(11.4, 12.2), control1: p(8.8, 9.8), control2: p(10.6, 10.8))
        path.addCurve(to: p(11.8, 15.3), control1: p(12.0, 13.2), control2: p(12.1, 14.3))
        path.addCurve(to: p(8.9, 13.6), control1: p(10.7, 15.1), control2: p(9.7, 14.5))
        path.addCurve(to: p(6.2, 9.4), control1: p(7.8, 12.3), control2: p(7.1, 10.6))
        path.closeSubpath()

        path.move(to: p(17.8, 9.4))
        path.addCurve(to: p(15.1, 13.6), control1: p(16.9, 10.6), control2: p(16.2, 12.3))
        path.addCurve(to: p(12.2, 15.3), control1: p(14.3, 14.5), control2: p(13.3, 15.1))
        path.addCurve(to: p(12.6, 12.2), control1: p(11.9, 14.3), control2: p(12.0, 13.2))
        path.addCurve(to: p(17.8, 9.4), control1: p(13.4, 10.8), control2: p(15.2, 9.8))
        path.closeSubpath()

        path.move(to: p(11.2, 14.8))
        path.addCurve(to: p(12.0, 19.6), control1: p(11.4, 16.4), control2: p(11.7, 18.0))
        path.addCurve(to: p(12.8, 14.8), control1: p(12.3, 18.0), control2: p(12.6, 16.4))
        path.addCurve(to: p(11.2, 14.8), control1: p(12.3, 14.7), control2: p(11.7, 14.7))
        path.closeSubpath()
        return path
    }
}

enum SPSFormat {
    static func hkd(_ value: Decimal?) -> String {
        guard let value else { return "—" }
        let n = NSDecimalNumber(decimal: value)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "HKD"
        f.locale = Locale(identifier: "en_HK")
        f.maximumFractionDigits = 0
        return f.string(from: n) ?? "HK$\(n)"
    }

    static func date(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "—" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        if let d = iso.date(from: String(value.prefix(10))) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_HK")
            f.dateStyle = .medium
            f.timeStyle = .none
            return f.string(from: d)
        }
        return value
    }

    static func titleCase(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }
}
