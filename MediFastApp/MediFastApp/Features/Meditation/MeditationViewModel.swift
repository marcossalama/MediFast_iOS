import Foundation
import SwiftUI

/// ViewModel for the Meditation feature: foreground-only ticking, multi-session chaining, local persistence.
@MainActor
final class MeditationViewModel: ObservableObject {
    enum State { case idle, warmup, running, pausedDueToBackground, completed }

    // Legacy UI support: a single-minute value used only as a fallback default
    @Published var selectedMinutes: Int = 10

    // Plan (persisted)
    @Published private(set) var plan: MeditationPlan = MeditationPlan(sessionsMinutes: [10], warmupSeconds: nil)

    // Runtime state
    @Published private(set) var state: State = .idle
    @Published private(set) var currentIndex: Int = 0 // 0-based
    @Published private(set) var startAt: Date? = nil  // per-session
    @Published private(set) var elapsedInCurrent: TimeInterval = 0 // warmup or session seconds
    private var nextMidpointTrigger: TimeInterval? = nil
    private var lastTickAt: Date? = nil

    // Derived helpers
    var warmupSeconds: Int? { plan.warmupSeconds }
    var totalSessions: Int { max(1, plan.sessionsMinutes.count) }
    var currentSessionNumber: Int { min(currentIndex + 1, totalSessions) }
    var sessionMinutes: Int { plan.sessionsMinutes.indices.contains(currentIndex) ? plan.sessionsMinutes[currentIndex] : (plan.sessionsMinutes.last ?? 10) }
    var sessionDuration: TimeInterval { TimeInterval(max(1, sessionMinutes)) * 60 }
    var warmupDuration: TimeInterval { TimeInterval(warmupSeconds ?? 0) }
    var progress: Double {
        switch state {
        case .warmup:
            guard warmupDuration > 0 else { return 0 }
            return min(1, elapsedInCurrent / warmupDuration)
        case .running:
            return min(1, elapsedInCurrent / sessionDuration)
        default:
            return 0
        }
    }
    var remainingSeconds: Int {
        switch state {
        case .warmup: return max(0, Int(warmupDuration - elapsedInCurrent))
        case .running: return max(0, Int(sessionDuration - elapsedInCurrent))
        default: return 0
        }
    }
    private var midpointInterval: TimeInterval? {
        guard let minutes = plan.midpointIntervalMinutes else { return nil }
        return TimeInterval(max(1, minutes)) * 60
    }

    // Storage (injected)
    private let storage: StorageProtocol

    init(storage: StorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        // Prefer new MeditationPlan; migrate from old settings if needed
        if let plan: MeditationPlan = try? storage.load(MeditationPlan.self, forKey: UDKeys.meditationPlan) {
            self.plan = plan
            self.selectedMinutes = plan.sessionsMinutes.first ?? 10
        } else if let legacy: MeditationSettings = try? storage.load(MeditationSettings.self, forKey: UDKeys.meditationSettings) {
            let plan = MeditationPlan(sessionsMinutes: [legacy.presetMinutes], warmupSeconds: legacy.warmupSeconds)
            self.plan = plan
            self.selectedMinutes = legacy.presetMinutes
            try? storage.save(plan, forKey: UDKeys.meditationPlan)
        }
    }

    // MARK: - Intents
    func start(minutes: Int, warmupSeconds: Int?, midpointInterval: Int?) {
        // Backwards-compat entrypoint: create a one-session plan
        let plan = MeditationPlan(
            sessionsMinutes: [minutes],
            warmupSeconds: warmupSeconds,
            midpointIntervalMinutes: midpointInterval
        )
        try? storage.save(plan, forKey: UDKeys.meditationPlan)
        startPlan(plan)
    }

    func startPlan(_ plan: MeditationPlan) {
        self.plan = plan
        try? storage.save(plan, forKey: UDKeys.meditationPlan)
        currentIndex = 0
        elapsedInCurrent = 0
        nextMidpointTrigger = nil
        lastTickAt = nil
        if let w = plan.warmupSeconds, w > 0 {
            state = .warmup
            startAt = nil
        } else {
            beginSession(index: 0, playStartBell: true, startedAt: Date())
        }
    }

    func cancel() {
        state = .idle
        startAt = nil
        elapsedInCurrent = 0
        nextMidpointTrigger = nil
        lastTickAt = nil
    }

