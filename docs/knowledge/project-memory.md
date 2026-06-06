# 專案記憶

## 2026-06-06 需求與決策

- 目標是每天 08:30 快速查看身體狀態、訓練建議與重大新聞。
- 第一版使用 SwiftUI、HealthKit、UserNotifications，最低 iOS 17。
- 健康資料包含體重、體脂、步數、睡眠、靜止心率、HRV、熱量、運動時間與心率。
- 恢復分數使用睡眠 40%、HRV 30%、靜止心率 20%、活動量 10%。
- 同齡百分位不得捏造，需等待可核對年齡、性別、裝置與量測方法的研究資料。
- 本機通知可在 08:30 提醒，但 iOS 不保證 App 在背景準時完成網路更新。
- 正式準時晨報仍需要後端排程與 APNs。

## 新聞更新

- 初版 mock 新聞無法點擊，已改用 Google 新聞 RSS 即時抓取。
- 每次取 3 則台灣與 7 則國際相關新聞。
- 每則保留分類、來源、發布時間與原文網址。
- RSS 只提供有限摘要，因此目前使用誠實的本機模板，不宣稱為 AI 摘要。
- 健康與新聞更新必須彼此獨立，單一來源失敗時保留另一方的新資料。

## HealthKit 與實機

- 模擬器缺少可用的 HealthKit entitlement，必須直接使用示範快照，不能要求授權。
- 實機安裝需要 Developer Mode、Apple Development 憑證、Personal Team 與信任開發者。
- 這台 Mac 曾缺少有效的 Apple WWDR G3 中繼憑證；Xcode 內建
  `AppleWWDRCA-2030.cer` 可修復簽署信任鏈。
- 不得把 Apple Account、憑證、裝置 ID 或 provisioning profile 寫入 repo。

## 已驗證

- iPhone 17 模擬器可建置、啟動並顯示即時新聞更新時間。
- RSS parser 會產生可點擊網址。
- iPhone 14 Pro 實機可完成簽署、安裝與啟動。
