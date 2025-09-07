import SwiftUI

/// Lightweight design tokens for colors, spacing and radii.
enum Theme {
    // Colors
    static let background = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let primary = Color.accentColor
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    // Layout
    static let cornerRadius: CGFloat = 16
    static let spacing: CGFloat = 12

    // Typography
    enum Type {
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let section = Font.system(.caption, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let numeric = Font.system(size: 56, weight: .medium, design: .rounded).monospacedDigit()
    }
}

/// Section header text style shortcut.
extension Text {
    func sectionStyle() -> some View {
        self.font(Theme.Type.section)
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

