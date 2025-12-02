import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile
    @Published var form: ProfileForm
    @Published var isEditing = false
    @Published var errorMessage: String?
    @Published var statusMessage: String?

    private let storage: StorageProtocol

    init(storage: StorageProtocol = UserDefaultsStorage()) {
        self.storage = storage
        let storedProfile = (try? storage.load(UserProfile.self, forKey: UDKeys.userProfile)) ?? UserProfile.empty
        self.profile = storedProfile
        self.form = ProfileForm(profile: storedProfile)
    }

    // MARK: - Summary
    var displayName: String {
        let name = profile.fullName
        return name.isEmpty ? "Add your name" : name
    }

    var displayEmail: String {
        profile.email.isEmpty ? "Add your email" : profile.email
    }

    var displayWeight: String {
        guard let value = profile.weight(in: profile.unitSystem) else { return "—" }
        return UserProfile.formatted(value: value, unitSystem: profile.unitSystem, type: .weight) ?? "—"
    }

    var displayHeight: String {
        guard let value = profile.height(in: profile.unitSystem) else { return "—" }
        return UserProfile.formatted(value: value, unitSystem: profile.unitSystem, type: .height) ?? "—"
    }

    var bmiSummary: String {
        guard let bmiValue = UserProfile.formattedBMI(profile.bmi),
              let category = profile.bmiCategory else { return "Add weight and height to see BMI" }
        return "\(bmiValue) • \(category.description)"
    }

    var canSave: Bool {
        guard isEditing else { return false }
        guard form.hasChanges(comparedTo: profile) else { return false }
        return form.validationMessage == nil
    }

    // MARK: - Intents
    func startEditing() {
        isEditing = true
        form = ProfileForm(profile: profile)
        errorMessage = nil
        statusMessage = nil
    }

    func cancelEditing() {
        isEditing = false
        form = ProfileForm(profile: profile)
        errorMessage = nil
        statusMessage = nil
    }

    func saveChanges() {
        do {
            let updatedProfile = try form.buildProfile(from: profile)
            profile = updatedProfile
            try storage.save(updatedProfile, forKey: UDKeys.userProfile)
            isEditing = false
            form = ProfileForm(profile: updatedProfile)
            statusMessage = "Profile updated"
            errorMessage = nil
            Haptics.notify(.success)
        } catch let validation as ProfileForm.ValidationError {
            errorMessage = validation.message
            statusMessage = nil
            Haptics.notify(.error)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = nil
            Haptics.notify(.error)
        }
    }

    func updateUnitSystem(_ system: UserProfile.UnitSystem) {
        guard form.unitSystem != system else { return }
        form.updateUnitSystem(system)
    }
    
    // MARK: - Activity Stats
    struct ActivityStats {
        // Meditation
        var meditationStreak: Int = 0
        var meditationTotalSessions: Int = 0
        var meditationTotalMinutes: Double = 0
        
        // Breathing
        var breathingLatestBestRetention: TimeInterval? = nil
        var breathingLatestRounds: Int = 0
        
        // Fasting
        var fastingStreak: Int = 0
        var fastingTotalFasts: Int = 0
        var fastingLongestHours: Double? = nil
    }
    
    func getActivityStats() -> ActivityStats {
        let storage = self.storage
        
        // Meditation stats
        let meditationSessions = (try? storage.load([MeditationSession].self, forKey: UDKeys.meditationSessions)) ?? []
        let meditationStreaks = (try? storage.load(StreaksState.self, forKey: UDKeys.meditationStreaks)) ?? StreaksState(lastSessionDate: nil, currentStreak: 0, bestStreak: 0)
        let meditationTotalSeconds = meditationSessions.reduce(0.0) { $0 + $1.duration }
        
        // Breathing stats (latest session only)
        let breathingHistory = (try? storage.load([BreathingRoundResult].self, forKey: UDKeys.breathingHistory)) ?? []
        let breathingBestRetention = breathingHistory.map { $0.retentionSeconds }.max()
        let breathingRounds = breathingHistory.count
        
        // Fasting stats
        let fastingHistory = (try? storage.load([Fast].self, forKey: UDKeys.fastingHistory)) ?? []
        let fastingStreak = calculateFastingStreak(from: fastingHistory)
        let fastingLongest = fastingHistory.max(by: { ($0.duration ?? 0) < ($1.duration ?? 0) })
        let fastingLongestHours = fastingLongest?.duration.map { $0 / 3600.0 }
        
        return ActivityStats(
            meditationStreak: meditationStreaks.currentStreak,
            meditationTotalSessions: meditationSessions.count,
            meditationTotalMinutes: meditationTotalSeconds / 60.0,
            breathingLatestBestRetention: breathingBestRetention,
            breathingLatestRounds: breathingRounds,
            fastingStreak: fastingStreak,
            fastingTotalFasts: fastingHistory.count,
            fastingLongestHours: fastingLongestHours
        )
    }
    
    private func calculateFastingStreak(from history: [Fast]) -> Int {
        guard !history.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var lastDay: Date? = nil

        for fast in history {
            guard let end = fast.endAt else { continue }
            let day = calendar.startOfDay(for: end)

            if let prevDay = lastDay {
                if calendar.isDate(day, inSameDayAs: prevDay) {
                    continue
                }
                if let expected = calendar.date(byAdding: .day, value: -1, to: prevDay),
                   calendar.isDate(day, inSameDayAs: expected) {
                    streak += 1
                    lastDay = day
                } else {
                    break
                }
            } else {
                streak = 1
                lastDay = day
            }
        }

        return streak
    }
}

