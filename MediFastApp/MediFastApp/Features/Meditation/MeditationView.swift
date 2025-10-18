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
    @State private var midpointInterval: Int? = nil
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
                                Text("Session \(idx + 1): \(row.minutes) min")
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
                                let next = min(59, max(1, rows.last?.minutes ?? 10))
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

                Text("Feedback").sectionStyle().cardPadding()
                Card {
                    Toggle(isOn: $vibrateAfterSession) {
                        Label("Vibrate after session", systemImage: "waveform")
                    }
                    Divider()
                    Toggle(isOn: $dingAfterSession) {
                        Label("Ding after session", systemImage: "bell")
                    }
                }
                .cardPadding()

                Text("Warm-up").sectionStyle().cardPadding()
                Card {
                    HStack {
                        Text("Warm-up: \(warmup) s")
                        Spacer()
                        HStack(spacing: 8) {
                            Button { warmup = max(0, warmup - 5); Haptics.impact(.light) } label: { Image(systemName: "minus") }
                                .buttonStyle(IconPillButtonStyle())
                            Button { warmup = min(15, warmup + 5); Haptics.impact(.light) } label: { Image(systemName: "plus") }
                                .buttonStyle(IconPillButtonStyle())
                        }
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
                warmup = plan.warmupSeconds ?? 0
                vibrateAfterSession = plan.vibrateAfterSession
                dingAfterSession = plan.dingAfterSession
                midpointInterval = plan.midpointIntervalMinutes
            } else {
                rows = [SessionRow(id: UUID(), minutes: max(1, viewModel.selectedMinutes))]
                warmup = viewModel.warmupSeconds ?? 0
                midpointInterval = viewModel.plan.midpointIntervalMinutes
            }
        }
        .accessibilityLabel("Meditation Home")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    let plan = MeditationPlan(
                        sessionsMinutes: rows.map { $0.minutes },
                        warmupSeconds: warmup == 0 ? nil : warmup,
                        midpointIntervalMinutes: midpointInterval,
                        vibrateAfterSession: vibrateAfterSession,
                        dingAfterSession: dingAfterSession
                    )
                    try? storage.save(plan, forKey: UDKeys.meditationPlan)
                    viewModel.startPlan(plan)
                    goFocus = true
                } label: {
                    Text("Start").frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityLabel("Start Meditation")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
    }
}

#Preview { NavigationStack { MeditationView() } }
