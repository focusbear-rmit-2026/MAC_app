//
//  AppDelegate+UITestSupport.swift
//  Focus Bear
//
//  The UI-test launch modes (docs/ui-tests.md). Every entry point is a no-op unless the build carries
//  the isolated `.uitests` bundle id, so the defaults and Application Support folder these touch are
//  the test app's own — never the installed app's — and its credentials live only in memory
//  (`LogicTestHost.CredentialsStore`). The call sites in AppDelegate are one line each; the logic and
//  the reasons live here.
//

import Auth0
import Cocoa

extension AppDelegate {
    private static let uiTestSignInTimeoutSeconds = 30.0

    /// True once the main window has been surfaced for a test, so the repeating `backgroundThread`
    /// tick doesn't re-present it.
    private static var didPresentMainWindowForUITest = false

    private var isUITestSkippingOnboarding: Bool {
        UITestHost.isEnabled && UITestHost.has(UITestContract.LaunchArgument.skipOnboarding)
    }

    /// `--uiTestReset`: start from a logged-out, never-configured test app. Wiping the whole defaults
    /// domain is only acceptable because `isEnabled` guarantees it is the `.uitests` one.
    func applyUITestResetIfNeeded() {
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.reset),
              let domain = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: domain)
        sharedDefaults?.removePersistentDomain(forName: fbSharedDefaultsSuiteName)
        // A developer-signed UI-test build encrypts; its sealed values must not outlive the reset either.
        SecureStore.shared.eraseAllData()
        // First run done, so a fresh CI runner goes straight to sign-in — unless the test is about
        // the welcome onboarding a new Mac gets.
        guard !UITestHost.has(UITestContract.LaunchArgument.freshInstall) else { return }
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
    }

    /// Signs the test app in with the account CI provides. Credentials are kept in memory only, so
    /// this runs on every signed-in launch.
    ///
    /// Blocks its caller: launch reads `canRenew()` straight after this to choose between the login
    /// screen and the signed-in app. Called from the config-fetch completion, which is off the main
    /// thread, so the wait never stalls the UI. That completion runs on `URLSession.shared`'s delegate
    /// queue, so the request uses a session of its own: on the shared one its reply queued behind the
    /// blocked caller, and every launch waited out the timeout and came up signed out.
    func signInForUITestIfRequested() {
        let environment = ProcessInfo.processInfo.environment
        // Only launches XCUITest made: the app's own relaunch after logging out inherits the
        // environment but not the arguments, and must come back logged out.
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest),
              let email = environment[UITestContract.Environment.email], UITestContract.TestAccount.isAllowed(email: email),
              let password = environment[UITestContract.Environment.password], !password.isEmpty else { return }
        if let cached = UITestCredentialsCache.credentials(for: email), credentialsManager.store(credentials: cached) {
            markSignedInForUITest()
            return
        }
        let finished = DispatchSemaphore(value: 0)
        PasswordSignIn.request(email: email, password: password, session: URLSession(configuration: .ephemeral)).start { result in
            switch result {
            case .success(let credentials):
                _ = self.credentialsManager.store(credentials: credentials)
                UITestCredentialsCache.save(credentials, for: email)
                self.markSignedInForUITest()
            case .failure(let error):
                addLog(text: "UITestHost: sign-in failed — \(error.localizedDescription)")
            }
            finished.signal()
        }
        if finished.wait(timeout: .now() + Self.uiTestSignInTimeoutSeconds) == .timedOut {
            addLog(text: "UITestHost: sign-in timed out")
        }
    }

    private func markSignedInForUITest() {
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
    }

    /// `--uiTestSkipOnboarding`: take the already-onboarded path, skipping the wizard and its system
    /// permission prompts. Returns true when it handled the launch; the caller then returns.
    ///
    /// It does not show the main window: the routine schedule hasn't loaded yet at this point, and the
    /// Day Plan reads it. `presentMainWindowForUITest` does that once settings have loaded (`runUITestLaunchHooks`).
    func handleUITestSkipOnboardingIfNeeded() -> Bool {
        guard isUITestSkippingOnboarding else { return false }
        UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
        // Every test launch resets the settings, so the once-per-install clipboard check for an AuDHD
        // retest code ran on every launch — and with such a link on the Mac's clipboard, its results
        // window covered the app after each routine. A test launch never reads the clipboard for it.
        UserDefaults.standard.set(true, forKey: AudhdResults.clipboardCheckedDefaultsKey)
        needToCheckEmailVerification = false
        getUserSubscriptionInfo()
        closeSplashWindow()
        return true
    }

    /// What a UI test launch asks for, once settings have loaded: run on the first chance after they
    /// load and again on every background tick.
    func runUITestLaunchHooks() {
        presentMainWindowForUITest()
        applyUITestLaunchSettingsIfRequested()
        // Before the screens: joining a class session moves the main window, which the popover anchors to.
        #if DEBUG
        UITestManagedSafetyFixture.startTeacherSessionIfRequested()
        #endif
        presentScreenForUITestIfRequested()
        UITestBlockingFixture.applyIfRequested()
        UITestEventsProbe.sendIfRequested()
        retryPresentingScreenSoonIfNeeded()
    }

    /// A screen that couldn't be shown yet (the popover needs the main window up and the app active)
    /// is tried again in a moment, not on the next five-second tick, which every such test waited for.
    private func retryPresentingScreenSoonIfNeeded() {
        guard UITestHost.isEnabled, !Self.didPresentScreenForUITest, Self.quickRetriesLeft > 0,
              ProcessInfo.processInfo.environment[UITestContract.Environment.presentScreen] != nil else { return }
        Self.quickRetriesLeft -= 1
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.quickRetryInterval) {
            self.presentScreenForUITestIfRequested()
            self.retryPresentingScreenSoonIfNeeded()
        }
    }

    private static var quickRetriesLeft = 50
    private static let quickRetryInterval: TimeInterval = 0.1

    /// An account with no routine due legitimately gets no main window, so a test couldn't reach
    /// anything. Surface it once, at the normal windowed size, after the schedule has loaded. A routine
    /// that is due still shows — the routine tests rely on it.
    func presentMainWindowForUITest() {
        guard isUITestSkippingOnboarding, !Self.didPresentMainWindowForUITest else { return }
        Self.didPresentMainWindowForUITest = true
        mainWindowControllerObj?.showWindow(nil)
        leftMenuVcObj?.showHabitsView()
        mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - Screens on demand

    /// Settings a test launch asks for through its environment, applied on every launch tick once
    /// settings have loaded — a later settings fetch would otherwise put the account's values back.
    /// This launch only: none of them is saved to the server.
    func applyUITestLaunchSettingsIfRequested() {
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest) else { return }
        typealias Environment = UITestContract.Environment
        let environment = ProcessInfo.processInfo.environment
        if environment[Environment.easySkip] == Environment.disabledValue {
            SettingsManagerObject.isEasySkipEnabled = false
        }
        if environment[Environment.focusMusic] == Environment.focusMusicOff, SettingsManagerObject.focusMusicAutoStart != .off {
            SettingsManagerObject.focusMusicAutoStart = .off
        }
        if environment[Environment.routineEndsOnDayPlan] == Environment.enabledValue {
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsPomodoroModeEnabled)
            SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled = false
        }
        if environment[Environment.cleanAccount] == Environment.enabledValue, !Self.didStartAccountCleanup {
            Self.didStartAccountCleanup = true
            UITestAccountCleanup.run()
        }
    }

    private static var didStartAccountCleanup = false

    /// From the first moment of a test launch: a logged-out screen needs presses too.
    func listenForUITestCommandsIfRequested() {
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest) else { return }
        UITestAccountCleanup.listenForRequests()
        UITestPress.listenForRequests()
        UITestFocusQuery.listenForRequests()
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name(UITestContract.Command.presentScreen),
                                                            object: nil, queue: .main) { [weak self] note in
            guard let raw = note.object as? String else { return }
            self?.presentScreenForUITest(named: raw)
        }
    }

    /// The screens the accessibility suites could not otherwise reach — they appear when a break falls
    /// due, during a meeting, or mid-routine. Shown once, through the same calls the real triggers
    /// make. Test build and `--uiTest` launches only.
    func presentScreenForUITestIfRequested() {
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest), !Self.didPresentScreenForUITest,
              let raw = ProcessInfo.processInfo.environment[UITestContract.Environment.presentScreen] else { return }
        Self.didPresentScreenForUITest = presentScreenForUITest(named: raw)
    }

    /// Shows the screen a `PresentedScreen` or sessions `Screen` raw value names. False when it
    /// couldn't yet (the popover needs the main window up) or the name is unknown.
    @discardableResult
    private func presentScreenForUITest(named raw: String) -> Bool {
        if let sessionsScreen = SessionsScreen(rawValue: raw) {
            addLog(text: "UITestHost: presenting \(raw)")
            presentSessionsScreenForUITest(sessionsScreen)
            return true
        }
        guard let screen = UITestContract.PresentedScreen(rawValue: raw) else { return false }
        addLog(text: "UITestHost: presenting \(raw)")
        switch screen {
        case .microBreak, .meetingBreak:
            // The tail of habitsVc.timeToStartBreakActivities, once it has decided a break is due —
            // which it only does with at least one break activity, so give a new account one.
            if arrAllbreakActivities.isEmpty { arrAllbreakActivities = [uiTestBreakActivity()] }
            getHabitsVcObject().reFillBreakActivitiesArray()
            isBreakActivityShowingWhileMeeting = screen == .meetingBreak
            showBreakWarningWindow()
            currentState = ._MICRO_BREAK_
            currentAction = ._START_
        case .nonTimerActivity:
            presentNonTimerActivityForUITest()
        case .menuBarPopover:
            // Retried on the next tick until the main window is on screen to anchor the popover.
            return presentMenuPopoverForUITest()
        case .dayPlanRoutine:
            seedDayPlanRoutineForUITest()
        case .offlinePopup:
            showPopUpOfflineWindow()
        }
        return true
    }

    private static var didPresentScreenForUITest = false
    private typealias RoutineFixture = UITestContract.RoutineFixture

    /// A one-habit morning routine whose habit has a completion requirement instead of a timer —
    /// in memory only, never saved.
    private func presentNonTimerActivityForUITest() {
        let activity = uiTestHabit(name: RoutineFixture.untimedHabitName, seconds: RoutineFixture.untimedHabitSeconds,
                                   requirement: RoutineFixture.untimedHabitRequirement, useTimer: false)
        arrFilteredMorningHabits = [activity]
        currentHabitIndex = 0
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
        let player = getHabitsVcObject()
        player.removeSubViews()
        player.habitsView.addSubview(timerViewcontrollerObj!.view)
        player.habitsView.addConstraints(subView: timerViewcontrollerObj!.view)
        mainViewControllerObj?.showHabitsView()
        timerViewcontrollerObj?.tryStartTimerHabit(durationSeconds: activity.durationSeconds, name: activity.name,
                                                  currentHabit: activity, currentTimerValue: 0, shouldUpdateDeviceButton: false)
    }

    /// The real popover, anchored to the main window instead of the menu-bar icon: the icon can be
    /// hidden by a crowded menu bar (it was, off screen, on the developer's Mac), and a popover pinned
    /// to it opens off screen too.
    /// Returns whether it could: NSPopover raises if its anchor isn't in a visible window yet, and a
    /// transient popover shown before the app is active closes the moment it becomes active. A fresh
    /// test account has the menu as a window (the setting's default); the tests are about the
    /// popover, so this launch uses it.
    private func presentMenuPopoverForUITest() -> Bool {
        guard let window = mainWindowControllerObj?.window, window.isVisible, let anchor = window.contentView else { return false }
        guard NSApp.isActive else {
            NSApp.activate(ignoringOtherApps: true)
            return false
        }
        SettingsManagerObject.isMenuPopoverEnabled = true
        ensureMenuContentAttached()
        let top = NSRect(x: anchor.bounds.midX, y: anchor.bounds.maxY - 1, width: 1, height: 1)
        popover.show(relativeTo: top, of: anchor, preferredEdge: .minY)
        menuViewControllerObj?.view.window?.makeKey()
        return true
    }

    /// Today's evening routine becomes one timed and one untimed habit — in this process's routine
    /// list and in the test app's own copy of the settings JSON, which the Day Plan editors read. Both
    /// are replaced by the account's real (empty) routine on the next settings fetch; nothing is saved.
    private func seedDayPlanRoutineForUITest() {
        let timed = uiTestHabit(name: RoutineFixture.timedHabitName, seconds: RoutineFixture.timedHabitSeconds, requirement: "", useTimer: true)
        let untimed = uiTestHabit(name: RoutineFixture.untimedHabitName, seconds: RoutineFixture.untimedHabitSeconds,
                                  requirement: RoutineFixture.untimedHabitRequirement, useTimer: false)
        // Evening, because the morning routine is already over for most of the day and the Day Plan
        // only shows today's routines that are still ahead.
        arrAllDaysEveningHabits = [timed, untimed]
        let eveningStart = Date().addingTimeInterval(TimeInterval(RoutineFixture.eveningStartsInMinutes * 60))
        if Calendar.current.isDateInToday(eveningStart) {
            let start = Calendar.current.dateComponents([.hour, .minute], from: eveningStart)
            shutOffTime = Time(hour: start.hour ?? 0, minute: start.minute ?? 0, second: 0)
        }
        guard let json = SensitiveDefaults.string(forKey: kUserdefaultsSelectedJson),
              let root = (try? JSONSerialization.jsonObject(with: Data(json.utf8), options: [.mutableContainers])) as? NSMutableDictionary
        else { return }
        root[RoutineSettingsKey.eveningActivities] = [timed, untimed].map { habit -> [String: Any] in
            [RoutineSettingsKey.id: habit.id ?? "", RoutineSettingsKey.name: habit.name ?? "",
             RoutineSettingsKey.durationSeconds: habit.durationSeconds ?? 0,
             RoutineSettingsKey.completionRequirements: habit.completion_requirements,
             RoutineSettingsKey.daysOfWeek: [String]()]
        }
        if let data = try? JSONSerialization.data(withJSONObject: root) {
            SensitiveDefaults.set(String(decoding: data, as: UTF8.self), forKey: kUserdefaultsSelectedJson)
        }
    }

    private func uiTestBreakActivity() -> breakActivity {
        breakActivity(id: getUuid(), name: RoutineFixture.breakActivityName, durationSeconds: RoutineFixture.breakActivitySeconds,
                      IncludeInEveryBreak: false, urlsArray: [], logQuantity: false, choiceType: ._NONE_, choices: [],
                      logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [],
                      isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "", activity_sequence_id: "",
                      take_notes: "", text_instructions: "", imgUrls: [], completion_requirements: "",
                      useTimer: true, checkList: [])
    }

    private func uiTestHabit(name: String, seconds: Int, requirement: String, useTimer: Bool) -> habit {
        habit(id: getUuid(), name: name, durationSeconds: seconds, urlsArray: [], logQuantity: false,
              logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "",
              activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false,
              days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: requirement,
              useTimer: useTimer, checkList: [], tutorial: "")
    }
}

