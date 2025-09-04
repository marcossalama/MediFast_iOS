import Foundation

/// A completed meditation session.
struct MeditationSession: Identifiable, Codable, Equatable {
    var id: UUID
    var startAt: Date
    var endAt: Date
    var duration: TimeInterval // seconds
}

