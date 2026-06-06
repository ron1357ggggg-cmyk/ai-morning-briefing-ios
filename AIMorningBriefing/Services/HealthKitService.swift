import Foundation
import HealthKit

protocol HealthDataProviding: Sendable {
    func requestAuthorization() async throws
    func loadSnapshot() async throws -> HealthSnapshot
    func loadDemographics() async -> UserDemographics
}

final class HealthKitService: HealthDataProviding, @unchecked Sendable {
    private let store = HKHealthStore()
    private let calendar = Calendar.current

    func requestAuthorization() async throws {
#if targetEnvironment(simulator)
        return
#else
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthServiceError.unavailable
        }
        try await store.requestAuthorization(toShare: [], read: readTypes)
#endif
    }

    func loadSnapshot() async throws -> HealthSnapshot {
#if targetEnvironment(simulator)
        return .preview
#else
        guard HKHealthStore.isHealthDataAvailable() else {
            return .preview
        }

        async let weight = metric(
            id: "weight",
            title: "體重",
            identifier: .bodyMass,
            unit: .gramUnit(with: .kilo),
            displayUnit: "kg",
            aggregation: .latest
        )
        async let bodyFat = metric(
            id: "bodyFat",
            title: "體脂率",
            identifier: .bodyFatPercentage,
            unit: .percent(),
            displayUnit: "%",
            multiplier: 100,
            aggregation: .latest
        )
        async let steps = metric(
            id: "steps",
            title: "步數",
            identifier: .stepCount,
            unit: .count(),
            displayUnit: "步",
            aggregation: .sum
        )
        async let rhr = metric(
            id: "rhr",
            title: "靜止心率",
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            displayUnit: "bpm",
            aggregation: .average
        )
        async let hrv = metric(
            id: "hrv",
            title: "HRV",
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            displayUnit: "ms",
            aggregation: .average
        )
        async let energy = metric(
            id: "energy",
            title: "活動熱量",
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            displayUnit: "kcal",
            aggregation: .sum
        )
        async let exercise = metric(
            id: "exercise",
            title: "運動時間",
            identifier: .appleExerciseTime,
            unit: .minute(),
            displayUnit: "分",
            aggregation: .sum
        )
        async let heartRate = metric(
            id: "heartRate",
            title: "平均心率",
            identifier: .heartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            displayUnit: "bpm",
            aggregation: .average
        )
        async let sleep = loadSleep()

        let snapshot = HealthSnapshot(
            date: .now,
            weight: try await weight,
            bodyFat: try await bodyFat,
            steps: try await steps,
            sleep: try await sleep,
            restingHeartRate: try await rhr,
            hrv: try await hrv,
            activeEnergy: try await energy,
            exerciseMinutes: try await exercise,
            averageHeartRate: try await heartRate,
            isSampleData: false
        )

        let hasAnyValue = [
            snapshot.weight.value,
            snapshot.steps.value,
            snapshot.restingHeartRate.value,
            snapshot.hrv.value,
        ].contains { $0 != nil }
        return hasAnyValue ? snapshot : .preview
#endif
    }

    func loadDemographics() async -> UserDemographics {
#if targetEnvironment(simulator)
        return .preview
#else
        let birthDate = try? store.dateOfBirthComponents().date
        let age = birthDate.flatMap {
            Calendar.current.dateComponents([.year], from: $0, to: .now).year
        }
        let healthKitSex = try? store.biologicalSex().biologicalSex
        let sex: BiologicalSex = switch healthKitSex {
        case .female: .female
        case .male: .male
        default: .other
        }
        return UserDemographics(age: age, sex: sex)
#endif
    }

    private var readTypes: Set<HKObjectType> {
        let quantityIdentifiers: [HKQuantityTypeIdentifier] = [
            .bodyMass,
            .bodyFatPercentage,
            .stepCount,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .activeEnergyBurned,
            .appleExerciseTime,
            .heartRate,
        ]
        var types = Set<HKObjectType>(
            quantityIdentifiers.compactMap(HKObjectType.quantityType(forIdentifier:))
        )
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(dateOfBirth)
        }
        if let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(biologicalSex)
        }
        return types
    }

    private enum Aggregation: Equatable {
        case sum
        case average
        case latest
    }

    private func metric(
        id: String,
        title: String,
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        displayUnit: String,
        multiplier: Double = 1,
        aggregation: Aggregation
    ) async throws -> MetricValue {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else {
            throw HealthServiceError.unsupportedType(identifier.rawValue)
        }

        async let current = value(
            type: type,
            unit: unit,
            daysAgo: 0,
            durationDays: aggregation == .latest ? 90 : 1,
            aggregation: aggregation
        )
        let baselineAggregation: Aggregation = aggregation == .latest ? .average : aggregation
        async let seven = value(
            type: type,
            unit: unit,
            daysAgo: 0,
            durationDays: 7,
            aggregation: baselineAggregation
        )
        async let thirty = value(
            type: type,
            unit: unit,
            daysAgo: 0,
            durationDays: 30,
            aggregation: baselineAggregation
        )
        async let ninety = value(
            type: type,
            unit: unit,
            daysAgo: 0,
            durationDays: 90,
            aggregation: baselineAggregation
        )

        return MetricValue(
            id: id,
            title: title,
            value: try await current.map { $0 * multiplier },
            unit: displayUnit,
            sevenDayAverage: try await seven.map { $0 * multiplier },
            thirtyDayAverage: try await thirty.map { $0 * multiplier },
            ninetyDayAverage: try await ninety.map { $0 * multiplier }
        )
    }

    private func value(
        type: HKQuantityType,
        unit: HKUnit,
        daysAgo: Int,
        durationDays: Int,
        aggregation: Aggregation
    ) async throws -> Double? {
        let end = Date()
        let start: Date
        if daysAgo == 0 && durationDays == 1 {
            start = calendar.startOfDay(for: end)
        } else {
            start = calendar.date(byAdding: .day, value: -(daysAgo + durationDays), to: end) ?? end
        }
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        if aggregation == .latest {
            return try await latestValue(type: type, unit: unit, predicate: predicate)
        }

        let option: HKStatisticsOptions = aggregation == .sum ? .cumulativeSum : .discreteAverage
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: option
            ) { _, statistics, error in
                if let error {
                    if HealthQueryErrorPolicy.isMissingData(error) {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                let quantity = aggregation == .sum
                    ? statistics?.sumQuantity()
                    : statistics?.averageQuantity()
                let rawValue = quantity?.doubleValue(for: unit)
                let normalized = durationDays > 1 && aggregation == .sum
                    ? rawValue.map { $0 / Double(durationDays) }
                    : rawValue
                continuation.resume(returning: normalized)
            }
            store.execute(query)
        }
    }

    private func latestValue(
        type: HKQuantityType,
        unit: HKUnit,
        predicate: NSPredicate
    ) async throws -> Double? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error {
                    if HealthQueryErrorPolicy.isMissingData(error) {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }
            store.execute(query)
        }
    }

    private func loadSleep() async throws -> SleepSummary {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return .init(totalHours: nil, coreHours: nil, deepHours: nil, remHours: nil, awakeHours: nil)
        }
        let end = Date()
        let start = calendar.date(byAdding: .hour, value: -18, to: end) ?? end
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    if HealthQueryErrorPolicy.isMissingData(error) {
                        continuation.resume(returning: .empty)
                        return
                    }
                    continuation.resume(throwing: error)
                    return
                }

                let categorySamples = (samples as? [HKCategorySample]) ?? []
                func hours(for values: Set<Int>) -> Double {
                    categorySamples
                        .filter { values.contains($0.value) }
                        .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } / 3_600
                }

                let core = hours(for: [HKCategoryValueSleepAnalysis.asleepCore.rawValue])
                let deep = hours(for: [HKCategoryValueSleepAnalysis.asleepDeep.rawValue])
                let rem = hours(for: [HKCategoryValueSleepAnalysis.asleepREM.rawValue])
                let unspecified = hours(for: [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                ])
                let awake = hours(for: [HKCategoryValueSleepAnalysis.awake.rawValue])
                let stagedSleep = core + deep + rem

                continuation.resume(returning: SleepSummary(
                    totalHours: stagedSleep > 0 ? stagedSleep : unspecified,
                    coreHours: core,
                    deepHours: deep,
                    remHours: rem,
                    awakeHours: awake
                ))
            }
            store.execute(query)
        }
    }
}

