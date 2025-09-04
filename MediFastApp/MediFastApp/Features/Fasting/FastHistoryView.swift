import SwiftUI

/// Minimal history list placeholder (data will be injected later).
struct FastHistoryView: View {
    var items: [Fast] = []

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView("No Fasts Yet", systemImage: "clock.arrow.2.circlepath", description: Text("Your completed fasts will appear here."))
            } else {
                List(items) { fast in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fast.startAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                        if let end = fast.endAt {
                            Text("End: " + end.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let dur = fast.duration {
                                Text(TimeFormatter.hms(dur))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Active")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .accessibilityLabel("Fasting History")
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
