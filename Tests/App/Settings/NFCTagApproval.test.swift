import Foundation
import GRDB
@testable import HomeAssistant
@testable import Shared
import Testing

@Suite(.serialized)
struct NFCTagApprovalTests {
    private let legacyAllowedTagsKey = "allowedTags"

    @Test("Unapproved Home Assistant tags require approval")
    func unapprovedTagsRequireApproval() throws {
        try withAllowedTagDatabase {
            let result = iOSTagManager().handle(userActivity: userActivity(tag: "front-door"))

            guard case let .requiresApproval(tag, type) = result else {
                Issue.record("Expected tag to require approval")
                return
            }

            #expect(tag == "front-door")
            #expect(isGeneric(type))
        }
    }

    @Test("New NFC tags use the branded URL and refuse identifiers that cannot be read back")
    func newTagsUseBrandedURL() {
        #expect(TagActivityManager.url(for: "front-door")?.absoluteString == "https://www.apporo.ai/tag/front-door")
        #expect(TagActivityManager.url(for: "") == nil)
        #expect(TagActivityManager.url(for: ".") == nil)
        #expect(TagActivityManager.url(for: "..") == nil)
        #expect(TagActivityManager.url(for: "floor/door") == nil)
        #expect(TagActivityManager.url(for: "door?x=1") == nil)
        #expect(TagActivityManager.url(for: "door#frag") == nil)
    }

    @Test("Branded and upstream tag URLs are read with exact secure semantics")
    func readsOnlySupportedTagURLs() throws {
        for url in [
            "https://www.apporo.ai/tag/front-door",
            // Read compatibility with tags written by the upstream Home Assistant app and by
            // earlier internal builds of this app, which both wrote this host.
            "https://www.home-assistant.io/tag/front-door",
        ] {
            let parsedURL = try #require(URL(string: url))
            #expect(TagActivityManager.identifier(from: parsedURL) == "front-door")
        }

        for url in [
            "http://www.apporo.ai/tag/front-door",
            "https://www.apporo.ai.evil.example/tag/front-door",
            "https://evil.example/tag/front-door",
            // The retired domain must NOT be accepted: it never resolved, so no tag can carry it.
            "https://aiot.apporo.io/tag/front-door",
            "https://www.apporo.ai/other/tag/front-door",
            "https://www.apporo.ai/tag/",
            "https://www.apporo.ai/tag/front-door/extra",
            "https://www.apporo.ai/tag/../../etc/passwd",
            "https://www.apporo.ai/tag/front-door?url=https://evil.example",
            "https://www.apporo.ai/tag/front-door#fragment",
            "https://user@www.apporo.ai/tag/front-door",
            "https://user:password@www.apporo.ai/tag/front-door",
            "https://www.apporo.ai:443/tag/front-door",
            "https://www.apporo.ai/tag/%2F",
            "https://www.apporo.ai/tag/%2E%2E",
        ] {
            let parsedURL = try #require(URL(string: url))
            #expect(TagActivityManager.identifier(from: parsedURL) == nil, "Unexpectedly accepted \(url)")
        }
    }

