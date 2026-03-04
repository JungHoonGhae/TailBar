import AppKit
import SwiftUI
import Observation

@MainActor
final class PopoverController: NSObject {
    private let store: TailscaleStore
    private let exitNodeManager: ExitNodeManager
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?

    init(store: TailscaleStore, exitNodeManager: ExitNodeManager) {
        self.store = store
        self.exitNodeManager = exitNodeManager
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        super.init()

        setupPopover()
        setupStatusButton()
        observeStoreChanges()
    }

    private func setupPopover() {
        let popoverView = TailBarPopoverView(
            store: store,
            exitNodeManager: exitNodeManager,
            onClose: { [weak self] in self?.closePopover() }
        )
        popover.contentViewController = NSHostingController(rootView: popoverView)
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 480)
    }

    private func setupStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover)
        updateIcon()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // Close on outside click
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }

        // Refresh on open
        Task { await store.refresh() }
    }

    private func closePopover() {
        popover.performClose(nil)
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

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

    private func observeStoreChanges() {
        withObservationTracking {
            _ = store.isConnected
            _ = store.serviceCount
            _ = store.error
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateIcon()
                self?.observeStoreChanges()
            }
        }
    }
}
