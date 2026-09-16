import XCTest

class HomeAssistantUITests: XCTestCase {
    override func setUp() {
        super.setUp()

        let app = XCUIApplication()
        continueAfterFailure = false

        // Enable Fastlane snapshots
        setupSnapshot(app, waitForAnimations: false)
        app.launch()

        let handler = addUIInterruptionMonitor(withDescription: "System Dialog") { alert -> Bool in
            alert.buttons.element(boundBy: 1).tap()
            return true
        }
        app.tap()
        removeUIInterruptionMonitor(handler)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testScreenshots() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        /* let app = XCUIApplication()
         let web = app.webViews

         let sidebarToggle = web.buttons["Sidebar Toggle"]

         wait(for: sidebarToggle, timeout: 20)

         sidebarToggle.tap(withNumberOfTaps: 2, numberOfTouches: 1)
         web.links["App Configuration"].firstMatch.tap()

         // Map Notification Screenshot
         app.tables.cells["map_notification_test"].tap() */

        ensureMapNotification()

        snapshot("01MapContentExtension")

        XCTAssert(springboard.buttons.matching(identifier: "dismiss-expanded-button").firstMatch.exists)

        springboard.buttons.matching(identifier: "dismiss-expanded-button").firstMatch.tap()

        sleep(5)

        // Camera Notification Screenshot
        // app.tables.cells["camera_notification_test"].tap()

        ensureCameraNotification()

        snapshot("02CameraContentExtension")

        XCTAssert(springboard.buttons.matching(identifier: "dismiss-expanded-button").firstMatch.exists)

        springboard.buttons.matching(identifier: "dismiss-expanded-button").firstMatch.tap()

        snapshot("03Frontend")
    }

    func ensureMapNotification() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let notification = springboard.otherElements["NotificationShortLookView"]
        XCTAssert(notification.waitForExistence(timeout: 10))
        notification.swipeDown()

        let notificationMap = springboard.maps.element(boundBy: 0)
        let notifPredicate = NSPredicate(format: "label CONTAINS 'New York'")
        let ensureNotifMapLoad = notificationMap.otherElements.matching(notifPredicate).element(boundBy: 0)

        // wait for the map to finish loading and zooming
        wait(for: ensureNotifMapLoad, timeout: 10)
        XCTAssertTrue(ensureNotifMapLoad.exists)

        let notifMap = springboard.otherElements.matching(identifier: "notification_map").element(boundBy: 0)
        XCTAssertTrue(notifMap.exists)
    }

    func ensureCameraNotification() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let notification = springboard.otherElements["NotificationShortLookView"]
        XCTAssert(notification.waitForExistence(timeout: 20))
        notification.swipeDown()

        let expandedNotification = springboard.otherElements["camera_notification"]

        wait(for: expandedNotification, timeout: 10)

        let imageView = expandedNotification.images["camera_notification_imageview"]
        wait(for: imageView, timeout: 20)
        XCTAssertTrue(imageView.exists)
    }
}

extension XCTestCase {
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }

        // We use a buffer here to avoid flakiness with Timer on CI
        waitForExpectations(timeout: duration + 0.5)
    }

    /// Wait for element to appear
    func wait(for element: XCUIElement, timeout duration: TimeInterval) {
        let predicate = NSPredicate(format: "exists == true")
        _ = expectation(for: predicate, evaluatedWith: element, handler: nil)

        // Here we don't need to call `waitExpectation.fulfill()`

        // We use a buffer here to avoid flakiness with Timer on CI
        waitForExpectations(timeout: duration + 0.5)
    }
}

// MARK: - 商店截圖

