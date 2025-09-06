import SwiftUI

/// Full-screen focus mode with minimal progress and large timer.
struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: MeditationViewModel
    @State private var hasPlayedStart = false

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    // Session indicator
                    if viewModel.state == .running || viewModel.state == .warmup {
                        Text("Session \(viewModel.currentSessionNumber)/\(viewModel.totalSessions)")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    // Progress
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(.linear)
                        .tint(.white.opacity(0.8))
                        .padding(.horizontal)

                    // Time remaining
                    Text(timeDisplay)
                        .font(.system(size: 56, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Button {
                        viewModel.cancel()
                        dismiss()
                    } label: {
                        Text("Exit")
                            .font(.title3)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // ticks only when active; we still set explicit paused state
                if newPhase != .active {
                    // mark paused
                    viewModel.tick(isActive: false)
                }
            }
            .onAppear { setIdleDisabled(true) }
            .onDisappear { setIdleDisabled(false) }
            .task(id: context.date) {
                viewModel.tick(isActive: scenePhase == .active)
            }
            .accessibilityLabel("Meditation Focus Mode")
            .contentShape(Rectangle())
            .onTapGesture {
                // tap anywhere to exit focus mode
                viewModel.cancel()
                dismiss()
            }
        }
    }

    private var timeDisplay: String {
        let remaining = max(0, viewModel.remainingSeconds)
        let hrs = remaining / 3600
        let mins = (remaining % 3600) / 60
        let secs = remaining % 60
        if hrs > 0 { return String(format: "%02d:%02d:%02d", hrs, mins, secs) }
        return String(format: "%02d:%02d", mins, secs)
    }

    private func setIdleDisabled(_ disabled: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }
}

#Preview {
    FocusModeView()
        .environmentObject(MeditationViewModel())
}
