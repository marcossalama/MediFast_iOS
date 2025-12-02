import SwiftUI

/// History list for meditation sessions with grouping and deletion.
struct MeditationHistoryView: View {
    var items: [MeditationSession] = []
    var onDelete: ((MeditationSession) -> Void)? = nil
    @State private var workingItems: [MeditationSession]

    init(items: [MeditationSession], onDelete: ((MeditationSession) -> Void)? = nil) {
        self.items = items
        self.onDelete = onDelete
        _workingItems = State(initialValue: items)
    }

    var body: some View {
        Group {
            if workingItems.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "leaf",
                    description: Text("Complete meditation sessions to see them here.")
                )
            } else {
                List {
                    ForEach(groupedSections) { section in
                        Section(section.title) {
                            ForEach(section.items) { session in
                                SessionListRow(session: session, onDelete: {
                                    delete(session)
                                })
                                .padding(.vertical, 4)
                                .swipeActions {
                                    if onDelete != nil {
                                        Button(role: .destructive) {
                                            delete(session)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Session History")
        .accessibilityLabel("Meditation Session History")
        .onAppear { workingItems = items }
    }

    private var groupedSections: [HistorySection] {
        let calendar = Calendar.current
        let grouped = workingItems.reduce(into: [HistorySectionKey: [MeditationSession]]()) { partial, session in
            let referenceDate = session.startAt
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            guard let startOfWeek = calendar.date(from: components) else { return }
            let key = HistorySectionKey(startOfWeek: startOfWeek)
            partial[key, default: []].append(session)
        }

        return grouped
            .map { key, items in
                HistorySection(
                    title: key.label,
                    items: items.sorted(by: { $0.startAt > $1.startAt }),
                    start: key.startOfWeek
                )
            }
            .sorted(by: { $0.start > $1.start })
    }

    private struct HistorySection: Identifiable {
        let title: String
        let items: [MeditationSession]
        let start: Date
        var id: Date { start }
    }

    private struct HistorySectionKey: Hashable {
        let startOfWeek: Date

        var label: String {
            let calendar = Calendar.current
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
            let startLabel = startOfWeek.formatted(date: .abbreviated, time: .omitted)
            let endLabel = endOfWeek.formatted(date: .abbreviated, time: .omitted)
            if calendar.isDate(startOfWeek, inSameDayAs: endOfWeek) {
                return startLabel
            }
            return "\(startLabel) – \(endLabel)"
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(startOfWeek.timeIntervalSince1970)
        }

        static func == (lhs: HistorySectionKey, rhs: HistorySectionKey) -> Bool {
            lhs.startOfWeek == rhs.startOfWeek
        }
    }
}

private struct SessionListRow: View {
    var session: MeditationSession
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.semibold))
            HStack {
                Text("Duration: \(TimeFormatter.hms(session.duration))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(session.endAt.formatted(date: .omitted, time: .shortened))
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
                    Label("Delete Session", systemImage: "trash")
                }
            }
        }
    }
}

extension MeditationHistoryView {
    private func delete(_ session: MeditationSession) {
        withAnimation {
            workingItems.removeAll(where: { $0.id == session.id })
        }
        onDelete?(session)
    }
}

#Preview {
    NavigationStack {
        MeditationHistoryView(items: [
            MeditationSession(id: UUID(), startAt: .now.addingTimeInterval(-7200), endAt: .now.addingTimeInterval(-3600), duration: 3600),
            MeditationSession(id: UUID(), startAt: .now.addingTimeInterval(-86400), endAt: .now.addingTimeInterval(-82800), duration: 3600)
        ])
    }
}


