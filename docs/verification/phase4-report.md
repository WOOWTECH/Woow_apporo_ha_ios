# Phase 4 模擬器驗證報告(2026-08-16)

環境:iPhone 17 Simulator(iOS 26.5)/ Debug build(`com.apporo.home.dev`,dev 精簡 entitlements)
伺服器:`https://woowtech-ha.woowtech.io`(HA,使用者 admin)

| # | 項目 | 結果 |
|---|---|---|
| 1 | Onboarding 品牌畫面 | ✅ 鳥形 mark、#8B6B24、全文案(`phase4-apporo-onboarding.png`) |
| 2 | 連線 + OAuth + 登入 | ✅ 手動輸入 server → 授權頁顯示 client_id(Android 共用頁)→ admin 登入 → `apporohome://auth-callback` 攔截成功 → 原生 onboarding(裝置命名/定位/網路)全程品牌文案 → 完成 |
| 3 | Dashboard WebView | ✅ Home「Welcome admin」真實實體(`phase4-apporo-dashboard.png`) |
| 4 | 深連結 | ✅ `apporohome://navigate/lovelace/0` → app 解析導向總覽(`phase4-apporo-deeplink.png`) |

發現:
- onboarding 完成後跳出上游「Beta Tester Update / TestFlight」What's New 卡(上游社群內容,`WhatsNewCatalog` 屬刻意保留清單)——對白牌使用者具誤導性,建議列入下輪 rebrand 工項(隱藏 What's New 或换品牌內容)
- 第一次嘗試時輸入被 focus 時序打亂導致登入失敗+流程污染;重啟 app 乾跑一次即成功。自動化輸入 SOP:每欄位 tap → sleep 2 → 輸入 → 截圖驗證
