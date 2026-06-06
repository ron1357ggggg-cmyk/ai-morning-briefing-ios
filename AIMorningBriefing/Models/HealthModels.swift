import Foundation

struct MetricValue: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let title: String
    let value: Double?
    let unit: String
    let sevenDayAverage: Double?
    let thirtyDayAverage: Double?
    let ninetyDayAverage: Double?

    var changeFromThirtyDays: Double? {
        guard let value, let baseline = thirtyDayAverage, baseline != 0 else { return nil }
        return ((value - baseline) / baseline) * 100
    }
}

struct SleepSummary: Equatable, Codable, Sendable {
    let totalHours: Double?
    let coreHours: Double?
    let deepHours: Double?
    let remHours: Double?
    let awakeHours: Double?
}

struct HealthSnapshot: Equatable, Codable, Sendable {
    let date: Date
    let weight: MetricValue
    let bodyFat: MetricValue
    let steps: MetricValue
    let sleep: SleepSummary
    let restingHeartRate: MetricValue
    let hrv: MetricValue
    let activeEnergy: MetricValue
    let exerciseMinutes: MetricValue
    let averageHeartRate: MetricValue
    let isSampleData: Bool

    static let preview = HealthSnapshot(
        date: .now,
        weight: .init(
            id: "weight",
            title: "體重",
            value: 78.4,
            unit: "kg",
            sevenDayAverage: 78.7,
            thirtyDayAverage: 79.1,
            ninetyDayAverage: 80.0
        ),
        bodyFat: .init(
            id: "bodyFat",
            title: "體脂率",
            value: 18.2,
            unit: "%",
            sevenDayAverage: 18.4,
            thirtyDayAverage: 18.8,
            ninetyDayAverage: 19.1
        ),
        steps: .init(
            id: "steps",
            title: "步數",
            value: 8_420,
            unit: "步",
            sevenDayAverage: 7_800,
            thirtyDayAverage: 7_350,
            ninetyDayAverage: 7_100
        ),
        sleep: .init(
            totalHours: 7.6,
            coreHours: 4.4,
            deepHours: 1.2,
            remHours: 1.7,
            awakeHours: 0.3
        ),
        restingHeartRate: .init(
            id: "rhr",
            title: "靜止心率",
            value: 56,
            unit: "bpm",
            sevenDayAverage: 58,
            thirtyDayAverage: 59,
            ninetyDayAverage: 60
        ),
        hrv: .init(
            id: "hrv",
            title: "HRV",
            value: 58,
            unit: "ms",
            sevenDayAverage: 54,
            thirtyDayAverage: 52,
            ninetyDayAverage: 50
        ),
        activeEnergy: .init(
            id: "energy",
            title: "活動熱量",
            value: 620,
            unit: "kcal",
            sevenDayAverage: 580,
            thirtyDayAverage: 550,
            ninetyDayAverage: 530
        ),
        exerciseMinutes: .init(
            id: "exercise",
            title: "運動時間",
            value: 48,
            unit: "分",
            sevenDayAverage: 42,
            thirtyDayAverage: 38,
            ninetyDayAverage: 35
        ),
        averageHeartRate: .init(
            id: "heartRate",
            title: "平均心率",
            value: 72,
            unit: "bpm",
            sevenDayAverage: 73,
            thirtyDayAverage: 74,
            ninetyDayAverage: 74
        ),
        isSampleData: true
    )
}
