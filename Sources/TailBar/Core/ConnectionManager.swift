import Foundation
import Observation

/// Manages the connection to Tailscale via watch-ipn-bus streaming,
/// with automatic reconnection and fallback to polling.
@MainActor @Observable
final class ConnectionManager {
    var connectionState: ConnectionState = .disconnected

    private let client: any TailscaleClientProtocol
    private let store: TailscaleStore
    private let retryPolicy: RetryPolicy
    private var streamTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var reconnectAttempt = 0

    init(client: any TailscaleClientProtocol, store: TailscaleStore, retryPolicy: RetryPolicy = .default) {
        self.client = client
        self.store = store
        self.retryPolicy = retryPolicy
    }

    func start() {
        startStreaming()
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        pollingTask?.cancel()
        pollingTask = nil
        connectionState = .disconnected
    }

    // MARK: - Streaming

    private func startStreaming() {
        streamTask?.cancel()
        connectionState = reconnectAttempt > 0 ? .reconnecting(attempt: reconnectAttempt) : .connecting

        streamTask = Task { [weak self] in
            guard let self else { return }

            do {
                let stream = try await client.watchIPNBus()
                self.connectionState = .connected
                self.reconnectAttempt = 0
                self.stopPolling()

                for try await notification in stream {
                    guard !Task.isCancelled else { break }
                    await self.handleNotification(notification)
                }

                // Stream ended normally
                if !Task.isCancelled {
                    self.handleStreamEnded()
                }
            } catch is CancellationError {
                // Intentional cancellation, do nothing
            } catch let error as TailBarError where !error.isRetryable {
                // Non-retryable error — fall back to polling
                self.connectionState = .error(error.userMessage)
                self.startPollingFallback()
            } catch {
                // Retryable error — attempt reconnect
                self.handleStreamEnded()
            }
        }
    }

    private func handleStreamEnded() {
        guard !Task.isCancelled else { return }

        if retryPolicy.shouldRetry(attempt: reconnectAttempt) {
            reconnectAttempt += 1
            connectionState = .reconnecting(attempt: reconnectAttempt)

            let delay = retryPolicy.delay(for: reconnectAttempt - 1)
            streamTask = Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.startStreaming()
            }
        } else {
            connectionState = .error("Max reconnect attempts reached")
            startPollingFallback()
        }
    }

    private func handleNotification(_ notification: IPNBusNotification) async {
        // Refresh the full status when we get a state change or net map update
        if notification.State != nil || notification.NetMap != nil || notification.Prefs != nil {
            await store.refresh()
        }

        if let errMsg = notification.ErrMessage, !errMsg.isEmpty {
            store.error = errMsg
        }
    }

    // MARK: - Polling Fallback

    private func startPollingFallback() {
        stopPolling()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.store.refresh()
                try? await Task.sleep(for: .seconds(10))
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
}
