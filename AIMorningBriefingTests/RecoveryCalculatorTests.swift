import XCTest
import HealthKit
@testable import AIMorningBriefing

final class RecoveryCalculatorTests: XCTestCase {
    func testPreviewSnapshotProducesExcellentRecovery() {
        let result = RecoveryCalculator().calculate(snapshot: .preview)
        XCTAssertGreaterThanOrEqual(result.score, 85)
        XCTAssertEqual(result.status, .excellent)
    }

    func testMetricChangeUsesThirtyDayBaseline() {
        let metric = MetricValue(
            id: "hrv",
            title: "HRV",
            value: 58,
            unit: "ms",
            sevenDayAverage: 55,
            thirtyDayAverage: 52,
            ninetyDayAverage: 50
        )
        XCTAssertEqual(metric.changeFromThirtyDays ?? 0, 11.538, accuracy: 0.01)
    }

    func testPreviewNewsMeetsMVPQuota() {
        let news = MockNewsService.previewNews
        XCTAssertEqual(news.count, 10)
        XCTAssertGreaterThanOrEqual(news.filter { $0.category == .taiwan }.count, 3)
        XCTAssertGreaterThanOrEqual(news.filter { $0.category != .taiwan }.count, 7)
        XCTAssertTrue(news.allSatisfy { $0.sourceURL != nil })
    }

