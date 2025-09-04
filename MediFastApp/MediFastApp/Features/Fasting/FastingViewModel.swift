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

    /// 7-day average duration (seconds) of completed fasts.
    var sevenDayAverage: TimeInterval? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-7*86400)
        let recent = history.filter { ($0.endAt ?? Date.distantPast) >= cutoff }
        guard !recent.isEmpty else { return nil }
        let total = recent.reduce(0.0) { $0 + ($1.duration ?? 0) }
        return total / Double(recent.count)
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
