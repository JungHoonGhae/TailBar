import SwiftUI

@MainActor
struct ServicesTab: View {
    let store: TailscaleStore
    let searchText: String

    @State private var showAddServe = false
    @State private var newPort = ""
    @State private var newFunnel = false

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
        VStack(alignment: .leading, spacing: 8) {
            // Services list
            if filteredServices.isEmpty {
                EmptyServicesView()
            } else {
                ServiceListView(services: filteredServices)
            }

            Divider().padding(.horizontal, 14)

            // Quick serve for detected ports
            if !store.detectedPorts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    SectionLabel(text: "Quick Serve")
                    ForEach(store.detectedPorts, id: \.self) { port in
                        Button {
                            Task { await store.addServe(port: port, funnel: false) }
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.blue.opacity(0.5))
                                    .frame(width: 6, height: 6)
                                Text(":\(port)")
                                    .font(.system(size: 11, design: .monospaced))
                                Spacer()
                                Text("Serve")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.blue)
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 3)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().padding(.horizontal, 14)
            }

            // Add serve
            VStack(alignment: .leading, spacing: 6) {
                if showAddServe {
                    HStack(spacing: 8) {
                        TextField("Port", text: $newPort)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 80)

                        Toggle("Funnel", isOn: $newFunnel)
                            .font(.system(size: 10))
                            .toggleStyle(.checkbox)

                        Button("Add") {
                            guard let port = Int(newPort), port > 0, port <= 65535 else { return }
                            Task { await store.addServe(port: port, funnel: newFunnel) }
                            newPort = ""
                            newFunnel = false
                            showAddServe = false
                        }
                        .font(.system(size: 10))
                        .disabled(Int(newPort) == nil)

                        Button("Cancel") {
                            showAddServe = false
                            newPort = ""
                        }
                        .font(.system(size: 10))
                    }
                    .padding(.horizontal, 14)
                } else {
                    Button {
                        showAddServe = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 11))
                            Text("Add Serve...")
                                .font(.system(size: 11))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                }
            }

            // Reset all
            if !store.services.isEmpty {
                Button {
                    Task { await store.resetAllServes() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                        Text("Reset All Serves")
                            .font(.system(size: 10))
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red.opacity(0.7))
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 8)
    }
}
