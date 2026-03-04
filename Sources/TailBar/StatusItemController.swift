import AppKit
import SwiftUI
import Observation

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let store: TailscaleStore
    private let statusItem: NSStatusItem
    private let menu: NSMenu
    private static let menuWidth: CGFloat = 320

    init(store: TailscaleStore) {
        self.store = store
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.menu = NSMenu()
        super.init()

        menu.delegate = self
        statusItem.menu = menu
        updateIcon()
        observeStoreChanges()
    }

    // MARK: - Icon

    private func updateIcon() {
        guard let button = statusItem.button else { return }
        let symbolName = store.isConnected ? "network" : "network.slash"
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "TailBar")?
            .withSymbolConfiguration(config)
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading
        let count = store.serviceCount
        button.title = count > 0 ? " \(count)" : ""
    }

    // MARK: - Observation

    private func observeStoreChanges() {
        withObservationTracking {
            _ = store.isConnected
            _ = store.serviceCount
            _ = store.error
            _ = store.isLoading
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateIcon()
                self?.observeStoreChanges()
            }
        }
    }

    // MARK: - NSMenuDelegate

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    // MARK: - Menu Construction

    private func rebuildMenu() {
        menu.removeAllItems()

        addHeaderSection()
        menu.addItem(.separator())

        if let error = store.error {
            addErrorSection(error)
            menu.addItem(.separator())
        }

        addServicesSection()
        addDetectedPortsSection()
        addServeManagementSection()
        addFooterSection()
    }

    private func addHeaderSection() {
        let view = HeaderCardView(
            tailnetName: store.tailnetName,
            isConnected: store.isConnected,
            selfNode: store.selfNode,
            selfRelayCity: store.selfRelayCity
        )
        menu.addItem(MenuHostingItem(view, width: Self.menuWidth))
    }

    private func addErrorSection(_ error: String) {
        menu.addItem(MenuHostingItem(ErrorCardView(message: error), width: Self.menuWidth))
    }

    private func addServicesSection() {
        let services = store.services
        if services.isEmpty {
            menu.addItem(sectionHeader("Serves"))
            menu.addItem(MenuHostingItem(EmptyServicesView(), width: Self.menuWidth))
        } else {
            menu.addItem(sectionHeader("Serves (\(services.count))"))
            menu.addItem(MenuHostingItem(ServiceListView(services: services), width: Self.menuWidth))
        }
        menu.addItem(.separator())
    }

    private func addDetectedPortsSection() {
        let ports = store.detectedPorts
        guard !ports.isEmpty else { return }
        menu.addItem(sectionHeader("Detected (\(ports.count))"))
        menu.addItem(MenuHostingItem(DetectedPortsView(ports: ports), width: Self.menuWidth))
        menu.addItem(.separator())
    }

    // MARK: - Serve Management

    private func addServeManagementSection() {
        let services = store.services

        let addItem = NSMenuItem(title: "Add Serve…", action: #selector(addServe), keyEquivalent: "n")
        addItem.target = self
        menu.addItem(addItem)

        // Quick Serve detected ports
        if !store.detectedPorts.isEmpty {
            let quickMenu = NSMenu()
            for port in store.detectedPorts {
                let item = NSMenuItem(
                    title: ":\(port)",
                    action: #selector(quickServe(_:)), keyEquivalent: ""
                )
                item.target = self
                item.tag = port
                quickMenu.addItem(item)
            }
            let quickItem = NSMenuItem(title: "Quick Serve", action: nil, keyEquivalent: "")
            quickItem.submenu = quickMenu
            menu.addItem(quickItem)
        }

        if !services.isEmpty {
            // Toggle Funnel
            let funnelMenu = NSMenu()
            for service in services {
                let item = NSMenuItem(
                    title: serviceLabel(service),
                    action: #selector(toggleFunnel(_:)), keyEquivalent: ""
                )
                item.target = self
                item.tag = service.port
                item.state = service.isFunnel ? .on : .off
                funnelMenu.addItem(item)
            }
            let funnelItem = NSMenuItem(title: "Toggle Funnel", action: nil, keyEquivalent: "")
            funnelItem.submenu = funnelMenu
            menu.addItem(funnelItem)

            // Remove Serve
            let removeMenu = NSMenu()
            for service in services {
                let item = NSMenuItem(
                    title: serviceLabel(service),
                    action: #selector(removeServe(_:)), keyEquivalent: ""
                )
                item.target = self
                item.tag = service.port
                removeMenu.addItem(item)
            }
            removeMenu.addItem(.separator())
            let resetAll = NSMenuItem(title: "Reset All…", action: #selector(resetAllServes), keyEquivalent: "")
            resetAll.target = self
            removeMenu.addItem(resetAll)

            let removeItem = NSMenuItem(title: "Remove Serve", action: nil, keyEquivalent: "")
            removeItem.submenu = removeMenu
            menu.addItem(removeItem)

            // Edit Alias
            let aliasMenu = NSMenu()
            for service in services {
                let item = NSMenuItem(
                    title: serviceLabel(service),
                    action: #selector(editServiceAlias(_:)), keyEquivalent: ""
                )
                item.target = self
                item.tag = service.port
                aliasMenu.addItem(item)
            }
            let aliasItem = NSMenuItem(title: "Edit Alias", action: nil, keyEquivalent: "")
            aliasItem.submenu = aliasMenu
            menu.addItem(aliasItem)
        }

        menu.addItem(.separator())
    }

    private func addFooterSection() {
        let refreshItem = NSMenuItem(
            title: store.isLoading ? "Refreshing…" : "Refresh Now",
            action: #selector(refreshNow), keyEquivalent: "r"
        )
        refreshItem.target = self
        refreshItem.isEnabled = !store.isLoading
        menu.addItem(refreshItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit TailBar", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> NSMenuItem {
        let item = NSMenuItem()
        item.attributedTitle = NSAttributedString(
            string: "  \(text)",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.tertiaryLabelColor,
            ]
        )
        item.isEnabled = false
        return item
    }

    private func serviceLabel(_ service: ServiceInfo) -> String {
        let alias = AliasStore.alias(forPort: service.port)
        return alias != nil ? "\(alias!) (:\(service.port))" : ":\(service.port)"
    }

    // MARK: - Serve Actions

    @objc private func addServe() {
        let alert = NSAlert()
        alert.messageText = "Add Tailscale Serve"
        alert.informativeText = "Expose a local port to your tailnet via HTTPS."
        alert.addButton(withTitle: "Serve")
        alert.addButton(withTitle: "Cancel")

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 54))

        let portLabel = NSTextField(labelWithString: "Local port:")
        portLabel.frame = NSRect(x: 0, y: 30, width: 80, height: 20)
        container.addSubview(portLabel)

        let portField = NSTextField(frame: NSRect(x: 85, y: 28, width: 190, height: 24))
        portField.placeholderString = "e.g., 3000, 8080"
        container.addSubview(portField)

        let funnelCheck = NSButton(
            checkboxWithTitle: "Also enable Funnel (public internet access)",
            target: nil, action: nil
        )
        funnelCheck.frame = NSRect(x: 0, y: 0, width: 280, height: 20)
        container.addSubview(funnelCheck)

        alert.accessoryView = container
        alert.window.initialFirstResponder = portField

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let portStr = portField.stringValue.trimmingCharacters(in: .whitespaces)
        guard let port = Int(portStr), port > 0, port <= 65535 else {
            showError("Invalid port number. Enter a number between 1 and 65535.")
            return
        }
        let funnel = funnelCheck.state == .on
        Task { await store.addServe(port: port, funnel: funnel) }
    }

    @objc private func quickServe(_ sender: NSMenuItem) {
        let port = sender.tag
        Task { await store.addServe(port: port, funnel: false) }
    }

    @objc private func removeServe(_ sender: NSMenuItem) {
        let port = sender.tag
        let label = serviceLabel(ServiceInfo(
            id: "", port: port, isHTTPS: true, isFunnel: false,
            handlers: [], fullURL: "", isHealthy: nil
        ))
        let alert = NSAlert()
        alert.messageText = "Remove serve on \(label)?"
        alert.informativeText = "This will stop serving on this port."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await store.removeServe(port: port) }
    }

    @objc private func toggleFunnel(_ sender: NSMenuItem) {
        let port = sender.tag
        let currentlyOn = sender.state == .on
        Task { await store.toggleFunnel(port: port, enable: !currentlyOn) }
    }

    @objc private func resetAllServes() {
        let alert = NSAlert()
        alert.messageText = "Reset All Serves?"
        alert.informativeText = "This will remove all serve configurations on this device."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await store.resetAllServes() }
    }

    // MARK: - Alias Editing

    @objc private func editServiceAlias(_ sender: NSMenuItem) {
        let port = sender.tag
        let alert = NSAlert()
        alert.messageText = "Set alias for :\(port)"
        alert.informativeText = "Leave empty to remove the alias."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        input.stringValue = AliasStore.alias(forPort: port) ?? ""
        input.placeholderString = "e.g., Web App, API Server"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let value = input.stringValue.trimmingCharacters(in: .whitespaces)
        AliasStore.setAlias(value.isEmpty ? nil : value, forPort: port)
    }

    // MARK: - General Actions

    @objc private func refreshNow() {
        Task { await store.refresh() }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.mainMenu?.items.first?.submenu?.item(withTitle: "Settings…")?.performAction()
        } else {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

private extension NSMenuItem {
    func performAction() {
        guard let action else { return }
        _ = target?.perform(action, with: self)
    }
}
