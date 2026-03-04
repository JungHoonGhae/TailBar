import Foundation
import Observation

@MainActor @Observable
final class TailscaleStore {
    var status: TailscaleStatus?
    var serveConfig: ServeConfig?
    var isLoading = false
    var error: String?
    var serviceHealth: [Int: Bool] = [:]
    var detectedPorts: [Int] = []

    private let client: any TailscaleClientProtocol
    private var refreshTask: Task<Void, Never>?

    private static let commonDevPorts = [
        3000, 3001, 4000, 4200, 5000, 5173, 5500, 8000, 8080, 8888, 9000,
    ]

    init(client: any TailscaleClientProtocol) {
        self.client = client
    }

    var isConnected: Bool {
        status?.backendState == "Running"
    }

    var tailnetName: String {
        status?.currentTailnet?.Name ?? status?.magicDNSSuffix ?? "—"
    }

    var selfNode: PeerStatus? {
        status?.selfNode
    }

    var selfRelayCity: String? {
        guard let relay = status?.selfNode?.Relay, !relay.isEmpty else { return nil }
        return NodeInfo.relayCity(for: relay)
    }

    var serviceCount: Int {
        serveConfig?.TCP?.count ?? 0
    }

    var services: [ServiceInfo] {
        guard let config = serveConfig, let tcp = config.TCP else { return [] }

        let hostname = cleanDNSName(status?.selfNode?.DNSName)

        return tcp.keys.sorted().compactMap { portStr -> ServiceInfo? in
            guard let port = Int(portStr) else { return nil }
            let tcpConfig = tcp[portStr]
            let isHTTPS = tcpConfig?.HTTPS ?? false

            var handlers: [HandlerInfo] = []
            if let web = config.Web {
                for (hostKey, webConfig) in web {
                    let matchesPort: Bool
                    if port == 443 {
                        matchesPort = !hostKey.contains(":") || hostKey.hasSuffix(":443")
                    } else {
                        matchesPort = hostKey.hasSuffix(":\(port)")
                    }
                    guard matchesPort else { continue }

                    if let h = webConfig.Handlers {
                        for (path, entry) in h.sorted(by: { $0.key < $1.key }) {
                            let target: String
                            let type: HandlerInfo.HandlerType
                            if let proxy = entry.Proxy {
                                target = simplifyTarget(proxy)
                                type = .proxy
                            } else if let filePath = entry.Path {
                                target = filePath
                                type = .file
                            } else if let text = entry.Text {
                                target = String(text.prefix(60))
                                type = .text
                            } else {
                                continue
                            }
                            handlers.append(HandlerInfo(path: path, target: target, type: type))
                        }
                    }
                }
            }

            let isFunnel: Bool
            if let allowFunnel = config.AllowFunnel {
                isFunnel = allowFunnel.contains { key, value in
                    value && (key.hasSuffix(":\(port)") || (port == 443 && !key.contains(":")))
                }
            } else {
                isFunnel = false
            }

            let portSuffix = (isHTTPS && port == 443) ? "" : ":\(port)"
            let scheme = isHTTPS ? "https" : "http"
            let fullURL = "\(scheme)://\(hostname)\(portSuffix)"

            return ServiceInfo(
                id: portStr,
                port: port,
                isHTTPS: isHTTPS,
                isFunnel: isFunnel,
                handlers: handlers,
                fullURL: fullURL,
                isHealthy: serviceHealth[port]
            )
        }
    }

    // MARK: - Actions

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            self.status = try await client.fetchStatus()
            self.error = nil
        } catch {
            self.error = error.localizedDescription
            return
        }

        do {
            self.serveConfig = try await client.fetchServeConfig()
        } catch {
            self.serveConfig = nil
        }

        await checkServiceHealth()
        await scanLocalPorts()
    }

    func startAutoRefresh(interval: TimeInterval = 10) {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func resetAllServes() async {
        do {
            try await client.resetServes()
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func addServe(port: Int, funnel: Bool) async {
        do {
            if funnel {
                try await client.enableFunnel(port: port)
            } else {
                try await client.addServe(port: port)
            }
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeServe(port: Int) async {
        do {
            try await client.removeServe(port: port)
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleFunnel(port: Int, enable: Bool) async {
        do {
            if enable {
                try await client.enableFunnel(port: port)
            } else {
                try await client.disableFunnel(port: port)
            }
            await refresh()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Health Check

    private func checkServiceHealth() async {
        var health: [Int: Bool] = [:]

        await withTaskGroup(of: (Int, Bool).self) { group in
            for service in services {
                guard let localPort = extractLocalPort(service) else { continue }
                let servePort = service.port
                group.addTask { [client] in
                    let ok = await client.checkPort(localPort)
                    return (servePort, ok)
                }
            }
            for await (port, ok) in group {
                health[port] = ok
            }
        }

        self.serviceHealth = health
    }

    // MARK: - Port Scanning

    private func scanLocalPorts() async {
        let servedLocalPorts = Set(services.compactMap { extractLocalPort($0) })
        let servedPorts = Set(services.map(\.port))
        let excluded = servedLocalPorts.union(servedPorts)
        let portsToScan = Self.commonDevPorts.filter { !excluded.contains($0) }

        var detected: [Int] = []
        await withTaskGroup(of: (Int, Bool).self) { group in
            for port in portsToScan {
                group.addTask { [client] in
                    let ok = await client.checkPort(port)
                    return (port, ok)
                }
            }
            for await (port, ok) in group {
                if ok { detected.append(port) }
            }
        }
        self.detectedPorts = detected.sorted()
    }

    // MARK: - Helpers

    private func extractLocalPort(_ service: ServiceInfo) -> Int? {
        guard let handler = service.handlers.first, handler.type == .proxy else { return nil }
        guard let colonIdx = handler.target.lastIndex(of: ":") else { return nil }
        let afterColon = handler.target[handler.target.index(after: colonIdx)...]
        let portStr = afterColon.prefix(while: { $0.isNumber })
        return Int(portStr)
    }

    private func cleanDNSName(_ dns: String?) -> String {
        guard let dns else { return "localhost" }
        return dns.hasSuffix(".") ? String(dns.dropLast()) : dns
    }

    private func simplifyTarget(_ target: String) -> String {
        var s = target
        for prefix in ["http://", "https://"] {
            if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)) }
        }
        return s
            .replacingOccurrences(of: "127.0.0.1", with: "localhost")
            .replacingOccurrences(of: "[::1]", with: "localhost")
    }
}
