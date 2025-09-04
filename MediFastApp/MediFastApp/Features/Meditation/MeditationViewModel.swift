import Foundation
import SwiftUI

/// ViewModel for the Meditation feature: foreground-only ticking, midpoint/end triggers, local persistence.
@MainActor
final class MeditationViewModel: ObservableObject {
    enum State { case idle, warmup, running, pausedDueToBackground, completed }

    // MARK: - Inputs / Settings
    @Published var selectedMinutes: Int = 10
    @Published var midpointInterval: Int? = nil // minutes (every N minutes)
    @Published var warmupSeconds: Int? = nil    // optional warm-up

    // MARK: - Runtime State
    @Published private(set) var state: State = .idle
    @Published private(set) var startAt: Date? = nil
    @Published private(set) var elapsed: TimeInterval = 0 // total elapsed including warmup

    // Track which midpoint marks have fired (minute offsets from main session start)
    private(set) var firedMidpoints: Set<Int> = []

    // Derived
    var totalDuration: TimeInterval { TimeInterval(max(0, selectedMinutes)) * 60 + TimeInterval(warmupSeconds ?? 0) }
    var mainDuration: TimeInterval { TimeInterval(max(0, selectedMinutes)) * 60 }
    var warmupDuration: TimeInterval { TimeInterval(warmupSeconds ?? 0) }
    var progress: Double { totalDuration > 0 ? min(1.0, elapsed / totalDuration) : 0 }

    // Storage (injected)
    private let storage: StorageProtocol

    init(storage: StorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        // Attempt to load saved settings as defaults
        if let saved: MeditationSettings = try? storage.load(MeditationSettings.self, forKey: UDKeys.meditationSettings) {
            self.selectedMinutes = saved.presetMinutes
            self.midpointInterval = saved.midpointInterval
            self.warmupSeconds = saved.warmupSeconds
        }
    }

    // MARK: - Intents
    func start(minutes: Int, warmupSeconds: Int?, midpointInterval: Int?) {
        selectedMinutes = minutes
        self.warmupSeconds = warmupSeconds
        self.midpointInterval = midpointInterval
        // Persist settings for next launch
        let settings = MeditationSettings(presetMinutes: minutes, midpointInterval: midpointInterval, warmupSeconds: warmupSeconds)
        try? storage.save(settings, forKey: UDKeys.meditationSettings)

        state = (warmupSeconds ?? 0) > 0 ? .warmup : .running
        startAt = Date()
        elapsed = 0
        firedMidpoints.removeAll()
    }

    func cancel() {
        state = .idle
        startAt = nil
        elapsed = 0
        firedMidpoints.removeAll()
    }

    /// Advance the timer by one tick when app is active. No background accumulation.
    func tick(isActive: Bool) {
        guard isActive else {
            if state == .running || state == .warmup { state = .pausedDueToBackground }
            return
        }
        if state == .pausedDueToBackground { state = warmupRemaining > 0 ? .warmup : .running }
        guard state == .warmup || state == .running else { return }

        elapsed += 1

        // Handle warmup completion transition
        if state == .warmup && warmupRemaining <= 0 {
            state = .running
            // Start bell at main session start
            Haptics.impact(.light)
            AudioPlayer.shared.play(named: Sounds.bellStart)
        }

        // Midpoint bells during running
        if state == .running, let intervalMin = midpointInterval, intervalMin > 0 {
            let mainElapsed = max(0, Int(elapsed - warmupDuration))
            let mark = (mainElapsed / 60)
            if mark > 0, mark % intervalMin == 0, !firedMidpoints.contains(mark) {
                firedMidpoints.insert(mark)
                Haptics.impact(.soft)
                AudioPlayer.shared.play(named: Sounds.bellMid)
            }
        }

        // Completion
        if elapsed >= totalDuration {
            finishSession()
        }
    }

    private var warmupRemaining: Int { max(0, Int(warmupDuration - elapsed)) }

    private func finishSession() {
        state = .completed
        let end = Date()
        let start = startAt ?? end
        let session = MeditationSession(id: UUID(), startAt: start, endAt: end, duration: mainDuration)
        persist(session: session)
        updateStreaks(for: end)
        Haptics.notify(.success)
        AudioPlayer.shared.play(named: Sounds.bellEnd)
    }

    // MARK: - Persistence
    private func persist(session: MeditationSession) {
        var sessions: [MeditationSession] = (try? storage.load([MeditationSession].self, forKey: UDKeys.meditationSessions)) ?? []
        sessions.append(session)
        // Keep most recent 500 to avoid bloat
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
