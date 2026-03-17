import XCTest
@testable import DynamicNotch

@MainActor
final class LockScreenManagerIntegrationTests: XCTestCase {
    func testLockAndUnlockTransitionsPlayExpectedSounds() async {
        let service = FakeLockScreenMonitoringService()
        let soundPlayer = FakeLockScreenSoundPlayer()
        let manager = LockScreenManager(
            service: service,
            soundPlayer: soundPlayer,
            unlockCollapseDelay: 0.05,
            idleResetDelay: 0.05
        )

        manager.startMonitoring()

        service.publish(isLocked: true)
        service.publish(isLocked: true)
        service.publish(isLocked: false)
        service.publish(isLocked: false)

        await assertEventually(timeout: 0.2) {
            await MainActor.run {
                soundPlayer.playedSounds == [.lock, .unlock] &&
                !manager.isLocked &&
                !manager.isLockIdle
            }
        }

        await assertEventually(timeout: 0.2) {
            await MainActor.run {
                manager.isLockIdle && manager.event == .stopped
            }
        }
    }
}
