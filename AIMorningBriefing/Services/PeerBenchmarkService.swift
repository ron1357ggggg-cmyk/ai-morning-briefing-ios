import Foundation

struct PeerBenchmarkResult: Equatable, Sendable {
    let label: String
    let percentile: Int?
    let sourceDescription: String
}

protocol PeerBenchmarkProviding: Sendable {
    func benchmark(metricID: String, value: Double, age: Int, sex: String) async throws -> PeerBenchmarkResult
}

struct UnavailablePeerBenchmarkService: PeerBenchmarkProviding {
    func benchmark(
        metricID: String,
        value: Double,
        age: Int,
        sex: String
    ) async throws -> PeerBenchmarkResult {
        PeerBenchmarkResult(
            label: "等待研究資料校準",
            percentile: nil,
            sourceDescription: "MVP 尚未內建未經驗證的同齡百分位。"
        )
    }
}
