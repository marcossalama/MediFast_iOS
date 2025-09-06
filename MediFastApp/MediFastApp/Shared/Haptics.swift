import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Lightweight wrapper around system haptics. Safe no-ops on unsupported platforms.
enum Haptics {
    static func impact(_ style: ImpactStyle = .medium) {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: style.uiStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    static func notify(_ type: NotificationType = .success) {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type.uiType)
        #endif
    }

    enum ImpactStyle { case light, medium, heavy, soft, rigid }
    enum NotificationType { case success, warning, error }

    /// Repeated impact pulses over a duration to approximate a longer vibration.
    static func pulse(duration: TimeInterval = 2.0, interval: TimeInterval = 0.25, style: ImpactStyle = .medium) {
        guard duration > 0, interval > 0 else { return }
        let count = max(1, Int(ceil(duration / interval)))
        func fire(_ i: Int) {
            impact(style)
            if i + 1 < count {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) { fire(i + 1) }
            }
        }
        fire(0)
    }
}

#if canImport(UIKit)
private extension Haptics.ImpactStyle { var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
    switch self { case .light: .light; case .medium: .medium; case .heavy: .heavy; case .soft: .soft; case .rigid: .rigid }
} }

private extension Haptics.NotificationType { var uiType: UINotificationFeedbackGenerator.FeedbackType {
    switch self { case .success: .success; case .warning: .warning; case .error: .error }
} }
#endif
