import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @FocusState private var focusedField: Field?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryCard.cardPadding()
                    formCard.cardPadding()
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
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Profile")
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

    private var summaryCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 16) {
                    InitialsBadge(initials: viewModel.profile.initials)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.displayName)
                            .font(.title3.weight(.semibold))
                        Text(viewModel.displayEmail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Divider()
                HStack(spacing: 16) {
                    MetricPill(title: "Weight", value: viewModel.displayWeight, icon: "scalemass")
                    MetricPill(title: "Height", value: viewModel.displayHeight, icon: "ruler")
                }
                Divider()
                Text(viewModel.bmiSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var formCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 20) {
                Text("Personal Info")
                    .font(.headline)
                editableField(
                    title: "First Name",
                    text: $viewModel.form.givenName,
                    field: .firstName,
                    placeholder: "Jane",
                    capitalization: .words
                )
                editableField(
                    title: "Last Name",
                    text: $viewModel.form.familyName,
                    field: .lastName,
                    placeholder: "Doe",
                    capitalization: .words
                )
                editableField(
                    title: "Email",
                    text: $viewModel.form.email,
                    field: .email,
                    placeholder: "jane@example.com",
                    keyboard: .emailAddress,
                    capitalization: .never
                )

                Divider().padding(.top, 4)

                Text("Body Metrics")
                    .font(.headline)
                editableField(
                    title: "Weight (\(viewModel.form.unitSystem.weightUnitSymbol))",
                    text: $viewModel.form.weight,
                    field: .weight,
                    placeholder: viewModel.form.unitSystem == .metric ? "70.0" : "154.3",
                    keyboard: .decimalPad,
                    capitalization: .never,
                    submitLabel: .next
                )
                editableField(
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
                .disabled(!viewModel.isEditing)

                if let error = viewModel.errorMessage, viewModel.isEditing {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.red)
                }
            }
        }
    }

    @ViewBuilder
    private func editableField(
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
            if viewModel.isEditing {
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
            } else {
                Text(text.wrappedValue.isEmpty ? "—" : text.wrappedValue)
                    .font(.body.weight(.medium))
            }
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

#Preview {
    NavigationStack {
        ProfileView()
    }
}
