import Foundation

enum BiologicalSex: String, Codable, Sendable {
    case female = "女性"
    case male = "男性"
    case other = "其他／未設定"
}

struct UserDemographics: Equatable, Codable, Sendable {
    let age: Int?
    let sex: BiologicalSex

    static let preview = UserDemographics(age: 35, sex: .male)
}

enum BenchmarkConfidence: String, Codable, Sendable {
    case populationPercentile = "人口百分位"
    case researchOrientation = "研究參考"
}

struct PeerBenchmarkResult: Identifiable, Equatable, Codable, Sendable {
    let id: String
    let metricTitle: String
    let valueText: String
    let label: String
    let percentile: Int?
    let confidence: BenchmarkConfidence
    let referenceText: String
    let sourceTitle: String
    let sourceURL: URL
}

struct PeerBenchmarkService: Sendable {
    func benchmarks(
        health: HealthSnapshot,
        demographics: UserDemographics
    ) -> [PeerBenchmarkResult] {
        guard let age = demographics.age else { return [] }
        var results: [PeerBenchmarkResult] = []

        if let value = health.restingHeartRate.value,
           let row = RestingHeartRateReference.row(age: age, sex: demographics.sex) {
            let populationPercentile = row.percentile(for: value)
            let favorablePercentile = 100 - populationPercentile
            results.append(
                PeerBenchmarkResult(
                    id: "restingHeartRate",
                    metricTitle: "靜止心率",
                    valueText: "\(Int(value.rounded())) bpm",
                    label: Self.label(percentile: favorablePercentile),
                    percentile: favorablePercentile,
                    confidence: .populationPercentile,
                    referenceText: "\(row.ageLabel)、\(row.sexLabel)；較低心率視為較佳方向。",
                    sourceTitle: "CDC NHANES 1999–2008",
                    sourceURL: URL(string: "https://www.cdc.gov/nchs/data/nhsr/nhsr041.pdf")!
                )
            )
        }

        if let value = health.hrv.value,
           let heartRate = health.averageHeartRate.value,
           let row = HRVReference.row(age: age, sex: demographics.sex) {
            let correctedValue = value * exp(-0.02263 * (60 - heartRate))
            let percentile = row.percentile(for: correctedValue)
            results.append(
                PeerBenchmarkResult(
                    id: "hrv",
                    metricTitle: "HRV（SDNN）",
                    valueText: value.formatted(.number.precision(.fractionLength(1))) + " ms",
                    label: Self.label(percentile: percentile),
                    percentile: percentile,
                    confidence: .researchOrientation,
                    referenceText: "\(row.ageLabel)、\(row.sexLabel)；以同日平均心率近似校正為 \(correctedValue.formatted(.number.precision(.fractionLength(1)))) ms。研究為 10 秒 ECG，與 Apple Watch 採樣不同。",
                    sourceTitle: "van den Berg et al., Frontiers in Physiology 2018",
                    sourceURL: URL(string: "https://doi.org/10.3389/fphys.2018.00424")!
                )
            )
        }

        return results
    }

    private static func label(percentile: Int) -> String {
        switch percentile {
        case 75...: "高於多數同齡者"
        case 40..<75: "接近同齡中間範圍"
        case 20..<40: "低於同齡中間範圍"
        default: "明顯低於同齡參考"
        }
    }
}

private struct PercentilePoint: Sendable {
    let percentile: Double
    let value: Double
}

private protocol PercentileReferenceRow {
    var points: [PercentilePoint] { get }
}

private extension PercentileReferenceRow {
    func percentile(for value: Double) -> Int {
        guard let first = points.first, let last = points.last else { return 50 }
        if value <= first.value { return Int(first.percentile) }
        if value >= last.value { return Int(last.percentile) }

        for index in 1..<points.count {
            let lower = points[index - 1]
            let upper = points[index]
            guard value <= upper.value else { continue }
            let fraction = (value - lower.value) / (upper.value - lower.value)
            return Int((lower.percentile + fraction * (upper.percentile - lower.percentile)).rounded())
        }
        return Int(last.percentile)
    }
}

private struct RestingHeartRateRow: PercentileReferenceRow, Sendable {
    let ageRange: ClosedRange<Int>
    let ageLabel: String
    let sex: BiologicalSex
    let sexLabel: String
    let points: [PercentilePoint]
}

private enum RestingHeartRateReference {
    private static let percentiles: [Double] = [1, 2.5, 5, 10, 25, 50, 75, 90, 95, 97.5, 99]

    static let rows: [RestingHeartRateRow] = [
        row(16...19, "16–19 歲", .male, [46, 50, 52, 56, 61, 69, 78, 87, 92, 95, 104]),
        row(20...39, "20–39 歲", .male, [47, 50, 52, 55, 61, 69, 76, 84, 89, 95, 101]),
        row(40...59, "40–59 歲", .male, [46, 49, 52, 55, 61, 68, 77, 85, 90, 95, 104]),
        row(60...79, "60–79 歲", .male, [45, 48, 50, 54, 60, 67, 75, 84, 91, 98, 102]),
        row(
            80...120,
            "80 歲以上",
            .male,
            percentiles: [2.5, 5, 10, 25, 50, 75, 90, 95, 97.5],
            values: [48, 51, 54, 61, 68, 78, 86, 94, 97]
        ),
        row(16...19, "16–19 歲", .female, [50, 54, 58, 62, 69, 77, 85, 94, 99, 103, 108]),
        row(20...39, "20–39 歲", .female, [52, 55, 57, 60, 66, 74, 82, 89, 95, 99, 104]),
        row(40...59, "40–59 歲", .female, [51, 53, 56, 59, 64, 71, 79, 86, 92, 97, 101]),
        row(60...79, "60–79 歲", .female, [52, 54, 56, 59, 64, 70, 78, 86, 92, 96, 102]),
        row(
            80...120,
            "80 歲以上",
            .female,
            percentiles: [2.5, 5, 10, 25, 50, 75, 90, 95, 97.5, 99],
            values: [53, 56, 59, 64, 71, 77, 85, 93, 98, 100]
        ),
    ]

