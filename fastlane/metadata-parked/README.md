# 暫存的商店 metadata（首版不出）

首版商店頁只出 `en-US`（Owner 2026-09-15 拍板）。

## 為什麼要移走而不是留在原處

`deliver` 會**為任何有截圖或有 metadata 目錄的語系建立商店 localization**。
`zh-Hans` / `zh-Hant` 的文案是完整的，但**這兩個語系沒有截圖** ——
留在 `fastlane/metadata/` 底下的話，deliver 會多開兩個商店頁，
然後那兩個 localization 會因為缺截圖而**擋住整個版本送審**。

## 為什麼是移走而不是刪掉

文案本身是好的、已經逐字檢查過長度（zh-Hans description 867 字元、
zh-Hant 870 字元，皆遠低於 4000 上限），刪掉等於丟掉可用的成果。

## 要恢復時

1. 把目錄移回 `fastlane/metadata/`
2. **先產出對應語系的截圖**（`fastlane/Snapfile` 的 `languages([...])` 已列了這兩個語系）
3. 確認 App Store Connect 上那兩個 localization 的必填欄位都齊全

相關紀錄：RELEASE-CHECKLIST 6-2。
