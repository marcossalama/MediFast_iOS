import SwiftUI

/// Setup screen for guided breathing (Wim Hof style).
struct BreathingSetupView: View {
    @State private var rounds: Int = 5
    @State private var breathsPerRound: Int = 30
    @State private var recoveryHoldSeconds: Int = 15
    @State private var goSession = false
    @State private var viewModel: BreathingViewModel? = nil
    private let storage: StorageProtocol = UserDefaultsStorage()
    @State private var paceSeconds: Int = 3
    @State private var vibrateAfterRound: Bool = false
    @State private var dingAfterRound: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Mode").sectionStyle().cardPadding()
                Card {
                    Picker("Breaths", selection: $breathsPerRound) {
                        Text("25").tag(25)
                        Text("30").tag(30)
                        Text("35").tag(35)
                    }
                    .pickerStyle(.segmented)
                }
                .cardPadding()

                Text("Rounds").sectionStyle().cardPadding()
                Card {
                    HStack {
                        Text("Rounds: \(rounds)")
                        Spacer()
                        HStack(spacing: 8) {
                            Button { rounds = max(1, rounds - 1); Haptics.impact(.light) } label: { Image(systemName: "minus") }
                                .buttonStyle(IconPillButtonStyle())
                            Button { rounds = min(8, rounds + 1); Haptics.impact(.light) } label: { Image(systemName: "plus") }
                                .buttonStyle(IconPillButtonStyle())
                        }
                    }
                }
                .cardPadding()

                Text("Recovery Hold").sectionStyle().cardPadding()
                Card {
                    HStack {
                        Text("Hold: \(recoveryHoldSeconds)s")
                        Spacer()
                        HStack(spacing: 8) {
                            Button { recoveryHoldSeconds = max(5, recoveryHoldSeconds - 5); Haptics.impact(.light) } label: { Image(systemName: "minus") }
                                .buttonStyle(IconPillButtonStyle())
                            Button { recoveryHoldSeconds = min(60, recoveryHoldSeconds + 5); Haptics.impact(.light) } label: { Image(systemName: "plus") }
                                .buttonStyle(IconPillButtonStyle())
                        }
                    }
                }
                .cardPadding()

                Text("Settings").sectionStyle().cardPadding()
                Card {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Pace", selection: $paceSeconds) {
                            Text("Slow (4s)").tag(4)
                            Text("Med (3s)").tag(3)
                            Text("Fast (2s)").tag(2)
                        }
                        .pickerStyle(.segmented)
                        
                        Divider()
                        
                        Toggle(isOn: $vibrateAfterRound) {
                            Label("Vibrate after round", systemImage: "waveform")
                        }
                        Toggle(isOn: $dingAfterRound) {
                            Label("Ding after round", systemImage: "bell")
                        }
                    }
                }
                .cardPadding()

                Color.clear.frame(height: 80)
            }
            .padding(.top, 8)
        }
        .background(Theme.background)
        .navigationTitle("Guided Breathing")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    let settings = BreathingSettings(
                        rounds: rounds,
                        breathsPerRound: breathsPerRound,
                        recoveryHoldSeconds: recoveryHoldSeconds,
                        paceSeconds: paceSeconds,
                        vibrateAfterRound: vibrateAfterRound,
                        dingAfterRound: dingAfterRound
                    )
                    viewModel = BreathingViewModel(settings: settings)
                    goSession = true
                } label: { Text("Start").frame(maxWidth: .infinity) }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(.ultraThinMaterial)
        }
        .navigationDestination(isPresented: $goSession) {
            if let vm = viewModel {
                BreathingSessionView().environmentObject(vm)
            }
        }
        .onAppear {
            if let saved: BreathingSettings = try? storage.load(BreathingSettings.self, forKey: UDKeys.breathingSettings) {
                rounds = saved.rounds
                breathsPerRound = saved.breathsPerRound
                recoveryHoldSeconds = saved.recoveryHoldSeconds
                paceSeconds = saved.paceSeconds
                vibrateAfterRound = saved.vibrateAfterRound
                dingAfterRound = saved.dingAfterRound
            }
        }
    }
}

#Preview { NavigationStack { BreathingSetupView() } }
