import SwiftUI

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var sessions: [Int] = [10]
    @State private var warmup: Int = 0
    @State private var goFocus: Bool = false
    private let storage: StorageProtocol = UserDefaultsStorage()

    var body: some View {
        Form {
            Section("Sessions") {
                ForEach(sessions.indices, id: \.self) { idx in
                    Stepper(value: Binding(get: { sessions[idx] }, set: { sessions[idx] = min(59, max(1, $0)) }), in: 1...59) {
                        Text("Session \(idx + 1): \(sessions[idx]) min")
                    }
                }
                HStack {
                    Button {
                        if sessions.count < 9 { sessions.append(sessions.last ?? 10) }
                    } label: { Label("Add Session", systemImage: "plus") }
                    .disabled(sessions.count >= 9)
                    Spacer()
                    Button(role: .destructive) {
                        if sessions.count > 1 { _ = sessions.removeLast() }
                    } label: { Label("Remove Last", systemImage: "minus") }
                    .disabled(sessions.count <= 1)
                }
            }

            Section("Warm-up") {
                Stepper(value: $warmup, in: 0...15, step: 5) {
                    Text("Warm-up: \(warmup) s")
                }
            }

            Section {
                Button {
                    let plan = MeditationPlan(sessionsMinutes: sessions, warmupSeconds: warmup == 0 ? nil : warmup)
                    try? storage.save(plan, forKey: UDKeys.meditationPlan)
                    viewModel.startPlan(plan)
                    goFocus = true
                } label: {
                    Label("Start", systemImage: "play.circle.fill").font(.title3)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Meditate")
        .navigationDestination(isPresented: $goFocus) {
            FocusModeView().environmentObject(viewModel)
        }
        .onAppear {
            if let plan: MeditationPlan = try? storage.load(MeditationPlan.self, forKey: UDKeys.meditationPlan) {
                sessions = plan.sessionsMinutes.isEmpty ? [10] : plan.sessionsMinutes
                warmup = plan.warmupSeconds ?? 0
            } else {
                sessions = [viewModel.selectedMinutes]
                warmup = viewModel.warmupSeconds ?? 0
            }
        }
        .accessibilityLabel("Meditation Home")
    }
}

#Preview { NavigationStack { MeditationView() } }
