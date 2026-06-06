import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let healthService: HealthDataProviding
    private let newsService: NewsProviding
    private let notificationService: NotificationService
    private let snapshotStore = DailyHealthSnapshotStore()
    private let recoveryCalculator = RecoveryCalculator()

    var briefing: MorningBriefing = .preview
    var isLoading = false
    var healthAuthorizationRequested = false
    var errorMessage: String?
    var updateMessage = "尚未更新"
    var isUsingLiveNews = false

    init(
        healthService: HealthDataProviding = HealthKitService(),
        newsService: NewsProviding = GoogleNewsRSSService(),
        notificationService: NotificationService = NotificationService()
    ) {
        self.healthService = healthService
        self.newsService = newsService
        self.notificationService = notificationService
    }

    func start() async {
        do {
            try await healthService.requestAuthorization()
            healthAuthorizationRequested = true
        } catch {
            errorMessage = "Apple Health 授權：\(error.localizedDescription)"
        }
        await refresh()
    }

    func requestHealthAuthorization() async {
        do {
            try await healthService.requestAuthorization()
            healthAuthorizationRequested = true
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let healthTask = result { try await healthService.loadSnapshot() }
        let window = BriefingWindow.currentTaipeiWindow()
        async let newsTask = result {
            try await newsService.fetchImportantNews(from: window.start, to: window.end)
        }
        let (healthResult, newsResult) = await (healthTask, newsTask)
        var health = briefing.health
        var news = briefing.news
        var failures: [String] = []

        switch healthResult {
        case .success(let value):
            health = value
        case .failure(let error):
            failures.append("健康資料：\(error.localizedDescription)")
        }

        switch newsResult {
        case .success(let value):
            news = value
            isUsingLiveNews = true
        case .failure(let error):
            failures.append("新聞：\(error.localizedDescription)")
            isUsingLiveNews = false
        }

        do {
            try snapshotStore.save(health)
            let recovery = recoveryCalculator.calculate(snapshot: health)
            briefing = MorningBriefing(
                generatedAt: .now,
                health: health,
                recovery: recovery,
                recommendations: RecommendationEngine().makeRecommendations(
                    health: health,
                    recovery: recovery
                ),
                news: news
            )
            if UserDefaults.standard.bool(forKey: "morningNotificationEnabled") {
                try? await notificationService.scheduleDailyBriefing(
                    hour: 8,
                    minute: 30,
                    recoveryScore: recovery.score,
                    newsCount: news.count
                )
            }
            updateMessage = Date.now.formatted(
                .dateTime.hour().minute().second().locale(Locale(identifier: "zh_TW"))
            )
        } catch {
            failures.append("儲存資料：\(error.localizedDescription)")
        }

        if !failures.isEmpty {
            errorMessage = failures.joined(separator: "\n")
        }
    }

    func enableMorningNotification() async {
        do {
            try await notificationService.requestAuthorization()
            try await notificationService.scheduleDailyBriefing(
                hour: 8,
                minute: 30,
                recoveryScore: briefing.recovery.score,
                newsCount: briefing.news.count
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private func result<T: Sendable>(
    _ operation: @Sendable () async throws -> T
) async -> Result<T, Error> {
    do {
        return .success(try await operation())
    } catch {
        return .failure(error)
    }
}

private struct BriefingWindow {
    let start: Date
    let end: Date

    static func currentTaipeiWindow(now: Date = .now) -> BriefingWindow {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei") ?? .current
        let startOfToday = calendar.startOfDay(for: now)
        let todayAtNine = calendar.date(byAdding: .hour, value: 9, to: startOfToday) ?? now
        let end = min(now, todayAtNine)
        let start = calendar.date(byAdding: .day, value: -1, to: todayAtNine) ?? end
        return BriefingWindow(start: start, end: end)
    }
}
