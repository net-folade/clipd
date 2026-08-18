import SwiftUI

struct SettingsMenu: View {
    @EnvironmentObject private var monitor: ClipboardMonitor
    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("showDockIcon") private var showDockIcon = true

    let palette: Palette

    var body: some View {
        Menu {
            Picker("Theme", selection: $appearanceRaw) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode.rawValue)
                }
            }
            Toggle("Show Dock Icon", isOn: $showDockIcon)
            Toggle("Pause Recording", isOn: $monitor.isPaused)
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
    }
}
