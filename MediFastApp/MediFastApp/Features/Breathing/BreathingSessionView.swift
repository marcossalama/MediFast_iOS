import SwiftUI

/// Session screen for guided breathing. Foreground-only timing with simple, sober UI.
struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: BreathingViewModel

    @State private var showResults = false
    @State private var exitToSetup = false
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 20) {
                HStack {
                    Text("Round \(viewModel.currentRound)/\(viewModel.settings.rounds)")
                        .font(.headline)
                    Spacer()
                    Button { viewModel.finishEarly(); showResults = true } label: { Text("Finish") }
                        .buttonStyle(IconPillButtonStyle())
                }
                .padding(.horizontal)

                Text(viewModel.phase.title)
                    .font(Theme.Typography.title)

                Card {
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.surface)
                            .frame(height: 240)
                            .scaleEffect(viewModel.phase == .breathing ? (viewModel.breathPhase == .inhale ? 1.03 : 0.97) : 1.0)
                            .animation(.easeInOut(duration: 0.9), value: viewModel.breathPhase)
                            .overlay(
                                Text(viewModel.displayValue)
                                    .font(Theme.Typography.numeric)
                            )

                        if viewModel.phase == .breathing {
                            Text(viewModel.breathPhase == .inhale ? "Inhale" : "Exhale")
                                .foregroundStyle(Theme.textSecondary)
                                .transition(.opacity)
                                .id(viewModel.breathPhase == .inhale ? "inhale" : "exhale")
                        }
                    }
                }
                .cardPadding()

                Text(instruction)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) { viewModel.handleSingleTap() }
        .onTapGesture(count: 2) { viewModel.handleDoubleTap() }
        .onReceive(timer) { _ in viewModel.tick(isActive: scenePhase == .active) }
        .onChange(of: viewModel.phase) { _, newPhase in if newPhase == .completed { showResults = true } }
        .navigationDestination(isPresented: $showResults) {
            BreathingResultsView(onDone: { exitToSetup = true; showResults = false }).environmentObject(viewModel)
        }
        .onChange(of: showResults) { _, isShown in if !isShown && exitToSetup { exitToSetup = false; dismiss() } }
    }

    private var instruction: String {
        switch viewModel.phase {
        case .breathing: return "Prompts follow pace (\(viewModel.settings.paceSeconds)s). Double‑tap to hold."
        case .retention: return "Double‑tap for recovery breath."
        case .recovery: return "Auto‑advance after countdown. Double‑tap to skip."
        case .completed: return "Session completed."
        }
    }
}

#Preview {
    let vm = BreathingViewModel(settings: .init(rounds: 5, breathsPerRound: 30, recoveryHoldSeconds: 15))
    NavigationStack { BreathingSessionView().environmentObject(vm) }
}
