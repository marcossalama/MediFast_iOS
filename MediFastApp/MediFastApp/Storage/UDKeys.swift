import Foundation

/// UserDefaults keys (versioned) used across features.
enum UDKeys {
    // Meditation
    static let meditationSettings = "meditation.settings.v1"
    static let meditationSessions = "meditation.sessions.v1" // [MeditationSession]
    static let meditationStreaks = "meditation.streaks.v1"   // StreaksState
    static let meditationPlan = "meditation.plan.v1"         // MeditationPlan

    // Fasting
    static let fastingActive = "fasting.active.v1"  // Optional active fast
    static let fastingHistory = "fasting.history.v1" // [Fast]

    // Breathing
    static let breathingSettings = "breathing.settings.v1" // BreathingSettings
    static let breathingHistory = "breathing.history.v1"  // [BreathingRoundResult] (optional)
}
