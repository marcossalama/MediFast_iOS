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

    private var midpointEnabledBinding: Binding<Bool> {
        Binding(
            get: { midpointInterval != nil },
            set: { isOn in
                if isOn {
                    let current = midpointInterval ?? 5
                    midpointInterval = min(59, max(1, current))
                } else {
                    midpointInterval = nil
                }
            }
        )
    }

    private var midpointIntervalStepperBinding: Binding<Int> {
        Binding(
            get: { midpointInterval ?? 5 },
            set: { value in
                midpointInterval = min(59, max(1, value))
            }
        )
    }

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

                Text("Cues & Feedback").sectionStyle().cardPadding()
                Card {
                    VStack(alignment: .leading, spacing: 16) {
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
                        Divider()
                        Toggle(isOn: midpointEnabledBinding) {
                            Label("Midpoint bell", systemImage: "bell.badge")
                        }
                        if midpointInterval != nil {
                            Stepper(
                                "Every \(midpointInterval ?? 5) min",
                                value: midpointIntervalStepperBinding,
                                in: 1...59
                            )
                            .accessibilityLabel("Midpoint bell every \(midpointInterval ?? 5) minutes")
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
                warmup = min(15, max(0, plan.warmupSeconds ?? 0))
                vibrateAfterSession = plan.vibrateAfterSession
                dingAfterSession = plan.dingAfterSession
                midpointInterval = plan.midpointIntervalMinutes.map { min(59, max(1, $0)) }
            } else {
                rows = [SessionRow(id: UUID(), minutes: max(1, viewModel.selectedMinutes))]
                warmup = min(15, max(0, viewModel.warmupSeconds ?? 0))
                midpointInterval = viewModel.plan.midpointIntervalMinutes.map { min(59, max(1, $0)) }
            }
        }
        .accessibilityLabel("Meditation Home")
        .onChange(of: warmup, initial: false) { _, _ in
            // Provide light feedback when adjusting warm-up length.
            Haptics.impact(.light)
        }
        .onChange(of: midpointInterval, initial: false) { _, _ in
            Haptics.impact(.light)
        }
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
