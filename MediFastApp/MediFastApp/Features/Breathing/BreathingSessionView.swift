import SwiftUI

/// Session screen for guided breathing. Minimal scaffold: shows phase, round, and a large placeholder value.
struct BreathingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: BreathingViewModel

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Round \(viewModel.currentRound)/\(viewModel.settings.rounds)")
                    .font(.headline)
                Spacer()
                Button("Finish") { dismiss() }
                    .buttonStyle(.bordered)
            }
            .padding(.horizontal)

            Text(viewModel.phase.title)
                .font(.title2)

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 220, height: 220)
                Text(viewModel.displayValue)
                    .font(.system(size: 56, weight: .medium, design: .rounded))
                    .monospacedDigit()
            }

            Text("Tap to count a breath. Double-tap to advance phase.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .contentShape(Rectangle())
        .onTapGesture(count: 1) {
            viewModel.handleSingleTap()
        }
        .onTapGesture(count: 2) {
            viewModel.handleDoubleTap()
        }
    }
}

#Preview {
    let vm = BreathingViewModel(settings: .init(rounds: 5, breathsPerRound: 30, recoveryHoldSeconds: 15))
    return NavigationStack { BreathingSessionView().environmentObject(vm) }
}