/// 產生上架用的商店截圖。
///
/// **為什麼不用上游那套 `-useDemo` 機制**：
/// `ConnectionInfo+WebView.swift:6` 在 `useDemo` 為真時會把 WebView 指到
/// `https://companion.home-assistant.io/app/ios/demo` —— 那是**上游 Home Assistant 的示範頁**。
/// 拍出來的畫面會是 Home Assistant 的內容與品牌，不能當 Apporo 的商店素材。
/// 另外 `Snapfile` 傳的 `-url` / `-token` / `-webhookID` / `-webhookSecret` 在本 fork 的
/// 原始碼裡**沒有任何地方讀取**（只會進 UserDefaults 然後被忽略），所以那條路徑實際上
/// 只會產出上游示範頁的截圖。
///
/// 因此這裡改成真的走一次上線流程，連上 Apporo 自己的示範主機。
///
/// **必須用 en-US 執行**（`-testLanguage en -testRegion US`）：
/// 上線流程沒有任何無障礙識別碼，只能靠可見文字比對，語系一變就全部找不到。
final class StoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    private let serverURL = ProcessInfo.processInfo.environment["APPORO_DEMO_URL"]
        ?? "https://family-demo.apporo.ai"
    private let username = ProcessInfo.processInfo.environment["APPORO_DEMO_USER"] ?? "admin"
    private let password = ProcessInfo.processInfo.environment["APPORO_DEMO_PASSWORD"] ?? "admin"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launch()
    }

    func testCaptureStoreScreenshots() throws {
        // ⚠️ 一定要先等歡迎頁渲染完。App 冷啟動要數秒,在那之前畫面是全黑的——
        //    實測過:不等就拍,01Welcome 會是一張純黑圖,而且緊接著的 tap 會找不到按鈕。
        let welcomeReady = app.buttons["Connect to my Apporo aiot"].waitForExistence(timeout: 60)
            || app.staticTexts["Apporo aiot"].waitForExistence(timeout: 10)
        // ⚠️ 這一條失敗時最常見的原因**不是 App 壞掉**,而是模擬器留著上一輪的登入狀態。
        //    而且 `xcrun simctl uninstall` **清不掉** —— 實測過兩次:
        //    伺服器設定與 Realm 資料庫在 App Group 容器(group.com.apporo.aiot)裡,
        //    那個容器屬於「群組」不屬於 App,解除安裝不會刪;權杖另外還在鑰匙圈,
        //    鑰匙圈在 iOS 上本來就活得比 App 久。重裝後 App 仍直接開在儀表板上。
        //    要回到全新狀態,跑之前必須:
        //        xcrun simctl shutdown <udid> && xcrun simctl erase <udid>
        XCTAssertTrue(
            welcomeReady,
            "歡迎頁沒有出現。若下方的元素樹顯示的是儀表板,代表模擬器留有上一輪的登入狀態;"
                + "uninstall 不夠(App Group 容器與鑰匙圈不會被清),請 simctl erase 整台再跑。"
                + "\n\(app.debugDescription)"
        )
        sleep(2)
        snapshot("01Welcome")

        // 歡迎頁 → 伺服器探索。
        // 點完必須確認真的換頁:實測過「按鈕存在且 isHittable、tap() 也回來了,
        // 但畫面沒有變」——SwiftUI 在轉場動畫期間會吃掉點擊。所以要重試。
        try tap(
            ["Connect to my Apporo aiot", "Connect"],
            thenWaitFor: ["Enter address manually", "Enter Address Manually", "Searching on home network"],
            step: "welcome"
        )

        // 探索畫面會先找區網伺服器;示範主機在外網,所以一定要走手動輸入。
        try tap(
            ["Enter address manually", "Enter Address Manually"],
            thenWaitForTextField: true,
            step: "server discovery"
        )

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 20), "找不到位址輸入框\n\(app.debugDescription)")
        field.tap()
        field.typeText(serverURL)
        snapshot("02EnterAddress")

        try tapFirstButton(labelled: ["Connect"], step: "manual url entry")

        try signIn()

        // 上線流程結束後可能還有「裝置命名」「權限」等步驟,一路按到底。
        finishRemainingOnboarding()

        // 等主畫面(WebView)真的載入,再拍儀表板。
        // 到這裡上線流程已經推完,畫面上剩下的 WebView 才是儀表板。
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 180), "儀表板沒有載入\n\(app.debugDescription)")
        sleep(20)

        // ⚠️ 拍之前一定要先關掉系統對話框。實測過一次沒關的後果有兩層,第二層很難發現:
        //    1. 通知授權對話框直接**蓋在儀表板上**被拍進 03Dashboard,
        //       而且上面寫的是 debug 版的 App 名稱(`Apporo aiot Δ`)。
        //    2. 對話框會**吃掉之後所有的手勢** —— 於是 04Devices / 05MoreDevices
        //       跟 03Dashboard **位元組完全相同**(md5 一致)。測試照樣通過,
        //       產出三張一模一樣的圖,沒人會發現。
        dismissSystemAlerts()
        snapshot("03Dashboard")

        // ⚠️ **不要用捲動來產生不同的畫面。** 捲多少才會變是看裝置尺寸的:
        //    iPhone 上捲一次有效、捲兩次就到底;iPad 13" 的儀表板整頁裝得下,
        //    **捲一次就完全沒有作用**。兩種情況都不會報錯,只會默默產出重複的圖
        //    (實測 iPhone 04==05、iPad 03==04,md5 一致)。
        //    改成點進去看真正不同的畫面 —— 尺寸無關,而且跟 Android 那組構成一致。
        let room = app.webViews.buttons["Living Room"]
        XCTAssertTrue(
            room.waitForExistence(timeout: 20),
            "找不到房間卡片「Living Room」。示範主機的區域名稱改過了?\n\(app.debugDescription)"
        )
        room.tap()
        sleep(6)
        snapshot("04Room")

        // 單一裝置的控制面板(亮度、色溫)—— 商店素材裡最有說服力的一張。
        let light = app.webViews.buttons
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Ceiling Lights")).firstMatch
        XCTAssertTrue(
            light.waitForExistence(timeout: 20),
            "房間裡找不到「Ceiling Lights」。\n\(app.debugDescription)"
        )
        light.tap()
        sleep(5)
        snapshot("05LightControl")
    }

    /// 上線流程在連上伺服器之後還有幾個步驟(命名裝置、權限說明等),
    /// 每台裝置/每個版本不完全一樣,所以用「找得到就按」的方式一路推進,
    /// 直到 WebView 出現(代表已經進主畫面)為止。
    private func finishRemainingOnboarding() {
        // ⚠️ "Save" 一定要在清單裡 —— 登入後的「How would you like to name this device?」
        //    那一頁用的就是 Save,漏了它整個流程就停在那裡。
        // ⚠️ 這份清單是**照著原始碼裡的實際字串**列的,不是猜的。漏一個,流程就靜靜停住,
        //    而外層只會看到「儀表板沒有載入」,完全指不到真正卡住的那一頁:
        //      - "Got it"                   LocalAccessOnlyDisclaimerView
        //      - "Share my location" /
        //        "Do not share my location" LocationPermissionView
        //      - "Next"                     HomeNetworkInputView / LocalAccessPermissionView
        //      - "Allow notifications" /
        //        "Do not allow"             通知授權頁。它是 **App 自己的畫面**(不是系統
        //                                   對話框),而且疊在**儀表板之上** —— 漏了它,
        //                                   03Dashboard 會拍到下半截被遮住的畫面。
        //
        //    這裡一律挑**不會叫出系統對話框**的那一個(Do not share / Do not allow):
        //    商店截圖不需要這些權限,少一個系統對話框就少一個不穩定來源。
        let next = [
            "Got it", "Next", "Save", "Continue", "Done", "Finish", "Get started",
            "Do not share my location", "Do not allow", "Skip", "Not now", "Later",
        ]
        // ⚠️ **不能用「有 WebView 就代表進了主畫面」當結束條件。**
        //    HA 的 OAuth 登入頁本身就是 WKWebView,那個判斷會在登入當下就成立,
        //    於是後面的裝置命名、權限頁全被跳過,而 03Dashboard 拍到的其實是命名畫面。
        //    改成:要「**已經有 WebView** 而且連續數次都找不到前進按鈕」才算結束。
        //
        //    ⚠️ 只看「連續 N 次沒按鈕」是不夠的 —— 實測過:登入成功後權限流程是
        //    fullScreenCover,從授權完成到它出現在畫面上大約要 4 秒,期間什麼按鈕都找不到,
        //    於是這裡在 t=84s 就結束了,而權限頁 t=80s 才剛蓋上來。App 其實一切正常
        //    (log 顯示註冊、感測器全部 fulfilled,WebSocket 一路 ping 成功),
        //    只有測試自己先走了,最後報成「儀表板沒有載入」,指向完全錯誤的方向。
        var quietRounds = 0
        let deadline = Date().addingTimeInterval(240)
        while Date() < deadline {
            if let b = firstHittable(next) {
                quietRounds = 0
                b.tap()
                sleep(3)
                continue
            }
            quietRounds += 1
            // 進了主畫面,而且連續三輪都沒有東西可按 = 流程真的推完了。
            if app.webViews.firstMatch.exists, quietRounds >= 3 { return }
            // 沒有 WebView 又完全沒動靜約 75 秒:別空轉到逾時,交給外層斷言去印畫面。
            if quietRounds >= 25 { return }
            // 系統權限對話框(定位、通知)不屬於 app,要從 springboard 按
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            for label in ["Allow While Using App", "Allow", "OK", "Don't Allow"] {
                let b = springboard.buttons[label]
                if b.exists, b.isHittable { b.tap(); break }
            }
            usleep(800_000)
        }
    }

    // MARK: - Helpers

    /// 關掉任何系統層級的對話框(通知授權、定位…)。
    ///
    /// 這些對話框**不屬於受測 App**,`app.alerts` 看不到,要從 springboard 找。
    /// 模擬器的系統語言不一定是英文(shots.sh 會設成英文,但真人跑的時候不保證),
    /// 所以中英文按鈕都列。
    private func dismissSystemAlerts(timeout: TimeInterval = 30) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let labels = ["Allow", "Don't Allow", "允許", "不允許", "OK", "好"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            guard springboard.alerts.firstMatch.exists else { return }
            var tapped = false
            for label in labels {
                let button = springboard.alerts.buttons[label]
                if button.exists, button.isHittable {
                    button.tap()
                    tapped = true
                    break
                }
            }
            // 有對話框但一個按鈕都認不得:繼續拍會拍到它,但這裡硬等也沒用,交給外面看圖。
            if !tapped { return }
            sleep(2)
        }
    }

    /// 點一個按鈕,然後**確認畫面真的前進了**;沒前進就重點。
    ///
    /// 為什麼需要:實測遇過按鈕 `exists` 且 `isHittable`、`tap()` 也正常回來,
    /// 但畫面完全沒變(SwiftUI 在轉場動畫期間會吞掉點擊)。
    /// 只檢查「按鈕點得到」不足以判斷這一步成功,必須檢查下一頁的特徵元素出現。
    private func tap(
        _ labels: [String],
        thenWaitFor nextLabels: [String] = [],
        thenWaitForTextField: Bool = false,
        step: String,
        attempts: Int = 4
    ) throws {
        for attempt in 1 ... attempts {
            // ⚠️ 每一次都要**等**按鈕出現,不能只查一次就判定失敗。
            //    先前寫成「第一次找不到就 XCTFail」,結果 App 還在冷啟動就被判死,
            //    錯誤訊息還會誤導成「按鈕不存在」。
            guard let button = waitForHittable(labels, timeout: attempt == 1 ? 45 : 15) else {
                // 按鈕不見了 = 多半已經前進了
                if arrived(nextLabels, textField: thenWaitForTextField, timeout: 10) { return }
                continue
            }
            button.tap()
            if arrived(nextLabels, textField: thenWaitForTextField, timeout: 25) { return }
            XCTContext.runActivity(named: "「\(step)」第 \(attempt) 次點擊後畫面未前進,重試") { _ in }
        }
        XCTFail("「\(step)」點了 \(attempts) 次畫面都沒有前進\n\(app.debugDescription)")
    }

    /// 輪詢直到其中一個標籤變成可點,或逾時。
    private func waitForHittable(_ labels: [String], timeout: TimeInterval) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let e = firstHittable(labels) { return e }
            usleep(400_000)
        }
        return nil
    }

    private func firstHittable(_ labels: [String]) -> XCUIElement? {
        for label in labels {
            let b = app.buttons[label]
            if b.exists, b.isHittable { return b }
            let t = app.staticTexts[label]
            if t.exists, t.isHittable { return t }
        }
        return nil
    }

    private func arrived(_ labels: [String], textField: Bool, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if textField, app.textFields.firstMatch.exists { return true }
            for label in labels where app.buttons[label].exists || app.staticTexts[label].exists {
                return true
            }
            usleep(300_000)
        }
        return false
    }


    /// 對 WKWebView 裡的 HTML 欄位輸入文字。
    ///
    /// **不能直接 `element.typeText(...)`。** 那會拋
    /// `Failed to synthesize event: Neither element nor any descendant has keyboard focus`
    /// —— `tap()` 回來時焦點不保證已經建立（HTML 欄位的焦點是網頁自己處理的，
    /// 比原生控制項慢一拍）。
    ///
    /// 作法：點擊 → 輪詢 `hasKeyboardFocus` 直到真的取得焦點 → 用 **app 層**的
    /// `typeText` 送鍵盤事件（送給當前焦點元素，不再對元素本身做焦點檢查）。
    private func type(_ text: String, into element: XCUIElement, named label: String) throws {
        for attempt in 1 ... 3 {
            element.tap()
            let deadline = Date().addingTimeInterval(8)
            while Date() < deadline {
                if (element.value(forKey: "hasKeyboardFocus") as? Bool) == true {
                    app.typeText(text)
                    return
                }
                usleep(200_000)
            }
            XCTContext.runActivity(named: "\(label)欄位第 \(attempt) 次取得焦點失敗，重試") { _ in }
        }
        XCTFail("\(label)欄位始終無法取得鍵盤焦點\n\(element.debugDescription)")
    }


    /// 依序嘗試多個候選標籤。上線流程沒有無障礙識別碼,標籤是唯一的抓手,
    /// 所以失敗時要把畫面樹印出來,否則除錯完全沒有線索。
    private func tapFirstButton(
        labelled labels: [String],
        step: String,
        timeout: TimeInterval = 20
    ) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for label in labels {
                let button = app.buttons[label]
                if button.exists, button.isHittable {
                    button.tap()
                    return
                }
            }
            // 有些是以靜態文字呈現的可點元素
            for label in labels where app.staticTexts[label].exists {
                app.staticTexts[label].tap()
                return
            }
            usleep(500_000)
        }
        XCTFail("在「\(step)」找不到任何一個按鈕:\(labels)\n\(app.debugDescription)")
    }

    /// HA 的登入表單是 WKWebView 裡的 HTML,欄位沒有穩定的識別碼,
    /// 所以用「第一個文字框 = 帳號、第一個密碼框 = 密碼」的位置關係。
    private func signIn() throws {
        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 60), "登入頁沒有出現\n\(app.debugDescription)")

        let userField = webView.textFields.firstMatch
        XCTAssertTrue(userField.waitForExistence(timeout: 60), "找不到帳號欄位\n\(webView.debugDescription)")
        try type(username, into: userField, named: "帳號")

        let passwordField = webView.secureTextFields.firstMatch
        XCTAssertTrue(passwordField.waitForExistence(timeout: 20), "找不到密碼欄位\n\(webView.debugDescription)")
        try type(password, into: passwordField, named: "密碼")

        // 送出表單。三段備案,由最可靠到最後手段:
        //
        // ⚠️ 不要依賴 app.keyboards.buttons["go"] —— 模擬器接著硬體鍵盤時
        //    **軟體鍵盤根本不會出現**,那個查詢會直接失敗
        //    (Failed to tap "go" Button: No matches found for ... Keyboard)。
        //    而硬體鍵盤又是 typeText 能運作的原因,所以不能為了讓 go 出現就把它關掉。
        let submitLabels = ["Login", "Log in", "Sign in", "登入"]
        if let button = submitLabels.lazy
            .map({ webView.buttons[$0] })
            .first(where: { $0.exists && $0.isHittable }) {
            button.tap()
            return
        }
        // HTML 表單對 Enter 的反應是提交,這比找按鈕穩(按鈕文字會隨 HA 版本變)。
        app.typeText("\n")
    }
}
