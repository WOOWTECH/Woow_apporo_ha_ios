import Foundation
import Shared
import Testing

struct AppConstantsTests {
    @Test func testInvitationURL() async throws {
        let serverURL = URL(string: "https://demo.home-assistant.io")!
        let expected = "https://my.home-assistant.io/invite/#url=https://demo.home-assistant.io"
        let result = AppConstants.invitationURL(serverURL: serverURL)?.absoluteString
        assert(result == expected, "Expected \(expected), got \(String(describing: result))")
    }

    @Test func testBrandHost() async throws {
        assert(AppConstants.brandHost == "www.apporo.ai", "brand host must be the www.apporo.ai domain")
    }

    @Test func testWebURLsAllLiveOnBrandHost() async throws {
        // Guards the regression this migration exists to fix: a help link left on an upstream
        // Home Assistant domain, or on the dead `www.apporo.ai` domain.
        let all: [URL] = [
            AppConstants.WebURLs.homeAssistant,
            AppConstants.WebURLs.support,
            AppConstants.WebURLs.privacy,
            AppConstants.WebURLs.homeAssistantGetStarted,
            AppConstants.WebURLs.homeAssistantCompanionGetStarted,
            AppConstants.WebURLs.companionAppDocs,
            AppConstants.WebURLs.companionAppDocsTroubleshooting,
            AppConstants.WebURLs.companionAppConnectionSecurityLevel,
            AppConstants.WebURLs.notificationsDocs,
            AppConstants.WebURLs.actionableNotificationsDocs,
            AppConstants.WebURLs.notificationSoundsDocs,
            AppConstants.WebURLs.liveActivitiesDocs,
            AppConstants.WebURLs.companionLocalPush,
            AppConstants.WebURLs.widgetsDocs,
            AppConstants.WebURLs.appleWatchDocs,
            AppConstants.WebURLs.nfcDocs,
            AppConstants.WebURLs.appleDropSupportiOS15,
            AppConstants.WebURLs.issues,
        ]
        for url in all {
            assert(url.scheme == "https", "\(url) must use https")
            assert(url.host == AppConstants.brandHost, "\(url) must be served by \(AppConstants.brandHost)")
        }
    }

    @Test func testWebURLPaths() async throws {
        let root = "https://\(AppConstants.brandHost)"
        assert(AppConstants.WebURLs.homeAssistant.absoluteString == root)
        assert(AppConstants.WebURLs.support.absoluteString == "\(root)/help/support")
        assert(AppConstants.WebURLs.privacy.absoluteString == "\(root)/privacy")
        assert(AppConstants.WebURLs.companionAppDocs.absoluteString == "\(root)/help")
        assert(AppConstants.WebURLs.companionAppDocsTroubleshooting.absoluteString == "\(root)/help/troubleshooting")
        assert(AppConstants.WebURLs.notificationsDocs.absoluteString == "\(root)/help/notifications")
        assert(AppConstants.WebURLs.nfcDocs.absoluteString == "\(root)/help/nfc")
        // The upstream community entry points (forums / chat / twitter / facebook / repo) are gone;
        // anything that used to "report an issue" now goes to our support page instead.
        assert(AppConstants.WebURLs.issues == AppConstants.WebURLs.support)
    }

    @Test func testQueryItemsRawValues() async throws {
        assert(AppConstants.QueryItems.openMoreInfoDialog.rawValue == "more-info-entity-id")
        assert(AppConstants.QueryItems.isComingFromAppIntent.rawValue == "isComingFromAppIntent")
    }

    @Test func testOpenEntityDeeplinkURL() async throws {
        let entityId = "light.living_room"
        let serverId = "server123"
        let result = AppConstants.openEntityDeeplinkURL(entityId: entityId, serverId: serverId)?.absoluteString

        // Verify the URL contains empty path (navigate/?) and correct query params
        assert(result?.contains("navigate/?") == true, "URL should contain navigate/? with empty path")
        assert(
            result?.contains("more-info-entity-id=\(entityId)") == true,
            "URL should contain more-info-entity-id query parameter"
        )
        assert(result?.contains("server=\(serverId)") == true, "URL should contain server query parameter")
        assert(
            result?.contains("avoidUnnecessaryReload=true") == true,
            "URL should contain avoidUnnecessaryReload=true"
        )
        assert(
            result?.contains("isComingFromAppIntent=true") == true,
            "URL should contain isComingFromAppIntent=true"
        )
    }

