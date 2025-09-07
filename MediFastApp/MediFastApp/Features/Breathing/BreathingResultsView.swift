import SwiftUI

/// Shows per-round retention times and simple stats for a completed session.
struct BreathingResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: BreathingViewModel
    var onDone: (() -> Void)? = nil

    private var durations: [TimeInterval] { viewModel.results.map { $0.retentionSeconds } }
    private var best: TimeInterval? { durations.max() }
    private var average: TimeInterval? { durations.isEmpty ? nil : durations.reduce(0, +) / Double(durations.count) }
    private var total: TimeInterval? { durations.isEmpty ? nil : durations.reduce(0, +) }

    var body: some View {
        ZStack { Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Session Summary").sectionStyle().cardPadding()

                    if viewModel.results.isEmpty {
                        Card {
                            VStack(spacing: 8) {
                                Image(systemName: "wind").font(.largeTitle).foregroundStyle(.secondary)
                                Text("No rounds recorded.").foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }.cardPadding()
                    } else {
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                statRow("Best", value: best)
                                Divider()
                                statRow("Average", value: average)
                                Divider()
                                statRow("Total", value: total)
                            }
                        }.cardPadding()

                        Text("Rounds").sectionStyle().cardPadding()
                        Card {
                            VStack(spacing: 12) {
                                ForEach(viewModel.results) { item in
                                    HStack {
                                        Text("Round \(item.round)")
                                        Spacer()
                                        Text("Breaths: \(item.breaths)").foregroundStyle(.secondary)
                                        Spacer(minLength: 12)
                                        Text(TimeFormatter.ms(item.retentionSeconds)).monospacedDigit()
                                    }
                                    .accessibilityLabel("Round \(item.round), breaths \(item.breaths), retention \(TimeFormatter.ms(item.retentionSeconds))")
                                    if item.id != viewModel.results.last?.id { Divider() }
                                }
                            }
                        }.cardPadding()
                    }

                    Color.clear.frame(height: 80)
                }
                .padding(.top, 8)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { Haptics.notify(.success) }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button { onDone?(); dismiss() } label: { Text("Done").frame(maxWidth: .infinity) }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
    }

    private func statRow(_ title: String, value: TimeInterval?) -> some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value.map(TimeFormatter.ms) ?? "—").monospacedDigit() }
            .accessibilityLabel("\(title): \(value.map(TimeFormatter.ms) ?? "none")")
    }
}

#Preview {
    let vm = BreathingViewModel(settings: .init(rounds: 3, breathsPerRound: 30, recoveryHoldSeconds: 15))
    NavigationStack { BreathingResultsView().environmentObject(vm) }
}
