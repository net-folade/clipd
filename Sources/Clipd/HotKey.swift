import AppKit
import Carbon.HIToolbox

/// The global Option-Command-V shortcut. Carbon's RegisterEventHotKey is used
/// because, unlike an NSEvent global monitor, it needs no Accessibility
/// permission and keeps working inside the App Sandbox.
@MainActor
final class HotKey {
    static let shared = HotKey()
    nonisolated static let enabledKey = "hotKeyEnabled"

    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false
    private var defaultsObserver: NSObjectProtocol?

    /// Unset means on: the shortcut works until the user turns it off.
    nonisolated static func isEnabled(in defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: enabledKey) as? Bool ?? true
    }

    /// Registers the shortcut if enabled, then follows the setting.
    /// didChangeNotification fires for every key, so `update()` must stay cheap
    /// and idempotent.
    func start() {
        update()
        guard defaultsObserver == nil else { return }
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { _ in
            MainActor.assumeIsolated { HotKey.shared.update() }
        }
    }

    private func update() {
        if Self.isEnabled() { register() } else { unregister() }
    }

    private func register() {
        guard hotKeyRef == nil else { return }
        if !handlerInstalled {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            handlerInstalled = InstallEventHandler(
                GetApplicationEventTarget(), hotKeyHandler, 1, &eventType, nil, nil) == noErr
        }
        let id = EventHotKeyID(signature: OSType(0x434C_5044), id: 1) // 'CLPD'
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_V), UInt32(cmdKey | optionKey), id,
            GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr {
            NSLog("Clipd: could not register Option-Command-V (OSStatus \(status))")
            hotKeyRef = nil
        }
    }

    private func unregister() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }

    /// Toggles the popover. When it's already open, close it the way Escape
    /// does so focus goes back to the app the user came from.
    fileprivate func pressed() {
        if MenuBarPopover.isShown {
            MenuBarPopover.dismiss()
            return
        }
        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        if !MenuBarPopover.toggle() {
            // Status item not found (SwiftUI's private window layout changed):
            // show the main window instead so the shortcut still does something.
            NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        }
    }
}

/// Carbon calls back through a C function pointer, which can't capture
/// context, so it goes through `HotKey.shared`. Handlers on the application
/// event target run on the main thread.
private func hotKeyHandler(
    _ call: EventHandlerCallRef?, _ event: EventRef?, _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    MainActor.assumeIsolated { HotKey.shared.pressed() }
    return noErr
}

/// Opens and closes the MenuBarExtra popover, which SwiftUI has no API for.
/// We click the status item's button just as the user would: closing the
/// popover window directly leaves SwiftUI thinking it is still open, and the
/// next click on the menu bar icon then does nothing.
@MainActor
enum MenuBarPopover {
    static var isShown: Bool {
        NSApp.windows.contains { $0.className.contains("MenuBarExtraWindow") && $0.isVisible }
    }

    /// Returns false when the status item button can't be found.
    @discardableResult
    static func toggle() -> Bool {
        guard let button = statusBarButton() else { return false }
        button.performClick(nil)
        return true
    }

    /// Closes the popover and hides the app so focus returns to the previously
    /// active app. Hiding alone isn't enough: the popover is only hidden, not
    /// closed, and pops back up (still "open") on the next unhide.
    static func dismiss() {
        if isShown { toggle() }
        NSApp.hide(nil)
    }

    /// Walks subviews instead of using `value(forKey: "statusItem")`: KVC on a
    /// missing key raises an Objective-C exception Swift can't catch.
    private static func statusBarButton() -> NSStatusBarButton? {
        for window in NSApp.windows where window.className.contains("NSStatusBarWindow") {
            if let button = firstStatusBarButton(in: window.contentView) { return button }
        }
        return nil
    }

    private static func firstStatusBarButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view else { return nil }
        if let button = view as? NSStatusBarButton { return button }
        for subview in view.subviews {
            if let button = firstStatusBarButton(in: subview) { return button }
        }
        return nil
    }
}
