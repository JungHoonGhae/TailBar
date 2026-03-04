import Foundation
import Testing
@testable import TailBar

@Suite("TailscaleStore")
struct TailscaleStoreTests {
    @Test("refresh fetches status and serve config")
    @MainActor
    func refreshFetchesData() async {
        let mock = MockTailscaleClient()
        mock.serveConfigResult = .success(MockTailscaleClient.defaultServeConfig)
        let store = TailscaleStore(client: mock)

        await store.refresh()

        #expect(mock.fetchStatusCallCount == 1)
        #expect(mock.fetchServeConfigCallCount == 1)
        #expect(store.status != nil)
        #expect(store.isConnected == true)
        #expect(store.error == nil)
    }

    @Test("refresh sets error on status failure")
    @MainActor
    func refreshSetsError() async {
        let mock = MockTailscaleClient()
        mock.statusResult = .failure(TailBarError.tailscaleNotFound)
        let store = TailscaleStore(client: mock)

        await store.refresh()

        #expect(store.error != nil)
        #expect(store.status == nil)
    }

    @Test("isConnected reflects backend state")
    @MainActor
    func isConnectedState() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        #expect(store.isConnected == false)

        await store.refresh()
        #expect(store.isConnected == true)

        // Simulate stopped state
        let stoppedStatus = TailscaleStatus(
            version: "1.60.0", backendState: "Stopped", tun: false,
            tailscaleIPs: nil, selfNode: nil, peers: nil,
            currentTailnet: nil, magicDNSSuffix: nil, certDomains: nil
        )
        mock.statusResult = .success(stoppedStatus)
        await store.refresh()
        #expect(store.isConnected == false)
    }

    @Test("tailnetName returns correct value")
    @MainActor
    func tailnetName() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.refresh()
        #expect(store.tailnetName == "example@gmail.com")
    }

    @Test("addServe calls client with correct parameters")
    @MainActor
    func addServe() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.addServe(port: 3000, funnel: false)
        #expect(mock.addServeCallCount == 1)
        #expect(mock.lastAddedPort == 3000)
        #expect(mock.enableFunnelCallCount == 0)
    }

    @Test("addServe with funnel calls enableFunnel")
    @MainActor
    func addServeWithFunnel() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.addServe(port: 8080, funnel: true)
        #expect(mock.enableFunnelCallCount == 1)
        #expect(mock.lastFunnelPort == 8080)
        #expect(mock.addServeCallCount == 0)
    }

    @Test("removeServe calls client")
    @MainActor
    func removeServe() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.removeServe(port: 3000)
        #expect(mock.removeServeCallCount == 1)
        #expect(mock.lastRemovedPort == 3000)
    }

    @Test("resetAllServes calls client")
    @MainActor
    func resetAllServes() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.resetAllServes()
        #expect(mock.resetServesCallCount == 1)
    }

    @Test("toggleFunnel enable/disable")
    @MainActor
    func toggleFunnel() async {
        let mock = MockTailscaleClient()
        let store = TailscaleStore(client: mock)

        await store.toggleFunnel(port: 443, enable: true)
        #expect(mock.enableFunnelCallCount == 1)

        await store.toggleFunnel(port: 443, enable: false)
        #expect(mock.disableFunnelCallCount == 1)
    }

    @Test("services computes from serve config")
    @MainActor
    func servicesComputation() async {
        let mock = MockTailscaleClient()
        mock.serveConfigResult = .success(MockTailscaleClient.defaultServeConfig)
        let store = TailscaleStore(client: mock)

        await store.refresh()

        #expect(store.serviceCount == 1)
        #expect(store.services.count == 1)

        let service = store.services.first!
        #expect(service.port == 443)
        #expect(service.isHTTPS == true)
        #expect(service.isFunnel == false)
        #expect(service.handlers.count == 1)
        #expect(service.handlers.first?.path == "/")
        #expect(service.handlers.first?.target == "localhost:3000")
    }

    @Test("error is cleared on successful refresh")
    @MainActor
    func errorCleared() async {
        let mock = MockTailscaleClient()
        mock.statusResult = .failure(TailBarError.tailscaleNotFound)
        let store = TailscaleStore(client: mock)

        await store.refresh()
        #expect(store.error != nil)

        mock.statusResult = .success(MockTailscaleClient.defaultStatus)
        await store.refresh()
        #expect(store.error == nil)
    }
}
