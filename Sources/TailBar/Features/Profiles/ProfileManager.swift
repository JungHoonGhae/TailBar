import Foundation
import Observation

@MainActor @Observable
final class ProfileManager {
    var profiles: [TailscaleProfile] = []
    var currentProfileID: String?
    var isSwitching = false

    private let client: any TailscaleClientProtocol

    init(client: any TailscaleClientProtocol) {
        self.client = client
    }

    func refresh() async {
        do {
            profiles = try await client.fetchProfiles()
        } catch {
            profiles = []
        }
    }

    func switchProfile(to id: String) async {
        isSwitching = true
        defer { isSwitching = false }

        do {
            try await client.switchProfile(id: id)
            currentProfileID = id
        } catch {
            // Profile switching failed
        }
    }

    var currentProfile: TailscaleProfile? {
        guard let id = currentProfileID else { return profiles.first }
        return profiles.first(where: { $0.ID == id })
    }
}
