import SwiftUI

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var customMinutes: Int = 10
    @State private var selection: Preset = .ten
    @State private var midpointEnabled: Bool = false
    @State private var midpointEvery: Int = 10
    @State private var warmup: Int = 0
    @State private var goFocus: Bool = false

    enum Preset: Hashable { case five, ten, twenty, custom }

    var body: some View {
        Form {
            Section("Duration") {
                Picker("Preset", selection: $selection) {
                    Text("5 min").tag(Preset.five)
                    Text("10 min").tag(Preset.ten)
                    Text("20 min").tag(Preset.twenty)
                    Text("Custom").tag(Preset.custom)
                }
                .pickerStyle(.segmented)

                if selection == .custom {
                    Stepper(value: $customMinutes, in: 1...180) {
                        Text("Custom: \(customMinutes) min")
                    }
                }
            }

            Section("Options") {
                Toggle("Midpoint bells", isOn: $midpointEnabled)
                if midpointEnabled {
                    Picker("Every", selection: $midpointEvery) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                        Text("20 min").tag(20)
                    }
                    .pickerStyle(.segmented)
                }

                Stepper(value: $warmup, in: 0...15, step: 5) {
                    Text("Warm-up: \(warmup) s")
                }
            }

            Section {
                Button {
                    let minutes: Int = {
                        switch selection {
                        case .five: return 5
                        case .ten: return 10
                        case .twenty: return 20
                        case .custom: return customMinutes
                        }
                    }()
                    viewModel.start(minutes: minutes, warmupSeconds: warmup == 0 ? nil : warmup, midpointInterval: midpointEnabled ? midpointEvery : nil)
                    goFocus = true
                } label: {
                    Label("Start", systemImage: "play.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Meditate")
        .navigationDestination(isPresented: $goFocus) {
            FocusModeView()
                .environmentObject(viewModel)
        }
        .onAppear {
            // Initialize UI from saved settings
            selection = presetFrom(minutes: viewModel.selectedMinutes)
            customMinutes = viewModel.selectedMinutes
            midpointEnabled = viewModel.midpointInterval != nil
            midpointEvery = viewModel.midpointInterval ?? 10
            warmup = viewModel.warmupSeconds ?? 0
        }
        .accessibilityLabel("Meditation Home")
    }

    private func presetFrom(minutes: Int) -> Preset {
        switch minutes { case 5: return .five; case 10: return .ten; case 20: return .twenty; default: return .custom }
    }
}

#Preview {
    NavigationStack { MeditationView() }
}
