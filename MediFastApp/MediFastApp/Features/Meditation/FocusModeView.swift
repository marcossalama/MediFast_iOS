import SwiftUI

/// Full-screen focus mode with gradient, ring progress, and toolbar exit.
struct FocusModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var viewModel: MeditationViewModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                LinearGradient(colors: [Theme.primary.opacity(0.18), Theme.background], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    if viewModel.state == .running || viewModel.state == .warmup {
                        Text("Session \(viewModel.currentSessionNumber)/\(viewModel.totalSessions)")
                            .font(.headline)
                    }

                    ZStack {
                        RingProgress(progress: viewModel.progress, size: 260, lineWidth: 14, tint: Theme.primary, track: Color.secondary.opacity(0.2))
                        Text(timeDisplay)
                            .font(Theme.Typography.numeric)
                    }

                    if viewModel.state == .warmup {
                        Text("Warm‑up").foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 12)
                }
                .padding(.top, 12)
            }
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { viewModel.cancel(); dismiss() } label: { Image(systemName: "xmark.circle.fill") } } }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase != .active {
                    viewModel.tick(at: Date(), isActive: false)
                }
            }
            .onAppear { setIdleDisabled(true) }
            .onDisappear { setIdleDisabled(false) }
            .task(id: context.date) { viewModel.tick(at: context.date, isActive: scenePhase == .active) }
            .accessibilityLabel("Meditation Focus Mode")
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
