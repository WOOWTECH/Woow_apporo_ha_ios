import Vapor

func routes(_ app: Application) throws {
    app.get { req in
        req.redirect(to: "https://companion.home-assistant.io")
    }

    app.group("push") { push in
        // Release bundle id; dev deployments override it with APNS_TOPIC=com.apporo.aiot.dev.
        let pushTopic = Environment.get("APNS_TOPIC") ?? "com.apporo.aiot"
        let pushController = PushController(appIdPrefix: pushTopic)

        push.post("send") { req in
            try await pushController.send(req: req)
        }
    }

    app.group("rate_limits") { rateLimits in
        let rateLimitsController = RateLimitsController()

        rateLimits.post("check") { req in
            try await rateLimitsController.check(req: req)
        }
    }
}
