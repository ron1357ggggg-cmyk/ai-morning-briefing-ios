# 專案規則

## 語言

- 說明文件、使用者訊息與程式註解使用繁體中文。
- API、型別、函式、檔名、環境變數與 Git 指令保留英文。

## 修改前

必須先閱讀：

- `AGENTS.md`
- `docs/quick-index.md`
- `docs/knowledge/project-memory.md`
- 與修改範圍相關的 `docs/` 文件
- 將要修改的原始碼與現有測試

先確認問題是否已記錄在 `docs/troubleshooting/common.md`，避免重複嘗試已知無效做法。

## 實作原則

- HealthKit 原始資料只在裝置上處理，不提交或記錄個人健康資料。
- API key、Apple Account、憑證內容、裝置 ID 與 provisioning profile 不得提交。
- 錯誤不得被無條件吞掉；可預期缺值需轉成明確狀態，其他錯誤需回報或記錄。
- 新聞失敗不得阻止健康資料更新；健康資料失敗也不得阻止新聞更新。
- 即時新聞必須保留來源與可開啟的原文網址。
- 模擬器固定使用示範健康資料，HealthKit 僅在已簽署實機測試。
- 健康基準數據必須可追溯到原始研究或官方資料，記錄版本、量測方法與限制。
- 不得因測試偶發失敗而只加入 retry；必須先定位並修正不穩定原因。

## 驗證

每次程式修改至少執行：

```bash
xcodebuild -quiet \
  -project AIMorningBriefing.xcodeproj \
  -scheme AIMorningBriefing \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

涉及 UI、網路或 HealthKit 時，另外執行：

- 模擬器啟動檢查與截圖。
- 已連接 iPhone 的簽署建置、安裝與啟動。
- 更新 `docs/changelog/change-log.md` 與 `docs/knowledge/project-memory.md`。

重大版本、穩定性修正或使用者要求壓力測試時執行：

```bash
./scripts/repeat-tests.sh 101
```

重複測試必須完整通過；任一迭代失敗即停止，並保留失敗迭代與日誌。

## Git

只提交本次相關檔案。提交前後都要執行：

```bash
git status --short --branch
```

新功能、修正與測試結果需寫入異動紀錄後再 commit、push。

提交前必須執行 `git diff --check`，並確認沒有秘密、個人健康資料或本機簽署資訊。
