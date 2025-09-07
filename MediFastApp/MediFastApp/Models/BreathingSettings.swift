import Foundation

struct BreathingSettings: Codable, Equatable {
    var rounds: Int
    var breathsPerRound: Int
    var recoveryHoldSeconds: Int
    var paceSeconds: Int // seconds per breath during auto-pace (2/3/4)
    var vibrateAfterRound: Bool // feedback options
    var dingAfterRound: Bool

    init(rounds: Int, breathsPerRound: Int, recoveryHoldSeconds: Int, paceSeconds: Int = 3, vibrateAfterRound: Bool = false, dingAfterRound: Bool = false) {
        self.rounds = rounds
        self.breathsPerRound = breathsPerRound
        self.recoveryHoldSeconds = recoveryHoldSeconds
        self.paceSeconds = max(1, paceSeconds)
        self.vibrateAfterRound = vibrateAfterRound
        self.dingAfterRound = dingAfterRound
    }

    // Backward-compatible decoding (pace defaults to 3s; toggles default to false)
    enum CodingKeys: String, CodingKey { case rounds, breathsPerRound, recoveryHoldSeconds, paceSeconds, vibrateAfterRound, dingAfterRound }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.rounds = try c.decode(Int.self, forKey: .rounds)
        self.breathsPerRound = try c.decode(Int.self, forKey: .breathsPerRound)
        self.recoveryHoldSeconds = try c.decode(Int.self, forKey: .recoveryHoldSeconds)
        self.paceSeconds = (try? c.decode(Int.self, forKey: .paceSeconds)) ?? 3
        self.vibrateAfterRound = (try? c.decode(Bool.self, forKey: .vibrateAfterRound)) ?? false
        self.dingAfterRound = (try? c.decode(Bool.self, forKey: .dingAfterRound)) ?? false
    }
}
