import Foundation

/// Protocol defining all Tailscale client operations.
/// Enables dependency injection and testability via mock implementations.
protocol TailscaleClientProtocol: Sendable {
    // MARK: - Status
    func fetchStatus() async throws -> TailscaleStatus
    func fetchServeConfig() async throws -> ServeConfig

    // MARK: - Serve Management
    func addServe(port: Int) async throws
    func removeServe(port: Int) async throws
    func resetServes() async throws

    // MARK: - Funnel Management
    func enableFunnel(port: Int) async throws
    func disableFunnel(port: Int) async throws

    // MARK: - Network
    func ping(hostname: String) async throws -> String
    func checkPort(_ port: Int) async -> Bool

    // MARK: - Preferences
    func fetchPrefs() async throws -> TailscalePrefs
    func updatePrefs(_ update: PrefsPatch) async throws

    // MARK: - Exit Node
    func suggestExitNode() async throws -> ExitNodeSuggestion

    // MARK: - Profiles
    func fetchProfiles() async throws -> [TailscaleProfile]
    func switchProfile(id: String) async throws

    // MARK: - Taildrop
    func fetchFileTargets() async throws -> [FileTarget]
    func sendFile(to nodeID: String, fileName: String, data: Data) async throws

    // MARK: - Streaming
    func watchIPNBus() async throws -> AsyncThrowingStream<IPNBusNotification, Error>
}

// Default implementations for optional/advanced features so existing clients
// can conform without implementing everything immediately.
extension TailscaleClientProtocol {
    func fetchPrefs() async throws -> TailscalePrefs {
        throw TailBarError.unsupportedOperation("fetchPrefs")
    }

    func updatePrefs(_ update: PrefsPatch) async throws {
        throw TailBarError.unsupportedOperation("updatePrefs")
    }

    func suggestExitNode() async throws -> ExitNodeSuggestion {
        throw TailBarError.unsupportedOperation("suggestExitNode")
    }

    func fetchProfiles() async throws -> [TailscaleProfile] {
        throw TailBarError.unsupportedOperation("fetchProfiles")
    }

    func switchProfile(id: String) async throws {
        throw TailBarError.unsupportedOperation("switchProfile")
    }

    func fetchFileTargets() async throws -> [FileTarget] {
        throw TailBarError.unsupportedOperation("fetchFileTargets")
    }

    func sendFile(to nodeID: String, fileName: String, data: Data) async throws {
        throw TailBarError.unsupportedOperation("sendFile")
    }

    func watchIPNBus() async throws -> AsyncThrowingStream<IPNBusNotification, Error> {
        throw TailBarError.unsupportedOperation("watchIPNBus")
    }
}
