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
- `HKError.errorNoData` 代表特定查詢沒有資料，不是整體更新失敗；必須轉成
  `nil`，讓欄位顯示 `--`，不可向上拋出中止整份快照。
- App 啟動流程必須先要求 HealthKit 授權，再執行健康資料更新。
- 實機安裝需要 Developer Mode、Apple Development 憑證、Personal Team 與信任開發者。
- 這台 Mac 曾缺少有效的 Apple WWDR G3 中繼憑證；Xcode 內建
  `AppleWWDRCA-2030.cer` 可修復簽署信任鏈。
- 不得把 Apple Account、憑證、裝置 ID 或 provisioning profile 寫入 repo。

## 已驗證

- iPhone 17 模擬器可建置、啟動並顯示即時新聞更新時間。
- RSS parser 會產生可點擊網址。
- iPhone 14 Pro 實機可完成簽署、安裝與啟動。

## 同齡基準

- 年齡與生理性別由 HealthKit characteristic data 讀取，使用者未填寫時不可猜測。
- 靜止心率使用 CDC NHANES 1999–2008 的年齡、性別完整百分位表。
- 心率較低以有利方向呈現百分位，但仍需考量藥物、疾病與體能差異。
- HRV 使用 van den Berg et al. 2018 的 13,943 人、心率校正 10 秒 ECG
  SDNN 第 2／50／98 百分位。
- HRV 必須依研究公式校正後才可比較；目前使用同日平均心率近似校正，沒有心率時
  不產生 HRV 百分位。
- Apple Watch HRV 與該 ECG 研究方法不同，UI 必須標示「研究參考」與採樣差異。
- 生理性別未設定或非男女二元值時，使用男女參考值平均並標示全部性別參考，
  不得默認男性。

## App 圖示

- 原創圖示結合日出、心率與晨報摘要，不使用 Apple Health 商標。
- 原始生成檔由內建 image generation 產生，專案使用 1024×1024 無透明 PNG。
