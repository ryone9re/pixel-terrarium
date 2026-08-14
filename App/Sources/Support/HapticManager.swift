import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    private let generator = UINotificationFeedbackGenerator()

    private init() {
        generator.prepare()
    }

    func success() {
        generator.notificationOccurred(.success)
        generator.prepare()
    }
}
