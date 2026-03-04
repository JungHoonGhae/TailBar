import Foundation

// MARK: - Tailscale Status JSON

struct TailscaleStatus: Codable, Sendable {
    let version: String?
    let backendState: String?
    let tun: Bool?
    let tailscaleIPs: [String]?
    let selfNode: PeerStatus?
    let peers: [String: PeerStatus]?
    let currentTailnet: TailnetInfo?
    let magicDNSSuffix: String?
    let certDomains: [String]?

    enum CodingKeys: String, CodingKey {
        case version = "Version"
        case backendState = "BackendState"
        case tun = "TUN"
        case tailscaleIPs = "TailscaleIPs"
        case selfNode = "Self"
        case peers = "Peer"
        case currentTailnet = "CurrentTailnet"
        case magicDNSSuffix = "MagicDNSSuffix"
        case certDomains = "CertDomains"
    }
}

struct PeerStatus: Codable, Sendable {
    let ID: String?
    let HostName: String?
    let DNSName: String?
    let OS: String?
    let TailscaleIPs: [String]?
    let Online: Bool?
    let ExitNode: Bool?
    let ExitNodeOption: Bool?
    let Active: Bool?
    let LastSeen: String?
    let Relay: String?
    let CurAddr: String?
    let RxBytes: Int?
    let TxBytes: Int?
    let KeyExpiry: String?
}

struct TailnetInfo: Codable, Sendable {
    let Name: String?
    let MagicDNSSuffix: String?
    let MagicDNSEnabled: Bool?
}

// MARK: - Serve Config JSON

struct ServeConfig: Codable, Sendable {
    let TCP: [String: TCPPortConfig]?
    let Web: [String: WebHostConfig]?
    let AllowFunnel: [String: Bool]?
}

struct TCPPortConfig: Codable, Sendable {
    let HTTPS: Bool?
    let TCPForward: String?
    let TerminateTLS: String?
}

struct WebHostConfig: Codable, Sendable {
    let Handlers: [String: HandlerEntry]?
}

struct HandlerEntry: Codable, Sendable {
    let Proxy: String?
    let Path: String?
    let Text: String?
}

// MARK: - Display Models

struct ServiceInfo: Identifiable, Sendable {
    let id: String
    let port: Int
    let isHTTPS: Bool
    let isFunnel: Bool
    let handlers: [HandlerInfo]
    let fullURL: String
    let isHealthy: Bool?
}

struct HandlerInfo: Identifiable, Sendable {
    var id: String { "\(path)-\(target)" }
    let path: String
    let target: String
    let type: HandlerType

    enum HandlerType: Sendable {
        case proxy
        case file
        case text
    }
}

struct NodeInfo: Identifiable, Sendable {
    let id: String
    let hostName: String
    let dnsName: String
    let dnsLabel: String
    let os: String
    let tailscaleIPs: [String]
    let isOnline: Bool
    let isSelf: Bool
    let isExitNode: Bool
    let isExitNodeOption: Bool
    let lastSeen: String?
    let relay: String?
    let curAddr: String?
    let keyExpiry: Date?
    let rxBytes: Int?
    let txBytes: Int?

    /// Best display name: manual alias > Tailscale DNS label > raw hostname
    var displayName: String {
        AliasStore.alias(forNode: hostName) ?? dnsLabel
    }

    var hasCustomName: Bool {
        displayName != hostName
    }

    var osIcon: String {
        switch os.lowercased() {
        case "macos": return "laptopcomputer"
        case "windows": return "desktopcomputer"
        case "linux": return "server.rack"
        case "android": return "apps.iphone"
        case "ios": return "iphone"
        default: return "display"
        }
    }

    // MARK: - Relay region

    var relayCity: String? {
        guard let relay, !relay.isEmpty else { return nil }
        return Self.derpRegions[relay] ?? relay.uppercased()
    }

    /// "Direct (1.2.3.4)" or "via Tokyo" or nil
    var connectionInfo: String? {
        guard isOnline else { return nil }
        if let addr = curAddr, !addr.isEmpty {
            return "Direct"
        }
        if let city = relayCity {
            return "via \(city)"
        }
        return nil
    }

    // MARK: - Key expiry