// MARK: - Focus session, break and routine screens (RegressionBreaksUITests, RegressionRoutineUITests)

private typealias SessionsScreen = UITestContract.Identifier.SessionsRegression.Screen
private typealias SessionsFixture = UITestContract.Identifier.SessionsRegression.Fixture

extension AppDelegate {
    /// Each builds its routine or break from fixture habits held in this process only — never saved,
    /// and replaced by the account's own on the next settings fetch.
    fileprivate func presentSessionsScreenForUITest(_ screen: SessionsScreen) {
        switch screen {
        case .timedHabit:
            presentRoutineForUITest([sessionsTimedHabit(seconds: SessionsFixture.timedHabitSeconds)])
        case .shortTimedHabit:
            presentRoutineForUITest([sessionsTimedHabit(seconds: SessionsFixture.shortTimedHabitSeconds)])
        case .habitWithNotes:
            var notesHabit = sessionsUntimedHabit()
            notesHabit.take_notes = DURING_ACTIVITY
            presentRoutineForUITest([notesHabit])
        case .habitWithLogQuantity:
            // A question with no range is answered by typing; one with a range, by a slider.
            presentRoutineForUITest([sessionsQuantityHabit(minimum: 0, maximum: 0)])
        case .habitWithSliderQuantity:
            presentRoutineForUITest([sessionsQuantityHabit(minimum: SessionsFixture.sliderMinimum,
                                                           maximum: SessionsFixture.sliderMaximum)])
        case .twoHabitRoutine:
            presentRoutineForUITest(sessionsTwoHabits())
        case .rememberNextHabit:
            presentRememberNextHabitForUITest(sessionsTwoHabits())
        case .untimedBreak:
            presentBreakWarningForUITest(activities: [sessionsUntimedBreakActivity()])
        case .breakWithNoActivities:
            presentBreakWarningForUITest(activities: [])
        case .allowedAppHabitRoutine:
            var allowedAppHabit = sessionsUntimedHabit()
            allowedAppHabit.name = SessionsFixture.allowedAppHabitName
            allowedAppHabit.allowApps = [SessionsFixture.allowedAppName]
            presentRoutineForUITest([allowedAppHabit])
        }
    }

