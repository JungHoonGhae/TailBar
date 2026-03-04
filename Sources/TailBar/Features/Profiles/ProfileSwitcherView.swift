import SwiftUI

struct ProfileSwitcherView: View {
    let profiles: [TailscaleProfile]
    let currentProfileID: String?
    let onSwitch: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(profiles) { profile in
                Button(action: { onSwitch(profile.ID) }) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(profile.UserProfile?.DisplayName ?? profile.Name ?? "Unknown")
                                .font(.system(size: 11, weight: .medium))
                            if let login = profile.UserProfile?.LoginName {
                                Text(login)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                            }
                            if let domain = profile.NetworkProfile?.DomainName {
                                Text(domain)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if profile.ID == currentProfileID {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
