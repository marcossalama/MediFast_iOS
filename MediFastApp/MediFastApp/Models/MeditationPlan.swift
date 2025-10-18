import Foundation

/// A chain of meditation sessions to run back-to-back.
/// Each entry is a duration in minutes (1...59). Max 9 entries by design.
struct MeditationPlan: Codable, Equatable {
    var sessionsMinutes: [Int] // e.g. [10, 10, 5]
    var warmupSeconds: Int?    // optional warm-up before the first session only
    var midpointIntervalMinutes: Int? // optional midpoint bell cadence
    var vibrateAfterSession: Bool // optional feedback toggle
    var dingAfterSession: Bool    // optional feedback toggle

    init(
        sessionsMinutes: [Int],
        warmupSeconds: Int?,
        midpointIntervalMinutes: Int? = nil,
        vibrateAfterSession: Bool = false,
        dingAfterSession: Bool = false
    ) {
        self.sessionsMinutes = MeditationPlan.clamped(sessionsMinutes)
        self.warmupSeconds = warmupSeconds
        self.midpointIntervalMinutes = MeditationPlan.normalizedMidpoint(midpointIntervalMinutes)
        self.vibrateAfterSession = vibrateAfterSession
        self.dingAfterSession = dingAfterSession
    }

    static func clamped(_ values: [Int]) -> [Int] {
        let limited = Array(values.prefix(9))
        return limited.map { min(59, max(1, $0)) }
    }
    static func normalizedMidpoint(_ value: Int?) -> Int? {
        guard let value, value > 0 else { return nil }
        return min(59, value)
    }
    private enum CodingKeys: String, CodingKey {
        case sessionsMinutes, warmupSeconds, midpointIntervalMinutes, vibrateAfterSession, dingAfterSession
    }

    // Backward-compatible decode: default toggles to false if absent
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let minutes = try c.decode([Int].self, forKey: .sessionsMinutes)
        self.sessionsMinutes = MeditationPlan.clamped(minutes)
        self.warmupSeconds = try? c.decode(Int.self, forKey: .warmupSeconds)
        self.midpointIntervalMinutes = MeditationPlan.normalizedMidpoint(try? c.decode(Int.self, forKey: .midpointIntervalMinutes))
        self.vibrateAfterSession = (try? c.decode(Bool.self, forKey: .vibrateAfterSession)) ?? false
        self.dingAfterSession = (try? c.decode(Bool.self, forKey: .dingAfterSession)) ?? false
    }
}
