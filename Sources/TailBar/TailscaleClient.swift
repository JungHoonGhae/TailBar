import Foundation

enum TailBarError: LocalizedError {
    case tailscaleNotFound
    case commandFailed(status: Int, stderr: String)

    var errorDescription: String? {
        switch self {
        case .tailscaleNotFound:
            return "Tailscale CLI not found. Is Tailscale installed?"
        case .commandFailed(let status, let stderr):
            return "Command failed (\(status)): \(stderr)"
        }
    }
}

enum TailscaleClient {
    private static let tailscalePath: String = {
        let candidates = [
            "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
            "/opt/homebrew/bin/tailscale",
            "/usr/local/bin/tailscale",
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        return candidates[0]
    }()

    // MARK: - Status

    static func fetchStatus() async throws -> TailscaleStatus {
        let data = try await run("status", "--json")
        return try JSONDecoder().decode(TailscaleStatus.self, from: data)
    }

    static func fetchServeConfig() async throws -> ServeConfig {
        let data = try await run("serve", "status", "--json")
        return try JSONDecoder().decode(ServeConfig.self, from: data)
    }

    // MARK: - Serve Management

    static func addServe(port: Int) async throws {
        _ = try await run("serve", "--bg", String(port))
    }

    static func removeServe(port: Int) async throws {
        _ = try await run("serve", "--https=\(port)", "off")
    }

    static func resetServes() async throws {
        _ = try await run("serve", "reset")
    }

    // MARK: - Funnel Management

    static func enableFunnel(port: Int) async throws {
        _ = try await run("funnel", "--bg", String(port))
    }

    static func disableFunnel(port: Int) async throws {
        _ = try await run("funnel", "--https=\(port)", "off")
    }

    // MARK: - Network

    static func ping(hostname: String) async throws -> String {
        let data = try await run("ping", "--c", "1", "--timeout", "5s", hostname)
        return String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// TCP connect test to a local port.
    static func checkPort(_ port: Int) async -> Bool {
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

    // MARK: - Shell

    private static func run(_ arguments: String...) async throws -> Data {
        let path = tailscalePath
        let args = Array(arguments)

        return try await Task.detached {
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            try process.run()
            process.waitUntilExit()

            let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            let err = stderrPipe.fileHandleForReading.readDataToEndOfFile()

            guard process.terminationStatus == 0 else {
                let msg = String(data: err, encoding: .utf8) ?? ""
                throw TailBarError.commandFailed(
                    status: Int(process.terminationStatus),
                    stderr: msg.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            return data
        }.value
    }
}
