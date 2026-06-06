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
}
