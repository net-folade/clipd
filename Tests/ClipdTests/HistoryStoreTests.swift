import Foundation
import Testing

@testable import Clipd

@MainActor
final class HistoryStoreTests {
    private let tempURL: URL

    init() {
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipdTests-\(UUID().uuidString)")
            .appendingPathComponent("history.json")
    }

    deinit {
        try? FileManager.default.removeItem(at: tempURL.deletingLastPathComponent())
    }

    private func makeStore() -> HistoryStore {
        HistoryStore(storageURL: tempURL)
    }

    // MARK: - add / dedup

    @Test func addInsertsAtTop() {
        let store = makeStore()
        store.add("first")
        store.add("second")
        #expect(store.items.map(\.text) == ["second", "first"])
    }

    @Test func whitespaceOnlyIgnored() {
        let store = makeStore()
        store.add("   \n\t  ")
        store.add("")
        #expect(store.items.isEmpty)
    }

    @Test func addingNewestAgainIsNoOp() {
        let store = makeStore()
        store.add("hello")
        let originalDate = store.items[0].createdAt
        store.add("hello")
        #expect(store.items.count == 1)
        #expect(store.items[0].createdAt == originalDate)
    }

    @Test func duplicateOfOlderItemPromotesToTop() throws {
        let store = makeStore()
        store.add("first")
        store.add("second")
        let original = try #require(store.items.first(where: { $0.text == "first" }))
        store.add("first")
        #expect(store.items.map(\.text) == ["first", "second"])
        #expect(store.items[0].id == original.id, "promotion should move, not duplicate")
        #expect(store.items[0].createdAt >= original.createdAt)
        #expect(store.items.count == 2)
    }

    // MARK: - cap

    @Test func capEvictsOldestUnpinned() {
        let store = makeStore()
        for i in 1...(HistoryStore.maxUnpinned + 5) {
            store.add("item \(i)")
        }
        #expect(store.items.count == HistoryStore.maxUnpinned)
        #expect(store.items.first?.text == "item 35")
        #expect(store.items.last?.text == "item 6", "oldest five evicted")
    }

    @Test func pinnedItemSurvivesEviction() {
        let store = makeStore()
        store.add("keep me")
        store.togglePin(store.items[0])
        for i in 1...(HistoryStore.maxUnpinned + 10) {
            store.add("filler \(i)")
        }
        #expect(store.items.contains { $0.text == "keep me" && $0.isPinned })
        #expect(store.items.filter { !$0.isPinned }.count == HistoryStore.maxUnpinned)
        #expect(store.items.count == HistoryStore.maxUnpinned + 1)
    }

    // MARK: - pin / clear

    @Test func togglePin() {
        let store = makeStore()
        store.add("a")
        store.togglePin(store.items[0])
        #expect(store.items[0].isPinned)
        store.togglePin(store.items[0])
        #expect(!store.items[0].isPinned)
    }

    @Test func clearUnpinnedKeepsPins() {
        let store = makeStore()
        store.add("pinned one")
        store.togglePin(store.items[0])
        store.add("unpinned one")
        store.add("unpinned two")
        store.clearUnpinned()
        #expect(store.items.map(\.text) == ["pinned one"])
    }

    @Test func clearAllRemovesEverything() {
        let store = makeStore()
        store.add("pinned")
        store.togglePin(store.items[0])
        store.add("unpinned")
        store.clearAll()
        #expect(store.items.isEmpty)
    }

    // MARK: - filtered

    @Test func filteredIsCaseInsensitive() {
        let store = makeStore()
        store.add("Hello World")
        store.add("goodbye")
        #expect(store.filtered(query: "hello").map(\.text) == ["Hello World"])
        #expect(store.filtered(query: "WORLD").map(\.text) == ["Hello World"])
    }

    @Test func filteredSortsPinnedFirst() {
        let store = makeStore()
        store.add("old pinned")
        store.togglePin(store.items[0])
        store.add("newer unpinned")
        #expect(store.filtered(query: "").map(\.text) == ["old pinned", "newer unpinned"])
    }

    // MARK: - persistence

    @Test func jsonRoundTrip() {
        let store = makeStore()
        store.add("persist me")
        store.add("me too")
        store.togglePin(store.items[0])
        store.saveNow()

        let reloaded = HistoryStore(storageURL: tempURL)
        #expect(reloaded.items.map(\.text) == ["me too", "persist me"])
        #expect(reloaded.items[0].isPinned)
        #expect(reloaded.items.map(\.id) == store.items.map(\.id))
    }

    @Test func savedFileHasOwnerOnlyPermissions() throws {
        let store = makeStore()
        store.add("secretish")
        store.saveNow()
        let attrs = try FileManager.default.attributesOfItem(atPath: tempURL.path)
        #expect((attrs[.posixPermissions] as? NSNumber)?.intValue == 0o600)
    }

    @Test func corruptJSONLoadsEmptyWithoutCrashing() throws {
        try FileManager.default.createDirectory(
            at: tempURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("{not valid json!".utf8).write(to: tempURL)
        let store = HistoryStore(storageURL: tempURL)
        #expect(store.items.isEmpty)
    }
}
