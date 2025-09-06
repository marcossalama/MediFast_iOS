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
        VStack(spacing: 24) {
                HStack {
                    Text("Round \(viewModel.currentRound)/\(viewModel.settings.rounds)")
                        .font(.headline)
                    Spacer()
                    Button("Finish") { viewModel.finishEarly(); showResults = true }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Text(viewModel.phase.title)
                    .font(.title2)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 240, height: 240)
                        .scaleEffect(viewModel.phase == .breathing ? (viewModel.breathPhase == .inhale ? 1.04 : 0.98) : 1.0)
                        .animation(.easeInOut(duration: 0.9), value: viewModel.breathPhase)
                    Text(viewModel.displayValue)
                        .font(.system(size: 56, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }

                if viewModel.phase == .breathing {
                    Text(viewModel.breathPhase == .inhale ? "Inhale" : "Exhale")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                        .id(viewModel.breathPhase == .inhale ? "inhale" : "exhale")
                }

                Text(instruction)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) { viewModel.handleSingleTap() }
        .onTapGesture(count: 2) { viewModel.handleDoubleTap() }
        .onReceive(timer) { _ in
            viewModel.tick(isActive: scenePhase == .active)
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if newPhase == .completed { showResults = true }
        }
        .navigationDestination(isPresented: $showResults) {
            BreathingResultsView(onDone: {
                exitToSetup = true
                showResults = false
            })
            .environmentObject(viewModel)
        }
        .onChange(of: showResults) { _, isShown in
            if !isShown && exitToSetup {
                exitToSetup = false
                dismiss()
            }
        }
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
