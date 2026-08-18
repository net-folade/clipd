import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "appearanceMode"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct Palette {
    let background: Color
    let surface: Color
    let border: Color
    let text: Color
    let dim: Color

    static let dark = Palette(
        background: Color(hex: 0x0B0B0F),
        surface: Color(hex: 0x14141A),
        border: Color(hex: 0x232330),
        text: Color(hex: 0xE8E0D2),
        dim: Color(hex: 0x8A8478)
    )

    static let light = Palette(
        background: Color(hex: 0xF2EAD9),
        surface: Color(hex: 0xE9DFC9),
        border: Color(hex: 0xD8CBB0),
        text: Color(hex: 0x14141A),
        dim: Color(hex: 0x6B6353)
    )

    static func resolve(_ scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
