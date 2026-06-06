# 快速索引

## 專案定位

這是 iPhone 原生 SwiftUI 晨間簡報 App，整合 Apple Health、恢復分數、
健康建議、即時新聞與 08:30 本機通知。

## 核心模組

- `AIMorningBriefing/App/AppModel.swift`：健康與新聞的獨立更新協調。
- `AIMorningBriefing/Services/HealthKitService.swift`：HealthKit 查詢與模擬器備援。
- `AIMorningBriefing/Services/NewsService.swift`：Google 新聞 RSS 與解析。
- `AIMorningBriefing/Services/RecoveryCalculator.swift`：恢復分數與建議。
- `AIMorningBriefing/Features/Dashboard`：首頁、新聞詳情與原文連結。
- `AIMorningBriefingTests`：恢復公式、新聞配額與 RSS 解析測試。

## 必要檢查

```bash
xcodebuild -quiet \
  -project AIMorningBriefing.xcodeproj \
  -scheme AIMorningBriefing \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  test
git status --short --branch
```
