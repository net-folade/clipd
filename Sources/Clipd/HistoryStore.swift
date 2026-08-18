import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [ClipItem] = []

    static let maxUnpinned = 30

    private let storageURL: URL
    private var saveTask: Task<Void, Never>?

    init(storageURL: URL? = nil) {
        self.storageURL = storageURL ?? Self.defaultStorageURL()
        load()
    }

    static func defaultStorageURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Clipd/history.json")
    }

    func add(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        if items.first?.text == text { return }
        if let index = items.firstIndex(where: { $0.text == text }) {
            var existing = items.remove(at: index)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
        } else {
            items.insert(ClipItem(text: text), at: 0)
        }
        enforceCap()
        scheduleSave()
    }

    func togglePin(_ item: ClipItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        enforceCap()
        scheduleSave()
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
        scheduleSave()
    }

    func clearAll() {
        items.removeAll()
        scheduleSave()
    }

    func filtered(query: String) -> [ClipItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let matches = trimmed.isEmpty
            ? items
            : items.filter { $0.text.localizedCaseInsensitiveContains(trimmed) }
        return matches.filter(\.isPinned) + matches.filter { !$0.isPinned }
    }

    private func enforceCap() {
        var unpinned = items.filter { !$0.isPinned }.count
        guard unpinned > Self.maxUnpinned else { return }
        var index = items.count - 1
        while unpinned > Self.maxUnpinned && index >= 0 {
            if !items[index].isPinned {
                items.remove(at: index)
                unpinned -= 1
            }
            index -= 1
        }
    }

    // MARK: - Persistence

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    func saveNow() {
        saveTask?.cancel()
        saveTask = nil
        do {
            let directory = storageURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(items)
            try data.write(to: storageURL, options: .atomic)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o600], ofItemAtPath: storageURL.path)
        } catch {
            // Persistence is best-effort; history stays usable in memory.
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([ClipItem].self, from: data) else { return }
        items = decoded
    }
}
