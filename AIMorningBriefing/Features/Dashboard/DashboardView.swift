import SwiftUI

struct DashboardView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                header
                if appModel.briefing.health.isSampleData {
                    sampleDataNotice
                }
                updateStatus
                RecoveryCard(score: appModel.briefing.recovery)
                HealthSummaryCard(snapshot: appModel.briefing.health)
                PeerBenchmarkCard()
                RecommendationCard(items: appModel.briefing.recommendations)
                NewsListCard(items: appModel.briefing.news)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("早安")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await appModel.refresh() }
                } label: {
                    if appModel.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(appModel.isLoading)
            }
        }
        .refreshable {
            await appModel.refresh()
        }
        .alert("無法更新", isPresented: Binding(
            get: { appModel.errorMessage != nil },
            set: { if !$0 { appModel.errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(appModel.errorMessage ?? "")
        }
    }

    private var updateStatus: some View {
        HStack {
            Label(
                appModel.isUsingLiveNews ? "即時新聞" : "離線備援新聞",
                systemImage: appModel.isUsingLiveNews ? "network" : "wifi.slash"
            )
            Spacer()
            Text("更新：\(appModel.updateMessage)")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title2.bold())
                Text("你的健康與世界重點")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "sun.max.fill")
                .font(.system(size: 34))
                .foregroundStyle(.orange)
        }
    }

    private var sampleDataNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
            Text(sampleDataDescription)
                .font(.subheadline)
        }
        .foregroundStyle(.blue)
        .padding()
        .background(.blue.opacity(0.10), in: RoundedRectangle(cornerRadius: 16))
    }

    private var sampleDataDescription: String {
#if targetEnvironment(simulator)
        "目前為模擬器示範資料。Apple Health 請使用已簽署的實機 App 測試。"
#else
        "目前顯示示範健康資料。請至設定授權 Apple Health。"
#endif
    }
}
