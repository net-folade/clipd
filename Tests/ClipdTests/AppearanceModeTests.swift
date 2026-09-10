import Foundation
import SwiftUI
import Testing

@testable import Clipd

/// Covers the appearance preference read that the Theme picker depends on.
/// `apply()` itself is not covered — it needs a live `NSApp`.
struct AppearanceModeTests {
    private func makeDefaults() throws -> UserDefaults {
        let suite = "ClipdTests-\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: suite))
    }

    @Test func storedDefaultsToSystemWhenUnset() throws {
        let defaults = try makeDefaults()
        #expect(AppearanceMode.stored(in: defaults) == .system)
    }

    @Test func storedReadsEachMode() throws {
        for mode in AppearanceMode.allCases {
            let defaults = try makeDefaults()
            defaults.set(mode.rawValue, forKey: AppearanceMode.storageKey)
            #expect(AppearanceMode.stored(in: defaults) == mode)
        }
    }

    @Test func storedFallsBackToSystemOnGarbage() throws {
        let defaults = try makeDefaults()
        defaults.set("sepia", forKey: AppearanceMode.storageKey)
        #expect(AppearanceMode.stored(in: defaults) == .system)
    }

    @Test func colorSchemeIsNilOnlyForSystem() {
        #expect(AppearanceMode.system.colorScheme == nil)
        #expect(AppearanceMode.light.colorScheme == .light)
        #expect(AppearanceMode.dark.colorScheme == .dark)
    }
}
