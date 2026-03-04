import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = TailscaleStore()
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItemController = StatusItemController(store: store)
        store.startAutoRefresh()
    }
}
