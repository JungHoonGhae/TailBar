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
        }
        .frame(width: 360, height: 200)
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
