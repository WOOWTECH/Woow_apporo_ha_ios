import Foundation

/// Outbound links used by the connection-error screen and the widget builder.
///
/// Everything here now resolves through `AppConstants.WebURLs`, so the brand domain lives in
/// exactly one place. The upstream "report an issue on GitHub" entry points are gone: the brand
/// has no public issue tracker, and pointing users at Home Assistant's would be wrong.
public enum ExternalLink {
    /// Troubleshooting article shown when the app cannot reach a server.
    public static let companionAppDocs = AppConstants.WebURLs.companionAppDocsTroubleshooting

    /// ⚠️ Home Assistant's community Discord — not an Apporo support channel, and not on the brand
    /// host. It is kept only so its single call site (`ConnectionErrorDetailsView`) keeps compiling;
    /// that call site should be replaced with `AppConstants.WebURLs.support` in the scope-reduction
    /// batch, after which this constant can go.
    public static let discord = URL(string: "https://discord.com/channels/330944238910963714/1284965926336335993")!

    /// Formerly a GitHub issue search. There is no public issue tracker, so this now points at the
    /// brand support page, carrying the failing error domain along so support has some context.
    public static func githubSearchIssue(domain: String) -> URL? {
        guard var components = URLComponents(
            url: AppConstants.WebURLs.support,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "q", value: domain)]
        return components.url
    }

    public static let customWidgetsDocumentation = AppConstants.WebURLs.widgetsDocs
}
