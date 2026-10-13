# Provisioning profiles

**刻意留空。** 這個目錄由 `fastlane import_provisioning_profiles` 無差別讀取——
它會把目錄裡**每一個檔案**安裝進系統。

先前這裡放著 25 份上游 Home Assistant 的設定檔（team `QMQYCKL255`，
bundle `io.robbie.HomeAssistant.*`），已全部移除，原因是撞名：

- `Configuration/HomeAssistant.release.xcconfig:7` 用
  `PROVISIONING_PROFILE_SPECIFIER = iOS App Store - $(TARGET_NAME)`，
  也就是**依 Name 比對**而非檔案路徑。
- 那些上游檔案的 `Name` 欄位正好就是 `iOS App Store - App`、
  `iOS App Store - Extensions-Widgets` 等。
- Apporo 在 team `W4UWZ8NP2P` 建立的設定檔會叫同樣的名字。
  兩個同名、不同團隊的設定檔同時安裝時，Xcode 的解析行為未定義。

要取得 Apporo 自己的設定檔，請用 `fastlane download_provisioning_profiles`
（需要 Apporo/渥屋的 App Store Connect 帳號），或從開發者網站下載後放進這裡。
**不要**把其他品牌或上游的設定檔放進來。
