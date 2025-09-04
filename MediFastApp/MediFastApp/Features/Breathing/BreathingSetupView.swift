import SwiftUI

/// Setup screen for guided breathing (Wim Hof style). Minimal scaffold UI.
struct BreathingSetupView: View {
    @State private var rounds: Int = 5
    @State private var breathsPerRound: Int = 30
    @State private var recoveryHoldSeconds: Int = 15
    @State private var goSession = false
    @State private var viewModel: BreathingViewModel? = nil

    var body: some View {
        Form {
            Section("Mode") {
                Picker("Breaths", selection: $breathsPerRound) {
                    Text("25").tag(25)
                    Text("30").tag(30)
                    Text("35").tag(35)
                }
                .pickerStyle(.segmented)
            }

            Section("Rounds") {
                Stepper(value: $rounds, in: 1...8) {
                    Text("Rounds: \(rounds)")
                }
            }

            Section("Recovery Hold") {
                Stepper(value: $recoveryHoldSeconds, in: 5...60, step: 5) {
                    Text("Hold: \(recoveryHoldSeconds)s")
                }
            }

            Section {
                Button {
                    let settings = BreathingSettings(rounds: rounds, breathsPerRound: breathsPerRound, recoveryHoldSeconds: recoveryHoldSeconds)
                    viewModel = BreathingViewModel(settings: settings)
                    goSession = true
                } label: {
                    Label("Start", systemImage: "play.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Guided Breathing")
        .navigationDestination(isPresented: $goSession) {
            if let vm = viewModel {
                BreathingSessionView()
                    .environmentObject(vm)
            }
        }
    }
}

#Preview {
    NavigationStack { BreathingSetupView() }
}