    /// A morning routine playing its first habit — the path `habitsVc.changeMorningHabit` takes.
    private func presentRoutineForUITest(_ habits: [habit]) {
        guard let first = habits.first, let timer = timerViewcontrollerObj else { return }
        arrFilteredMorningHabits = habits
        currentHabitIndex = 0
        currentState = ._MORNING_HABIT_
        currentAction = ._INPROGRESS_
        let player = getHabitsVcObject()
        player.removeSubViews()
        player.showCloseButtons()
        player.habitsView.addSubview(timer.view)
        player.habitsView.addConstraints(subView: timer.view)
        mainViewControllerObj?.showHabitsView()
        timer.tryStartTimerHabit(durationSeconds: first.durationSeconds, name: first.name, currentHabit: first,
                                 currentTimerValue: 0, shouldUpdateDeviceButton: false)
    }

    /// The first habit done and "What comes next?" asked — what `activityCompletionVc.btnMainClicked`
    /// shows when it picks the remember-next prompt, which it otherwise does at random.
    private func presentRememberNextHabitForUITest(_ habits: [habit]) {
        guard habits.count > 1, let completion = activityCompletionVcObj else { return }
        arrFilteredMorningHabits = habits
        currentHabitIndex = 0
        currentState = ._MORNING_HABIT_
        currentAction = ._END_
        let player = getHabitsVcObject()
        player.removeSubViews()
        player.showCloseButtons()
        player.habitsView.addSubview(completion.view)
        player.habitsView.addConstraints(subView: completion.view)
        mainViewControllerObj?.showHabitsView()
        completion.lastHabitIndex = 0
        completion.isSequenceFinished = false
        completion.randomIntToRememberNextHabit = 0
        completion.boxBg.isHidden = true
        let rememberNext = getRememberNextHabitVcObj()
        rememberNext.nextHabitIndex = 1
        completion.view.addSubview(rememberNext.view)
        completion.view.addConstraints(subView: rememberNext.view)
        rememberNext.resetData()
    }

