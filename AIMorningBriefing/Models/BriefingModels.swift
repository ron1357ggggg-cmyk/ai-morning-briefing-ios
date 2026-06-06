import Foundation

enum RecoveryStatus: String, Codable, Sendable {
    case excellent = "極佳"
    case good = "良好"
    case moderate = "普通"
    case low = "需要恢復"
}

struct RecoveryScore: Equatable, Codable, Sendable {
    let score: Int
    let status: RecoveryStatus
    let sleepScore: Double
    let hrvScore: Double
    let restingHeartRateScore: Double
    let activityScore: Double
}

enum NewsCategory: String, CaseIterable, Codable, Sendable {
    case taiwan = "台灣"
    case world = "國際"
    case ai = "AI"
    case technology = "科技"
    case finance = "財經"
    case politics = "政治"
    case geopolitics = "戰爭與地緣政治"
}

struct NewsItem: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    let category: NewsCategory
    let title: String
    let summary: String
    let whyItMatters: String
    let sourceName: String
    let publishedAt: Date
    let sourceURL: URL?
    let importance: Int
}

struct MorningBriefing: Equatable, Codable, Sendable {
    let generatedAt: Date
    let health: HealthSnapshot
    let recovery: RecoveryScore
    let recommendations: [String]
    let news: [NewsItem]

    static let preview = MorningBriefing(
        generatedAt: .now,
        health: .preview,
        recovery: .init(
            score: 94,
            status: .excellent,
            sleepScore: 100,
            hrvScore: 89,
            restingHeartRateScore: 84,
            activityScore: 100
        ),
        recommendations: [
            "今天適合正常重訓，主項可維持原定強度。",
            "午後安排 20 分鐘低強度有氧，有助維持恢復。",
            "今晚盡量在 23:00 前入睡。"
        ],
        news: MockNewsService.previewNews
    )
}
