import SwiftUI

struct ExitNodeSectionView: View {
    let exitNodes: [ExitNodeInfo]
    let currentExitNodeID: String?
    let suggestedNode: ExitNodeSuggestion?
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let currentID = currentExitNodeID,
               let current = exitNodes.first(where: { $0.id == currentID }) {
                CurrentExitNodeView(node: current, onClear: onClear)
                Divider().padding(.vertical, 2)
            }

            if let suggestion = suggestedNode, let name = suggestion.Name {
                SuggestedExitNodeView(
                    name: name,
                    location: suggestion.Location,
                    onSelect: { if let id = suggestion.ID { onSelect(id) } }
                )
                Divider().padding(.vertical, 2)
            }

            if exitNodes.isEmpty {
                Text("No exit nodes available")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(exitNodes) { node in
                    ExitNodeRowView(
                        node: node,
                        isSelected: node.id == currentExitNodeID,
                        onSelect: { onSelect(node.id) }
                    )
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}

struct CurrentExitNodeView: View {
    let node: ExitNodeInfo
    let onClear: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Exit Node Active")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange)
                Text(node.hostName)
                    .font(.system(size: 12, weight: .medium))
                if !node.locationLabel.isEmpty {
                    Text(node.locationLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Disconnect") { onClear() }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(.orange)
        }
    }
}

struct SuggestedExitNodeView: View {
    let name: String
    let location: ExitNodeLocation?
    let onSelect: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text("Suggested")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.blue)
                Text(name)
                    .font(.system(size: 11))
                if let city = location?.City {
                    Text(city)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Use") { onSelect() }
                .font(.system(size: 10))
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
        }
    }
}

struct ExitNodeRowView: View {
    let node: ExitNodeInfo
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Circle()
                    .fill(node.isOnline ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                VStack(alignment: .leading, spacing: 0) {
                    Text(node.hostName)
                        .font(.system(size: 11))
                        .foregroundStyle(node.isOnline ? .primary : .tertiary)
                    if !node.locationLabel.isEmpty {
                        Text(node.locationLabel)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!node.isOnline)
        .padding(.vertical, 2)
    }
}
