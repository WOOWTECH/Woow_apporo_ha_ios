import Foundation
import KeychainAccess
import UIKit
import Version

/// Contains shared constants
public enum AppConstants {
    /// Single source of truth for the brand host used by help-center links and OAuth client metadata.
    /// Changing the brand domain should only ever require editing this one line.
    public static let brandHost = "aiot.apporo.ai"

    /// Help-center / documentation destinations.
    ///
    /// WARNING: the help-center articles behind these paths have NOT been written yet. The paths
    /// below are the planned, structured layout (`https://<brandHost>/<path>`) so that call sites can
    /// be pointed at stable names now and the content can be filled in later.
    /// Before App Store submission every URL here MUST be opened and confirmed to return a readable
    /// page — a reviewer following an in-app help link into a 404 is a rejection risk.
    public enum WebURLs {
        private static let root = "https://\(AppConstants.brandHost)"

        private static func page(_ path: String) -> URL {
            URL(string: "\(root)/\(path)")!
        }

        // MARK: Landing / general

        public static let homeAssistant = URL(string: root)!
        public static let support = page("support")
        public static let privacy = page("privacy")

        // MARK: Getting started

        public static let homeAssistantGetStarted = page("docs/getting-started")
        public static let homeAssistantCompanionGetStarted = page("docs/getting-started")
        public static let companionAppDocs = page("docs")

        // MARK: Troubleshooting

        public static let companionAppDocsTroubleshooting = page("docs/troubleshooting")
        public static let companionAppConnectionSecurityLevel =
            page("docs/troubleshooting#connection-security-level")

        // MARK: Notifications

        public static let notificationsDocs = page("docs/notifications")
        public static let actionableNotificationsDocs = page("docs/notifications#actionable-notifications")
        public static let notificationSoundsDocs = page("docs/notifications#notification-sounds")
        public static let liveActivitiesDocs = page("docs/notifications#live-activities")
        public static let companionLocalPush = page("docs/notifications#local-push")

        // MARK: Platform features

        public static let widgetsDocs = page("docs/widgets")
        public static let appleWatchDocs = page("docs/apple-watch")
        public static let nfcDocs = page("docs/nfc")
        public static let appleDropSupportiOS15 = page("docs/troubleshooting")

        // MARK: Support
        //
        // The upstream companion app exposed the Home Assistant community here (forums, chat,
        // Twitter/Facebook, the GitHub repo and its issue tracker, the beta/translate programmes).
        // Those are Home Assistant's channels, not Apporo's — presenting them under the Apporo
        // brand is both misleading and a trademark problem — so the call sites were removed.
        // Everything that used to funnel into them now funnels into a single support destination.

        /// Where a user is sent when they need help from us. Also the fallback for former
        /// "report an issue" affordances, since the brand has no public issue tracker.
        public static let issues = support
    }

    public enum QueryItems: String, CaseIterable {
        case openMoreInfoDialog = "more-info-entity-id"
        case isComingFromAppIntent = "isComingFromAppIntent"
    }

    public enum WebRTC {
        public static let iceServers = [
            "stun:stun.home-assistant.io:80",
            "stun:stun.home-assistant.io:3478",
        ]
    }

    /// Push endpoints served by **our own** relay on `brandHost`.
    ///
    /// ⚠️ Blocker B-7: these were inherited pointing at `https://mobile-apps.home-assistant.io`,
    /// Home Assistant's public relay. Left that way, every notification for every Apporo user is
    /// registered with, and delivered through, Home Assistant's infrastructure instead of ours —
    /// the app is not actually white-labelled at the push layer. Never point these back upstream.
    ///
    /// ⚠️ Both paths MUST be implemented on `brandHost` before release
    /// (`POST /api/sendPushNotification`, `POST /api/checkRateLimits`), and the Firebase project the
    /// app registers against must be ours (blocker B-1) — the two only work as a pair.
    public enum Firebase {
        private static let apiRoot = "https://\(AppConstants.brandHost)/api"