    /// The micro-break warning over `activities` — the tail of `habitsVc.timeToStartBreakActivities`,
    /// like the `.microBreak` screen, but with the break list replaced rather than only filled when empty.
    private func presentBreakWarningForUITest(activities: [breakActivity]) {
        arrAllbreakActivities = activities
        // Refilling from nothing can switch office mode off and save that to the account, so an
        // empty break is emptied directly.
        if activities.isEmpty {
            arrFinalBreakActivities.removeAll()
        } else {
            getHabitsVcObject().reFillBreakActivitiesArray()
        }
        isBreakActivityShowingWhileMeeting = false
        showBreakWarningWindow()
        currentState = ._MICRO_BREAK_
        currentAction = ._START_
    }

    private func sessionsTwoHabits() -> [habit] {
        [sessionsUntimedHabit(), sessionsTimedHabit(seconds: SessionsFixture.timedHabitSeconds)]
    }

    private func sessionsTimedHabit(seconds: Int) -> habit {
        uiTestHabit(name: SessionsFixture.timedHabitName, seconds: seconds, requirement: "", useTimer: true)
    }

    private func sessionsUntimedHabit() -> habit {
        uiTestHabit(name: SessionsFixture.untimedHabitName, seconds: SessionsFixture.untimedHabitSeconds,
                    requirement: SessionsFixture.untimedHabitRequirement, useTimer: false)
    }

