import SwiftUI

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
        TabView {
            GeneralSettingsView(store: store)
                .tabItem { Label("General", systemImage: "gear") }
            NotificationSettingsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            AdvancedSettingsView(store: store)
                .tabItem { Label("Advanced", systemImage: "wrench") }
        }
        .frame(width: 420, height: 260)
    }
}

struct GeneralSettingsView: View {
    let store: TailscaleStore
    @AppStorage("refreshInterval") private var refreshInterval: Double = 10

    var body: some View {
        Form {
            Picker("Refresh interval", selection: $refreshInterval) {
                Text("5 seconds").tag(5.0)
                Text("10 seconds").tag(10.0)
                Text("30 seconds").tag(30.0)
                Text("1 minute").tag(60.0)
            }

            LabeledContent("Tailscale") {
                Text(store.status?.version ?? "Not detected")
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Tailnet") {
                Text(store.tailnetName)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onChange(of: refreshInterval) {
            store.startAutoRefresh(interval: refreshInterval)
        }
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notifyPeerChanges") private var notifyPeerChanges = true
    @AppStorage("notifyKeyExpiry") private var notifyKeyExpiry = true
    @AppStorage("notifyServiceHealth") private var notifyServiceHealth = false

    var body: some View {
        Form {
            Toggle("Peer online/offline changes", isOn: $notifyPeerChanges)
            Toggle("Key expiry warnings", isOn: $notifyKeyExpiry)
            Toggle("Service health changes", isOn: $notifyServiceHealth)
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("usePopoverUI") private var usePopoverUI = true

    var body: some View {
        Form {
            Toggle("Use popover UI (vs. classic menu)", isOn: $usePopoverUI)
                .help("Restart TailBar after changing this setting.")
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    let store: TailscaleStore
    @AppStorage("preferLocalAPI") private var preferLocalAPI = true

    var body: some View {
        Form {
            Toggle("Prefer Local API over CLI", isOn: $preferLocalAPI)
                .help("Uses the Tailscale Local API for faster communication. Falls back to CLI if unavailable.")

            LabeledContent("MagicDNS") {
                Text(store.status?.currentTailnet?.MagicDNSEnabled == true ? "Enabled" : "Disabled")
                    .foregroundStyle(.secondary)
            }

            LabeledContent("DNS Suffix") {
                Text(store.status?.magicDNSSuffix ?? "—")
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding()
    }
}
