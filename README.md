# AI Morning Briefing（iPhone）

每天早上整合 Apple Health、恢復分數、生活建議與重要新聞的 SwiftUI App。

## MVP

- HealthKit：體重、體脂、步數、睡眠階段、靜止心率、HRV、活動熱量、
  運動時間與心率
- 7、30、90 日個人基準
- 0 至 100 恢復分數
- 依 HealthKit 年齡與生理性別比較靜止心率、HRV 研究基準
- 本機健康與訓練建議
- 10 則即時繁中新聞卡片，可開啟詳情與原文
- 每天 08:30 本機通知
- 深色模式與 Dynamic Type

## 執行

1. 使用 Xcode 開啟 `AIMorningBriefing.xcodeproj`。
2. 選擇 Apple Development Team。
3. 使用實體 iPhone 執行。
4. 在設定頁授權 Apple Health 與通知。

HealthKit 在 Simulator 沒有完整真實資料，App 會顯示清楚標示的示範資料。

同齡比較使用公開研究資料。靜止心率提供人口百分位；HRV 因 Apple Watch 與研究
ECG 採樣方法不同，只提供研究定位，不構成醫療診斷。

## 建置

```bash
xcodebuild \
  -project AIMorningBriefing.xcodeproj \
  -scheme AIMorningBriefing \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 資料與隱私

- MVP 健康資料只在裝置上查詢與分析。
- 不將 HealthKit 原始資料上傳。
- 不在 App 內保存新聞或 AI API key。
- 未來 API 由後端代理，App 只取得最小必要的晨報結果。

## 尚未接入

- OpenAI API
- 經研究資料校準的同齡百分位
- 背景產生完整晨報
- 遠端推播

目前即時新聞使用 Google 新聞 RSS，不需要 API key；摘要為本機模板，尚未使用
OpenAI。網路失敗時會保留上一次資料或示範資料。恢復分數是產品初始公式，
不是醫療診斷。
