import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    private var previousPeerOnlineState: [String: Bool] = [:]
    private var previousKeyExpiryWarnings: Set<String> = []
    private var hasRequestedPermission = false

    func requestPermissionIfNeeded() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func checkForChanges(status: TailscaleStatus?, previousStatus: TailscaleStatus?) {
        guard let status, let peers = status.peers else { return }

        // Peer online/offline changes
        for (id, peer) in peers {
            let isOnline = peer.Online ?? false
            let wasOnline = previousPeerOnlineState[id]

            if let wasOnline, wasOnline != isOnline {
                let name = peer.HostName ?? id
                if isOnline {
                    sendNotification(title: "Peer Online", body: "\(name) is now online")
                } else {
                    sendNotification(title: "Peer Offline", body: "\(name) went offline")
                }
            }

            previousPeerOnlineState[id] = isOnline
        }

        // Key expiry warnings
        checkKeyExpiryWarnings(status: status)
    }

    private func checkKeyExpiryWarnings(status: TailscaleStatus?) {
        guard let selfNode = status?.selfNode, let keyExpiryStr = selfNode.KeyExpiry else { return }

        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let expiryDate = isoFractional.date(from: keyExpiryStr) ?? ISO8601DateFormatter().date(from: keyExpiryStr) else { return }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 999
        let warningKey = "key-expiry-\(days)"

        if days <= 7 && !previousKeyExpiryWarnings.contains(warningKey) {
            previousKeyExpiryWarnings.insert(warningKey)
            if days <= 0 {
                sendNotification(title: "Key Expired", body: "Your Tailscale key has expired. Re-authenticate to continue.")
            } else {
                sendNotification(title: "Key Expiring Soon", body: "Your Tailscale key expires in \(days) day\(days == 1 ? "" : "s").")
            }
        }
    }

    func notifyExitNodeDisconnected(nodeName: String) {
        sendNotification(title: "Exit Node Disconnected", body: "Disconnected from exit node: \(nodeName)")
    }

    func notifyServiceHealthChange(port: Int, isHealthy: Bool) {
        let status = isHealthy ? "healthy" : "unhealthy"
        sendNotification(title: "Service Health", body: "Service on port \(port) is now \(status)")
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
