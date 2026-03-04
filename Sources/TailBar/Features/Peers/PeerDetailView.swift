import SwiftUI

struct PeerListView: View {
    let nodes: [NodeInfo]
    let onPing: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                PeerRowView(node: node, onPing: { onPing(node.dnsName) })
                if index < nodes.count - 1 {
                    Divider()
                        .padding(.leading, 14)
                        .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct PeerRowView: View {
    let node: NodeInfo
    let onPing: () -> Void
    @State private var copiedIP = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(node.isOnline ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)

                Image(systemName: node.osIcon)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(node.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)

                if node.isSelf {
                    Text("(you)")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if let conn = node.connectionInfo {
                    Text(conn)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 4) {
                if let ip = node.tailscaleIPs.first {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(ip, forType: .string)
                        copiedIP = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copiedIP = false }
                    } label: {
                        HStack(spacing: 2) {
                            Text(ip)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(.tertiary)
                            Image(systemName: copiedIP ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 8))
                                .foregroundStyle(copiedIP ? .green : Color.gray.opacity(0.3))
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if let warning = node.keyExpiryWarning {
                    Text(warning)
                        .font(.system(size: 9))
                        .foregroundStyle(.orange)
                }

                if !node.isOnline, let lastSeen = node.formattedLastSeen {
                    Text(lastSeen)
                        .font(.system(size: 9))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.leading, 12)

            // Traffic stats
            if node.isOnline {
                HStack(spacing: 8) {
                    if let rx = node.rxBytes {
                        Label(formatBytes(rx), systemImage: "arrow.down")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                    if let tx = node.txBytes {
                        Label(formatBytes(tx), systemImage: "arrow.up")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.leading, 12)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