enum HealthQueryErrorPolicy {
    static func isMissingData(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == HKErrorDomain
            && error.code == HKError.errorNoData.rawValue
    }
}

enum HealthServiceError: LocalizedError {
    case unavailable
    case unsupportedType(String)

    var errorDescription: String? {
        switch self {
        case .unavailable:
            "此裝置無法使用 Apple Health。"
        case .unsupportedType(let type):
            "此系統不支援健康資料類型：\(type)"
        }
    }
}

struct DailyHealthSnapshotStore: Sendable {
    func save(_ snapshot: HealthSnapshot) throws {
        let url = try storageURL()
        var snapshots = (try? load(from: url)) ?? []
        var calendar = Calendar.current
        calendar.timeZone = .current
        snapshots.removeAll { calendar.isDate($0.date, inSameDayAs: snapshot.date) }
        snapshots.append(snapshot)
        snapshots = Array(snapshots.sorted { $0.date < $1.date }.suffix(120))

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshots)
        try data.write(to: url, options: .atomic)
    }

    private func load(from url: URL) throws -> [HealthSnapshot] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([HealthSnapshot].self, from: Data(contentsOf: url))
    }

    private func storageURL() throws -> URL {
        let fileManager = FileManager.default
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("AIMorningBriefing", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("health-snapshots.json")
    }
}
