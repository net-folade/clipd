import SwiftUI

// Note: this file must not be named main.swift — SwiftPM rejects @main there.
@main
struct ClipdApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var store: HistoryStore
    @StateObject private var monitor: ClipboardMonitor

    init() {
        let store = HistoryStore()
        let monitor = ClipboardMonitor(store: store)
        monitor.start()
        _store = StateObject(wrappedValue: store)
        _monitor = StateObject(wrappedValue: monitor)
        AppDelegate.store = store
    }

    // ContentView owns the appearance preference now — a preferredColorScheme
    // applied out here never reached the MenuBarExtra popover.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(monitor)
        }
        .defaultSize(width: 360, height: 480)

        MenuBarExtra("Clipd", systemImage: "doc.on.clipboard") {
            ContentView()
                .environmentObject(store)
                .environmentObject(monitor)
                .frame(width: 340, height: 460)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var store: HistoryStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppearanceMode.stored().apply()
        let showDockIcon = UserDefaults.standard.object(forKey: "showDockIcon") as? Bool ?? true
        NSApp.setActivationPolicy(showDockIcon ? .regular : .accessory)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppDelegate.store?.saveNow()
    }
}
