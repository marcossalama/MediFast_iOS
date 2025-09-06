import Foundation

/// A chain of meditation sessions to run back-to-back.
/// Each entry is a duration in minutes (1...59). Max 9 entries by design.
struct MeditationPlan: Codable, Equatable {
    var sessionsMinutes: [Int] // e.g. [10, 10, 5]
    var warmupSeconds: Int?    // optional warm-up before the first session only

    init(sessionsMinutes: [Int], warmupSeconds: Int?) {
        self.sessionsMinutes = MeditationPlan.clamped(sessionsMinutes)
        self.warmupSeconds = warmupSeconds
    }

    static func clamped(_ values: [Int]) -> [Int] {
        let limited = Array(values.prefix(9))
        return limited.map { min(59, max(1, $0)) }
    }
}

