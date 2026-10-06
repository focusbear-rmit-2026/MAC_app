import Foundation

/// A throwaway defaults suite for one test.
///
/// App-hosted tests run inside the app, on the developer's Mac (the CI runner is self-hosted), so
/// `UserDefaults.standard` and the FBHelper shared suite are the user's real ones. Tests that touch
/// defaults use one of these instead and call `destroy()` in tearDown.
final class IsolatedDefaults {
    static let suitePrefix = "io.focusbear.tests."

    let suiteName: String
    let defaults: UserDefaults

    init() {
        suiteName = Self.suitePrefix + UUID().uuidString
        defaults = UserDefaults(suiteName: suiteName)!
    }

    /// Empties the suite. cfprefsd still leaves a 42-byte empty plist behind, whatever the test does.
    func destroy() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
