import SwiftUI

/// Shows per-round retention times and simple stats for a completed session.
struct BreathingResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: BreathingViewModel

    private var durations: [TimeInterval] { viewModel.results.map { $0.retentionSeconds } }
    private var best: TimeInterval? { durations.max() }
    private var average: TimeInterval? {
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }
    private var total: TimeInterval? {
        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Session Summary")
                .font(.title2)

            if viewModel.results.isEmpty {
                ContentUnavailableView("No data", systemImage: "wind", description: Text("No rounds recorded."))
            } else {
                // Stats
                VStack(spacing: 8) {
                    statRow("Best", value: best)
                    statRow("Average", value: average)
                    statRow("Total", value: total)
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))

                // Per-round list
                List(viewModel.results) { item in
                    HStack {
                        Text("Round \(item.round)")
                        Spacer()
                        Text("Breaths: \(item.breaths)")
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 12)
                        Text(TimeFormatter.ms(item.retentionSeconds))
                            .monospacedDigit()
                    }
                    .accessibilityLabel("Round \(item.round), breaths \(item.breaths), retention \(TimeFormatter.ms(item.retentionSeconds))")
                }
                .listStyle(.insetGrouped)
            }

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear { Haptics.notify(.success) }
    }

    private func statRow(_ title: String, value: TimeInterval?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value.map(TimeFormatter.ms) ?? "—")
                .monospacedDigit()
        }
        .accessibilityLabel("\(title): \(value.map(TimeFormatter.ms) ?? "none")")
    }
}

#Preview {
    let vm = BreathingViewModel(settings: .init(rounds: 3, breathsPerRound: 30, recoveryHoldSeconds: 15))
    vm.handleSingleTap(); vm.handleSingleTap();
    return NavigationStack { BreathingResultsView().environmentObject(vm) }
}

