import SwiftUI

enum PopoverTab: Int, CaseIterable {
    case overview = 0
    case peers
    case services
    case exitNodes

    var label: String {
        switch self {
        case .overview: return "Overview"
        case .peers: return "Peers"
        case .services: return "Services"
        case .exitNodes: return "Exit Nodes"
        }
    }

    var icon: String {
        switch self {
        case .overview: return "gauge.with.dots.needle.bottom.50percent"
        case .peers: return "laptopcomputer.and.iphone"
        case .services: return "server.rack"
        case .exitNodes: return "arrow.triangle.branch"
        }
    }
}

struct TailBarPopoverView: View {
    @Bindable var store: TailscaleStore
    let exitNodeManager: ExitNodeManager
    let onClose: () -> Void

    @State private var selectedTab: PopoverTab = .overview
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            PopoverHeaderView(
                tailnetName: store.tailnetName,
                isConnected: store.isConnected,
                selfNode: store.selfNode,
                selfRelayCity: store.selfRelayCity
            )

            Divider()

            // Search bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isSearchFocused)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Tab bar
            HStack(spacing: 0) {
                ForEach(PopoverTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.label)
                                .font(.system(size: 9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Error banner
            if let error = store.error {
                ErrorCardView(message: error)
                Divider()
            }

            // Tab content
            ScrollView {
                Group {
                    switch selectedTab {
                    case .overview:
                        OverviewTab(store: store, searchText: searchText)
                    case .peers:
                        PeersTab(store: store, searchText: searchText)
                    case .services:
                        ServicesTab(store: store, searchText: searchText)
                    case .exitNodes:
                        ExitNodesTab(
                            exitNodeManager: exitNodeManager,
                            searchText: searchText
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // Footer
            PopoverFooterView(
                isLoading: store.isLoading,
                onRefresh: { Task { await store.refresh() } },
                onSettings: { openSettings() },
                onQuit: { NSApp.terminate(nil) }
            )
        }
        .frame(width: 360)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(KeyboardShortcutHandler(
            onRefresh: { Task { await store.refresh() } },
            onSearch: { isSearchFocused = true },
            onClose: onClose,
            onTabSelect: { selectedTab = $0 }
        ))
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(withTitle: "Settings...")?.performAction()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }
}

struct PopoverHeaderView: View {
    let tailnetName: String
    let isConnected: Bool
    let selfNode: PeerStatus?
    let selfRelayCity: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(tailnetName)
                        .font(.system(size: 13, weight: .semibold))
                }
                HStack(spacing: 8) {
                    if let node = selfNode, let ip = node.TailscaleIPs?.first {
                        Text(ip)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if let city = selfRelayCity {
                        Text("via \(city)")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct PopoverFooterView: View {
    let isLoading: Bool
    let onRefresh: () -> Void
    let onSettings: () -> Void
    let onQuit: () -> Void

    var body: some View {
        HStack {
            Button(action: onRefresh) {
                HStack(spacing: 4) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    Text(isLoading ? "Refreshing..." : "Refresh")
                        .font(.system(size: 10))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(isLoading)

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gear")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button(action: onQuit) {
                Image(systemName: "power")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.leading, 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

private extension NSMenuItem {
    func performAction() {
        guard let action else { return }
        _ = target?.perform(action, with: self)
    }
}

// MARK: - Keyboard Shortcuts

struct KeyboardShortcutHandler: NSViewRepresentable {
    let onRefresh: () -> Void
    let onSearch: () -> Void
    let onClose: () -> Void
    let onTabSelect: (PopoverTab) -> Void

    func makeNSView(context: Context) -> KeyboardEventView {
        let view = KeyboardEventView()
        view.handler = self
        return view
    }

    func updateNSView(_ nsView: KeyboardEventView, context: Context) {
        nsView.handler = self
    }

    final class KeyboardEventView: NSView {
        var handler: KeyboardShortcutHandler?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            let cmd = event.modifierFlags.contains(.command)

            if event.keyCode == 53 { // Escape
                handler?.onClose()
                return
            }

            guard cmd, let chars = event.charactersIgnoringModifiers else {
                super.keyDown(with: event)
                return
            }

            switch chars {
            case "r": handler?.onRefresh()
            case "f": handler?.onSearch()
            case "1": handler?.onTabSelect(.overview)
            case "2": handler?.onTabSelect(.peers)
            case "3": handler?.onTabSelect(.services)
            case "4": handler?.onTabSelect(.exitNodes)
            default: super.keyDown(with: event)
            }
        }
    }
}
