import SwiftUI

struct FastingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = FastingViewModel()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 24) {
                if viewModel.isActive {
                    Text(TimeFormatter.hms(viewModel.liveElapsed(now: context.date)))
                        .font(.system(size: 48, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .padding(.top)

                    Button {
                        viewModel.stopFast()
                    } label: {
                        Label("Stop Fast", systemImage: "stop.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        viewModel.startFast()
                    } label: {
                        Label("Start Fast", systemImage: "play.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }

                Divider()

                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stats").font(.headline)
                    statRow(title: "Last", value: formattedDuration(viewModel.lastFast?.duration))
                    statRow(title: "Longest", value: formattedDuration(viewModel.longestFast?.duration))
                    statRow(title: "7‑day Avg", value: formattedDuration(viewModel.sevenDayAverage))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // History link
                NavigationLink {
                    FastHistoryView(items: viewModel.history)
                } label: {
                    Label("View History", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
            .navigationTitle("Fast")
            .accessibilityLabel("Fasting Home")
        }
    }

    private func statRow(title: String, value: String?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "—")
        }
    }

    private func formattedDuration(_ seconds: TimeInterval?) -> String? {
        guard let seconds else { return nil }
        return TimeFormatter.hms(seconds)
    }
}

#Preview {
    NavigationStack { FastingView() }
}