    @available(iOS 16.0, *)
    @Test func testTodoListAddItemURL() async throws {
        let listId = "todo.shopping_list"
        let serverId = "server123"
        let url = AppConstants.todoListAddItemURL(listId: listId, serverId: serverId)
        assert(url != nil, "Expected URL to be created for valid listId and serverId")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        assert(components?.scheme == AppConstants.deeplinkURL.scheme, "URL should use the app deeplink scheme")
        assert(components?.host == "navigate", "URL host should be navigate")
        assert(components?.path == "/todo", "URL path should be /todo")

        let queryItems = components?.queryItems ?? []
        let queryValues = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        assert(queryValues["entity_id"] == listId, "URL should include entity_id query item")
        assert(queryValues["serverId"] == serverId, "URL should include serverId query item")
        assert(queryValues["add_item"] == "true", "URL should include add_item query item set to true as String")
    }

    @available(iOS 16.0, *)
    @Test func testTodoListOpenURL() async throws {
        let listId = "todo.shopping_list"
        let serverId = "server123"
        let url = AppConstants.todoListOpenURL(listId: listId, serverId: serverId)
        assert(url != nil, "Expected URL to be created for valid listId and serverId")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        assert(components?.scheme == AppConstants.deeplinkURL.scheme, "URL should use the app deeplink scheme")
        assert(components?.host == "navigate", "URL host should be navigate")
        assert(components?.path == "/todo", "URL path should be /todo")

        let queryItems = components?.queryItems ?? []
        let queryValues = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        assert(queryValues["entity_id"] == listId, "URL should include entity_id query item")
        assert(queryValues["serverId"] == serverId, "URL should include serverId query item")
        assert(queryValues["add_item"] == nil, "URL should not include add_item in query item")
    }

    @Test func testPushEndpointsAreOnOurOwnRelay() async throws {
        // Blocker B-7: if either of these drifts back to mobile-apps.home-assistant.io, every push
        // for every user is registered with and delivered through Home Assistant's public relay.
        assert(
            AppConstants.Firebase.pushURLString == "https://\(AppConstants.brandHost)/api/sendPushNotification",
            "push_url must point at our own relay"
        )
        assert(
            AppConstants.Firebase.rateLimitURL
                .absoluteString == "https://\(AppConstants.brandHost)/api/checkRateLimits",
            "rate limit lookup must point at our own relay"
        )
    }

    @Test func testURLSchemeAndOAuthClientIdentity() async throws {
        // The scheme is read from the running bundle's CFBundleURLTypes (ENV_URL_HANDLER), so this
        // also catches the Info.plist and the Swift constant disagreeing.
        assert(
            AppConstants.urlScheme == AppConstants.expectedURLScheme,
            "Info.plist URL scheme (\(AppConstants.urlScheme)) disagrees with the compile-time "
                + "expectation (\(AppConstants.expectedURLScheme)) — check ENV_URL_HANDLER"
        )
        assert(AppConstants.urlScheme.hasPrefix("apporoaiot"), "scheme must be the aiot scheme")
        assert(AppConstants.deeplinkURL.absoluteString == "\(AppConstants.urlScheme)://")
        // Blocker B-6: iOS used to authenticate with the Android client's client_id.
        assert(AppConstants.OAuth.clientID == "https://\(AppConstants.brandHost)/ios")
        assert(AppConstants.OAuth.redirectURI == "\(AppConstants.urlScheme)://auth-callback")
    }

    @Test func testNormalizedNavigationDestination() async throws {
        func normalized(_ raw: String) -> String { AppConstants.normalizedNavigationDestination(raw) }

        // Rooted HA path — unchanged.
        assert(normalized("/map/0") == "/map/0")
        // Slash-less HA path — rooted so it still navigates the frontend.
        assert(normalized("map/0") == "/map/0")
        // Deep links are left untouched — the URL handler processes them as deep links.
        let deeplink = "\(AppConstants.urlScheme)://navigate/map/0"
        assert(normalized(deeplink) == deeplink)
        // External URLs — untouched so they open in the browser.
        assert(normalized("https://google.com") == "https://google.com")
        assert(normalized("https://www.google.com") == "https://www.google.com")
        // Other schemes — untouched.
        assert(normalized("mailto:a@b.com") == "mailto:a@b.com")
    }
}
