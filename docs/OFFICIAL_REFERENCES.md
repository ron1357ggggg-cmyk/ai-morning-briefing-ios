# 官方技術參考

- HealthKit：
  <https://developer.apple.com/documentation/healthkit>
- `HKHealthStore` 授權與查詢：
  <https://developer.apple.com/documentation/healthkit/hkhealthstore>
- 本機通知排程：
  <https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app>
- 每日固定時間通知：
  <https://developer.apple.com/documentation/usernotifications/uncalendarnotificationtrigger>
- HealthKit 背景更新 entitlement：
  <https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.healthkit.background-delivery>

HealthKit 資料屬敏感個人資料，App 必須取得使用者授權並採資料最小化原則。

## 同齡基準研究

- 靜止心率：Ostchega et al.，CDC National Health Statistics Reports No. 41，
  NHANES 1999–2008：
  <https://www.cdc.gov/nchs/data/nhsr/nhsr041.pdf>
- HRV SDNN：van den Berg et al.，13,943 人、心率校正 10 秒 ECG，
  Frontiers in Physiology 2018：
  <https://doi.org/10.3389/fphys.2018.00424>

靜止心率使用研究表格提供的完整百分位內插。HRV 依原始論文公式
`SDNNc = SDNN × exp[-0.02263 × (60 − HR)]`，目前以同日平均心率近似校正。
研究與 Apple Watch 的採樣時間、姿勢及裝置演算法不同，因此 App 僅顯示研究定位，
不宣稱為精準人口百分位或診斷。
