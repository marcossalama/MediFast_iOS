import Foundation

/// User-configurable meditation preferences. Codable for local persistence.
struct MeditationSettings: Codable, Equatable {
    var presetMinutes: Int
    var midpointInterval: Int? // minutes; optional recurring midpoint bell
    var warmupSeconds: Int?    // optional warm-up 5–15s
}