        /// Sent to Home Assistant at registration as `push_url`; core POSTs notifications here.
        public static let pushURLString = "\(apiRoot)/sendPushNotification"

        /// Queried by the notification settings screen to show the remaining daily push quota.
        public static let rateLimitURL = URL(string: "\(apiRoot)/checkRateLimits")!
    }

    /// Home Assistant Blue
    public static var tintColor: UIColor {
        #if os(iOS)
        return UIColor { [lighterTintColor, darkerTintColor] (traitCollection: UITraitCollection) -> UIColor in
            traitCollection.userInterfaceStyle == .dark ? lighterTintColor : darkerTintColor
        }
        #else
        return lighterTintColor
        #endif
    }

    public static var lighterTintColor: UIColor {
        UIColor(hue: 199.0 / 360.0, saturation: 0.99, brightness: 0.96, alpha: 1.0)
    }

    public static var darkerTintColor: UIColor {
        UIColor(hue: 199.0 / 360.0, saturation: 0.99, brightness: 0.67, alpha: 1.0)
    }

    /// Help icon UIBarButtonItem
    #if os(iOS)
    public static var helpBarButtonItem: UIBarButtonItem {
        with(UIBarButtonItem(
            icon: .helpCircleOutlineIcon,
            target: nil,
            action: nil
        )) {
            $0.accessibilityLabel = L10n.helpLabel
        }
    }
    #endif

    /// The Bundle ID used for the AppGroupID
    public static var BundleID: String {
        let baseBundleID = Bundle.main.bundleIdentifier!
        var removeBundleSuffix = baseBundleID.replacingOccurrences(of: ".APNSAttachmentService", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".Intents", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".NotificationContentExtension", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".TodayWidget", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".watchkitapp.watchkitextension", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".watchkitapp", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".Widgets", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".ShareExtension", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".PushProvider", with: "")
        removeBundleSuffix = removeBundleSuffix.replacingOccurrences(of: ".Matter", with: "")

        return removeBundleSuffix
    }

    /// The app's custom URL scheme, used for deep links and for the OAuth redirect.
    ///
    /// The single source of truth is the `ENV_URL_HANDLER` build setting, which Xcode substitutes
    /// into the app's `Info.plist` (`CFBundleURLTypes`): Release `apporoaiot`, Debug
    /// `apporoaiot-dev` (the Debug build also carries the `.dev` bundle-id suffix, so both variants
    /// can be installed side by side without fighting over the scheme).
    ///
    /// We read the scheme back out of the running bundle rather than hard-coding it, because a
    /// hard-coded string here would silently drift from `ENV_URL_HANDLER` and the OAuth
    /// `redirect_uri` would then name a scheme iOS never delivers back to us — login would hang on
    /// the callback with no error. App extensions (widgets, intents, notification service …) do not
    /// declare `CFBundleURLTypes`, so they fall back to `expectedURLScheme`.
    public static let urlScheme: String = registeredURLScheme() ?? expectedURLScheme

    /// Compile-time counterpart of the `ENV_URL_HANDLER` build setting.
    ///
    /// ⚠️ MUST be kept in sync by hand with `ENV_URL_HANDLER` in `project.pbxproj` /
    /// `BRAND_URL_SCHEME` in `Configuration/Brand.xcconfig`. It is what every app extension uses to
    /// build deep links back into the app, so a mismatch breaks widgets and App Intents even though
    /// the app itself would keep working off the value read from its own Info.plist.
    public static let expectedURLScheme: String = {
        #if DEBUG
        return "apporoaiot-dev"
        #else
        return "apporoaiot"
        #endif
    }()