    /// Advance timers based on the provided timestamp while active. No background accumulation.
    func tick(at now: Date, isActive: Bool) {
        guard isActive else {
            if state == .running || state == .warmup { state = .pausedDueToBackground }
            lastTickAt = nil
            return
        }

        if state == .pausedDueToBackground {
            if startAt == nil && warmupDuration > 0 && remainingSeconds > 0 {
                state = .warmup
            } else if state != .completed {
                state = .running
            }
        }

        guard state == .warmup || state == .running else {
            lastTickAt = now
            return
        }

        guard let lastTick = lastTickAt else {
            lastTickAt = now
            return
        }

        let delta = now.timeIntervalSince(lastTick)
        guard delta >= 1 else { return }

        let steps = Int(delta)
        for step in 0..<steps {
            let tickDate = lastTick.addingTimeInterval(TimeInterval(step + 1))
            advanceOneSecond(at: tickDate)
            if state == .completed { break }
        }

        if state == .completed {
            lastTickAt = nil
        } else {
            lastTickAt = lastTick.addingTimeInterval(TimeInterval(steps))
        }
    }

    private func beginSession(index: Int, playStartBell: Bool, startedAt: Date) {
        currentIndex = index
        elapsedInCurrent = 0
        state = .running
        startAt = startedAt
        lastTickAt = startedAt
        configureMidpointTrigger()
        if playStartBell {
            Haptics.impact(.light)
            AudioPlayer.shared.play(named: Sounds.bellStart)
        }
    }

    private func advanceOneSecond(at tickDate: Date) {
        switch state {
        case .warmup:
            elapsedInCurrent += 1
            if elapsedInCurrent >= warmupDuration {
                beginSession(index: 0, playStartBell: true, startedAt: tickDate)
            }
        case .running:
            elapsedInCurrent += 1
            handleMidpointIfNeeded()
            if elapsedInCurrent >= sessionDuration {
                endCurrentSessionAndAdvance(now: tickDate)
            }
        default:
            break
        }
    }

    private func endCurrentSessionAndAdvance(now end: Date) {
        let start = startAt ?? end
        let duration = min(sessionDuration, max(0, end.timeIntervalSince(start)))
        let session = MeditationSession(id: UUID(), startAt: start, endAt: end, duration: duration)
        persist(session: session)
        updateStreaks(for: end)
        Haptics.notify(.success)
        nextMidpointTrigger = nil

        let next = currentIndex + 1
        if next < totalSessions {
            // Optional feedback after each session
            if plan.vibrateAfterSession { Haptics.pulse(duration: 2.0, interval: 0.25, style: .rigid) }
            if plan.dingAfterSession { AudioPlayer.shared.play(named: Sounds.bellMid) }
            beginSession(index: next, playStartBell: false, startedAt: end)
        } else {
            state = .completed
            AudioPlayer.shared.play(named: Sounds.bellEnd)
            nextMidpointTrigger = nil
            lastTickAt = nil
        }
    }

    private func configureMidpointTrigger() {
        guard let interval = midpointInterval else {
            nextMidpointTrigger = nil
            return
        }
        nextMidpointTrigger = interval <= sessionDuration ? interval : nil
    }

    private func handleMidpointIfNeeded() {
        guard state == .running,
              nextMidpointTrigger != nil,
              let interval = midpointInterval
        else { return }
        while let trigger = nextMidpointTrigger,
              elapsedInCurrent >= trigger {
            Haptics.impact(.medium)
            AudioPlayer.shared.play(named: Sounds.bellMid)
            let next = trigger + interval
            nextMidpointTrigger = next <= sessionDuration ? next : nil
        }
    }

    // MARK: - Persistence
    private func persist(session: MeditationSession) {
        var sessions: [MeditationSession] = (try? storage.load([MeditationSession].self, forKey: UDKeys.meditationSessions)) ?? []
        sessions.append(session)
        if sessions.count > 500 { sessions.removeFirst(sessions.count - 500) }
        try? storage.save(sessions, forKey: UDKeys.meditationSessions)
    }

    private func updateStreaks(for endDate: Date) {
        var streaks: StreaksState = (try? storage.load(StreaksState.self, forKey: UDKeys.meditationStreaks)) ?? StreaksState(lastSessionDate: nil, currentStreak: 0, bestStreak: 0)
        let cal = Calendar.current
        let endDay = cal.startOfDay(for: endDate)
        if let last = streaks.lastSessionDate {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: endDay) {
                // same day: no change to currentStreak
            } else if cal.isDate(endDay, inSameDayAs: cal.date(byAdding: .day, value: 1, to: lastDay) ?? endDay) {
                streaks.currentStreak += 1
            } else {
                streaks.currentStreak = 1
            }
        } else {
            streaks.currentStreak = 1
        }
        streaks.lastSessionDate = endDay
        streaks.bestStreak = max(streaks.bestStreak, streaks.currentStreak)
        try? storage.save(streaks, forKey: UDKeys.meditationStreaks)
    }
}
