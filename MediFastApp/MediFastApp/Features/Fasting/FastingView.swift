import SwiftUI

struct FastingView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = FastingViewModel()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack { Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Timer").sectionStyle().cardPadding()
                        Card {
                            VStack(spacing: 16) {
                                Text(viewModel.isActive ? TimeFormatter.hms(viewModel.liveElapsed(now: context.date)) : "00:00:00")
                                    .font(Theme.Typography.numeric)
                                    .frame(maxWidth: .infinity)
                                if viewModel.isActive {
                                    Button { viewModel.stopFast() } label: { Text("Stop Fast").frame(maxWidth: .infinity) }
                                        .buttonStyle(PrimaryButtonStyle())
                                } else {
                                    Button { viewModel.startFast() } label: { Text("Start Fast").frame(maxWidth: .infinity) }
                                        .buttonStyle(PrimaryButtonStyle())
                                }
                            }
                        }.cardPadding()

                        Text("History").sectionStyle().cardPadding()
                        Card {
                            VStack(alignment: .leading, spacing: 12) {
                                if fullHistory.isEmpty {
                                    HistoryEmptyState()
                                } else {
                                    ForEach(fullHistory) { fast in
                                        HistoryRow(fast: fast, onDelete: {
                                            withAnimation {
                                                viewModel.deleteFast(fast)
                                            }
                                        })
                                        .swipeActions(allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    viewModel.deleteFast(fast)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                        if fast.id != fullHistory.last?.id {
                                            Divider()
                                        }
                                    }
                                    NavigationLink {
                                        FastHistoryView(items: fullHistory, onDelete: { fast in
                                            withAnimation {
                                                viewModel.deleteFast(fast)
                                            }
                                        })
                                    } label: {
                                        HStack {
                                            Text("See detailed history")
                                            Spacer()
                                            Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                        }
                                        .font(.subheadline.weight(.semibold))
                                    }
                                }
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

    private var fullHistory: [Fast] { viewModel.history }
}

#Preview { NavigationStack { FastingView() } }

private struct HistoryRow: View {
    var fast: Fast
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(fast.startAt.formatted(date: .abbreviated, time: .shortened))
                Spacer()
                if let duration = fast.duration {
                    Text(TimeFormatter.hms(duration))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            if let end = fast.endAt {
                Text("Ended \(end.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Fast", systemImage: "trash")
                }
            }
        }
    }
}

private struct HistoryEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.questionmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No fasts yet")
                .font(.headline)
            Text("Start a fast to see stats, streaks, and history summaries here.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}
