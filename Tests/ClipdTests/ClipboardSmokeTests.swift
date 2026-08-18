import AppKit
import Testing

@testable import Clipd

/// Integration smoke tests against the real general pasteboard.
///
/// The plan called these out as a `ClipdSmokeTest` executable; they live in the
/// test target because SwiftPM can't build one executable target that depends on
/// another. The suite is serialized (all tests share NSPasteboard.general) and
/// the user's clipboard contents are saved before and restored after each test.
@Suite(.serialized)
@MainActor
final class ClipboardSmokeTests {
    private let savedClipboard: String?
    private let store: HistoryStore
    private let monitor: ClipboardMonitor

    init() {
        savedClipboard = NSPasteboard.general.string(forType: .string)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipdSmoke-\(UUID().uuidString)/history.json")
        store = HistoryStore(storageURL: tempURL)
        monitor = ClipboardMonitor(store: store)
    }

    deinit {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if let saved = savedClipboard {
            pasteboard.setString(saved, forType: .string)
        }
    }

    @Test func writtenStringLandsInStore() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("smoke test payload", forType: .string)
        monitor.poll()
        #expect(store.items.map(\.text) == ["smoke test payload"])
    }

    @Test func concealedPayloadIsNotRecorded() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let item = NSPasteboardItem()
        item.setString("hunter2", forType: .string)
        item.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType"))
        pasteboard.writeObjects([item])
        monitor.poll()
        #expect(store.items.isEmpty, "concealed (password-manager) payloads must be skipped")
    }

    @Test func transientPayloadIsNotRecorded() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let item = NSPasteboardItem()
        item.setString("temporary", forType: .string)
        item.setString("", forType: NSPasteboard.PasteboardType("org.nspasteboard.TransientType"))
        pasteboard.writeObjects([item])
        monitor.poll()
        #expect(store.items.isEmpty)
    }

    @Test func copyBackDoesNotLoop() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("original", forType: .string)
        monitor.poll()
        #expect(store.items.count == 1)

        monitor.copyBack("original")
        monitor.poll()
        #expect(store.items.count == 1, "our own copy-back write must not be re-recorded")
        #expect(pasteboard.string(forType: .string) == "original")
    }

    @Test func pausedMonitorRecordsNothing() {
        monitor.isPaused = true
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("while paused", forType: .string)
        monitor.poll()
        #expect(store.items.isEmpty)
    }
}
