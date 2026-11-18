import Foundation
import Testing

@testable import Clipd

/// Covers the pure parts of keyboard control: arrow-key selection movement and
/// the hot key preference read. Registering the Carbon hot key and toggling the
/// popover need a live NSApp and are verified by hand.
struct KeyboardNavigationTests {
    private let ids = [UUID(), UUID(), UUID()]

    @Test func emptyListHasNoSelection() {
        #expect(ListSelection.moved(nil, by: 1, in: []) == nil)
        #expect(ListSelection.moved(UUID(), by: -1, in: []) == nil)
    }

    @Test func noSelectionLandsOnFirstRow() {
        #expect(ListSelection.moved(nil, by: 1, in: ids) == ids[0])
        #expect(ListSelection.moved(nil, by: -1, in: ids) == ids[0])
    }

    @Test func movesOneRowInEachDirection() {
        #expect(ListSelection.moved(ids[1], by: 1, in: ids) == ids[2])
        #expect(ListSelection.moved(ids[1], by: -1, in: ids) == ids[0])
    }

    @Test func clampsAtBothEnds() {
        #expect(ListSelection.moved(ids[0], by: -1, in: ids) == ids[0])
        #expect(ListSelection.moved(ids[2], by: 1, in: ids) == ids[2])
    }

    @Test func selectionNoLongerVisibleRestartsAtFirstRow() {
        #expect(ListSelection.moved(UUID(), by: 1, in: ids) == ids[0])
    }

    // MARK: - hot key preference

    private func makeDefaults() throws -> UserDefaults {
        let suite = "ClipdTests-\(UUID().uuidString)"
        return try #require(UserDefaults(suiteName: suite))
    }

    @Test func hotKeyEnabledWhenUnset() throws {
        #expect(HotKey.isEnabled(in: try makeDefaults()))
    }

    @Test func hotKeyFollowsStoredValue() throws {
        let defaults = try makeDefaults()
        defaults.set(false, forKey: HotKey.enabledKey)
        #expect(!HotKey.isEnabled(in: defaults))
        defaults.set(true, forKey: HotKey.enabledKey)
        #expect(HotKey.isEnabled(in: defaults))
    }
}
