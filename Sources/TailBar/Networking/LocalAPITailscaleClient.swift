import Foundation

/// Tailscale client that communicates via the Local API (HTTP on 127.0.0.1).
/// This is the preferred client — faster and more capable than CLI.
final class LocalAPITailscaleClient: TailscaleClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private var connection: LocalAPIConnection?

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Connection Management

    private func getConnection() throws -> LocalAPIConnection {
        if let connection { return connection }
        let conn = try LocalAPIConnection.discover()
        self.connection = conn
        return conn
    }

    func resetConnection() {
        connection = nil
    }

    // MARK: - Status

    func fetchStatus() async throws -> TailscaleStatus {
        let data = try await get("localapi/v0/status")
        return try JSONDecoder().decode(TailscaleStatus.self, from: data)
    }

    func fetchServeConfig() async throws -> ServeConfig {
        let data = try await get("localapi/v0/serve-config")
        return try JSONDecoder().decode(ServeConfig.self, from: data)
    }

    // MARK: - Serve Management

    func addServe(port: Int) async throws {
        let config = makeServeConfig(port: port, funnel: false)
        let body = try JSONEncoder().encode(config)
        try await post("localapi/v0/serve-config", body: body)
    }

    func removeServe(port: Int) async throws {
        let current = try await fetchServeConfig()
        var newTCP = current.TCP ?? [:]
        newTCP.removeValue(forKey: "\(port)")

        var newWeb = current.Web ?? [:]
        let webKeysToRemove = newWeb.keys.filter { key in
            key.hasSuffix(":\(port)") || (port == 443 && !key.contains(":"))
        }
        for key in webKeysToRemove { newWeb.removeValue(forKey: key) }

        var newFunnel = current.AllowFunnel ?? [:]
        let funnelKeysToRemove = newFunnel.keys.filter { key in
            key.hasSuffix(":\(port)") || (port == 443 && !key.contains(":"))
        }
        for key in funnelKeysToRemove { newFunnel.removeValue(forKey: key) }

        let updated = ServeConfig(
            TCP: newTCP.isEmpty ? nil : newTCP,
            Web: newWeb.isEmpty ? nil : newWeb,
            AllowFunnel: newFunnel.isEmpty ? nil : newFunnel
        )
        let body = try JSONEncoder().encode(updated)
        try await post("localapi/v0/serve-config", body: body)
    }

    func resetServes() async throws {
        let empty = ServeConfig(TCP: nil, Web: nil, AllowFunnel: nil)
        let body = try JSONEncoder().encode(empty)
        try await post("localapi/v0/serve-config", body: body)
    }

    // MARK: - Funnel Management

    func enableFunnel(port: Int) async throws {
        let config = makeServeConfig(port: port, funnel: true)
        let body = try JSONEncoder().encode(config)
        try await post("localapi/v0/serve-config", body: body)
    }

    func disableFunnel(port: Int) async throws {
        let current = try await fetchServeConfig()
        var newFunnel = current.AllowFunnel ?? [:]
        let keysToUpdate = newFunnel.keys.filter { key in
            key.hasSuffix(":\(port)") || (port == 443 && !key.contains(":"))
        }
        for key in keysToUpdate { newFunnel[key] = false }

        let updated = ServeConfig(
            TCP: current.TCP,
            Web: current.Web,
            AllowFunnel: newFunnel.isEmpty ? nil : newFunnel
        )
        let body = try JSONEncoder().encode(updated)
        try await post("localapi/v0/serve-config", body: body)
    }

    // MARK: - Network

    func ping(hostname: String) async throws -> String {
        let encoded = hostname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? hostname
        let data = try await get("localapi/v0/ping?hostname=\(encoded)&type=disco")
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func checkPort(_ port: Int) async -> Bool {
        await Task.detached {
            let sock = socket(AF_INET, SOCK_STREAM, 0)
            guard sock >= 0 else { return false }

            var timeout = timeval(tv_sec: 1, tv_usec: 0)
            setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &timeout,
                       socklen_t(MemoryLayout<timeval>.size))

            var addr = sockaddr_in()
            addr.sin_family = sa_family_t(AF_INET)
            addr.sin_port = UInt16(port).bigEndian
            addr.sin_addr.s_addr = inet_addr("127.0.0.1")

            let ok = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sa in
                    connect(sock, sa, socklen_t(MemoryLayout<sockaddr_in>.size)) == 0
                }
            }

            close(sock)
            return ok
        }.value
    }

    // MARK: - Preferences

    func fetchPrefs() async throws -> TailscalePrefs {
        let data = try await get("localapi/v0/prefs")
        return try JSONDecoder().decode(TailscalePrefs.self, from: data)
    }

    func updatePrefs(_ update: PrefsPatch) async throws {
        let body = try JSONEncoder().encode(update)
        try await patch("localapi/v0/prefs", body: body)
    }

    // MARK: - Exit Node

    func suggestExitNode() async throws -> ExitNodeSuggestion {
        let data = try await get("localapi/v0/suggest-exit-node")
        return try JSONDecoder().decode(ExitNodeSuggestion.self, from: data)
    }

    // MARK: - Profiles

    func fetchProfiles() async throws -> [TailscaleProfile] {
        let data = try await get("localapi/v0/profiles/")
        return try JSONDecoder().decode([TailscaleProfile].self, from: data)
    }

    func switchProfile(id: String) async throws {
        try await post("localapi/v0/profiles/\(id)", body: nil)
    }

    // MARK: - Taildrop

    func fetchFileTargets() async throws -> [FileTarget] {
        let data = try await get("localapi/v0/file-targets")
        return try JSONDecoder().decode([FileTarget].self, from: data)
    }

    func sendFile(to nodeID: String, fileName: String, data fileData: Data) async throws {
        let conn = try getConnection()
        let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
        let url = conn.url(for: "localapi/v0/file-put/\(nodeID)/\(encoded)")
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(conn.token, forHTTPHeaderField: "Sec-Tailscale")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.httpBody = fileData

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Streaming

    func watchIPNBus() async throws -> AsyncThrowingStream<IPNBusNotification, Error> {
        let conn = try getConnection()
        let request = conn.request(path: "localapi/v0/watch-ipn-bus")

        return AsyncThrowingStream { continuation in
            let task = Task.detached { [session] in
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.finish(throwing: TailBarError.apiError(
                            endpoint: "watch-ipn-bus",
                            statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                            message: "Non-200 response"
                        ))
                        return
                    }

                    let decoder = JSONDecoder()
                    for try await line in bytes.lines {
                        guard !Task.isCancelled else { break }
                        guard !line.isEmpty else { continue }
                        guard let lineData = line.data(using: .utf8) else { continue }
                        if let notification = try? decoder.decode(IPNBusNotification.self, from: lineData) {
                            continuation.yield(notification)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - HTTP Helpers

    private func get(_ path: String) async throws -> Data {
        let conn = try getConnection()
        let request = conn.request(path: path)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, path: path)
        return data
    }

    private func post(_ path: String, body: Data?) async throws {
        let conn = try getConnection()
        let request = conn.request(method: "POST", path: path, body: body)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response, path: path)
    }

    private func patch(_ path: String, body: Data) async throws {
        let conn = try getConnection()
        let request = conn.request(method: "PATCH", path: path, body: body)
        let (_, response) = try await session.data(for: request)
        try validateResponse(response, path: path)
    }

    private func validateResponse(_ response: URLResponse, path: String = "") throws {
        guard let http = response as? HTTPURLResponse else {
            throw TailBarError.apiError(endpoint: path, statusCode: 0, message: "Invalid response")
        }
        guard (200...299).contains(http.statusCode) else {
            throw TailBarError.apiError(
                endpoint: path,
                statusCode: http.statusCode,
                message: HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            )
        }
    }

    // MARK: - Config Builders

    private func makeServeConfig(port: Int, funnel: Bool) -> ServeConfig {
        let portStr = "\(port)"
        let tcp = [portStr: TCPPortConfig(HTTPS: true, TCPForward: nil, TerminateTLS: nil)]
        let handler = HandlerEntry(Proxy: "http://127.0.0.1:\(port)", Path: nil, Text: nil)
        let web = ["${TS_CERT_DOMAIN}:\(port)": WebHostConfig(Handlers: ["/": handler])]
        let allowFunnel: [String: Bool]? = funnel ? ["${TS_CERT_DOMAIN}:\(port)": true] : nil
        return ServeConfig(TCP: tcp, Web: web, AllowFunnel: allowFunnel)
    }
}