    /// The first non-empty scheme the running bundle registers, or `nil` for bundles (extensions)
    /// that register none. A literal starting with `$` means the build setting was never
    /// substituted, which is a misconfiguration rather than a usable scheme.
    private static func registeredURLScheme() -> String? {
        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] else {
            return nil
        }
        return urlTypes
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }
            .flatMap { $0 }
            .first { !$0.isEmpty && !$0.hasPrefix("$") }
    }

    public static let deeplinkURL = URL(string: "\(urlScheme)://")!

    public enum OAuth {
        /// Public client metadata URL advertised to Home Assistant as `client_id` (blocker B-6).
        ///
        /// It previously pointed at `https://woowtech.github.io/Woow_apporo_ha_app/android` — the
        /// **Android** client's page. iOS was authenticating under Android's identity, which is why
        /// this moved onto the brand host.
        ///
        /// ⚠️ THIS PAGE IS NOT PUBLISHED YET. Home Assistant's IndieAuth implementation really does
        /// fetch this URL during login, so before App Review submission confirm that it:
        ///   * is readable anonymously — not a 404, not a login page, not a redirect to one;
        ///   * is served over HTTPS with a certificate the OS trusts;
        ///   * returns HTML containing `<link rel="redirect_uri" href="…">` for **every** scheme the
        ///     app ships with, i.e. both `apporoaiot://auth-callback` (Release) and
        ///     `apporoaiot-dev://auth-callback` (Debug) — otherwise Debug builds cannot log in;
        ///   * keeps `<link rel="redirect_uri">` in sync whenever `urlScheme` changes.
        /// Until it is live, login fails against any Home Assistant that enforces IndieAuth discovery.
        public static let clientID = "https://\(AppConstants.brandHost)/ios"
        public static let redirectURI = "\(AppConstants.urlScheme)://auth-callback"
    }

    /// Roots a scheme-less, slash-less navigation path (`map/0` → `/map/0`) so an HA path that is
    /// missing its leading slash still resolves in the frontend. Anything already rooted, or that
    /// carries a scheme — `https://`, `mailto:`, or the app's own `apporoaiot://` deep links —
    /// is returned unchanged, so external URLs open in the browser and deep links are handled by
    /// the URL handler as deep links rather than being coerced into a path.
    public static func normalizedNavigationDestination(_ raw: String) -> String {
        guard !raw.hasPrefix("/"), URL(string: raw)?.scheme == nil else { return raw }
        return "/" + raw
    }

    public static func invitationURL(serverURL: URL) -> URL? {
        guard let encodedURLString = serverURL.absoluteString
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: "https://my.home-assistant.io/invite/#url=\(encodedURLString)")
    }

    public static func navigateDeeplinkURL(
        path: String,
        serverId: String,
        queryParams: String? = nil,
        avoidUnnecessaryReload: Bool
    ) -> URL? {
        var url = URL(
            string: "\(AppConstants.deeplinkURL.absoluteString)navigate/\(path)?server=\(serverId)&avoidUnnecessaryReload=\(avoidUnnecessaryReload)&\(AppConstants.QueryItems.isComingFromAppIntent.rawValue)=true"
        )

        if let queryParams, let newURL = URL(string: "\(url?.absoluteString ?? "")&\(queryParams)") {
            url = newURL
        }

        return url
    }

    public static func openPageDeeplinkURL(path: String, serverId: String) -> URL? {
        AppConstants.navigateDeeplinkURL(path: path, serverId: serverId, avoidUnnecessaryReload: true)?
            .withWidgetAuthenticity()
    }

    public static func openEntityDeeplinkURL(entityId: String, serverId: String) -> URL? {
        AppConstants.navigateDeeplinkURL(
            path: "",
            serverId: serverId,
            queryParams: "\(AppConstants.QueryItems.openMoreInfoDialog.rawValue)=\(entityId)",
            avoidUnnecessaryReload: true
        )?.withWidgetAuthenticity()
    }

    public static func openCameraDeeplinkURL(entityId: String, serverId: String) -> URL? {
        URL(
            string: "\(AppConstants.deeplinkURL.absoluteString)camera/?entityId=\(entityId)&serverId=\(serverId)&\(AppConstants.QueryItems.isComingFromAppIntent.rawValue)=true"
        )
    }

    @available(iOS 16.0, watchOS 9.0, *)
    public static func todoListAddItemURL(listId: String, serverId: String) -> URL? {
        guard !serverId.isEmpty, !listId.isEmpty else {
            return nil
        }
        return URL(string: "\(AppConstants.deeplinkURL.absoluteString)navigate/todo")?.appending(queryItems: [
            URLQueryItem(name: "entity_id", value: listId),
            URLQueryItem(name: "serverId", value: serverId),
            URLQueryItem(name: "add_item", value: "true"),
        ])
    }

    @available(iOS 16.0, watchOS 9.0, *)
    public static func todoListOpenURL(listId: String, serverId: String) -> URL? {
        guard !serverId.isEmpty, !listId.isEmpty else {
            return nil
        }
        return URL(string: "\(AppConstants.deeplinkURL.absoluteString)navigate/todo")?.appending(queryItems: [
            URLQueryItem(name: "entity_id", value: listId),
            URLQueryItem(name: "serverId", value: serverId),
        ])
    }

    public static func assistDeeplinkURL(serverId: String, pipelineId: String, startListening: Bool) -> URL? {
        URL(
            string: "\(AppConstants.deeplinkURL.absoluteString)assist?serverId=\(serverId)&pipelineId=\(pipelineId)&startListening=\(startListening)"
        )?.withWidgetAuthenticity()
    }

    public static var createCustomWidgetURL: URL {
        URL(string: "\(AppConstants.deeplinkURL.absoluteString)createCustomWidget")!
    }

    /// The App Group ID used by the app and extensions for sharing data.
    public static var AppGroupID: String {
        "group." + BundleID.lowercased()
    }

    public static var AppGroupContainer: URL {
        let fileManager = FileManager.default

        let groupDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.AppGroupID)

        guard let groupDir else {
            Current.Log.error("Unable to get app group container URL; falling back to temporary directory")
            return URL(fileURLWithPath: NSTemporaryDirectory())
        }

        return groupDir
    }

    public static var appGRDBFile: URL {
        let fileManager = FileManager.default
        let directoryURL = Self.AppGroupContainer.appendingPathComponent("databases", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Current.Log.error("Failed to create App GRDB file")
            }
        }
        let databaseURL = directoryURL.appendingPathComponent("App.sqlite")
        return databaseURL
    }

    public static var clientEventsFile: URL {
        let fileManager = FileManager.default
        let directoryURL = Self.AppGroupContainer.appendingPathComponent("databases", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Current.Log.error("Failed to create Client Events file")
            }
        }
        let eventsURL = directoryURL.appendingPathComponent("clientEvents.json")
        return eventsURL
    }

    public static var notificationHistoryFile: URL {
        let fileManager = FileManager.default
        let directoryURL = Self.AppGroupContainer.appendingPathComponent("databases", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Current.Log.error("Failed to create Notification History file")
            }
        }
        let historyURL = directoryURL.appendingPathComponent("notificationHistory.json")
        return historyURL
    }

    public static var widgetsCacheURL: URL = {
        let fileManager = FileManager.default
        let directoryURL = Self.AppGroupContainer.appendingPathComponent("caches/widgets", isDirectory: true)
        return directoryURL
    }()

    public static func widgetCachedStates(widgetId: String) -> URL {
        let fileManager = FileManager.default
        let directoryURL = Self.widgetsCacheURL
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Current.Log.error("Failed to create Client Events file")
            }
        }
        let eventsURL = directoryURL.appendingPathComponent("/widgetId-\(widgetId).json")
        return eventsURL
    }

    public static var watchMagicItemsInfo: URL {
        let fileManager = FileManager.default
        let directoryURL = Self.AppGroupContainer.appendingPathComponent("caches", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                Current.Log.error("Failed to magic items info file")
            }
        }
        let eventsURL = directoryURL.appendingPathComponent("magicItemsInfo.json")
        return eventsURL
    }

    public static var LogsDirectory: URL {
        let fileManager = FileManager.default
        let directoryURL = AppGroupContainer.appendingPathComponent("logs", isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError("Error while attempting to create data store URL: \(error)")
            }
        }

        return directoryURL
    }

    public static var DownloadsDirectory: URL {
        var directoryURL: URL = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first!

        // Save directly in macOS Downloads folder if running on Catalyst and allowed access to download folder when
        // prompted.
        if Current.isCatalyst, let macDownloadFolder = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first {
            directoryURL = macDownloadFolder
        } else {
            directoryURL = directoryURL.appendingPathComponent(
                "Downloads",
                isDirectory: true
            )
        }
        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            do {
                try FileManager.default.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            } catch {
                fatalError("Error while attempting to create downloads path URL: \(error)")
            }
        }

        return directoryURL
    }

    /// An initialized Keychain from KeychainAccess.
    public static var Keychain: KeychainAccess.Keychain {
        KeychainAccess.Keychain(service: BundleID)
    }

    /// A permanent ID stored in UserDefaults and Keychain.
    public static var PermanentID: String {
        let storageKey = "deviceUID"
        let defaultsStore = UserDefaults(suiteName: AppConstants.AppGroupID)
        let keychain = KeychainAccess.Keychain(service: storageKey)

        if let keychainUID = keychain[storageKey] {
            return keychainUID
        }

        if let userDefaultsUID = defaultsStore?.object(forKey: storageKey) as? String {
            return userDefaultsUID
        }

        let newID = UUID().uuidString

        if keychain[storageKey] == nil {
            keychain[storageKey] = newID
        }

        if defaultsStore?.object(forKey: storageKey) == nil {
            defaultsStore?.setValue(newID, forKey: storageKey)
        }

        return newID
    }

    public static var build: String {
        SharedPlistFiles.Info.cfBundleVersion
    }

    public static var version: String {
        SharedPlistFiles.Info.cfBundleShortVersionString
    }

    static var clientVersion: Version {
        // swiftlint:disable:next force_try
        var clientVersion = try! Version(version)
        clientVersion.build = build
        return clientVersion
    }
}

