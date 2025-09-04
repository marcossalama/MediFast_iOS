import Foundation

/// Tracks consecutive meditation days and best streak (by local calendar days).
struct StreaksState: Codable, Equatable {
    var lastSessionDate: Date?
    var currentStreak: Int
    var bestStreak: Int
}

