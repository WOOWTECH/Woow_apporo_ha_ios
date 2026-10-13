import Foundation
import Shared
import Testing

struct AppConstantsTests {
    @Test func testInvitationURL() async throws {
        let serverURL = URL(string: "https://demo.home-assistant.io")!
        // 邀請連結已改由品牌 host 提供(AppConstants.invitationURL 用 brandHost),
        // 不再是上游的 my.home-assistant.io。www.apporo.ai/invite 已上線,
        // 且 AASA 同時宣告 /invite 與 /invite/ 兩種形式。
        let expected = "https://\(AppConstants.brandHost)/invite/#url=https://demo.home-assistant.io"
        let result = AppConstants.invitationURL(serverURL: serverURL)?.absoluteString
        #expect(result == expected, "Expected \(expected), got \(String(describing: result))")
    }

    @Test func testBrandHost() async throws {
        #expect(AppConstants.brandHost == "www.apporo.ai", "brand host must be the www.apporo.ai domain")
    }

    @Test func testWebURLsAllLiveOnBrandHost() async throws {
        // Guards the regression this migration exists to fix: a help link left on an upstream
        // Home Assistant domain, or on one of the two dead Apporo domains — `aiot.apporo.io`
        // (retired 2026-09) and `aiot.apporo.ai` (has DNS but no origin on Cloudflare, so the
        // whole host answers 404). The live brand host is `www.apporo.ai`.
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
            #expect(url.scheme == "https", "\(url) must use https")
            #expect(url.host == AppConstants.brandHost, "\(url) must be served by \(AppConstants.brandHost)")
        }
    }

    @Test func testWebURLPaths() async throws {
        let root = "https://\(AppConstants.brandHost)"
        #expect(AppConstants.WebURLs.homeAssistant.absoluteString == root)
        #expect(AppConstants.WebURLs.support.absoluteString == "\(root)/help/support")
        #expect(AppConstants.WebURLs.privacy.absoluteString == "\(root)/privacy")
        #expect(AppConstants.WebURLs.companionAppDocs.absoluteString == "\(root)/help")
        #expect(AppConstants.WebURLs.companionAppDocsTroubleshooting.absoluteString == "\(root)/help/troubleshooting")
        #expect(AppConstants.WebURLs.notificationsDocs.absoluteString == "\(root)/help/notifications")
        #expect(AppConstants.WebURLs.nfcDocs.absoluteString == "\(root)/help/nfc")
        // The upstream community entry points (forums / chat / twitter / facebook / repo) are gone;
        // anything that used to "report an issue" now goes to our support page instead.
        #expect(AppConstants.WebURLs.issues == AppConstants.WebURLs.support)
    }

    @Test func testQueryItemsRawValues() async throws {
        #expect(AppConstants.QueryItems.openMoreInfoDialog.rawValue == "more-info-entity-id")
        #expect(AppConstants.QueryItems.isComingFromAppIntent.rawValue == "isComingFromAppIntent")
    }

    @Test func testOpenEntityDeeplinkURL() async throws {
        let entityId = "light.living_room"
        let serverId = "server123"
        let result = AppConstants.openEntityDeeplinkURL(entityId: entityId, serverId: serverId)?.absoluteString

        // Verify the URL contains empty path (navigate/?) and correct query params
        #expect(result?.contains("navigate/?") == true, "URL should contain navigate/? with empty path")
        #expect(
            result?.contains("more-info-entity-id=\(entityId)") == true,
            "URL should contain more-info-entity-id query parameter"
        )
        #expect(result?.contains("server=\(serverId)") == true, "URL should contain server query parameter")
        #expect(
            result?.contains("avoidUnnecessaryReload=true") == true,
            "URL should contain avoidUnnecessaryReload=true"
        )
        #expect(
            result?.contains("isComingFromAppIntent=true") == true,
            "URL should contain isComingFromAppIntent=true"
        )
    }

    @available(iOS 16.0, *)
    @Test func testTodoListAddItemURL() async throws {
        let listId = "todo.shopping_list"
        let serverId = "server123"
        let url = AppConstants.todoListAddItemURL(listId: listId, serverId: serverId)
        #expect(url != nil, "Expected URL to be created for valid listId and serverId")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.scheme == AppConstants.deeplinkURL.scheme, "URL should use the app deeplink scheme")
        #expect(components?.host == "navigate", "URL host should be navigate")
        #expect(components?.path == "/todo", "URL path should be /todo")

        let queryItems = components?.queryItems ?? []
        let queryValues = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        #expect(queryValues["entity_id"] == listId, "URL should include entity_id query item")
        #expect(queryValues["serverId"] == serverId, "URL should include serverId query item")
        #expect(queryValues["add_item"] == "true", "URL should include add_item query item set to true as String")
    }

    @available(iOS 16.0, *)
    @Test func testTodoListOpenURL() async throws {
        let listId = "todo.shopping_list"
        let serverId = "server123"
        let url = AppConstants.todoListOpenURL(listId: listId, serverId: serverId)
        #expect(url != nil, "Expected URL to be created for valid listId and serverId")

        let components = URLComponents(url: url!, resolvingAgainstBaseURL: false)
        #expect(components?.scheme == AppConstants.deeplinkURL.scheme, "URL should use the app deeplink scheme")
        #expect(components?.host == "navigate", "URL host should be navigate")
        #expect(components?.path == "/todo", "URL path should be /todo")

        let queryItems = components?.queryItems ?? []
        let queryValues = Dictionary(uniqueKeysWithValues: queryItems.map { ($0.name, $0.value) })
        #expect(queryValues["entity_id"] == listId, "URL should include entity_id query item")
        #expect(queryValues["serverId"] == serverId, "URL should include serverId query item")
        #expect(queryValues["add_item"] == nil, "URL should not include add_item in query item")
    }

    @Test func testPushEndpointsAreOnOurOwnRelay() async throws {
        // Blocker B-7: if either of these drifts back to mobile-apps.home-assistant.io, every push
        // for every user is registered with and delivered through Home Assistant's public relay.
        #expect(
            AppConstants.Firebase.pushURLString == "https://\(AppConstants.brandHost)/api/sendPushNotification",
            "push_url must point at our own relay"
        )
        #expect(
            AppConstants.Firebase.rateLimitURL
                .absoluteString == "https://\(AppConstants.brandHost)/api/checkRateLimits",
            "rate limit lookup must point at our own relay"
        )
    }

    @Test func testURLSchemeAndOAuthClientIdentity() async throws {
        // The scheme is read from the running bundle's CFBundleURLTypes (ENV_URL_HANDLER), so this
        // also catches the Info.plist and the Swift constant disagreeing.
        #expect(
            AppConstants.urlScheme == AppConstants.expectedURLScheme,
            // #expect 的訊息參數型別是 Comment,只吃字串「字面值」;用 + 串接會變成
            // String 運算式而編譯失敗。所以這裡寫成單一內插字面值,不要拆行串接。
            "Info.plist URL scheme (\(AppConstants.urlScheme)) disagrees with the compile-time expectation (\(AppConstants.expectedURLScheme)) — check ENV_URL_HANDLER"
        )
        #expect(AppConstants.urlScheme.hasPrefix("apporoaiot"), "scheme must be the aiot scheme")
        #expect(AppConstants.deeplinkURL.absoluteString == "\(AppConstants.urlScheme)://")
        // Blocker B-6: iOS used to authenticate with the Android client's client_id.
        #expect(AppConstants.OAuth.clientID == "https://\(AppConstants.brandHost)/ios")
        #expect(AppConstants.OAuth.redirectURI == "\(AppConstants.urlScheme)://auth-callback")
    }

    @Test func testNormalizedNavigationDestination() async throws {
        func normalized(_ raw: String) -> String { AppConstants.normalizedNavigationDestination(raw) }

        // Rooted HA path — unchanged.
        #expect(normalized("/map/0") == "/map/0")
        // Slash-less HA path — rooted so it still navigates the frontend.
        #expect(normalized("map/0") == "/map/0")
        // Deep links are left untouched — the URL handler processes them as deep links.
        let deeplink = "\(AppConstants.urlScheme)://navigate/map/0"
        #expect(normalized(deeplink) == deeplink)
        // External URLs — untouched so they open in the browser.
        #expect(normalized("https://google.com") == "https://google.com")
        #expect(normalized("https://www.google.com") == "https://www.google.com")
        // Other schemes — untouched.
        #expect(normalized("mailto:a@b.com") == "mailto:a@b.com")
    }
}
