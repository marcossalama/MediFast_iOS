import Foundation

struct BreathingRoundResult: Identifiable, Codable, Equatable {
    var id: UUID
    var round: Int
    var breaths: Int
    var retentionSeconds: TimeInterval
}

