import SwiftUI

struct RecoveryCard: View {
    let score: RecoveryScore

    var body: some View {
        CardContainer {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.18), lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: Double(score.score) / 100)
                        .stroke(
                            recoveryColor,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(score.score)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("/ 100")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 118, height: 118)

                VStack(alignment: .leading, spacing: 8) {
                    Label("今日恢復分數", systemImage: "heart.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.pink)
                    Text(score.status.rawValue)
                        .font(.title.bold())
                    Text(trainingMessage)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    private var recoveryColor: Color {
        switch score.status {
        case .excellent: .green
        case .good: .mint
        case .moderate: .orange
        case .low: .red
        }
    }

    private var trainingMessage: String {
        switch score.status {
        case .excellent: "適合高強度訓練"
        case .good: "適合正常訓練"
        case .moderate: "建議降低訓練量"
        case .low: "今天以恢復為主"
        }
    }
}

struct HealthSummaryCard: View {
    let snapshot: HealthSnapshot

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日健康摘要", systemImage: "waveform.path.ecg")
                    .font(.headline)
                    .foregroundStyle(.red)

                HStack {
                    MetricTile(
                        title: "睡眠",
                        value: format(snapshot.sleep.totalHours, suffix: " 小時"),
                        detail: "深睡 \(format(snapshot.sleep.deepHours, suffix: " 小時"))",
                        color: .indigo
                    )
                    MetricTile(
                        title: "HRV",
                        value: format(snapshot.hrv.value, suffix: " ms"),
                        detail: changeText(snapshot.hrv),
                        color: .green
                    )
                }
                HStack {
                    MetricTile(
                        title: "靜止心率",
                        value: format(snapshot.restingHeartRate.value, suffix: " bpm"),
                        detail: changeText(snapshot.restingHeartRate),
                        color: .pink
                    )
                    MetricTile(
                        title: "步數",
                        value: integer(snapshot.steps.value),
                        detail: "30 日均值 \(integer(snapshot.steps.thirtyDayAverage))",
                        color: .orange
                    )
                }
            }
        }
    }

    private func format(_ value: Double?, suffix: String) -> String {
        guard let value else { return "--" }
        return value.formatted(.number.precision(.fractionLength(1))) + suffix
    }

    private func integer(_ value: Double?) -> String {
        guard let value else { return "--" }
        return Int(value).formatted()
    }

    private func changeText(_ metric: MetricValue) -> String {
        guard let change = metric.changeFromThirtyDays else { return "無 30 日基準" }
        return "較 30 日 \(change >= 0 ? "+" : "")\(change.formatted(.number.precision(.fractionLength(1))))%"
    }
}

struct RecommendationCard: View {
    let items: [String]

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Label("今日建議", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.purple)
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(item)
                    }
                }
            }
        }
    }
}

struct PeerBenchmarkCard: View {
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Label("同齡基準", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(.teal)
                Text("等待研究資料校準")
                    .font(.title3.bold())
                Text("正式顯示百分位前，需確認年齡、性別、裝置與量測方法相容的公開研究資料。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct NewsListCard: View {
    let items: [NewsItem]

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 16) {
                Label("今日十大新聞", systemImage: "newspaper.fill")
                    .font(.headline)
                    .foregroundStyle(.blue)

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        NewsDetailView(item: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(index + 1)")
                                    .font(.title3.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 24)
                                Text(item.category.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.blue.opacity(0.12), in: Capsule())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                            Text(item.title)
                                .font(.title3.bold())
                                .foregroundStyle(.primary)
                            Text(item.summary)
                                .foregroundStyle(.secondary)
                            Text(item.sourceName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    if index < items.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

struct NewsDetailView: View {
    @Environment(\.openURL) private var openURL
    let item: NewsItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.category.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.blue.opacity(0.12), in: Capsule())
                Text(item.title)
                    .font(.largeTitle.bold())
                LabeledContent("來源", value: item.sourceName)
                LabeledContent(
                    "發布時間",
                    value: item.publishedAt.formatted(
                        .dateTime.month().day().hour().minute().locale(Locale(identifier: "zh_TW"))
                    )
                )
                Divider()
                Text("摘要")
                    .font(.headline)
                Text(item.summary)
                Text("為何重要")
                    .font(.headline)
                Text(item.whyItMatters)

                if let url = item.sourceURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("閱讀原文", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .navigationTitle("新聞詳情")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
    }
}
