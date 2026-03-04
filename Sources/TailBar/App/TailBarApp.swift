import SwiftUI
import ServiceManagement

@main
struct TailBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(store: appDelegate.store)
        }
    }
}

struct SettingsView: View {
    let store: TailscaleStore

    var body: some View {
        Form {
            Section("General") {
                LaunchAtLoginToggle()

                Picker("Refresh interval", selection: Binding(
                    get: { UserDefaults.standard.double(forKey: "refreshInterval").nonZero ?? 10 },
                    set: {
                        UserDefaults.standard.set($0, forKey: "refreshInterval")
                        store.startAutoRefresh(interval: $0)
                    }
                )) {
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                }
            }

            Section("Interface") {
                Toggle("Use popover UI (vs. classic menu)", isOn: Binding(
                    get: { UserDefaults.standard.object(forKey: "usePopoverUI") as? Bool ?? true },
                    set: { UserDefaults.standard.set($0, forKey: "usePopoverUI") }
                ))
                .help("Restart TailBar after changing this setting.")
            }

            Section("Info") {
                LabeledContent("Tailscale") {
                    Text(store.status?.version ?? "Not detected")
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Tailnet") {
                    Text(store.tailnetName)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 280)
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at login", isOn: $launchAtLogin)
            .onChange(of: launchAtLogin) { _, newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchAtLogin = SMAppService.mainApp.status == .enabled
                }
            }
    }
}

private extension Double {
    var nonZero: Double? { self == 0 ? nil : self }
}
