//
//  AccountSignUpUITests.swift
//  Focus BearUITests
//
//  The first test of a run (XCTest runs classes in name order): a first launch on a new Mac, the
//  welcome onboarding, and a new internaltest account created through the real sign-up form. The
//  rest of the run signs in with that account.
//

import XCTest

final class AccountSignUpUITests: FocusBearUITestCase {
    /// The step indicator only shows on the distraction-blocking steps, which come after sign-up, so
    /// it is checked here rather than with the other onboarding names (English run).
    func testOnboardingCreatesAnAccount() throws {
        try signUpThroughOnboarding(atDistractionBlocking: checkStepProgressIsAnnounced)
    }

    private static let progressName = "Onboarding progress"
    private static let progressValuePrefix = "Step "

    private func checkStepProgressIsAnnounced() {
        let progress = app.staticTexts.matching(NSPredicate(format: "label == %@", Self.progressName)).firstMatch
        let value = progress.exists ? progress.value as? String ?? "" : "(missing)"
        guard !value.hasPrefix(Self.progressValuePrefix) else { return }
        XCTFail("“\(Self.progressName)” reads “\(value)”, not “Step N of 3, …”")
    }

    func testBackReturnsToThePreviousOnboardingStep() {
        app.launchArguments = [UITestContract.LaunchArgument.uiTest,
                               UITestContract.LaunchArgument.reset,
                               UITestContract.LaunchArgument.freshInstall]
        launchIsolated()
        expectOnboardingStep(OnboardingStep.welcome, timeout: Self.firstLaunchTimeout)
        advanceOnboarding(with: UITestContract.Identifier.Onboarding.welcomeContinueButton, to: OnboardingStep.welcomeAdhd)
        tap(element(UITestContract.Identifier.Onboarding.backButton))
        expectOnboardingStep(OnboardingStep.welcome)
    }
}
