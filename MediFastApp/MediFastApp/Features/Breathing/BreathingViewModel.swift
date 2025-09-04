import Foundation
import SwiftUI

/// Minimal state machine scaffold for guided breathing.
@MainActor
final class BreathingViewModel: ObservableObject {
    enum Phase { case breathing, retention, recovery, completed }

    @Published private(set) var settings: BreathingSettings
    @Published private(set) var currentRound: Int = 1
    @Published private(set) var phase: Phase = .breathing
    @Published private(set) var breathCount: Int = 0
    @Published private(set) var retentionElapsed: TimeInterval = 0
    @Published private(set) var recoveryRemaining: TimeInterval = 0

    // Storage for potential later persistence, injected
    private let storage: StorageProtocol

    init(settings: BreathingSettings, storage: StorageProtocol = UserDefaultsStorage()) {
        self.settings = settings
        self.storage = storage
    }

    // Display helpers for scaffold
    var displayValue: String {
        switch phase {
        case .breathing: return "\(breathCount)"
        case .retention: return TimeFormatter.ms(retentionElapsed)
        case .recovery: return TimeFormatter.ms(recoveryRemaining)
        case .completed: return "Done"
        }
    }
}

// MARK: - Intents (stubs for scaffold)
extension BreathingViewModel {
    func handleSingleTap() {
        if phase == .breathing { breathCount += 1 }
    }

    func handleDoubleTap() {
        // Placeholder phase advance; full logic will come in implementation step
        switch phase {
        case .breathing: phase = .retention
        case .retention: phase = .recovery
        case .recovery:
            if currentRound < settings.rounds {
                currentRound += 1
                breathCount = 0
                phase = .breathing
            } else {
                phase = .completed
            }
        case .completed: break
        }
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
