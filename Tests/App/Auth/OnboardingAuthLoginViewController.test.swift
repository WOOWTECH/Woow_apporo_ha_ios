@testable import HomeAssistant
import PromiseKit
import Shared
import WebKit
import XCTest

class OnboardingAuthLoginViewControllerImplTests: XCTestCase {
    private var controller: OnboardingAuthLoginViewControllerImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()

        controller = try .init(authDetails: .init(baseURL: URL(string: "https://www.example.com")!))
    }

    func testError() {
        controller.webView(controller.webViewForTests, didFail: nil, withError: URLError(.badServerResponse))
        XCTAssertTrue(controller.promise.isRejected)
    }

    func testAuthorizationRequestUsesSharedOAuthConstants() throws {
        let details = try OnboardingAuthDetails(baseURL: URL(string: "https://example.com")!)
        let query = try XCTUnwrap(URLComponents(url: details.url, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(query.first { $0.name == "client_id" }?.value, AppConstants.OAuth.clientID)
        XCTAssertEqual(query.first { $0.name == "redirect_uri" }?.value, AppConstants.OAuth.redirectURI)
        XCTAssertEqual(details.scheme, AppConstants.urlScheme)
    }

    func testNonCallbackAppURLsDoNotCompleteLogin() {
        let scheme = AppConstants.urlScheme
        for value in [
            // A scheme that merely *starts with* ours must not be accepted: the original
            // implementation used hasPrefix and would have matched this.
            "\(scheme)x://auth-callback",
            // Our scheme, but not the callback host.
            "\(scheme)://navigate",
            // Another app's scheme entirely.
            "woowhome://auth-callback",
        ] {
            let url = URL(string: value)!
            controller.webView(
                controller.webViewForTests,
                decidePolicyFor: FakeWKNavigationAction(request: URLRequest(url: url)),
                decisionHandler: { XCTAssertEqual($0, .allow) }
            )
            XCTAssertFalse(controller.promise.isResolved)
        }
    }

    func testDecisionHandlerWithCallbackURL() {
        let url = URL(string: "\(AppConstants.urlScheme)://auth-callback")!

        let expectation = expectation(description: "decision handler")
        controller.webView(
            controller.webViewForTests,
            decidePolicyFor: FakeWKNavigationAction(request: URLRequest(url: url)),
            decisionHandler: { policy in
                XCTAssertEqual(policy, .cancel)
                expectation.fulfill()
            }
        )
        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(try hang(controller.promise), url)
    }

    func testResolvedServerURLCapturedFromLastNavigation() {
        // Simulate the server redirecting the login page to a different port before the callback.
        let redirectedURL = URL(string: "http://example.com:8124/auth/authorize")!
        let httpExpectation = expectation(description: "http nav")
        controller.webView(
            controller.webViewForTests,
            decidePolicyFor: FakeWKNavigationAction(request: URLRequest(url: redirectedURL)),
            decisionHandler: { _ in httpExpectation.fulfill() }
        )
        wait(for: [httpExpectation], timeout: 10.0)

        let callbackURL = URL(string: "\(AppConstants.urlScheme)://auth-callback?code=code_123")!
        let callbackExpectation = expectation(description: "callback nav")
        controller.webView(
            controller.webViewForTests,
            decidePolicyFor: FakeWKNavigationAction(request: URLRequest(url: callbackURL)),
            decisionHandler: { _ in callbackExpectation.fulfill() }
        )
        wait(for: [callbackExpectation], timeout: 10.0)

        // webView.url is nil in tests (no real load), so it falls back to the last navigated URL.
        XCTAssertEqual(controller.resolvedServerURL, redirectedURL)
        XCTAssertEqual(try hang(controller.promise), callbackURL)
    }

    func testDecisionHandlerWithHttpScheme() {
        let url = URL(string: "http://example.com")!

        let expectation = expectation(description: "decision handler")
        controller.webView(
            controller.webViewForTests,
            decidePolicyFor: FakeWKNavigationAction(request: URLRequest(url: url)),
            decisionHandler: { policy in
                XCTAssertEqual(policy, .allow)
                expectation.fulfill()
            }
        )
        wait(for: [expectation], timeout: 10.0)

        XCTAssertFalse(controller.promise.isResolved)
    }
}

private class FakeWKNavigationAction: WKNavigationAction {
    init(request: URLRequest) {
        self.overrideRequest = request
    }

    var overrideRequest: URLRequest?

    override var request: URLRequest {
        overrideRequest ?? super.request
    }
}