    private func sessionsQuantityHabit(minimum: Int, maximum: Int) -> habit {
        var quantityHabit = sessionsUntimedHabit()
        quantityHabit.logQuantity = true
        quantityHabit.logQuantityQuestion = SessionsFixture.quantityQuestion
        quantityHabit.logQuantityQuestions = [quantityQuestion(id: getUuid(), minValue: minimum, maxValue: maximum,
                                                               question: SessionsFixture.quantityQuestion, logQuantityType: "",
                                                               minValueDescription: "", maxValueDescription: "")]
        return quantityHabit
    }

    private func sessionsUntimedBreakActivity() -> breakActivity {
        breakActivity(id: getUuid(), name: SessionsFixture.untimedBreakName, durationSeconds: SessionsFixture.untimedBreakSeconds,
                      IncludeInEveryBreak: false, urlsArray: [], logQuantity: false, choiceType: ._NONE_, choices: [],
                      logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [],
                      isOfficeFriendly: true, allowedFocusMode: "", logQuantityType: "", activity_sequence_id: "",
                      take_notes: "", text_instructions: "", imgUrls: [], completion_requirements: SessionsFixture.untimedBreakRequirement,
                      useTimer: false, checkList: [])
    }
}

/// Deletes what earlier test runs left on the test account — to-dos and projects titled exactly as
/// the tests name them (`UITestContract.TestTitle`) — so leftovers can't change what later tests see
/// (an auto-picked goal, rows pushing a section below the fold). Reached only through
/// `applyUITestLaunchSettingsIfRequested`: the test build, launched by XCUITest, with
/// FOCUSBEAR_UITEST_CLEAN_ACCOUNT=1.
enum UITestAccountCleanup {
    /// Each search returns one page; enough rounds for a few hundred leftovers.
    private static let searchRounds = 20
    private typealias TestTitle = UITestContract.TestTitle

    /// Only one sweep at a time; a request arriving mid-sweep is answered when that one finishes.
    private static var isRunning = false
    private static var pendingRequestIds = [String]()

    static func run(requestId: String? = nil) {
        if let requestId { pendingRequestIds.append(requestId) }
        guard !isRunning else { return }
        isRunning = true
        addLog(text: "UITestAccountCleanup: started")
        deleteToDos(round: 0, deleted: 0)
    }

