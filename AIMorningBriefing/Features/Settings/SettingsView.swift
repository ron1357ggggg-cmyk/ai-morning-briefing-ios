import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @AppStorage("morningNotificationEnabled") private var notificationEnabled = false

    var body: some View {
        Form {
            Section("Apple Health") {
                Button {
                    Task { await appModel.requestHealthAuthorization() }
                } label: {
                    Label(healthAuthorizationTitle, systemImage: "heart.fill")
                }
                .disabled(isHealthAuthorizationDisabled)
                Text(healthAuthorizationDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("每日提醒") {
                Toggle("每天 08:30 提醒", isOn: $notificationEnabled)
                    .onChange(of: notificationEnabled) { _, enabled in
                        guard enabled else { return }
                        Task { await appModel.enableMorningNotification() }
                    }
                Text("本機通知可準時提醒；新聞與 AI 內容會在開啟 App 時更新。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("資料來源") {
                LabeledContent("健康", value: "Apple Health")
                LabeledContent("新聞", value: "MVP 示範 Provider")
                LabeledContent("AI 建議", value: "本機規則引擎")
            }

            Section("重要說明") {
                Text("恢復分數與建議僅供一般健康參考，不構成醫療診斷或治療建議。")
            }
        }
        .navigationTitle("設定")
    }

    private var healthAuthorizationTitle: String {
#if targetEnvironment(simulator)
        "模擬器使用示範健康資料"
#else
        "授權並讀取健康資料"
#endif
    }

    private var healthAuthorizationDescription: String {
#if targetEnvironment(simulator)
        "HealthKit 必須使用已簽署的實機 App 測試，目前畫面使用示範資料。"
#else
        "健康資料只在裝置上分析。MVP 不會上傳健康資料。"
#endif
    }

    private var isHealthAuthorizationDisabled: Bool {
#if targetEnvironment(simulator)
        true
#else
        false
#endif
    }
}
