import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    activitySummaryCard.cardPadding()
                    summaryCard.cardPadding()
                    if viewModel.isEditing, let error = viewModel.errorMessage {
                        StatusBanner(
                            text: error,
                            systemImage: "exclamationmark.triangle.fill",
                            tint: .orange
                        )
                        .cardPadding()
                    } else if let status = viewModel.statusMessage, !viewModel.isEditing {
                        StatusBanner(
                            text: status,
                            systemImage: "checkmark.circle.fill",
                            tint: .green.opacity(0.9)
                        )
                        .cardPadding()
                    }
                    termsCard.cardPadding()
                }
                .padding(.top, 8)
                .padding(.horizontal, 0)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            // Refresh activity stats when view appears
            _ = viewModel.getActivityStats()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
            if viewModel.isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        focusedField = nil
                        viewModel.cancelEditing()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        focusedField = nil
                        viewModel.saveChanges()
                    }
                    .disabled(!viewModel.canSave)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        viewModel.startEditing()
                        focusedField = .firstName
                    }
                }
            }
        }
    }

    private var activitySummaryCard: some View {
        let stats = viewModel.getActivityStats()
        
        return Card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Activity Summary").sectionStyle()
                
                // Meditation Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                        Text("Meditation")
                            .font(.headline)
                    }
                    
                    HStack(spacing: 16) {
                        ActivityMetric(
                            label: "Streak",
                            value: "\(stats.meditationStreak)",
                            unit: stats.meditationStreak == 1 ? "day" : "days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        ActivityMetric(
                            label: "Sessions",
                            value: "\(stats.meditationTotalSessions)",
                            unit: "",
                            icon: "list.bullet",
                            color: Theme.primary
                        )
                        ActivityMetric(
                            label: "Total Time",
                            value: formatMinutes(stats.meditationTotalMinutes),
                            unit: "",
                            icon: "clock.fill",
                            color: Theme.primary
                        )
                    }
                }
                
                Divider()
                
                // Breathing Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "wind")
                            .foregroundStyle(.blue)
                            .font(.headline)
                        Text("Breathing")
                            .font(.headline)
                    }
                    
                    HStack(spacing: 16) {
                        if let bestRetention = stats.breathingLatestBestRetention {
                            ActivityMetric(
                                label: "Best Retention",
                                value: TimeFormatter.ms(bestRetention),
                                unit: "",
                                icon: "timer",
                                color: Theme.primary
                            )
                        } else {
                            ActivityMetric(
                                label: "Best Retention",
                                value: "—",
                                unit: "",
                                icon: "timer",
                                color: Theme.primary
                            )
                        }
                        ActivityMetric(
                            label: "Latest Rounds",
                            value: "\(stats.breathingLatestRounds)",
                            unit: "",
                            icon: "arrow.clockwise",
                            color: Theme.primary
                        )
                    }
                }
                
                Divider()
                
                // Fasting Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .foregroundStyle(.purple)
                            .font(.headline)
                        Text("Fasting")
                            .font(.headline)
                    }
                    
                    HStack(spacing: 16) {
                        ActivityMetric(
                            label: "Streak",
                            value: "\(stats.fastingStreak)",
                            unit: stats.fastingStreak == 1 ? "day" : "days",
                            icon: "flame.fill",
                            color: .orange
                        )
                        ActivityMetric(
                            label: "Total Fasts",
                            value: "\(stats.fastingTotalFasts)",
                            unit: "",
                            icon: "list.bullet",
                            color: Theme.primary
                        )
                        if let longestHours = stats.fastingLongestHours {
                            ActivityMetric(
                                label: "Longest",
                                value: formatHours(longestHours),
                                unit: "",
                                icon: "clock.fill",
                                color: Theme.primary
                            )
                        } else {
                            ActivityMetric(
                                label: "Longest",
                                value: "—",
                                unit: "",
                                icon: "clock.fill",
                                color: Theme.primary
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    InitialsBadge(initials: viewModel.profile.initials)
                    VStack(alignment: .leading, spacing: viewModel.isEditing ? 12 : 4) {
                        if viewModel.isEditing {
                            summaryEditableField(
                                title: "First Name",
                                text: $viewModel.form.givenName,
                                field: .firstName,
                                placeholder: "Jane",
                                capitalization: .words,
                                submitLabel: .next
                            )
                            summaryEditableField(
                                title: "Last Name",
                                text: $viewModel.form.familyName,
                                field: .lastName,
                                placeholder: "Doe",
                                capitalization: .words,
                                submitLabel: .next
                            )
                            summaryEditableField(
                                title: "Email",
                                text: $viewModel.form.email,
                                field: .email,
                                placeholder: "jane@example.com",
                                keyboard: .emailAddress,
                                capitalization: .never,
                                submitLabel: .next
                            )
                        } else {
                            Text(viewModel.displayName)
                                .font(.title3.weight(.semibold))
                            Text(viewModel.displayEmail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                if viewModel.isEditing {
                    Divider()
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Body Metrics")
                            .font(.headline)
                        summaryEditableField(
                            title: "Weight (\(viewModel.form.unitSystem.weightUnitSymbol))",
                            text: $viewModel.form.weight,
                            field: .weight,
                            placeholder: viewModel.form.unitSystem == .metric ? "70.0" : "154.3",
                            keyboard: .decimalPad,
                            capitalization: .never,
                            submitLabel: .next
                        )
                        summaryEditableField(
                            title: "Height (\(viewModel.form.unitSystem.heightUnitSymbol))",
                            text: $viewModel.form.height,
                            field: .height,
                            placeholder: viewModel.form.unitSystem == .metric ? "175" : "68.9",
                            keyboard: .decimalPad,
                            capitalization: .never,
                            submitLabel: .done
                        )
                        Picker("Units", selection: Binding(
                            get: { viewModel.form.unitSystem },
                            set: { newValue in viewModel.updateUnitSystem(newValue) }
                        )) {
                            ForEach(UserProfile.UnitSystem.allCases) { system in
                                Text(system.label).tag(system)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                } else {
                    Divider()
                    HStack(spacing: 16) {
                        MetricPill(title: "Weight", value: viewModel.displayWeight, icon: "scalemass")
                        MetricPill(title: "Height", value: viewModel.displayHeight, icon: "ruler")
                    }
                }

                if let bmi = viewModel.profile.bmi {
                    Divider()
                    BMICategoryBar(bmi: bmi)
                        .accessibilityLabel(viewModel.bmiSummary)
                } else {
                    Divider()
                    Text(viewModel.bmiSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var termsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Terms & Safety")
                    .font(.headline)
                    .foregroundStyle(.primary)

                VStack(alignment: .leading, spacing: 10) {
                    Label("Only use Focus Mode when you can give it your full attention.", systemImage: "checkmark.circle.fill")
                    Label("Never run sessions while driving, cycling, swimming, or during tasks that demand focus.", systemImage: "checkmark.circle.fill")
                    Label("Follow local laws, safety guidance, and any advice from your healthcare provider.", systemImage: "checkmark.circle.fill")
                    Label("Make sure your surroundings stay safe and you can pause or stop any session immediately.", systemImage: "checkmark.circle.fill")
                }
                .labelStyle(TermsLabelStyle())

                Text("By continuing you accept responsibility for safe use and acknowledge that MediFast is not liable for issues caused by unsafe behavior.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Terms and safety guidance for using Focus Mode.")
    }

    @ViewBuilder
    private func summaryEditableField(
        title: String,
        text: Binding<String>,
        field: Field,
        placeholder: String,
        keyboard: UIKeyboardType = .default,
        capitalization: TextInputAutocapitalization = .sentences,
        submitLabel: SubmitLabel = .next
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .focused($focusedField, equals: field)
                .textInputAutocapitalization(capitalization)
                .autocorrectionDisabled(true)
                .keyboardType(keyboard)
                .submitLabel(submitLabel)
                .onSubmit { advanceFocus(from: field) }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Theme.surface.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func advanceFocus(from field: Field) {
        switch field {
        case .firstName: focusedField = .lastName
        case .lastName: focusedField = .email
        case .email: focusedField = .weight
        case .weight: focusedField = .height
        case .height: focusedField = nil
        }
    }

    private enum Field: Hashable {
        case firstName, lastName, email, weight, height
    }
}

private struct InitialsBadge: View {
    var initials: String

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.primary.opacity(0.15))
                .frame(width: 64, height: 64)
            Text(initials.isEmpty ? "--" : initials)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.primary)
        }
    }
}

private struct MetricPill: View {
    var title: String
    var value: String
    var icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(Theme.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

private struct StatusBanner: View {
    var text: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
            Text(text)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Theme.surface.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

/// Segmented BMI bar showing category colors and current value marker.
private struct BMICategoryBar: View {
    var bmi: Double

    private static let maxBMI: Double = 40
    private static let segments: [Segment] = [
        Segment(id: "under", lowerBound: 0, upperBound: 18.5, label: "Under", color: .blue.opacity(0.5)),
        Segment(id: "healthy", lowerBound: 18.5, upperBound: 25, label: "Healthy", color: .green.opacity(0.6)),
        Segment(id: "over", lowerBound: 25, upperBound: 30, label: "Over", color: .orange.opacity(0.7)),
        Segment(id: "obese", lowerBound: 30, upperBound: maxBMI, label: "Obese", color: .red.opacity(0.7))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let capped = min(max(bmi, 0), Self.maxBMI)
                let markerX = width * CGFloat(capped / Self.maxBMI)

                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(Self.segments) { segment in
                            Rectangle()
                                .fill(segment.color)
                                .frame(
                                    width: width / CGFloat(Self.segments.count),
                                    height: proxy.size.height
                                )
                        }
                    }
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                    )

                    VStack(spacing: 2) {
                        Text(Self.formatted(bmi))
                            .font(.caption2.monospacedDigit())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        Capsule()
                            .fill(Color.primary)
                            .frame(width: 2, height: proxy.size.height)
                    }
                    .offset(x: markerX - 1)
                }
            }
            .frame(height: 28)
            .padding(.bottom, 6)

            HStack(alignment: .center, spacing: 12) {
                ForEach(Self.segments) { segment in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 8, height: 8)
                        Text(segment.accessibleLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }

    private struct Segment: Identifiable {
        let id: String
        let lowerBound: Double
        let upperBound: Double
        let label: String
        let color: Color

        var accessibleLabel: String {
            switch id {
            case "under": return "Underweight"
            case "healthy": return "Healthy"
            case "over": return "Overweight"
            case "obese": return "Obese"
            default: return label
            }
        }
    }

    private static func formatted(_ value: Double) -> String {
        UserProfile.formattedBMI(value) ?? String(format: "%.1f", value)
    }
}

private struct TermsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            configuration.icon
                .symbolRenderingMode(.hierarchical)
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.primary)
            configuration.title
                .font(.footnote)
                .foregroundStyle(.primary)
        }
    }
}

private struct ActivityMetric: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold))
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func formatMinutes(_ minutes: Double) -> String {
    let totalMinutes = Int(minutes.rounded())
    if totalMinutes >= 60 {
        let hours = totalMinutes / 60
        let remainingMinutes = totalMinutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(remainingMinutes)m"
    }
    return "\(totalMinutes)m"
}

private func formatHours(_ hours: Double) -> String {
    let totalHours = Int(hours.rounded())
    let minutes = Int((hours - Double(totalHours)) * 60)
    if minutes == 0 {
        return "\(totalHours)h"
    }
    return "\(totalHours)h \(minutes)m"
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
