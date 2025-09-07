import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.primary.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Small icon pill for inline +/- actions.
struct IconPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Theme.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.secondary.opacity(0.15))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

