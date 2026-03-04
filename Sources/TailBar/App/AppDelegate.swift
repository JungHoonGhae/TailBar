import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store: TailscaleStore
    private let client: any TailscaleClientProtocol
    private var popoverController: PopoverController?
    private var statusItemController: StatusItemController?
    private var exitNodeManager: ExitNodeManager?
    private var connectionManager: ConnectionManager?
    private var notificationManager: NotificationManager?

    override init() {
        let client = Self.createClient()
        self.client = client
        self.store = TailscaleStore(client: client)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let exitNodeMgr = ExitNodeManager(client: client)
        self.exitNodeManager = exitNodeMgr

        // Notifications require a proper .app bundle; skip when running as bare executable
        if Bundle.main.bundleIdentifier != nil {
            let notifMgr = NotificationManager()
            notifMgr.requestPermissionIfNeeded()
            self.notificationManager = notifMgr
        }

        // Choose UI mode based on user preference
        let usePopover = UserDefaults.standard.object(forKey: "usePopoverUI") as? Bool ?? true
        if usePopover {
            popoverController = PopoverController(store: store, exitNodeManager: exitNodeMgr)
        } else {
            statusItemController = StatusItemController(store: store)
        }

        // Start connection manager (streaming with polling fallback)
        let connMgr = ConnectionManager(client: client, store: store)
        self.connectionManager = connMgr
        connMgr.start()

        // Auto-refresh as fallback alongside streaming
        store.startAutoRefresh()
    }

    private static func createClient() -> any TailscaleClientProtocol {
        do {
            _ = try LocalAPIConnection.discover()
            return LocalAPITailscaleClient()
        } catch {
            return CLITailscaleClient()
        }
    }
}
