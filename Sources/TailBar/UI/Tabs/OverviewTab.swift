import SwiftUI

struct OverviewTab: View {
    let store: TailscaleStore
    let searchText: String

    private var filteredServices: [ServiceInfo] {
        guard !searchText.isEmpty else { return store.services }
        let query = searchText.lowercased()
        return store.services.filter {
            $0.fullURL.lowercased().contains(query) ||
            "\($0.port)".contains(query) ||
            (AliasStore.alias(forPort: $0.port)?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status summary
            StatusSummaryView(store: store)

            Divider().padding(.horizontal, 14)

            // Active services
            VStack(alignment: .leading, spacing: 4) {
                Text("Active Services")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)

                if filteredServices.isEmpty {
                    EmptyServicesView()
                } else {
                    ServiceListView(services: filteredServices)
                }
            }

            // Detected ports
            if !store.detectedPorts.isEmpty {
                Divider().padding(.horizontal, 14)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected Ports")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)

                    DetectedPortsView(ports: store.detectedPorts)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusSummaryView: View {
    let store: TailscaleStore

    var body: some View {
        HStack(spacing: 16) {
            StatBadge(
                label: "Peers",
                value: "\(store.status?.peers?.count ?? 0)",
                icon: "laptopcomputer.and.iphone"
            )
            StatBadge(
                label: "Services",
                value: "\(store.serviceCount)",
                icon: "server.rack"
            )
            StatBadge(
                label: "Status",
                value: store.isConnected ? "Connected" : "Offline",
                icon: store.isConnected ? "checkmark.circle" : "xmark.circle"
            )
        }
        .padding(.horizontal, 14)
    }
}

struct StatBadge: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
