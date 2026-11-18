import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: HistoryStore
    @EnvironmentObject private var monitor: ClipboardMonitor
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue

    @State private var query = ""
    @State private var showClearConfirm = false
    @State private var copiedID: UUID?
    @State private var selectedID: UUID?
    @FocusState private var searchFocused: Bool

    /// The menu bar popover dismisses on Return/Escape; the Dock window stays put.
    var isPopover = false

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceRaw) ?? .system
    }

    // Read the preference here rather than inheriting \.colorScheme: a
    // preferredColorScheme set on the Scene does not reach the MenuBarExtra
    // popover, so the environment stays on the system value and the palette
    // never followed the Theme picker.
    private var palette: Palette {
        switch appearance {
        case .light: return .light
        case .dark: return .dark
        case .system: return Palette.resolve(colorScheme)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(palette.border)
            // Inline confirmation instead of .alert — SwiftUI alerts never
            // present from a MenuBarExtra .window popover, so clearing from
            // the menu bar silently did nothing.
            if showClearConfirm {
                clearConfirmBar
                Divider().overlay(palette.border)
            }
            list
            Divider().overlay(palette.border)
            footer
        }
        .background(palette.background)
        .frame(minWidth: 320, minHeight: 400)
        .preferredColorScheme(appearance.colorScheme)
        // Runs on every popover open, not just the first: the popover keeps
        // this view alive between opens, so start each one fresh.
        .onAppear {
            searchFocused = true
            selectedID = nil
        }
        .onChange(of: query) { _, newValue in
            selectedID = store.filtered(query: newValue).first?.id
        }
    }

    private var clearConfirmBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Clear history? Clear Unpinned keeps your pinned items.")
                .font(.system(size: 11))
                .foregroundStyle(palette.text)
            HStack(spacing: 12) {
                Button("Clear Unpinned") {
                    store.clearUnpinned()
                    showClearConfirm = false
                }
                .foregroundStyle(.red)
                Button("Clear All") {
                    store.clearAll()
                    showClearConfirm = false
                }
                .foregroundStyle(.red)
                Spacer()
                Button("Cancel") {
                    showClearConfirm = false
                }
                .foregroundStyle(palette.dim)
            }
            .font(.system(size: 11, weight: .medium))
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(palette.surface)
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Clipd")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.text)
                if monitor.isPaused {
                    Text("Paused")
                        .font(.caption2)
                        .foregroundStyle(palette.dim)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(palette.surface))
                        .overlay(Capsule().strokeBorder(palette.border))
                }
                Spacer()
                Button {
                    showClearConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(palette.dim)
                }
                .buttonStyle(.plain)
                .help("Clear history")
                .disabled(store.items.isEmpty)
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.caption)
                    .foregroundStyle(palette.dim)
                TextField("Search", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.text)
                    .focused($searchFocused)
                    // Keys are handled on the field itself because it keeps
                    // focus while the user types; onKeyPress sees the arrows
                    // before the field editor uses them to move the caret.
                    .onKeyPress(.upArrow) {
                        moveSelection(by: -1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        moveSelection(by: 1)
                        return .handled
                    }
                    .onSubmit(copySelectionAndDismiss)
                    .onExitCommand {
                        if isPopover { MenuBarPopover.dismiss() }
                    }
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(palette.surface))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).strokeBorder(palette.border))
        }
        .padding(10)
    }

    private var list: some View {
        let results = store.filtered(query: query)
        let pinned = results.filter(\.isPinned)
        let unpinned = results.filter { !$0.isPinned }
        return ScrollViewReader { proxy in
            ScrollView {
                if results.isEmpty {
                    emptyState
                } else {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        if !pinned.isEmpty {
                            sectionHeader("Pinned")
                            ForEach(pinned) { row(for: $0) }
                        }
                        if !pinned.isEmpty && !unpinned.isEmpty {
                            sectionHeader("Recent")
                        }
                        ForEach(unpinned) { row(for: $0) }
                    }
                    .padding(10)
                }
            }
            .onChange(of: selectedID) { _, id in
                // No anchor: scroll only as far as needed to reveal the row.
                if let id { proxy.scrollTo(id) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(palette.dim)
            .padding(.top, 2)
    }

    private func row(for item: ClipItem) -> some View {
        ClipRowView(
            item: item,
            palette: palette,
            isCopied: copiedID == item.id,
            isSelected: selectedID == item.id,
            onCopy: { copy(item) },
            onTogglePin: { store.togglePin(item) }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: store.items.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.title2)
                .foregroundStyle(palette.dim)
            Text(store.items.isEmpty ? "No clipboard history yet" : "No matches")
                .font(.system(size: 12))
                .foregroundStyle(palette.dim)
            if store.items.isEmpty {
                Text("Copy some text to get started")
                    .font(.caption)
                    .foregroundStyle(palette.dim.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var footer: some View {
        HStack {
            Text("\(store.items.count) item\(store.items.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(palette.dim)
            Spacer()
            SettingsMenu(palette: palette)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func copy(_ item: ClipItem) {
        monitor.copyBack(item.text)
        copiedID = item.id
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            if copiedID == item.id {
                copiedID = nil
            }
        }
    }

    // filtered(query:) already returns pinned then recent, the displayed order.
    private func moveSelection(by offset: Int) {
        let ids = store.filtered(query: query).map(\.id)
        selectedID = ListSelection.moved(selectedID, by: offset, in: ids)
    }

    private func copySelectionAndDismiss() {
        let results = store.filtered(query: query)
        guard let item = results.first(where: { $0.id == selectedID }) ?? results.first else { return }
        copy(item)
        if isPopover { MenuBarPopover.dismiss() }
    }
}

/// Arrow-key movement through the visible results, kept free of view state so
/// it can be unit-tested.
enum ListSelection {
    /// The id `offset` rows away from `current`, clamped to the ends. With no
    /// selection, or one that is no longer visible, any move lands on the first
    /// row, so the first Down press highlights the top result.
    static func moved(_ current: UUID?, by offset: Int, in ids: [UUID]) -> UUID? {
        guard !ids.isEmpty else { return nil }
        guard let current, let index = ids.firstIndex(of: current) else { return ids.first }
        return ids[min(max(index + offset, 0), ids.count - 1)]
    }
}
