import Foundation
import SwiftUI

/// ViewModel for the Fasting feature: start/stop, history persistence, simple stats.
@MainActor
final class FastingViewModel: ObservableObject {
    // Active fast (nil when not fasting)
    @Published private(set) var activeFast: Fast? = nil

    // Local history of completed fasts (newest first)
    @Published private(set) var history: [Fast] = []

    // Storage (injected)
    private let storage: StorageProtocol

    init(storage: StorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        loadFromStorage()
    }

    // MARK: - Public Computed
    var isActive: Bool { activeFast != nil }

    /// Live elapsed for the active fast (seconds). 0 when inactive.
    func liveElapsed(now: Date = Date()) -> TimeInterval {
        guard let start = activeFast?.startAt else { return 0 }
        return max(0, now.timeIntervalSince(start))
    }

    /// Last completed fast (most recent in history).
    var lastFast: Fast? { history.first }

    /// Longest completed fast by duration.
    var longestFast: Fast? {
        history.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) })
    }

    /// Three most recent completed fasts.
    var lastThreeFasts: [Fast] {
        Array(history.prefix(3))
    }

    /// 7-day average duration (seconds) of completed fasts.
    var sevenDayAverage: TimeInterval? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-7*86400)
        let recent = history.filter { ($0.endAt ?? Date.distantPast) >= cutoff }
        guard !recent.isEmpty else { return nil }
        let total = recent.reduce(0.0) { $0 + ($1.duration ?? 0) }
        return total / Double(recent.count)
    }

    /// Overall average fast duration (seconds).
    var overallAverage: TimeInterval? {
        guard !history.isEmpty else { return nil }
        let total = history.reduce(0.0) { $0 + ($1.duration ?? 0) }
        return total / Double(history.count)
    }

    /// Total number of completed fasts.
    var completedFastCount: Int { history.count }

    /// Consecutive days with a completed fast counting backwards from the most recent entry.
    var currentStreakDays: Int {
        guard !history.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var lastDay: Date? = nil

        for fast in history {
            guard let end = fast.endAt else { continue }
            let day = calendar.startOfDay(for: end)

            if let prevDay = lastDay {
                if calendar.isDate(day, inSameDayAs: prevDay) {
                    // Multiple fasts on the same day; ignore duplicates.
                    continue
                }
                if let expected = calendar.date(byAdding: .day, value: -1, to: prevDay),
                   calendar.isDate(day, inSameDayAs: expected) {
                    streak += 1
                    lastDay = day
                } else {
                    break
                }
            } else {
                streak = 1
                lastDay = day
            }
        }

        return streak
    }

    /// Returns up to the requested number of most recent completed fasts.
    func recentHistory(limit: Int) -> [Fast] {
        guard limit > 0 else { return [] }
        return Array(history.prefix(limit))
    }

    /// Returns completed fasts whose duration meets the provided minimum (seconds). `nil` returns all.
    func filteredHistory(minDuration: TimeInterval?) -> [Fast] {
        guard let minDuration else { return history }
        return history.filter { ($0.duration ?? 0) >= minDuration }
    }

    /// Durations (seconds) of the last N completed fasts, ignoring missing durations.
    func recentDurations(count: Int) -> [TimeInterval] {
        guard count > 0 else { return [] }
        return history.prefix(count).compactMap { $0.duration }
    }

    // MARK: - Intents
    func startFast() {
        guard activeFast == nil else { return }
        let fast = Fast(id: UUID(), startAt: Date(), endAt: nil, duration: nil)
        activeFast = fast
        persistActive()
        Haptics.impact(.medium)
    }

    func stopFast() {
        guard var current = activeFast else { return }
        let end = Date()
        current.endAt = end
        current.duration = max(0, end.timeIntervalSince(current.startAt))
        activeFast = nil
        history.insert(current, at: 0)
        // Keep the most recent 500 entries to limit UD size
        if history.count > 500 { history.removeLast(history.count - 500) }
        persistHistory()
        clearActive()
        Haptics.notify(.success)
    }

    func clearHistory() {
        history.removeAll()
        persistHistory()
    }

    func deleteFast(_ fast: Fast) {
        let original = history.count
        history.removeAll(where: { $0.id == fast.id })
        guard history.count != original else { return }
        persistHistory()
    }

    func removeFasts(at offsets: IndexSet) {
        let items = offsets.compactMap { $0 < history.count ? history[$0] : nil }
        items.forEach { deleteFast($0) }
    }

    // MARK: - Persistence
    private func loadFromStorage() {
        if let active: Fast = try? storage.load(Fast.self, forKey: UDKeys.fastingActive) {
            self.activeFast = active
        }
        if let list: [Fast] = try? storage.load([Fast].self, forKey: UDKeys.fastingHistory) {
            self.history = list
        }
    }

    private func persistActive() {
        if let activeFast { try? storage.save(activeFast, forKey: UDKeys.fastingActive) }
    }

    private func clearActive() { storage.remove(forKey: UDKeys.fastingActive) }

    private func persistHistory() { try? storage.save(history, forKey: UDKeys.fastingHistory) }
}
