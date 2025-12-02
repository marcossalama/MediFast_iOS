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
    private var lastTickAt: Date? = nil

    // Stats
    @Published private(set) var currentStreakDays: Int = 0
    @Published private(set) var sessionsThisMonth: Int = 0
    @Published private(set) var sessionsThisYear: Int = 0
    @Published private(set) var totalMinutesMeditated: Double = 0
    @Published private(set) var totalSessionsCount: Int = 0

    // Derived helpers
    var warmupSeconds: Int? { plan.warmupSeconds }
    var totalSessions: Int { max(1, plan.sessionsMinutes.count) }
    var currentSessionNumber: Int { min(currentIndex + 1, totalSessions) }
    var sessionMinutes: Int { plan.sessionsMinutes.indices.contains(currentIndex) ? plan.sessionsMinutes[currentIndex] : (plan.sessionsMinutes.last ?? 10) }
    private var isTestMode: Bool = false
    var sessionDuration: TimeInterval {
        let minutes = sessionMinutes
        // In test mode, interpret minutes as seconds
        return isTestMode ? TimeInterval(max(1, minutes)) : TimeInterval(max(1, minutes)) * 60
    }
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
        refreshStats()
    }

    // MARK: - Intents
    func start(minutes: Int, warmupSeconds: Int?) {
        // Backwards-compat entrypoint: create a one-session plan
        let plan = MeditationPlan(
            sessionsMinutes: [minutes],
            warmupSeconds: warmupSeconds
        )
        try? storage.save(plan, forKey: UDKeys.meditationPlan)
        startPlan(plan)
    }

    func startPlan(_ plan: MeditationPlan, isTestMode: Bool = false) {
        self.plan = plan
        self.isTestMode = isTestMode
        try? storage.save(plan, forKey: UDKeys.meditationPlan)
        currentIndex = 0
        elapsedInCurrent = 0
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

        // Optional feedback after each session (including final)
        if plan.vibrateAfterSession { Haptics.vibrate(duration: 3.0) }
        if plan.dingAfterSession { AudioPlayer.shared.play(named: Sounds.bellMid) }

        let next = currentIndex + 1
        if next < totalSessions {
            beginSession(index: next, playStartBell: false, startedAt: end)
        } else {
            state = .completed
            AudioPlayer.shared.play(named: Sounds.bellEnd)
            lastTickAt = nil
        }
    }

    // MARK: - Persistence
    private func persist(session: MeditationSession) {
        var sessions: [MeditationSession] = (try? storage.load([MeditationSession].self, forKey: UDKeys.meditationSessions)) ?? []
        sessions.append(session)
        if sessions.count > 500 { sessions.removeFirst(sessions.count - 500) }
        try? storage.save(sessions, forKey: UDKeys.meditationSessions)
        refreshStats()
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
        refreshStats()
    }

    // MARK: - Stats
    func refreshStats() {
        let sessions = loadAllSessions()
        let calendar = Calendar.current
        let now = Date()
        
        // Current streak
        let streaks: StreaksState = (try? storage.load(StreaksState.self, forKey: UDKeys.meditationStreaks)) ?? StreaksState(lastSessionDate: nil, currentStreak: 0, bestStreak: 0)
        currentStreakDays = streaks.currentStreak
        
        // Sessions this month
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        sessionsThisMonth = sessions.filter { session in
            let sessionMonth = calendar.component(.month, from: session.startAt)
            let sessionYear = calendar.component(.year, from: session.startAt)
            return sessionMonth == currentMonth && sessionYear == currentYear
        }.count
        
        // Sessions this year
        sessionsThisYear = sessions.filter { session in
            let sessionYear = calendar.component(.year, from: session.startAt)
            return sessionYear == currentYear
        }.count
        
        // Total minutes meditated
        let totalSeconds = sessions.reduce(0.0) { $0 + $1.duration }
        totalMinutesMeditated = totalSeconds / 60.0
        
        // Total sessions count
        totalSessionsCount = sessions.count
    }
    
    private func loadAllSessions() -> [MeditationSession] {
        (try? storage.load([MeditationSession].self, forKey: UDKeys.meditationSessions)) ?? []
    }
    
    // MARK: - Session Management
    func getAllSessions() -> [MeditationSession] {
        loadAllSessions()
    }
    
    func deleteSession(_ session: MeditationSession) {
        var sessions = loadAllSessions()
        sessions.removeAll(where: { $0.id == session.id })
        try? storage.save(sessions, forKey: UDKeys.meditationSessions)
        recalculateStreaks(from: sessions)
        refreshStats()
    }
    
    private func recalculateStreaks(from sessions: [MeditationSession]) {
        guard !sessions.isEmpty else {
            let emptyStreaks = StreaksState(lastSessionDate: nil, currentStreak: 0, bestStreak: 0)
            try? storage.save(emptyStreaks, forKey: UDKeys.meditationStreaks)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Get unique days with sessions, sorted newest first
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.startAt) })
            .sorted(by: >)
        
        guard let mostRecentDay = sessionDays.first else {
            let emptyStreaks = StreaksState(lastSessionDate: nil, currentStreak: 0, bestStreak: 0)
            try? storage.save(emptyStreaks, forKey: UDKeys.meditationStreaks)
            return
        }
        
        // Calculate current streak: consecutive days from most recent backwards
        // Only count if most recent session was today or yesterday (active streak)
        var currentStreak = 0
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        
        if calendar.isDate(mostRecentDay, inSameDayAs: today) || 
           calendar.isDate(mostRecentDay, inSameDayAs: yesterday) {
            currentStreak = 1
            var checkDay = calendar.date(byAdding: .day, value: -1, to: mostRecentDay) ?? mostRecentDay
            for day in sessionDays.dropFirst() {
                if calendar.isDate(day, inSameDayAs: checkDay) {
                    currentStreak += 1
                    guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
                    checkDay = prev
                } else {
                    break
                }
            }
        }
        
        // Calculate best streak: find longest consecutive sequence
        var bestStreak = 1
        var tempStreak = 1
        var expectedDay = sessionDays.first!
        
        for day in sessionDays.dropFirst() {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDay) else {
                expectedDay = day
                tempStreak = 1
                continue
            }
            
            if calendar.isDate(day, inSameDayAs: previousDay) {
                tempStreak += 1
                bestStreak = max(bestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
            expectedDay = day
        }
        
        let streaks = StreaksState(
            lastSessionDate: mostRecentDay,
            currentStreak: currentStreak,
            bestStreak: max(bestStreak, currentStreak)
        )
        try? storage.save(streaks, forKey: UDKeys.meditationStreaks)
    }
}