public extension Version {
    static let canSendDeviceID: Version = .init(minor: 104)
    static let pedometerIconsAvailable: Version = .init(minor: 105)
    static let tagWebhookAvailable: Version = .init(minor: 114, prerelease: "b5")
    static let mobileAppConfig: Version = .init(minor: 115, prerelease: "any0")
    static let localPushConfirm: Version = .init(major: 2021, minor: 10, prerelease: "any0")
    static let externalBusCommandRestart: Version = .init(major: 2021, minor: 12, prerelease: "b6")
    static let updateLocationGPSOptional: Version = .init(major: 2022, minor: 2, prerelease: "any0")
    static let fullWebhookSecretKey: Version = .init(major: 2022, minor: 3)
    static let conversationWebhook: Version = .init(major: 2023, minor: 2, prerelease: "any0")
    static let externalBusCommandSidebar: Version = .init(major: 2023, minor: 4, prerelease: "b3")
    static let externalBusCommandAutomationEditor: Version = .init(major: 2024, minor: 2, prerelease: "any0")
    static let canUseAppThemeForStatusBar: Version = .init(major: 2024, minor: 7)
    /// The version where the app can subscribe to entities changes with a filter (e.g. only state changes from sensor
    /// domain)
    static let canSubscribeEntitiesChangesWithFilter: Version = .init(major: 2024, minor: 10)
    /// Allows app to ask frontend to navigate to a specific page
    static let canNavigateThroughFrontend: Version = .init(major: 2025, minor: 6, prerelease: "any0")
    /// Allows app to ask frontend to navigate to a more info dialog
    static let canNavigateMoreInfoDialogThroughFrontend: Version = .init(major: 2026, minor: 1, prerelease: "any0")
    /// Frontend introduces the quickbar with Ctrl+K keyboard shortcut in 2026.2
    static let quickSearchKeyboardShortcut: Version = .init(major: 2026, minor: 2, prerelease: "any0")
    /// Core accepts `in_zones` in update_location payloads from 2026.6.0.
    static let inZonesOnLocationUpdate: Version = .init(major: 2026, minor: 6, patch: 0, prerelease: "any0")

    var coreRequiredString: String {
        L10n.requiresVersion(String(format: "core-%d.%d", major, minor ?? -1))
    }
}
