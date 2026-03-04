import Foundation
import Observation

@MainActor @Observable
final class ExitNodeManager {
    var exitNodes: [ExitNodeInfo] = []
    var currentExitNodeID: String?
    var suggestedNode: ExitNodeSuggestion?
    var isLoading = false

    private let client: any TailscaleClientProtocol

    init(client: any TailscaleClientProtocol) {
        self.client = client
    }

    func refresh(from status: TailscaleStatus?) async {
        guard let status, let peers = status.peers else {
            exitNodes = []
            return
        }

        // Find current exit node
        currentExitNodeID = peers.values.first(where: { $0.ExitNode == true })?.ID

        // Build exit node list from peers that advertise ExitNodeOption
        exitNodes = peers.values
            .filter { $0.ExitNodeOption == true }
            .map { peer in
                ExitNodeInfo(
                    id: peer.ID ?? "",
                    hostName: peer.HostName ?? "Unknown",
                    dnsName: peer.DNSName ?? "",
                    isOnline: peer.Online ?? false,
                    isCurrentExitNode: peer.ExitNode ?? false,
                    country: nil,
                    city: peer.Relay.flatMap { NodeInfo.relayCity(for: $0) }
                )
            }
            .sorted { a, b in
                if a.isOnline != b.isOnline { return a.isOnline }
                return a.hostName < b.hostName
            }

        // Fetch suggestion
        do {
            suggestedNode = try await client.suggestExitNode()
        } catch {
            suggestedNode = nil
        }
    }

    func selectExitNode(id: String) async throws {
        isLoading = true
        defer { isLoading = false }
        try await client.updatePrefs(PrefsPatch(ExitNodeID: id, ExitNodeAllowLANAccess: nil))
    }

    func clearExitNode() async throws {
        isLoading = true
        defer { isLoading = false }
        try await client.updatePrefs(PrefsPatch(ExitNodeID: "", ExitNodeAllowLANAccess: nil))
    }

    func setAllowLANAccess(_ allow: Bool) async throws {
        try await client.updatePrefs(PrefsPatch(ExitNodeID: nil, ExitNodeAllowLANAccess: allow))
    }
}

struct ExitNodeInfo: Identifiable, Sendable {
    let id: String
    let hostName: String
    let dnsName: String
    let isOnline: Bool
    let isCurrentExitNode: Bool
    let country: String?
    let city: String?

    var locationLabel: String {
        [city, country].compactMap { $0 }.joined(separator: ", ")
    }
}