    /// A test's clean-up asks the running app instead of relaunching it into a sweep, which cost
    /// about five seconds a test. Called only from the gated launch hook (test build, `--uiTest`).
    static func listenForRequests() {
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name(UITestContract.Command.cleanAccountNow),
                                                            object: nil, queue: .main) { note in
            guard let requestId = note.object as? String, !requestId.isEmpty else { return }
            run(requestId: requestId)
        }
    }

    private static func deleteToDos(round: Int, deleted: Int) {
        allApiObject.searchToDoTasks(title: TestTitle.prefix) { tasks in
            let leftovers = (tasks ?? []).filter { TestTitle.matches($0.title) }
            guard !leftovers.isEmpty, round < searchRounds else { return deleteProjects(toDosDeleted: deleted) }
            let requests = DispatchGroup()
            for task in leftovers {
                requests.enter()
                addLog(text: "UITestAccountCleanup: deleting to-do “\(task.title)”")
                allApiObject.deleteToDo(id: task.id) { _ in requests.leave() }
            }
            requests.notify(queue: .main) { deleteToDos(round: round + 1, deleted: deleted + leftovers.count) }
        }
    }

    private static func deleteProjects(toDosDeleted: Int) {
        allApiObject.getProjectsList { projects in
            let leftovers: [(id: String, name: String)] = (projects ?? []).compactMap { project in
                guard let id = project["id"] as? String, let name = project["name"] as? String, TestTitle.matches(name) else { return nil }
                return (id, name)
            }
            let requests = DispatchGroup()
            for project in leftovers {
                requests.enter()
                addLog(text: "UITestAccountCleanup: deleting project “\(project.name)”")
                allApiObject.deleteProject(id: project.id) { _ in requests.leave() }
            }
            requests.notify(queue: .main) { finish(toDos: toDosDeleted, projects: leftovers.count) }
        }
    }

    private static func finish(toDos: Int, projects: Int) {
        addLog(text: "UITestAccountCleanup: deleted \(toDos) to-dos and \(projects) projects")
        let answered = pendingRequestIds.map { $0 + ":" }.joined()
        pendingRequestIds.removeAll()
        isRunning = false
        appdelegate?.statusbutton?.setAccessibilityValue(UITestContract.Environment.accountCleanupDonePrefix + answered + "\(toDos),\(projects)")
    }
}

/// Posts one analytics event to whichever events stack this launch selected (`EventsEndpoint`) and
/// reports the HTTP status on the status item, so a UI test can check the stack accepts the Mac's
/// payload end to end. Test build and `--uiTest` launches only.
///
/// It goes straight to `EventBuffer`, past `captureEventEndpoint`'s CI guard and `capturePosthog`'s
/// internaltest filter: the test build otherwise sends no analytics at all, and this one event to the
/// isolated test account is what the test is about.
enum UITestEventsProbe {
    private static var hasSent = false

    /// Called on every launch tick; waits for the access token, which arrives after settings load.
    static func sendIfRequested() {
        typealias Environment = UITestContract.Environment
        guard UITestHost.isEnabled, UITestHost.has(UITestContract.LaunchArgument.uiTest), !hasSent,
              ProcessInfo.processInfo.environment[Environment.eventsProbe] == Environment.enabledValue,
              let email = ProcessInfo.processInfo.environment[Environment.email],
              UITestContract.TestAccount.isAllowed(email: email),
              appdelegate?.credential?.accessToken != nil else { return }
        hasSent = true
        let stack = EventsEndpoint.current.rawValue
        let event = TrackEventPayload.make(event: UITestContract.EventsProbe.eventType, metadata: [:],
                                           userId: appdelegate?.user?.userId ?? globalUUID, userName: currentUserName,
                                           appVersion: getAppVersionInString())
        addLog(text: "UITestEventsProbe: posting \(UITestContract.EventsProbe.eventType) to the \(stack) events stack")
        EventBuffer.shared.sendNow(event) { status in
            let reply = status.map(String.init) ?? UITestContract.EventsProbe.noReply
            addLog(text: "UITestEventsProbe: the \(stack) events stack replied \(reply)")
            DispatchQueue.main.async {
                let separator = String(UITestContract.EventsProbe.fieldSeparator)
                appdelegate?.statusbutton?.setAccessibilityValue(Environment.eventsProbeDonePrefix + stack + separator + reply)
            }
        }
    }
}

/// Presses a control for a UI test the way VoiceOver does (`accessibilityPerformPress`), found by its
/// accessibility identifier in the app's own windows. A synthesized mouse click costs XCUITest about
/// half a second; this costs a few milliseconds and needs no accessibility grant for the test runner.
/// Only through the gated launch hook (test build, `--uiTest`).
enum UITestPress {
    private typealias Command = UITestContract.Command
    /// Deep enough for SwiftUI's nesting inside a split view, bounded so a cycle can't hang the app.
    private static let depthLimit = 40

