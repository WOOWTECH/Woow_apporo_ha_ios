import Foundation
import PromiseKit
import Shared
#if !targetEnvironment(macCatalyst)
import CoreNFC
#endif

class TagActivityManager: TagManager {
    var isNFCAvailable: Bool {
        false
    }

    func readNFC() -> Promise<String> {
        .init(error: TagManagerError.nfcUnavailable)
    }

    func writeNFC(value: String) -> Promise<String> {
        .init(error: TagManagerError.nfcUnavailable)
    }

    func handle(userActivity: NSUserActivity) -> TagManagerHandleResult {
        guard let url = userActivity.webpageURL else {
            return .unhandled
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let tag = Self.identifier(from: url) {
            let type = handledType(from: userActivity)
            if AllowedTag.contains(tag) {
                fireEvent(tag: tag).cauterize()
                return .handled(type)
            } else {
                return .requiresApproval(tag: tag, type: type)
            }
        }

        if let urlString = components?.queryItems?.first(where: { $0.name.lowercased() == "url" })?.value,
           let url = URL(string: urlString) {
            return .open(url)
        }

        return .unhandled
    }

    func handledType(from userActivity: NSUserActivity) -> TagManagerHandleResult.HandledType {
        .generic
    }

    /// Builds the address written onto a newly provisioned NFC tag.
    ///
    /// Newly written tags always carry the brand host so that they can be claimed by this app's
    /// associated domains. Returns `nil` — instead of trapping — when the identifier could not be
    /// embedded in an address that `identifier(from:)` would read back unchanged.
    static func url(for identifier: String) -> URL? {
        guard isValidTagIdentifier(identifier) else { return nil }

        var components = URLComponents()
        components.scheme = "https"
        components.host = AppConstants.brandHost
        components.path = "/tag/" + identifier
        return components.url
    }

    /// Reads the tag identifier out of the address stored on an NFC tag.
    ///
    /// A tag is a piece of hardware anybody can hand to the user, so its address is untrusted input.
    /// Only an exact `https://<accepted host>/tag/<identifier>` address is accepted: plain HTTP, a
    /// look-alike host, embedded user information, an explicit port, a query string, a fragment or
    /// any extra path segment is rejected rather than scanned.
    static func identifier(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              components.user == nil,
              components.password == nil,
              components.port == nil,
              components.query == nil,
              components.fragment == nil,
              isSupportedTagHost(components.host?.lowercased()) else {
            return nil
        }

        // Split the still-encoded path so that a percent-encoded separator cannot smuggle extra
        // segments past the count check below.
        let encodedParts = components.percentEncodedPath.split(separator: "/", omittingEmptySubsequences: false)
        guard encodedParts.count == 3,
              encodedParts[0].isEmpty,
              encodedParts[1] == "tag",
              let identifier = String(encodedParts[2]).removingPercentEncoding,
              isValidTagIdentifier(identifier) else {
            return nil
        }
        return identifier
    }

    private static func isValidTagIdentifier(_ identifier: String) -> Bool {
        !identifier.isEmpty
            && identifier != "."
            && identifier != ".."
            && !identifier.contains("/")
            && !identifier.contains("?")
            && !identifier.contains("#")
    }

    /// Hosts accepted when reading a tag.
    ///
    /// `AppConstants.brandHost` is the host this app writes. `www.home-assistant.io` is kept for
    /// read compatibility with tags provisioned by the upstream Home Assistant app (and by earlier
    /// internal builds of this app, which also wrote that host); it matches the Android manifest's
    /// `NDEF_DISCOVERED` compatibility entry. The retired `aiot.apporo.io` host is deliberately
    /// *not* accepted: that domain never resolved, so no tag in the field can carry it, and
    /// accepting an unregistered domain would let whoever registers it later mint valid tags.
    private static func isSupportedTagHost(_ host: String?) -> Bool {
        guard let host else { return false }

        var hosts = [AppConstants.brandHost, "www.home-assistant.io"]
        if Current.appConfiguration == .debug {
            hosts.append("next.home-assistant.io")
        }
        return hosts.contains(host)
    }
}

#if !targetEnvironment(macCatalyst)
class iOSTagManager: TagActivityManager {
    override var isNFCAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    override func readNFC() -> Promise<String> {
        let reader = NFCReader()
        var readerRetain: NFCReader? = reader

        return firstly {
            reader.promise
        }.ensure {
            withExtendedLifetime(readerRetain) {
                readerRetain = nil
            }
        }.then {
            Self.identifier(from: $0)
        }
    }

    override func writeNFC(value: String) -> Promise<String> {
        guard let tagURL = Self.url(for: value),
              let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: tagURL),
              let aarPayload = NFCNDEFPayload.androidPackage(payload: "com.apporo.aiot") else {
            return .init(error: TagManagerError.notHomeAssistantTag)
        }

        let writer = NFCWriter(requiredPayload: [uriPayload], optionalPayload: [aarPayload])
        var writerRetain: NFCWriter? = writer

        return firstly {
            writer.promise
        }.ensure {
            withExtendedLifetime(writerRetain) {
                writerRetain = nil
            }
        }.then { message in
            // we use the same logic as reading, so we can be sure the identifier is right
            Self.identifier(from: message)
        }
    }

    override func handledType(from userActivity: NSUserActivity) -> TagManagerHandleResult.HandledType {
        let ndefRecord = userActivity.ndefMessagePayload.records.first
        if ndefRecord == nil || ndefRecord?.typeNameFormat == .empty {
            /*
             For user activities not generated by background tag reading, ndefMessagePayload returns a message
             that contains only one NFCNDEFPayload record. That record has a typeNameFormat of NFCTypeNameFormat
             */
            return .generic
        } else {
            return .nfc
        }
    }

    private static func identifier(from message: NFCNDEFMessage) -> Promise<String> {
        firstly {
            .value(message.records)
        }.compactMapValues { payload in
            payload.wellKnownTypeURIPayload()
        }.compactMapValues { url -> String? in
            Self.identifier(from: url)
        }.map {
            if let value = $0.first {
                return value
            } else {
                throw TagManagerError.notHomeAssistantTag
            }
        }
    }
}
#endif
