import Foundation
import Testing
@testable import TailBar

@Suite("Model Decoding")
struct ModelsTests {
    @Test("Decode TailscaleStatus from fixture")
    func decodeStatus() throws {
        let url = Bundle.module.url(forResource: "status", withExtension: "json", subdirectory: "Fixtures")!
        let data = try Data(contentsOf: url)
        let status = try JSONDecoder().decode(TailscaleStatus.self, from: data)

        #expect(status.version == "1.60.0")
        #expect(status.backendState == "Running")
        #expect(status.tun == true)
        #expect(status.selfNode?.HostName == "my-mac")
        #expect(status.selfNode?.OS == "macOS")
        #expect(status.selfNode?.Online == true)
        #expect(status.peers?.count == 1)
        #expect(status.peers?["peer-1"]?.HostName == "server-1")
        #expect(status.currentTailnet?.Name == "example@gmail.com")
        #expect(status.magicDNSSuffix == "tail12345.ts.net")
    }

    @Test("Decode ServeConfig from fixture")
    func decodeServeConfig() throws {
        let url = Bundle.module.url(forResource: "serve-config", withExtension: "json", subdirectory: "Fixtures")!
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ServeConfig.self, from: data)

        #expect(config.TCP?.count == 2)
        #expect(config.TCP?["443"]?.HTTPS == true)
        #expect(config.Web?.count == 2)
        #expect(config.AllowFunnel?["my-mac.tail12345.ts.net:443"] == true)
        #expect(config.AllowFunnel?["my-mac.tail12345.ts.net:8443"] == false)

        let handlers = config.Web?["my-mac.tail12345.ts.net:8443"]?.Handlers
        #expect(handlers?.count == 2)
        #expect(handlers?["/"]?.Proxy == "http://127.0.0.1:8080")
        #expect(handlers?["/api"]?.Proxy == "http://127.0.0.1:4000")
    }

    @Test("PeerStatus ExitNodeOption")
    func peerExitNodeOption() {
        let peer = PeerStatus(
            ID: "test-id", HostName: "exit-node", DNSName: "exit-node.ts.net.",
            OS: "linux", TailscaleIPs: ["100.64.0.5"], Online: true,
            ExitNode: false, ExitNodeOption: true, Active: true,
            LastSeen: nil, Relay: "sfo", CurAddr: "1.2.3.4:41641",
            RxBytes: 100, TxBytes: 200, KeyExpiry: nil
        )
        #expect(peer.ExitNodeOption == true)
        #expect(peer.ExitNode == false)
    }

    @Test("NodeInfo relay city lookup")
    func nodeInfoRelayCity() {
        #expect(NodeInfo.relayCity(for: "tok") == "Tokyo")
        #expect(NodeInfo.relayCity(for: "sfo") == "San Francisco")
        #expect(NodeInfo.relayCity(for: "unknown") == "UNKNOWN")
    }

    @Test("NodeInfo OS icon mapping")
    func nodeInfoOsIcon() {
        let node = NodeInfo(
            id: "1", hostName: "mac", dnsName: "mac.ts.net.", dnsLabel: "mac",
            os: "macOS", tailscaleIPs: [], isOnline: true, isSelf: false,
            isExitNode: false, isExitNodeOption: false, lastSeen: nil, relay: nil, curAddr: nil, keyExpiry: nil, rxBytes: nil, txBytes: nil
        )
        #expect(node.osIcon == "laptopcomputer")

        let linuxNode = NodeInfo(
            id: "2", hostName: "srv", dnsName: "srv.ts.net.", dnsLabel: "srv",
            os: "linux", tailscaleIPs: [], isOnline: true, isSelf: false,
            isExitNode: false, isExitNodeOption: false, lastSeen: nil, relay: nil, curAddr: nil, keyExpiry: nil, rxBytes: nil, txBytes: nil
        )
        #expect(linuxNode.osIcon == "server.rack")
    }

    @Test("NodeInfo connection info")
    func nodeInfoConnectionInfo() {
        let directNode = NodeInfo(
            id: "1", hostName: "host", dnsName: "h.ts.net.", dnsLabel: "h",
            os: "linux", tailscaleIPs: [], isOnline: true, isSelf: false,
            isExitNode: false, isExitNodeOption: false, lastSeen: nil, relay: "tok", curAddr: "1.2.3.4:41641",
            keyExpiry: nil, rxBytes: nil, txBytes: nil
        )
        #expect(directNode.connectionInfo == "Direct")

        let relayedNode = NodeInfo(
            id: "2", hostName: "host2", dnsName: "h2.ts.net.", dnsLabel: "h2",
            os: "linux", tailscaleIPs: [], isOnline: true, isSelf: false,
            isExitNode: false, isExitNodeOption: false, lastSeen: nil, relay: "fra", curAddr: nil,
            keyExpiry: nil, rxBytes: nil, txBytes: nil
        )
        #expect(relayedNode.connectionInfo == "via Frankfurt")

        let offlineNode = NodeInfo(
            id: "3", hostName: "host3", dnsName: "h3.ts.net.", dnsLabel: "h3",
            os: "linux", tailscaleIPs: [], isOnline: false, isSelf: false,
            isExitNode: false, isExitNodeOption: false, lastSeen: nil, relay: "tok", curAddr: nil,
            keyExpiry: nil, rxBytes: nil, txBytes: nil
        )
        #expect(offlineNode.connectionInfo == nil)
    }

    @Test("Decode TailscalePrefs")
    func decodePrefs() throws {
        let json = """
        {
            "ControlURL": "https://controlplane.tailscale.com",
            "RouteAll": false,
            "ExitNodeID": "",
            "ExitNodeAllowLANAccess": false,
            "CorpDNS": true,
            "ShieldsUp": false,
            "Hostname": "my-mac"
        }
        """.data(using: .utf8)!

        let prefs = try JSONDecoder().decode(TailscalePrefs.self, from: json)
        #expect(prefs.CorpDNS == true)
        #expect(prefs.Hostname == "my-mac")
        #expect(prefs.ExitNodeID == "")
    }

    @Test("Encode PrefsPatch omits nil fields")
    func encodePrefsPatch() throws {
        let patch = PrefsPatch(ExitNodeID: "node123", ExitNodeAllowLANAccess: nil)
        let data = try JSONEncoder().encode(patch)
        let json = try JSONDecoder().decode([String: String].self, from: data)
        #expect(json["ExitNodeID"] == "node123")
        #expect(json["ExitNodeAllowLANAccess"] == nil)
    }

    @Test("Decode IPNBusNotification")
    func decodeIPNNotification() throws {
        let json = """
        {"Version":"1.60.0","State":6,"Health":["warning: update available"]}
        """.data(using: .utf8)!

        let notification = try JSONDecoder().decode(IPNBusNotification.self, from: json)
        #expect(notification.Version == "1.60.0")
        #expect(notification.State == 6)
        #expect(notification.Health?.first == "warning: update available")
    }
}