    static func listenForRequests() {
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name(Command.press), object: nil, queue: .main) { note in
            guard let request = note.object as? String else { return }
            let fields = request.split(separator: Command.requestFieldSeparator).map(String.init)
            guard fields.count == 6, let x = Double(fields[2]), let y = Double(fields[3]),
                  let action = UITestContract.PressAction(rawValue: fields[4]), let sentAt = Double(fields[5]) else { return }
            // Held up (an alert's own event loop), it arrives after the test has clicked instead.
            guard Date().timeIntervalSince1970 - sentAt < Command.pressRequestLifetime else {
                return addLog(text: "UITestPress: \(fields[1]): arrived too late, ignored")
            }
            let resolution = resolve(action, onIdentifier: fields[1], at: CGPoint(x: x, y: y))
            let outcome: UITestContract.PressOutcome
            switch resolution {
            case .failed(let failure): outcome = failure
            case .ready: outcome = .pressed
            }
            if outcome != .pressed { addLog(text: "UITestPress: \(fields[1]) at (\(x), \(y)): \(outcome.rawValue)") }
            appdelegate?.statusbutton?.setAccessibilityValue(Command.pressDonePrefix + fields[0] + ":" + outcome.rawValue)
            // Answered first, acted on after: a press that opens an alert or a menu runs its own event
            // loop and would otherwise hold the answer until it closed.
            if case .ready(let act) = resolution { DispatchQueue.main.async(execute: act) }
        }
    }

    private enum Resolution {
        case ready(() -> Void)
        case failed(UITestContract.PressOutcome)
    }

    /// The identifier alone can match several rows' controls; the point picks the one the test saw.
    private static func resolve(_ action: UITestContract.PressAction, onIdentifier identifier: String,
                                at topLeftPoint: CGPoint) -> Resolution {
        let point = cocoaScreenPoint(fromTopLeft: topLeftPoint)
        switch action {
        case .select:
            guard let cell = view(identified: identifier, at: point) else { return .failed(.missing) }
            return .ready { selectRow(containing: cell) }
        case .focus:
            // An AppKit field inside SwiftUI (NSViewRepresentable) isn't reached through the
            // accessibility children; its view is, and focusing a view is making it first responder.
            if let field = view(identified: identifier, at: point) {
                return .ready { field.window?.makeFirstResponder(field) }
            }
            return element(identified: identifier, at: point).map { control in { control.setAccessibilityFocused?(true) } }
        case .press:
            let found = element(identified: identifier, at: point)
            if case .ready = found { return found.map { control in { _ = control.accessibilityPerformPress?() } } }
            // An AppKit button the accessibility children don't reach (in a stack or table) is pressed
            // as Space presses it. Not through its accessibilityPerformPress: a button that tracks
            // the mouse itself (settingsMouseDownEffectButton) acted on it and still returned false.
            guard let button = view(identified: identifier, at: point) as? NSButton, button.isEnabled else { return found.failure }
            return .ready { button.performClick(nil) }
        }
    }

    /// The one accessibility element with `identifier` under `point`.
    private static func element(identified identifier: String, at point: CGPoint) -> ElementLookup {
        var matches = [AnyObject]()
        // Front to back, panels and popovers included (orderedWindows leaves them out): a sheet's
        // control before the window under it.
        for window in NSApp.windows.filter(\.isVisible).sorted(by: { $0.orderedIndex < $1.orderedIndex }) {
            collect(identifier, in: window, depth: 0, into: &matches)
            if !matches.isEmpty { break }
        }
        guard !matches.isEmpty else { return .failed(.missing) }
        let underPoint = matches.filter { frame(of: $0).contains(point) }
        guard underPoint.count == 1, let control = underPoint.first else {
            addLog(text: "UITestPress: \(matches.count) match(es) for \(identifier), frames \(matches.map(frame(of:))), point \(point)")
            return .failed(.ambiguous)
        }
        return .ready(control)
    }

    private enum ElementLookup {
        case ready(AnyObject)
        case failed(UITestContract.PressOutcome)

        var failure: Resolution {
            if case .failed(let outcome) = self { return .failed(outcome) }
            return .failed(.notPressable)
        }

        func map(_ act: (AnyObject) -> () -> Void) -> Resolution {
            switch self {
            case .ready(let control): return .ready(act(control))
            case .failed(let outcome): return .failed(outcome)
            }
        }
    }

    /// Through the Objective-C accessibility methods, which every element answers, AppKit's or
    /// SwiftUI's; SwiftUI's own elements don't all adopt the Swift protocol.
    private static func collect(_ identifier: String, in element: AnyObject, depth: Int, into matches: inout [AnyObject]) {
        guard depth < depthLimit else { return }
        if element.accessibilityIdentifier?() == identifier { matches.append(element) }
        for child in element.accessibilityChildren?() ?? [] {
            collect(identifier, in: child as AnyObject, depth: depth + 1, into: &matches)
        }
    }

    /// Selecting through the table, as a click on the row does, so its delegate hears of it.
    private static func selectRow(containing view: NSView) -> Bool {
        var ancestor = view.superview
        while let current = ancestor, !(current is NSTableView) { ancestor = current.superview }
        guard let table = ancestor as? NSTableView else { return false }
        let row = table.row(for: view)
        guard row >= 0, table.delegate?.tableView?(table, shouldSelectRow: row) ?? true else { return false }
        table.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        return table.selectedRow == row
    }

    private static func view(identified identifier: String, at point: CGPoint) -> NSView? {
        for window in NSApp.windows where window.isVisible {
            guard let root = window.contentView?.superview ?? window.contentView else { continue }
            if let found = descendant(of: root, identified: identifier, at: point, depth: 0) { return found }
        }
        return nil
    }

    private static func descendant(of view: NSView, identified identifier: String, at point: CGPoint, depth: Int) -> NSView? {
        guard depth < depthLimit, !view.isHiddenOrHasHiddenAncestor else { return nil }
        if view.accessibilityIdentifier() == identifier, let window = view.window,
           window.convertToScreen(view.convert(view.bounds, to: nil)).contains(point) { return view }
        for subview in view.subviews {
            if let found = descendant(of: subview, identified: identifier, at: point, depth: depth + 1) { return found }
        }
        return nil
    }

    private static func frame(of element: AnyObject) -> CGRect {
        element.accessibilityFrame?() ?? .zero
    }

    /// XCUITest frames have their origin at the top left of the main screen; AppKit's at the bottom left.
    private static func cocoaScreenPoint(fromTopLeft point: CGPoint) -> CGPoint {
        let mainScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        return CGPoint(x: point.x, y: mainScreenHeight - point.y)
    }
}

