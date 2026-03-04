import SwiftUI

struct PeersTab: View {
    let store: TailscaleStore
    let searchText: String

    private var allNodes: [NodeInfo] {
        guard let status = store.status else { return [] }
        var nodes: [NodeInfo] = []

        // Add self node
        if let selfNode = status.selfNode {
            nodes.append(makeNodeInfo(from: selfNode, isSelf: true))
        }

        // Add peers
        if let peers = status.peers {
            for (_, peer) in peers.sorted(by: { ($0.value.HostName ?? "") < ($1.value.HostName ?? "") }) {
                nodes.append(makeNodeInfo(from: peer, isSelf: false))
            }
        }

        return nodes
    }

    private var filteredNodes: [NodeInfo] {
        guard !searchText.isEmpty else { return allNodes }
        let query = searchText.lowercased()
        return allNodes.filter {
            $0.hostName.lowercased().contains(query) ||
            $0.dnsName.lowercased().contains(query) ||
            $0.displayName.lowercased().contains(query) ||
            $0.os.lowercased().contains(query) ||
            $0.tailscaleIPs.contains(where: { $0.contains(query) })
        }
    }

    private var onlineNodes: [NodeInfo] {
        filteredNodes.filter { $0.isOnline }
    }

    private var offlineNodes: [NodeInfo] {
        filteredNodes.filter { !$0.isOnline }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !onlineNodes.isEmpty {
                SectionLabel(text: "Online (\(onlineNodes.count))")
                PeerListView(nodes: onlineNodes, onPing: { _ in })
            }

            if !offlineNodes.isEmpty {
                if !onlineNodes.isEmpty {
                    Divider().padding(.horizontal, 14)
                }
                SectionLabel(text: "Offline (\(offlineNodes.count))")
                PeerListView(nodes: offlineNodes, onPing: { _ in })
            }

            if filteredNodes.isEmpty {
                Text("No peers found")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
        }
        .padding(.vertical, 8)
    }

    private func makeNodeInfo(from peer: PeerStatus, isSelf: Bool) -> NodeInfo {
        let dnsName = peer.DNSName ?? ""
        let dnsLabel = dnsName.components(separatedBy: ".").first ?? peer.HostName ?? ""

        var keyExpiry: Date?
        if let expiryStr = peer.KeyExpiry {
            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            keyExpiry = isoFractional.date(from: expiryStr) ?? ISO8601DateFormatter().date(from: expiryStr)
        }

        return NodeInfo(
            id: peer.ID ?? UUID().uuidString,
            hostName: peer.HostName ?? "Unknown",
            dnsName: dnsName,
            dnsLabel: dnsLabel,
            os: peer.OS ?? "",
            tailscaleIPs: peer.TailscaleIPs ?? [],
            isOnline: peer.Online ?? false,
            isSelf: isSelf,
            isExitNode: peer.ExitNode ?? false,
            isExitNodeOption: peer.ExitNodeOption ?? false,
            lastSeen: peer.LastSeen,
            relay: peer.Relay,
            curAddr: peer.CurAddr,
            keyExpiry: keyExpiry,
            rxBytes: peer.RxBytes,
            txBytes: peer.TxBytes
        )
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 14)
    }
}
