import Foundation
@testable import TailBar

final class MockTailscaleClient: TailscaleClientProtocol, @unchecked Sendable {
    // Configurable responses
    var statusResult: Result<TailscaleStatus, Error> = .success(MockTailscaleClient.defaultStatus)
    var serveConfigResult: Result<ServeConfig, Error> = .success(ServeConfig(TCP: nil, Web: nil, AllowFunnel: nil))
    var checkPortResult: Bool = false
    var pingResult: Result<String, Error> = .success("pong")
    var prefsResult: Result<TailscalePrefs, Error> = .failure(TailBarError.unsupportedOperation("fetchPrefs"))
    var suggestExitNodeResult: Result<ExitNodeSuggestion, Error> = .failure(TailBarError.unsupportedOperation("suggestExitNode"))
    var profilesResult: Result<[TailscaleProfile], Error> = .failure(TailBarError.unsupportedOperation("fetchProfiles"))
    var fileTargetsResult: Result<[FileTarget], Error> = .failure(TailBarError.unsupportedOperation("fetchFileTargets"))

    // Call tracking
    var fetchStatusCallCount = 0
    var fetchServeConfigCallCount = 0
    var addServeCallCount = 0
    var removeServeCallCount = 0
    var resetServesCallCount = 0
    var enableFunnelCallCount = 0
    var disableFunnelCallCount = 0
    var lastAddedPort: Int?
    var lastRemovedPort: Int?
    var lastFunnelPort: Int?

    func fetchStatus() async throws -> TailscaleStatus {
        fetchStatusCallCount += 1
        return try statusResult.get()
    }

    func fetchServeConfig() async throws -> ServeConfig {
        fetchServeConfigCallCount += 1
        return try serveConfigResult.get()
    }

    func addServe(port: Int) async throws {
        addServeCallCount += 1
        lastAddedPort = port
    }

    func removeServe(port: Int) async throws {
        removeServeCallCount += 1
        lastRemovedPort = port
    }

    func resetServes() async throws {
        resetServesCallCount += 1
    }

    func enableFunnel(port: Int) async throws {
        enableFunnelCallCount += 1
        lastFunnelPort = port
    }

    func disableFunnel(port: Int) async throws {
        disableFunnelCallCount += 1
        lastFunnelPort = port
    }

    func ping(hostname: String) async throws -> String {
        try pingResult.get()
    }

    func checkPort(_ port: Int) async -> Bool {
        checkPortResult
    }

    func fetchPrefs() async throws -> TailscalePrefs {
        try prefsResult.get()
    }

    func updatePrefs(_ update: PrefsPatch) async throws {}

    func suggestExitNode() async throws -> ExitNodeSuggestion {
        try suggestExitNodeResult.get()
    }

    func fetchProfiles() async throws -> [TailscaleProfile] {
        try profilesResult.get()
    }

    func switchProfile(id: String) async throws {}

    func fetchFileTargets() async throws -> [FileTarget] {
        try fileTargetsResult.get()
    }

    func sendFile(to nodeID: String, fileName: String, data: Data) async throws {}

    func watchIPNBus() async throws -> AsyncThrowingStream<IPNBusNotification, Error> {
        AsyncThrowingStream { $0.finish() }
    }

    // MARK: - Default Fixtures

    static let defaultStatus = TailscaleStatus(
        version: "1.60.0",
        backendState: "Running",
        tun: true,
        tailscaleIPs: ["100.64.0.1"],
        selfNode: PeerStatus(
            ID: "self-node-id",
            HostName: "my-mac",
            DNSName: "my-mac.tail12345.ts.net.",
            OS: "macOS",
            TailscaleIPs: ["100.64.0.1"],
            Online: true,
            ExitNode: false,
            ExitNodeOption: false,
            Active: true,
            LastSeen: nil,
            Relay: "tok",
            CurAddr: nil,
            RxBytes: 1024,
            TxBytes: 2048,
            KeyExpiry: "2025-12-31T00:00:00Z"
        ),
        peers: [
            "peer-1": PeerStatus(
                ID: "peer-1",
                HostName: "server-1",
                DNSName: "server-1.tail12345.ts.net.",
                OS: "linux",
                TailscaleIPs: ["100.64.0.2"],
                Online: true,
                ExitNode: false,
                ExitNodeOption: true,
                Active: true,
                LastSeen: "2025-01-01T12:00:00Z",
                Relay: "sfo",
                CurAddr: "192.168.1.100:41641",
                RxBytes: 4096,
                TxBytes: 8192,
                KeyExpiry: "2025-06-15T00:00:00Z"
            ),
        ],
        currentTailnet: TailnetInfo(
            Name: "example@gmail.com",
            MagicDNSSuffix: "tail12345.ts.net",
            MagicDNSEnabled: true
        ),
        magicDNSSuffix: "tail12345.ts.net",
        certDomains: ["my-mac.tail12345.ts.net"]
    )

    static let defaultServeConfig = ServeConfig(
        TCP: ["443": TCPPortConfig(HTTPS: true, TCPForward: nil, TerminateTLS: nil)],
        Web: [
            "my-mac.tail12345.ts.net:443": WebHostConfig(
                Handlers: ["/": HandlerEntry(Proxy: "http://127.0.0.1:3000", Path: nil, Text: nil)]
            ),
        ],
        AllowFunnel: ["my-mac.tail12345.ts.net:443": false]
    )
}
