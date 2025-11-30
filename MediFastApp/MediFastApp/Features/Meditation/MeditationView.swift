import SwiftUI

private struct SessionRow: Identifiable, Equatable {
    let id: UUID
    var minutes: Int
}

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var rows: [SessionRow] = [SessionRow(id: UUID(), minutes: 10)]
    @State private var warmup: Int = 0
    @State private var goFocus: Bool = false
    @State private var vibrateAfterSession: Bool = false
    @State private var dingAfterSession: Bool = false
    @State private var testMode: Bool = false
    private let storage: StorageProtocol = UserDefaultsStorage()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sessions").sectionStyle().cardPadding()
                Card {
                    VStack(spacing: 12) {
                        ForEach($rows) { $row in
                            let idx = rows.firstIndex(where: { $0.id == row.id }) ?? 0
                            HStack {
                                Text("Session \(idx + 1): \(row.minutes) \(testMode ? "sec" : "min")")
                                Spacer()
                                HStack(spacing: 8) {
                                    Button { row.minutes = max(1, row.minutes - 1); Haptics.impact(.light) } label: { Image(systemName: "minus") }
                                        .buttonStyle(IconPillButtonStyle())
                                    Button { row.minutes = min(59, row.minutes + 1); Haptics.impact(.light) } label: { Image(systemName: "plus") }
                                        .buttonStyle(IconPillButtonStyle())
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            if row.id != rows.last?.id { Divider() }
                        }
                        HStack {
                            Button {
                                guard rows.count < 9 else { return }
                                let next = min(59, max(1, rows.last?.minutes ?? (testMode ? 5 : 10)))
                                rows.append(SessionRow(id: UUID(), minutes: next))
                                Haptics.impact(.soft)
                            } label: { Label("Add Session", systemImage: "plus") }
                                .buttonStyle(IconPillButtonStyle())
                                .disabled(rows.count >= 9)
                            Spacer()
                            Button(role: .destructive) {
                                guard rows.count > 1 else { return }
                                _ = rows.removeLast()
                                Haptics.impact(.rigid)
                            } label: { Label("Remove Last", systemImage: "minus") }
                                .buttonStyle(IconPillButtonStyle())
                                .disabled(rows.count <= 1)
                        }
                    }
                }
                .cardPadding()

                Text("Cues & Feedback").sectionStyle().cardPadding()
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $testMode) {
                            Label("Test sound and vibration", systemImage: "flask")
                        }
                        .onChange(of: testMode) { _, enabled in
                            if enabled {
                                // Reset to test-friendly defaults
                                rows = [SessionRow(id: UUID(), minutes: 5)]
                                warmup = 0
                                vibrateAfterSession = true
                                dingAfterSession = true
                            } else {
                                // Reset to normal defaults
                                rows = [SessionRow(id: UUID(), minutes: 10)]
                            }
                            Haptics.impact(.light)
                        }
                        Divider()
                        Toggle(isOn: $vibrateAfterSession) {
                            Label("Vibrate after session", systemImage: "waveform")
                        }
                        Toggle(isOn: $dingAfterSession) {
                            Label("Ding after session", systemImage: "bell")
                        }
                        Divider()
                        Stepper(
                            "Warm-up: \(warmup) s",
                            value: $warmup,
                            in: 0...15,
                            step: 5
                        )
                        .accessibilityLabel("Warm-up \(warmup) seconds")
                    }
                }
                .cardPadding()

                Text("History").sectionStyle().cardPadding()
                Card {
                    VStack(spacing: 16) {
                        // Top row: Streak and This Month
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "flame.fill",
                                title: "Current Streak",
                                value: "\(viewModel.currentStreakDays)",
                                subtitle: viewModel.currentStreakDays == 1 ? "day" : "days",
                                color: .orange
                            )
                            StatCard(
                                icon: "calendar",
                                title: "This Month",
                                value: "\(viewModel.sessionsThisMonth)",
                                subtitle: viewModel.sessionsThisMonth == 1 ? "session" : "sessions",
                                color: Theme.primary
                            )
                        }
                        
                        // Middle row: This Year and Total Time
                        HStack(spacing: 12) {
                            StatCard(
                                icon: "chart.bar.fill",
                                title: "This Year",
                                value: "\(viewModel.sessionsThisYear)",
                                subtitle: viewModel.sessionsThisYear == 1 ? "session" : "sessions",
                                color: Theme.primary
                            )
                            StatCard(
                                icon: "clock.fill",
                                title: "Total Time",
                                value: formatMinutes(viewModel.totalMinutesMeditated),
                                subtitle: "",
                                color: Theme.primary
                            )
                        }
                        
                        // Bottom: Total Sessions (full width)
                        StatCard(
                            icon: "list.bullet",
                            title: "Total Sessions",
                            value: "\(viewModel.totalSessionsCount)",
                            subtitle: viewModel.totalSessionsCount == 1 ? "session" : "sessions",
                            color: Theme.primary,
                            isFullWidth: true
                        )
                    }
                }
                .cardPadding()

                Color.clear.frame(height: 80)
            }
            .padding(.top, 8)
        }
        .background(Theme.background)
        .navigationTitle("Meditate")
        .navigationDestination(isPresented: $goFocus) {
            FocusModeView().environmentObject(viewModel)
        }
        .onAppear {
            if let plan: MeditationPlan = try? storage.load(MeditationPlan.self, forKey: UDKeys.meditationPlan) {
                let mins = plan.sessionsMinutes.isEmpty ? [10] : plan.sessionsMinutes
                rows = mins.map { SessionRow(id: UUID(), minutes: min(59, max(1, $0))) }
                warmup = min(15, max(0, plan.warmupSeconds ?? 0))
                vibrateAfterSession = plan.vibrateAfterSession
                dingAfterSession = plan.dingAfterSession
            } else {
                rows = [SessionRow(id: UUID(), minutes: max(1, viewModel.selectedMinutes))]
                warmup = min(15, max(0, viewModel.warmupSeconds ?? 0))
            }
            viewModel.refreshStats()
        }
        .accessibilityLabel("Meditation Home")
        .onChange(of: warmup, initial: false) { _, _ in
            // Provide light feedback when adjusting warm-up length.
            Haptics.impact(.light)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    let plan = MeditationPlan(
                        sessionsMinutes: rows.map { $0.minutes },
                        warmupSeconds: warmup == 0 ? nil : warmup,
                        vibrateAfterSession: vibrateAfterSession,
                        dingAfterSession: dingAfterSession
                    )
                    try? storage.save(plan, forKey: UDKeys.meditationPlan)
                    viewModel.startPlan(plan, isTestMode: testMode)
                    goFocus = true
                } label: {
                    Text(testMode ? "Start Test" : "Start").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel(testMode ? "Start Test Meditation" : "Start Meditation")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview { NavigationStack { MeditationView() } }

// MARK: - Stat Card Component
private struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    var isFullWidth: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Formatting Helper
private func formatMinutes(_ minutes: Double) -> String {
    let totalMinutes = Int(minutes.rounded())
    if totalMinutes >= 60 {
        let hours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }
    return "\(totalMinutes)"
}
