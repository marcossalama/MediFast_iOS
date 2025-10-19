import SwiftUI

/// Enhanced history list with grouping, filters, and richer empty state.
struct FastHistoryView: View {
    var items: [Fast] = []
    var defaultFilterHours: Double = 0
    var onDelete: ((Fast) -> Void)? = nil
    @State private var selectedFilter: HistoryFilter
    @State private var workingItems: [Fast]

    init(items: [Fast], defaultFilterHours: Double = 0, onDelete: ((Fast) -> Void)? = nil) {
        self.items = items
        self.defaultFilterHours = defaultFilterHours
        self.onDelete = onDelete
        _selectedFilter = State(initialValue: HistoryFilter(hours: defaultFilterHours))
        _workingItems = State(initialValue: items)
    }

    var body: some View {
        Group {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    "No fasts match",
                    systemImage: "clock.badge.exclamationmark",
                    description: Text(emptyDescription)
                )
                .toolbar { filterToolbar }
            } else {
                List {
                    ForEach(groupedSections) { section in
                        Section(section.title) {
                            ForEach(section.items) { fast in
                                HistoryListRow(fast: fast, onDelete: {
                                    delete(fast)
                                })
                                .padding(.vertical, 4)
                                .swipeActions {
                                    if onDelete != nil {
                                        Button(role: .destructive) {
                                            delete(fast)
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
                .toolbar { filterToolbar }
            }
        }
        .navigationTitle("History")
        .accessibilityLabel("Fasting History")
        .onAppear { workingItems = items }
    }

    private var filterToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }

    private var emptyDescription: String {
        selectedFilter.minimumDuration == nil ?
        "Start a fast to build your history." :
        "Try adjusting the filter to include shorter fasts."
    }

    private var filteredItems: [Fast] {
        guard let minDuration = selectedFilter.minimumDuration else { return workingItems }
        return workingItems.filter { ($0.duration ?? 0) >= minDuration }
    }

    private var groupedSections: [HistorySection] {
        let calendar = Calendar.current
        let grouped = filteredItems.reduce(into: [HistorySectionKey: [Fast]]()) { partial, fast in
            let referenceDate = fast.endAt ?? fast.startAt
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            guard let startOfWeek = calendar.date(from: components) else { return }
            let key = HistorySectionKey(startOfWeek: startOfWeek)
            partial[key, default: []].append(fast)
        }

        return grouped
            .map { key, items in
                HistorySection(
                    title: key.label,
                    items: items.sorted(by: { ($0.startAt) > ($1.startAt) }),
                    start: key.startOfWeek
                )
            }
            .sorted(by: { $0.start > $1.start })
    }

    private struct HistorySection: Identifiable {
        let title: String
        let items: [Fast]
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

    private enum HistoryFilter: CaseIterable, Identifiable {
        case all
        case hours12
        case hours16
        case hours20

        var id: Self { self }

        var title: String {
            switch self {
            case .all: return "All fasts"
            case .hours12: return "12+ hours"
            case .hours16: return "16+ hours"
            case .hours20: return "20+ hours"
            }
        }

        var minimumDuration: TimeInterval? {
            switch self {
            case .all: return nil
            case .hours12: return 12 * 3600
            case .hours16: return 16 * 3600
            case .hours20: return 20 * 3600
            }
        }

        init(hours: Double) {
            switch hours {
            case 20...: self = .hours20
            case 16..<20: self = .hours16
            case 12..<16: self = .hours12
            default: self = .all
            }
        }
    }
}

private struct HistoryListRow: View {
    var fast: Fast
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fast.startAt.formatted(date: .abbreviated, time: .shortened))
                .font(.subheadline.weight(.semibold))
            if let end = fast.endAt {
                Text("Ended " + end.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let duration = fast.duration {
                Text(TimeFormatter.hms(duration))
                    .font(.caption.monospacedDigit())
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

extension FastHistoryView {
    private func delete(_ fast: Fast) {
        withAnimation {
            workingItems.removeAll(where: { $0.id == fast.id })
        }
        onDelete?(fast)
    }
}
#Preview {
    NavigationStack {
        FastHistoryView(items: [
            Fast(id: UUID(), startAt: .now.addingTimeInterval(-7200), endAt: .now.addingTimeInterval(-3600), duration: 3600),
            Fast(id: UUID(), startAt: .now.addingTimeInterval(-86400), endAt: .now.addingTimeInterval(-43200), duration: 43200)
        ])
    }
}
