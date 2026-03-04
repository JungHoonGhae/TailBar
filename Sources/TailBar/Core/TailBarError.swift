import Foundation

enum TailBarError: LocalizedError {
    // CLI errors
    case tailscaleNotFound
    case commandFailed(status: Int, stderr: String)

    // Local API errors
    case localAPIUnavailable(reason: String)
    case apiError(endpoint: String, statusCode: Int, message: String)

    // Operation errors
    case unsupportedOperation(String)

    // Connection errors
    case connectionLost
    case timeout

    var errorDescription: String? {
        switch self {
        case .tailscaleNotFound:
            return "Tailscale CLI not found. Is Tailscale installed?"
        case .commandFailed(let status, let stderr):
            return "Command failed (\(status)): \(stderr)"
        case .localAPIUnavailable(let reason):
            return "Local API unavailable: \(reason)"
        case .apiError(let endpoint, let statusCode, let message):
            return "API error on \(endpoint) (\(statusCode)): \(message)"
        case .unsupportedOperation(let op):
            return "\(op) is not supported by this client"
        case .connectionLost:
            return "Connection to Tailscale lost"
        case .timeout:
            return "Request timed out"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .tailscaleNotFound, .unsupportedOperation:
            return false
        case .commandFailed:
            return true
        case .localAPIUnavailable:
            return true
        case .apiError(_, let statusCode, _):
            return statusCode >= 500 || statusCode == 0
        case .connectionLost, .timeout:
            return true
        }
    }

    var userMessage: String {
        switch self {
        case .tailscaleNotFound:
            return "Tailscale is not installed. Please install Tailscale first."
        case .commandFailed(_, let stderr):
            return stderr.isEmpty ? "A Tailscale command failed." : stderr
        case .localAPIUnavailable:
            return "Cannot connect to Tailscale. Is it running?"
        case .apiError:
            return "Failed to communicate with Tailscale."
        case .unsupportedOperation(let op):
            return "\(op) requires the Local API client."
        case .connectionLost:
            return "Lost connection to Tailscale. Reconnecting..."
        case .timeout:
            return "Request timed out. Will retry."
        }
    }
}
