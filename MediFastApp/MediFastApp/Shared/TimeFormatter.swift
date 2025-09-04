import Foundation

/// Common time formatting helpers.
enum TimeFormatter {
    /// Formats a duration as HH:MM:SS (hours may exceed 24).
    static func hms(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    /// Formats a duration as MM:SS, clamping at 59:59 before rolling to hours.
    static func ms(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

