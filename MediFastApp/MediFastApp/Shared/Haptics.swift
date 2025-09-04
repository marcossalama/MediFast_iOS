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
}

#if canImport(UIKit)
private extension Haptics.ImpactStyle { var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
    switch self { case .light: .light; case .medium: .medium; case .heavy: .heavy; case .soft: .soft; case .rigid: .rigid }
} }

private extension Haptics.NotificationType { var uiType: UINotificationFeedbackGenerator.FeedbackType {
    switch self { case .success: .success; case .warning: .warning; case .error: .error }
} }
#endif
