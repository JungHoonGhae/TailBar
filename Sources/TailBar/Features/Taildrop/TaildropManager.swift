import Foundation
import Observation

@MainActor @Observable
final class TaildropManager {
    var fileTargets: [FileTarget] = []
    var isSending = false
    var lastError: String?

    private let client: any TailscaleClientProtocol

    init(client: any TailscaleClientProtocol) {
        self.client = client
    }

    func refreshTargets() async {
        do {
            fileTargets = try await client.fetchFileTargets()
            lastError = nil
        } catch {
            fileTargets = []
            // Silently fail — Taildrop may not be available
        }
    }

    func sendFile(to target: FileTarget, fileURL: URL) async {
        guard let nodeID = target.Node.ID else {
            lastError = "Invalid target node"
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let data = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            try await client.sendFile(to: nodeID, fileName: fileName, data: data)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    var onlineTargets: [FileTarget] {
        fileTargets.filter { $0.Node.Online ?? false }
    }
}
