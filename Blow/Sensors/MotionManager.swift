import CoreMotion
import UIKit

/// Turns device motion into what a real flame would do on screen:
/// it stays upright in the world when the phone tilts, and lags behind when the phone moves.
@MainActor
final class MotionManager {
    /// Target lean of every flame, in radians. + = tip to the right of the screen.
    private(set) var lean: Float = 0
    /// Phone lying screen-down (used for the wish on non-folding iPhones).
    private(set) var faceDown = false

    private let manager = CMMotionManager()
    private var orientation: UIInterfaceOrientation = .portrait
    private var frame = 0

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.handle(motion)
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        lean = 0
        faceDown = false
    }

    private func handle(_ m: CMDeviceMotion) {
        frame += 1
        if frame % 30 == 1 { refreshOrientation() }

        let g = toScreen(m.gravity.x, m.gravity.y)
        let a = toScreen(m.userAcceleration.x, m.userAcceleration.y)

        // tilt: flame points opposite to gravity as seen on screen
        let mag = hypot(g.x, g.y)
        var tilt = mag > 0.12 ? -atan2(g.x, g.y) : 0
        tilt *= min(1, mag / 0.45)
        tilt = tilt.clamped(-1.1, 1.1)

        // inertia: moving the phone right makes the flame trail left
        let inertia = (-a.x * 1.6).clamped(-0.9, 0.9)

        lean = Float((tilt + inertia).clamped(-1.3, 1.3))
        faceDown = m.gravity.z > 0.85
    }

    /// Device axes → screen axes (x right, y down) for the current interface orientation.
    private func toScreen(_ x: Double, _ y: Double) -> (x: Double, y: Double) {
        switch orientation {
        case .landscapeRight: return (-y, -x)
        case .landscapeLeft: return (y, x)
        case .portraitUpsideDown: return (-x, y)
        default: return (x, -y)
        }
    }

    private func refreshOrientation() {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        if let o = scene?.interfaceOrientation, o != .unknown { orientation = o }
    }
}

@MainActor
enum Haptics {
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notify = UINotificationFeedbackGenerator()

    static func prepare() { light.prepare(); medium.prepare(); soft.prepare() }
    static func tap() { light.impactOccurred() }
    static func land(final: Bool) { (final ? medium : light).impactOccurred(intensity: final ? 1 : 0.7) }
    static func puff() { soft.impactOccurred(intensity: 0.8) }
    static func success() { notify.notificationOccurred(.success) }
}
