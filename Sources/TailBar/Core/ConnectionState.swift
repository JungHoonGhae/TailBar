import Foundation

enum ConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case error(String)
    case reconnecting(attempt: Int)

    var isUsable: Bool {
        switch self {
        case .connected: return true
        default: return false
        }
    }

    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return "Error: \(msg)"
        case .reconnecting(let attempt): return "Reconnecting (\(attempt))..."
        }
    }
}
