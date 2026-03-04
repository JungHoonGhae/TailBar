import AppKit
import SwiftUI

// MARK: - Header

struct HeaderCardView: View {
    let tailnetName: String
    let isConnected: Bool
    let selfNode: PeerStatus?
    let selfRelayCity: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Circle()
                    .fill(isConnected ? .green : .red)
                    .frame(width: 7, height: 7)
                Text(verbatim: tailnetName)
                    .font(.system(size: 13, weight: .medium))
                if let selfRelayCity {
                    Text(verbatim: "· \(selfRelayCity)")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            if let node = selfNode, let ip = node.TailscaleIPs?.first {
                Text(verbatim: ip)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - Services

struct ServiceListView: View {
    let services: [ServiceInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(services.enumerated()), id: \.element.id) { index, service in
                ServiceRowView(service: service)
                if index < services.count - 1 {
                    Divider()
                        .padding(.leading, 14)
                        .padding(.vertical, 3)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct ServiceRowView: View {
    let service: ServiceInfo
    @State private var copied = false

    private var alias: String? { AliasStore.alias(forPort: service.port) }

    private var healthColor: Color {
        switch service.isHealthy {
        case true: return .green
        case false: return .red
        default: return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Circle()
                    .fill(healthColor)
                    .frame(width: 6, height: 6)
                    .padding(.trailing, 6)

                if let alias {
                    Text(verbatim: alias)
                        .font(.system(size: 12, weight: .medium))
                    Text(verbatim: " :\(service.port)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                } else {
                    Text(verbatim: ":\(service.port)")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }

                Spacer().frame(minWidth: 8)

                Text(verbatim: service.isFunnel ? "Funnel" : "Tailnet")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(service.isFunnel ? .orange : .secondary)

                Spacer()

                // Open in browser
                Button {
                    if let url = URL(string: service.fullURL) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.gray.opacity(0.4))
                }
                .buttonStyle(.plain)

                Spacer().frame(width: 8)

                // Copy URL
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(service.fullURL, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundStyle(copied ? Color.green : Color.gray.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            if !service.handlers.isEmpty {
                ForEach(service.handlers) { handler in
                    HStack(spacing: 0) {
                        Text(verbatim: handler.path)
                            .frame(minWidth: 16, alignment: .leading)
                        Text(verbatim: " → ")
                            .foregroundStyle(.quaternary)
                        Text(verbatim: handler.target)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.system(size: 10, design: .monospaced))
                    .padding(.leading, 12)
                }
            }
        }
    }
}

// MARK: - Detected Ports

struct DetectedPortsView: View {
    let ports: [Int]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(ports, id: \.self) { port in
                HStack(spacing: 6) {
                    Circle()
                        .fill(.blue.opacity(0.5))
                        .frame(width: 6, height: 6)
                    Text(verbatim: ":\(port)")
                        .font(.system(size: 12, design: .monospaced))
                    Spacer()
                    Text(verbatim: "listening")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }
}

// MARK: - Utility Views

struct ErrorCardView: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .font(.system(size: 12))
            Text(verbatim: message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct EmptyServicesView: View {
    var body: some View {
        Text("No active serves")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
    }
}
