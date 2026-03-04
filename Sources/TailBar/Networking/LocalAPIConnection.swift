import Foundation

/// Discovers and manages the Local API connection to the Tailscale daemon.
///
/// On macOS, the Tailscale daemon exposes a local HTTP API:
/// 1. `/Library/Tailscale/ipnport` symlink contains the TCP port number
/// 2. `/Library/Tailscale/sameuserproof-{port}` contains the auth token
/// 3. HTTP requests go to `http://127.0.0.1:{port}/localapi/v0/...`
/// 4. Auth header: `Sec-Tailscale: {token}`
struct LocalAPIConnection: Sendable {
    let port: Int
    let token: String

    var baseURL: URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }

    func url(for path: String) -> URL {
        baseURL.appendingPathComponent(path)
    }

    func request(method: String = "GET", path: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url(for: path))
        request.httpMethod = method
        request.setValue(token, forHTTPHeaderField: "Sec-Tailscale")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    // MARK: - Discovery

    private static let ipnPortPath = "/Library/Tailscale/ipnport"
    private static let sameUserProofPrefix = "/Library/Tailscale/sameuserproof-"

    /// Attempts to discover the Local API connection from the filesystem.
    static func discover() throws -> LocalAPIConnection {
        let port = try readPort()
        let token = try readToken(port: port)
        return LocalAPIConnection(port: port, token: token)
    }

    private static func readPort() throws -> Int {
        let fm = FileManager.default

        guard fm.fileExists(atPath: ipnPortPath) else {
            throw TailBarError.localAPIUnavailable(
                reason: "Port file not found at \(ipnPortPath). Is Tailscale running?"
            )
        }

        // The ipnport file is a symlink whose target name is the port number,
        // or a regular file containing the port number.
        let portString: String
        if let dest = try? fm.destinationOfSymbolicLink(atPath: ipnPortPath) {
            // Symlink target is just the port number (e.g., "41112")
            portString = URL(fileURLWithPath: dest).lastPathComponent
        } else {
            portString = try String(contentsOfFile: ipnPortPath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let port = Int(portString), port > 0, port <= 65535 else {
            throw TailBarError.localAPIUnavailable(
                reason: "Invalid port in \(ipnPortPath): '\(portString)'"
            )
        }

        return port
    }

    private static func readToken(port: Int) throws -> String {
        let tokenPath = "\(sameUserProofPrefix)\(port)"
        let fm = FileManager.default

        guard fm.fileExists(atPath: tokenPath) else {
            throw TailBarError.localAPIUnavailable(
                reason: "Auth token not found at \(tokenPath). Check admin group membership."
            )
        }

        let token = try String(contentsOfFile: tokenPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !token.isEmpty else {
            throw TailBarError.localAPIUnavailable(
                reason: "Empty auth token at \(tokenPath)"
            )
        }

        return token
    }
}
