import Foundation

protocol NewsProviding: Sendable {
    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem]
}

struct BackendNewsService: NewsProviding {
    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("v1/news"),
            resolvingAgainstBaseURL: false
        )
        let formatter = ISO8601DateFormatter()
        components?.queryItems = [
            URLQueryItem(name: "from", value: formatter.string(from: start)),
            URLQueryItem(name: "to", value: formatter.string(from: end)),
            URLQueryItem(name: "locale", value: "zh-TW"),
            URLQueryItem(name: "limit", value: "10"),
        ]
        guard let url = components?.url else {
            throw NewsServiceError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw NewsServiceError.invalidResponse
        }
        return try JSONDecoder().decode([NewsItem].self, from: data)
            .sorted { $0.importance > $1.importance }
    }
}

struct GoogleNewsRSSService: NewsProviding {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem] {
        async let taiwanFeed = fetchFeed(query: "台灣 when:1d", category: .taiwan)
        async let worldFeed = fetchFeed(
            query: "國際 OR AI OR 科技 OR 財經 OR 政治 when:1d",
            category: nil
        )

        let (taiwan, world) = try await (taiwanFeed, worldFeed)
        let selectedTaiwan = unique(taiwan).prefix(3)
        let selectedWorld = unique(world)
            .filter { $0.category != .taiwan }
            .prefix(7)
        let result = Array(selectedTaiwan) + Array(selectedWorld)

        guard result.count == 10 else {
            throw NewsServiceError.insufficientItems
        }
        return result.enumerated().map { index, item in
            NewsItem(
                id: item.id,
                category: item.category,
                title: item.title,
                summary: item.summary,
                whyItMatters: item.whyItMatters,
                sourceName: item.sourceName,
                publishedAt: item.publishedAt,
                sourceURL: item.sourceURL,
                importance: 100 - index
            )
        }
    }

    private func fetchFeed(query: String, category: NewsCategory?) async throws -> [NewsItem] {
        var components = URLComponents(string: "https://news.google.com/rss/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "hl", value: "zh-TW"),
            URLQueryItem(name: "gl", value: "TW"),
            URLQueryItem(name: "ceid", value: "TW:zh-Hant"),
        ]
        guard let url = components?.url else {
            throw NewsServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
            throw NewsServiceError.invalidResponse
        }
        return try RSSFeedParser(defaultCategory: category).parse(data)
    }

    private func unique(_ items: [NewsItem]) -> [NewsItem] {
        var titles = Set<String>()
        return items.filter { titles.insert($0.title).inserted }
    }
}

struct MockNewsService: NewsProviding {
    func fetchImportantNews(from start: Date, to end: Date) async throws -> [NewsItem] {
        Self.previewNews
            .sorted { $0.importance > $1.importance }
            .prefix(10)
            .map { $0 }
    }

    static let previewNews: [NewsItem] = [
        item(.taiwan, "台灣公共政策焦點", "政府公布新的政策方向，影響民生與產業布局。", "後續執行細節可能影響家庭支出與企業決策。", 100),
        item(.world, "全球經濟重要動向", "主要經濟體公布最新數據，市場重新評估成長與利率路徑。", "利率與景氣預期會影響投資、匯率及就業。", 98),
        item(.ai, "AI 產業發布新進展", "大型科技公司推出新的 AI 能力與開發工具。", "可能改變軟體開發、生產力工具及企業成本。", 96),
        item(.geopolitics, "國際安全局勢更新", "主要衝突地區出現新的外交與軍事發展。", "可能牽動能源、供應鏈與金融市場風險。", 94),
        item(.taiwan, "台灣產業與科技消息", "關鍵產業公布投資或供應鏈調整計畫。", "影響本地就業、出口與產業競爭力。", 92),
        item(.finance, "金融市場與匯率變化", "股債匯市場因政策訊號出現波動。", "可能影響資產配置、房貸與消費信心。", 90),
        item(.world, "國際組織發布重大報告", "報告更新全球成長、氣候或公共衛生風險。", "提供政府與企業中期決策的重要依據。", 88),
        item(.technology, "科技供應鏈新趨勢", "晶片、雲端與裝置市場出現新的產品及需求訊號。", "影響台灣科技產業與全球供應鏈。", 86),
        item(.taiwan, "台灣社會與交通焦點", "地方政府公布影響通勤與公共服務的新措施。", "與每日生活安排及區域發展直接相關。", 84),
        item(.politics, "主要國家政治進展", "選舉、國會或政策協商出現重要變化。", "可能改變國際合作、貿易及安全政策。", 82),
    ]

