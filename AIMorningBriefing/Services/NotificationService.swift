import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async throws {
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleDailyBriefing(
        hour: Int,
        minute: Int,
        recoveryScore: Int,
        newsCount: Int
    ) async throws {
        center.removePendingNotificationRequests(withIdentifiers: ["daily-morning-briefing"])

        let content = UNMutableNotificationContent()
        content.title = "今日晨間簡報已準備"
        content.body = "恢復分數 \(recoveryScore)，\(newsCount) 則重要新聞已整理。"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-morning-briefing",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }
}
