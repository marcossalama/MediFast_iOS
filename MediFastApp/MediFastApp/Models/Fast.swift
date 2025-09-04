import Foundation

/// Represents a fasting entry. Active fasts have a nil `endAt`.
struct Fast: Identifiable, Codable, Equatable {
    var id: UUID
    var startAt: Date
    var endAt: Date? // set on stop
    var duration: TimeInterval? // computed when ended (seconds)
}

