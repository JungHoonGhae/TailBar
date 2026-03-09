import SwiftUI

@MainActor
struct ExitNodesTab: View {
    let exitNodeManager: ExitNodeManager
    let searchText: String

    private var filteredNodes: [ExitNodeInfo] {
        guard !searchText.isEmpty else { return exitNodeManager.exitNodes }
        let query = searchText.lowercased()
        return exitNodeManager.exitNodes.filter {
            $0.hostName.lowercased().contains(query) ||
            $0.dnsName.lowercased().contains(query) ||
            ($0.city?.lowercased().contains(query) ?? false) ||
            ($0.country?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if exitNodeManager.isLoading {
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Switching exit node...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }

            ExitNodeSectionView(
                exitNodes: filteredNodes,
                currentExitNodeID: exitNodeManager.currentExitNodeID,
                suggestedNode: exitNodeManager.suggestedNode,
                onSelect: { id in
                    Task { try? await exitNodeManager.selectExitNode(id: id) }
                },
                onClear: {
                    Task { try? await exitNodeManager.clearExitNode() }
                }
            )
        }
        .padding(.vertical, 8)
    }
}