// MARK: - Form Data
struct ProfileForm: Equatable {
    var givenName: String
    var familyName: String
    var email: String
    var weight: String
    var height: String
    var unitSystem: UserProfile.UnitSystem

    init(
        givenName: String = "",
        familyName: String = "",
        email: String = "",
        weight: String = "",
        height: String = "",
        unitSystem: UserProfile.UnitSystem = .metric
    ) {
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.weight = weight
        self.height = height
        self.unitSystem = unitSystem
    }

    init(profile: UserProfile) {
        let formatter = ProfileForm.formatter
        self.givenName = profile.givenName
        self.familyName = profile.familyName
        self.email = profile.email
        self.unitSystem = profile.unitSystem
        if let weightValue = profile.weight(in: profile.unitSystem) {
            self.weight = formatter.string(from: NSNumber(value: weightValue)) ?? ""
        } else {
            self.weight = ""
        }
        if let heightValue = profile.height(in: profile.unitSystem) {
            self.height = formatter.string(from: NSNumber(value: heightValue)) ?? ""
        } else {
            self.height = ""
        }
    }

    var validationMessage: String? {
        do {
            _ = try buildProfile(from: nil)
            return nil
        } catch let validation as ValidationError {
            return validation.message
        } catch {
            return error.localizedDescription
        }
    }

    func hasChanges(comparedTo profile: UserProfile) -> Bool {
        self != ProfileForm(profile: profile)
    }

    func buildProfile(from existingProfile: UserProfile?) throws -> UserProfile {
        let trimmedFirst = givenName.trimmed()
        let trimmedLast = familyName.trimmed()
        let trimmedEmail = email.trimmed()

        guard !trimmedFirst.isEmpty else { throw ValidationError.missingFirstName }
        guard !trimmedLast.isEmpty else { throw ValidationError.missingLastName }
        guard !trimmedEmail.isEmpty else { throw ValidationError.missingEmail }
        guard Self.validateEmail(trimmedEmail) else { throw ValidationError.invalidEmail }

        let normalizedWeight = try parseMeasurement(weight, kind: .weight)
        let normalizedHeight = try parseMeasurement(height, kind: .height)

        let profileId = existingProfile?.id ?? UUID()
        return UserProfile(
            id: profileId,
            givenName: trimmedFirst,
            familyName: trimmedLast,
            email: trimmedEmail,
            weightInKilograms: normalizedWeight,
            heightInCentimeters: normalizedHeight,
            unitSystem: unitSystem,
            updatedAt: Date()
        )
    }

    private func parseMeasurement(_ input: String, kind: MeasurementKind) throws -> Double? {
        let trimmed = input.trimmed()
        guard !trimmed.isEmpty else {
            throw kind == .weight ? ValidationError.missingWeight : ValidationError.missingHeight
        }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0 else {
            throw kind == .weight ? ValidationError.invalidWeight : ValidationError.invalidHeight
        }

        switch kind {
        case .weight:
            switch unitSystem {
            case .metric: return value
            case .imperial: return value * UserProfile.UnitSystem.imperial.weightConversionFactor
            }
        case .height:
            switch unitSystem {
            case .metric: return value
            case .imperial: return value * UserProfile.UnitSystem.imperial.heightConversionFactor
            }
        }
    }

    private static func validateEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    enum MeasurementKind { case weight, height }

    mutating func updateUnitSystem(_ newSystem: UserProfile.UnitSystem) {
        guard newSystem != unitSystem else { return }
        weight = Self.convert(value: weight, from: unitSystem, to: newSystem, kind: .weight)
        height = Self.convert(value: height, from: unitSystem, to: newSystem, kind: .height)
        unitSystem = newSystem
    }

    private static func convert(
        value: String,
        from current: UserProfile.UnitSystem,
        to target: UserProfile.UnitSystem,
        kind: MeasurementKind
    ) -> String {
        let trimmed = value.trimmed()
        guard !trimmed.isEmpty else { return "" }
        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        guard let numeric = Double(normalized) else { return value }

        let canonical: Double
        switch kind {
        case .weight:
            canonical = current == .metric
            ? numeric
            : numeric * UserProfile.UnitSystem.imperial.weightConversionFactor
        case .height:
            canonical = current == .metric
            ? numeric
            : numeric * UserProfile.UnitSystem.imperial.heightConversionFactor
        }

        let converted: Double
        switch kind {
        case .weight:
            converted = target == .metric
            ? canonical
            : canonical / UserProfile.UnitSystem.imperial.weightConversionFactor
        case .height:
            converted = target == .metric
            ? canonical
            : canonical / UserProfile.UnitSystem.imperial.heightConversionFactor
        }

        return formatter.string(from: NSNumber(value: converted)) ?? value
    }

    enum ValidationError: LocalizedError {
        case missingFirstName
        case missingLastName
        case missingEmail
        case invalidEmail
        case missingWeight
        case missingHeight
        case invalidWeight
        case invalidHeight

        var message: String {
            switch self {
            case .missingFirstName: return "First name is required."
            case .missingLastName: return "Last name is required."
            case .missingEmail: return "Email is required."
            case .invalidEmail: return "Enter a valid email address."
            case .missingWeight: return "Weight is required."
            case .missingHeight: return "Height is required."
            case .invalidWeight: return "Weight must be a positive number."
            case .invalidHeight: return "Height must be a positive number."
            }
        }

        var errorDescription: String? { message }
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

private extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
