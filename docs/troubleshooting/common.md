# 疑難排解

## 模擬器顯示 HealthKit entitlement 錯誤

模擬器不可要求 HealthKit 授權。`HealthKitService` 在
`targetEnvironment(simulator)` 必須直接回傳示範資料。

## 實機無法啟動 App

依序確認：

1. iPhone 已開啟 Developer Mode。
2. Xcode 已登入 Apple Account 並建立 Apple Development 憑證。
3. 專案已選擇正確 Development Team。
4. iPhone 已在「VPN 與裝置管理」信任開發者。

## `0 valid identities found`

先確認 Apple Development 憑證與私鑰同時存在。若憑證由 WWDR G3 簽發，
但系統只有 2023 年到期的舊 WWDR 憑證，可安裝 Xcode 內建的
`AppleWWDRCA-2030.cer` 到登入鑰匙圈。

## 新聞無法更新

- 確認裝置可連線到 `https://news.google.com/`。
- RSS timeout 為 15 秒。
- 失敗時 App 會保留上一次或示範新聞，首頁顯示「離線備援新聞」。

## 新聞無法點擊

確認 RSS parser 有建立 `sourceURL`，且列表使用 `NavigationLink` 進入
`NewsDetailView`。原文按鈕使用 SwiftUI `openURL`。

## 顯示 `No data available`

HealthKit 的 `HKError.errorNoData` 只表示該指標在指定期間沒有資料。查詢層必須
回傳 `nil` 或空睡眠摘要，不可讓錯誤中止完整健康快照。其他錯誤，例如資料庫因
裝置鎖定而無法存取，仍需向上回報。
