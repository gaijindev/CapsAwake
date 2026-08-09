import CapsAwakeCore
import Foundation
import IOKit.pwr_mgt

@MainActor
final class PowerAssertionController {
    private let nullAssertion: IOPMAssertionID = 0
    private var systemAssertion: IOPMAssertionID = 0
    private var displayAssertion: IOPMAssertionID = 0

    private(set) var lastError: String?

    func apply(_ plan: AwakePlan) {
        lastError = nil
        if plan.preventSystemSleep {
            createSystemAssertionIfNeeded()
        } else {
            releaseSystemAssertion()
        }

        if plan.preventDisplaySleep {
            createDisplayAssertionIfNeeded()
        } else {
            releaseDisplayAssertion()
        }
    }

    func releaseAll() {
        releaseSystemAssertion()
        releaseDisplayAssertion()
    }

    private func createSystemAssertionIfNeeded() {
        guard systemAssertion == nullAssertion else { return }
        systemAssertion =
            createAssertion(
                type: kIOPMAssertPreventUserIdleSystemSleep as CFString,
                name: "CapsAwake keeps the Mac awake" as CFString,
                failureMessage: "CapsAwake could not prevent idle system sleep"
            ) ?? nullAssertion
    }

    private func createDisplayAssertionIfNeeded() {
        guard displayAssertion == nullAssertion else { return }
        displayAssertion =
            createAssertion(
                type: kIOPMAssertPreventUserIdleDisplaySleep as CFString,
                name: "CapsAwake keeps the display awake" as CFString,
                failureMessage: "CapsAwake could not prevent display sleep"
            ) ?? nullAssertion
    }

    private func releaseSystemAssertion() {
        releaseAssertion(&systemAssertion)
    }

    private func releaseDisplayAssertion() {
        releaseAssertion(&displayAssertion)
    }

    private func createAssertion(type: CFString, name: CFString, failureMessage: String) -> IOPMAssertionID? {
        var assertionID: IOPMAssertionID = nullAssertion
        let result = IOPMAssertionCreateWithName(
            type,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            name,
            &assertionID
        )
        guard result == kIOReturnSuccess else {
            lastError = "\(failureMessage) (code \(result))."
            return nil
        }
        return assertionID
    }

    private func releaseAssertion(_ assertion: inout IOPMAssertionID) {
        guard assertion != nullAssertion else { return }
        IOPMAssertionRelease(assertion)
        assertion = nullAssertion
    }
}