/// The test account's last sign-in, kept between launches so each test launch doesn't sign in over
/// the network again (1.5–2 s each, on the main thread). Test build only (`UITestHost`), in the
/// test app's own Application Support folder, readable by the user only; only for the email it was
/// made for, and only while the token has an hour or more to run.
enum UITestCredentialsCache {
    private static let fileName = "UITestCredentials.json"
    private static let minimumRemainingLifetime: TimeInterval = 60 * 60
    private static let ownerOnlyPermissions = 0o600

    private struct Entry: Codable {
        let email: String
        let credentials: Credentials
    }

    static func credentials(for email: String) -> Credentials? {
        guard UITestHost.isEnabled, let url = fileURL, let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(Entry.self, from: data), entry.email == email,
              entry.credentials.expiresIn.timeIntervalSinceNow > minimumRemainingLifetime else { return nil }
        return entry.credentials
    }

    static func save(_ credentials: Credentials, for email: String) {
        guard UITestHost.isEnabled, let url = fileURL,
              let data = try? JSONEncoder().encode(Entry(email: email, credentials: credentials)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard FileManager.default.createFile(atPath: url.path, contents: data,
                                             attributes: [.posixPermissions: ownerOnlyPermissions]) else { return }
    }

    private static var fileURL: URL? {
        guard let bundleId = Bundle.main.bundleIdentifier,
              let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        return support.appendingPathComponent(bundleId).appendingPathComponent(fileName)
    }
}

/// Answers which control has the keyboard focus (`UITestContract.Command.focusQuery`). Only through the
/// gated launch hook (test build, `--uiTest`).
enum UITestFocusQuery {
    private typealias Command = UITestContract.Command

    static func listenForRequests() {
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name(Command.focusQuery), object: nil, queue: .main) { note in
            guard let requestId = note.object as? String, !requestId.isEmpty else { return }
            appdelegate?.statusbutton?.setAccessibilityValue(Command.focusAnswerPrefix + requestId + ":" + focusedIdentifier())
        }
    }

    /// While a text field is edited, the window's first responder is its field editor, whose delegate
    /// is the field itself.
    private static func focusedIdentifier() -> String {
        let responder = NSApp.keyWindow?.firstResponder
        if let editor = responder as? NSTextView, editor.isFieldEditor, let field = editor.delegate as? NSView {
            return field.accessibilityIdentifier()
        }
        return (responder as? NSView)?.accessibilityIdentifier() ?? ""
    }
}
