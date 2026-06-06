import XCTest
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
}
