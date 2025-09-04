import Foundation

struct BreathingSettings: Codable, Equatable {
    var rounds: Int
    var breathsPerRound: Int
    var recoveryHoldSeconds: Int
}