    var keyExpiryDays: Int? {
        guard let keyExpiry else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: keyExpiry).day
    }

    var keyExpiryWarning: String? {
        guard let days = keyExpiryDays else { return nil }
        if days <= 0 { return "Key expired" }
        if days <= 30 { return "Key: \(days)d left" }
        return nil
    }

    // MARK: - Last seen

    var formattedLastSeen: String? {
        guard let lastSeen, !isOnline else { return nil }
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFractional.date(from: lastSeen) ?? ISO8601DateFormatter().date(from: lastSeen)
        guard let date else { return nil }
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        return relative.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - DERP relay regions

    static func relayCity(for code: String) -> String {
        derpRegions[code] ?? code.uppercased()
    }

    private static let derpRegions: [String: String] = [
        "nyc": "New York",
        "sfo": "San Francisco",
        "sin": "Singapore",
        "fra": "Frankfurt",
        "syd": "Sydney",
        "tok": "Tokyo",
        "lhr": "London",
        "dfw": "Dallas",
        "sea": "Seattle",
        "sao": "São Paulo",
        "blr": "Bangalore",
        "ord": "Chicago",
        "lax": "Los Angeles",
        "ams": "Amsterdam",
        "par": "Paris",
        "hkg": "Hong Kong",
        "mia": "Miami",
        "den": "Denver",
        "dbi": "Dubai",
        "jnb": "Johannesburg",
        "nai": "Nairobi",
        "waw": "Warsaw",
        "mad": "Madrid",
        "hnl": "Honolulu",
    ]
}

// MARK: - Preferences

struct TailscalePrefs: Codable, Sendable {
    let ControlURL: String?
    let RouteAll: Bool?
    let ExitNodeID: String?
    let ExitNodeAllowLANAccess: Bool?
    let CorpDNS: Bool?
    let ShieldsUp: Bool?
    let AdvertiseRoutes: [String]?
    let Hostname: String?
}

struct PrefsPatch: Codable, Sendable {
    var ExitNodeID: String?
    var ExitNodeAllowLANAccess: Bool?

    enum CodingKeys: String, CodingKey {
        case ExitNodeID
        case ExitNodeAllowLANAccess
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Only encode non-nil fields
        if let v = ExitNodeID { try container.encode(v, forKey: .ExitNodeID) }
        if let v = ExitNodeAllowLANAccess { try container.encode(v, forKey: .ExitNodeAllowLANAccess) }
    }
}

// MARK: - Exit Node

struct ExitNodeSuggestion: Codable, Sendable {
    let ID: String?
    let Name: String?
    let Location: ExitNodeLocation?
}

struct ExitNodeLocation: Codable, Sendable {
    let Country: String?
    let CountryCode: String?
    let City: String?
    let CityCode: String?
    let Priority: Int?
}

// MARK: - Profiles

struct TailscaleProfile: Codable, Sendable, Identifiable {
    let ID: String
    let Name: String?
    let NetworkProfile: ProfileNetwork?
    let LocalUserID: String?
    let UserProfile: ProfileUser?
    let NodeID: String?

    var id: String { self.ID }
}

struct ProfileNetwork: Codable, Sendable {
    let MagicDNSName: String?
    let DomainName: String?
}

struct ProfileUser: Codable, Sendable {
    let ID: Int?
    let LoginName: String?
    let DisplayName: String?
    let ProfilePicURL: String?
}

// MARK: - Taildrop

struct FileTarget: Codable, Sendable, Identifiable {
    let Node: FileTargetNode
    let PeerAPI: [String]?

    var id: String { Node.ID ?? Node.Name ?? "" }
}

struct FileTargetNode: Codable, Sendable {
    let ID: String?
    let Name: String?
    let Addresses: [String]?
    let Online: Bool?
}

// MARK: - IPN Bus

struct IPNBusNotification: Codable, Sendable {
    let Version: String?
    let ErrMessage: String?
    let LoginFinished: LoginFinishedMessage?
    let State: Int?
    let Prefs: TailscalePrefs?
    let NetMap: NetMapSummary?
    let Engine: EngineStatus?
    let BrowseToURL: String?
    let LocalTCPPort: Int?
    let FilesWaiting: [IncomingFile]?
    let Health: [String]?
}

struct LoginFinishedMessage: Codable, Sendable {}

struct NetMapSummary: Codable, Sendable {
    let SelfNode: PeerStatus?
    let Peers: [PeerStatus]?
    let DNS: DNSConfig?
}

struct DNSConfig: Codable, Sendable {
    let Domains: [String]?
    let Nameservers: [String]?
}

struct EngineStatus: Codable, Sendable {
    let RBytes: Int?
    let WBytes: Int?
    let NumLive: Int?
}

struct IncomingFile: Codable, Sendable {
    let Name: String?
    let Started: String?
    let DeclaredSize: Int?
    let Received: Int?
    let PartialPath: String?
}
