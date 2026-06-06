# 技術架構

## App

- `AppModel`：協調健康、新聞、評分與畫面狀態。
- `HealthDataProviding`：HealthKit 與測試資料邊界。
- `NewsProviding`：新聞後端或 mock provider 邊界。
- `RecoveryCalculator`：無 UI、可單元測試的恢復公式。
- `NotificationService`：08:30 本機通知。

## 未來後端

建議端點：

```text
GET /v1/briefings/today
POST /v1/devices/push-token
GET /v1/news?from=<ISO8601>&to=<ISO8601>
```

後端負責：

- 新聞來源授權與聚合
- 台灣至少 3 則、國際至少 7 則
- 去重與影響力排序
- AI 繁中摘要
- APNs 推播

健康原始資料預設不離開裝置。若未來需要雲端分析，必須另做明確同意、
資料最小化、刪除機制與加密設計。
