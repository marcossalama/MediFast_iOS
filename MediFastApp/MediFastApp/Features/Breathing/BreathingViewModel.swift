import Foundation
import SwiftUI

/// Guided breathing (Wim Hof style): breaths → retention hold → recovery hold, repeated for N rounds.
@MainActor
final class BreathingViewModel: ObservableObject {
    enum Phase { case breathing, retention, recovery, completed }
    enum BreathPhase { case inhale, exhale }

    @Published private(set) var settings: BreathingSettings
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var phase: Phase = .breathing
    @Published private(set) var breathCount: Int = 0
    @Published private(set) var retentionElapsed: TimeInterval = 0
    @Published private(set) var recoveryRemaining: TimeInterval = 0

    // Results per round (retention durations)
    @Published private(set) var results: [BreathingRoundResult] = []

    // Auto-breath pacing (seconds accumulator)
    private var breathTickCounter: Int = 0

    // Storage for settings/history (local only)
    private let storage: StorageProtocol

    init(settings: BreathingSettings, storage: StorageProtocol = UserDefaultsStorage()) {
        self.settings = settings
        self.storage = storage
        // Persist chosen settings for convenience
        try? storage.save(settings, forKey: UDKeys.breathingSettings)
    }

    // Display helpers
    var displayValue: String {
        switch phase {
        case .breathing: return "\(breathCount)"
        case .retention: return TimeFormatter.ms(retentionElapsed)
        case .recovery: return TimeFormatter.ms(recoveryRemaining)
        case .completed: return "Done"
        }
    }

    /// Current sub-phase of a single breath during auto-pace.
    var breathPhase: BreathPhase {
        guard phase == .breathing else { return .exhale }
        let p = max(1, settings.paceSeconds)
        // First half (rounded up) = inhale, second half = exhale
        let pivot = (p + 1) / 2
        return breathTickCounter < pivot ? .inhale : .exhale
    }

    /// 0...1 progress within the current breath window.
    var breathProgress: Double {
        let p = max(1, settings.paceSeconds)
        return min(1, Double(breathTickCounter) / Double(p))
    }

    // MARK: - Timer tick (foreground only)
    func tick(isActive: Bool) {
        guard isActive else { return }
        switch phase {
        case .breathing:
            // Auto-pace: increment breath count every paceSeconds while active
            breathTickCounter += 1
            if breathTickCounter >= max(1, settings.paceSeconds) {
                breathTickCounter = 0
                if breathCount < settings.breathsPerRound {
                    breathCount += 1
                    if breathCount >= settings.breathsPerRound {
                        Haptics.impact(.soft) // hint that target breaths reached
                    }
                }
            }
        case .retention:
            retentionElapsed += 1
        case .recovery:
            if recoveryRemaining > 0 { recoveryRemaining -= 1 }
            if recoveryRemaining <= 0 { advanceAfterRecovery() }
        case .completed:
            break
        }
    }
}

// MARK: - Intents
extension BreathingViewModel {
    func handleSingleTap() {
        guard phase == .breathing else { return }
        // Manual taps respect the configured round size to keep history accurate.
        guard breathCount < settings.breathsPerRound else { return }
        breathCount += 1
        if breathCount == settings.breathsPerRound { Haptics.impact(.soft) }
    }

    func handleDoubleTap() {
        switch phase {
        case .breathing:
            startRetention()
        case .retention:
            startRecovery()
        case .recovery:
            advanceAfterRecovery()
        case .completed:
            break
        }
    }

    func finishEarly() {
        phase = .completed
        persistHistory()
    }
}

// MARK: - Phase transitions
private extension BreathingViewModel {
    func startRetention() {
        phase = .retention
        retentionElapsed = 0
        breathTickCounter = 0
        Haptics.impact(.medium)
    }

    func startRecovery() {
        phase = .recovery
        recoveryRemaining = TimeInterval(max(0, settings.recoveryHoldSeconds))
        // Log the finished retention round
        let result = BreathingRoundResult(id: UUID(), round: currentRound, breaths: breathCount, retentionSeconds: retentionElapsed)
        results.append(result)
        breathTickCounter = 0
        // Optional feedback on round transition
        if settings.vibrateAfterRound { Haptics.impact(.medium) }
        if settings.dingAfterRound { AudioPlayer.shared.play(named: Sounds.bellMid) }
    }

    func advanceAfterRecovery() {
        if currentRound < settings.rounds {
            currentRound += 1
            // Reset counters for next round
            breathCount = 0
            retentionElapsed = 0
            recoveryRemaining = 0
            breathTickCounter = 0
            phase = .breathing
            Haptics.notify(.success)
        } else {
            phase = .completed
            recoveryRemaining = 0
            breathTickCounter = 0
            Haptics.notify(.success)
            persistHistory()
            // Final bell at the end of the full session
            AudioPlayer.shared.play(named: Sounds.bellEnd)
        }
    }

    func persistHistory() {
        // Persist latest session results (overwrite). Keep lightweight.
        try? storage.save(results, forKey: UDKeys.breathingHistory)
    }
}

// MARK: - Display Strings
extension BreathingViewModel.Phase {
    var title: String {
        switch self {
        case .breathing: return "Take deep breaths"
        case .retention: return "Let go and hold"
        case .recovery: return "Recovery breath"
        case .completed: return "Completed"
        }
    }
}
