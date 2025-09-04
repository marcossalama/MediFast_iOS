import Foundation

/// UserDefaults keys (versioned) used across features.
enum UDKeys {
    // Meditation
    static let meditationSettings = "meditation.settings.v1"
    static let meditationSessions = "meditation.sessions.v1" // [MeditationSession]
    static let meditationStreaks = "meditation.streaks.v1"   // StreaksState

    // Fasting
    static let fastingActive = "fasting.active.v1"  // Optional active fast
    static let fastingHistory = "fasting.history.v1" // [Fast]
}

