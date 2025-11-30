import Foundation
#if canImport(UIKit)
import UIKit
import AudioToolbox
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

    /// Repeated pulses using system vibration (when available) as well as impact feedback.
    static func pulse(duration: TimeInterval = 2.0, interval: TimeInterval = 0.25, style: ImpactStyle = .medium) {
        guard duration > 0, interval > 0 else { return }
        let count = max(1, Int(ceil(duration / interval)))
        func fire(_ i: Int) {
            triggerVibrate(style: style)
            if i + 1 < count {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) { fire(i + 1) }
            }
        }
        fire(0)
    }

    /// Continuous standard iOS vibration for the specified duration.
    /// Uses system vibration sound repeatedly at short intervals to create continuous feel.
    static func vibrate(duration: TimeInterval) {
        guard duration > 0 else { return }
        #if canImport(UIKit)
        let interval: TimeInterval = 0.1 // Short interval for continuous feel
        let count = max(1, Int(ceil(duration / interval)))
        func fire(_ i: Int) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            if i + 1 < count {
                DispatchQueue.main.asyncAfter(deadline: .now() + interval) { fire(i + 1) }
            }
        }
        fire(0)
        #endif
    }

    #if canImport(UIKit)
    private static func triggerVibrate(style: ImpactStyle) {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        impact(style)
    }
    #else
    private static func triggerVibrate(style: ImpactStyle) { /* no-op */ }
    #endif
}

#if canImport(UIKit)
private extension Haptics.ImpactStyle {
    var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .light: .light
        case .medium: .medium
        case .heavy: .heavy
        case .soft: .soft
        case .rigid: .rigid
        }
    }
}

private extension Haptics.NotificationType {
    var uiType: UINotificationFeedbackGenerator.FeedbackType {
        switch self {
        case .success: .success
        case .warning: .warning
        case .error: .error
        }
    }
}
#endif
