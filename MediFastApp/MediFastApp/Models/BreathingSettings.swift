import Foundation

struct BreathingSettings: Codable, Equatable {
    var rounds: Int
    var breathsPerRound: Int
    var recoveryHoldSeconds: Int
    var paceSeconds: Int // seconds per breath during auto-pace (2/3/4)

    init(rounds: Int, breathsPerRound: Int, recoveryHoldSeconds: Int, paceSeconds: Int = 3) {
        self.rounds = rounds
        self.breathsPerRound = breathsPerRound
        self.recoveryHoldSeconds = recoveryHoldSeconds
        self.paceSeconds = max(1, paceSeconds)
    }

    // Backward-compatible decoding (pace defaults to 3s if absent)
    enum CodingKeys: String, CodingKey { case rounds, breathsPerRound, recoveryHoldSeconds, paceSeconds }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rounds = try c.decode(Int.self, forKey: .rounds)
        self.breathsPerRound = try c.decode(Int.self, forKey: .breathsPerRound)
        self.recoveryHoldSeconds = try c.decode(Int.self, forKey: .recoveryHoldSeconds)
        self.paceSeconds = (try? c.decode(Int.self, forKey: .paceSeconds)) ?? 3
    }
}
