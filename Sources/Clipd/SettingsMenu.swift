import ServiceManagement
import SwiftUI

struct SettingsMenu: View {
    @EnvironmentObject private var store: HistoryStore
    @EnvironmentObject private var monitor: ClipboardMonitor
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage(HistoryStore.limitKey) private var historyLimit = HistoryStore.defaultMaxUnpinned
    @AppStorage("showDockIcon") private var showDockIcon = true
    @AppStorage("hotKeyEnabled") private var hotKeyEnabled = true
    @State private var runningApps: [NSRunningApplication] = []
    // Launch at Login and Ignored Apps read their state from outside SwiftUI
    // (ServiceManagement, a [String] default @AppStorage can't hold), so their
    // setters bump this to make SwiftUI re-read them.
    @State private var externalStateRevision = 0

    let palette: Palette

    // Opened in the user's browser: Clipd itself has no networking code, so the
    // policy is never fetched or shown in-app.
    private static let privacyPolicyURL = URL(string: "https://github.com/net-folade/clipd/blob/main/PRIVACY.md")!

    var body: some View {
        let _ = externalStateRevision
        Menu {
            Picker("Theme", selection: $appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode.rawValue)
                }
            }
            Picker("History Size", selection: $historyLimit) {
                ForEach(HistoryStore.limitOptions, id: \.self) { limit in
                    Text("\(limit) items").tag(limit)
                }
            }
            Menu("Ignored Apps") {
                let apps = ignorableApps
                if apps.isEmpty {
                    Button("No apps running") {}
                        .disabled(true)
                }
                ForEach(apps, id: \.bundleID) { app in
                    Toggle(app.name, isOn: ignoredBinding(for: app.bundleID))
                }
            }
            Divider()
            Toggle("Show Dock Icon", isOn: $showDockIcon)
            Toggle("Launch at Login", isOn: launchAtLogin)
            Toggle("Keyboard Shortcut (⌥⌘V)", isOn: $hotKeyEnabled)
            Toggle("Pause Recording", isOn: $monitor.isPaused)
            Button("Privacy Policy…") {
                NSWorkspace.shared.open(Self.privacyPolicyURL)
            }
            Divider()
            Button("Quit Clipd") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(palette.dim)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .onChange(of: showDockIcon) { _, newValue in
            NSApp.setActivationPolicy(newValue ? .regular : .accessory)
            if newValue {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onChange(of: appearanceRaw) { _, newValue in
            (AppearanceMode(rawValue: newValue) ?? .system).apply()
        }
        .onChange(of: historyLimit) { _, newValue in
            store.maxUnpinned = newValue
        }
        // KVO keeps the Ignored Apps list current as apps launch and quit.
        .onReceive(NSWorkspace.shared.publisher(for: \.runningApplications)) { apps in
            runningApps = apps
        }
    }

    // MARK: - Launch at Login

    // Registration only works from a signed .app bundle; from `swift run` it
    // throws, so failures are logged and the toggle simply stays off.
    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    NSLog("Clipd: could not change Launch at Login: \(error)")
                }
                externalStateRevision += 1
            })
    }

    // MARK: - Ignored Apps

    /// Running regular apps plus anything already ignored, so an ignored app
    /// can be un-ignored even while it isn't running.
    private var ignorableApps: [(bundleID: String, name: String)] {
        let ownID = Bundle.main.bundleIdentifier
        var names: [String: String] = [:]
        for app in runningApps where app.activationPolicy == .regular {
            guard let id = app.bundleIdentifier, id != ownID else { continue }
            names[id] = app.localizedName ?? Self.displayName(forBundleID: id)
        }
        for id in ignoredBundleIDs where names[id] == nil {
            names[id] = Self.displayName(forBundleID: id)
        }
        return names
            .map { (bundleID: $0.key, name: $0.value) }
            .sorted {
                let order = $0.name.localizedStandardCompare($1.name)
                return order == .orderedSame ? $0.bundleID < $1.bundleID : order == .orderedAscending
            }
    }

    private var ignoredBundleIDs: [String] {
        UserDefaults.standard.stringArray(forKey: ClipboardMonitor.ignoredAppsKey) ?? []
    }

    // Re-reads the stored list on every change: the window and the menu bar
    // popover each have a SettingsMenu, and a cached copy in one would
    // overwrite the other's edits.
    private func ignoredBinding(for bundleID: String) -> Binding<Bool> {
        Binding(
            get: { ignoredBundleIDs.contains(bundleID) },
            set: { isIgnored in
                var ids = ignoredBundleIDs.filter { $0 != bundleID }
                if isIgnored {
                    ids.append(bundleID)
                }
                UserDefaults.standard.set(ids, forKey: ClipboardMonitor.ignoredAppsKey)
                externalStateRevision += 1
            })
    }

    private static func displayName(forBundleID bundleID: String) -> String {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID
        }
        return FileManager.default.displayName(atPath: url.path)
    }
}