    private static func item(
        _ category: NewsCategory,
        _ title: String,
        _ summary: String,
        _ importanceText: String,
        _ importance: Int
    ) -> NewsItem {
        NewsItem(
            id: UUID(),
            category: category,
            title: title,
            summary: summary,
            whyItMatters: importanceText,
            sourceName: "示範資料",
            publishedAt: .now,
            sourceURL: URL(string: "https://news.google.com/"),
            importance: importance
        )
    }
}

final class RSSFeedParser: NSObject, XMLParserDelegate {
    private let defaultCategory: NewsCategory?
    private var items: [NewsItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDate = ""
    private var currentSource = ""
    private var isInsideItem = false

    init(defaultCategory: NewsCategory?) {
        self.defaultCategory = defaultCategory
    }

    func parse(_ data: Data) throws -> [NewsItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        guard parser.parse() else {
            throw parser.parserError ?? NewsServiceError.invalidResponse
        }
        return items.sorted { $0.publishedAt > $1.publishedAt }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentLink = ""
            currentDate = ""
            currentSource = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "pubDate": currentDate += string
        case "source": currentSource += string
        default: break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        defer { currentElement = "" }
        guard elementName == "item" else { return }
        isInsideItem = false

        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty,
              let url = URL(string: currentLink.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return }

        let source = currentSource.trimmingCharacters(in: .whitespacesAndNewlines)
        let category = defaultCategory ?? Self.category(for: title)
        items.append(
            NewsItem(
                id: UUID(),
                category: category,
                title: title,
                summary: "來自 \(source.isEmpty ? "新聞來源" : source) 的即時報導，點擊可查看完整內容。",
                whyItMatters: Self.impactText(for: category),
                sourceName: source.isEmpty ? "Google 新聞彙整" : source,
                publishedAt: Self.date(from: currentDate) ?? .now,
                sourceURL: url,
                importance: 0
            )
        )
    }

    private static func category(for title: String) -> NewsCategory {
        let normalized = title.lowercased()
        if normalized.contains("ai") || normalized.contains("人工智慧") {
            return .ai
        }
        if normalized.contains("晶片") || normalized.contains("科技") || normalized.contains("蘋果") {
            return .technology
        }
        if normalized.contains("股") || normalized.contains("金融") || normalized.contains("經濟") {
            return .finance
        }
        if normalized.contains("戰爭") || normalized.contains("軍") || normalized.contains("烏克蘭") {
            return .geopolitics
        }
        if normalized.contains("選舉") || normalized.contains("政府") || normalized.contains("總統") {
            return .politics
        }
        return .world
    }

    private static func impactText(for category: NewsCategory) -> String {
        switch category {
        case .taiwan: "可能影響台灣民生、政策或產業發展。"
        case .world: "可能影響全球局勢與台灣對外環境。"
        case .ai: "可能改變工作方式、產品能力與產業競爭。"
        case .technology: "可能影響科技產品、供應鏈與市場需求。"
        case .finance: "可能影響市場、匯率、利率與個人資產配置。"
        case .politics: "可能改變政策方向與國際合作關係。"
        case .geopolitics: "可能牽動安全、能源與全球供應鏈風險。"
        }
    }

    private static func date(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter.date(from: text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

enum NewsServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case insufficientItems

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "新聞 API 網址無效。"
        case .invalidResponse:
            "新聞 API 回傳失敗。"
        case .insufficientItems:
            "即時新聞數量不足，請稍後再試。"
        }
    }
}
