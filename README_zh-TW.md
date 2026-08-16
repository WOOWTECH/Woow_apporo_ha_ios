<p align="center">
  <img src="docs/screenshots/icon.png" alt="Apporo SmartHome" width="120"/>
</p>

<h1 align="center">Apporo SmartHome — iOS App</h1>

<p align="center">
  <strong>Apporo SmartHome 生態系的白牌 Home Assistant 隨行 App</strong><br/>
  <a href="https://github.com/WOOWTECH/Woow_apporo_ha_app">Woow_apporo_ha_app</a>(Android)的 iOS 對應版
</p>

<p align="center">
  <a href="#總覽">總覽</a> &bull;
  <a href="#架構">架構</a> &bull;
  <a href="#截圖">截圖</a> &bull;
  <a href="#編譯">編譯</a> &bull;
  <a href="#驗證狀態">驗證</a> &bull;
  <a href="README.md">English</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.4+-blue?logo=apple" alt="iOS 16.4+"/>
  <img src="https://img.shields.io/badge/Bundle%20ID-com.apporo.home-8B6B24" alt="com.apporo.home"/>
  <img src="https://img.shields.io/badge/上游-release%2F2026.7.3%2F2026.2546-purple" alt="Upstream pin"/>
  <img src="https://img.shields.io/badge/License-Apache%202.0-green" alt="Apache 2.0"/>
</p>

---

## 總覽

**Apporo SmartHome iOS** 是官方
[Home Assistant Companion](https://github.com/home-assistant/iOS) 的白牌版本,
由共用基底 [`woow_ha_ios`](https://github.com/WOOWTECH/woow_ha_ios) 的一鍵換裝工具組
產出——與 [`Woow_simon_ha_ios`](https://github.com/WOOWTECH/Woow_simon_ha_ios)、
[`Woow_woowtech_ha_ios`](https://github.com/WOOWTECH/Woow_woowtech_ha_ios) 同一條管線。
品牌參數 1:1 移植自 Android `apporo.conf`(2026-08-10 grill 定案),
包含無障礙色彩決策。

| | |
|---|---|
| **Bundle ID** | `com.apporo.home`(Release)/ `com.apporo.home.dev`(Debug)——與 Android 對齊 |
| **URL scheme** | `apporohome://`(深連結 + OAuth callback) |
| **OAuth client** | `https://woowtech.github.io/Woow_apporo_ha_app/android`(與 Android 共用;已上線、宣告 `apporohome://auth-callback`) |
| **品牌色** | `#8B6B24`——WCAG AA 修正色(品牌色票 `#C49E53` 白字對比 2.50:1 不合格;`#8B6B24` 為 4.88:1 合格,依 Android ADR-0001) |
| **App icon** | 去字鳥形 mark、白底(`#FFFFFF`),依 icon/wordmark 分工規則 |
| **上游 pin** | `home-assistant/iOS` tag `release/2026.7.3/2026.2546` |

## 架構

```mermaid
flowchart LR
    subgraph iPhone["Apporo SmartHome app(iOS)"]
        WV["WKWebView<br/>HA 前端"] <--> BUS["JS ↔ Swift<br/>message bus"] <--> N["原生外殼<br/>onboarding · OAuth · 感測器 ·<br/>apporohome:// 深連結 · widgets"]
    end
    WV -- "HTTPS / WebSocket" --> HA["Home Assistant 伺服器<br/>(客戶自架)"]
    N -.->|"IndieAuth client 頁<br/>(與 Android 共用)"| PAGE["宣告<br/>apporohome://auth-callback"]
```

一頁 client_id 服務雙平台——HA 伺服器以 IndieAuth 方式向它驗證 OAuth redirect。
fork 拓撲、工具組設計、環境筆記見基底 repo
[README](https://github.com/WOOWTECH/woow_ha_ios/blob/main/README_zh-TW.md);
與上游偏離記錄於 [`docs/fork-divergence.md`](docs/fork-divergence.md)。

## 截圖

| 上游基準線 | Apporo onboarding |
|---|---|
| <img src="docs/screenshots/baseline-upstream-onboarding.png" width="280"/> | <img src="docs/screenshots/apporo-onboarding.png" width="280"/> |
| pin tag 直接編出的官方原版(工具鏈基準)。 | 一鍵換裝後:Apporo 鳥形 mark、名稱、文案、`#8B6B24` 深金主色,原生外殼零殘留。 |

## 編譯

環境與全家族相同(細節見
[基底 repo](https://github.com/WOOWTECH/woow_ha_ios/blob/main/README_zh-TW.md#本機編譯環境)):
Xcode 26.6+、watchOS platform、brew CocoaPods(+`cocoapods-acknowledgements`)、
swiftlint/swiftformat。

```bash
pod install
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -workspace HomeAssistant.xcworkspace -scheme App-Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## 驗證狀態

| 階段 | 狀態 |
|---|---|
| 換裝(3 934 條字串 / 34 語系、79 組資產)+ preflight 66/66 | ✅ 2026-08-16 |
| 模擬器編譯 + 品牌 onboarding | ✅ 2026-08-16 |
| 實伺服器 OAuth 全鏈路、實機、8 大類冒煙 | ⏳ 待辦 |

## 授權與致謝

Home Assistant Companion for iOS 之修改發行版,© Home Assistant contributors——
[Apache License 2.0](LICENSE.md)。上游署名與 app 內開源致謝頁完整保留。
