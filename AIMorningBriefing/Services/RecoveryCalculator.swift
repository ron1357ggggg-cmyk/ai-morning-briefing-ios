import Foundation

struct RecoveryCalculator {
    func calculate(snapshot: HealthSnapshot) -> RecoveryScore {
        let sleep = sleepScore(hours: snapshot.sleep.totalHours)
        let hrv = relativeScore(
            current: snapshot.hrv.value,
            baseline: snapshot.hrv.thirtyDayAverage,
            higherIsBetter: true
        )
        let restingHeartRate = relativeScore(
            current: snapshot.restingHeartRate.value,
            baseline: snapshot.restingHeartRate.thirtyDayAverage,
            higherIsBetter: false
        )
        let activity = activityScore(
            steps: snapshot.steps.value,
            exerciseMinutes: snapshot.exerciseMinutes.value
        )

        let total = sleep * 0.40 + hrv * 0.30 + restingHeartRate * 0.20 + activity * 0.10
        let rounded = Int(total.rounded())
        let status: RecoveryStatus = switch rounded {
        case 85...: .excellent
        case 70..<85: .good
        case 50..<70: .moderate
        default: .low
        }

        return RecoveryScore(
            score: rounded,
            status: status,
            sleepScore: sleep,
            hrvScore: hrv,
            restingHeartRateScore: restingHeartRate,
            activityScore: activity
        )
    }

    private func sleepScore(hours: Double?) -> Double {
        guard let hours else { return 50 }
        switch hours {
        case 7.5...9.0: return 100
        case 7.0..<7.5, 9.0..<9.5: return 85
        case 6.0..<7.0, 9.5..<10.0: return 65
        default: return 40
        }
    }

    private func relativeScore(
        current: Double?,
        baseline: Double?,
        higherIsBetter: Bool
    ) -> Double {
        guard let current, let baseline, baseline > 0 else { return 50 }
        let ratio = current / baseline
        let adjusted = higherIsBetter ? ratio : (2 - ratio)
        return min(100, max(0, adjusted * 80))
    }

    private func activityScore(steps: Double?, exerciseMinutes: Double?) -> Double {
        let stepScore = min(100, (steps ?? 0) / 8_000 * 100)
        let exerciseScore = min(100, (exerciseMinutes ?? 0) / 30 * 100)
        return stepScore * 0.5 + exerciseScore * 0.5
    }
}

struct RecommendationEngine {
    func makeRecommendations(
        health: HealthSnapshot,
        recovery: RecoveryScore
    ) -> [String] {
        var items: [String] = []
        switch recovery.status {
        case .excellent:
            items.append("恢復狀態極佳，適合安排高強度訓練。")
        case .good:
            items.append("恢復狀態良好，適合正常重訓或有氧。")
        case .moderate:
            items.append("今天建議降低訓練量，保留 2 至 3 次餘力。")
        case .low:
            items.append("優先休息或進行低強度活動，避免高強度訓練。")
        }

        if (health.sleep.totalHours ?? 0) < 7 {
            items.append("睡眠不足 7 小時，今晚建議提早就寢。")
        }
        if let hrvChange = health.hrv.changeFromThirtyDays, hrvChange < -10 {
            items.append("HRV 低於 30 日基準，留意壓力與疲勞。")
        }
        if (health.steps.value ?? 0) < 5_000 {
            items.append("今天可安排短時間散步，增加低強度活動量。")
        }
        return Array(items.prefix(3))
    }
}