    func testRSSParserCreatesTappableNews() throws {
        let xml = """
        <rss><channel><item>
        <title>AI 產業推出新工具</title>
        <link>https://example.com/story</link>
        <pubDate>Sat, 06 Jun 2026 09:00:00 GMT</pubDate>
        <source>測試新聞</source>
        </item></channel></rss>
        """
        let items = try RSSFeedParser(defaultCategory: nil).parse(Data(xml.utf8))
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.category, .ai)
        XCTAssertEqual(items.first?.sourceURL?.absoluteString, "https://example.com/story")
    }

    func testHealthKitNoDataIsHandledAsMissingValue() {
        let error = NSError(domain: HKErrorDomain, code: HKError.errorNoData.rawValue)
        XCTAssertTrue(HealthQueryErrorPolicy.isMissingData(error))
    }

    func testOtherHealthKitErrorsAreNotHidden() {
        let error = NSError(
            domain: HKErrorDomain,
            code: HKError.errorDatabaseInaccessible.rawValue
        )
        XCTAssertFalse(HealthQueryErrorPolicy.isMissingData(error))
    }

    func testMaleRestingHeartRateUsesNHANESPercentiles() {
        let results = PeerBenchmarkService().benchmarks(
            health: .preview,
            demographics: UserDemographics(age: 35, sex: .male)
        )
        let restingHeartRate = results.first { $0.id == "restingHeartRate" }
        XCTAssertNotNil(restingHeartRate)
        XCTAssertGreaterThan(restingHeartRate?.percentile ?? 0, 75)
        XCTAssertEqual(restingHeartRate?.confidence, .populationPercentile)
    }

    func testHRVIsMarkedAsResearchOrientation() {
        let results = PeerBenchmarkService().benchmarks(
            health: .preview,
            demographics: UserDemographics(age: 35, sex: .male)
        )
        let hrv = results.first { $0.id == "hrv" }
        XCTAssertNotNil(hrv)
        XCTAssertEqual(hrv?.confidence, .researchOrientation)
        XCTAssertTrue(hrv?.referenceText.contains("採樣不同") == true)
        XCTAssertTrue(hrv?.referenceText.contains("近似校正") == true)
    }

    func testMissingAgeDoesNotProduceBenchmark() {
        let results = PeerBenchmarkService().benchmarks(
            health: .preview,
            demographics: UserDemographics(age: nil, sex: .other)
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testUnknownSexUsesCombinedReferenceInsteadOfMaleDefault() {
        let results = PeerBenchmarkService().benchmarks(
            health: .preview,
            demographics: UserDemographics(age: 35, sex: .other)
        )
        XCTAssertTrue(results.allSatisfy { $0.referenceText.contains("全部性別參考") })
    }

    @MainActor
    func testHealthFailureStillUpdatesNews() async {
        let news = [
            NewsItem(
                id: UUID(),
                category: .taiwan,
                title: "測試即時新聞",
                summary: "測試摘要",
                whyItMatters: "測試影響",
                sourceName: "測試來源",
                publishedAt: .now,
                sourceURL: URL(string: "https://example.com/news"),
                importance: 100
            )
        ]
        let model = AppModel(
            healthService: FailingHealthService(),
            newsService: StubNewsService(news: news)
        )

        await model.refresh()

        XCTAssertEqual(model.briefing.news, news)
        XCTAssertTrue(model.isUsingLiveNews)
        XCTAssertTrue(model.errorMessage?.contains("健康資料") == true)
        XCTAssertFalse(model.isLoading)
    }

    @MainActor
    func testNewsFailureStillUpdatesHealthAndBenchmarks() async {
        let health = Self.snapshot(restingHeartRate: 62)
        let model = AppModel(
            healthService: StubHealthService(snapshot: health),
            newsService: FailingNewsService()
        )

        await model.refresh()

        XCTAssertEqual(model.briefing.health, health)
        XCTAssertFalse(model.isUsingLiveNews)
        XCTAssertFalse(model.peerBenchmarks.isEmpty)
        XCTAssertTrue(model.errorMessage?.contains("新聞") == true)
        XCTAssertFalse(model.isLoading)
    }

    func testRecoveryScoreStaysWithinBoundsWithMissingData() {
        let result = RecoveryCalculator().calculate(snapshot: Self.emptySnapshot)
        XCTAssertTrue((0...100).contains(result.score))
    }

    private static func snapshot(restingHeartRate: Double) -> HealthSnapshot {
        let preview = HealthSnapshot.preview
        return HealthSnapshot(
            date: .now,
            weight: preview.weight,
            bodyFat: preview.bodyFat,
            steps: preview.steps,
            sleep: preview.sleep,
            restingHeartRate: MetricValue(
                id: "rhr",
                title: "靜止心率",
                value: restingHeartRate,
                unit: "bpm",
                sevenDayAverage: 64,
                thirtyDayAverage: 65,
                ninetyDayAverage: 66
            ),
            hrv: preview.hrv,
            activeEnergy: preview.activeEnergy,
            exerciseMinutes: preview.exerciseMinutes,
            averageHeartRate: preview.averageHeartRate,
            isSampleData: false
        )
    }

    private static let emptyMetric = MetricValue(
        id: "empty",
        title: "無資料",
        value: nil,
        unit: "",
        sevenDayAverage: nil,
        thirtyDayAverage: nil,
        ninetyDayAverage: nil
    )

    private static let emptySnapshot = HealthSnapshot(
        date: .now,
        weight: emptyMetric,
        bodyFat: emptyMetric,
        steps: emptyMetric,
        sleep: .empty,
        restingHeartRate: emptyMetric,
        hrv: emptyMetric,
        activeEnergy: emptyMetric,
        exerciseMinutes: emptyMetric,
        averageHeartRate: emptyMetric,
        isSampleData: false
    )
}

private enum TestFailure: LocalizedError {
    case expected

    var errorDescription: String? { "預期的測試錯誤" }
}

private struct StubHealthService: HealthDataProviding {
    let snapshot: HealthSnapshot

    func requestAuthorization() async throws {}
    func loadSnapshot() async throws -> HealthSnapshot { snapshot }
    func loadDemographics() async -> UserDemographics { .preview }
}

private struct FailingHealthService: HealthDataProviding {
    func requestAuthorization() async throws {}
    func loadSnapshot() async throws -> HealthSnapshot { throw TestFailure.expected }
    func loadDemographics() async -> UserDemographics { .preview }
}

private struct StubNewsService: NewsProviding {
    let news: [NewsItem]

    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem] {
        news
    }
}

private struct FailingNewsService: NewsProviding {
    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem] {
        throw TestFailure.expected
    }
}
