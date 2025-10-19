import Foundation

/// Stores the user's personal details and body metrics in canonical units.
struct UserProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var givenName: String
    var familyName: String
    var email: String
    /// Weight stored in kilograms for normalization.
    var weightInKilograms: Double?
    /// Height stored in centimeters for normalization.
    var heightInCentimeters: Double?
    var unitSystem: UnitSystem
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        givenName: String = "",
        familyName: String = "",
        email: String = "",
        weightInKilograms: Double? = nil,
        heightInCentimeters: Double? = nil,
        unitSystem: UnitSystem = .metric,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.givenName = givenName
        self.familyName = familyName
        self.email = email
        self.weightInKilograms = weightInKilograms
        self.heightInCentimeters = heightInCentimeters
        self.unitSystem = unitSystem
        self.updatedAt = updatedAt
    }

    static let empty = UserProfile()

    var fullName: String {
        [givenName, familyName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var initials: String {
        let first = givenName.trimmingCharacters(in: .whitespacesAndNewlines).first
        let last = familyName.trimmingCharacters(in: .whitespacesAndNewlines).first
        return [first, last]
            .compactMap { $0 }
            .map { String($0) }
            .joined()
            .uppercased()
    }

    var bmi: Double? {
        guard let weight = weightInKilograms,
              let heightCentimeters = heightInCentimeters,
              heightCentimeters > 0 else { return nil }
        let heightMeters = heightCentimeters / 100
        guard heightMeters > 0 else { return nil }
        return weight / (heightMeters * heightMeters)
    }

    var bmiCategory: BMICategory? {
        guard let bmi else { return nil }
        return BMICategory(value: bmi)
    }

    func weight(in system: UnitSystem) -> Double? {
        guard let weightInKilograms else { return nil }
        switch system {
        case .metric:
            return weightInKilograms
        case .imperial:
            return weightInKilograms / UnitSystem.imperial.weightConversionFactor
        }
    }

    func height(in system: UnitSystem) -> Double? {
        guard let heightInCentimeters else { return nil }
        switch system {
        case .metric:
            return heightInCentimeters
        case .imperial:
            return heightInCentimeters / UnitSystem.imperial.heightConversionFactor
        }
    }
}

extension UserProfile {
    enum UnitSystem: String, Codable, CaseIterable, Identifiable {
        case metric
        case imperial

        var id: Self { self }

        var label: String {
            switch self {
            case .metric: return "Metric (kg / cm)"
            case .imperial: return "Imperial (lb / in)"
            }
        }

        var weightUnitSymbol: String {
            switch self {
            case .metric: return "kg"
            case .imperial: return "lb"
            }
        }

        var heightUnitSymbol: String {
            switch self {
            case .metric: return "cm"
            case .imperial: return "in"
            }
        }

        /// Conversion factor from kilograms to this system's weight unit.
        var weightConversionFactor: Double {
            switch self {
            case .metric: return 1.0
            case .imperial: return 0.453_592_37
            }
        }

        /// Conversion factor from centimeters to this system's height unit.
        var heightConversionFactor: Double {
            switch self {
            case .metric: return 1.0
            case .imperial: return 2.54
            }
        }
    }

    enum BMICategory: String, Codable, CaseIterable, Identifiable {
        case underweight
        case normal
        case overweight
        case obese

        var id: Self { self }

        init?(value: Double) {
            switch value {
            case ..<18.5:
                self = .underweight
            case 18.5..<25:
                self = .normal
            case 25..<30:
                self = .overweight
            case 30...:
                self = .obese
            default:
                return nil
            }
        }

        var description: String {
            switch self {
            case .underweight: return "Underweight"
            case .normal: return "Healthy"
            case .overweight: return "Overweight"
            case .obese: return "Obese"
            }
        }
    }
}

extension UserProfile {
    static func formattedBMI(_ bmi: Double?) -> String? {
        guard let bmi else { return nil }
        return UserProfileFormatter.bmi.string(from: NSNumber(value: bmi))
    }

    static func formatted(value: Double?, unitSystem: UnitSystem, type: ValueType) -> String? {
        guard let value else { return nil }
        let formatter = UserProfileFormatter.decimal
        formatter.maximumFractionDigits = type == .height ? 1 : 1
        let number = formatter.string(from: NSNumber(value: value))
        let unit = type == .height ? unitSystem.heightUnitSymbol : unitSystem.weightUnitSymbol
        guard let number else { return nil }
        return "\(number) \(unit)"
    }

    enum ValueType {
        case weight
        case height
    }
}

private enum UserProfileFormatter {
    static let bmi: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}