    @Test("Branded redirect, invitation and tag routes require the exact host and path")
    func brandedUniversalLinkRoutes() throws {
        let redirect = try #require(
            URL(string: "https://www.apporo.ai/redirect/config_flow_start?domain=mobile_app")
        )
        let legacyRedirect = try #require(
            URL(string: "https://my.home-assistant.io/redirect/config_flow_start?domain=mobile_app")
        )
        #expect(BrandedUniversalLink.route(for: redirect) == .redirect(legacyRedirect))

        // Both invitation spellings are accepted; `/invite/` is the canonical form shared with Android.
        let inviteWithSlash = try #require(URL(string: "https://www.apporo.ai/invite/#url=https%3A%2F%2Fha.example"))
        let inviteWithoutSlash = try #require(URL(string: "https://www.apporo.ai/invite#url=https%3A%2F%2Fha.example"))
        #expect(BrandedUniversalLink.route(for: inviteWithSlash) == .invite(inviteWithSlash))
        #expect(BrandedUniversalLink.route(for: inviteWithoutSlash) == .invite(inviteWithoutSlash))

        let tag = try #require(URL(string: "https://www.apporo.ai/tag/front-door"))
        #expect(BrandedUniversalLink.route(for: tag) == .tag("front-door"))

        for url in [
            // Wrong scheme, wrong host, or an origin carrying extra credentials / a port.
            "http://www.apporo.ai/redirect/config_flow_start?domain=mobile_app",
            "https://www.apporo.ai.evil.example/redirect/config_flow_start?domain=mobile_app",
            "https://evil.example/redirect/config_flow_start",
            "https://aiot.apporo.io/redirect/config_flow_start",
            "https://user@www.apporo.ai/redirect/config_flow_start",
            "https://user:password@www.apporo.ai/redirect/config_flow_start",
            "https://www.apporo.ai:443/redirect/config_flow_start",
            "https://user@www.apporo.ai/invite/#url=https%3A%2F%2Fha.example",
            "https://www.apporo.ai:8443/invite/#url=https%3A%2F%2Fha.example",
            // Malformed or traversing paths.
            "https://www.apporo.ai/redirect/",
            "https://www.apporo.ai/redirect//config_flow_start",
            "https://www.apporo.ai/redirect/../config_flow_start",
            "https://www.apporo.ai/redirect/%2E%2E/config_flow_start",
            "https://www.apporo.ai/not-redirect/config_flow_start",
            "https://www.apporo.ai/",
            "https://www.apporo.ai/invite/extra#url=https%3A%2F%2Fha.example",
            // Fragment must be exactly one http(s) `url` item.
            "https://www.apporo.ai/invite",
            "https://www.apporo.ai/invite#",
            "https://www.apporo.ai/invite#other=https%3A%2F%2Fha.example",
            "https://www.apporo.ai/invite#url=javascript%3Aalert(1)",
            "https://www.apporo.ai/invite#url=file%3A%2F%2F%2Fetc%2Fpasswd",
            "https://www.apporo.ai/invite#url=https%3A%2F%2Fha.example&url=https%3A%2F%2Fevil.example",
            "https://www.apporo.ai/invite#url=https%3A%2F%2Fha.example&mobile=1",
            "https://www.apporo.ai/invite?url=https%3A%2F%2Fevil.example#url=https%3A%2F%2Fha.example",
            // A redirect must not smuggle an invitation fragment past the redirect branch.
            "https://www.apporo.ai/redirect/config_flow_start#url=https%3A%2F%2Fevil.example",
            "https://www.apporo.ai/tag/",
        ] {
            let parsedURL = try #require(URL(string: url))
            #expect(BrandedUniversalLink.route(for: parsedURL) == nil, "Unexpectedly accepted \(url)")
        }
    }

    @Test("Allowed Home Assistant tags are handled immediately")
    func allowedTagsAreHandledImmediately() throws {
        try withAllowedTagDatabase {
            let previousServers = Current.servers
            Current.servers = FakeServerManager(initial: 0)
            defer { Current.servers = previousServers }

            AllowedTag.add("front-door")

            let result = iOSTagManager().handle(userActivity: userActivity(tag: "front-door"))

            guard case let .handled(type) = result else {
                Issue.record("Expected allowed tag to be handled")
                return
            }

            #expect(isGeneric(type))
        }
    }

    private func withAllowedTagDatabase(perform work: () throws -> Void) throws {
        let previousDatabase = Current.database
        let database = try DatabaseQueue(path: ":memory:")

        Current.settingsStore.prefs.removeObject(forKey: legacyAllowedTagsKey)
        try AllowedTagTable().createIfNeeded(database: database)
        Current.database = { database }

        defer {
            Current.database = previousDatabase
            Current.settingsStore.prefs.removeObject(forKey: legacyAllowedTagsKey)
        }

        try work()
    }

    private func userActivity(tag: String) -> NSUserActivity {
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = URL(string: "https://www.apporo.ai/tag/\(tag)")!
        return activity
    }

    private func isGeneric(_ type: TagManagerHandleResult.HandledType) -> Bool {
        if case .generic = type {
            return true
        } else {
            return false
        }
    }
}
