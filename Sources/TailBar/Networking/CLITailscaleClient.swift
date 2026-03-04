import Foundation

/// Tailscale client that communicates via the CLI executable.
/// Used as a fallback when Local API is unavailable.
final class CLITailscaleClient: TailscaleClientProtocol, @unchecked Sendable {
    private let tailscalePath: String

    init() {
        let candidates = [
            "/Applications/Tailscale.app/Contents/MacOS/Tailscale",
            "/opt/homebrew/bin/tailscale",
            "/usr/local/bin/tailscale",
        ]
        self.tailscalePath = candidates.first {
            FileManager.default.isExecutableFile(atPath: $0)
        } ?? candidates[0]
    }

    // MARK: - Status

    func fetchStatus() async throws -> TailscaleStatus {
        let data = try await run("status", "--json")
        return try JSONDecoder().decode(TailscaleStatus.self, from: data)
    }

    func fetchServeConfig() async throws -> ServeConfig {
        let data = try await run("serve", "status", "--json")
        return try JSONDecoder().decode(ServeConfig.self, from: data)
    }

    // MARK: - Serve Management

    func addServe(port: Int) async throws {
        _ = try await run("serve", "--bg", String(port))
    }

    func removeServe(port: Int) async throws {
        _ = try await run("serve", "--https=\(port)", "off")
    }

    func resetServes() async throws {
        _ = try await run("serve", "reset")
    }

    // MARK: - Funnel Management

    func enableFunnel(port: Int) async throws {
        _ = try await run("funnel", "--bg", String(port))
    }

    func disableFunnel(port: Int) async throws {
        _ = try await run("funnel", "--https=\(port)", "off")
    }

    // MARK: - Network

    func ping(hostname: String) async throws -> String {
        let data = try await run("ping", "--c", "1", "--timeout", "5s", hostname)
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

    // MARK: - Shell

    private func run(_ arguments: String...) async throws -> Data {
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
