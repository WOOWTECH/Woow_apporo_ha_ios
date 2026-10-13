import Foundation
import PromiseKit
import Shared

struct RateLimitResponse: Decodable {
    var target: String

    struct RateLimits: Decodable {
        var attempts: Int
        var successful: Int
        var errors: Int
        var total: Int
        var maximum: Int
        var remaining: Int
        var resetsAt: Date
    }

    var rateLimits: RateLimits
}

class NotificationRateLimitsAPI {
    class func rateLimits(pushID: String) -> Promise<RateLimitResponse> {
        firstly { () -> Promise<URLRequest> in
            do {
                // Blocker B-7: this used to call Home Assistant's public relay
                // (mobile-apps.home-assistant.io), which knows nothing about our push tokens.
                // The endpoint now lives on our own relay; see AppConstants.Firebase.
                var urlRequest = URLRequest(url: AppConstants.Firebase.rateLimitURL)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: [
                    "push_token": pushID,
                ])
                return .value(urlRequest)
            } catch {
                return .init(error: error)
            }
        }.then {
            URLSession.shared.dataTask(.promise, with: $0)
        }.map { data, _ throws -> RateLimitResponse in
            let decoder = with(JSONDecoder()) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.sss'Z'"
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(identifier: "UTC")
                $0.dateDecodingStrategy = .formatted(dateFormatter)
            }
            return try decoder.decode(RateLimitResponse.self, from: data)
        }
    }
}
