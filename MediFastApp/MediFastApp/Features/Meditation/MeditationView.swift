import SwiftUI

private struct SessionRow: Identifiable, Equatable {
    let id: UUID
    var minutes: Int
}

struct MeditationView: View {
    @StateObject private var viewModel = MeditationViewModel()
    @State private var rows: [SessionRow] = [SessionRow(id: UUID(), minutes: 10)]
    @State private var warmup: Int = 0
    @State private var goFocus: Bool = false
    private let storage: StorageProtocol = UserDefaultsStorage()

    var body: some View {
        Form {
            Section("Sessions") {
                ForEach($rows) { $row in
                    let idx = rows.firstIndex(where: { $0.id == row.id }) ?? 0
                    HStack {
                        Text("Session \(idx + 1): \(row.minutes) min")
                        Spacer()
                        HStack(spacing: 12) {
                            Button { row.minutes = max(1, row.minutes - 1) } label: {
                                Image(systemName: "minus")
                            }
                            .buttonStyle(.borderless)
                            Button { row.minutes = min(59, row.minutes + 1) } label: {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                HStack {
                    Button {
                        if rows.count < 9 {
                            let next = min(59, max(1, rows.last?.minutes ?? 10))
                            rows.append(SessionRow(id: UUID(), minutes: next))
                        }
                    } label: { Label("Add Session", systemImage: "plus") }
                    .buttonStyle(.borderless)
                    .disabled(rows.count >= 9)
                    Spacer()
                    Button(role: .destructive) {
                        if rows.count > 1 { _ = rows.removeLast() }
                    } label: { Label("Remove Last", systemImage: "minus") }
                    .buttonStyle(.borderless)
                    .disabled(rows.count <= 1)
                }
            }

            Section("Warm-up") {
                Stepper(value: $warmup, in: 0...15, step: 5) {
                    Text("Warm-up: \(warmup) s")
                }
            }

            Section {
                Button {
                    let plan = MeditationPlan(sessionsMinutes: rows.map { $0.minutes }, warmupSeconds: warmup == 0 ? nil : warmup)
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
                let mins = plan.sessionsMinutes.isEmpty ? [10] : plan.sessionsMinutes
                rows = mins.map { SessionRow(id: UUID(), minutes: min(59, max(1, $0))) }
                warmup = plan.warmupSeconds ?? 0
            } else {
                rows = [SessionRow(id: UUID(), minutes: max(1, viewModel.selectedMinutes))]
                warmup = viewModel.warmupSeconds ?? 0
            }
        }
        .accessibilityLabel("Meditation Home")
    }
}

#Preview { NavigationStack { MeditationView() } }
