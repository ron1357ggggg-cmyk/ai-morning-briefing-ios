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
