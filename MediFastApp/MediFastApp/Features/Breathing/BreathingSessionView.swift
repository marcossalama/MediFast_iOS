import SwiftUI

/// Session screen for guided breathing. Foreground-only timing with simple, sober UI.
struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: BreathingViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 24) {
                HStack {
                    Text("Round \(viewModel.currentRound)/\(viewModel.settings.rounds)")
                        .font(.headline)
                    Spacer()
                    Button("Finish") {
                        viewModel.finishEarly()
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Text(viewModel.phase.title)
                    .font(.title2)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 240, height: 240)
                    Text(viewModel.displayValue)
                        .font(.system(size: 56, weight: .medium, design: .rounded))
                        .monospacedDigit()
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
            .task(id: context.date) {
                viewModel.tick(isActive: scenePhase == .active)
            }
        }
    }

    private var instruction: String {
        switch viewModel.phase {
        case .breathing: return "Tap to count a breath. Double‑tap to hold."
        case .retention: return "Double‑tap for recovery breath."
        case .recovery: return "Auto‑advance after countdown. Double‑tap to skip."
        case .completed: return "Session completed."
        }
    }
}

#Preview {
    let vm = BreathingViewModel(settings: .init(rounds: 5, breathsPerRound: 30, recoveryHoldSeconds: 15))
    return NavigationStack { BreathingSessionView().environmentObject(vm) }
}
