import SwiftUI

struct FastingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = FastingViewModel()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack { Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Timer").sectionStyle().cardPadding()
                        Card {
                            VStack(spacing: 16) {
                                Text(viewModel.isActive ? TimeFormatter.hms(viewModel.liveElapsed(now: context.date)) : "00:00:00")
                                    .font(Theme.Typography.numeric)
                                    .frame(maxWidth: .infinity)
                                if viewModel.isActive {
                                    Button { viewModel.stopFast(); Haptics.notify(.success) } label: { Text("Stop Fast").frame(maxWidth: .infinity) }
                                        .buttonStyle(PrimaryButtonStyle())
                                } else {
                                    Button { viewModel.startFast(); Haptics.impact(.medium) } label: { Text("Start Fast").frame(maxWidth: .infinity) }
                                        .buttonStyle(PrimaryButtonStyle())
                                }
                            }
                        }.cardPadding()

                        Text("Stats").sectionStyle().cardPadding()
                        Card {
                            VStack(alignment: .leading, spacing: 10) {
                                statRow(title: "Last", value: formattedDuration(viewModel.lastFast?.duration))
                                Divider()
                                statRow(title: "Longest", value: formattedDuration(viewModel.longestFast?.duration))
                                Divider()
                                statRow(title: "7‑day Avg", value: formattedDuration(viewModel.sevenDayAverage))
                            }
                        }.cardPadding()

                        Text("History").sectionStyle().cardPadding()
                        Card {
                            NavigationLink { FastHistoryView(items: viewModel.history) } label: {
                                HStack { Label("View History", systemImage: "list.bullet"); Spacer(); Image(systemName: "chevron.right").foregroundStyle(.secondary) }
                            }
                        }.cardPadding()

                        Color.clear.frame(height: 20)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Fast")
            .accessibilityLabel("Fasting Home")
        }
    }

    private func statRow(title: String, value: String?) -> some View {
        HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value ?? "—") }
    }

    private func formattedDuration(_ seconds: TimeInterval?) -> String? {
        guard let seconds else { return nil }
        return TimeFormatter.hms(seconds)
    }
}

#Preview { NavigationStack { FastingView() } }