    static func row(age: Int, sex: BiologicalSex) -> RestingHeartRateRow? {
        if sex == .female || sex == .male {
            return rows.first { $0.sex == sex && $0.ageRange.contains(age) }
        }
        return averagedRow(age: age)
    }

    private static func row(
        _ ageRange: ClosedRange<Int>,
        _ ageLabel: String,
        _ sex: BiologicalSex,
        _ values: [Double]
    ) -> RestingHeartRateRow {
        row(
            ageRange,
            ageLabel,
            sex,
            percentiles: percentiles,
            values: values
        )
    }

    private static func row(
        _ ageRange: ClosedRange<Int>,
        _ ageLabel: String,
        _ sex: BiologicalSex,
        percentiles: [Double],
        values: [Double]
    ) -> RestingHeartRateRow {
        RestingHeartRateRow(
            ageRange: ageRange,
            ageLabel: ageLabel,
            sex: sex,
            sexLabel: sex.rawValue,
            points: zip(percentiles, values).map(PercentilePoint.init)
        )
    }

    private static func averagedRow(age: Int) -> RestingHeartRateRow? {
        guard let male = rows.first(where: { $0.sex == .male && $0.ageRange.contains(age) }),
              let female = rows.first(where: { $0.sex == .female && $0.ageRange.contains(age) })
        else { return nil }
        return RestingHeartRateRow(
            ageRange: male.ageRange,
            ageLabel: male.ageLabel,
            sex: .other,
            sexLabel: "全部性別參考",
            points: zip(male.points, female.points).map { malePoint, femalePoint in
                PercentilePoint(
                    percentile: malePoint.percentile,
                    value: (malePoint.value + femalePoint.value) / 2
                )
            }
        )
    }
}

private struct HRVRow: PercentileReferenceRow, Sendable {
    let ageRange: ClosedRange<Int>
    let ageLabel: String
    let sex: BiologicalSex
    let sexLabel: String
    let points: [PercentilePoint]
}

private enum HRVReference {
    static let rows: [HRVRow] = [
        row(16...19, "16–19 歲", .male, 17.8, 60.7, 190.9),
        row(20...29, "20–29 歲", .male, 13.9, 48.5, 161.4),
        row(30...39, "30–39 歲", .male, 11.0, 37.5, 129.2),
        row(40...49, "40–49 歲", .male, 8.8, 30.4, 113.7),
        row(50...59, "50–59 歲", .male, 6.9, 24.4, 103.4),
        row(60...69, "60–69 歲", .male, 5.6, 20.4, 104.8),
        row(70...79, "70–79 歲", .male, 4.7, 17.8, 120.9),
        row(80...89, "80–89 歲", .male, 3.9, 15.6, 158.3),
        row(16...19, "16–19 歲", .female, 20.0, 67.3, 199.2),
        row(20...29, "20–29 歲", .female, 16.6, 56.0, 172.7),
        row(30...39, "30–39 歲", .female, 13.3, 43.4, 137.8),
        row(40...49, "40–49 歲", .female, 10.6, 33.3, 109.5),
        row(50...59, "50–59 歲", .female, 8.4, 25.6, 90.2),
        row(60...69, "60–69 歲", .female, 6.9, 20.7, 82.8),
        row(70...79, "70–79 歲", .female, 5.9, 17.9, 89.5),
        row(80...89, "80–89 歲", .female, 5.1, 16.1, 126.1),
    ]

    static func row(age: Int, sex: BiologicalSex) -> HRVRow? {
        if sex == .female || sex == .male {
            return rows.first { $0.sex == sex && $0.ageRange.contains(age) }
        }
        return averagedRow(age: age)
    }

    private static func row(
        _ ageRange: ClosedRange<Int>,
        _ ageLabel: String,
        _ sex: BiologicalSex,
        _ p2: Double,
        _ p50: Double,
        _ p98: Double
    ) -> HRVRow {
        HRVRow(
            ageRange: ageRange,
            ageLabel: ageLabel,
            sex: sex,
            sexLabel: sex.rawValue,
            points: [
                PercentilePoint(percentile: 2, value: p2),
                PercentilePoint(percentile: 50, value: p50),
                PercentilePoint(percentile: 98, value: p98),
            ]
        )
    }

    private static func averagedRow(age: Int) -> HRVRow? {
        guard let male = rows.first(where: { $0.sex == .male && $0.ageRange.contains(age) }),
              let female = rows.first(where: { $0.sex == .female && $0.ageRange.contains(age) })
        else { return nil }
        return HRVRow(
            ageRange: male.ageRange,
            ageLabel: male.ageLabel,
            sex: .other,
            sexLabel: "全部性別參考",
            points: zip(male.points, female.points).map { malePoint, femalePoint in
                PercentilePoint(
                    percentile: malePoint.percentile,
                    value: (malePoint.value + femalePoint.value) / 2
                )
            }
        )
    }
}
