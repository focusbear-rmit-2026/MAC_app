//
//  AppDelegate.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//


import Cocoa
import Sentry
import Sparkle
import ORSSerial
import Auth0
import TrueTime
import CoreMedia

/// Logic tests use the app as a bundle host, without starting a signed-in desktop session.
/// The dedicated scheme flag alone cannot change a normal app launch or a Release build.
enum LogicTestHost {
    static let HOST_ENVIRONMENT_KEY = "FOCUSBEAR_LOGIC_TEST_HOST"
    static let ENABLED_ENVIRONMENT_VALUE = "1"
    static let BUNDLE_IDENTIFIER_SUFFIX = ".logictests"
    static let SHIPPING_BUNDLE_IDENTIFIER = "com.App.EarnYourScreentime"
    static let BUNDLE_IDENTIFIER = SHIPPING_BUNDLE_IDENTIFIER + BUNDLE_IDENTIFIER_SUFFIX

    static func sharedDefaultsSuiteName(productionSuiteName: String, bundleIdentifier: String?) -> String {
        bundleIdentifier == BUNDLE_IDENTIFIER ? productionSuiteName + BUNDLE_IDENTIFIER_SUFFIX : productionSuiteName
    }

    static func shouldIsolate(environment: [String: String], hasXCTest: Bool, isDebug: Bool) -> Bool {
        // The independently installed runner preflight verifies this exact expression.
        isDebug && hasXCTest && environment["FOCUSBEAR_LOGIC_TEST_HOST"] == "1"
    }

    static func shouldPermitLaunch(environment: [String: String], bundleIdentifier: String?,
                                   hasXCTest: Bool, isDebug: Bool) -> Bool {
        let isIsolatedBundle = bundleIdentifier == BUNDLE_IDENTIFIER
        let requestsLogicHost = environment[HOST_ENVIRONMENT_KEY] == ENABLED_ENVIRONMENT_VALUE
        guard isIsolatedBundle || requestsLogicHost else { return true }
        return isIsolatedBundle && shouldIsolate(environment: environment, hasXCTest: hasXCTest, isDebug: isDebug)
    }

    static var isEnabled: Bool {
#if DEBUG
        return shouldIsolate(environment: ProcessInfo.processInfo.environment,
                             hasXCTest: NSClassFromString("XCTestCase") != nil, isDebug: true)
#else
        return false
#endif
    }

    static func loadBundledConfiguration() {
        guard let url = Bundle.main.url(forResource: "config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let configuration = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary else {
            preconditionFailure("Logic test host requires the bundled configuration")
        }
        currentLanguageCode = "en"
        configjson = configuration
        readConfigFile()
    }

    /// Credentials storage for the logic test host: in memory, never the login keychain.
    ///
    /// Every `AllApi` call asks `credentialsManager` for a token, and some test reaches one of them.
    /// The host is an ad-hoc build, and its designated requirement is a bare cdhash, so every CI run is
    /// a new binary to macOS: the developer got a "Focus Bear wants to use your confidential
    /// information" prompt per run on their own Mac (the self-hosted runner). Each "Always Allow" added
    /// another ACL entry — 24 CI cdhashes on the item by 2026-09-24. Tests have no business reading a
    /// person's real login.
    final class CredentialsStore: CredentialsStorage {
        private var entries: [String: Data] = [:]
        func getEntry(forKey key: String) -> Data? { entries[key] }
        func setEntry(_ data: Data, forKey key: String) -> Bool { entries[key] = data; return true }
        func deleteEntry(forKey key: String) -> Bool { entries[key] = nil; return true }
    }

    static func makeCredentialsManager() -> CredentialsManager {
        isEnabled
            ? CredentialsManager(authentication: Auth0.authentication(), storage: CredentialsStore())
            : CredentialsManager(authentication: Auth0.authentication())
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSPopoverDelegate, SPUUpdaterDelegate {
    static func main() {
#if DEBUG
        let isDebug = true
#else
        let isDebug = false
#endif
        // Refuse unsafe test launches before AppKit creates the delegate or loads the storyboard.
        guard LogicTestHost.shouldPermitLaunch(
            environment: ProcessInfo.processInfo.environment,
            bundleIdentifier: Bundle.main.bundleIdentifier,
            hasXCTest: NSClassFromString("XCTestCase") != nil, isDebug: isDebug) else {
            fatalError("Logic tests require an isolated Debug bundle, the logic-host flag, and XCTest")
        }
        _ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
    }
    
    let sharedDefaults = UserDefaults(suiteName: fbSharedDefaultsSuiteName)
    @IBOutlet weak var menuItemUninstall: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var statusbutton:NSStatusBarButton?

    /// When this process started. NSApplicationMain creates the delegate before anything else runs, so
    /// this is effectively launch time — used to tell the system's own launch activation apart from the
    /// user switching to Focus Bear (see `AppActivationRestore.launchSettlingSeconds`).
    private let launchedAt = Date()
    var secondsSinceLaunch: TimeInterval { Date().timeIntervalSince(launchedAt) }

    private var selfActivationMarkedAt: Date?
    private var activationRestoreWorkItem: DispatchWorkItem?
    private var windowsOnScreenAtActivation: Set<ObjectIdentifier>?

    /// Declares that the app is coming to the front for a purpose of its OWN, so the activation that
    /// follows (or has just happened) is not the user asking for the main window.
    ///
    /// AppKit cannot tell us where an activation came from, so origin is declared rather than detected —
    /// see `AppActivationRestore`. Call this from any path that brings the app forward for a specific
    /// transient thing AND does not put a window up during the settle period for
    /// `didAnotherWindowOpenSinceActivation` to notice; a path that does open a window is already covered
    /// without a marker.
    func noteSelfActivation() {
        selfActivationMarkedAt = Date()
        // The marker can arrive after `applicationDidBecomeActive` has already scheduled a decision, so
        // kill that decision outright rather than relying on the marker still being inside its window.
        cancelScheduledMainWindowRestore()
    }

    /// Reads the self-activation marker and consumes it, so one self-activation suppresses exactly one
    /// restore decision instead of blunting every ⌘-Tab for the next couple of seconds.
    func consumeSelfActivationMarker() -> Bool {
        guard let markedAt = selfActivationMarkedAt else { return false }
        selfActivationMarkedAt = nil
        return Date().timeIntervalSince(markedAt) < AppActivationRestore.selfActivationWindowSeconds
    }

    /// Decides whether to restore the main window one settle period after activation rather than at the
    /// instant of it. The user's logs show `applicationDidBecomeActive` arriving BEFORE `togglePopover
    /// start` on a menu-bar click, so deciding immediately would open a window on top of the menu they
    /// asked for. Coalesced, because activation fires constantly.
    ///
    /// The windows on screen are recorded here, before the app has had time to put up whatever it may
    /// have activated itself to show. Comparing that against the windows a settle period later is what
    /// distinguishes "a window was already open when you switched in" — which must not stop the restore
    /// — from "the app pulled itself forward to show you this", which must.
    func scheduleMainWindowRestoreAfterActivation() {
        activationRestoreWorkItem?.cancel()
        // Guarded like the restore itself: reading the windows would load the main window from the
        // storyboard, and the system's own launch activation must not be what does that.
        if secondsSinceLaunch >= AppActivationRestore.launchSettlingSeconds {
            windowsOnScreenAtActivation = nonMainWindowIdentitiesOnScreen()
        }
        let work = DispatchWorkItem { [weak self] in
            self?.activationRestoreWorkItem = nil
            restoreMainWindowOnActivationIfNeeded()
        }
        activationRestoreWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + AppActivationRestore.activationSettleSeconds,
                                      execute: work)
    }

    /// The windows recorded at the last activation, consumed so that a later decision with no activation
    /// behind it — a Dock reopen — compares against nothing rather than against a stale snapshot.
    func consumeWindowsOnScreenAtActivation() -> Set<ObjectIdentifier>? {
        defer { windowsOnScreenAtActivation = nil }
        return windowsOnScreenAtActivation
    }

    /// The user switched away again inside the settle period — they are no longer asking for us, so a
    /// window must not arrive in a now-background app.
    func cancelScheduledMainWindowRestore() {
        activationRestoreWorkItem?.cancel()
        activationRestoreWorkItem = nil
        windowsOnScreenAtActivation = nil
    }

    var updaterController: SPUStandardUpdaterController?
    
    let client = TrueTimeClient.sharedInstance
    let popover = NSPopover()
    // Outside-click dismissal for the menu when it's shown as a window (isMenuPopoverEnabled == false).
    // A .transient NSPopover dismisses itself; the custom window doesn't, so we watch for clicks
    // outside it and close it manually to match popover behaviour.
    var menuOutsideClickMonitorGlobal: Any?
    var menuOutsideClickMonitorLocal: Any?
    var terminateFromSelf = false
    var needToCheckEmailVerification = false
    var hotKeyClearUserdefaults: HotKey? {
        didSet {
            guard let hotKey = hotKeyClearUserdefaults else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                self!.resetAllData()
                
            }
        }
    }
    
    var hotKeyPauseFocusMode: HotKey? {
        didSet {
            guard let hotKey = hotKeyPauseFocusMode else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                self?.macSleepPauseFocusModeIfRunning()
                
            }
        }
    }
    var hotKeyResumeFocusMode: HotKey? {
        didSet {
            guard let hotKey = hotKeyResumeFocusMode else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                self?.macWakeupResumeFocusModeIfRunning()
            }
        }
    }
    
    var timerCheckReactivateTime:Timer?
    var timerCheckClearPasswordTime:Timer?
    var timerBackgroundThread:Timer?
    var timerExtraNagsAfterInactivity:Timer?
    
    var currentUserURL: URL?
    
    // auth
    var credential:Credentials?
    var user: AuthUser?
    // Tokens live in the data-protection keychain (no per-binary ACL, so macOS never asks for
    // Uses Auth0's default (legacy login) keychain storage. A data-protection keychain path was tried on
    // this branch but removed: in signed Release it stored the tokens yet could not read them back, so
    // login looped every session (#2588). The legacy keychain already works for signed builds
    // (certificate-based, no re-prompt), so we ship that and can revisit data-protection as a separate,
    // properly-tested change.
    let credentialsManager = LogicTestHost.makeCredentialsManager()
    
    // Renew credentials
    var renewCredentialsLastDate:Date?
    var renewCredentialsProcessing = false
    
    func resetAllData(){
        addLog(text: "resetAllData")
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to reset Focus Bear? All your settings will be deleted."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        if let window = NSApp.keyWindow{
            alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    addLog(text: "reset All Data Done")
                    self.deleteAllSettings()
                }
            })
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            let result = alert.runModal()
            if result == .alertFirstButtonReturn{
                addLog(text: "reset All Data Done")
                deleteAllSettings()
            }
        }
        
    }
    
    func deleteAllSettings(){
        guard ManagedBlockingRuntime.shared.allowLegacySettingsMutation() else { return }
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        
        
        self.user = nil
        let _ = self.credentialsManager.clear()
        self.credential = nil
       
        deleteAllCsvFiles()
        
        if arrNonTimerBasedHabitsDurationsPlistFileUrl != nil{
            do{
                try FileManager.default.removeItem(at: arrNonTimerBasedHabitsDurationsPlistFileUrl!)
            }catch{
                
            }
        }
        self.quitAndRestartApp()
    }
 
    func logout(isAutomatic:Bool) {
        if !isAutomatic && !ManagedBlockingRuntime.shared.isSignedInAsWrongAccount && !ManagedBlockingRuntime.shared.allowLegacySettingsMutation() { return }
        addLog(text: "logout")
        
        //Improve auto logout - remember email address #1308//
        if !isAutomatic{
            UserDefaults.standard.removeObject(forKey: kUserDefaultsLastUserLoginWithGoogle)
        }
        UserDefaults.standard.set(currentUserEmail, forKey: kUserDefaultsLastUserEmailBeforeLogout)
        //--------------------------------------------------//

        // Clear persisted user identity so stale data doesn't bleed into the next account
        currentLeaderboardUsername = ""
        sharedDefaults?.removeObject(forKey: kUserdefaultsSharedLeaderboardUsername)
        sharedDefaults?.removeObject(forKey: kUserdefaultsSharedUserEmail)
        sharedDefaults?.removeObject(forKey: kUserdefaultsSharedUserName)

        self.user = nil
        let _ = self.credentialsManager.clear()
        self.credential = nil
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastBreaksStartTime)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastBreakEndTime)

        // Talking Clock settings live in device-level UserDefaults. Clear them on logout so a
        // previous account's values don't bleed into the next account when that account has never
        // saved them (its synced blob has no key, so the login apply-from-server is a no-op). Once
        // cleared, login re-applies the new account's synced values or falls back to the defaults.
        UserDefaults.standard.removeObject(forKey: kUserdefaultsTalkingClockEnabled)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsTalkingClockInterval)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsTalkingClockQuietStart)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsTalkingClockQuietEnd)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsTalkingClockSuppressMeetings)
        quitAndRestartApp()
    }
    let alertAppAutoRestart = NSAlert()
    var lastOpenUrlString = ""
    
    open func application(_ application: NSApplication, open urls: [URL]) {
        addLog(text: "func:- open urls")
        if let url = urls.first{
            let urlString = url.absoluteString
            lastOpenUrlString = urlString
            addLog(text: "func:- open url \(urlString)")
            if isSettingsLoddedInAppdelegate{
                filterUrl(url: lastOpenUrlString)
            }
        }
        
        if updaterController != nil{// it means application is already started
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if state{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
                }else{
                    NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            }
        }
    }
    
    /// Called whenever an AppleScript command touches the app (custom verbs via runWhenAppReady, and the
    /// standard get/set/make verbs via the `tasks` element accessors). Records that a script drove us and,
    /// if we already finished launching in the background, brings the app to the foreground right away;
    /// otherwise checkWindowState() will once loading completes.
    @objc func fbNoteScriptingCommand() {
        didHandleScriptingCommand = true
        if isCheckWindowStateDone { fbActivateFromBackgroundLaunch() }
    }

    /// Foreground the app and clear the (late-rendering) splash after a background scripting launch. No-op
    /// unless a script actually drove us and we're still inactive — so login/startup launches and normal
    /// user launches (already frontmost) are left alone. Runs at most once per launch.
    @objc func fbActivateFromBackgroundLaunch() {
        guard didHandleScriptingCommand, !NSApplication.shared.isActive, !didForegroundFromScriptLaunch else { return }
        didForegroundFromScriptLaunch = true
        NSApplication.shared.activate(ignoringOtherApps: true)
        func dismissSplash() {
            splashWcObj?.window?.orderOut(nil)
            splashWcObj?.window?.close()
        }
        dismissSplash()
        for delay in [0.3, 0.8, 1.5] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: dismissSplash)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        if LogicTestHost.isEnabled {
            LogicTestHost.loadBundledConfiguration()
            return
        }
        SentrySDK.start { options in
            options.dsn = "https://85574080eb088006a0f2b0f5d326d6ff@o4509122919006208.ingest.us.sentry.io/4509122992275456"
            #if DEBUG
            options.debug = true
            #endif
            options.attachStacktrace = true// line added on 5/3/25
            options.enableSwizzling = false
            options.enableAutoSessionTracking = false
            options.sendDefaultPii = false // do not send PII (IP address, request bodies) by default
        }
       
        //doing this because if app is started after quit by user then  helper app will know that main app is restarted
        //        getTransparentWindowObject().showWindow(nil)
        let isAppRestartedNormally = UserDefaults.standard.object(forKey: kUserDefaultsAppRestartedNormally) as? Bool ?? false
        if !isAppRestartedNormally{
            showSplashWindow()
        }
        UserDefaults.standard.removeObject(forKey: kUserDefaultsAppRestartedNormally)
        
        sharedDefaults?.removeObject(forKey: kUserdefaultsDontShowNudgeView)
        sharedDefaults?.removeObject(forKey: kUserdefaultsAppQuitForUser)
        sharedDefaults?.removeObject(forKey: kUserdefaultsStartHabitNagCount)
        sharedDefaults?.removeObject(forKey: kUserdefaultsLastNagShowDate)
        sharedDefaults?.removeObject(forKey: kUserdefaultsOnboardingIncompleted)
        sharedDefaults?.synchronize()
        //--------------------------------------------------------//
        checkAndGetGlobalUUID()
        stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
        
        if let fontPath = Bundle.main.path(forResource: "OpenDyslexic3-Regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }
        
        if let fontPath = Bundle.main.path(forResource: "intelone-mono-font-family-regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }
        
        if let fontPath = Bundle.main.path(forResource: "Poppins-Regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }

        // Lexend (Google Fonts, OFL) — the default app font.
        for weight in ["Lexend-Regular", "Lexend-Medium", "Lexend-SemiBold", "Lexend-Bold"] {
            if let fontPath = Bundle.main.path(forResource: weight, ofType: "ttf") {
                var errorRef: Unmanaged<CFError>?
                _ = CTFontManagerRegisterFontsForURL(URL(fileURLWithPath: fontPath) as CFURL, .process, &errorRef)
                print(errorRef as Any)
            }
        }

        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
        for family in fontFamilies {
            print(family)
            let familyFonts = NSFontManager.shared.availableMembers(ofFontFamily: family)
            if let fonts = familyFonts {
                for font in fonts {
                    print("\t\(font)")
                }
            }
        }
        
        
        menuItemUninstall.isHidden = true
        client.start()// for getting true time

        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: self, userDriverDelegate: nil)
        updaterController?.updater.automaticallyChecksForUpdates = true
        
        
        // -----------------------------GENERATE LOG FILE----------------------------
        let bundel = Bundle.main.bundleIdentifier ?? ""
        let applicationSupportPath = "/Users/\(NSUserName())/Library/Application Support/\(bundel)"
        CreateDirectoryIfNotExist(path: applicationSupportPath)
        applicationSupportURL  = URL(fileURLWithPath: applicationSupportPath)
        DebugLogsFolderURL = applicationSupportURL!.appendingPathComponent("Logs")
        CreateDirectoryIfNotExist(path: DebugLogsFolderURL!.path)
        DebugLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Logs.txt")
        //        DebugGraphLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Graphs_Logs.txt")
        quantityCsvURL = applicationSupportURL!.appendingPathComponent("eystStats.csv")
        arrNonTimerBasedHabitsDurationsPlistFileUrl = applicationSupportURL!.appendingPathComponent("nonTimerBasedHabitsDurations.plist")
        focusAlignmentScoreCsvURL = applicationSupportURL!.appendingPathComponent("focusAlignmentScore.csv")
        focusAIDecisionsCsvURL = applicationSupportURL!.appendingPathComponent("focusAIDecisions.csv")
        browsersTabAuditCsvURL = applicationSupportURL!.appendingPathComponent("browsersTabAudit.csv")
        focusProductivityStatsCsvURL = applicationSupportURL!.appendingPathComponent("focusProductivityStats.csv")
        offlineActivitiesCsvURL = applicationSupportURL!.appendingPathComponent("offlineActivities.csv")
        trackFilesFolderURL = applicationSupportURL!.appendingPathComponent("Tracks")
        usageTimingsExplanationCsvUrl = applicationSupportURL!.appendingPathComponent("usage_timings.csv")
        
        settingForScreeenTimeFileURL = applicationSupportURL!.appendingPathComponent("fbtt.plist")
        CreateDirectoryIfNotExist(path: trackFilesFolderURL!.path)
        
        
        // Flask server work
        
        localFlaskServerFolderURL = applicationSupportURL!.appendingPathComponent("static")
        CreateDirectoryIfNotExist(path: localFlaskServerFolderURL!.path)
        let fileManager = FileManager.default
        
        if FileManager.default.fileExists(atPath: "/Users/\(NSUserName())/Desktop/is_fb_test_user.txt"){
            isTestUser = true
        }
        
        
        let filename = "focus-block.html"//also change in defaultAllowedUrl
        let fileUrl = localFlaskServerFolderURL!.appendingPathComponent(filename)
        
        let logoURL = localFlaskServerFolderURL!.appendingPathComponent("logo.svg")
        if !fileManager.fileExists(atPath: logoURL.path){
            if let path = Bundle.main.path(forResource: "logo", ofType: "svg") {
                let url = URL(fileURLWithPath: path)
                do{
                    try fileManager.copyItem(at: url, to: logoURL)
                }catch{
                    print(error)
                }
            }
        }
        
        blockWebUrlString = fileUrl.absoluteString
        
        allApiObject.downloadBlockPageAsync(url: URL(string: "https://focus-bear.github.io/assets/focus-blocked/index.html"), destinationUrl: fileUrl){ (success, error) in
            print(success)
            if flaskServerObject.startFlaskServer(){
                blockWebUrlString = "http://localhost:\(flaskServerPort)"
            }else{
                blockWebUrlString = fileUrl.absoluteString
            }
        }
        firefoxServer.start()
        
        
        
        // ----------------SET APP INSTALL DATE---------------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
        }
        // ----------------Dock icon work---------------------------------
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
            if state{
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            }else{
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }else{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        }
        
        
        
        let char = "k"
        var flags = NSEvent.modifierFlags
        flags.insert(.control)
        flags.insert(.command)
        self.hotKeyClearUserdefaults = HotKey(keyCombo: KeyCombo(stkey: char, modifiers: flags))
        
        
        
        
        // ///////////////////SET TOP ICON////////////////////////
        if self.statusItem.button != nil {
            self.statusbutton = self.statusItem.button
            self.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            
            self.statusbutton?.font = NSFont.systemFont(ofSize: 10)
            
            boxForStatusBar = customStatusBarBox(frame: self.statusbutton!.frame)
            boxForStatusBar.boxType = .custom
            boxForStatusBar.borderWidth = 0
            boxForStatusBar.cornerRadius = statusBarBoxHeightWidth/2
            boxForStatusBar.fillColor = NSColor.clear
            statusbutton?.addSubview(boxForStatusBar)

            boxForStatusBar.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: statusBarBoxHeightWidth)
            let heightConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: statusBarBoxHeightWidth)
            let centerYConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .centerY, relatedBy: .equal, toItem: statusbutton!, attribute: .centerY, multiplier: 1, constant: 0)
            let centerXConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .centerX, relatedBy: .equal, toItem: statusbutton!, attribute: .centerX, multiplier: 1, constant: 0)
            
            statusbutton!.addConstraints([widthConstraint, heightConstraint, centerYConstraint, centerXConstraint])
            
            boxForStatusBarForTooltip = customStatusBarBoxForTooltip(frame: self.statusbutton!.frame)
            boxForStatusBarForTooltip.boxType = .custom
            boxForStatusBarForTooltip.borderWidth = 0
            boxForStatusBarForTooltip.cornerRadius = statusBarBoxHeightWidth/2
            boxForStatusBarForTooltip.fillColor = NSColor.clear
            statusbutton?.addSubview(boxForStatusBarForTooltip)
            
            
            
            boxForStatusBarForTooltip.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: statusBarBoxHeightWidth)
            let heightConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: statusBarBoxHeightWidth)
            let centerYConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .centerY, relatedBy: .equal, toItem: statusbutton!, attribute: .centerY, multiplier: 1, constant: 0)
            let leadingConstraint = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .leading, relatedBy: .equal, toItem: statusbutton!, attribute: .leading, multiplier: 1, constant: leadingStatusBarBox)
            
            statusbutton!.addConstraints([widthConstraintForTooltip, heightConstraintForTooltip, centerYConstraintForTooltip, leadingConstraint])
            
            
            
            
            let customBox = NSBox()
            customBox.boxType = .custom
            customBox.borderWidth = 0
            customBox.fillColor = NSColor.clear
            statusbutton?.addSubview(customBox)
            statusbutton?.addConstraints(subView: customBox)
            
        }
        
        DispatchQueue.global().async {
            avmonitor.isMicOn()
            avmonitor.isACameraOn()// Called early because it takes time on first use, so initializing it at the start
        }
        
        
        //  ---------------------------SETTINGS Language--------------------------
        
        var languageCode = "en"
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            languageCode = language
        }else{
            let language = Locale.preferredLanguages[0] as String
            let range: NSRange = (language as NSString).range(of: "-")
            if range.location != NSNotFound {
                let newString = (language as NSString).substring(to: range.location)
                if newString == "es"{
                    languageCode = "es"
                }else{
                    languageCode = "en"
                }
                UserDefaults.standard.set(languageCode, forKey: kUserdefaultsSelectedLanguage)
                print("\(newString)")
                self.sharedDefaults?.setValue(languageCode, forKeyPath: kUserdefaultsSharedSelectedLanguage)
                self.sharedDefaults?.synchronize()
            } else {
                UserDefaults.standard.set(languageCode, forKey: kUserdefaultsSelectedLanguage)
                self.sharedDefaults?.setValue(languageCode, forKeyPath: kUserdefaultsSharedSelectedLanguage)
                self.sharedDefaults?.synchronize()
            }
        }
        
        //defaults write com.App.EarnYourScreentime SUEnableAutomaticChecks -bool false
        writeSettingForScreeenTime(habitInfo: "")
        var configFileName = ""
        if languageCode == "en"{
            configFileName = "config"
        }else{
            configFileName = "config-\(languageCode)"
        }
        currentLanguageCode = languageCode
        if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
            addLog(text: "running app version:" + " " + version + "." + build)
            appVersion = version + "." + build
        }
        
        let systemVersion = ProcessInfo().operatingSystemVersion
        addLog(text: "macOS Version \(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
        macOSVersion = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        //        https://focus-bear.github.io/assets/config/config.json
        checkLogFileRotation()
        allApiObject.getConfigFile(fileUrl:"https://focus-bear.github.io/assets/config/\(configFileName).json", completionHandler: {dic in
            print("response mila")
            if dic != nil{//todo != kro
                configjson = dic!
            }else{
                if let path = Bundle.main.path(forResource: configFileName, ofType: "json") {
                    let url = URL(fileURLWithPath: path)
                    do {
                        let data = try Data(contentsOf: url, options: .mappedIfSafe)
                        do {
                            if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                configjson = dicResult
                                print(configjson)
                            }
                        }catch {
                            print(error)
                        }
                        
                    } catch {
                        // handle error
                    }
                    
                }
            }
            readConfigFile()
            // canRenew() synchronously reads + decrypts the stored Auth0 credentials from the Keychain
            // (SimpleKeychain.data → SecItemCopyMatching → SecurityServer XPC). On some machines that
            // stalls for >2s, and it used to be called inside the DispatchQueue.main.async below, which
            // froze the launch UI (Sentry AppHang: SimpleKeychain.data). Compute it once out here
            // instead: this closure is getConfigFile's URLSession completion, so we're already off the
            // main thread — no extra dispatch needed — then hop to main for the launch/login UI.
            let canRenew = self.credentialsManager.canRenew()
            DispatchQueue.main.async {

                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)//this is correct, needs to block uls even if user is not logged in
                // Quick Look previews never trigger the activation notification above (see quickLookPreviewMonitor).
                quickLookPreviewMonitor.shared.start()
                NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
                
                if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) != nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsAppQuitProperly) == nil{
                        //                        if UserDefaults.standard.object(forKey: kUserdefaultsDontTellAgain) == nil{ // commented bcos of new splash screen 27/5/25
                        //                            NSApplication.shared.activate(ignoringOtherApps: true)
                        //                            self.alertAppAutoRestart.setSharingType()
                        //                            self.alertAppAutoRestart.messageText = "Focus Bear automatically restarts if it gets force quit/crashes to make sure you always have help combatting distractions. If you want to quit the app/take a break, use the Quit option from the Focus Bear menu bar."
                        //                            self.alertAppAutoRestart.showsSuppressionButton = true
                        //                            self.alertAppAutoRestart.suppressionButton?.title = "Got it - don't tell me again"
                        //                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                        //                                self.alertAppAutoRestart.messageText = common.value(forKey: "alertAppRestartText") as? String ?? self.alertAppAutoRestart.messageText
                        //                                self.alertAppAutoRestart.suppressionButton?.title = common.value(forKey: "buttonDontTellAgainText") as? String ?? "Got it - don't tell me again"
                        //                            }
                        //                            self.alertAppAutoRestart.suppressionButton?.state = .off
                        //                            self.alertAppAutoRestart.addButton(withTitle: buttonOkText)
                        //                            self.alertAppAutoRestart.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))//.modalPanel
                        //                            self.alertAppAutoRestart.runModal()
                        //                            if self.alertAppAutoRestart.suppressionButton?.state == .on{
                        //                                UserDefaults.standard.set(true, forKey: kUserdefaultsDontTellAgain)
                        //                            }
                        //                        }
                    }else{
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsAppQuitProperly)
                    }
                }
                // work for old useres beacuse we have changed the login routine now we will also write is Logged in in userdefaulsts so handle old users
                if UserDefaults.standard.object(forKey: "oldUserLoggedInCheck") == nil{
                    if canRenew {
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                    }
                    UserDefaults.standard.set(true, forKey: "oldUserLoggedInCheck")
                }
                createLaunchAgentForHelperApp()// for nudge work
                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        closeSplashWindow()
                        showWelcomeWindowOrAudhdResultsFirst()
                    }else{
                        closeSplashWindow()
                        
                        if let lastUserEmail = UserDefaults.standard.object(forKey: kUserDefaultsLastUserEmailBeforeLogout) as? String{
                            addLog(text:"showCustomLoginWindow:- because last user email found")
                            showCustomLoginWindow(isLogin: true)
                            DispatchQueue.global().async {
                                DispatchQueue.main.async {
                                    customLoginVcObj?.textFieldEmail.stringValue = lastUserEmail
                                }
                            }
                            return;
                        }
                        showAskLoginWindow()
                    }
                    return;
                }else{
                    guard canRenew else {
                        // Present login screen
                        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                            closeSplashWindow()
                            showWelcomeWindowOrAudhdResultsFirst()
                        }else{
                            closeSplashWindow()
                            showAskLoginWindow()
                        }
                        
                        return;
                    }
                }
                
                self.loadCredentialsAndDeviceId()
            }

        }
        )
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let win = notification.object as? NSWindow,
               let identifier = win.identifier?.rawValue {
                //SUUpdateAlert for progress alert
                if identifier.hasPrefix("SUUpdateAlert") || identifier.hasPrefix("SUStatus"){   // catches SUUpdateAlert, SUStatus, etc.
                    win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
                    print("Adjusted Sparkle window:", identifier)
                }
            }
        }
    }
    
    func completeRemainingOnboarding(){
        addLog(text: "complete Remaining Onboarding")
        if !getHabitsVcObject().isViewLoaded{
            getHabitsVcObject().loadView()
        }
        currentState = ._ONBOARDING_
        mainWindowControllerObj?.showWindow(self)
        mainViewControllerObj?.checkIsFullScreenNeeded()
        mainViewControllerObj!.showOnboardingVc()
        leftMenuVcObj?.disableAllTabForOnboarding()
        mainViewControllerObj?.collapseLeftPanel()
        // Distraction blocking now comes before habits in onboarding: enter the blocking
        // section first; it hands off to the habits intro (._HOLD_ON_) once finished.
        getOnboardingVcObject().navigate(to: ._SET_DISTRACTION_BLOCKING_)
    }
    
    /// What a failed credential read should cause. Report 2026-09-13: the access token expired,
    /// its refresh token had already been revoked, and the app showed the "please login again"
    /// alert **78 times** across **39 relaunches** — because every API call's credential callback
    /// independently alerted and logged out, and `logout()` restarts the app, whose launch-time
    /// requests then failed with "no credentials" and logged it out again.
    enum CredentialFailure: Equatable {
        /// Already logged out: show the login window. Never alert, never log out again — that is
        /// the loop.
        case alreadySignedOut
        /// No internet: the session may be fine, so keep it and say so.
        case offline
        /// The session is genuinely dead: say so once and sign out.
        case signOut
        /// Something has already handled this in this process.
        case handled

        static func of(error: Error?, hasInternet: Bool, alreadyHandled: Bool) -> CredentialFailure {
            if alreadyHandled { return .handled }
            if let error = error as? CredentialsManagerError, error == .noCredentials { return .alreadySignedOut }
            return hasInternet ? .signOut : .offline
        }
    }

    /// Set for the life of the process the first time a credential failure is acted on. The process
    /// is about to be restarted or is sitting on the login window, so it is never cleared.
    private static var handledCredentialFailure = false

    func setCredentialAndUserInfo(credentialsInfo: CredentialsManagerResult<Credentials>, isAppLaunching:Bool){
        // A late callback from a storyboard/global initializer must not open the credential-error
        // modal while XCTest is preparing. Logic tests supply their own auth/API fixtures.
        guard !LogicTestHost.isEnabled else { return }
        addLog(text: "set Credential And User Info")
        var newCredential:Credentials?
        var credentialError: Error?
        do{
            newCredential = try credentialsInfo.get()
            if let newCredential = newCredential{
                renewCredentialsIfNeeded(newCredential: newCredential)
            }
        }catch{
            credentialError = error
            addLog(text: "failed:- appdelegate!.credentialsManager.credentials \(error.localizedDescription)")
            print(error)
        }
        
        var needToRefreshUser = false
        if newCredential == nil{
            addLog(text: "failed:- newCredential nil")
            // One failure is enough. Without this, four concurrent Day Plan reloads meant four
            // alerts and four logouts, and a logged-out relaunch alerted all over again.
            let failure = AppDelegate.CredentialFailure.of(error: credentialError,
                                                           hasInternet: Reachability.isConnectedToNetwork(),
                                                           alreadyHandled: AppDelegate.handledCredentialFailure)
            addLog(text: "credential failure: \(failure)")
            switch failure {
            case .handled:
                return
            case .alreadySignedOut:
                // Already signed out — no keychain credentials. Showing the login window is the whole
                // response; alerting and "logging out" an already-logged-out app is what looped it 39
                // times. NOTE (#2583): .alreadySignedOut is CredentialsManagerError.noCredentials,
                // which a FRESH user has too — so this branch used to show a brand-new user login
                // instead of onboarding. That only happened because the timezone/busy-hours reporters
                // called an authenticated API pre-auth in applicationDidFinishLaunching; they now start
                // in loadAppAndSettings() (post-auth), so at launch a fresh user is routed to
                // onboarding by the launch flow (kUserdefaultsIsUserLoggedIn == nil) and never reaches
                // here — this branch now only fires for a user who WAS logged in but lost credentials,
                // for whom login is correct. ⚠️ This is a per-request failure handler with no launch-
                // flow context, so it can't itself tell "fresh" from "signed out": if any future
                // pre-auth AllApi caller is added, the fresh-user-login regression returns. The real
                // home for the login-vs-onboarding decision is the launch flow, not here. Kept as-is
                // (option A) because the root cause is fixed; make it first-run-aware if that trap
                // ever needs closing for good.
                // In practice this branch is now rarely reached: .alreadySignedOut is specifically
                // CredentialsManagerError.noCredentials — no credentials item in the keychain at all.
                // With the pre-auth caller removed, at launch that means a user who was logged in but
                // whose keychain item is now gone/cleared. (An expired token whose refresh fails is a
                // different error and falls to .signOut/.offline below, not here.)
                AppDelegate.handledCredentialFailure = true
                DispatchQueue.main.async {
                    closeSplashWindow()
                    showCustomLoginWindow(isLogin: true)
                }
                return
            case .offline, .signOut:
                AppDelegate.handledCredentialFailure = true
            }
            DispatchQueue.main.async {
                
                
                if Reachability.isConnectedToNetwork() == false{
                    
                    allApiObject.isInternetOn(completionHandler: {isInternetOn in
                        DispatchQueue.main.async {
                            if !isInternetOn{
                                addLog(text: "failed:- newCredential nil : reason no internet")
                                closeSplashWindow()
                                showPopUpOfflineWindow()
                                
                                if mainWindowControllerObj?.window?.isVisible ?? false{
                                    self.abortAllProcess()
                                    mainWindowControllerObj?.window?.close()
                                    hideBlankWindowInSecondaryMonitor()
                                }
                            }else{
                                addLog(text: "failed:- newCredential nil : show alert and logout")
                                closeSplashWindow()
                                if mainWindowControllerObj?.window?.isVisible ?? false{
                                    self.abortAllProcess()
                                    mainWindowControllerObj?.window?.close()
                                    hideBlankWindowInSecondaryMonitor()
                                }
                                allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                                let alert = NSAlert()
                                alert.setSharingType()
                                var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                    someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                                }
                                alert.messageText = someProblemInCredentialText
                                alert.addButton(withTitle: buttonOkText)
                                NSApplication.shared.activate(ignoringOtherApps: true)
                                alert.runModal()
                                self.logout(isAutomatic: true)
                            }
                        }
                        
                    })
                    
                }else{
                    addLog(text: "failed:- newCredential nil : show alert and logout")
                    closeSplashWindow()
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        self.abortAllProcess()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    alert.runModal()
                    self.logout(isAutomatic: true)
                }
                
            }
            return;
        }
        
        if self.credential == nil{
            self.credential = newCredential
            addLog(text: "successfully fetch cedential from credentialsManager in app launch")
            needToRefreshUser = true
            let expireDate = newCredential!.expiresIn
            let expireDateString = getStringFromDate(date: expireDate, dateFormat: "yyyy-MM-dd HH:mm:ss")
            addLog(text: "Credential expires in: \(expireDateString)")
        }else{
            if self.credential?.accessToken != newCredential?.accessToken{
                addLog(text: "accessToken changed:- update cedential in credentialsManager")
                self.credential = newCredential
                let _ = credentialsManager.store(credentials: self.credential!)
                needToRefreshUser = true
                let expireDate = newCredential!.expiresIn
                let expireDateString = getStringFromDate(date: expireDate, dateFormat: "yyyy-MM-dd HH:mm:ss")
                addLog(text: "Credential expires in \(expireDateString)")
            }
        }
        
        if needToRefreshUser{
            addLog(text: "successfully fetch cedential:- needToRefreshUser")
            self.user = AuthUser(from: self.credential!.accessToken)
        }
    }
    
    func renewCredentialsIfNeeded(newCredential:Credentials){
        if let renewCredentialsLastDate = renewCredentialsLastDate{
            let diffMinuteS = Calendar.current.dateComponents([.minute], from: renewCredentialsLastDate, to: Date()).minute ?? 0
            if diffMinuteS < 5{//renew token once in five miunutes
                return;
            }
        }
        if renewCredentialsProcessing{//return if already renewing token
            return;
        }
        if isAppInitialLodded{
            renewCredentialsProcessing = true
            let now = Date()
            let expireDate = newCredential.expiresIn
            let needsRefresh = expireDate.timeIntervalSince(now) <= 86400 //24 hours
            renewCredentialsLastDate = Date()
            addLog(text: "Check whether to renew the token if its expiration date is within 24 hours.")
            if needsRefresh {
                addLog(text: "Renew token because the expiration date is within 24 hours.")
                Auth0
                    .authentication()
                    .renew(withRefreshToken: newCredential.refreshToken ?? "")
                    .start { result in
                        self.renewCredentialsProcessing = false
                        switch result {
                        case .success(let credentials):
                            addLog(text: "renew Token successfully")
                            if credentials.accessToken != newCredential.accessToken{
                                addLog(text: "accessToken updated:- update cedential in credentialsManager")
                                self.credential = credentials
                                let _ = self.credentialsManager.store(credentials: self.credential!)
                                addLog(text: "successfully fetch cedential:- user created again")
                                self.user = AuthUser(from: self.credential!.accessToken)
                            }
                            
                            
                        case .failure(let error):
                            // `AuthenticationError` is a struct, so its bridged NSError code is
                            // always 1 — 245 consecutive failures all logged "error code: 1" and
                            // said nothing. The description carries the actual reason (e.g.
                            // "Unknown or invalid refresh token"), which is what identifies a dead
                            // refresh token rather than a network blip.
                            addLog(text: "renewToken failed: \(error.localizedDescription)")
                            
                        }
                    }
            }else{
                renewCredentialsProcessing = false
            }
        }
    }
    
    func loadCredentialsAndDeviceId(){
        addLog(text: "load Credentials And DeviceId")
        
        
        credentialsManager.credentials { [self] credentialsInfo in
            
            setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: true)
            
            if self.credential == nil{ //  it means failed to get cradential and popup offline or error msg is visible
                return;
            }
            if self.credential != nil{
                // Warm the Todo List / Edit Habits / Stats shared webview so the first sidebar
                // click on whichever of the three the user opens first is (often) already loaded.
                // credentialsManager.credentials' callback fires on a background thread, but WKWebView
                // must only ever be created on the main thread (WebKit crashes with EXC_BREAKPOINT
                // otherwise) — SharedDashboardWebViewManager.shared lazily creates one on first access.
                DispatchQueue.main.async {
                    SharedDashboardWebViewManager.shared.preload(.editHabits)   // Todo List + Stats are native now; Edit Habits is the only shared web screen left
                }

                sharedDefaults?.setValue(self.user?.userId ?? "", forKeyPath: kUserdefaultsSharedUserId)
                sharedDefaults?.setValue(self.credential!.accessToken, forKeyPath: kUserdefaultsSharedAccessToken)
                sharedDefaults?.setValue(appVersion, forKeyPath: kUserdefaultsSharedAppVersion)
                // Restore persisted user info so account screen shows correct values before the API call returns
                currentUserEmail = sharedDefaults?.object(forKey: kUserdefaultsSharedUserEmail) as? String ?? ""
                currentUserName = sharedDefaults?.object(forKey: kUserdefaultsSharedUserName) as? String ?? ""
                currentLeaderboardUsername = sharedDefaults?.object(forKey: kUserdefaultsSharedLeaderboardUsername) as? String ?? ""

                SentrySDK.configureScope { scope in
                    let user = User(userId: self.user?.userId ?? "")
                    scope.setUser(user)
                }
                // Day Plan projects that only ever existed on this Mac get pushed to the backend once
                // we're signed in (see DayPlanProjectRepair) — otherwise they never show on web/mobile.
                DayPlanProjectRepair.shared.scheduleAfterLaunch()

                sharedDefaults?.synchronize()
                DispatchQueue.main.async {
                    kUserdefaultsVideoShown = kUserdefaultsVideoShown + (self.user?.userId ?? "")
                    if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) == nil{
                        var shouldShowOnboardingAfterLogin = true
                        var userHasDoneOnboardingOnWeb = false
                        allApiObject.getUserLocalDeviceSettings(completionHandler: { json in
                            if json != nil{
                                
                                if let webSettings = json?.value(forKey: "Web") as? NSDictionary {// added on 9/9/25 version 2.27.413
                                    
                                    
                                    if let onboarding = webSettings.value(forKey: "onboarding") as? NSDictionary{
                                        if let currentStep = onboarding.value(forKey: "currentStep") as? String{
                                            if currentStep.lowercased() == "completed"{
                                                //                                                shouldShowOnboardingAfterLogin = false
                                                userHasDoneOnboardingOnWeb = true
                                            }
                                        }
                                    }
                                }
                                
                                if let settings = json?.value(forKey: "MacOS") as? NSDictionary {//
                                    print(settings)
                                    if settings.allKeys.count == 0{
                                        shouldShowOnboardingAfterLogin = true
                                    }else{
                                        shouldShowOnboardingAfterLogin = false
                                    }
                                    
                                }
                            }
                            DispatchQueue.main.async {
                                if shouldShowOnboardingAfterLogin{
                                    
                                    if userHasDoneOnboardingOnWeb{// added v 2.27.422
                                        SettingsManagerObject.doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue = true
                                        SettingsManagerObject.isGeekModeEnabled = false // for new user app is in simple mode
                                        if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == false{
                                            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
                                            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
                                        }
                                        self.needToCheckEmailVerification = false// if onboarding then dont show till menu tour is over
                                        self.getUserSubscriptionInfo()
                                        self.statusbutton?.action = nil
                                        appdelegate?.menuShowSimplePomodoroModeView()
                                        UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
                                    }else{
                                        allApiObject.postTermsService(consentType: "terms_of_service")
                                        allApiObject.postTermsService(consentType: "privacy_policy")
                                        allApiObject.postCourse()
                                        allApiObject.autoEenrolledCourse()
                                        
                                        
                                        kUserDefaultsSelectedOccupationForPosthog = kUserDefaultsSelectedOccupationForPosthogKey + (self.user?.userId ?? "")

                                        
                                        kUserDefaultsBlockingScheduleAddedFirstTime = kUserDefaultsBlockingScheduleAddedFirstTime + (self.user?.userId ?? "")
                                        closeSplashWindow()
                                        self.completeRemainingOnboarding()
                                    }
                                }else{
                                    UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
                                    self.getUserSubscriptionInfo()
                                }
                            }
                        }
                        )
                        
                    }else{
                        self.getUserSubscriptionInfo()
                    }
                }
            }else{
                DispatchQueue.main.async {
                    addLog(text: "credential nil:- ask login again")
                    allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                    closeSplashWindow()
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    alert.runModal()
                    self.logout(isAutomatic: true)
                }
            }
            
        }
    }
    
    
    func getUserSubscriptionInfo(){
        if UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserDefaultsFirstAppFullLoadDate)
        }
        //if user clicked i already have a account from onboarding
        if currentState == ._ONBOARDING_{
            let currentOnboardingState = getOnboardingVcObject().currentOnboardingState
            // getUserSubscriptionInfo is now also called up-front from allSetVc (via
            // onboardingFinishedGoAhedForSettings) while still on the All-Set screen. In that case
            // skip the onboarding teardown/window-close — the loader/gating flow closes the window
            // later in onboardingFinishedUnlockMachine(). Only tear down for the older non-_ALL_SET_ paths.
            if currentOnboardingState != ._ALL_SET_{
                leftMenuVcObj?.enableAllItems()
                mainViewControllerObj?.expandLeftPanel()
                mainViewControllerObj?.removeSubViews()
                mainWindowControllerObj?.window?.close()
                currentState = ._NOTHING_
            }
        }
        allApiObject.getUserSubscriptionInfo(completionHandler: {dic,statusCode  in
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
            var subscriptionStatus: [String : Any]?
            if let subscriptionStatusDic = dic as? [String:Any]{
                subscriptionStatus = subscriptionStatusDic
            }else if let subscriptionStatusDic = self.user?.subscriptionStatus{
                subscriptionStatus = subscriptionStatusDic
                if statusCode != nil{
                    if statusCode == 404{
                        DispatchQueue.main.async {
                            self.logout(isAutomatic: true)
                        }
                        return;
                    }
                }
            }
            
            isPurchased = false
            if let subscriptionStatus = subscriptionStatus{
                
                var activeEntitlementStatus = ""
                if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
                    // Consider every active entitlement, not just the first — see SubscriptionEntitlements.
                    if let paid = SubscriptionEntitlements.payingEntitlement(in: activeEntitlements){
                        activeEntitlementStatus = paid
                        isPurchased = true
                    }else{
                        activeEntitlementStatus = activeEntitlements.first ?? ""
                        isPurchased = false
                    }
                }
                let oldDaysLeft = daysLeft
                daysLeft = 0
                print(subscriptionStatus)
                if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
                    if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
                        if let days_left = trial["days_left"] as? Int{
                            print(days_left)
                            daysLeft = days_left
                        }
                    }
                }
                if oldDaysLeft > 0{// subscription over need to restart
                    if isPurchased == false && daysLeft == 0{
                        addLog(text: "subscription over:- need to restart app")
                        DispatchQueue.main.async {
                            self.quitAndRestartApp()
                        }
                        
                    }
                }
                if isPurchased == false && daysLeft == 0{
                    isExpired = true
                }
            }
            self.sharedDefaults?.setValue(isPurchased, forKeyPath: kUserdefaultsSharedIsPurchased)
            self.sharedDefaults?.synchronize()
            // The sidebar decides whether to show "Upgrade Now" in viewWillAppear, which runs at launch
            // — before this answer arrives. A paid account therefore kept the row for the rest of the
            // session and was invited to upgrade something it already had (report 2026-09-14_19-47-35).
            DispatchQueue.main.async { leftMenuVcObj?.checkPurchaseState() }
            
            
            DispatchQueue.main.async {
                // ----------------SET DeviceID---------------------------------
                addLog(text: "User Id is :- \(self.user?.userId ?? "")")
                kUserdefaultsDeviceId = kUserdefaultsDeviceId + (self.user?.userId ?? "")
                kUserdefaultsIsAppEnabled = kUserdefaultsIsAppEnabled + (self.user?.userId ?? "")
                kUserdefaultsLastAppAbortedDate = kUserdefaultsLastAppAbortedDate + (self.user?.userId ?? "")
                kUserdefaultsLastFocusModeDoneDate = kUserdefaultsLastFocusModeDoneDate + (self.user?.userId ?? "")
                kUserdefaultsLastInactivityNagShowDate = kUserdefaultsLastInactivityNagShowDate + (self.user?.userId ?? "")
                kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate = kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate + (self.user?.userId ?? "")
                kUserdefaultsLastHabitSavedNotes = kUserdefaultsLastHabitSavedNotes + (self.user?.userId ?? "")
                kUserdefaultsLastCustomRoutineHabitSavedNotes = kUserdefaultsLastCustomRoutineHabitSavedNotes + (self.user?.userId ?? "")
                kUserdefaultsLastActivitySavedNotes = kUserdefaultsLastActivitySavedNotes + (self.user?.userId ?? "")
                kUserdefaults4HourReActivateTime = kUserdefaults4HourReActivateTime + (self.user?.userId ?? "")
                kUserdefaultsShutdownAborted = kUserdefaultsShutdownAborted + (self.user?.userId ?? "")
                kUserdefaultsLastShutdownAbortedDate = kUserdefaultsLastShutdownAbortedDate + (self.user?.userId ?? "")
                kUserdefaultsEveningHabitsShowedTillDate = kUserdefaultsEveningHabitsShowedTillDate + (self.user?.userId ?? "")
                kUserdefaultsFocusSummaryShowedTillDate = kUserdefaultsFocusSummaryShowedTillDate + (self.user?.userId ?? "")
                // #2142: namespace the brain-dump seed flag per user, so each user on this device gets
                // their saved brain dump seeded into the webview once (not shared across accounts).
                kUserdefaultsBrainDumpSentToWebView = kUserdefaultsBrainDumpSentToWebView + (self.user?.userId ?? "")
                kUserdefaultsArrFocusTypes = kUserdefaultsArrFocusTypes + (self.user?.userId ?? "")
                kUserdefaults24HoursClearPasswordTime = kUserdefaults24HoursClearPasswordTime + (self.user?.userId ?? "")
                
                kUserdefaultsLastHabitsStartedDate = kUserdefaultsLastHabitsStartedDate + (self.user?.userId ?? "")
                kUserdefaultsDontAskFocusMusicPrompt = kUserdefaultsDontAskFocusMusicPrompt + (self.user?.userId ?? "")
                kUserdefaultsFocusMusicAutoStartPreference = kUserdefaultsFocusMusicAutoStartPreference + (self.user?.userId ?? "")
                kUserdefaultsLastHabitRunningInfo = kUserdefaultsLastHabitRunningInfo + (self.user?.userId ?? "")
                kUserdefaultsLastCustomRoutineHabitRunningInfo = kUserdefaultsLastCustomRoutineHabitRunningInfo + (self.user?.userId ?? "")
                
                kUserdefaultsLastSequencePostponeInfo = kUserdefaultsLastSequencePostponeInfo + (self.user?.userId ?? "")
                kUserdefaultsLastBreakActivityPostponeInfo = kUserdefaultsLastBreakActivityPostponeInfo + (self.user?.userId ?? "")
                
                kUserdefaultsNotesAddedInOfflineCsv = kUserdefaultsNotesAddedInOfflineCsv + (self.user?.userId ?? "")
                kUserdefaultsTagsColumnAddedInStatsCsv = kUserdefaultsTagsColumnAddedInStatsCsv + (self.user?.userId ?? "")
                kUserdefaultsEditBlockedUrlsOnce = kUserdefaultsEditBlockedUrlsOnce + (self.user?.userId ?? "")
                kUserdefaultsLastFocusSavedIntention = kUserdefaultsLastFocusSavedIntention + (self.user?.userId ?? "")
                
                kUserdefaultsAllFocusModesTags = kUserdefaultsAllFocusModesTags + (self.user?.userId ?? "")
                kUserdefaultsFocusModeNotes = kUserdefaultsFocusModeNotes + (self.user?.userId ?? "")
                kUserdefaultsFocusTipsShown = kUserdefaultsFocusTipsShown + (self.user?.userId ?? "")
                kUserdefaultsImpactMeasurementShown = kUserdefaultsImpactMeasurementShown + (self.user?.userId ?? "")
                kUserdefaultsSurveyShown = kUserdefaultsSurveyShown + (self.user?.userId ?? "")
                kUserdefaultsTotalTimeSpentOnDistractingSites = kUserdefaultsTotalTimeSpentOnDistractingSites + (self.user?.userId ?? "")
                kUserdefaultsTotalDistractingSitesBlocked = kUserdefaultsTotalDistractingSitesBlocked + (self.user?.userId ?? "")
                kUserdefaultsSimplePomodoroAiBlockingSelected = kUserdefaultsSimplePomodoroAiBlockingSelected + (self.user?.userId ?? "")
                kUserdefaultsDisableBreaksForToday = kUserdefaultsDisableBreaksForToday + (self.user?.userId ?? "")
                kUserdefaultsBreakOffDates = kUserdefaultsBreakOffDates + (self.user?.userId ?? "")
                kUserdefaultsBreakOffPromptShown = kUserdefaultsBreakOffPromptShown + (self.user?.userId ?? "")
                kUserdefaultsNextBreakDueTime = kUserdefaultsNextBreakDueTime + (self.user?.userId ?? "")
                kUserdefaultsLastFocusModeStrictness = kUserdefaultsLastFocusModeStrictness + (self.user?.userId ?? "")
                kUserdefaultsIsFocusSessionAutoStarted = kUserdefaultsIsFocusSessionAutoStarted + (self.user?.userId ?? "")
                kUserDefaultsOpenTodoPlayerFirstTime = kUserDefaultsOpenTodoPlayerFirstTime + (self.user?.userId ?? "")
                kUserDefaultsHideAppModeOption = kUserDefaultsHideAppModeOption + (self.user?.userId ?? "")
                kUserdefaultsMicroBreaksDoneCount = kUserdefaultsMicroBreaksDoneCount + (self.user?.userId ?? "")
                
                kUserdefaultsBeginMorningHabitClickedDate = kUserdefaultsBeginMorningHabitClickedDate + (self.user?.userId ?? "")
                kUserdefaultsBeginEveningHabitClickedDate = kUserdefaultsBeginEveningHabitClickedDate + (self.user?.userId ?? "")
                
                
                // having default key because after create acount we change userdefaults key and here we again change default key so get rig of this problem we are having now a default userdefault key
                
                kUserDefaultsSelectedOccupationForPosthog = kUserDefaultsSelectedOccupationForPosthogKey + (self.user?.userId ?? "")

                
                kUserDefaultsBlockPageTourShowed = kUserDefaultsBlockPageTourShowed + (self.user?.userId ?? "")
                kUserDefaultsHowHeardAboutApp = kUserDefaultsHowHeardAboutApp + (self.user?.userId ?? "")
                kUserDefaultsLastQuitReason = kUserDefaultsLastQuitReason + (self.user?.userId ?? "")
                
                
                kUserdefaultsManageTaskFirstTime = kUserdefaultsManageTaskFirstTime + (self.user?.userId ?? "")
                
                kUserdefaultsIsAnyDistractionSetByUser = kUserdefaultsIsAnyDistractionSetByUser + (self.user?.userId ?? "")
                
                kUserDefaultsLastRoutinePostponeEndDate = kUserDefaultsLastRoutinePostponeEndDate + (self.user?.userId ?? "")
                kUserDefaultsLastRoutinePostponeState = kUserDefaultsLastRoutinePostponeState + (self.user?.userId ?? "")

                kUserdefaultsHiddenFocusModeIDs = kUserdefaultsHiddenFocusModeIDs + (self.user?.userId ?? "")

                kUserdefaultsHiddenToolIds = kUserdefaultsHiddenToolIds + (self.user?.userId ?? "")

                connectGlobalAndMacIDWithDistinctUserID()
                
                
                SettingsManagerObject.resetAllKeys()
                
                allApiObject.getAllTracks(completionHandler: {arrJson in
                    print(arrJson)
                    
                    autoreleasepool{
                        if arrJson != nil{
                            for item in arrJson!{
                                let artist = item.value(forKey: "artist") as? String ?? ""
                                let description = item.value(forKey: "description") as? String ?? ""
                                let download_url = item.value(forKey: "download_url") as? String ?? ""//URL(string:item.value(forKey: "download_url") as? String ?? "")
                                let duration = Int(item.value(forKey: "duration") as? String ?? "") ?? 0
                                let id = item.value(forKey: "id") as? String ?? ""
                                let name = item.value(forKey: "name") as? String ?? ""
                                let pathExtension = URL(string: download_url)?.pathExtension ?? ""
                                let localUrl = trackFilesFolderURL!.appendingPathComponent(id + "." + pathExtension)
                                
                                let thumbnail_download_url = item.value(forKey: "thumbnail_download_url") as? String ?? ""
                                let thumbnailExtension = URL(string: thumbnail_download_url)?.pathExtension ?? ""
                                let thumbnailLocalUrl = trackFilesFolderURL!.appendingPathComponent(id + "." + thumbnailExtension)
                                
                                
                                var isFileDownloading = false
                                var isFileDownloded = true
                                if !FileManager.default.fileExists(atPath: localUrl.path){
                                    isFileDownloded = false
                                    isFileDownloading = false
                                    
                                }
                                arrAllTracks.append(["artist":artist, "description":description, "download_url":download_url, "id":id, "name":name, "url":localUrl.path, "isFileDownloded":isFileDownloded, "isFileDownloading":isFileDownloading, "isPlaying":false, "thumbnailLocalUrl":thumbnailLocalUrl.path, "thumbnail_download_url":thumbnail_download_url, "duration":duration])
                                
                            }//
                        }else{
                            arrAllTracks = UserDefaults.standard.object(forKey: kUserdefaultsAllTracks) as? [[String : Any]] ?? []
                            for i in 0..<arrAllTracks.count{
                                arrAllTracks[i]["isPlaying"] = false
                                arrAllTracks[i]["isPaused"] = false
                            }
                        }
                        UserDefaults.standard.set(arrAllTracks, forKey: kUserdefaultsAllTracks)
                    }
                    checkAllTracksDownloadState()
                    // If the app relaunched into a still-running focus session before the track library
                    // finished loading, this is where a pending resume auto-start finally gets its tracks.
                    DispatchQueue.main.async { FocusMusicPromptManager.startAutoStartOnResumeIfReady() }
                })
                
                
                self.currentUserURL = applicationSupportURL!.appendingPathComponent(self.user?.userId ?? "")
                if self.currentUserURL != nil{
                    CreateDirectoryIfNotExist(path: self.currentUserURL!.path)
                    quantityCsvURL = self.currentUserURL!.appendingPathComponent("eystStats.csv")
                    arrNonTimerBasedHabitsDurationsPlistFileUrl = self.currentUserURL!.appendingPathComponent("nonTimerBasedHabitsDurations.plist")
                    focusAlignmentScoreCsvURL = self.currentUserURL!.appendingPathComponent("focusAlignmentScore.csv")
                    focusAIDecisionsCsvURL = self.currentUserURL!.appendingPathComponent("focusAIDecisions.csv")
                    focusProductivityStatsCsvURL = self.currentUserURL!.appendingPathComponent("focusProductivityStats.csv")
                    offlineActivitiesCsvURL = self.currentUserURL!.appendingPathComponent("offlineActivities.csv")
                    newLocalSettingsFileURL = self.currentUserURL!.appendingPathComponent("localSettings.plist")
                    browsersTabAuditCsvURL = self.currentUserURL!.appendingPathComponent("browsersTabAudit.csv")
                    usageTimingsExplanationCsvUrl = self.currentUserURL!.appendingPathComponent("usage_timings.csv")
                }
                nonTimerBasedHabitsObject.readNonTimerBasedHabitsDurations()
                if let id  = UserDefaults.standard.object(forKey: kUserdefaultsDeviceId) as? String{
                    currentDeviceId = id
                    addLog(text: "load Credentials And DeviceId - got old id")
                    self.loadAppAndSettings()
                    self.sharedDefaults?.setValue(id, forKeyPath: kUserdefaultsSharedCurrentDeviceId)
                    self.sharedDefaults?.synchronize()
                    
                }else{
                    addLog(text: "load Credentials And DeviceId - getDeviceId")
                    allApiObject.getDeviceId(completionHandler: {id in
                        addLog(text: "load Credentials And DeviceId - got id")
                        if id != nil{
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(id!, forKey: kUserdefaultsDeviceId)//e935f08a-5571-4cc3-b514-e0bea9739fd7
                                currentDeviceId = id!
                                self.loadAppAndSettings()
                                self.sharedDefaults?.setValue(id, forKeyPath: kUserdefaultsSharedCurrentDeviceId)
                                self.sharedDefaults?.synchronize()
                            }
                        }else{
                            DispatchQueue.main.async {
                                allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                                closeSplashWindow()
                                let alert = NSAlert()
                                alert.setSharingType()
                                alert.messageText = "Unable to connect to server. Please check your internet connection."
                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                    alert.messageText = common.value(forKey: "checkInternetText") as? String ?? alert.messageText
                                }
                                alert.addButton(withTitle: buttonOkText)
                                NSApplication.shared.activate(ignoringOtherApps: true)
                                alert.runModal()
                                addLog(text: "load Credentials And DeviceId - id is nil - force Logout user and ask sign in")
                                self.logout(isAutomatic: true)
                            }
                        }
                        
                    }
                    )
                    
                }
            }
            
            
        })
    }
    
    func loadAppAndSettings(){
        DispatchQueue.main.async { ManagedBlockingRuntime.shared.authenticatedSessionReady() }
        addLog(text: "load App And Settings")

        // Declared timezone first (the busy-hours day keys are validated against it), then the hourly
        // EventKit busy-hours report to the portfolio (#2418); the Day Plan also triggers it.
        // Started here rather than in applicationDidFinishLaunching so they only fire once the user
        // is signed in — they hit authenticated endpoints, and running them pre-auth broke the fresh
        // -user launch (login shown instead of onboarding) and looped "please login again" (#2583).
        // Both start() calls are idempotent, so reaching this twice is harmless.
        UserTimezoneSync.shared.start()
        BusyHoursReporter.shared.start()

        checkAllCsvFiles()
        
        SettingsManagerObject.getUserLocalDeviceSettings(completionHandler: {
            
            DispatchQueue.main.async {
                addLog(text: "work after getUserLocalDeviceSettings")
                TalkingClockManager.shared.start()

                // Register keyboard shortcuts for Brain Dump, Focus Music, Task List
                HotkeyService.shared.registerAll()

                deleteLaunchAgent()// this will be always
                // tell helper app to  monitor force quit
                
                if SettingsManagerObject.shouldReloadAfterForceQuitEnabled{
                    startMainAppForceQuitMonitoring()
                }else{
                    stopMainAppForceQuitMonitoring()
                }

                
                if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
                    if SettingsManagerObject.arrBlockedApps.count != 0 || SettingsManagerObject.arrBlockedUrls.count != 0{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
                    }
                }
                
                if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                    addLog(text: "BrowsersPermissionsSetByUser is nil check again")
                    var permissionGiven = false
                    if isAccessibilityEnabled(isPrompt: false){
                        permissionGiven = true
                        addLog(text: "Accessibility enabled")
                    }
                    // additiona
                    if !permissionGiven{
                        addLog(text: "check All Browsers Permission Info")
                        if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
                            for i in 0..<arrBrowsersInfo.count{
                                let info = arrBrowsersInfo[i]
                                let isEnabled = info["isEnabled"] as? Bool ?? false
                                if isEnabled{
                                    permissionGiven = true
                                    break;
                                }
                            }
                        }
                    }
                    if permissionGiven{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
                    }
                }
                
                
                //  --------------------Checking Password reset time -------------------------------------------------
                
                if let date = UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) as? Date{
                    if Date().compare(date) == .orderedAscending {
                        //first date is smaller than second
                        addLog(text: "set timer Check Clear Password Time")
                        DispatchQueue.global().sync {
                            self.timerCheckClearPasswordTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkTwentyFourHourActivateTime), userInfo: nil, repeats: true)
                            RunLoop.main.add((self.timerCheckClearPasswordTime!), forMode: RunLoop.Mode.common)
                        }
                    }else{
                        UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
                        UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                        SettingsManagerObject.isSettingsChanged = true
                        SettingsManagerObject.putUserLocalDeviceSettings()
                        addLog(text: "password is cleared after 24 hours")
                    }
                }
                
                allApiObject.getAllBlockingSchedules(completionHandler: {data in
                    if data != nil{
                        addLog(text: "Blocking schedules fetched successfully from API.")// log added v3.32.487
                        customBlockingScheduleManagerObj.readCustomBlockingScheduleData(jsonData: data!)
                    }else{
                        // local cache added v3.32.487
                        addLog(text: "Blocking schedules API failed. Loading local cache.")
                        customBlockingScheduleManagerObj.loadBlockingSchedulesFromLocal()
                    }
                })
                // added on 18/11/25 v2.27.432
                allApiObject.getAllBuddies(completionHandler: {data in
                    if let data = data{
                        convertJsonToBuddies(json: data)
                    }
                })
                
                //  ------------------------------------------------------------------------------------
                addLog(text: "get user Details Info")
                allApiObject.getAllFocusModes(completionHandler: {dic in
                    if let arrFocusModes = dic as? [[String:Any]]{
                        var newArr = [[String:Any]]()
                        
                        for i in 0..<arrFocusModes.count{
                            var focusDic = arrFocusModes[i]
                            focusDic.removeValue(forKey: "created_at")
                            focusDic.removeValue(forKey: "updated_at")
                            focusDic.removeValue(forKey: "user_id")
                            focusDic.removeValue(forKey: "deleted_at")
                            focusDic.removeValue(forKey: "doNotSuggestAnyMore")
                            var newDic = [String:Any]()
                            for key in focusDic.keys{
                                if key == "metadata"{
                                    if let metaDataDic = focusDic["metadata"] as? [String:Any]{
                                        for key in metaDataDic.keys{
                                            newDic[key] = metaDataDic[key]
                                        }
                                    }
                                }else if key == "tags"{
                                    if let arrTags = focusDic["tags"] as? [NSDictionary]{
                                        var arrtags = [String]()
                                        for tagInfo in arrTags{
                                            arrtags.append(tagInfo["text"] as? String ?? "")
                                        }
                                        newDic["tags"] = arrtags
                                    }
                                }else{
                                    newDic[key] = focusDic[key]
                                }
                            }
                            newDic.removeValue(forKey: "doNotSuggestAnyMore")
                            print(newDic)
                            print("////////\(newArr.count)")
                            newArr.append(newDic)
                            
                        }
                        
                        UserDefaults.standard.set(plistSafeFocusModes(newArr), forKey: kUserdefaultsArrFocusTypes)
                    }
                    
                    checkAllFocusModes()
                })
                
                allApiObject.getuserDetailsSummary(completionHandler: {dic in
                    if dic != nil{
                        isEmailVerified = dic?.value(forKey: "email_verified") as? Bool ?? false
                        
                        if isCurrentUserGuestAccount(){
                            addLog(text: "No need to verify email. Reason: Guest account.")
                            isEmailVerified = true
                        }
                        
                        addLog(text:"isEmailVerified :- \(isEmailVerified)")
                        self.needToCheckEmailVerification = false
                        currentUserEmail = dic?.value(forKey: "email") as? String ?? ""
                        currentUserName = dic?.value(forKey: "name") as? String ?? ""
                        currentLeaderboardUsername = dic?.value(forKey: "username") as? String ?? ""
                        self.sharedDefaults?.setValue(currentUserEmail, forKeyPath: kUserdefaultsSharedUserEmail)
                        self.sharedDefaults?.setValue(currentUserName, forKeyPath: kUserdefaultsSharedUserName)
                        self.sharedDefaults?.setValue(currentLeaderboardUsername, forKeyPath: kUserdefaultsSharedLeaderboardUsername)
                        self.sharedDefaults?.synchronize()
                        DispatchQueue.main.async {
                            accountVcObj?.reloadView()
                        }
                    }
                    
                    
                    DispatchQueue.main.async {
                        self.checkActivationState()
                    }
                })
                
                
                self.updaterController?.updater.checkForUpdatesInBackground()
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidWakeNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidSleepNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.didWakeNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.willSleepNotification, object: nil)
                
                
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"),object: nil)
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstop"),object: nil)
                
                
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),object: nil)
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.macWillPowerOff(_:)), name: NSWorkspace.willPowerOffNotification, object: nil)
            }
        }
        )
    }
    
    @objc private func macWillPowerOff(_ aNotification: Notification) {
        //respond to the power-off notification
        addLog(text: "func:- macWillPowerOff")
        //        createLaunchAgent()
        startMainAppForceQuitMonitoring()
        terminateFromSelf = true
        disableAllAlertsBeforeQuit()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard !LogicTestHost.isEnabled else { return }
        // #2575: the app is now running, so any pending "relaunch me at X" request from the
        // "turn everything off until tomorrow" flow is satisfied — clear it so the helper won't
        // relaunch/activate us again. (The helper also clears it when it fires; this covers the case
        // where the user reopens the app manually before that time.)
        sharedDefaults?.removeObject(forKey: kUserdefaultsMainAppScheduledRestartDate)
        sharedDefaults?.synchronize()
        // Armed first, so a hang during the rest of startup is still reported.
        MainThreadWatchdog.shared.start()
        // Both the Do Not Disturb click and the shutdown prompt ask this before taking the menu bar
        // or the screen away from the user, so it has to be watching from launch.
        MenuBarActivityProbe.shared.startMonitoring()
        ManagedBlockingRuntime.shared.restoreLastSession()
        // Insert code here to initialize your application

        // Warm up the native relevance shadow model so it's ready before the first focus-mode URL check.
        RelevanceShadowNativeModel.shared.warmUp()

        // Start Wi-Fi profile auto-switching (#1000)
        WiFiMonitorService.shared.startMonitoring()

        // Let another local process (e.g. a firmware flashing tool) ask us to release the Focus Button
        // serial port via ~/.focusbear/focus-button-command (#1947 / Focus-Button#15,#21).
        FocusButtonCommandChannel.shared.start()

        // Glowing screen-edge border shown while a focus session is running.
        FocusGlowBorderManager.shared.start()

        // ⚠️ applicationDidFinishLaunching runs for EVERYONE on every launch — before the
        // logged-in/onboarding/login decision, and for fresh and logged-out users too. So it is NOT
        // a safe place to start anything that hits authenticated endpoints or assumes a signed-in
        // user: any AllApi call here reaches setCredentialAndUserInfo on failure and runs auth
        // handling before we've decided the launch flow. Put that work in loadAppAndSettings()
        // instead, which only runs once credentials have resolved.
        // Example: the timezone sync and busy-hours reporter used to start here and, being
        // pre-auth, showed fresh users the login screen and looped "please login again" (#2583) —
        // they now start in loadAppAndSettings().

#if DEBUG
        // Offscreen Day Plan mockup render (DEBUG-only; no-op unless FB_MOCKUP_FILE is set); quits when done.
        DayPlanMockup.runIfRequested()
        // Offscreen SwiftUI menu render (DEBUG-only; no-op unless FB_SNAPSHOT_MENU=1). Lets us verify the
        // redesigned menu layout without opening the menu-bar popover.
        if #available(macOS 13.0, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                MenuSnapshot.renderIfRequested()
                if OffscreenRenderLaunch.isMenuSnapshot { NSApp.terminate(nil) }
            }
        }
        // "Create Claude debug task…" Help-menu item (one user only). The user loads asynchronously after
        // launch, so install once it's available.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { ClaudeDebugTaskMenu.installIfAllowed() }
#endif
    }
    func pauseHabitActivityIfRunning(){
        addLog(text: "func:- pauseHabitActivityIfRunning")
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                return;
            }
        }
        
        macGoesInSleepTime = Date()
        if  currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if currentAction == ._INPROGRESS_ && timerViewcontrollerObj?.timer != nil{
                isLastActivityStoppedInRunningState = true
                lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                timerViewcontrollerObj?.timer?.invalidate()
                timerViewcontrollerObj?.timer  = nil
                if timerViewcontrollerObj?.isVideoLodded ?? false{
                    timerViewcontrollerObj?.loadBlankUrl()
                }
                
                //focusButtonService---//
                focusButtonServiceObject.pauseHabit()
                //--------------//
                
                //                refreshFocusModeData()// do not need here//Focus alignment score drops to 0% after resuming from sleep #1321
                isAnyAllowedFocusModeActivityRunning = false
                habitPlayingBeforeMacSleepId = currentHabitPlaying?.id ?? ""////Focus alignment score drops to 0% after resuming from sleep #1321
                closePupUpBlockIfVisible()
                
                currentHabitPlaying = nil
                habitBlockTimerHelper.stopUrlTimer()
                self.timerAllowAppForActivity?.invalidate()
                currentActivityPlaying = nil
                closeSmallCountDownTimerBoxIfVisible()
                
                enableSystemSleep()// dont change current state
            }
        }
    }
    
    func pauseBreakActivityTimerIfRunning(){
        addLog(text: "pause Break Activity Timer Called")
        
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                return;
            }
        }
        if  currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{// no need to check morning or evening habit beacuse now morning evening habits can show breaks
            addLog(text: "return - no need to pause:- \(currentState)")
            return
        }
        
        if getHabitsVcObject().breakTimer != nil{
            getHabitsVcObject().stopActivityTimer()
            isActivityTimerPaused = true
            addLog(text: "pause Break Activity Timer Done")
        }else{
            addLog(text: "Timer Already nil - return")
        }
        
    }
    
    func resumeBreakActivityTimerIfNededed(){
        addLog(text: "resume Break Activity Timer Called")
        checkNaturalBreakFromIdleTimeAfterScreenUnlocked()
        if isActivityTimerPaused{
            isActivityTimerPaused = false
        }else{
            addLog(text: "return - activity was not paused")
            return;
        }
        
        if  currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{
            addLog(text: "return - no need to resume:- \(currentState)")
            return
        }
        
        if getHabitsVcObject().breakTimer == nil{
            getHabitsVcObject().setActivityTimer()
        }else{
            addLog(text: "return - breakTimer is not nil")
        }
    }
    
    
    
    @objc private func sleepEvent(_ aNotification: Notification) {
        //                print("******didwakeup psps*******")
        addLog(text: "sleepEvent")
        
        //        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
        //            addLog(text: "sleepEvent:- subscription expired return")
        //            return;
        //        }
        if aNotification.name == NSWorkspace.screensDidSleepNotification {
            print("screensDidSleepNotification")
            addLog(text: "screensDidSleepNotification")
            
        }else if aNotification.name == NSWorkspace.screensDidWakeNotification {
            print("screensDidWakeNotification")
            addLog(text: "screensDidWakeNotification")
            
        }else if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
            addLog(text: "Going to sleep")
            isSystemSleep = true
            // Drop the realtime socket before the network goes away, so PusherSwift doesn't churn
            // reconnects into a dead network and crash (Network.framework use-after-free, #2125).
            pusherEventsObject.disconnectForSleep()
            if !isScreenLocked{
                pauseBreakActivityTimerIfRunning()
                pauseHabitActivityIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            addLog(text: "Woke up")
            isSystemSleep = false
            pusherEventsObject.reconnectAfterWake()
            TalkingClockManager.shared.restart()
            if !isScreenLocked{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()//always calll this function before returnFromSystemSleepCheckAppStateAgain func
                }else{
                    checkNaturalBreakFromIdleTimeAfterScreenUnlocked()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstart") {//agar screensaver anable h to system slleep se pahle scrrensaver aayga or system sleep hote i jayga
            print("com.apple.screensaver.didstart")
            addLog(text: "com.apple.screensaver.didstart")
            pauseBreakActivityTimerIfRunning()
            pauseHabitActivityIfRunning()
            isScreenSaverStart = true
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstop") {
            print("com.apple.screensaver.didstop")
            addLog(text: "com.apple.screensaver.didstop")
            isScreenSaverStart = false
            if !isSystemSleep && !isScreenLocked{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()
                }else{
                    checkNaturalBreakFromIdleTimeAfterScreenUnlocked()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screenIsLocked") {
            print("com.apple.screenIsLocked")
            addLog(text: "com.apple.screenIsLocked")
            isScreenLocked = true
            if !isSystemSleep && !isScreenSaverStart{
                pauseBreakActivityTimerIfRunning()
                pauseHabitActivityIfRunning()
            }
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screenIsUnlocked") {
            print("com.apple.screenIsUnlocked")
            addLog(text: "com.apple.screenIsUnlocked")
            isScreenLocked = false
            
            if !isSystemSleep && !isScreenSaverStart{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()
                }else{
                    checkNaturalBreakFromIdleTimeAfterScreenUnlocked()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
        }else {
            print("Some other event other than the first four")
        }
        
        
        
        
        if !isFocusModeOn(){
            isAutoFocusPaused = false
            return;
        }
        
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")

            markIndefiniteFocusSleepStartIfNeeded()
            if !isAutoFocusPaused{
                macSleepPauseFocusModeIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")

            excludeIndefiniteFocusSleepDurationIfNeeded()
            if isAutoFocusPaused{
                macWakeupResumeFocusModeIfRunning()
            }

        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstart") {
            print("com.apple.screensaver.didstart")

            markIndefiniteFocusSleepStartIfNeeded()
            macSleepPauseFocusModeIfRunning()

        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstop") {
            print("com.apple.screensaver.didstop")

            excludeIndefiniteFocusSleepDurationIfNeeded()
            if isSystemSleep{
                return;
            }
            if isAutoFocusPaused{
                macWakeupResumeFocusModeIfRunning()
            }
        }else {
            print("Some other event other than the first four")
        }
        
    }
    
    var isActivityTimerPaused = false
    var isSystemSleep = false
    var isScreenSaverStart = false
    var isScreenLocked = false
    var isAutoFocusPaused = false// auto pause when mac goes in sleep mode
    var remainingFocusModeSecondsAfterPaused = 0
    func macSleepPauseFocusModeIfRunning(){// auto pause when mac goes in sleep mode
        addLog(text: "func:- macSleepPauseFocusModeIfRunning")
        if timerForFocusMode != nil{
            isAutoFocusPaused = true
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                focusModeActualDurationPerformed += passedSeconds
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            //            closeTaskPlayerWindowIfVisible()
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
            self.timerCheckAllowedApps?.invalidate()
            if focusEndWarningWcObj != nil{
                if focusEndWarningWcObj?.window?.isVisible ?? false{
                    focusEndWarningWcObj?.window?.close()
                }
            }
            setAppIconForFocusModeScore(probability: nil)
            menuViewControllerObj?.stopFocusModeCountDownTimer()
            
            focusButtonServiceObject.pauseFocusSession()
        }else{
            addLog(text: "return:- timerForFocusMode is nil (auto meetings focus mode started)")
        }
    }
    
    func macWakeupResumeFocusModeIfRunning(){// auto pause when mac goes in sleep mode
        isAutoFocusPaused = false
        print("focus resume")
        addLog(text: "resume Focus Mode If Running")
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                setStatusBarButtonColorForFocusMode(color: nil, colorString: dic["color"] as? String ?? "")
                setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                statusbutton?.imagePosition = .imageLeft
                focusModeTaskString = dic["lastTaskUsed"] as? String ?? ""
                taskCreatedByBlockPopup = ""
                if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
                    let minute = self.remainingFocusModeSecondsAfterPaused / 60
                    getTaskPlayerVcObject().loadView()
                    getTaskPlayerVcObject().loadRequest()
                    shouldReloadTaskPlayer = true
                    showRunningFocusSessionWindow()
                }
                let name = dic["name"] as? String ?? ""
                addLog(text: "\(name) focus mode resumed successfully")// added v 3.32.483 //
                
                //focusButtonService
                focusButtonServiceObject.resumeFocusSession()
                break;
            }
        }
        
        
        
        
        DispatchQueue.global().sync {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
        }
        menuViewControllerObj?.showFocusModeCountDownIfNeeded()
    }

    // A focus session is "indefinite" when it runs with no countdown timer (e.g. a blocking-schedule
    // activated block list). Timered sessions already exclude sleep time via
    // macSleepPauseFocusModeIfRunning / macWakeupResumeFocusModeIfRunning; indefinite ones don't, so we
    // exclude sleep separately (see indefiniteFocusSleepStartDate). isAutoFocusPaused is only set by the
    // timered pause, so gating on it keeps a just-paused timered session out of the indefinite path.
    private var isIndefiniteFocusSessionRunning:Bool {
        return isFocusModeOn() && timerForFocusMode == nil && !isAutoFocusPaused
    }

    // Called when the Mac is about to sleep / the screensaver starts. Records the moment so the sleep
    // gap can be excluded from an indefinite focus session's recorded duration.
    func markIndefiniteFocusSleepStartIfNeeded(){
        guard isIndefiniteFocusSessionRunning, indefiniteFocusSleepStartDate == nil else { return }
        indefiniteFocusSleepStartDate = Date()
        addLog(text: "indefinite focus session: mac sleeping - will exclude idle time from duration")
    }

    // Called on wake / screensaver stop. Pushes the duration segment start forward by the slept
    // interval so `Date() - startFocusModeTimeForPauseAndResume` (used to record the block duration in
    // tryFocusModeFinished) skips the time the Mac was asleep. Idempotent across repeated wake events.
    func excludeIndefiniteFocusSleepDurationIfNeeded(){
        guard let sleepStart = indefiniteFocusSleepStartDate else { return }
        indefiniteFocusSleepStartDate = nil
        let sleptSeconds = Int(Date().timeIntervalSince(sleepStart))
        guard sleptSeconds > 0, let segmentStart = startFocusModeTimeForPauseAndResume else { return }
        startFocusModeTimeForPauseAndResume = segmentStart.addingTimeInterval(TimeInterval(sleptSeconds))
        addLog(text: "indefinite focus session: excluded \(sleptSeconds)s of sleep from focus duration")
    }

    func extendFocusModeFor(minutes:Int){
        addLog(text: "extendFocusModeFor \(minutes)")
        if teacherSessionManagerObject.isTeacherSessionActive(){// the teacher owns the schedule of a class session
            return;
        }
        // Extending must leave AI relevance checking exactly as it was — same block list, same
        // `is_ai_enabled`. Captured here and re-asserted once the extension has been applied.
        let blockingContextBeforeExtension = FocusSessionExtension.captureBlockingContext()
        if minutes > 0{
            if isFocusModeOn(){
                if timerForFocusMode != nil{
                    if let fireDate =  startFocusModeTimeForPauseAndResume{
                        let interval = focusModeSecondsToPerform
                        let now = Date()
                        let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: now).second ?? 0
                        let remainingFocusModeSeconds = max(0, interval - passedSeconds)
                        let baseEnd = max(now, endFocusModeTime ?? now.addingTimeInterval(TimeInterval(remainingFocusModeSeconds)))
                        let grantedMinutes = FocusSessionExtension.cutoffLimitedMinutes(minutes, from: baseEnd, now: now)
                        guard grantedMinutes > 0 else { return }
                        let grantedEnd = baseEnd.addingTimeInterval(TimeInterval(grantedMinutes * 60))
                        focusModeActualDurationPerformed += passedSeconds
                        addLog(text: "Remaining seconds \(remainingFocusModeSeconds)")
                        
                        //focusButtonService
                        focusButtonServiceObject.updateFocusDuration(seconds: remainingFocusModeSeconds)
                        //---------//
                        
                        timerForFocusMode?.invalidate()
                        timerForFocusMode = nil
                        timerForFocusModeEndNotification?.invalidate()
                        timerForFocusModeEndNotification = nil
                        
                        
                        startFocusModeTimeForPauseAndResume = now
                        focusModeSecondsToPerform = max(0, Int(grantedEnd.timeIntervalSince(now)))
                        endFocusModeTime = grantedEnd
                        timerForFocusMode = Timer(fireAt: grantedEnd, interval: 0, target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
                        RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
                        
                        if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                            timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                            RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
                        }
                        
                        var currentFocusModeIndex = -1
                        for i in 0..<arrFocusType.count{
                            if arrFocusType[i]["id"] as? String == currentRunningFocusType["id"] as? String ?? ""{
                                currentFocusModeIndex = i
                                break;
                            }
                        }
                        if currentFocusModeIndex == -1{
                            currentFocusModeIndex = 0
                        }
                        arrFocusType[currentFocusModeIndex]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
                        
                        allApiObject.extendFocusMode(id: currentRunningFocusType["id"] as? String ?? "", finish_time: endFocusModeTime!, completionHandler: {dic in
                            
                        })
                        updateAllFocusModes()
                        FocusSessionExtension.reapplyBlockingContext(blockingContextBeforeExtension)
                    }
                    
                    
                }
            }
        }
        
    }
    
    func reduceFocusModeFor(minutes:Int){
        addLog(text: "reduceFocusModeFor \(minutes)")
        if teacherSessionManagerObject.isTeacherSessionActive(){// reducing the duration would be an early stop of a teacher controlled session
            teacherSessionManagerObject.showTeacherSessionLockedAlert()
            return;
        }
        if minutes > 0{
            if isFocusModeOn(){
                if timerForFocusMode != nil{
                    if let fireDate =  startFocusModeTimeForPauseAndResume{
                        let interval = focusModeSecondsToPerform
                        let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                        focusModeActualDurationPerformed += passedSeconds
                        let remainingFocusModeSeconds = interval - passedSeconds
                        addLog(text: "Remaining seconds \(remainingFocusModeSeconds)")
                        
                        //focusButtonService
                        focusButtonServiceObject.updateFocusDuration(seconds: remainingFocusModeSeconds)
                        //---------//
                        
                        timerForFocusMode?.invalidate()
                        timerForFocusMode = nil
                        timerForFocusModeEndNotification?.invalidate()
                        timerForFocusModeEndNotification = nil
                        
                        let reduceSeconds = minutes * 60
                        let newRemainingSeconds = remainingFocusModeSeconds - reduceSeconds
                        
                        // If reduced duration finishes focus mode
                        if newRemainingSeconds <= 0 {
                            focusModeSecondsToPerform = 0
                            endFocusModeTime = Date()
                            focusModeTimerFinished()
                            return
                        }
                        
                        startFocusModeTimeForPauseAndResume = Date()
                        focusModeSecondsToPerform = newRemainingSeconds
                        endFocusModeTime = Calendar.current.date(byAdding: .second, value: focusModeSecondsToPerform, to: Date())
                        timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
                        RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
                        
                        if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                            timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                            RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
                        }
                        
                        var currentFocusModeIndex = -1
                        for i in 0..<arrFocusType.count{
                            if arrFocusType[i]["id"] as? String == currentRunningFocusType["id"] as? String ?? ""{
                                currentFocusModeIndex = i
                                break;
                            }
                        }
                        if currentFocusModeIndex == -1{
                            currentFocusModeIndex = 0
                        }
                        arrFocusType[currentFocusModeIndex]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")
                        
                        allApiObject.extendFocusMode(id: currentRunningFocusType["id"] as? String ?? "", finish_time: endFocusModeTime!, completionHandler: {dic in
                            
                        })
                        
                        updateAllFocusModes()
                    }
                    
                    
                }
            }
        }
        
    }
    
    /// `shouldSyncToServer` mirrors `shouldUpdateFocusButton`: pass false when the pause ORIGINATED
    /// elsewhere (a Pusher `focus-mode-paused` from another device), so applying it locally doesn't
    /// POST it straight back and bounce around the user's devices. Local/UI pauses leave it true so the
    /// backend hears about them and can broadcast to the other devices (FOCUS_SESSION_SYNC.md §6).
    func pauseFocusMode(index:Int, shouldUpdateFocusButton:Bool = true, shouldSyncToServer:Bool = true){
        if timerForFocusMode != nil{
            if shouldSyncToServer{
                let focusModeId = arrFocusType[index]["id"] as? String ?? ""
                allApiObject.pauseFocusMode(id: focusModeId, completionHandler: { _ in })
            }
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                focusModeActualDurationPerformed += passedSeconds
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            
            //focusButtonService
            if shouldUpdateFocusButton{
                focusButtonServiceObject.pauseFocusSession()
            }
            //--
            
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
            timerForFocusModeEndNotification?.invalidate()
            setAppIconForFocusModeScore(probability: nil)
            timerForFocusModeEndNotification = nil
            self.timerCheckAllowedApps?.invalidate()
            menuViewControllerObj?.stopFocusModeCountDownTimer()
            arrFocusType[index]["isPaused"] = true
            arrFocusType[index]["isOn"] = false
            isFocusModeRunning = false
            if focusEndWarningWcObj != nil{
                if focusEndWarningWcObj?.window?.isVisible ?? false{
                    focusEndWarningWcObj?.window?.close()
                }
            }
            leftMenuVcObj?.resetFocusModeTitle()
            leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
            // The TOOLS slot is the To-do list now, and it reloads itself in viewWillAppear — there is
            // nothing to re-show here. The headless player still needs its pending reload.
            reloadHeadlessToDoPlayerIfPending()
            
            if taskPlayerVcObj != nil{
                getTaskPlayerVcObject().notifyToDoPlayerPauseState(isPaused: true)
            }
            
            if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                if focusModeStateVcObj != nil{
                    if focusModeStateVcObj!.isViewVisible{
                        focusModeStateVcObj?.reloadData()
                    }
                }
            }
            if mainWindowControllerObj?.window?.isVisible ?? false{//2.27.421
                if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                    mainViewControllerObj?.showFocusModeState()
                }
            }
            
        }
    }
    
    /// See pauseFocusMode — `shouldSyncToServer` is false when the resume came from another device.
    func resumeFocusMode(index:Int, shouldUpdateFocusButton:Bool = true, shouldSyncToServer:Bool = true){
        if shouldSyncToServer{
            let focusModeId = arrFocusType[index]["id"] as? String ?? ""
            allApiObject.resumeFocusMode(id: focusModeId, completionHandler: { _ in })
        }
        //focusButtonService
        if shouldUpdateFocusButton{
            focusButtonServiceObject.resumeFocusSession()
        }
        //---
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        arrFocusType[index]["isPaused"] = false
        arrFocusType[index]["isOn"] = true
        arrFocusType[index]["lastScheduledEndDate"] = getStringFromDate(date: endFocusModeTime!, dateFormat: "yyyy-MM-dd HH:mm:ss")//
        shouldReloadTaskPlayer = true
        setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[index]["color"] as? String ?? "")
        setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        isFocusModeRunning = true
        if !(menuViewControllerObj?.isViewLoaded ?? false){
            menuViewControllerObj?.loadView()
        }
        DispatchQueue.global().sync {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            
            
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
            
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
            DispatchQueue.main.async {
                menuViewControllerObj?.showFocusModeCountDownIfNeeded()
                
                if leftMenuVcObj != nil{
                    leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
                    reloadHeadlessToDoPlayerIfPending()
                    if taskPlayerVcObj != nil{
                        getTaskPlayerVcObject().notifyToDoPlayerPauseState(isPaused: false)
                    }
                    leftMenuVcObj?.resetFocusModeTitle()
                    if leftMenuVcObj?.boxFocusSession.isSelected ?? false{
                        if focusModeStateVcObj != nil{
                            if focusModeStateVcObj!.isViewVisible{
                                focusModeStateVcObj?.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        addLog(text: "updater Will Relaunch Application")
        print("updater Will Relaunch Application")
        //        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        stopMainAppForceQuitMonitoring()
        terminateFromSelf = true
        disableAllAlertsBeforeQuit()
    }
    
    func checkActivationState(){
        addLog(text: "checkActivationState")
        if isPurchased == true{
            // initial work includes top menu, and habit activities process
            self.initialWork()
            writeSettingForScreeenTime(habitInfo: "")
        }else{//daysLeft
            
            //new work 12/9/22
            if daysLeft <= 0{//if expired than menu is enabled
                //                self.readSettingsJsonDictionary(json: nil)
                self.statusbutton?.wantsLayer = true
                self.statusbutton?.layer?.backgroundColor = NSColor.clear.cgColor
                var expiredBarText = "Expired"
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    expiredBarText = common.value(forKey: "expiredBarText") as? String ?? expiredBarText
                }
                self.statusbutton?.title = expiredBarText
                self.statusbutton?.imagePosition = .imageLeft
                addLog(text: "App started in Expired state")
                
                // change appMode to simple mode
                if SettingsManagerObject.isGeekModeEnabled{
                    SettingsManagerObject.isGeekModeEnabled = false
                    SettingsManagerObject.storedCuddlyModeEnabled = true
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                self.initialWork()
                //
//                closeSplashWindow()
//                addLog(text:"func checkActivationState:- showUpgradeToProNagWindow")
//                showUpgradeToProNagWindow(titleText: "", reason: "app_started_in_expired_mode")
                if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool == true{
                    UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
                }
                writeSettingForScreeenTime(habitInfo: "")
            }else{
                self.initialWork()
                writeSettingForScreeenTime(habitInfo: "")
            }
            //
            
        }
    }
    
    
    func readSettingsJsonDictionary(json:NSDictionary?){
        addLog(text: "read Settings Json Dictionary")
        arrFilteredMorningHabits.removeAll()
        arrPreFilteredMorningHabits.removeAll()
        arrFilteredEveningHabits.removeAll()
        arrAllbreakActivities.removeAll()
        var jsonResult:NSDictionary?
        jsonResult = json
        if jsonResult == nil{
            if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
                //            jsonResult = dic
                if let data = stringDic.data(using: String.Encoding.utf8) {
                    
                    do {
                        jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                        
                    } catch let error as NSError {
                        print(error)
                    }
                }
                
            }else {
                if let path = Bundle.main.path(forResource: "settings", ofType: "json") {//ise na upload krenge na local per save krenege bcos ye us state mai aai hai jab upar se setting utar ni pai na hi koi  settings userdefaults mai nahi mili
                    let url = URL(fileURLWithPath: path)
                    do {
                        let data = try Data(contentsOf: url, options: .mappedIfSafe)
                        do {
                            if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                jsonResult = dicResult
                                
                                if let str = String(data: data, encoding: String.Encoding.utf8){
                                    UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                                }
                            }
                        }catch {
                            print(error)
                        }
                    } catch {
                        // handle error
                    }
                }
            }
        }
        
        
        
        
        // -------------------READING SETTINGS JSON----------------------//
        if jsonResult != nil{
            if let morningHabits = jsonResult!.value(forKey: "morning_activities") as? [NSDictionary] {
                print("morningHabits")
                print(morningHabits)
                for habitDic in morningHabits {
                    let id = habitDic["id"] as? String ?? ""//"image_urls","text_instructions" // completion_requirements
                    var name = habitDic["name"] as? String ?? ""
                    var durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    var logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    let take_notes = habitDic["take_notes"] as? String ?? ""
                    let days_of_week = habitDic["days_of_week"] as? [String] ?? []
                    var tutorial = habitDic["tutorial"] as? String ?? ""
                    let icon = habitDic["habit_icon"] as? String ?? ""
                    let nameWithoutIcon = name
                    
                    if !icon.isEmpty{
                        name = icon + " " + name
                    }
                    
                    
                    if tutorial.isEmpty{
                        if let arrTutorials = habitDic["tutorials"] as? [NSDictionary]{
                            if let tutorialDic = arrTutorials.first{
                                tutorial = tutorialDic.value(forKey: "id") as? String ?? ""
                            }
                        }
                    }
                    
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    let text_instructions = habitDic["text_instructions"] as? String ?? ""
                    let image_urls = habitDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    var useTimer = true
                    let completion_requirements = habitDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{
                        useTimer = false
                        durationSeconds = 86400
                    }
                    var check_list = habitDic["check_list"] as? [String] ?? []
                    if let type = habitDic["choice_type"] as? String{//competency,  "random", check_list
                        if type != "check_list"{
                            check_list.removeAll()
                        }
                    }
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = habitDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode, activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: false, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list, tutorial: tutorial)
                    
                    habit.nameWithoutIcon = nameWithoutIcon
                    habit.habitIcon = icon
                    habit.logQuantityQuestions = arrLogQuantityQuestions
                    habit.fakeIdForDevice = "\(arrFilteredMorningHabits.count + 1)"
                    arrFilteredMorningHabits.append(habit)
                }
            }
            
            arrAllDaysMorningHabits = arrFilteredMorningHabits
            
            
            if let eveningHabits = jsonResult!.value(forKey: "evening_activities") as? [NSDictionary] {
                print("eveningHabits")
                print(eveningHabits)
                for habitDic in eveningHabits {
                    let id = habitDic["id"] as? String ?? ""
                    var name = habitDic["name"] as? String ?? ""
                    var durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    var logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    let take_notes = habitDic["take_notes"] as? String ?? ""
                    let days_of_week = habitDic["days_of_week"] as? [String] ?? []
                    var tutorial = habitDic["tutorial"] as? String ?? ""
                    let icon = habitDic["habit_icon"] as? String ?? ""
                    let nameWithoutIcon = name
                    if !icon.isEmpty{
                        name = icon + " " + name
                    }
                    
                    if tutorial.isEmpty{
                        if let arrTutorials = habitDic["tutorials"] as? [NSDictionary]{
                            if let tutorialDic = arrTutorials.first{
                                tutorial = tutorialDic.value(forKey: "id") as? String ?? ""
                            }
                        }
                    }
                    let priority = habitDic["priority"] as? String ?? ""
                    var isPriorityHigh = false
                    if priority == "HIGH"{
                        isPriorityHigh = true
                    }
                    
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    
                    let text_instructions = habitDic["text_instructions"] as? String ?? ""
                    let image_urls = habitDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    var useTimer = true
                    let completion_requirements = habitDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{
                        useTimer = false
                        durationSeconds = 86400
                    }
                    let check_list = habitDic["check_list"] as? [String] ?? []
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = habitDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    let show_saved_distracting_websites = habitDic["show_saved_distracting_websites"] as? Bool ?? false
                    
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode,activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: isPriorityHigh, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list, tutorial: tutorial)
                    
                    
                    if let cutoff_time = habitDic["cutoff_time_for_doing_activity"] as? String{
                        habit.cutOffTime = getTimeFromString(val: cutoff_time)
                    }
                    
                    habit.nameWithoutIcon = nameWithoutIcon
                    habit.habitIcon = icon
                    habit.showSavedDistractingWebsites = show_saved_distracting_websites
                    habit.logQuantityQuestions = arrLogQuantityQuestions
                    habit.fakeIdForDevice = "\(arrFilteredEveningHabits.count + 1)"
                    arrFilteredEveningHabits.append(habit)
                    
                }
            }
            
            arrAllDaysEveningHabits = arrFilteredEveningHabits
            
            if let breakActivities = jsonResult!.value(forKey: "break_activities") as? [NSDictionary] {
                print("breakActivities")
                print(breakActivities)
                for activityDic in breakActivities {
                    let id = activityDic["id"] as? String ?? ""
                    var name = activityDic["name"] as? String ?? ""
                    var durationSeconds = activityDic["duration_seconds"] as? Int ?? 0
                    let IncludeInEveryBreak = activityDic["include_in_every_break"] as? Bool ?? false
                    let videoUrl = activityDic["video_urls"] as? [String] ?? []
                    var logQuantity = activityDic["log_quantity"] as? Bool ?? false

                    let isOfficeFriendly = activityDic["is_office_friendly"] as? Bool ?? false
                    let allowedFocusMode = activityDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = activityDic["activity_sequence_id"] as? String ?? ""
                    let take_notes = activityDic["take_notes"] as? String ?? ""
                    let icon = activityDic["habit_icon"] as? String ?? ""
                    if !icon.isEmpty{
                        name = icon + " " + name
                    }

                    //"Initially, micro-break with the 'allowed apps' feature were available, but later, the functionality for allowing apps was removed from web settings. However, the implementation still exists within the app. To ensure that the 'allowed apps' micro-break does not occur, we have stopped reading that data accordingly."
                    //                    let allowUrls = activityDic["allowed_urls"] as? [String] ?? []
                    //                    let allowApps = activityDic["allowed_apps"] as? [String] ?? []
                    //                    var openSpecificApps = false
                    //                    if allowApps.count != 0{
                    //                        openSpecificApps = true
                    //                    }
                    //                    var isRandomChoice = false
                    var choiceType:CHOICETYPE = ._NONE_
                    if let type = activityDic["choice_type"] as? String{//competency,  "random", check_list
                        if type == "random"{
                            choiceType = ._RANDOM_
                        }else if type == "competency"{
                            choiceType = ._COMPETENCY_
                        }else if type == "check_list"{
                            choiceType = ._CHECKLIST_
                        }
                    }//"SUM" "AVG"// comapre
                    var arrChoices = [activityChoice]()
                    if let choices = activityDic.value(forKey: "choices") as? [NSDictionary] {
                        for dic in choices{
                            let id = dic["id"] as? String ?? ""
                            var name = dic["name"] as? String ?? ""
                            let videoUrl = dic["video_urls"] as? [String] ?? []
                            let logQuantityQuestion = dic["log_quantity_question"] as? String ?? ""
                            var logQuantity = dic["log_quantity"] as? Bool ?? false
                            let logQuantityType = dic["log_summary_type"] as? String ?? ""
                            let icon = dic["habit_icon"] as? String ?? ""
                            if !icon.isEmpty{
                                name = icon + " " + name
                            }
                            var choice = activityChoice(name: name, urlsArray: videoUrl, logQuantityQuestion: logQuantityQuestion, logQuantity: logQuantity, logQuantityType: logQuantityType, id: id)
                            
                            
                            
                            var arrLogQuantityQuestions = [quantityQuestion]()
                            if let logQuantityQuestions = dic["log_quantity_questions"] as? [NSDictionary]{
                                for questionDic in logQuantityQuestions{
                                    let id = questionDic.value(forKey: "id") as? String ?? ""
                                    let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                                    let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                                    let question = questionDic["question"] as? String ?? ""
                                    let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                                    let min_value_description = questionDic["min_value_description"] as? String ?? ""
                                    let max_value_description = questionDic["max_value_description"] as? String ?? ""
                                    
                                    arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                                }
                            }
                            if arrLogQuantityQuestions.count == 0{
                                logQuantity = false
                            }
                            
                            
                            choice.logQuantityQuestions = arrLogQuantityQuestions
                            arrChoices.append(choice)
                        }
                    }
                    var check_list = activityDic["check_list"] as? [String] ?? []
                    
                    if arrChoices.count == 0 && choiceType == ._RANDOM_{
                        choiceType = ._NONE_
                    }
                    if check_list.count == 0 && choiceType == ._CHECKLIST_{
                        choiceType = ._NONE_
                    }else if check_list.count != 0 && choiceType != ._CHECKLIST_{
                        check_list.removeAll()
                    }
                    
                    if arrChoices.count == 0 && choiceType == ._COMPETENCY_{
                        choiceType = ._NONE_
                    }
                    
                    let text_instructions = activityDic["text_instructions"] as? String ?? ""
                    let image_urls = activityDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    
                    let logQuantityQuestion = activityDic["log_quantity_question"] as? String
                    let logQuantityType = activityDic["log_summary_type"] as? String ?? ""
                    
                    var useTimer = true
                    let completion_requirements = activityDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{
                        useTimer = false
                        durationSeconds = 86400
                    }
                    
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = activityDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    
                    var activity = breakActivity(id: id, name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, urlsArray: videoUrl, logQuantity:logQuantity, choiceType: choiceType, choices: arrChoices, logQuantityQuestion: logQuantityQuestion, openSpecificApps: false, allowUrls: [], allowApps: [], isOfficeFriendly: isOfficeFriendly, allowedFocusMode: allowedFocusMode, logQuantityType: logQuantityType, activity_sequence_id: activity_sequence_id, take_notes: take_notes, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list)
                    activity.logQuantityQuestions = arrLogQuantityQuestions
                    arrAllbreakActivities.append(activity)
                }
            }
            
            if let breakMinutes = jsonResult!.value(forKey: "break_after_minutes") as? Int {
                // break_after_minutes is the single source of truth. Changes are written straight to it
                // (BreakFrequencyStreakTracker.saveNewBreakFrequency → server + re-cached settings), so we
                // read it directly rather than letting a separate local key shadow the server value.
                breakAfterMinutes = breakMinutes
            }
            
            if let customRoutines = jsonResult!.value(forKey: "custom_routines") as? [NSDictionary] {
                // Rebuild the list from this payload rather than appending to it. readSettingsJsonDictionary
                // runs a few times per session — via initialWork() (launch/login, and after an upgrade) and the
                // abort-confirm path — and nothing else clears arrAllCustomRoutine (a plain in-memory global). So
                // without this, each of those events appended another full copy of every custom routine, and
                // CustomRoutinesPanel.reload() renders one NSStackView row per entry — so repeated logins/upgrades
                // accumulate duplicate routines and duplicate rows. Clearing first keeps the list to exactly the
                // current payload. (Defensive: not confirmed as the root cause of the reported Day Plan hang — that
                // would need a trace showing arrAllCustomRoutine had actually grown large.)
                arrAllCustomRoutine.removeAll()
                for routineDic in customRoutines{
                    let title = routineDic.value(forKey: "name") as? String ?? ""
                    let id = routineDic.value(forKey: "activity_sequence_id") as? String ?? ""
                    var startTimeRoutine:Time?
                    var endTimeRoutine:Time?
                    var isTriggerOnDemand = false
                    
                    if let val = routineDic.value(forKey: "start_time") as? String {
                        startTimeRoutine = getTimeFromString(val: val)
                    }
                    
                    if let val = routineDic.value(forKey: "end_time") as? String {
                        endTimeRoutine = getTimeFromString(val: val)
                    }
                    
                    if let trigger = routineDic.value(forKey: "trigger") as? String{
                        if trigger.uppercased() == "ON_DEMAND"{
                            isTriggerOnDemand = true
                        }
                    }
                    let days_of_week = routineDic["days_of_week"] as? [String] ?? []
                    
                    var arrHabits = [habit]()
                    if let routineHabits = routineDic.value(forKey: "standalone_activities") as? [NSDictionary] {
                        
                        for habitDic in routineHabits {
                            let id = habitDic["id"] as? String ?? ""//"image_urls","text_instructions" // completion_requirements
                            var name = habitDic["name"] as? String ?? ""
                            var durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                            let videoUrl = habitDic["video_urls"] as? [String] ?? []
                            var logQuantity = habitDic["log_quantity"] as? Bool ?? false
                            let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                            //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                            let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                            let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                            let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                            let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                            let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                            let take_notes = habitDic["take_notes"] as? String ?? ""
                            let days_of_week = habitDic["days_of_week"] as? [String] ?? []
                            var tutorial = habitDic["tutorial"] as? String ?? ""
                            if tutorial.isEmpty{
                                if let arrTutorials = habitDic["tutorials"] as? [NSDictionary]{
                                    if let tutorialDic = arrTutorials.first{
                                        tutorial = tutorialDic.value(forKey: "id") as? String ?? ""
                                    }
                                }
                            }
                            
                            var openSpecificApps = false
                            if allowApps.count != 0{
                                openSpecificApps = true
                            }
                            let text_instructions = habitDic["text_instructions"] as? String ?? ""
                            let image_urls = habitDic["image_urls"] as? [[String:Any]] ?? []
                            var imgUrls = [String]()
                            for info in image_urls{
                                if let url = info["url"] as? String{
                                    imgUrls.append(url)
                                }
                            }
                            var useTimer = true
                            let completion_requirements = habitDic["completion_requirements"] as? String ?? ""
                            if !completion_requirements.isEmpty{
                                useTimer = false
                                durationSeconds = 86400
                            }
                            var check_list = habitDic["check_list"] as? [String] ?? []
                            if let type = habitDic["choice_type"] as? String{//competency,  "random", check_list
                                if type != "check_list"{
                                    check_list.removeAll()
                                }
                            }
                            var arrLogQuantityQuestions = [quantityQuestion]()
                            if let logQuantityQuestions = habitDic["log_quantity_questions"] as? [NSDictionary]{
                                for questionDic in logQuantityQuestions{
                                    let id = questionDic.value(forKey: "id") as? String ?? ""
                                    let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                                    let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                                    let question = questionDic["question"] as? String ?? ""
                                    let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                                    let min_value_description = questionDic["min_value_description"] as? String ?? ""
                                    let max_value_description = questionDic["max_value_description"] as? String ?? ""
                                    
                                    arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                                }
                            }
                            if arrLogQuantityQuestions.count == 0{
                                logQuantity = false
                            }
                            
                            let icon = habitDic["habit_icon"] as? String ?? ""
                            if !icon.isEmpty{
                                name = icon + " " + name
                            }
                            
                            var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode, activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: false, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list, tutorial: tutorial)
                            
                            habit.logQuantityQuestions = arrLogQuantityQuestions
                            arrHabits.append(habit)
                        }
                    }
                    
                    if arrHabits.count != 0{// Don't include emptry habits array routines  done on 24/7/25 in v 1.26.394
                        let routine = routine(title: title, sequenceId: id, startTime: startTimeRoutine, endTime: endTimeRoutine, triggerOnDemand: isTriggerOnDemand, arrAllHabits: arrHabits, arrAllFilteredHabits: arrHabits, days_of_week: days_of_week)
                        arrAllCustomRoutine.append(routine)
                    }
                }
                
                
            }
            
            if let val = jsonResult!.value(forKey: "startup_time") as? String {
                startTimeString = val
                startTime = getTimeFromString(val: val)
            }
            if let val = jsonResult!.value(forKey: "shutdown_time") as? String {
                shutOffTimeString = val
                shutOffTime = getTimeFromString(val: val)
            }
            
            addLog(text: "startup_time is \(startTimeString)")
            addLog(text: "shutdown_time is \(shutOffTimeString)")
            addLog(text: "break_after_minutes is \(breakAfterMinutes)")// 13/11/25  v 2.27.431
            if let val = jsonResult!.value(forKey: "cutoff_time_for_non_high_priority_activities") as? String {
                cutOffTimeString = val
                cutOffTime = getTimeFromString(val: val)
                addLog(text: "cutoff_time is \(cutOffTimeString)")// 22/7/25  v 1.26.393
            }
            
            has_edited_settings =  jsonResult!.value(forKey: "has_edited_settings") as? Bool ?? false
            writeSettingForScreeenTime(habitInfo: "")
            
            if arrFilteredMorningHabits.count == 0 && arrFilteredEveningHabits.count == 0{
                sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsNoHabitFound)
                sharedDefaults?.synchronize()
            }
        }
        // The app is designed to always have a routine start and shut-off time. If the settings payload
        // was missing `startup_time` / `shutdown_time` (absent key or unparseable), these stay nil — and
        // routine-window code force-unwraps them (startTime!/shutOffTime! appears ~87×), which crashed the
        // app on launch (checkLastHabitShowDate, #2457). Fall back to sensible defaults so they are never
        // nil: routine start 05:15, shut-off 20:00.
        if startTime == nil {
            startTime = Time(hour: 5, minute: 15, second: 0)
            startTimeString = "05:15:00"
            addLog(text: "startup_time missing → defaulting startTime to 05:15")
        }
        if shutOffTime == nil {
            shutOffTime = Time(hour: 20, minute: 0, second: 0)
            shutOffTimeString = "20:00:00"
            addLog(text: "shutdown_time missing → defaulting shutOffTime to 20:00")
        }
    }
    
    var isSettingsLoddedInAppdelegate = false
    /// Set once checkWindowState() has run loadAllWindows(), i.e. the main VCs/windows are set up
    /// and settings (startTime/shutOffTime) are populated. The onboarding "Start using Focus Bear"
    /// hand-off waits on this before showing the main window, so the Day Plan can't be opened before
    /// the app is fully initialised (which crashed getNextRoutineInfo on a nil shutOffTime).
    var isCheckWindowStateDone = false
    /// Set the first time an AppleScript command touches us (see fbNoteScriptingCommand). `tell application
    /// … to <cmd>` LAUNCHES the closed app in the background first and only THEN sends the command, so the
    /// launch itself looks like a normal launch (NSApplicationLaunchIsDefaultLaunchKey is true) — the only
    /// reliable "a script drove us" signal is a command actually arriving. Combined with `!isActive` this
    /// distinguishes a scripting launch (activate the app) from a login/startup launch (leave it backgrounded).
    var didHandleScriptingCommand = false
    /// Guards fbActivateFromBackgroundLaunch so we foreground/clear-splash only once per launch.
    private var didForegroundFromScriptLaunch = false
    func initialWork(){
        addLog(text: "initialWork")
        isAppInitialLodded = true
        self.statusbutton?.action = nil
        
        // -------------------GETTING SETTINGS JSON----------------------//
        var isFirstTime = false
        if UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) == nil{
            isFirstTime = true
        }
        
        // added on 18/11/25 v2.27.432
        if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastUnlockTimeByAccountabilityBuddy) as? Date{
            lastUnlockTimeByAccountabilityBuddy = date
        }
        
        checkIsAnyOldFoucsModeRemaining()
        allApiObject.getSettings(isFirstTime: isFirstTime, packId:"", completionHandler: {val in
            let settings = val?.mutableCopy() as? NSMutableDictionary
            
            if settings != nil{
                if isFirstTime{
                    // Break frequency chosen in onboarding (enableBreaksFromOnboarding seeds 60). Falls
                    // back to 60 if the in-memory global was reset by the time this first-run save runs,
                    // so a fresh user always gets an hourly break out of the box. Persisted here with the
                    // valid full-settings save instead of a standalone PUT (which 400s mid-onboarding).
                    let breakDuration = breakAfterMinutes > 0 ? breakAfterMinutes : 60
                    let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool ?? false
                    if isHabitsDisabled{
                        let startDate = "00:00"
                        let shutOffDate = "23:59"
                        let sleepTime = "23:59"
                        
                        
                        settings!["startup_time"] = startDate
                        settings!["shutdown_time"] = shutOffDate
                        settings!["break_after_minutes"] = breakDuration
                        settings!["sleep_time"] = sleepTime
                        
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsStartupTimeFromOnboarding)
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffTimeFromOnboarding)
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsSleepTimeFromOnboarding)
                        
                        allApiObject.isSettingsValid(settings: settings!, isOnboarding:true, completionHandler: {dic,statusCode  in
                            DispatchQueue.main.async {
                                
                                
                                if dic == nil{
                                    self.readSettingsAndLoadApp(settings: settings)
                                }else{
                                    if statusCode == 200{
                                        let settings = dic?.mutableCopy() as? NSMutableDictionary
                                        self.readSettingsAndLoadApp(settings: settings)
                                        do {
                                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                                UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                                //appdelegate?.readSettingsJsonDictionary(json: nil)//will not do this here
                                            }
                                        } catch let myJSONError {
                                            print(myJSONError)
                                        }
                                    }else{
                                        do {
                                            let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                                            if let str = String(data: data, encoding: String.Encoding.utf8){
                                                UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                                            }
                                        } catch let error as NSError {
                                            print(error)
                                        }
                                        self.readSettingsAndLoadApp(settings: settings)
                                    }
                                }
                            }
                        })
                    }else{
                        // Habits enabled: still sync the onboarding break frequency to the server so it
                        // isn't left local-only (this branch previously just cached). Mirrors the PUT above.
                        settings!["break_after_minutes"] = breakDuration
                        allApiObject.isSettingsValid(settings: settings!, isOnboarding:true, completionHandler: {dic,statusCode  in
                            DispatchQueue.main.async {
                                if dic == nil{
                                    self.readSettingsAndLoadApp(settings: settings)
                                }else{
                                    if statusCode == 200{
                                        let settings = dic?.mutableCopy() as? NSMutableDictionary
                                        self.readSettingsAndLoadApp(settings: settings)
                                        do {
                                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                                UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                            }
                                        } catch let myJSONError {
                                            print(myJSONError)
                                        }
                                    }else{
                                        do {
                                            let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                                            if let str = String(data: data, encoding: String.Encoding.utf8){
                                                UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                                            }
                                        } catch let error as NSError {
                                            print(error)
                                        }
                                        self.readSettingsAndLoadApp(settings: settings)
                                    }
                                }
                            }
                        })
                    }


                }else{
                    do {
                        let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                        if let str = String(data: data, encoding: String.Encoding.utf8){
                            UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                        }
                    } catch let error as NSError {
                        print(error)
                    }
                    self.readSettingsAndLoadApp(settings: settings)
                }
                
                
            }else{
                self.readSettingsAndLoadApp(settings: settings)
            }
            
            
        }
        )
    }
    
    func readSettingsAndLoadApp(settings: NSMutableDictionary?){
        self.readSettingsJsonDictionary(json: settings)
        
        arrAllFocusModeTags = UserDefaults.standard.object(forKey: kUserdefaultsAllFocusModesTags) as? [[String : String]] ?? []
        allApiObject.getFocusModeTags(completionHandler: {arrJson in
            
        })
        
        DispatchQueue.main.async {
            if popUpOfflineWcObj != nil{
                if popUpOfflineWcObj?.window?.isVisible ?? false{
                    addLog(text: "func:- initialWork   popUpOfflineWcObj window visible return")
                    closeSplashWindow()
                    return;
                }
            }
            addLog(text: "func:- initialWork   isSettingsLoddedInAppdelegate done")
            
            self.isSettingsLoddedInAppdelegate = true
            //
            SettingsManagerObject.readLocalSettings()
            if UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                isAppEnable = true
                SettingsManagerObject.writeLocalSettings()
            }
            closeSplashWindow()
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) as? Bool{
                isAppEnable = state
                if state{
                    self.checkWindowState()
                }else{
                    if !getHabitsVcObject().isViewLoaded{
                        getHabitsVcObject().loadView()
                    }
                    self.statusbutton?.wantsLayer = true
                    self.statusbutton?.layer?.backgroundColor = NSColor.clear.cgColor
                    self.statusbutton?.title = buttonStatusStateOffText
                    self.statusbutton?.imagePosition = .imageLeft
                    addLog(text: "App started in Deactivated state")
                    self.loadAllWindows()
                }
            }
            if let date = UserDefaults.standard.object(forKey: kUserdefaults4HourReActivateTime) as? Date{
                if Date().compare(date) == .orderedAscending {
                    //first date is smaller than second
                    DispatchQueue.global().sync {//async {
                        self.timerCheckReactivateTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkFourHourActivateTime), userInfo: nil, repeats: true)
                        RunLoop.main.add((self.timerCheckReactivateTime!), forMode: RunLoop.Mode.common)
                    }
                }else{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                    SettingsManagerObject.enableAppWriteSettings()
                    UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                    addLog(text: "App Reactivated after 4 hours")
                    self.quitAndRestartApp()
                    return;
                }
                
            }else if !isAppEnable && !isPurchased{
                if UserDefaults.standard.object(forKey: kUserdefaultsLastAppAbortedDate) != nil{
                    DispatchQueue.global().sync {
                        self.timerExtraNagsAfterInactivity = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(self.checkExtraNagsAfterInactivity), userInfo: nil, repeats: true)
                        RunLoop.main.add((self.timerExtraNagsAfterInactivity!), forMode: RunLoop.Mode.common)
                    }
                }
            }
            
            
            
            // ---------------------------------SET TOP MENU-------------------------------- //
            self.setTopMenu()
            
            // ---------------------------------FORCE HIDE APP AND ENTER BUTTON WORK SETUP-------------------------------- //
            let eventMask = NSEvent.EventTypeMask(rawValue: NSEvent.EventTypeMask.keyDown.rawValue)
            
            NSEvent.addLocalMonitorForEvents(
                matching: eventMask,
                handler: { event in
                    if event.type == .keyDown {
                        if mainWindowControllerObj == nil{
                            return event;
                        }else if event.window != mainWindowControllerObj?.window{
                            return event;
                        }
                        
                        if event.keyCode == 53 {
                            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.modifierFlags.contains(.control) {
                                addLog(text: "[user-action]ShortCut Clicked Hide main window")
                                if (mainWindowControllerObj?.window!.isVisible)! {
                                    self.abortAllProcess()
                                    mainWindowControllerObj?.window?.close()
                                }
                                hideBlankWindowInSecondaryMonitor()
                            }
                        }else if event.keyCode == 48{// tab
                            if mainWindowControllerObj?.window?.isVisible ?? false && (leftMenuVcObj?.boxHabits.isSelected ?? false || leftMenuVcObj?.boxCustomRoutine.isSelected ?? false || leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                                if (getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)){
                                    if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                        if currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                                            if logQuantityVcObj!.tabClickedSelectNextTextField(backwards: event.modifierFlags.contains(.shift)){
                                                return nil
                                            }
                                        }
                                    }
                                }
                            }
                        }else if event.keyCode == 36 || event.keyCode == 76{
                            // If the user is editing a Day Plan task field (name / duration), the
                            // snooze input, or a field inside the task-details modal (title, duration,
                            // project, details/notes, sub-tasks — see DayPlanTasks.openTaskModal), let
                            // the field handle Return — never start/advance a habit. Scoped by identifier
                            // so OTHER editable fields (e.g. the Log Quantity dialog) keep their existing
                            // Enter behaviour. Uses keyWindow so the snooze popover and task-details
                            // popover (their own windows) are covered too.
                            // NSTextField editing goes through the shared field editor, whose `delegate`
                            // is the NSTextField itself — that's `editor.delegate`. A bare NSTextView
                            // (e.g. the task-details "Details" notes view) IS its own editor and has no
                            // delegate set, so fall back to the editor view itself in that case.
                            if let editor = NSApp.keyWindow?.firstResponder as? NSText,
                               let edited = (editor.delegate as? NSView) ?? (editor as? NSView),
                               let fid = edited.identifier?.rawValue,
                               fid.hasPrefix("name:") || fid.hasPrefix("dur:") || fid == "snoozeInput"
                                   || fid.hasPrefix("taskModal") || fid == "projectFilter" {
                                return event
                            }
                            // Log Quantity dialog: Return always commits the entered value via OK,
                            // regardless of the current routine state/action. The state-nested handlers
                            // below reach btnOkClicked only on some paths (they miss e.g. the action-bar /
                            // past-habit and _SPECIAL_ACTIVITY_ entries), so Return did nothing there.
                            // Resign first responder first to commit an in-progress textFieldCount edit
                            // (its value is stored on controlTextDidEndEditing). Returning nil stops the
                            // event so it can't also start/skip a habit — in the borderless full-screen
                            // window a plain default button doesn't receive Return and the habit "Start"
                            // button would otherwise steal it.
                            if let logQ = logQuantityVcObj,
                               getHabitsVcObject().view.subviews.contains(logQ.view) {
                                logQ.view.window?.makeFirstResponder(nil)
                                logQ.btnOkClicked(self)
                                return nil
                            }
                            if mainWindowControllerObj?.window?.isVisible ?? false && (leftMenuVcObj?.boxHabits.isSelected ?? false || leftMenuVcObj?.boxCustomRoutine.isSelected ?? false || leftMenuVcObj?.boxMicroBreaks.isSelected ?? false){
                                if currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                                    if askPostponeVcObj != nil{
                                        if (getHabitsVcObject().view.subviews.contains((getAskPostponeVcObject().view))){
                                            return event
                                        }
                                    }
                                    if skipHabitVcObj != nil{
                                        if (getHabitsVcObject().view.subviews.contains((skipHabitVcObj!.view))){
                                            return event
                                        }
                                    }
                                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                                        if enterPasswordVcObj != nil{
                                            if getHabitsVcObject().view.subviews.contains(enterPasswordVcObj!.view){
                                                return event
                                            }
                                        }
                                    }
                                    if currentAction == ._END_{
                                        if (getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)){
                                            if focusCompletedForActivityVcObj != nil{
                                                if (getHabitsVcObject().view.subviews.contains((focusCompletedForActivityVcObj!.view))){
                                                    return event
                                                }
                                            }
                                            if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                                logQuantityVcObj?.btnOkClicked(self)
                                                return nil
                                            }else{
                                                if activityCompletionVcObj?.boxBg.isHidden == true{// it means remember next habit is added
                                                    if rememberNextHabitVcObj != nil{
                                                        if activityCompletionVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                                                            if rememberNextHabitVcObj?.btnStartNextHabit.isHidden == false{
                                                                rememberNextHabitVcObj?.btnStartNextHabitClicked(self)
                                                                return nil
                                                            }
                                                        }
                                                    }
                                                }else{
                                                    activityCompletionVcObj?.btnMainClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                        
                                    }else if currentAction == ._INPROGRESS_{
                                        if timerViewcontrollerObj != nil{
                                            if (getHabitsVcObject().habitsView.subviews.contains(timerViewcontrollerObj!.view)){
                                                if timerViewcontrollerObj?.boxTimer.isHidden == true{
                                                    timerViewcontrollerObj?.btnIAmDoneClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                        
                                    }else if currentAction == ._START_ {
                                        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._BREATHING_ || currentState == ._CUSTOM_ROUTINE_{
                                            if (getHabitsVcObject().habitsView.subviews.contains(firstViewControllerObj!.view)){
                                                if !firstViewControllerObj!.isTimerGoingOn{
                                                    
                                                    //------------ for action bar work:------------------// added on 10/11/25  v2.27.430
                                                    //now log qantity and  Take Activity Notes view can appear on firstViewControllerObj(habits list view)
                                                    if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                                        logQuantityVcObj?.btnOkClicked(self)
                                                        return nil
                                                    }
                                                    
                                                    if takeActivityNotesVcObj != nil{
                                                        if (getHabitsVcObject().view.subviews.contains((takeActivityNotesVcObj!.view))){
                                                            takeActivityNotesVcObj?.btnOkClicked(self)
                                                            return nil
                                                        }
                                                    }
                                                    //-----------------------------------------------------//
                                                    
                                                    if firstViewControllerObj!.btnStartFirstHabit.isEnabled{
                                                        firstViewControllerObj?.btnStartFirstHabitClicked(self)
                                                        return nil
                                                    }
                                                }
                                            }
                                        }else if currentState == ._MICRO_BREAK_{
                                            // The break start screen is now its own SwiftUI screen; it
                                            // ignores Return while the brain dump has focus so a newline
                                            // there doesn't start the break.
                                            if breakStartVcObj?.startFromReturnKey() ?? false{
                                                return nil
                                            }
                                            if (getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)){
                                                if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                                    logQuantityVcObj?.btnOkClicked(self)
                                                    return nil
                                                }else{
                                                    activityCompletionVcObj?.btnMainClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                    }else if currentAction == ._BRAIN_DUMP_ && breaksBrainDumpVcObj != nil && currentState == ._MICRO_BREAK_{
                                        if (getHabitsVcObject().habitsView.subviews.contains(breaksBrainDumpVcObj!.view)){
                                            if breaksBrainDumpVcObj!.btnMain.isEnabled{
                                                breaksBrainDumpVcObj?.btnMainClicked(self)
                                                return nil
                                            }
                                        }
                                    }else if currentAction == ._VISUALIZE_{
                                        if !getvisualizeInstructionsObject().isTimerGoingOn{
                                            getvisualizeInstructionsObject().btnMainClicked(self)
                                            return nil
                                        }
                                    }
                                }else if currentState == ._SHUTOFFMAC_{//shutoffmac k casemai last evening over hone per log quantity vala nag shutoff k upar aayga
                                    if arrFilteredEveningHabits.count != 0{
                                        if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                            logQuantityVcObj?.btnOkClicked(self)
                                            return nil
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    return event
                }
            )
        }
    }
    
    func setTopMenu(){
        addLog(text: "setTopMenu")
        if let button = statusItem.button{
            button.action = #selector(togglePopoverFromButton(_:))
            
            if SettingsManagerObject.isMenuPopoverEnabled{
                popover.contentViewController = menuViewControllerObj
                popover.animates = false
                popover.behavior = .transient
            }else{
                getMenuWindowObject().contentViewController = menuViewControllerObj
            }
            
            addLog(text: "setTopMenu end")
            
        }
    }
    
    var menuOpenedFromFloatingBar = false
    
    @objc func togglePopoverFromButton(_ sender: Any?) {
        togglePopover(true) // or true, depending on case
    }

    /// Menu-bar click handler used while logged out / on the login screen. The login flows clear the
    /// status button's action (so the popover can't open before sign-in), which left a click doing
    /// nothing. Instead, bring the main app window (login) to the foreground.
    @objc func bringMainWindowToForeground(_ sender: Any?) {
        addLog(text: "[user-action] menu-bar click while logged out — foregrounding main window")
        NSApplication.shared.activate(ignoringOtherApps: true)
        mainWindowControllerObj?.showWindow(nil)
        mainWindowControllerObj?.window?.makeKeyAndOrderFront(nil)
        mainWindowControllerObj?.window?.center()
    }

    @objc func togglePopover(_ isDefaultButton:Bool = true) {
        addLog(text: "togglePopover start")
        // Clicking the menu-bar item activates the app, and that activation reaches
        // applicationDidBecomeActive BEFORE this action is delivered (visible in the user's logs), so the
        // "a menu is open" guard cannot see the menu yet. Declare the activation as ours: the user asked
        // for the menu, not for the full window.
        noteSelfActivation()
        menuOpenedFromFloatingBar = false
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if runningApp.bundleIdentifier != Bundle.main.bundleIdentifier{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    if !arrExcludeAppsInBreaksBrainDumpLastActivateApp.contains(nameLowercased){
                        lastFrontMostApplication = runningApp
                    }
                }
            }
        }
        
        addLog(text: "[user-action] Top bar focus bear button clicked")
        // An open overlay panel closes on this click whatever is frontmost NOW. Clicking the status
        // item can make us the frontmost app, which would make isFrontmostAppCoveringScreen() false
        // and send us down the popover path — opening a SECOND menu on top of the panel.
        if menuShownInOverlayPanel {
            hideMenuOverlayPanel()
            addLog(text: "togglePopover end (overlay panel closed)")
            return
        }
        // Over an app covering the screen (native OR non-native full-screen), neither the popover nor a
        // plain window renders above it — only an NSPanel (.nonactivatingPanel) does (the window type the
        // focus tooltip uses, which the user confirmed shows there). Present the menu in that panel.
        if isFrontmostAppCoveringScreen(), let button = statusItem.button {
            showMenuInOverlayPanel(button: button)
            addLog(text: "togglePopover end (overlay panel)")
            return
        }
        if isFocusBearMenuVisible(){
            // In window mode, if another app is covering the screen (full-screen) the menu may be stuck
            // behind it — re-show it (close + open) so it comes back to the front over the full-screen app,
            // instead of toggling it closed. Otherwise (popover mode, or nothing covering) a click just
            // closes the menu, as normal.
            if !SettingsManagerObject.isMenuPopoverEnabled{
                if isFrontmostAppCoveringScreen(){
                    closePopover()
                    showPopover(isDefaultButton: isDefaultButton)
                }else{
                    closePopover()
                }
            }else{
                closePopover()
            }
        } else{
            addLog(text: "popover is not visible")
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_{
                if currentAction == ._INPROGRESS_{
                    if currentHabitPlaying != nil{
                        if !currentHabitPlaying!.useTimer{
                            showcompletionRequirementsWindow(title: currentHabitPlaying!.completion_requirements)
                        }
                    }else if currentActivityPlaying != nil{
                        if !currentActivityPlaying!.useTimer{
                            showcompletionRequirementsWindow(title: currentActivityPlaying!.completion_requirements)
                        }
                    }else if currentRelaxHabitPlaying != nil{
                        if relaxModeWcObj != nil{
                            relaxModeWcObj!.showWindow(nil)
                        }
                    }
                }
            }
            showPopover(isDefaultButton: isDefaultButton)
            
            addLog(text: "togglePopover end")
        }
    }
    
    func showPopover(isDefaultButton:Bool = true) {
        addLog(text: "showPopover")
        
        if isDefaultButton{
            if let button = statusItem.button{
                // Self-heal the shared menu content. The menu VC can only live in ONE container (the
                // popover OR the detached window); moving it around can leave it detached, which renders
                // an EMPTY menu. Re-attach it to the container that matches the current mode before showing.
                ensureMenuContentAttached()
                // A popover renders on Focus Bear's own Space, so over ANOTHER app's native full-screen
                // Space it stays hidden. The detached window menu shows there fine, so for full-screen
                // temporarily flip to window mode (in-memory only — never persisted) and move the shared
                // menu VC into the window. closePopover() restores popover mode. This reuses all the
                // window-mode plumbing (sizing, outside-click dismiss) rather than fighting NSPopover.
                if SettingsManagerObject.isMenuPopoverEnabled, isFrontmostAppInNativeFullScreen() {
                    menuFlippedToWindowForFullScreen = true
                    SettingsManagerObject.isMenuPopoverEnabled = false
                    if popover.isShown { popover.performClose(nil) }
                    popover.contentViewController = nil
                    getMenuWindowObject().contentViewController = menuViewControllerObj
                }
                if SettingsManagerObject.isMenuPopoverEnabled{
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    // Make the POPOVER'S own window key (not the status button's) so the .transient popover
                    // arms its outside-click auto-dismiss.
                    menuViewControllerObj?.view.window?.makeKey()

                    // Raise the popover to .popUpMenu and let it join all spaces so it appears over another
                    // app's full-screen space (and stays visible under Stage Manager). popUpMenu (vs the old
                    // .statusBar) sits ABOVE an app's traditional full-screen window, which occludes lower
                    // levels.
                    if let window = popover.contentViewController?.view.window {
                        window.level = .popUpMenu
                        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                    }
                }else{
                    let wc = getMenuWindowObject()
                    wc.showWindow(self)
                    if menuFlippedToWindowForFullScreen {
                        // Position under the status icon and make the window able to sit on the active
                        // full-screen Space, then order it front WITHOUT activating Focus Bear (which
                        // would yank the user out of the full-screen app).
                        positionMenuWindowUnderStatusItem(button: button)
                        wc.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                        wc.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
                        wc.window?.orderFrontRegardless()
                        wc.window?.makeKey()
                        installMenuOutsideClickMonitors()
                    } else {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
                addLog(text: "showPopover End")
            }
        }else{
            if let button = floatingTopBarVcObj?.boxFakeView{
                if SettingsManagerObject.isMenuPopoverEnabled{
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    menuViewControllerObj?.view.window?.makeKey()
                }else{
                    getMenuWindowObject().showWindow(self)
                    if let barMidxPoint = floatingTopBarWcObj?.window?.frame.midX, let barMidBottomYPoint = floatingTopBarWcObj?.window?.frame.minY{
                        let boxMainMaxY = floatingTopBarVcObj?.boxMain.frame.maxY ?? 134
                        
                        let minXPoint = barMidxPoint - ((menuViewControllerObj?.view.window?.frame.width ?? 300) / 2)
                        let minYPoint = barMidBottomYPoint - (menuViewControllerObj?.view.window?.frame.height ?? 300) + boxMainMaxY// 100 is timer box height
                        getMenuWindowObject().window?.setFrameOrigin(NSPoint(x: minXPoint, y: minYPoint))
                        
                    }
                    
                }
                NSApplication.shared.activate(ignoringOtherApps: true)
                addLog(text: "showPopover End")
            }
        }
        
        // Menu dark theme bug solved v 3.31.476
        if let popoverView = popover.contentViewController?.view.superview {
            switch SettingsManagerObject.selectedAppAppearanceIndex {
            case 0:
                popoverView.appearance = NSApp.effectiveAppearance
            case 1:
                popoverView.appearance = NSAppearance(named: .darkAqua)
            case 2:
                popoverView.appearance = NSAppearance(named: .aqua)
            default:
                break;
            }
        }


        // Window mode is a pinned, detached window: it should stay open until the user explicitly
        // closes it (a menu action, the pin toggle, or clicking the status item) — so we no longer
        // auto-dismiss it on an outside click, which made window mode behave just like the popover.
        // Popover mode keeps its own .transient auto-dismiss; nothing to install here.

        raiseMenuAboveBlockBuddyBlurIfVisible()
    }

    /// The AI-block "Quick check-in" buddy raises a dimming blur backdrop (`blurWcObj`) at
    /// modalPanelWindow level. The Focus Bear menu sits at the SAME level — both the unpinned popover's
    /// own window and the pinned detached window (`getMenuWindowObject()`) — so the blur covers the menu
    /// and the user can't reach it (e.g. to stop the session) while the buddy is up. When the blur is
    /// visible, raise whichever menu presentation is active to popUpMenuWindow level (matching the buddy
    /// dialog at `AiBlockBuddyScreen`) so it renders ABOVE the blur; restore the pinned window's normal
    /// modalPanelWindow level once the blur is gone (unless it's deliberately raised for native
    /// full-screen). The full-screen overlay-panel path already sits at popUpMenuWindow, so it's
    /// unaffected. No-op for normal (no-blur) menu z-order.
    private func raiseMenuAboveBlockBuddyBlurIfVisible() {
        let blurVisible = blurWcObj?.window?.isVisible == true
        // screenSaver level (1000) is definitively above the blur (modalPanel 8) AND the buddy dialog
        // (popUpMenu 101) — a plain popUpMenu raise wasn't beating the blur in practice.
        let overBlurLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow)))
        let modalPanelLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        if blurVisible {
            let target: NSWindow? = SettingsManagerObject.isMenuPopoverEnabled ? menuViewControllerObj?.view.window : getMenuWindowObject().window
            target?.level = overBlurLevel
            target?.orderFrontRegardless()
            addLog(text: "raiseMenuAboveBlur: popover=\(SettingsManagerObject.isMenuPopoverEnabled) menuLvl=\(target?.level.rawValue ?? -999) blurLvl=\(blurWcObj?.window?.level.rawValue ?? -999) buddyLvl=\(aiBlockBuddyWcObj?.window?.level.rawValue ?? -999)")
        } else if !menuFlippedToWindowForFullScreen {
            getMenuWindowObject().window?.level = modalPanelLevel
        }
    }

    /// True while the menu is temporarily shown as a detached window because the frontmost app is in
    /// native full-screen (popover mode can't render there). closePopover() uses this to restore
    /// popover mode. Never persisted — the user's isMenuPopoverEnabled setting is untouched.
    var menuFlippedToWindowForFullScreen = false

    /// Ensure the shared menu view controller is attached to the container for the CURRENT mode (popover
    /// when `isMenuPopoverEnabled`, else the detached window). The VC can only be in one place at a time,
    /// so a mode flip / earlier full-screen experiment can leave it detached → an empty menu. Idempotent.
    private func ensureMenuContentAttached() {
        if menuViewControllerObj == nil {
            menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController
        }
        if SettingsManagerObject.isMenuPopoverEnabled {
            if popover.contentViewController !== menuViewControllerObj {
                getMenuWindowObject().contentViewController = nil
                popover.contentViewController = menuViewControllerObj
                popover.animates = false
                popover.behavior = .transient
            }
        } else {
            if getMenuWindowObject().contentViewController !== menuViewControllerObj {
                popover.contentViewController = nil
                getMenuWindowObject().contentViewController = menuViewControllerObj
            }
        }
    }

    // MARK: - Full-screen overlay panel

    /// A borderless NON-ACTIVATING panel used ONLY to show the menu over another app that's covering the
    /// screen (native or non-native full-screen). An NSPanel(.nonactivatingPanel) renders on the active
    /// full-screen Space where a plain NSWindow does NOT (it's the window type the focus tooltip uses,
    /// which the user confirmed shows over their full-screen). Lazily created, reused.
    private var menuOverlayPanel: NSPanel?
    var menuShownInOverlayPanel = false

    private func getMenuOverlayPanel() -> NSPanel {
        if let panel = menuOverlayPanel { return panel }
        let panel = MenuOverlayPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
                                     styleMask: [.nonactivatingPanel, .borderless],
                                     backing: .buffered, defer: false)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        menuOverlayPanel = panel
        // `isFloatingPanel` rewrites the level, so record what the panel actually settled on and
        // restore that on every show — otherwise one appearance over the buddy's blur left the panel
        // pinned at screen-saver level for the rest of the session (seen as lvl=1000 in the logs).
        menuOverlayPanelRestingLevel = panel.level
        return panel
    }

    /// The overlay panel's level when it is not being raised above the AI-block buddy's blur.
    private var menuOverlayPanelRestingLevel: NSWindow.Level = .floating

    /// Host the shared menu VC in the overlay panel, position it under the status icon and show it over the
    /// full-screen app. Detaches the VC from the popover/window (only one container can own it).
    private func showMenuInOverlayPanel(button: NSStatusBarButton) {
        if popover.isShown { popover.performClose(nil) }
        if getMenuWindowObject().window?.isVisible ?? false { getMenuWindowObject().window?.close() }
        if menuViewControllerObj == nil {
            menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController
        }
        popover.contentViewController = nil
        getMenuWindowObject().contentViewController = nil
        let panel = getMenuOverlayPanel()
        panel.contentViewController = menuViewControllerObj
        panel.layoutIfNeeded()
        if let size = menuViewControllerObj?.view.fittingSize, size.width > 1, size.height > 1 {
            panel.setContentSize(size)
        }
        if let buttonWindow = button.window {
            let screenRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
            panel.setFrameTopLeftPoint(NSPoint(x: screenRect.midX - panel.frame.width / 2, y: screenRect.minY))
        }
        // If the AI-block buddy's blur backdrop is up, raise the panel above it (screenSaver level beats
        // the blur AND the buddy dialog) so the menu isn't hidden behind the blur over a full-screen app.
        if blurWcObj?.window?.isVisible == true {
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.screenSaverWindow)))
        } else {
            panel.level = menuOverlayPanelRestingLevel
        }
        panel.orderFrontRegardless()
        menuShownInOverlayPanel = true
        installMenuOutsideClickMonitors(force: true)
        addLog(text: "overlay panel shown: onActiveSpace=\(panel.isOnActiveSpace) visible=\(panel.isVisible) lvl=\(panel.level.rawValue) blurVis=\(blurWcObj?.window?.isVisible ?? false) blurLvl=\(blurWcObj?.window?.level.rawValue ?? -999) buddyLvl=\(aiBlockBuddyWcObj?.window?.level.rawValue ?? -999) frame=\(panel.frame)")
    }

    /// Close the overlay panel and return the menu VC to the popover/window for the next normal open.
    func hideMenuOverlayPanel() {
        removeMenuOutsideClickMonitors()
        menuOverlayPanel?.orderOut(nil)
        menuOverlayPanel?.contentViewController = nil
        menuShownInOverlayPanel = false
        ensureMenuContentAttached()
    }

    /// Place the detached menu window directly beneath the status-bar icon.
    private func positionMenuWindowUnderStatusItem(button: NSStatusBarButton) {
        guard let win = getMenuWindowObject().window, let buttonWindow = button.window else { return }
        let screenRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        win.setFrameTopLeftPoint(NSPoint(x: screenRect.midX - win.frame.width / 2, y: screenRect.minY))
    }

    func closePopover() {
        addLog(text: "closePopover")
        if menuShownInOverlayPanel { hideMenuOverlayPanel(); return }
        removeMenuOutsideClickMonitors()
        if SettingsManagerObject.isMenuPopoverEnabled{
            popover.performClose(nil)
        }else{
            getMenuWindowObject().window?.close()
        }
        // Restore popover mode if we temporarily flipped to a window for a full-screen app, moving the
        // shared menu VC back onto the popover so the next normal open works.
        if menuFlippedToWindowForFullScreen {
            menuFlippedToWindowForFullScreen = false
            getMenuWindowObject().contentViewController = nil
            SettingsManagerObject.isMenuPopoverEnabled = true
            popover.contentViewController = menuViewControllerObj
            popover.animates = false
            popover.behavior = .transient
        }
    }

    /// Watch for clicks outside the menu window and close it (the window doesn't auto-dismiss like a
    /// .transient popover). Global monitor catches clicks in other apps; local monitor catches clicks
    /// elsewhere in our own app. Only used in window mode.
    ///
    /// Both monitors hand the event to `MenuOutsideClickPolicy`, which is the only place allowed to
    /// answer "was that click away from the menu". The global monitor's event carries no window of
    /// ours, so it is classified by screen location instead.
    func installMenuOutsideClickMonitors(force: Bool = false) {
        guard force || !SettingsManagerObject.isMenuPopoverEnabled else { return }
        removeMenuOutsideClickMonitors()
        menuOutsideClickMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closeMenuIfClickedOutside(event)
        }
        menuOutsideClickMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.closeMenuIfClickedOutside(event)
            return event
        }
    }

    func removeMenuOutsideClickMonitors() {
        if let m = menuOutsideClickMonitorGlobal { NSEvent.removeMonitor(m); menuOutsideClickMonitorGlobal = nil }
        if let m = menuOutsideClickMonitorLocal { NSEvent.removeMonitor(m); menuOutsideClickMonitorLocal = nil }
    }

    /// The actions a user's click fires to OPEN or close the menu. A mouse-down on a control wired to
    /// one of them is the toggle, which reaches `togglePopover` a moment later — dismissing the menu
    /// from the monitor would only hide it microseconds before that action re-shows it.
    private static let menuToggleActions: Set<Selector> = [
        #selector(AppDelegate.togglePopoverFromButton(_:)),
        #selector(AppDelegate.bringMainWindowToForeground(_:)),
        #selector(floatingTopBarVc.btnBarClicked(_:))
    ]

    /// Did the click land on the chrome that owns the menu — the status-bar icon, or the floating
    /// bar's menu button? The status item is answered by geometry (we hold the button, and its window
    /// is a private AppKit class not worth matching); anything else by what the control under the
    /// click actually does.
    private func clickHitsMenuOwnerChrome(_ event: NSEvent) -> Bool {
        let clicked = event.window
        let location = event.locationInWindow
        let statusButton = statusItem.button
        // A windowless event (the global monitor, and any status-item click macOS reports that way)
        // carries its location in screen coordinates.
        let hitStatusItem = clicked == nil
            ? MenuOutsideClickPolicy.hits(statusButton, screenLocation: location)
            : MenuOutsideClickPolicy.hits(statusButton, clickedWindow: clicked, locationInWindow: location)
        if hitStatusItem { return true }
        let viewUnderClick = MenuOutsideClickPolicy.viewUnderClick(in: clicked, locationInWindow: location)
        return MenuOutsideClickPolicy.togglesMenu(viewUnderClick: viewUnderClick,
                                                  toggleActions: AppDelegate.menuToggleActions)
    }

    /// Where a monitored click landed, relative to the menu currently on screen.
    private func menuClickTarget(for event: NSEvent?, menu: NSWindow?) -> MenuOutsideClickPolicy.ClickTarget {
        guard let event else { return .otherApplication }
        return MenuOutsideClickPolicy.target(clickedWindow: event.window, menu: menu,
                                             hitOwnerChrome: clickHitsMenuOwnerChrome(event)) { window, menuWindow in
            guard let window = window as? NSWindow, let menuWindow = menuWindow as? NSWindow else { return false }
            return MenuWindowOwnership.isOwned(window, by: menuWindow)
        }
    }

    private func closeMenuIfClickedOutside(_ event: NSEvent?) {
        // Full-screen overlay panel: dismiss on a click away from it. Trust the panel's own
        // visibility, not just the flag, so a stale flag tidies up once instead of on every click.
        if menuShownInOverlayPanel {
            let panel = menuOverlayPanel
            guard panel?.isVisible == true else { hideMenuOverlayPanel(); return }
            let target = menuClickTarget(for: event, menu: panel)
            guard MenuOutsideClickPolicy.decide(target: target, isMenuVisible: true) == .dismiss else { return }
            addLog(text: "overlay panel dismissed by click: \(target)")
            hideMenuOverlayPanel()
            return
        }
        guard let menuWindow = menuWcObj?.window, menuWindow.isVisible else { removeMenuOutsideClickMonitors(); return }
        // A click inside the menu window — or inside a sheet / child window it presented, such as the
        // to-do task editor — must not dismiss it, and neither must the click on the icon that owns it.
        let target = menuClickTarget(for: event, menu: menuWindow)
        guard MenuOutsideClickPolicy.decide(target: target, isMenuVisible: true) == .dismiss else { return }
        addLog(text: "menu window dismissed by click: \(target)")
        closeMenuWindowIsVisible()
        removeMenuOutsideClickMonitors()
    }
    
    @objc func menuItem_Reactivate(){
        timerCheckReactivateTime?.invalidate()
        timerCheckReactivateTime = nil
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
        SettingsManagerObject.enableAppWriteSettings()
        UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Reactivated by user from top menu")
        appdelegate?.quitAndRestartApp()
    }
    @objc func checkFourHourActivateTime(){
        backgroundThread()//7 may 2022 (if you abort Habits, it shouldn't skip the evening routine #56)
        DispatchQueue.main.async {
            if let date  = UserDefaults.standard.object(forKey: kUserdefaults4HourReActivateTime) as? Date{
                if Date().compare(date) == .orderedAscending {
                    //first date is smaller than second
                }else{
                    self.timerCheckReactivateTime?.invalidate()
                    self.timerCheckReactivateTime = nil
                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                    SettingsManagerObject.enableAppWriteSettings()
                    UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                    addLog(text: "App Reactivated after 4 hours")
                    appdelegate?.quitAndRestartApp()
                }
            }else{
                self.timerCheckReactivateTime?.invalidate()
                self.timerCheckReactivateTime = nil
            }
        }
    }
    
    @objc func checkExtraNagsAfterInactivity(){
        DispatchQueue.main.async {
            if shareFeedbackWindowControllerObj != nil{
                if shareFeedbackWindowControllerObj?.window?.isVisible ?? false{
                    return;
                }
            }
            if let date  = UserDefaults.standard.object(forKey: kUserdefaultsLastAppAbortedDate) as? Date{
                var shouldShowNag = false
                let currentDate = Date()
                if let lastFocusModeDoneDate = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeDoneDate) as? Date{
                    let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                    
                    let diffHoursLastFocus = Calendar.current.dateComponents([.hour], from: lastFocusModeDoneDate, to: currentDate).hour ?? 0
                    if diffHours > 72  && diffHoursLastFocus > 72{
                        shouldShowNag = true
                    }
                    
                }else{
                    
                    let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                    if diffHours > 72 {
                        shouldShowNag = true
                    }
                    
                }
                
                if shouldShowNag{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastInactivityNagShowDate) as? Date{
                        let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                        if diffHours > 72 {
                            shouldShowNag = true
                        }else{
                            shouldShowNag = false
                        }
                    }else{
                        //show nag
                        shouldShowNag = true
                    }
                }
                
                
                if shouldShowNag{
                    self.showExtraNagsAfterInactivity()
                }
            }
        }
    }
    
    func showExtraNagsAfterInactivity(){
        addLog(text: "show Extra Nag After Inactivity")
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastInactivityNagShowDate)
        let alertExtraNagAfterInactivity = NSAlert()
        alertExtraNagAfterInactivity.messageText = "Still interested in improving your habits and productivity?"
        var buttonDoItText = "Yeah - let's do it"
        var buttonCancelText = "No thanks"
        
        
        if let inactivityNagInfo = configjson.value(forKey: "inactivityNagInfo") as? NSDictionary{
            alertExtraNagAfterInactivity.messageText = inactivityNagInfo.value(forKey: "title") as? String ?? alertExtraNagAfterInactivity.messageText
            buttonDoItText = inactivityNagInfo.value(forKey: "buttonDoItText") as? String ?? buttonDoItText
            buttonCancelText = inactivityNagInfo.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        }
        
        alertExtraNagAfterInactivity.setSharingType()
        
        
        alertExtraNagAfterInactivity.addButton(withTitle: buttonDoItText)
        alertExtraNagAfterInactivity.addButton(withTitle:  buttonCancelText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        let result = alertExtraNagAfterInactivity.runModal()
        if result == .alertFirstButtonReturn{
            addLog(text: "[user-action] button Do It Clicked")
            menuItem_Reactivate()
        }else if result == .alertSecondButtonReturn{
            addLog(text: "[user-action] button No thanks Clicked")
            showShareFeedbackWindow()
        }
    }
    @objc func checkTwentyFourHourActivateTime(){
        DispatchQueue.main.async {
            if let date  = UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) as? Date{
                if Date().compare(date) == .orderedAscending {
                    //first date is smaller than second
                }else{
                    self.timerCheckClearPasswordTime?.invalidate()
                    self.timerCheckClearPasswordTime = nil
                    UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
                    UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    addLog(text: "password is cleard after 24 hours")
                }
            }else{
                self.timerCheckClearPasswordTime?.invalidate()
                self.timerCheckClearPasswordTime = nil
            }
        }
    }
    
    /// `coverWithSplash` keeps the splash screen up across the restart: shown now, before this process
    /// quits, and again by the relaunched app (the "restarted normally" flag is what suppresses it on
    /// relaunch, so it is deliberately NOT set). Used after routine edits so the user isn't left with an
    /// unguarded desktop while the app comes back — a silent restart is fine for enable/disable toggles.
    func quitAndRestartApp(coverWithSplash: Bool = false){
        print("quitAndRestartApp")
        addLog(text: "quitAndRestartApp coverWithSplash=\(coverWithSplash)")
        if coverWithSplash {
            showSplashWindow()
        }
        let task = Process()
        var args: [AnyHashable] = []
        args.append("-c")
        args.append("sleep \(1); open \"\(Bundle.main.bundlePath)\"")
        task.launchPath = "/bin/sh"
        task.arguments = args as? [String]
        task.launch()
        if !coverWithSplash {
            UserDefaults.standard.set(true, forKey: kUserDefaultsAppRestartedNormally)
        }
        terminateFromSelf = true
        quitApplicationSmoothly()
    }
    
    @objc func showAutoPomodoroModeView(){
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        isFocusBreakOn = false
        if !SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "simple Mode is enabled:- Show Simple Pomodoro Mode View.")
            menuShowSimplePomodoroModeView()
            isHardCorePomodoroModeOn = false
            return;
        }
        
        
        if savedSitesForLaterWcObj != nil{
            if savedSitesForLaterWcObj!.window?.isVisible ?? false{
                savedSitesForLaterWcObj!.close()
            }
        }
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "Focus mode completed view is visible:- return")
            isHardCorePomodoroModeOn = false
            return;
        }
        
        if !isAppEnable{
            addLog(text: "App is Disabled: Pomodoro Mode View cancelled")
            isHardCorePomodoroModeOn = false
            return
        }
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
            isHardCorePomodoroModeOn = false
            return
        }
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._FOCUS_SUMMARY_ || currentState == ._CUSTOM_ROUTINE_{
            addLog(text: "Habit is running: Pomodoro Mode View cancelled")
            isHardCorePomodoroModeOn = false
            return;
        }
        
        if currentState == ._MICRO_BREAK_{
            //Super Focus session stops blocking after closing the break popup; session remains active but blocking and timer disappear#1572  v 2.28.440   (resume super pomodoro after micro breaks)
            addLog(text: "Micro Activity is running: Pomodoro Mode View cancelled")
            return;
        }
        
        if !isHardCorePomodoroModeOn{// if hardcore pomodoro is started than it will complete first
            if isUserOnMeeting{
                addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
                isHardCorePomodoroModeOn = false
                return
            }
        }
        
        if currentState == ._SHUTOFFMAC_{
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            isHardCorePomodoroModeOn = false
            return;//if not working hours then return
        }
        
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        
        mainWindowControllerObj?.showWindow(self)
        leftMenuVcObj?.showPomodoro(pomodoroVcObj: pomodoroVcObj!.view)
        
        pomodoroVcObj?.isShowingPomodoroManually = false
        pomodoroVcObj?.isShowingMorningPomodoro = false
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    
    @objc func showMorningPomodoroModeView(){
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        if !SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Simple Mode is enabled:- return.")
            return;
        }
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "Focus mode completed view is visible:- return")
            return;
        }
        
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
            return
        }
        
        if isUserOnMeeting{
            addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
            return
        }
        
        if isShutOffTimeGoing(){
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                //                get  what day is today and comapre from pomodoro settings
                let cday = SettingsManagerObject.getDayOfWeek(fromDate: Date()) ?? SettingsManagerObject.kSunday
                
                if let arrDays = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays) as? [String]{
                    if arrDays.contains(cday){
                        pomodoroVcObj?.isShowingMorningHardcorePomodoro = true
                    }else{
                        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
                    }
                }else{
                    pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
                }
            }else{
                pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
            }
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        
        mainWindowControllerObj?.showWindow(self)
        leftMenuVcObj?.showPomodoro(pomodoroVcObj: pomodoroVcObj!.view)
        
        pomodoroVcObj?.isShowingPomodoroManually = false
        pomodoroVcObj?.isShowingMorningPomodoro = true
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    
    @objc func menuShowPomodoroModeView(){
        addLog(text: "Initiating Pomodoro Mode View.")
        isFocusBreakOn = false
        if !SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Simple Mode is enabled:- return.")
            return;
        }
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "Focus mode completed Window is visible:- close Window Forcefully")
            focusCompletedVcObj!.closeWindowForcefully()
        }
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused.")
            return
        }
        if self.timerPomodoroMode != nil{
            self.timerPomodoroMode?.invalidate()
            self.timerPomodoroMode = nil
        }
        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
        
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        
        mainWindowControllerObj?.showWindow(self)
        leftMenuVcObj?.showPomodoro(pomodoroVcObj: pomodoroVcObj!.view)
        
        
        pomodoroVcObj?.isShowingPomodoroManually = true
        pomodoroVcObj?.isShowingMorningPomodoro = false
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    @objc func menuShowSimplePomodoroModeView(){
        addLog(text: "Initiating Simple Pomodoro Mode View.")
        isFocusBreakOn = false
        if SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Geek Mode is enabled:- return.")
            return;
        }
        
        if isFocusCompletedViewVisibled(){
            addLog(text: "Focus mode completed Window is visible:- close Window Forcefully")
            focusCompletedVcObj!.closeWindowForcefully()
        }
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused.")
            return
        }
        
        if self.timerPomodoroMode != nil{
            self.timerPomodoroMode?.invalidate()
            self.timerPomodoroMode = nil
        }
        
        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
        
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        
        mainWindowControllerObj?.showWindow(self)
        leftMenuVcObj?.showPomodoro(pomodoroVcObj: getSimplePomodoroVcObj().view)
        
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func loadAllWindows(){
        
        if !getHabitsVcObject().isViewLoaded{
            getHabitsVcObject().loadView()
        }
        
        if !(mainViewControllerObj?.isViewLoaded ?? false){
            mainViewControllerObj?.loadView()
        }
        // Custom Routine is removed from the menu (it lives in the Day Plan's Custom Routines panel),
        // so keep it hidden regardless of whether the user has custom routines.
        leftMenuVcObj?.boxCustomRoutine.isHidden = true
        mainViewControllerObj?.expandLeftPanel()
        leftMenuVcObj?.enableAllItems()
        // show floating bar
        if let frame = appdelegate?.statusbutton?.window?.frame{
            let leading = frame.midX
            
            showFloatingTopBarWindow(windowTopMidPoint: (NSPoint(x: leading, y: frame.maxY - 24)))
        }else{
            if let screenFrame = NSScreen.main?.frame{
                showFloatingTopBarWindow(windowTopMidPoint: (NSPoint(x: screenFrame.width - 350, y: screenFrame.height - 34)))
            }
        }
        
        
        loadMenuWindow()
    }

    // #2142: guards the one-time brain-dump migration so overlapping checkWindowState calls don't each
    // fire an upsert — without an id the API creates a new note, so two racing calls would duplicate it.
    private var isBrainDumpMigrationInFlight = false

    /// #2142: one-time migration of the saved local brain dump into the backend (PUT /note upsert), run
    /// at startup from checkWindowState so the web Brain Dump loads the migrated note from the API when it
    /// opens. Guarded per-user by `kUserdefaultsBrainDumpSentToWebView`; an empty local brain dump is a
    /// no-op upsert-wise (don't clobber whatever the backend already has) but still marks migration done.
    /// The flag is set only on a 200, so a failed upsert (logged in AllApi via writeJsonInLog) retries.
    private func migrateBrainDumpToBackendIfNeeded() {
        guard UserDefaults.standard.value(forKey: kUserdefaultsBrainDumpSentToWebView) == nil,
              !isBrainDumpMigrationInFlight else { return }
        let notes = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        guard !notes.isEmpty else {
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrainDumpSentToWebView)
            return
        }
        isBrainDumpMigrationInFlight = true
        allApiObject.upsertBrainDumpNote(body: notes) { [weak self] _, statusCode in
            DispatchQueue.main.async {
                self?.isBrainDumpMigrationInFlight = false
                if statusCode == 200 {
                    UserDefaults.standard.set(true, forKey: kUserdefaultsBrainDumpSentToWebView)
                }
            }
        }
    }

    /// Re-pull the user's focus modes (block lists) from the server into arrFocusType. Mirrors the
    /// fetch/transform/store the startup path does, exposed so the blocking-schedule realtime sync can
    /// refresh block lists too: a schedule changed on another device may reference a focus mode this
    /// Mac hasn't fetched, and without it the schedule shows the wrong / "Update block list" name.
    func refreshFocusModesFromServer(completion: (() -> Void)? = nil) {
        allApiObject.getAllFocusModes(completionHandler: { dic in
            if let arrFocusModes = dic as? [[String:Any]]{
                var newArr = [[String:Any]]()
                for i in 0..<arrFocusModes.count{
                    var focusDic = arrFocusModes[i]
                    focusDic.removeValue(forKey: "created_at")
                    focusDic.removeValue(forKey: "updated_at")
                    focusDic.removeValue(forKey: "user_id")
                    focusDic.removeValue(forKey: "deleted_at")
                    focusDic.removeValue(forKey: "doNotSuggestAnyMore")
                    var newDic = [String:Any]()
                    for key in focusDic.keys{
                        if key == "metadata"{
                            if let metaDataDic = focusDic["metadata"] as? [String:Any]{
                                for key in metaDataDic.keys{
                                    newDic[key] = metaDataDic[key]
                                }
                            }
                        }else if key == "tags"{
                            if let arrTags = focusDic["tags"] as? [NSDictionary]{
                                var arrtags = [String]()
                                for tagInfo in arrTags{
                                    arrtags.append(tagInfo["text"] as? String ?? "")
                                }
                                newDic["tags"] = arrtags
                            }
                        }else{
                            newDic[key] = focusDic[key]
                        }
                    }
                    newDic.removeValue(forKey: "doNotSuggestAnyMore")
                    newArr.append(newDic)
                }
                UserDefaults.standard.set(plistSafeFocusModes(newArr), forKey: kUserdefaultsArrFocusTypes)
            }
            checkAllFocusModes()
            completion?()
        })
    }

    @objc func checkWindowState(){
        loadAllWindows()
        isCheckWindowStateDone = true
        isFirstRun = false

        // Cold Apple-event launch: the app is up but still in the background (never activated). Bring it to
        // the foreground now that it's ready, so it doesn't sit invisible/unresponsive until a Dock click.
        // Also force out the splash, whose showWindow (applicationWillFinishLaunching) renders late under a
        // background launch. Guarded by !isActive so a normal user launch that's already frontmost is left
        // alone. Retried over ~1.5s to catch the late splash render.
        // A script command that cold-launched us may have arrived before we finished loading — foreground now.
        fbActivateFromBackgroundLaunch()
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                statusItem.button?.window?.sharingType = .none
            }else{
                statusItem.button?.window?.sharingType = .readOnly
            }
        }
        
        getAllLongTermGoals()
        getTotalFocuedTime()
        migrateBrainDumpToBackendIfNeeded()
        if !lastOpenUrlString.isEmpty{
            filterUrl(url: lastOpenUrlString)
        }

        // Deferred deep link: a fresh install coming from the web AuDHD test carries
        // the retest code on the clipboard (the deep link is lost across the install),
        // so read it ONCE on the first launch and open the results — otherwise a new
        // downloader lands on the home screen and never sees their results. Gated on
        // a UserDefaults flag so a returning user's clipboard is never re-scanned.
        if !UserDefaults.standard.bool(forKey: AudhdResults.clipboardCheckedDefaultsKey) {
            UserDefaults.standard.set(true, forKey: AudhdResults.clipboardCheckedDefaultsKey)
            if let clip = NSPasteboard.general.string(forType: .string),
               let testCode = AudhdResults.testCode(fromClipboard: clip) {
                showAudhdResultsWindow(testCode: testCode)
            }
        }

        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
            checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
        }else{
            isHabitAlreadyShowed = false
        }
        if startTime != nil && shutOffTime != nil{
            
            if isShutOffTimeGoing() && shouldDoHabits(){
                if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                    if currentState != ._SHUTOFFMAC_{
                        // self.shutOffMac()
                    }
                }else{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                        mainWindowControllerObj?.loadWindow()
                        if Date().compare(date) == .orderedDescending {
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                        }
                    }
                }
            }else{
                if isHabitAlreadyShowed{
                    mainWindowControllerObj?.loadWindow()
                    getHabitsVcObject().setActivityTimer()
                }
            }
        }
        restorePostponeStateIfNeeded()
        setBackgroundThreadTimer()
        pusherEventsObject.startEventNotifications()
        teacherSessionManagerObject.adoptCurrentSessionOnLaunch()// live class session adoption:- joined resumes, invited shows the join prompt


        // Set up callbacks
        focusButtonServiceObject.onStateChanged = { state in
            print("Device state changed to: \(state.rawValue)")
        }

        focusButtonServiceObject.onRemainingTimeChanged = { seconds in
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            print("Time remaining: \(minutes):\(String(format: "%02d", remainingSeconds))")
        }


        // Persistent restore hook: when the button (re)connects, re-push the currently-running focus
        // session so it reappears on device. Uses a dedicated slot (not onDeviceConnected, which the
        // settings screen reassigns). Fixes: a session that started while the button was disconnected
        // left the device idle → "no focus session" and extend's SET|UPDATE no-op'd.
        focusButtonServiceObject.onDeviceConnectedRestore = { [weak self] in
            self?.reSyncFocusButtonOnConnect()
        }

        // Create the serial-port manager on the MAIN thread FIRST. ORSSerialPortManager registers its
        // USB connect/disconnect (IOKit hotplug) notifications on the run loop of the thread that first
        // creates the shared instance (CFRunLoopGetCurrent). start() below runs on a background/utility
        // queue whose run loop never runs — so if it created the manager first, those events would never
        // fire and `availablePorts` would be frozen at whatever was present at launch (the button is only
        // ever detected if plugged in before launch, and never removed once gone). Forcing creation here,
        // on the main run loop, makes `availablePorts` update live as the button is plugged/unplugged.
        _ = ORSSerialPortManager.shared()

        // Start the service off the main thread. The Focus Button is an optional USB
        // accessory and ORSSerialPort's open() can block in the kernel for a
        // misbehaving / unrelated serial device (e.g. a USB hub's modem interface).
        // Running it synchronously here froze the whole UI on the splash screen because
        // the connection-timeout guard is itself scheduled on the (now-blocked) main queue.
        DispatchQueue.global(qos: .utility).async {
            if focusButtonServiceObject.start() {
                addLog(text: "FocusButton: service started successfully")
            }
        }

    }

    /// Re-push the currently-running focus session to the Focus Button when it (re)connects, so a
    /// session that began while the button was offline reappears on device — and later SET|UPDATE
    /// extends land, since the firmware only updates a RUNNING/PAUSED session (an idle device
    /// ignores UPDATE). Invoked from the connect handshake once the device clock is set.
    func reSyncFocusButtonOnConnect() {
        guard isFocusModeRunning, let end = endFocusModeTime else { return }
        let remaining = Int(end.timeIntervalSinceNow)
        guard remaining > 0 else { return }
        addLog(text: "FocusButton: re-pushing running focus session on connect (\(remaining)s remaining)")
        focusButtonServiceObject.startFocusSession(seconds: remaining)
    }


    func checkLastHabitShowDate(lastHabitShowDate:Date){
        isHabitAlreadyShowed = isHabitAlreadyShown(lastShown: lastHabitShowDate, now: Date(), routineStart: startTime)
    }
    
    
    func setBackgroundThreadTimer(){
        addLog(text: "setBackgroundThreadTimer")
        DispatchQueue.global().sync {//async {
            self.timerBackgroundThread = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.backgroundThread), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerBackgroundThread!), forMode: RunLoop.Mode.common)
        }
    }
    
    var alertSuggestFocusMode:NSAlert?
    var isUserOnMeeting = false
    var meetingStartTime:Date?
    
    var isAutoMeetingsModeStarted = false
    var appUsedInAutoMeetingFocusMode = ""
    var isMicAlreadyOn = false
    var isCameraAlreadyOn = false
    var isPreventUserIdleDisplaySleepAlreadyOn = false
    
    func checkIsMeetingsGoingOn(){
        DispatchQueue.global(qos: .utility).async {
            self.checkMeetingsInternal()
        }
    }
    
    private func checkMeetingsInternal(){
        if !SettingsManagerObject.isMeetingDetectionEnabled{
            DispatchQueue.main.async {
                if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning {
                    self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateFocusText)
                }
            }
            return;
        }
        
        let isMicOn = avmonitor.isMicOn()
        let isACameraOn = avmonitor.isACameraOn()
        let isPreventUserIdleDisplaySleepOn = isPreventUserIdleDisplaySleepOn()
        
        if isMicOn || isACameraOn || isPreventUserIdleDisplaySleepOn{
            // Ignore detection while the user is recording,
            // since recording itself may activate the microphone.
            if recorder.isRecording{
                return;
            }
            logStateTransitions(mic: isMicOn, camera: isACameraOn, preventSleep: isPreventUserIdleDisplaySleepOn)
            
            if isUserOnMeeting{
                if isFocusModeOn(){
                    DispatchQueue.main.async {
                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText + " / " + buttonStatusStateFocusText)
                    }
                }else{
                    DispatchQueue.main.async {
                        self.setStatusBarButtonColorForFocusMode(color: NSColor.systemBlue, colorString: nil)
                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText)
                        self.statusbutton?.imagePosition = .imageLeft
                    }
                }
                return;
            }
            
            detectMeetingAppAndUpdateState(isPreventUserIdleDisplaySleepOn: isPreventUserIdleDisplaySleepOn)
            
        }else{
            isMicAlreadyOn = false
            isCameraAlreadyOn = false
            isPreventUserIdleDisplaySleepAlreadyOn = false
            
            if isAutoMeetingsModeStarted{//end meetings focus mode
                if isFocusModeOn(){
                    DispatchQueue.main.async {
                        self.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
                    }
                }
            }
            handleMeetingEnded()
            
            if isFocusModeOn() {
                DispatchQueue.main.async { [self] in
                    self.setStatusBarButtonColorForFocusMode(color: nil, colorString: currentRunningFocusType["color"] as? String ?? "")
                    setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    statusbutton?.imagePosition = .imageLeft
                }
            }else if isAnyAllowedFocusModeActivityRunning && (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_){
                DispatchQueue.main.async { [self] in
                    self.setStatusBarButtonColorForFocusMode(color: nil, colorString: currentRunningFocusType["color"] as? String ?? "")
                    setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    statusbutton?.imagePosition = .imageLeft
                }
            }else{
                DispatchQueue.main.async {
                    self.statusbutton?.title = ""
                    self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                }
            }
            
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil
        }
    }
    
    private func logStateTransitions(mic: Bool, camera: Bool, preventSleep: Bool) {
        if mic{
            if !isMicAlreadyOn{
                addLog(text: "func checkIsMeetingsGoingOn:- Mic is On")
                isMicAlreadyOn = true
            }
        }else{
            isMicAlreadyOn = false
        }
        if camera{
            if !isCameraAlreadyOn{
                addLog(text: "func checkIsMeetingsGoingOn:- Camera is On")
                isCameraAlreadyOn = true
            }
        }else{
            isCameraAlreadyOn = false
        }
        
        if preventSleep{
            if !isPreventUserIdleDisplaySleepAlreadyOn{
                addLog(text: "func checkIsMeetingsGoingOn:- PreventUserIdleDisplaySleep is On")
                isPreventUserIdleDisplaySleepAlreadyOn = true
            }
        }else{
            isPreventUserIdleDisplaySleepAlreadyOn = false
        }
    }
    
    private func fetchRunningAppNames(
        completion: @escaping (Set<String>) -> Void
    ) {
        DispatchQueue.main.async {
            let names = Set(
                NSWorkspace.shared.runningApplications.compactMap {
                    $0.bundleURL?
                        .deletingPathExtension()
                        .lastPathComponent
                        .lowercased()
                }
            )
            completion(names)
        }
    }
    
    func detectMeetingAppAndUpdateState(isPreventUserIdleDisplaySleepOn: Bool){
        // NSRunningApplication.bundleURL does a synchronous LaunchServices XPC lookup per running app;
        // reading it on the main thread across every running app blocked the UI for >2s (Sentry
        // AppHang: detectMeetingAppAndUpdateState). NSWorkspace.runningApplications is a thread-safe
        // snapshot, so read it off the main thread — in the same utility-queue block that does the matching.
        DispatchQueue.global(qos: .utility).async { [self] in
            let runningAppNames = Set(
                NSWorkspace.shared.runningApplications.compactMap {
                    $0.bundleURL?
                        .deletingPathExtension()
                        .lastPathComponent
                        .lowercased()
                }
            )

            var micStatus: MicStatus?
            if isMicAlreadyOn{
                let monitor = micMonitor()
                let status = monitor.microphoneStatus()
                // Per-app mic attribution (microphoneStatus) returns an EMPTY apps list on some Bluetooth
                // inputs (confirmed via the input-route logs below). An empty attribution must NOT suppress
                // the runningAppNames fallback: treat it as "unknown app" (micStatus = nil) so the fallback
                // matches a running meeting app by name — otherwise a Bluetooth-headset call goes
                // undetected even though the mic is on.
                micStatus = status.apps.isEmpty ? nil : status
                let micApps = status.apps.map { "\($0.appName)[\($0.bundleID)]" }.joined(separator: ", ")
                addLog(text: "func checkIsMeetingsGoingOn:- input=\(monitor.defaultInputDeviceInfo()) micApps(\(status.apps.count))=[\(micApps)]")
            }
            for i in 0..<arrFocusType.count{
                let focus = arrFocusType[i]
                if let state = focus["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        if let arr = focus["allowed_apps"] as? [String]{
                            for apppPath in arr{
                                
                                if let micStatus = micStatus{// mic process name added v 3.32.491
                                    for app in micStatus.apps{
                                        let nameLowercased = app.appName.lowercased()
                                        let url = URL(fileURLWithPath: apppPath)
                                        let appNameToCheck = url.deletingPathExtension().lastPathComponent.lowercased()
                                        // Match either way: an allowed app's PATH name and its running
                                        // DISPLAY name can differ and neither is always the longer one —
                                        // e.g. Zoom's app is "zoom.us.app" (→ "zoom.us") but its running
                                        // name is "Zoom" (→ "zoom"), so a one-directional contains missed
                                        // Zoom entirely (Bluetooth-headset call went undetected).
                                        if nameLowercased.contains(s: appNameToCheck) || appNameToCheck.contains(s: nameLowercased){
                                            
                                            if isUserOnMeeting{
                                                if isFocusModeOn(){
                                                    DispatchQueue.main.async {
                                                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText + " / " + buttonStatusStateFocusText)
                                                    }
                                                }else{
                                                    DispatchQueue.main.async {
                                                        self.setStatusBarButtonColorForFocusMode(color: NSColor.systemBlue, colorString: nil)
                                                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText)
                                                        self.statusbutton?.imagePosition = .imageLeft
                                                    }
                                                }
                                                return;
                                            }
                                            
                                            if let browser = getCurrentBrowserFrom(browserName: appNameToCheck){
                                                addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is a browser:- get current url")
                                                
                                                if !isBrowserMeetingAllowed(focus: focus, browser: browser){
                                                    continue;
                                                }
                                            }
                                            
                                            addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is \(nameLowercased)")
                                            
                                            appUsedInAutoMeetingFocusMode = url.lastPathComponent
                                            
                                            handleMeetingDetected()
                                            return;
                                        }
                                        
                                    }
                                }else{
                                    for nameLowercased in runningAppNames{
                                        let url = URL(fileURLWithPath: apppPath)
                                        let appNameToCheck = url.deletingPathExtension().lastPathComponent.lowercased()
                                        // Bidirectional (see the micStatus branch above): "zoom.us" vs a
                                        // running "zoom" must still match.
                                        if appNameToCheck == nameLowercased
                                            || appNameToCheck.contains(s: nameLowercased)
                                            || nameLowercased.contains(s: appNameToCheck){
                                            
                                            if isUserOnMeeting{
                                                if isFocusModeOn(){
                                                    DispatchQueue.main.async {
                                                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText + " / " + buttonStatusStateFocusText)
                                                    }
                                                }else{
                                                    DispatchQueue.main.async {
                                                        self.setStatusBarButtonColorForFocusMode(color: NSColor.systemBlue, colorString: nil)
                                                        self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText)
                                                        self.statusbutton?.imagePosition = .imageLeft
                                                    }
                                                }
                                                return;
                                            }
                                            
                                            if nameLowercased == "microsoft teams" || nameLowercased == "microsoft teams classic" || nameLowercased == "zoom.us"{
                                                if !isPreventUserIdleDisplaySleepOn{
                                                    continue;
                                                }
                                            }
                                            
                                            
                                            if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                                                addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is a browser:- get current url")
                                                
                                                if !isBrowserMeetingAllowed(focus: focus, browser: browser){
                                                    continue;
                                                }
                                            }
                                            
                                            addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is \(nameLowercased)")
                                            
                                            appUsedInAutoMeetingFocusMode = url.lastPathComponent
                                            
                                            handleMeetingDetected()
                                            return;
                                        }
                                        
                                    }
                                }
                            }
                        }
                        // No known meeting *app* matched. Fall back to detecting a browser-based call by
                        // its live meeting URL (e.g. Google Meet), independent of allowed_apps membership
                        // and of per-app mic attribution (which misses browser calls on some Bluetooth
                        // inputs — see the instrumentation above). Only reached with mic/camera/keep-awake
                        // already on, so an idle open tab alone won't trip it.
                        if detectBrowserMeeting(focus: focus, runningAppNames: runningAppNames){
                            return;
                        }
                        addLog(text: "func checkIsMeetingsGoingOn:- no meeting app or browser-meeting matched (mic=\(isMicAlreadyOn) cam=\(isCameraAlreadyOn))")
                        handleMeetingEnded()
                        break;
                    }
                }
            }


        }

    }

    /// Fallback browser-meeting detection. The `allowed_apps` scan only matches a browser when the
    /// Meetings focus type lists that browser AND the mic is attributed to it — the latter fails for
    /// browser calls on some Bluetooth inputs (`microphoneStatus` returns no apps), so a Google Meet
    /// call slips through with mic/camera live but nothing matched. Check any running, recognised
    /// browser for a live meeting URL (`meet.google.com/<room>`, or the focus's `allowed_urls`) and
    /// treat that as the meeting. Returns true if one was found + handled. Runs on the detection
    /// background queue; reads browser tabs via the AppHang-safe `fetchBrowserAllTabUrlsInBackground`.
    private func detectBrowserMeeting(focus: [String: Any], runningAppNames: Set<String>) -> Bool {
        for name in runningAppNames {
            guard let browser = getCurrentBrowserFrom(browserName: name) else { continue }
            if isBrowserMeetingAllowed(focus: focus, browser: browser){
                addLog(text: "func checkIsMeetingsGoingOn:- browser meeting detected in \(name)")
                appUsedInAutoMeetingFocusMode = name
                handleMeetingDetected()
                return true
            }
        }
        return false
    }
    
    /// Grace timer that auto-ends an LNM meeting focus session shortly after the user leaves the meeting.
    /// Delayed so a breakout-room switch (which momentarily looks like leaving) doesn't end it prematurely.
    // A cancellable main-queue work item (NOT a Timer): handleMeetingEnded runs on the background
    // meeting-detection thread, where Timer.scheduledTimer lands on a non-spinning run loop and never fires.
    private var meetingSessionAutoEndWorkItem: DispatchWorkItem?
    private let meetingSessionAutoEndGraceSeconds: TimeInterval = 15

    private func handleMeetingEnded(){
        if isUserOnMeeting{
            isUserOnMeeting = false
            writeSettingForScreeenTime(habitInfo: "")
            // A meeting focus session (started by LNM when the meeting began) should end when the meeting
            // ends — but only after a grace period, since switching into a breakout room briefly reads as
            // "left the meeting". handleMeetingDetected cancels this if a meeting resumes within the window.
            startMeetingSessionAutoEndGraceIfNeeded()

            // A break/habit activity video paused when the meeting started (see
            // `suspendActivityVideoForMeeting`) must be resumed, otherwise a meeting detected mid-break
            // leaves it paused for the rest of the break (#1878 regression).
            DispatchQueue.main.async {
                timerViewcontrollerObj?.resumeActivityVideoAfterMeeting()
            }
            DispatchQueue.main.async { [self] in
                if alertSuggestFocusMode != nil{
                    if alertSuggestFocusMode!.window.isVisible{
                        if let sheet = alertSuggestFocusMode?.window,
                           let parentWindow = sheet.sheetParent {
                            parentWindow.endSheet(sheet)
                        }else{
                            NSApp.abortModal()
                        }
                        addLog(text: "close Meeting suggestion Alert")
                    }
                }
            }
        }
    }
    
    /// Browser live-meeting URL rules: (host suffix, path fragments that mark an ACTIVE meeting). An empty
    /// fragment list ⇒ ANY non-root path on that host is a meeting room (e.g. `whereby.com/my-room`). Host
    /// is matched by SUFFIX so per-org subdomains (`acme.zoom.us`, `company.webex.com`) count. One registry
    /// so meeting-URL knowledge isn't scattered — a bare home page under the same domain does NOT count.
    private static let browserMeetingUrlRules: [(hostSuffix: String, meetingPathFragments: [String])] = [
        ("teams.microsoft.com", ["meetup-join", "light-meetings", "/l/meeting"]),
        ("teams.live.com",      ["meetup-join", "light-meetings", "/l/meeting"]),
        ("zoom.us",             ["/j/", "/wc/", "/s/", "/my/"]),
        ("meet.google.com",     []),
        ("meet.jit.si",         []),
        ("whereby.com",         []),
        // Zoho Meeting rooms live on meeting.zoho.<region> — never meet.zoho.com (#2388).
        ("meeting.zoho.com",    []),
        ("meeting.zoho.eu",     []),
        ("meeting.zoho.in",     []),
        ("meeting.zoho.com.au", []),
        ("webex.com",           ["/meet/", "/join/", "/wbxmjs/", "/j.php"]),
    ]

    /// True when `url` is a live browser meeting (an actual room/join link), not the platform's home page.
    private func urlLooksLikeLiveMeeting(_ url: String) -> Bool {
        let host = getDomainFromUrl(url: url).lowercased()
        guard !host.isEmpty else { return false }
        let loweredUrl = url.lowercased()
        for rule in Self.browserMeetingUrlRules where host == rule.hostSuffix || host.hasSuffix("." + rule.hostSuffix) {
            if rule.meetingPathFragments.isEmpty {
                // No fragment gate for this host: any path segment beyond "/" is a room.
                let path = NSURL(string: url)?.path ?? ""
                return path.count > 1
            }
            if rule.meetingPathFragments.contains(where: { loweredUrl.contains($0) }) { return true }
        }
        return false
    }

    private func isBrowserMeetingAllowed(focus: [String: Any], browser:BROWSER) -> Bool {
        
        if let allTabUrls = fetchBrowserAllTabUrlsInBackground(browser: browser){
            for  activeTabUrl in allTabUrls{
                
                // Recognise live browser meetings across platforms (Meet, Teams, Zoom, Jitsi, Whereby,
                // Zoho, Webex) from the URL itself — a room/join link, not the platform home page.
                if urlLooksLikeLiveMeeting(activeTabUrl) {
                    return true
                }
                let arrAllowedUrlsMeetingsFocus = focus["allowed_urls"] as? [String] ?? []
                for turl in arrAllowedUrlsMeetingsFocus{
                    if validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl){
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func fetchBrowserAllTabUrlsInBackground(browser: BROWSER) -> [String]? {
        // Call directly on the (background) meeting-detection thread. `getBrowserAllTabUrl`
        // routes through `runAppleScriptSafely`, which already serialises the AppleScript onto
        // `appleScriptSerialQueue` and applies a bounded timeout — a background caller gets the
        // full, generous wait, the main thread is never touched. The previous
        // `DispatchQueue.main.async { … }; semaphore.wait()` bounce was the PR #2009 anti-pattern:
        // it forced browser "get every tab" AppleScript onto the main thread (freezing the UI while
        // a busy browser answered) and blocked this worker on an *un-timed* semaphore, so a stalled
        // main run loop hung the worker forever and starved the global thread pool → full beachball.
        return getBrowserAllTabUrl(browser: browser)
    }
    
    /// Schedule the meeting focus session to auto-end after the grace window, unless a meeting resumes in
    /// the meantime (handleMeetingDetected cancels the timer). No-op unless an LNM meeting session is live.
    private func startMeetingSessionAutoEndGraceIfNeeded() {
        guard currentAccountabilityBuddySession?.isMeeting == true else { return }
        addLog(text: "meeting ended: auto-ending meeting focus session in \(Int(meetingSessionAutoEndGraceSeconds))s unless a meeting resumes (breakout-room grace)")
        // Schedule on the MAIN queue (this can be called from the background detection thread) so it fires
        // reliably; a DispatchWorkItem lets handleMeetingDetected cancel it if a meeting resumes.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.meetingSessionAutoEndWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in self?.autoEndMeetingFocusSessionIfMeetingOver() }
            self.meetingSessionAutoEndWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + self.meetingSessionAutoEndGraceSeconds, execute: work)
        }
    }

    /// Re-check after another grace window, without the "meeting ended" log line — the meeting has not
    /// ended, we simply cannot see it right now.
    private func rearmMeetingSessionAutoEndGrace() {
        let work = DispatchWorkItem { [weak self] in self?.autoEndMeetingFocusSessionIfMeetingOver() }
        meetingSessionAutoEndWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + meetingSessionAutoEndGraceSeconds, execute: work)
    }

    /// Fired after the grace window: end the meeting focus session iff the meeting is still over and the
    /// live session is still the meeting one (a new session, or a re-detected meeting, cancels this).
    private func autoEndMeetingFocusSessionIfMeetingOver() {
        meetingSessionAutoEndWorkItem = nil
        guard currentAccountabilityBuddySession?.isMeeting == true else {
            addLog(text: "meeting focus session auto-end skipped: isMeetingSession=false")
            return
        }
        let calendarSaysLive = MeetingCoverage.hasLiveOrImminentMeeting(
            now: Date(), meetings: AnnouncedMeetingRegister.shared.activeMeetings())
        guard MeetingCoverage.shouldAutoEndMeetingSession(isUserOnMeeting: isUserOnMeeting,
                                                         hasLiveAnnouncedMeeting: calendarSaysLive) else {
            addLog(text: "meeting focus session auto-end skipped: onMeeting=\(isUserOnMeeting) calendarSaysLive=\(calendarSaysLive)")
            // Re-arm rather than give up: detection may stay quiet for the whole call (a browser tab
            // the mic check can't see), and the session must still end once the meeting really is over.
            rearmMeetingSessionAutoEndGrace()
            return
        }
        addLog(text: "meeting ended >\(Int(meetingSessionAutoEndGraceSeconds))s ago: auto-ending meeting focus session")
        // If the meeting had postponed an INCOMPLETE morning/evening routine, hand the user back to it (same
        // as stopping the session manually) rather than just ending — otherwise the routine is silently
        // abandoned after the meeting. Otherwise finish silently.
        if routinePostponeStateToReCoverOnExtend() != nil {
            addLog(text: "meeting auto-end: incomplete routine to recover → resuming routine")
            menuViewControllerObj?.stopFocusModeAndResumeRoutine()
        } else {
            tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend: false, isCustomRoutineTime: false, shouldUpdateFocusButton: true)
        }
    }

    func handleMeetingDetected(){
        isUserOnMeeting = true
        meetingStartTime = Date()
        writeSettingForScreeenTime(habitInfo: "")
        // A meeting is (still) on — cancel any pending auto-end of the meeting focus session. Covers the
        // breakout-room case where the meeting briefly looked ended and re-appeared within the grace window.
        DispatchQueue.main.async { [weak self] in
            self?.meetingSessionAutoEndWorkItem?.cancel()
            self?.meetingSessionAutoEndWorkItem = nil
        }

        // A break/habit activity video already playing when the meeting starts must be paused so it
        // doesn't blast audio/video into the call (#1878).
        DispatchQueue.main.async {
            timerViewcontrollerObj?.suspendActivityVideoForMeeting()
        }
        
        if isFocusModeOn(){
            DispatchQueue.main.async {
                self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText + " / " + buttonStatusStateFocusText)
            }
        }else{
            DispatchQueue.main.async {
                self.setStatusBarButtonColorForFocusMode(color: NSColor.systemBlue, colorString: nil)
                self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText)
                self.statusbutton?.imagePosition = .imageLeft
            }
        }
        if  SettingsManagerObject.showMeetingDetectionAlert && !FeatureSnooze.isSnoozed(.meetingDetection){
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil
            DispatchQueue.main.async { [self] in
                timerMeetingStartAlert = Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(self.showMeetingSuggestionAlert), userInfo: nil, repeats: false)
            }
        }else{
            addLog(text: "func checkIsMeetingsGoingOn:- showMeetingDetectionAlert setting is false:- return")
        }
    }
    
    func setStatusBarButtonColorForFocusMode(color:NSColor?, colorString:String?){
        if SettingsManagerObject.isOfficeModeEnabled{
            statusbutton?.backgroundcolor = NSColor.clear
            return;
        }
        
        if color != nil{
            statusbutton?.backgroundcolor = color
        }else if colorString != nil{
            statusbutton?.backgroundcolor = HexToColor(hexString: colorString!)
        }else{
            statusbutton?.backgroundcolor = NSColor.clear
        }
    }
    
    func setStatusBarButtonTitleForFocusMode(title:String){
        var finalTitle = ""
        if title.isEmpty{
            finalTitle = buttonStatusStateFocusText
        }else{
            let btnTitle = title.components(separatedBy: .newlines).joined()
            if btnTitle.count > 40 {
                finalTitle = String(btnTitle.prefix(40)) + "..."
            }else{
                finalTitle = btnTitle
            }
            
        }
        
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning) && !isUserOnMeeting{
            if let date = endFocusModeTime{
                let secondsBetween = date.timeIntervalSince(Date())
                
                var (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
                if s > 0{ //I did it this way because if 5.16 minutes are remaining, the user was only seeing 5, but now it will be 6 and  will also match the visible time with the "focus end warning."
                    m += 1
                }
                var hour = "\(h)"
                var minute = "\(m)"
                var second = "\(s)"
                
                if hour.count == 1 {
                    hour = "0\(h)"
                }
                if minute.count == 1 {
                    minute = "0\(m)"
                }
                if second.count == 1 {
                    second = "0\(s)"
                }
                
                
                finalTitle = "\(hour):\(minute)" + " - " + finalTitle//count down in minutes not in seconds
                
            }
        }
        
        if SettingsManagerObject.isOfficeModeEnabled{
            statusbutton?.title = finalTitle
            return;
        }
        
        
        let bgColor = statusbutton?.backgroundcolor ?? NSColor.black
        let rgbColor = bgColor.usingColorSpace(.deviceRGB) ?? NSColor.black
        
        let r = (rgbColor.redComponent) * 255
        let g = (rgbColor.greenComponent) * 255
        let b = (rgbColor.blueComponent) * 255
        
        let threshold:CGFloat = 105;
        let bgDelta = ((r * 0.299) + (g * 0.587) + (b * 0.114));
        var finalRgb = NSColor.black
        
        if (255 - bgDelta < threshold){
            finalRgb = NSColor.black
        }else{
            finalRgb = NSColor.white
        }
        
        let myString = finalTitle
        let myAttribute = [ NSAttributedString.Key.foregroundColor: finalRgb ]
        let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
        statusbutton?.attributedTitle = myAttrString
        return;
        
    }
    var timerMeetingStartAlert:Timer?
    @objc func showMeetingSuggestionAlert(){
        timerMeetingStartAlert?.invalidate()
        timerMeetingStartAlert = nil
        addLog(text: "showMeetingSuggestionAlert")
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SHUTOFFMAC_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
            addLog(text: "Meeting suggestion aborted due to activity.")
            return
        }
        

        
        alertSuggestFocusMode = NSAlert()
        alertSuggestFocusMode!.setSharingType()
        var notificationVideoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            notificationVideoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? notificationVideoCallText
        }
        
        var title = "It looks like you're in a meeting. Will you need to use other apps during the meeting? If not, I can block everything else to help you concentrate."
        var subTitle = "On selecting \"Block everything else\" the app will start \"Meetings\" focus mode."
        var buttonBlockText = "Block everything else"
        var buttonCancelText = "It's ok for me to use other apps during this meeting"
        var buttonFalseDetectionText = "False positive: I'm not in a meeting"
        var buttonGotItText = "Got it"
        var buttonCheckBoxText = "Don't show this again when I join meetings"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let suggestFocusInfo = focusInfo.value(forKey: "suggestFocusInfo") as? NSDictionary{
                if let val = suggestFocusInfo.value(forKey: "title") as? String{
                    title = val
                }
                if let val = suggestFocusInfo.value(forKey: "subTitle") as? String{
                    subTitle = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonBlockText") as? String{
                    buttonBlockText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonCancelText") as? String{
                    buttonCancelText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonFalseDetectionText") as? String{
                    buttonFalseDetectionText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonGotItText") as? String{
                    buttonGotItText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonCheckBoxText") as? String{
                    buttonCheckBoxText = val
                }
            }
        }
        let isFocusModeOn = isFocusModeOnOrPaused()
        alertSuggestFocusMode?.messageText = notificationVideoCallText
        
        if isFocusModeOn{
            alertSuggestFocusMode?.addButton(withTitle: buttonGotItText)
        }else{
            alertSuggestFocusMode?.informativeText = title + "\n\n" + subTitle
            alertSuggestFocusMode?.addButton(withTitle: buttonBlockText)
            alertSuggestFocusMode?.addButton(withTitle: buttonCancelText)
        }
        
        
        alertSuggestFocusMode?.addButton(withTitle: buttonFalseDetectionText)
        alertSuggestFocusMode?.showsSuppressionButton = true
        alertSuggestFocusMode?.suppressionButton?.title = buttonCheckBoxText
        alertSuggestFocusMode?.suppressionButton?.state = .off
        
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let window = NSApp.keyWindow{
            alertSuggestFocusMode?.beginSheetModal(for: window, completionHandler: { (result) in
                
                if self.alertSuggestFocusMode?.suppressionButton?.state == .on{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showMeetingDetectionAlert = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                
                if isFocusModeOn{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Start Focus clicked")
                        self.meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Cancel clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        //                print("third")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }
                
            })
            
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let result = alertSuggestFocusMode?.runModal(){
                
                if alertSuggestFocusMode?.suppressionButton?.state == .on{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showMeetingDetectionAlert = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                
                if isFocusModeOn{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Start Focus clicked")
                        meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Cancel clicked")
                        alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        alertSuggestFocusMode = nil
                        self.perform(#selector(showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }
            }
        }
        
    }
    
    @objc func showAlertFalseMicDetection(){
        addLog(text: "func showAlertFalseMicDetection")
        alertSuggestFocusMode = NSAlert()
        alertSuggestFocusMode!.messageText = "Sorry about that. Are you sure you're not using an app that is using your microphone? If we keep getting it wrong, click button below to disable meeting detection."
        var buttonDisableText = "Disable meeting detection"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let suggestFocusInfo = focusInfo.value(forKey: "suggestFocusInfo") as? NSDictionary{
                alertSuggestFocusMode!.messageText = suggestFocusInfo.value(forKey: "titleFalseDetection") as? String ?? alertSuggestFocusMode!.messageText
                buttonDisableText = suggestFocusInfo.value(forKey: "buttonDisableText") as? String ?? buttonDisableText
            }
        }
        
        alertSuggestFocusMode!.addButton(withTitle: buttonDisableText)
        alertSuggestFocusMode!.addButton(withTitle: buttonCancelText)
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let window = NSApp.keyWindow{
            alertSuggestFocusMode?.beginSheetModal(for: window, completionHandler: { (result) in
                if result == .alertFirstButtonReturn{
                    //                print("first")
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    self.alertSuggestFocusMode = nil
                    
                    if self.isUserOnMeeting{
                        self.isUserOnMeeting = false
                        writeSettingForScreeenTime(habitInfo: "")
                    }
                    if isFocusModeOn(){
                        self.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    }else{
                        self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                        self.statusbutton?.title = ""
                    }
                }else{
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Cancel clicked")
                    self.alertSuggestFocusMode = nil
                }
            })
            
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let result = alertSuggestFocusMode?.runModal(){
                if result == .alertFirstButtonReturn{
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    alertSuggestFocusMode = nil
                    
                    if isUserOnMeeting{
                        isUserOnMeeting = false
                        writeSettingForScreeenTime(habitInfo: "")
                    }
                    
                    
                    if isFocusModeOn(){
                        setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    }else{
                        self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                        self.statusbutton?.title = ""
                    }
                    
                }else{
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Cancel clicked")
                    alertSuggestFocusMode = nil
                }
            }
        }
    }
    
    func meetingAlertStartFocusClicked(){
        addLog(text: "meeting Alert Start Focus Clicked")
        for i in 0..<arrFocusType.count{
            let focus = arrFocusType[i]
            if let state = focus["isMeetings"] as? Bool{
                if  state{
                    let calendar = Calendar.current
                    endFocusModeTime = calendar.date(byAdding: .minute, value: 5, to: Date())
                    startFocusModeTime = Date()
                    currentFocusModeStrictness = ._NORMAL_
                    addLog(text: "focus mode is normal mode")
                    arrFocusType[i]["isOn"] = true
                    shouldReloadTaskPlayer = true
                    if let isAutoDoNotDisturbEnabled = arrFocusType[i]["isAutoDoNotDisturbEnabled"] as? Bool{
                        if isAutoDoNotDisturbEnabled{
                            if isAccessibilityEnabled(isPrompt: true){
                                DNDManager.shared.setDND(true)
                            }
                        }
                    }
                    workBeforeFocusBegin(index: i)
                    focusModeMinutesToPerform = 0
                    
                    self.setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[i]["color"] as? String ?? "")
                    statusbutton?.title = buttonStatusStateFocusText
                    statusbutton?.imagePosition = .imageLeft
                    setAppIconForFocusModeScore(probability: nil)
                    // Arm the focus timers the same way every other focus start does. setFocusModeTimer
                    // sets up BOTH the session-end timer (timerForFocusMode → focusModeTimerFinished, which
                    // already handles the meetings case) AND the end-of-session warning
                    // (timerForFocusModeEndNotification → showFocusModeFinishNotification → the extend/end
                    // window). This meeting path previously armed NEITHER, so a Meetings focus mode started
                    // from "Block everything else" never showed the normal end-warning (#2207 Scenario 5).
                    // 5 = the meeting focus duration (matches endFocusModeTime above); it also sets
                    // focusModeSecondsToPerform / startFocusModeTimeForPauseAndResume.
                    setFocusModeTimer(hour: nil, minute: 5)
                    isFocusModeStartedFromPomodoroMode = false
                    whatToAchieveInFocusBlock = ""
                    let time = focusModeSecondsToPerform*60
                    focusButtonServiceObject.startFocusSession(seconds: time)
                    focusModeStartted(isStartedByPusher: false)
                    allApiObject.capturePosthog(event: "start-meetings-focus-mode", metadata: [:])
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    isMeetingsFocusStartedAutomatically = true
                    isFocusModeStartedAutomatically = false

                    alertSuggestFocusMode = nil
                    isAutoMeetingsModeStarted = true
                }
            }
        }
    }
    
    
    
    func returnFromSystemSleepCheckAppStateAgain(){
        addLog(text: "func:- returnFromSystemSleepCheckAppStateAgain")
        
        if pomodoroVcObj?.timer != nil {
            if pomodoroVcObj?.isViewVisible ?? false{
                if pomodoroVcObj!.timer!.isValid{
                    pomodoroVcObj?.currentTimer = unfocusedTime
                }
            }
        }
        
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                if macGoesInSleepTime != nil{// it means popup comes after mac goes to sleep
                    popupAppointmentTimeWcObj?.window?.close()// // added on 2/9/25 on version 2.27.409 . before today it was returning from here
                }else if isShutOffTimeGoing() || isCutOffTimeGoing(){
                    // SECURITY: a Late No More appointment popup must NOT suppress shut-off / cut-off
                    // enforcement — otherwise unlocking past cut-off lets the user straight in without
                    // the required password. Close the popup and fall through to the enforcement below.
                    addLog(text: "Appointment popup visible but past shut-off/cut-off — enforcing password instead of returning.")
                    popupAppointmentTimeWcObj?.window?.close()
                }else{
                    return;
                }
            }
        }
        
        if currentState == ._MICRO_BREAK_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_ || currentState == ._POSTPONE_MORNING_HABIT_ || !isAppEnable || currentState == ._ABORT_ || currentState == ._SPECIAL_ACTIVITY_{
            addLog(text: "func:- returnFromSystemSleepCheckAppStateAgain   return:- currentState is activity/postpone/abort/specialActivity")
            
            
            if currentState == ._MICRO_BREAK_{// if user was doing break before system sleep and after sysytem wakes up if idle time is more then 5 minutes then stop activity and set timer again
                if macGoesInSleepTime != nil{
                    let passedSeconds = Calendar.current.dateComponents([.second], from: macGoesInSleepTime!, to: Date()).second ?? 0
                    if passedSeconds > 300{
                        currentState = ._NOTHING_
                        leftMenuVcObj?.microBreaksOver()
                        if breakWarningWcObj != nil{
                            if breakWarningWcObj?.window?.isVisible ?? false{
                                breakWarningWcObj?.window?.close()
                            }
                        }
                        getHabitsVcObject().stopActivityCountDownTimer()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        addLog(text: "Current State s activity: stop Break Activity Done")
                        getHabitsVcObject().setActivityTimer(forceReset: true)
                    }
                }
            }
            return
        }
        macGoesInSleepTime = nil
        if isShutOffTimeGoing(){
            if arrFilteredEveningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrFilteredEveningHabits count is 0")
                return;
            }
        }else{
            if arrFilteredMorningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrFilteredMorningHabits count is 0")
                return;
            }else if isHabitAlreadyShowed{
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- habit showed already")
                return;
            }
        }
        
        
        
        if popUpOfflineWcObj != nil{
            if popUpOfflineWcObj?.window?.isVisible ?? false{
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- popUpOffline window visible")
                return;
            }
        }
        if mainViewControllerObj != nil{//Log quantity box, Notes box, Focus mode end box will hold the activity screen there 26/6/23
            if !mainViewControllerObj!.checkIsAnyUserInputSubViewAdded(){
                
                
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                    self.abortAllProcess()
                    currentState = ._NOTHING_
                    routineTornDownForWakeAt = Date()
                    leftMenuVcObj?.habitOver()
                    backgroundThread()
                    if self.isUserOnMeeting && currentState == ._NOTHING_{
                        addLog(text: "isUserOnMeeting True and currentState is None: Hide Main Window.")
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            closeNaturalBreakDetectionWindowIfVisible()// added on 9/9/25 in 2.27.413
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                        }
                    }
                }else{
                    self.abortAllProcess()
                    if currentState == ._MICRO_BREAK_{
                        leftMenuVcObj?.microBreaksOver()
                    }
                    currentState = ._NOTHING_
                    routineTornDownForWakeAt = Date()
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    backgroundThread()
                }
            }
        }
    }
    
    
    
    var isProcessingHabitRoutine = false {
        didSet {
            // When a routine refetch finishes, the filtered habit arrays are now finalized
            // (completed habits filtered out) — refresh the Schedule tab so it picks up the
            // same source the habit list does, instead of waiting for its next timer tick.
            if oldValue && !isProcessingHabitRoutine {
                DispatchQueue.main.async {
                    if pendingReturnToSchedule {
                        pendingReturnToSchedule = false
                        firstViewControllerObj?.selectScheduleTab()
                        routinePostponedInfoVcObj?.selectScheduleTab()
                    }
                    firstViewControllerObj?.refreshScheduleIfVisible()
                    routinePostponedInfoVcObj?.refreshScheduleIfVisible()
                }
            }
        }
    }
    var isProcesssingOfflineData = false
    
    func processOfflineData(){// move it in routine data
        if !self.isProcesssingOfflineData{
            DispatchQueue.global().async {
                if Reachability.isConnectedToNetwork() == true{
                    self.isProcesssingOfflineData = true
                    var arr = readDataFromCSV(url: offlineActivitiesCsvURL!)
                    if arr.last?.count == 1{
                        arr.removeLast()
                    }
                    if arr.count > 1{
                        addLog(text: "Retrived data from offlineActivities csv")
                        var arrDic = [[String : Any]]()
                        let headers  = arr.first!
                        arr.removeFirst()
                        let newArr = arr
                        var maxCount = 50
                        var isLastLoop = false
                        if newArr.count > maxCount{
                            //let firstBatch = newArr
                            
                        }else{
                            maxCount = newArr.count
                            isLastLoop = true
                            
                        }
                        
                        for j in 0..<maxCount{
                            let subarray = newArr[j]
                            if subarray.count != headers.count{// column numbers are fixed so verifying content while reading
                                
                            }else{
                                var dic = [String:Any]()
                                for i in 0..<subarray.count{
                                    
                                    dic[headers[i]] = subarray[i]
                                }
                                dic["duration_logged"] = Int(dic["duration_logged"] as? String ?? "") ?? 0
                                
                                let quantity_logged_string = dic["quantity_logged"] as? String ?? ""
                                if quantity_logged_string.isEmpty{
                                    dic.removeValue(forKey: "quantity_logged")
                                }else{
                                    dic["quantity_logged"] = Double(quantity_logged_string) ?? 0
                                }
                                if dic["start_time"] as? String == ""{
                                    continue;
                                }
                                if j == newArr.count - 1{
                                    if isLastLoop{
                                        if let val = dic["skipped_did_not_complete"] as? String{
                                            let activity_sequence_id = dic["activity_sequence_id"] as? String ?? ""
                                            let start_time_String = dic["start_time"] as? String ?? ""
                                            let note_logged = dic["note_logged"] as? String ?? ""
                                            let morningStartDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                            let start_time = getDateFromStringInUtc(date: start_time_String, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") ?? Date()
                                            if start_time.compare(morningStartDate) == .orderedDescending{
                                                var choice_id:String?
                                                if let id = dic["choice_id"] as? String{
                                                    if !id.isEmpty{
                                                        choice_id = id
                                                    }
                                                }
                                                
                                                var quantity_logged:Double?
                                                
                                                if let val = dic["quantity_logged"] as? Double{
                                                    quantity_logged = val
                                                }
                                                
                                                
                                                let duration_logged = dic["duration_logged"] as? Int ?? 0
                                                let activity_id = dic["activity_id"] as? String ?? ""
                                                
                                                
                                                if val == "true"{
                                                    allApiObject.activitySkippedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, completionHandler: {dic in
                                                        
                                                    })
                                                }else{
                                                    var is_skipped = false
                                                    if let skipped_did_complete = dic["skipped_did_complete"] as? String{
                                                        if skipped_did_complete == "true"{
                                                            is_skipped = true
                                                        }
                                                    }
                                                    
                                                    
                                                    allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, is_skipped: is_skipped, notes: note_logged, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                                                        
                                                        DispatchQueue.main.async {
                                                            
                                                        }
                                                        print(dic)
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                var metadataDic = [String : Any]()
                                if let val = dic["skipped_did_not_complete"] as? String{
                                    dic.removeValue(forKey: "skipped_did_not_complete")
                                    var skipped_did_not_complete = false
                                    if val == "true"{
                                        skipped_did_not_complete = true
                                    }else{
                                        skipped_did_not_complete = false
                                    }
                                    metadataDic["skipped_did_not_complete"] = skipped_did_not_complete
                                }
                                
                                if let val = dic["skipped_did_complete"] as? String{
                                    dic.removeValue(forKey: "skipped_did_complete")
                                    var skipped_did_complete = false
                                    if val == "true"{
                                        skipped_did_complete = true
                                    }else{
                                        skipped_did_complete = false
                                    }
                                    metadataDic["skipped_did_complete"] = skipped_did_complete
                                }
                                
                                dic["metadata"] = metadataDic
                                arrDic.append(dic)
                            }
                        }
                        
                        if arrDic.count == 0{
                            addLog(text: "sync data from csv is 0:- return")
                            self.isProcesssingOfflineData = false
                            removeEntryInActivitiesCsv(count: maxCount)
                            return;
                        }else{
                            addLog(text: "sync data from csv is \(arrDic.count)")
                        }
                        
                        allApiObject.syncOfflineDataApi(offineData: arrDic, completionHandler: { json in
                            if json != nil{
                                self.nRetry = 0
                                removeEntryInActivitiesCsv(count: maxCount)
                            }else{
                                let nBaseDelayMs = 10000
                                let nDelayMs = calculateBackoffWithJitter(baseDelayMs: nBaseDelayMs, retry: self.nRetry)
                                let secondsToSleep = UInt32(nDelayMs) / 1000
                                sleep(secondsToSleep)
                                self.nRetry += 1
                            }
                            self.isProcesssingOfflineData = false
                        }
                        )
                        
                    }else{
                        self.isProcesssingOfflineData = false
                    }
                }
            }
            
        }
    }
    var nRetry = 0
    
    func filterUrl(url:String){
        addLog(text: "func:- filterUrl \(url)")

        // Growth/unlock flow: open the gated "advanced AuDHD results" webview.
        // Handled ABOVE the app-enabled / subscription guards below, so it works even
        // when the app isn't enabled or the subscription has expired. See online-tests#57.
        let decoded = url.removingPercentEncoding ?? url
        if decoded.hasPrefix(AudhdResults.deepLinkPrefix) {
            if let testCode = AudhdResults.testCode(fromDeepLink: decoded), !testCode.isEmpty {
                addLog(text: "func:- filterUrl- opening AuDHD results webview")
                showAudhdResultsWindow(testCode: testCode)
            } else {
                addLog(text: "func:- filterUrl- view-audhd-results missing \(AudhdResults.testCodeParamKey)")
            }
            return
        }

        if !isAppEnable{
            addLog(text: "func:- filterUrl- app is not enabled- return")
            return;
        }
        if !isPurchased && daysLeft <= 0{
            addLog(text: "func:- filterUrl- subscription expired return- return")
            return;
        }
        var urlString = url.removingPercentEncoding ?? url
        if urlString.contains("focusbear://start-activity?"){
            urlString = urlString.replacingOccurrences(of: "focusbear://start-activity?", with: "")
            
            // focusbear://start-activity?activity_id=1234s-sdf-&duration=600
            
            let activityInfo = urlString.components(separatedBy: "&")
            if activityInfo.count > 1{
                //let activityInfo = urlString.components(separatedBy: "=")
                
                let activityIdInfo  = activityInfo[0].components(separatedBy: "=")
                let activityDurationInfo  = activityInfo[1].components(separatedBy: "=")
                
                if activityIdInfo.count > 1 && activityDurationInfo.count > 1{
                    let activityId = activityIdInfo[1]
                    let activityDuration = activityDurationInfo[1]
                    
                    var isActivityFound = false
                    var specialHabit:habit?
                    var specialActivity:breakActivity?
                    
                    for habit in arrAllDaysMorningHabits{
                        if habit.id == activityId{
                            specialHabit = habit
                            isActivityFound = true
                            break;
                        }else if habit.name.lowercased() == activityId.lowercased(){
                            specialHabit = habit
                            isActivityFound = true
                            break;
                        }
                    }
                    
                    if !isActivityFound{
                        for habit in arrAllDaysEveningHabits{
                            if habit.id == activityId{
                                specialHabit = habit
                                isActivityFound = true
                                break;
                            }else if habit.name.lowercased() == activityId.lowercased(){
                                specialHabit = habit
                                isActivityFound = true
                                break;
                            }
                        }
                    }
                    
                    if !isActivityFound{
                        for activity in arrAllbreakActivities{
                            if activity.id == activityId{
                                specialActivity = activity
                                isActivityFound = true
                                break;
                            }else if activity.name.lowercased() == activityId.lowercased(){
                                specialActivity = activity
                                isActivityFound = true
                                break;
                            }
                        }
                    }
                    
                    if !isActivityFound{
                        let durationInSeconds = Int(activityDuration) ?? 0
                        if durationInSeconds >= 60 && SettingsManagerObject.isGeekModeEnabled{
                            for i in 0..<arrFocusType.count{
                                var isFocusModeFound = false
                                let id = arrFocusType[i]["id"] as? String ?? ""
                                let name = arrFocusType[i]["name"] as? String ?? ""
                                if id == activityId{
                                    isFocusModeFound = true
                                }else if name.lowercased() == activityId.lowercased(){
                                    isFocusModeFound = true
                                }
                                if isFocusModeFound{
                                    if isHardCorePomodoroModeOn{
                                        return;
                                    }
                                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                                        addLog(text: "Activity is running: Can not start a focus mode")
                                        let alert = NSAlert()
                                        alert.setSharingType()
                                        alert.messageText = "You can not start a focus mode while an activity is running."
                                        
                                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                                                alert.messageText = startingFocusModeInfo.value(forKey: "activityRunningCantStartFocusText") as? String ?? alert.messageText
                                            }
                                        }
                                        NSApplication.shared.activate(ignoringOtherApps: true)
                                        alert.runModal()
                                        return;
                                    }
                                    
                                    
                                    for j in 0..<arrFocusType.count{
                                        if arrFocusType[j]["isOn"] as? Bool == true || arrFocusType[j]["isPaused"] as? Bool == true{
                                            
                                            if i == j{
                                                return;
                                            }
                                            let alert = NSAlert()
                                            alert.setSharingType()
                                            alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
                                            var buttonStopFocusText = "Stop current focus mode and start this one"
                                            
                                            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                                if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
                                                    alert.messageText = focusAlreadyRunningText
                                                }
                                            }
                                            
                                            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                                                    buttonStopFocusText = startingFocusModeInfo.value(forKey: "buttonStopFocusText") as? String ?? buttonStopFocusText
                                                }
                                            }
                                            
                                            alert.addButton(withTitle: buttonOkText)
                                            alert.addButton(withTitle: buttonStopFocusText)
                                            NSApplication.shared.activate(ignoringOtherApps: true)
                                            let result = alert.runModal()
                                            if result == .alertSecondButtonReturn{
                                                addLog(text: "Stop current focus from alert and show start focus view")
                                                tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
                                                
                                                appdelegate?.menuShowPomodoroModeView()
                                                if !(pomodoroVcObj?.isViewLoaded ?? false){
                                                    pomodoroVcObj?.loadView()
                                                }
                                                pomodoroVcObj!.selectFocusModeWithId(id: arrFocusType[i]["id"] as? String ?? "", duration: durationInSeconds)
                                            }
                                            return;
                                        }
                                    }
                                    
                                    
                                    let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool ?? false
                                    
                                    
                                    if isRelaxFocus{
                                        if shouldAskPassword(){
                                            if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
                                                menuViewControllerObj?.showPasswordWindow()
                                                menuViewControllerObj?.isShowingPasswordForRelaxFocusMode = true
                                                customUrlHandleLastDurationForRelaxFocusMode = durationInSeconds
                                            }else{
                                                
                                                appdelegate?.menuShowPomodoroModeView()
                                                if !(pomodoroVcObj?.isViewLoaded ?? false){
                                                    pomodoroVcObj?.loadView()
                                                }
                                                pomodoroVcObj!.selectFocusModeWithId(id: arrFocusType[i]["id"] as? String ?? "", duration: durationInSeconds)
                                            }
                                        }else{
                                            appdelegate?.menuShowPomodoroModeView()
                                            if !(pomodoroVcObj?.isViewLoaded ?? false){
                                                pomodoroVcObj?.loadView()
                                            }
                                            pomodoroVcObj!.selectFocusModeWithId(id: arrFocusType[i]["id"] as? String ?? "", duration: durationInSeconds)
                                        }
                                    }else{
                                        appdelegate?.menuShowPomodoroModeView()
                                        if !(pomodoroVcObj?.isViewLoaded ?? false){
                                            pomodoroVcObj?.loadView()
                                        }
                                        pomodoroVcObj!.selectFocusModeWithId(id: arrFocusType[i]["id"] as? String ?? "", duration: durationInSeconds)
                                    }
                                    
                                    return;
                                }
                            }
                        }
                    }
                    
                    
                    
                    let durationInSeconds = Int(activityDuration) ?? 0
                    if durationInSeconds > 0{
                        if !isMainWindowLoaded{
                            mainWindowControllerObj?.loadWindow()
                        }
                        
                        if currentAction == ._INPROGRESS_{
                            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._CUSTOM_ROUTINE_{
                                if timerViewcontrollerObj != nil {
                                    if timerViewcontrollerObj?.timer != nil {
                                        timerViewcontrollerObj?.timer?.invalidate()
                                        
                                        //focusButtonService---//
                                        focusButtonServiceObject.pauseHabit()
                                        //--------------//
                                        
                                        enableSystemSleep()
                                        if timerViewcontrollerObj?.isVideoLodded ?? false{
                                            if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                                if #available(macOS 12.0, *) {
                                                    if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                                        timerViewcontrollerObj?.btnTabVideoClicked(self)
                                                    }
                                                    timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                                                } else {
                                                    // Fallback on earlier versions
                                                    timerViewcontrollerObj?.loadBlankUrl()
                                                }
                                            }
                                        }
                                    }
                                }
                                closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                            }
                        }
                        getHabitsVcObject().refreshLastPostponeCount()
                        closePupUpBlockIfVisible()
                        if currentState == ._MORNING_HABIT_{
                            getHabitsVcObject().stopActivityTimer()
                            getHabitsVcObject().postponeMorningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false, showAskIntention:false)
                        }else if currentState == ._EVENING_HABIT_{
                            getHabitsVcObject().stopActivityTimer()
                            getHabitsVcObject().postponeEveningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false, showAskIntention:false)
                        }else if currentState == ._CUSTOM_ROUTINE_{
                            getHabitsVcObject().postponeCustomRoutineFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false, showAskIntention:false, fromRoutineWarning:false)
                        }else if currentState == ._MICRO_BREAK_{
                            if breakWarningWcObj != nil{
                                if breakWarningWcObj?.window?.isVisible ?? false{
                                    breakWarningVcObj?.timer?.invalidate()
                                    breakWarningWcObj?.window?.close()
                                }
                            }
                            
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                            getHabitsVcObject().postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil, isFromBreakWarningWindow:false)
                        }else{
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                        }
                        
                        if !isActivityFound{
                            specialHabit = habit(id: "", name: activityId, durationSeconds: durationInSeconds, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
                        }
                        
                        getHabitsVcObject().startSpecialActivity(duration: durationInSeconds,habit:specialHabit, activity:specialActivity)
                    }
                    
                    
                    
                }
            }
        }
        else if urlString.contains("focusbear://event-about-to-start?"){
            addLog(text: "event-about-to-start:- \(urlString)")
            // Late No More announcing a meeting brings the app forward by itself (the `closePopover()`
            // below says as much: "popover was showing automatically reason: app activate"). That is the
            // app talking about a meeting, never the user asking for the main window — and when a routine
            // is already postponed this path shows NO window at all, so nothing else would stop a restore
            // putting one over the meeting.
            noteSelfActivation()
            urlString = urlString.replacingOccurrences(of: "focusbear://event-about-to-start?", with: "")
            // NOTE: the "an appointment popup is already visible → ignore" check used to sit here,
            // before the URL was even parsed. See below: it now needs the new meeting's end time,
            // because a popup for an EARLIER meeting must not swallow the next one.
            let arrActivityInfo = urlString.components(separatedBy: "&")
            if arrActivityInfo.count > 1{
                var eventTitle = ""
                var eventStartTime:Date?// = Date()
                var eventEndTime:Date?
                
                for info in arrActivityInfo{
                    let eventInfo  = info.components(separatedBy: "=")
                    if eventInfo.count > 1{
                        if eventInfo[0] == "event_title"{
                            eventTitle = eventInfo[1]
                            eventTitle = eventTitle.removingPercentEncoding ?? eventTitle
                        }else if eventInfo[0] == "event_start_time"{
                            var stringDate = eventInfo[1]
                            stringDate = stringDate.removingPercentEncoding ?? stringDate
                            let formatter = ISO8601DateFormatter()
                            if let date = formatter.date(from: stringDate) {
                                print(date) // Output: 2025-06-19 08:07:00 +0000
                                eventStartTime = date
                            } else {
                                print("Failed to parse date")
                            }
                            
                            //                            eventStartTime = getDateFromStringInUtc(date: stringDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                        }else if eventInfo[0] == "event_end_time"{
                            var stringDate = eventInfo[1]
                            stringDate = stringDate.removingPercentEncoding ?? stringDate
                            //                            eventEndTime = getDateFromStringInUtc(date: stringDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                            let formatter = ISO8601DateFormatter()
                            if let date = formatter.date(from: stringDate) {
                                print(date) // Output: 2025-06-19 08:07:00 +0000
                                eventEndTime = date
                            } else {
                                print("Failed to parse date")
                            }
                        }
                    }
                }
                // Late No More (the external app) fires this URL to warn an appointment is about to
                // start. Its trigger can be delivered late (e.g. the Mac was asleep, or a missed macOS
                // notification replays after waking) — without this check, a replayed/stale trigger for
                // an appointment that's long since ended still pops "about to start" and pauses habits.
                if let endTime = eventEndTime, endTime <= Date(){
                    addLog(text: "event-about-to-start:- ignoring stale trigger, appointment already ended at \(endTime)")
                    return
                }
                if let startTime = eventStartTime, Date().timeIntervalSince(startTime) > 15 * 60{
                    addLog(text: "event-about-to-start:- ignoring stale trigger, appointment started more than 15 minutes ago at \(startTime)")
                    return
                }
                // SECURITY: past the cut-off (the hard evening-routine lock), a Late No More appointment
                // trigger must NOT pause/unlock the routine — otherwise it's a free bypass of the cut-off
                // without the required password. This mirrors the enforcement already done for an
                // already-visible popup in returnFromSystemSleepCheckAppStateAgain (the shut-off/cut-off
                // branch there); the INITIAL trigger here was missing the same guard. The user must finish
                // their locked routine.
                if isCutOffTimeGoing(){
                    addLog(text: "event-about-to-start:- past cut-off, NOT pausing habits (cut-off lock enforced)")
                    return
                }
                // Late No More re-fires this URL whenever its own warning state is rebuilt (its
                // `shownWarnings` map is in-memory, so a relaunch or a sleep/wake replay re-arms it).
                // Don't re-open the popup for a meeting the user has already dealt with here.
                if let startTime = eventStartTime,
                   LateNoMoreDismissalRegistry.shared.isDismissed(LateNoMoreMeeting(title: eventTitle, startDate: startTime)){
                    addLog(text: "event-about-to-start:- already dismissed on this Mac, ignoring")
                    return
                }
                if let announcedEndTime = eventEndTime{
                    addLog(text: "event-about-to-start:- got end time")
                    // Remember EVERY announced meeting, popup or not: the routine's postpone is
                    // computed from the whole live/imminent chain, so it has to be able to see the
                    // meeting that follows the one currently on screen.
                    AnnouncedMeetingRegister.shared.record(title: eventTitle,
                                                           start: eventStartTime ?? Date(),
                                                           end: announcedEndTime)
                    // A popup still on screen for an EARLIER meeting must not swallow this trigger.
                    // Back-to-back meetings arrive as two triggers (Lunch 12:45-13:00 then UX checkin
                    // 13:00-13:20); dropping the second one wholesale meant nothing extended the
                    // postpone and the routine resumed inside the second call (report
                    // 2026-09-15_13-03-02). Re-point the popup at the meeting that reaches further;
                    // a duplicate or shorter trigger is still ignored so coverage never shrinks.
                    if popupAppointmentTimeWcObj?.window?.isVisible ?? false,
                       let visibleEndTime = popupAppointmentTimeVcObj?.endTime,
                       !MeetingCoverage.shouldRetargetAppointmentPopup(showing: visibleEndTime, incoming: announcedEndTime){
                        addLog(text: "event-about-to-start:- visible popup already covers this meeting, ignoring trigger")
                        return
                    }
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                        
                        lastCurrentState = currentState
                        lastCurrentAction = currentAction
                        getHabitsVcObject().stopActivityCountDownTimer()
                        
                        if currentHabitPlaying != nil || currentActivityPlaying != nil{
                            closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak()
                        }
                        
                        if currentState == ._MORNING_HABIT_{
                            getHabitsVcObject().refreshLastPostponeCount()
                            
                            if currentHabitPlaying != nil{
                                closePupUpBlockIfVisible()
                            }
                            
                        }else if currentState == ._EVENING_HABIT_{
                            getHabitsVcObject().refreshLastPostponeCount()
                            
                            if currentHabitPlaying != nil{
                                closePupUpBlockIfVisible()
                            }
                        }else if currentState == ._MICRO_BREAK_{
                            
                            
                            var lastSavedPostponeTime = Date()
                            activityPostponeCount = 0
                            var lastSavedPostponeCount = activityPostponeCount
                            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                            
                            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakActivityPostponeInfo) as? [String:Any]{
                                
                                
                                if let postponeCount =  infoDic["postponeCount"] as? Int{
                                    lastSavedPostponeCount = postponeCount
                                }
                                if let date =  infoDic["date"] as? Date{
                                    lastSavedPostponeTime = date
                                }
                            }
                            
                            if lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                                activityPostponeCount = lastSavedPostponeCount
                            }
                            
                            
                            
                            if currentActivityPlaying != nil{
                                closePupUpBlockIfVisible()
                            }
                        }else if currentState == ._CUSTOM_ROUTINE_{
                            if currentHabitPlaying != nil{
                                closePupUpBlockIfVisible()
                            }
                        }
                        
                        //Late No More disrupts saving achievements at end of activity with focus mode#919
                        if currentAction == ._END_ && activityCompletionVcObj != nil{
                            if (getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)){
                                if logQuantityVcObj != nil{// log quanity
                                    if (getHabitsVcObject().view.subviews.contains((logQuantityVcObj!.view))){
                                        logQuantityVcObj?.btnOkClicked(self)
                                    }
                                }
                                
                                if takeActivityNotesVcObj != nil{// notes
                                    if (getHabitsVcObject().view.subviews.contains((takeActivityNotesVcObj!.view))){
                                        takeActivityNotesVcObj?.btnOkClicked(self)
                                    }
                                }
                                
                                if focusCompletedForActivityVcObj != nil{// focus completed view
                                    if (getHabitsVcObject().view.subviews.contains((focusCompletedForActivityVcObj!.view))){
                                        focusCompletedForActivityVcObj?.btnContinueClicked(self)
                                    }
                                }
                            }
                        }
                        //--------------------------------------------------------------------------------------//
                        
                        getHabitsVcObject().stopActivityTimer()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        
                        showPopupAppointmentWindow(title: eventTitle, startTime: eventStartTime, endTime: announcedEndTime)
                        closeEasyPostponeWindowIfVisible()
                    }else{
                        // No routine to postpone right now — but one may already BE postponed, and
                        // that postpone was sized for the previous meeting. Stretch it over this one
                        // too, otherwise it expires partway into a back-to-back call.
                        getHabitsVcObject().extendPostponeToCoverAnnouncedMeetings()
                        closePopover()// popover was showing automatically reason: app activate so close popover here without checking any rhing
                    }
                    // Start the AI meeting session for the meeting's FULL remaining duration, regardless of
                    // routine state (even when the routine is already postponed or idle), so it reliably
                    // covers the whole meeting and supersedes an active all-day block schedule (a live
                    // session forces AI on + overrides the running focus mode to allow-list). Previously the
                    // session only started from the popup's Thanks/auto-close path — which fired at the
                    // meeting's END, yielding a ~1-minute session, or never started at all when the routine
                    // was already postponed (so the all-day block-list schedule governed the meeting and
                    // "allowed everything"). Opt-in via the AI-accountability setting; the nil-session guard
                    // stops an overlapping/replayed trigger restarting (and shortening) a live session.
                    if let meetingEndTime = eventEndTime {
                        Task { @MainActor in
                            if SettingsManagerObject.isAccountabilityBuddyEnabled, currentAccountabilityBuddySession == nil {
                                let remainingSeconds = Int(meetingEndTime.timeIntervalSinceNow)
                                if remainingSeconds > 0 {
                                    startMeetingFocusSession(title: eventTitle, durationMinutes: max(1, remainingSeconds / 60))
                                    // The meeting session covers a live call the user must actually attend, so drop
                                    // the routine's borderless full-screen window — otherwise it stayed covering the
                                    // whole screen and the user couldn't see/join the meeting.
                                    if mainWindowControllerObj?.isFullScreenVisible ?? false {
                                        mainWindowControllerObj?.window?.close()
                                    }
                                }
                            }
                        }
                    }
                }else{
                    addLog(text: "event-about-to-start:- end time is nil")
                }
            }
        }
    }
    
    var arrAllVideoKindUrls:[String] = ["https://vimeo.com/",
                                        "https://www.dailymotion.com/",
                                        "https://www.twitch.tv/",
                                        "http://www.veoh.com/",
                                        "http://www.metacafe.com/",
                                        "https://www.liveleak.com/",
                                        "https://www.viddler.com/",
                                        "https://9gag.com/tv",
                                        "https://9gag.com",
                                        "https://www.tiktok.com/",
                                        "https://www.bilibili.com/",
                                        "youtube.com"]
    
    func checkIsAnyVideoWebsiteIsRunning()->Bool{
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps{
            if let appUrl = app.bundleURL{
                let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    var isAllowed = false
                    if let allTabUrls = getBrowserAllTabUrl(browser: browser){
                        for  activeTabUrl in allTabUrls{
                            for turl in arrAllVideoKindUrls{
                                isAllowed = validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl)
                                if isAllowed{
                                    return true
                                }
                            }
                        }
                    }
                }
            }
        }
        return false
    }
    
    @objc func backgroundThread(){
        DispatchQueue.main.async {
            if isAppEnable{// If the app is disabled, this function will be called only in one case—when the app has been deactivated for 4 hours.
                self.checkIsMeetingsGoingOn() //and app kon kon si check krni haiu
            }else{
                if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
                    self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateFocusText)
                }
                return;
            }
            
            if (currentState == ._MICRO_BREAK_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
                
            }
  
            if isFocusModeRunning || (isAnyAllowedFocusModeActivityRunning && (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_)){
                calculateFocusAlignmentScore()
                saveRemainingFocusModeDuration()
            }
            
            customBlockingScheduleManagerObj.checkAndFinishScheduleIfNeeded()// Finish the current custom blocking schedule if its end time has passed
            self.processOfflineData()
            
            if isExpired{
                if let lastSubscriptionCheckDate = UserDefaults.standard.object(forKey: kUserdefaultsUserSubscriptionCheckDate) as? Date{
                    let currentDate = Date()
                    let diffHours = Calendar.current.dateComponents([.hour], from: lastSubscriptionCheckDate, to: currentDate).hour ?? 0
                    if diffHours > 24{
                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
                        allApiObject.getUserSubscriptionInfo(completionHandler: {dic,statusCode  in
                            if let subscriptionStatus = dic{
                                isPurchased = false
                                var activeEntitlementStatus = ""
                                if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
                                    // Consider every active entitlement — see SubscriptionEntitlements.
                                    if let paid = SubscriptionEntitlements.payingEntitlement(in: activeEntitlements){
                                        activeEntitlementStatus = paid
                                        isPurchased = true
                                    }else{
                                        activeEntitlementStatus = activeEntitlements.first ?? ""
                                        isPurchased = false
                                    }
                                }
                                let oldDaysLeft = daysLeft
                                daysLeft = 0
                                print(subscriptionStatus)
                                if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
                                    if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
                                        if let days_left = trial["days_left"] as? Int{
                                            print(days_left)
                                            daysLeft = days_left
                                        }
                                    }
                                }
                                if oldDaysLeft > 0{// subscription over need to restart
                                    if isPurchased == false && daysLeft == 0{
                                        addLog(text: "subscription over:- need to restart app")
                                        DispatchQueue.main.async {
                                            self.quitAndRestartApp()
                                        }
                                        
                                    }
                                }
                                if isPurchased == false && daysLeft == 0{
                                    isExpired = true
                                }
                            }
                        })
                    }
                }
            }
            
            
            if popupAppointmentTimeWcObj != nil{
                if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            
            if currentState == ._ABORT_{
                return;
            }
            if startTime == nil || shutOffTime == nil{
                return;
            }
            var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let currentDate = Date()
            
            //save progress during an activity (morning and evening) Progress lost when I restarted my computer during an activity#444
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && timerViewcontrollerObj != nil{
                if timerViewcontrollerObj?.timer?.isValid ?? false{
                    
                    var postPoneTime = currentDate
                    
                    if currentState == ._EVENING_HABIT_{
                        if currentDate > shutOffdate{// iska matlab 20-24 k bich
                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
                            postPoneTime = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? postPoneTime
                            
                        }
                    }
                    
                    let infoDic:[String:Any] = ["id":lastActivityRunningId, "duration":timerViewcontrollerObj?.currentTimer ?? 0, "date":postPoneTime]
                    
                    if currentState == ._CUSTOM_ROUTINE_{
                        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastCustomRoutineHabitRunningInfo)
                    }else{
                        UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastHabitRunningInfo)
                    }
                }
                
            }
            //  ////////////////////////////////////////////////////////////////
            
            
            if !shouldDoHabits(){
                customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()//3.31.463
                return;
            }
            
            if currentState == ._SPECIAL_ACTIVITY_{// if special activity  dont allow morning, evening. custom routine
                return;
            }
            
            if currentState == ._CUSTOM_ROUTINE_{
                if isCustomRoutineWasRunningInPostponeMorningHabit || isCustomRoutineWasRunningInPostponeEveningHabit{
                    return;
                }
            }
            

            // A class session owns the screen — don't trigger morning/evening routines, focus
            // summary, or the shutdown warning while it's running.
            if teacherSessionManagerObject.isTeacherSessionActive(){
                return;
            }

            /// 5  may 2022 (5 minute warning before shutdown time "It's time to wrap up for the day. Your shutdown time is in 5 minutes.")#62
            ///
            
            
            if arrAllDaysEveningHabits.count != 0{
                let fiveMinutesBeforeShutOffTime = shutOffdate.addingTimeInterval(-5 * 60)
                let sixtyFiveSecondsBeforeShutOffTime = fiveMinutesBeforeShutOffTime.addingTimeInterval(-5)
                if currentDate.compare(fiveMinutesBeforeShutOffTime) == .orderedAscending  && currentDate.compare(sixtyFiveSecondsBeforeShutOffTime) == .orderedDescending{
                    var shouldShowEveningHabit = true
                    if !isAppEnable{
                        shouldShowEveningHabit = false
                        
                        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                shouldShowEveningHabit = true
                            }
                        }
                    }
                    if shouldShowEveningHabit{
                        var shutdownNotificationTitle = "It's time to wrap up for the day. Your shutdown time is in 5 minutes."
                        
                        if let common = configjson.value(forKey: "common") as? NSDictionary{
                            shutdownNotificationTitle = common.value(forKey: "shutdownNotificationTitle") as? String ?? shutdownNotificationTitle
                        }
                        showNotificationWithMessage(msg: shutdownNotificationTitle)
                    }
                }
            }
            //  ////////////////
            
            
            if !self.isSystemSleep && !self.isScreenSaverStart && currentState != ._MICRO_BREAK_{//same condition in pomodoro view
                unfocusedTime += 5
            }

            
            if isShutOffTimeGoing(){
                if isAppEnable{
                    //Natural break detection not working if the user closes their laptop lid #319
                    detectNatualBreaks()
                    //
                }
                var shouldShowEveningHabit = true
                
                if !isAppEnable{
                    shouldShowEveningHabit = false
                    
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        if cutOffTime != nil{
                            if isCutOffTimeGoing(){
                                if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                    shouldShowEveningHabit = true
                                }
                            }else{
                                if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                    shouldShowEveningHabit = true
                                }
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                shouldShowEveningHabit = true
                            }
                        }
                    }
                }
                
                if shouldShowEveningHabit{
                    if arrAllDaysEveningHabits.count == 0 {// if count is 0 then we will not do anything // if change here then also change in habit state class
                        
                        // ----Focus Bear isn’t prompting breaks (#1548, v2.27.428)---
                        // When there are no morning/evening habits, `isHabitAlreadyShowed` remains true,
                        // preventing the code from reaching the section that sets the activity timer.
                        // To ensure the timer setup executes, we reset `isHabitAlreadyShowed` to false here.
                        isHabitAlreadyShowed = false
                        //-----
                        
                        checkCustomRoutineTime()
                        customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                        return;
                    }
                    
                    if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromEveningHabit{// new work  24/12/22
                        return;
                    }
                    
                    if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeEveningHabit{
                        return;
                    }
                    isBreakActivityExecuteFromMorningHabit = false
                    isBreakActivityExecuteFromPostponeMorningHabit = false
                    
                    if currentState == ._POSTPONE_MORNING_HABIT_{//if user postpone again and again
                        currentState = ._NOTHING_
                    }
                    if currentState == ._POSTPONE_FOCUS_SUMMARY_{
                        addLog(text: "Focus Summary is Postponed. Focus Summary Time checking Cancelled.")
                        
                        if cutOffTime != nil{//If you focus summary routine before cutoff time, it doesn't cut you off #1368
                            if focusSummaryLastPostponeTime != nil{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                                if isCutOffTimeGoing(){
                                    if focusSummaryLastPostponeTime! < cutOffDate{
                                        addLog(text: "Focus Summary postpone abandoned at the start of cutoff_for_high_priority_activities")
                                        currentState = ._NOTHING_
                                        getHabitsVcObject().stopPostponeEndTimer()
                                        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                                    }
                                }
                            }
                        }
                        
                        
                        if currentState == ._POSTPONE_FOCUS_SUMMARY_{
                            checkCustomRoutineTime()
                            customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                        }
                        return;
                    }
                    
                    if currentState == ._POSTPONE_EVENING_HABIT_{
                        addLog(text: "Evening Routine is Postponed. Evening Habits Time checking Cancelled.")
                        if cutOffTime != nil{//Postpone should be abandoned at the start of cutoff_for_high_priority_activities/evening_routine#513
                            if !isHighPrioritySequenceGoing{
                                if eveningRoutineLastPostponeTime != nil{
                                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!

                                    if eveningRoutineLastPostponeTime! < cutOffDate && isCutOffTimeGoing(){
                                        addLog(text: "Postpone abandoned at the start of cutoff_for_high_priority_activities")
                                        currentState = ._NOTHING_
                                        getHabitsVcObject().stopPostponeEndTimer()
                                        closeSmallCountDownTimerBoxIfVisibleForFocusBreak()
                                    }
                                }
                            }
                        }
                        
                        if currentState == ._POSTPONE_EVENING_HABIT_{// need to check this
                            checkCustomRoutineTime()
                            customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                        }
                        return;
                    }
                    
                    
                    if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                        if currentState != ._SHUTOFFMAC_{
                            // This check is a five-second repeating timer, and `shutOffMac()` used to run
                            // its whole pipeline — alerts, window raising, `activate(ignoringOtherApps:)` —
                            // on every beat of it. Run it once per situation instead.
                            self.shutOffMacIfNagIsDue()
                        }else if shutOffTimeVcObj != nil{
                            if shutOffTimeVcObj!.boxUpEarly.isHidden && shutOffTimeVcObj!.step == 0{
                                shutOffTimeVcObj?.checkUpEarlyTime()
                            }
                        }
                    }else{
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                            if Date().compare(date) == .orderedDescending {
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                                addLog(text: "Shutdown Aborted date passed.")// log added  v 2.28.448
                            }else{
                                customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()//v 2.29.459
                            }
                        }
                    }
                }
            }else{
                
                if isAppEnable{//7 may 2022 (if you abort Habits, it shouldn't skip the evening routine #56)//this func is callimng even if app is disable but morning habit will not execute if app is diable
                    
                    
                    //Natural break detection not working if the user closes their laptop lid #319
                    detectNatualBreaks()
                    //
                    
                    if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromMorningHabit{// new work  24/12/22
                        return;
                    }
                    if currentState == ._MICRO_BREAK_ && isBreakActivityExecuteFromPostponeMorningHabit{ //  new work - micro break start after postponing morning habit
                        return;
                    }
                    isBreakActivityExecuteFromEveningHabit = false
                    isBreakActivityExecuteFromPostponeEveningHabit = false
                    
                    if currentState != ._MORNING_HABIT_{
                        if currentState == ._POSTPONE_EVENING_HABIT_{//if user postpone again and again
                            currentState = ._NOTHING_
                        }
                        
                        if !isHabitAlreadyShowed{
                            if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
                                startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
                            }
                            
                            // if alldays array is blank then we do not write date in userdefaults(and checkLastHabitShowDate func will not call so no need to write date  )
                            if arrAllDaysMorningHabits.count == 0 {//  state bhi change krenge na currentState = ._NOTHING_
                                //                print("arr AllMorningHabits count is 0:-  skip morning habit")
                                addLog(text: "Morning Habits count is 0:- Morning Habits skipped.")
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                                
                                isHabitAlreadyShowed = true
                                unfocusedTime = 0
                                if !isMainWindowLoaded{
                                    mainWindowControllerObj?.loadWindow()
                                }else if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                    self.abortAllProcess()
                                    mainWindowControllerObj?.window?.close()
                                    hideBlankWindowInSecondaryMonitor()
                                    leftMenuVcObj?.enableAllItems()
                                    currentState = ._NOTHING_
                                }
                                getHabitsVcObject().setActivityTimer()
                                return;
                            }
                            
                            
                            // - If a morning habit sequence is already running, retrieve it and continue from where it left off.
                            
                            //********************** new work*************************//
                            
                            if !self.isProcessingHabitRoutine{
                                if currentState == ._POSTPONE_MORNING_HABIT_{
                                    addLog(text: "Morning Routine is Postponed. Morning Habits Time checking Cancelled.")
                                    checkCustomRoutineTime()
                                    customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                                    return;
                                }
                                
                                if self.isUserOnMeeting{
                                    addLog(text: "isUserOnMeeting True: Morning Habits Time checking Cancelled.")
                                    customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                                    return;
                                }
                                arrFilteredMorningHabits.removeAll()
                                arrPreFilteredMorningHabits.removeAll()
                                let today = Date()

                                for habit in arrAllDaysMorningHabits{
                                    if RoutineHabitSchedule.shouldPlay(habitId: habit.id, daysOfWeek: habit.days_of_week, on: today) {
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                
                                if arrFilteredMorningHabits.count == 0 {
                                    //                print("arr arrFilteredMorningHabits count is 0:-  skip morning habit")
                                    addLog(text: "Filtered Morning Habits count is 0:- Morning Habits skipped.")
                                    UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                                    isHabitAlreadyShowed = true
                                    unfocusedTime = 0
                                    if !isMainWindowLoaded{
                                        mainWindowControllerObj?.loadWindow()
                                    }else if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                        self.abortAllProcess()
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                        leftMenuVcObj?.enableAllItems()
                                        currentState = ._NOTHING_
                                    }
                                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                    getHabitsVcObject().setActivityTimer()
                                    return;
                                }
                                // The morning routine is due but a focus session is still running — finish it
                                // and let the routine render. This is also the path a postpone → start focus →
                                // Stop uses: stopFocusModeAndResumeRoutine() (menuViewController) only flips the
                                // routine's postpone state back and calls backgroundThread(); it relies on THIS
                                // block to actually finish the running session. Don't gate it on time-only
                                // conditions or that Stop-resume flow leaves the session running.
                                if isFocusModeOnOrPaused(){
                                    addLog(text: "isFocusModeOnOrPaused True: focusModeFinished.")
                                    self.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: true, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
                                    return;
                                }
                                
                                //--------------------------------------------------------------------//
                                //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
                                //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
                                isActivitiesReducedInExpiredApp = false
                                if isExpired{
                                    if arrFilteredMorningHabits.count > activitiesCountInExpireApp{
                                        isActivitiesReducedInExpiredApp = true
                                        let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                                        arrFilteredMorningHabits.removeAll()
                                        for i in 0..<activitiesCountInExpireApp{
                                            arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                                        }
                                    }
                                }
                                //----------------------------------------------------------------------//
                                self.isProcessingHabitRoutine = true//after this line this should be false
                                
                                
                                
                                addLog(text: "get Last Activity Info")
                                
                                if isMainWindowLoaded{// if main window is visible show loader
                                    if mainWindowControllerObj?.window?.isVisible ?? false{
                                        getHabitsVcObject().showLoaderView()
                                    }
                                }
                                allApiObject.getLastActivityInfo(completionHandler: { json in
                                    DispatchQueue.main.async {
                                        addLog(text: "current-activity-props completion: enter")   // freeze-diag: bracket the completion (2026-07-09 hang dead-ended right after 'success')
                                        if isMainWindowLoaded{// if main window is visible show loader
                                            if mainWindowControllerObj?.window?.isVisible ?? false{
                                                getHabitsVcObject().removeSubViews()
                                            }
                                        }

                                        getHabitsVcObject().hideLoaderView()
                                        addLog(text: "current-activity-props completion: loader hidden, processing json")   // freeze-diag
                                        if json != nil{
                                            //                print(json)
                                            // check is there any change in settings
                                            if let lastSettingsModifiedDateString = json?.value(forKey: "last_time_user_settings_modified") as? String{
                                                if let lastSettingsModifiedDate = getDateFromStringInUtc(date: lastSettingsModifiedDateString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                    if applastSettingsGetTime != nil{
                                                        if lastSettingsModifiedDate.compare(applastSettingsGetTime!) == .orderedDescending{
                                                            settingsChangedDuringHabitsCurrentActivityProps()
                                                            return;
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                            // additional check that if user change pc and there is not locally save that morning routine is done today than  check is there morning routine done by user or not
                                            if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                                                if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                                    if let sequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
                                                        if lastCompletedSequenceId == sequenceID{
                                                            if let lastCompletedSequenceStartedAt = json?.value(forKey: "last_completed_sequence_started_at") as? String{
                                                                if let activityStartDate = getDateFromStringInUtc(date: lastCompletedSequenceStartedAt, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                                    
                                                                    if activityStartDate.compare(startDate) == .orderedDescending{
                                                                        UserDefaults.standard.set(activityStartDate, forKey: kUserdefaultsLastHabitShowDate)
                                                                        
                                                                        UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                                                                        
                                                                        isHabitAlreadyShowed = true
                                                                        self.isProcessingHabitRoutine = false
                                                                        if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                            self.abortAllProcess()
                                                                            mainWindowControllerObj?.window?.close()
                                                                            hideBlankWindowInSecondaryMonitor()
                                                                        }
                                                                        leftMenuVcObj?.enableAllItems()
                                                                        currentState = ._NOTHING_
                                                                        mainWindowControllerObj?.loadWindow()
                                                                        getHabitsVcObject().setActivityTimer()
                                                                        addLog(text: "morning habit already shown for today - reason (backend return last_completed_sequence_started_at after morning routine start time)")
                                                                        return
                                                                    }
                                                                    
                                                                }
                                                            }
                                                            
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            
                                            if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                                                captureDayPlanCompletedIds(todayRoutineProgress)
                                                if let morningRoutine = todayRoutineProgress.value(forKey: "morning_routine") as? NSDictionary,let sequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
                                                    if let todaySequenceId = morningRoutine.value(forKey: "sequence_id") as? String, let status = morningRoutine.value(forKey: "status") as? String{
                                                        if todaySequenceId == sequenceID && status.lowercased() == "completed"{
                                                            addLog(text: "morning habit already shown for today - reason (backend return status is completed)")
                                                            
                                                            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                                            UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                                                            
                                                            isHabitAlreadyShowed = true
                                                            self.isProcessingHabitRoutine = false
                                                            if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                self.abortAllProcess()
                                                                mainWindowControllerObj?.window?.close()
                                                                hideBlankWindowInSecondaryMonitor()
                                                                leftMenuVcObj?.enableAllItems()
                                                            }
                                                            currentState = ._NOTHING_
                                                            mainWindowControllerObj?.loadWindow()
                                                            getHabitsVcObject().setActivityTimer()
                                                            addLog(text: "morning habit already shown for today - reason (backend return last_completed_sequence_started_at after morning routine start time)")
                                                            return
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            
                                            
                                            // new work  26/4/25 / cehck from "today_routine_progress" in app version 1.22.362
                                            
                                            if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                                                captureDayPlanCompletedIds(todayRoutineProgress)
                                                if let morningRoutine = todayRoutineProgress.value(forKey: "morning_routine") as? NSDictionary,let sequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
                                                    if let todaySequenceId = morningRoutine.value(forKey: "sequence_id") as? String, let status = morningRoutine.value(forKey: "status") as? String{
                                                        let statusLowerCased = status.lowercased()
                                                        if todaySequenceId == sequenceID && (statusLowerCased == "in_progress" || statusLowerCased == "postponed") && currentState != ._CUSTOM_ROUTINE_{
                                                            
                                                            
                                                            addLog(text: "morning habit sequnce is pending. start from current pending habit")
                                                            self.isProcessingHabitRoutine = false
                                                            var skippedActivities = [String]()
                                                            if let activities = morningRoutine.value(forKey: "skipped_habit_ids") as? [String]{
                                                                skippedActivities = activities
                                                            }//current_sequence_completed_activities
                                                            
                                                            var completedActivities = [String]()
                                                            if let activities = morningRoutine.value(forKey: "completed_habit_ids") as? [String]{
                                                                completedActivities = activities
                                                            }
                                                            // need to calculate activityId here
                                                            
                                                            self.startHabitsCall(activityId: nil, skippedActivities:skippedActivities, completedActivities: completedActivities, needToCreateActivityId: true)
                                                            return;
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            //--------------------------------------------------------//
                                            
                                            self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])//
                                            self.isProcessingHabitRoutine = false
                                            addLog(text: "start new morning routine sequence. morning habit sequnce is not pending.")
                                            
                                            
                                            
                                            
                                        }else{
                                            addLog(text: "func backgrounThread:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                                            if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitsStartedDate) as? Date{
                                                
                                                addLog(text: "start new morning routine sequence:- LastHabitsStartedDate found")
                                                if date.compare(startDate) == .orderedDescending{//if
                                                    if let lastActivityId = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitID) as? String{
                                                        for i in 0..<arrFilteredMorningHabits.count{
                                                            if arrFilteredMorningHabits[i].id == lastActivityId{
                                                                if i == arrFilteredMorningHabits.count - 1{// this case will never happened because we will write morning habit done (kUserdefaultsLastHabitShowDate) locally if all activities done in morning habit
                                                                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                                                    
                                                                    UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
                                                                    
                                                                    isHabitAlreadyShowed = true
                                                                    self.isProcessingHabitRoutine = false
                                                                    if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                        self.abortAllProcess()
                                                                        mainWindowControllerObj?.window?.close()
                                                                        hideBlankWindowInSecondaryMonitor()
                                                                        leftMenuVcObj?.enableAllItems()
                                                                    }
                                                                    currentState = ._NOTHING_
                                                                    mainWindowControllerObj?.loadWindow()
                                                                    getHabitsVcObject().setActivityTimer()
                                                                }else{
                                                                    addLog(text: "start new morning routine sequence:- Last Habit id is from morning habit, show morning Habit from last habit id found in userdefaults")
                                                                    self.isProcessingHabitRoutine = false
                                                                    self.startHabitsCall(activityId: arrFilteredMorningHabits[i+1].id, skippedActivities:[], completedActivities: [])
                                                                }
                                                                
                                                                return;
                                                            }
                                                        }
                                                        
                                                        addLog(text: "start new morning routine sequence Last Habit id is not from morning habit")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                        self.isProcessingHabitRoutine = false
                                                        
                                                    }else{
                                                        addLog(text: "start new morning routine sequence:- Last Habit id is nil")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                        self.isProcessingHabitRoutine = false
                                                    }
                                                }else{
                                                    addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is not from current day")
                                                    self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                            }else
                                            {
                                                addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is nil")
                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                self.isProcessingHabitRoutine = false
                                            }
                                            
                                        }
                                    }
                                }
                                )
                            }
                            
                            //***********************************************************//
                            
                            // return;
                            
                        }else{
                            if arrAllDaysMorningHabits.count != 0 {
                                if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
                                    self.checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
                                }
                            }
                        }
                        if isHabitAlreadyShowed{
                            checkCustomRoutineTime()
                            customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
                        }
                    }
                }
                
            }
            
        }
    }
    
    
    var timerHighPriorityHabitTime:Timer?

    /// The shutdown nag that last ran, so the five-second check can tell a new situation from the
    /// same one polled again.
    var lastShutOffNag: ShutdownNagRecord?
    /// When `returnFromSystemSleepCheckAppStateAgain` last ended the running routine so the shutdown
    /// check could rebuild it. See `ShutdownNagPolicy.decide`.
    var routineTornDownForWakeAt: Date?

    /// When a shutdown prompt first wanted focus and found the user in a menu. Bounds how long the
    /// shutdown itself will hold back.
    var shutdownFocusWaitingSince: Date?

    /// Re-asks for focus while the shutdown screen is being held back for an open menu.
    var shutdownFocusRetryTimer: Timer?
    
    func startTimerAlertHighPriorityHabit(durationSeconds:Int) {
        self.timerHighPriorityHabitTime = nil
        DispatchQueue.global().sync {
            self.timerHighPriorityHabitTime = Timer.scheduledTimer(timeInterval: TimeInterval(durationSeconds), target: self, selector: #selector(self.performTimerHighPriorityHabit), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerHighPriorityHabitTime!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerHighPriorityHabit() {
        self.timerHighPriorityHabitTime?.invalidate()
        self.timerHighPriorityHabitTime = nil
        NSApp.stopModal()
    }
    
    /// The five-second shutdown check, filtered so the shutdown pipeline runs once per situation
    /// rather than once per timer beat. See `ShutdownNagPolicy` for why.
    func shutOffMacIfNagIsDue(){
        let now = Date()
        let situation = ShutdownNagSituation(state: currentState,
                                             action: currentAction,
                                             habitIndex: currentHabitIndex,
                                             isCutOffPassed: cutOffTime == nil ? false : isCutOffTimeGoing())
        let abortedUntil = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date
        let isAborted = ShutdownNagPolicy.isAborted(abortedUntil: abortedUntil, now: now)

        switch ShutdownNagPolicy.decide(isShutdownAborted: isAborted, situation: situation,
                                        lastNag: lastShutOffNag, now: now,
                                        routineTornDownForWakeAt: routineTornDownForWakeAt) {
        case .stayQuiet:
            return
        case .fire:
            lastShutOffNag = ShutdownNagRecord(situation: situation, firedAt: now)
            shutOffMac()
        }
    }

    /// Act on a `ShutdownFocusPolicy` decision. `deferToUser` deliberately leaves focus alone: the
    /// user is in a menu, and taking focus is what dismisses it.
    func applyShutdownFocus(_ decision: ShutdownFocusDecision){
        switch decision {
        case .takeFocus:
            NSApplication.shared.activate(ignoringOtherApps: true)
        case .requestAttention:
            _ = NSApp.requestUserAttention(.criticalRequest)
            NSApplication.shared.activate(ignoringOtherApps: false)
        case .deferToUser:
            addLog(text: "Shutdown prompt: the menu bar is in use — not taking focus")
            _ = NSApp.requestUserAttention(.criticalRequest)
        }
    }

    /// Ask for focus on behalf of a shutdown prompt, honouring `ShutdownFocusPolicy`.
    func requestShutdownFocus(urgency: ShutdownFocusUrgency){
        let now = Date()
        let decision = ShutdownFocusPolicy.decide(urgency: urgency,
                                                  menuBar: MenuBarActivityProbe.shared.activity(),
                                                  now: now,
                                                  waitingSince: shutdownFocusWaitingSince)
        if decision == .deferToUser {
            if shutdownFocusWaitingSince == nil { shutdownFocusWaitingSince = now }
            // The shutdown itself still has to happen, so keep asking until the user is out of the
            // menu — or until the policy runs out of patience on their behalf.
            if urgency == .shutdownStarting { scheduleShutdownFocusRetry(urgency: urgency) }
        } else {
            shutdownFocusWaitingSince = nil
        }
        applyShutdownFocus(decision)
    }

    private func scheduleShutdownFocusRetry(urgency: ShutdownFocusUrgency){
        shutdownFocusRetryTimer?.invalidate()
        shutdownFocusRetryTimer = Timer.scheduledTimer(withTimeInterval: kShutdownFocusRetrySeconds,
                                                       repeats: false) { [weak self] _ in
            self?.requestShutdownFocus(urgency: urgency)
        }
    }

    @objc func shutOffMac(){
        isHabitAlreadyShowed = false
        addLog(text: "Initiating shut off process.")

        //    (Mic/camera shouldn't prevent shutdown #62)
        if UserDefaults.standard.object(forKey: kUserdefaultsShutOffCancelledForEveningRoutine) == nil{
            if (currentState == ._EVENING_HABIT_ && currentAction == ._START_) || currentState == ._FOCUS_SUMMARY_{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                let hoursToAllowUserToDoHabitsBeforeMorningHabitTime = 4
                var fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
                let curreentDate = Date()
                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate
                    fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
                }
                if curreentDate > fourHourBeforeStartTime{
                    if currentState == ._FOCUS_SUMMARY_{
                        addLog(text: "Focus summary aborted. reason:- four hours remaining in start morning routines.")
                        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
                        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
                        }
                        leftMenuVcObj?.enableAllItems()
                        currentState = ._NOTHING_
                        focusSummaryVcObj?.viewVisibleCount = 0
                    }
                    
                    currentHabitIndex = -1
                    addLog(text: "Evening routine aborted. reason:- four hours remaining in start morning routines and evening routine is not started yet.")
                    
                    
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                        showBlankWindowInSecondaryMonitor()
                    }
                    leftMenuVcObj?.showHabitsView()
                    getHabitsVcObject().shutOffMac()
                    return;
                }
            }
        }
        
        if currentState == ._EVENING_HABIT_{
            if cutOffTime != nil{
                
                if currentAction == ._INPROGRESS_{
                    if isCutOffTimeGoing(){
                        if !arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
                            addLog(text: "evening habit skipped:- running late global cutoff time passed:- \(arrFilteredEveningHabits[currentHabitIndex].name)  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
                            abortAllProcess()
                            if mainWindowControllerObj?.window?.isVisible ?? false{
                                mainWindowControllerObj?.window?.close()
                                hideBlankWindowInSecondaryMonitor()
                            }
                            let alertHighPriorityHabitTime = NSAlert()
                            alertHighPriorityHabitTime.setSharingType()
                            var cutOffTimePassedText = "Running low on time - let's just focus on the high priority habits for the rest of the evening."
                            var cutOffTimePassedsubTitle = "Your high priority habits will start after 5 seconds."
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                cutOffTimePassedText = common.value(forKey: "cutOffTimePassedText") as? String ?? cutOffTimePassedText
                                cutOffTimePassedsubTitle = common.value(forKey: "cutOffTimePassedsubTitle") as? String ?? cutOffTimePassedsubTitle
                            }
                            alertHighPriorityHabitTime.messageText = cutOffTimePassedText
                            alertHighPriorityHabitTime.informativeText = cutOffTimePassedsubTitle
                            alertHighPriorityHabitTime.addButton(withTitle: buttonOkText)
                            
                            // Telling the user a habit was skipped is not worth pulling the screen out
                            // from under whatever they are doing.
                            self.requestShutdownFocus(urgency: .notice)
                            self.startTimerAlertHighPriorityHabit(durationSeconds: 5)//
                            alertHighPriorityHabitTime.runModal()
                            //                            currentState = ._NOTHING_
                            isHighPrioritySequenceGoing = true
                            releaseFullScreenAfterCutoffSkip()
                            mainWindowControllerObj?.showWindow(self)
                            showBlankWindowInSecondaryMonitor()
                            leftMenuVcObj?.showHabitsView()
                            getHabitsVcObject().showThirdVc()
                            activityCompletionVcObj?.eveningHabitSkipped()
                        }else{
                            if let cutOffTime = arrFilteredEveningHabits[currentHabitIndex].cutOffTime{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                let currentDate = Date()
                                if currentDate > cutOffDate{
                                    abortAllProcess()
                                    if mainWindowControllerObj?.window?.isVisible ?? false{
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                    }
                                    addLog(text: "evening habit skipped:- cutoff time for this running habit passed:- \(arrFilteredEveningHabits[currentHabitIndex].name)  \(arrFilteredEveningHabits[currentHabitIndex].id)") // remove this
                                    let alertHighPriorityHabitTime = NSAlert()
                                    alertHighPriorityHabitTime.setSharingType()
                                    var cutOffTimePassedForHabitText = "It's past the cutoff time you set for this habit. Taking you to your next habit."
                                    
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        cutOffTimePassedForHabitText = common.value(forKey: "cutOffTimePassedForHabitText") as? String ?? cutOffTimePassedForHabitText
                                    }
                                    alertHighPriorityHabitTime.messageText = cutOffTimePassedForHabitText
                                    alertHighPriorityHabitTime.addButton(withTitle: buttonOkText)
                                    
                                    NSApplication.shared.activate(ignoringOtherApps: true)
                                    self.startTimerAlertHighPriorityHabit(durationSeconds: 5)
                                    alertHighPriorityHabitTime.runModal()
                                    isHighPrioritySequenceGoing = true
                                    releaseFullScreenAfterCutoffSkip()
                                    mainWindowControllerObj?.showWindow(self)
                                    showBlankWindowInSecondaryMonitor()
                                    leftMenuVcObj?.showHabitsView()
                                    getHabitsVcObject().showThirdVc()
                                    activityCompletionVcObj?.eveningHabitSkipped()
                                }
                            }
                        }
                    }
                }
            }
            if currentState == ._EVENING_HABIT_{
                return;
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            return;
        }
        
        abortAllProcess()
        if isFocusModeOnOrPaused(){
            // v 2.28.453
            //  bug:- After completing the evening habit, when Focus Mode was started before sleep time, the finish screen appeared immediately. When clicking Continue, the app got stuck on the same screen and did not proceed
            // solved:- if free time then we will not stop focus session
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                if Date().compare(date) == .orderedAscending {//"Evening habits already shown for today
                    if isShutOffTimeGoing() && !isCutOffTimeGoing(){
                        return;
                    }
                }
            }
            tryFocusModeFinished(isSilent: false, isShutOffTime: true, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
            return;
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date == nil{
            if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                mainWindowControllerObj?.loadWindow()
            }
            getHabitsVcObject().showFocusSummaryView()
            return;
        }else{
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date{
                if Date().compare(date) == .orderedDescending {
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsFocusSummaryShowedTillDate)
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
                    getHabitsVcObject().showFocusSummaryView()
                    return;
                }else{
                    addLog(text: "Focus Summary already shown for today - skipping.")
                }
            }
        }
        
        if arrAllDaysEveningHabits.count != 0{//} && !iseveningHabitAlreadyShowed {
            if UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date == nil{
                //            if currentState != ._SHUTOFFMAC_{
                processEveningHabit()
                return;
                //}
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                    if Date().compare(date) == .orderedDescending {
                        processEveningHabit()
                        return;
                    }else{
                        addLog(text: "Evening habits already shown for today - skipping.")
                    }
                }
            }
        }else{
            print("arr AllEveningHabits count is 0:-  skip Evening habit")
        }
        
        if isCutOffTimeAboutToReach(){
            if !(mainWindowControllerObj?.window!.isVisible)! {
                mainWindowControllerObj?.showWindow(self)
            }
            showBlankWindowInSecondaryMonitor()
            getHabitsVcObject().shutOffMac()
        }else{
            customBlockingScheduleManagerObj.checkCustomBlockingScheduleTime()
        }
    }
    
    func showEveningHabit(activityId: String?, skippedActivities:[String], completedActivities:[String], needToCreateActivityId:Bool = false){
        additionalHabitTotalCompletedSeconds = 0
        
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        var activityId = activityId
        if activityId == nil && needToCreateActivityId{
            if skippedActivities.count != 0 || completedActivities.count != 0{
                for i in 0..<arrFilteredEveningHabits.count{
                    if !completedActivities.contains(arrFilteredEveningHabits[i].id){
                        activityId = arrFilteredEveningHabits[i].id
                        break;
                    }
                }
            }
        }
        
        
        if activityId != nil{
            let arrTempFilteredEveningHabits = arrFilteredEveningHabits
            arrFilteredEveningHabits.removeAll()
            
            var isActivityFound = false
            for i in 0..<arrTempFilteredEveningHabits.count{
                
                if arrTempFilteredEveningHabits[i].id == activityId!{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                    isActivityFound = true
                }else if isActivityFound{
                    if !completedActivities.contains(arrTempFilteredEveningHabits[i].id){
                        arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                    }else{
                        if !skippedActivities.contains(arrTempFilteredEveningHabits[i].id){
                            if arrTempFilteredEveningHabits[i].useTimer{
                                additionalHabitTotalCompletedSeconds += arrTempFilteredEveningHabits[i].durationSeconds
                            }
                        }
                    }
                }else{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                }
                
            }
        }
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        isHighPrioritySequenceGoing = false
        if cutOffTime != nil{
            if isCutOffTimeGoing(){
                
                var isAnyHighPriorityActivityFound = false
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        isAnyHighPriorityActivityFound = true
                        
                        break;
                        
                    }
                }
                if !isAnyHighPriorityActivityFound{
                    abortAllProcess()
                    addLog(text: "No activities with high Priority found:- showing ShutOff screen with no activities warning")// v 2.28.450
                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                    
                    let curreentDate = Date()
                    if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                    }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                    }
                    
                    
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                    }
                    showBlankWindowInSecondaryMonitor()
                    getHabitsVcObject().shutOffMac()
                    getHabitsVcObject().showAlertNoHighPriorityActivities()
                    return;
                }
                
                
                isHighPrioritySequenceGoing = true
            }
        }
        
        
        if activityId == nil{
            arrPreFilteredEveningHabits = arrFilteredEveningHabits
            
            //  //Let user temporarily customise routine before starting#938
            let currentDate = Date()
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                    if lastSavedSequenceId == arrPreFilteredEveningHabits[0].activity_sequence_id && date.compare(currentDate) == .orderedDescending{
                        
                        
                        if arrHabitIds.count != 0{
                            arrFilteredEveningHabits.removeAll()
                            
                            for habit in arrPreFilteredEveningHabits{
                                if arrHabitIds.contains(habit.id){
                                    arrFilteredEveningHabits.append(habit)
                                }else{
                                    addLog(text: "evening habit skipped:- habit was not selected by user last time:- \(habit.name)  \(habit.id)") // remove this
                                }
                            }
                            if arrFilteredEveningHabits.count == 0{
                                arrFilteredEveningHabits = arrPreFilteredEveningHabits
                            }
                        }else{
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                        }
                    }
                }
            }
            //
            
            //focusButtonService-------//
            focusButtonServiceObject.sendEveningHabitsToFocusDevice()
            //---------//
            
            getHabitsVcObject().showAllEveningHabits()
        }else{
            
            arrPreFilteredEveningHabits = arrFilteredEveningHabits
            //  //Let user temporarily customise routine before starting#938
            let currentDate = Date()
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                    if lastSavedSequenceId == arrPreFilteredEveningHabits[0].activity_sequence_id && date.compare(currentDate) == .orderedDescending{
                        
                        if arrHabitIds.count != 0{
                            arrFilteredEveningHabits.removeAll()
                            
                            var isActivityFound = false
                            for habit in arrPreFilteredEveningHabits{
                                if habit.id == activityId!{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredEveningHabits.append(habit)
                                    }
                                    isActivityFound = true
                                }else if isActivityFound{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredEveningHabits.append(habit)
                                    }
                                }else{
                                    arrFilteredEveningHabits.append(habit)
                                }
                            }
                            
                            if arrFilteredEveningHabits.count == 0{
                                arrFilteredEveningHabits = arrPreFilteredEveningHabits
                            }
                        }else{
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                        }
                    }
                }
            }
            //
            
            //focusButtonService-------//
            focusButtonServiceObject.sendEveningHabitsToFocusDevice()
            //---------//
            
            var isActivityFound = false
            for i in 0..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].id == activityId!{
                    isActivityFound = true
                    if i == 0{
                        getHabitsVcObject().startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false, skippedActivities:skippedActivities, completedActivities:completedActivities)
                    }else{
                        if skippedActivities.count == 0{
                            habitTotalCompletedSeconds = 0
                            for j in 0..<i{
                                if arrFilteredEveningHabits[j].useTimer{
                                    if isHighPrioritySequenceGoing{
                                        if arrFilteredEveningHabits[j].isPriorityHigh{
                                            habitTotalCompletedSeconds += arrFilteredEveningHabits[j].durationSeconds!
                                        }
                                    }else{
                                        habitTotalCompletedSeconds += arrFilteredEveningHabits[j].durationSeconds!
                                    }
                                }
                            }
                            if i-1 >= 0{
                                UserDefaults.standard.set(arrFilteredEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                            }
                            
                            getHabitsVcObject().startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false, skippedActivities:skippedActivities, completedActivities:completedActivities)
                        }else{
                            var isLastActivitySkipped = false
                            if let lastActivityId = arrFilteredEveningHabits[i-1].id{
                                
                                if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                    isLastActivitySkipped = true
                                }
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    let habit = arrFilteredEveningHabits[j]
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                        //skiped
                                    }else{
                                        if habit.useTimer{
                                            if isHighPrioritySequenceGoing{
                                                if habit.isPriorityHigh{
                                                    habitTotalCompletedSeconds += habit.durationSeconds!
                                                }
                                            }else{
                                                habitTotalCompletedSeconds += habit.durationSeconds!
                                            }
                                            //completed
                                        }
                                    }
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrFilteredEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                }
                            }
                            getHabitsVcObject().startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: isLastActivitySkipped, skippedActivities:skippedActivities, completedActivities:completedActivities)
                        }
                    }
                    break;
                }
            }
            if !isActivityFound{
                addLog(text: "func showEveningHabit:- current activity id from actiity props not found in habit list.")
                //******************************************************************//
                //Doing this because if current habit id is not in selected habits list then we will found next habit to do according to selected list and if we can't find any current habit then show all habits
                var lastActivityFoundIndex = -1
                var isLastActivitySkipped = false
                for i in 0..<arrFilteredEveningHabits.count{
                    if completedActivities.contains(arrFilteredEveningHabits[i].id){
                        lastActivityFoundIndex = i+1// start next habit
                        if skippedActivities.contains(arrFilteredEveningHabits[i].id){
                            isLastActivitySkipped = true
                        }else{
                            isLastActivitySkipped = false
                        }
                    }
                }
                if lastActivityFoundIndex == -1{
                    getHabitsVcObject().showAllEveningHabits()
                }else{
                    getHabitsVcObject().startDirectIncompleteEveningHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped, skippedActivities:skippedActivities, completedActivities:completedActivities)
                }
                
                
                
            }
        }
        
    }
    var isNoHighPriorityActivityAlertVisible = false
    func processEveningHabit(){
        if isNoHighPriorityActivityAlertVisible{
            return;
        }
        arrFilteredEveningHabits.removeAll()
        let today = Date()
        let isCutOffTimeGoing = isCutOffTimeGoing()
        for habit in arrAllDaysEveningHabits{
            if isCutOffTimeGoing{
                if let cutOffTime = habit.cutOffTime{
                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                    let currentDate = Date()
                    if currentDate > cutOffDate{
                        addLog(text: "evening habit skipped:- running late cutoff time passed for this habit:- \(habit.name)  \(habit.id)") // remove this
                        continue;
                    }
                }
            }
            if RoutineHabitSchedule.shouldPlay(habitId: habit.id, daysOfWeek: habit.days_of_week, on: today) {
                arrFilteredEveningHabits.append(habit)
            }else{
                addLog(text: "evening habit skipped:- not scheduled for today or skipped ahead \(habit.days_of_week):- \(habit.name)  \(habit.id)") // remove this
            }
        }
        
        //--------------------------------------------------------------------//
        //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
        //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
        isActivitiesReducedInExpiredApp = false
        if isExpired{
            if arrFilteredEveningHabits.count > activitiesCountInExpireApp{
                isActivitiesReducedInExpiredApp = true
                let arrTempFilteredEveningHabits = arrFilteredEveningHabits
                arrFilteredEveningHabits.removeAll()
                
                for i in 0..<arrTempFilteredEveningHabits.count{
                    if arrTempFilteredEveningHabits[i].showSavedDistractingWebsites{
                        arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                    }
                }
                
                for i in 0..<activitiesCountInExpireApp{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                }
            }
        }
        //----------------------------------------------------------------------//
        if arrFilteredEveningHabits.count != 0{
            if cutOffTime != nil{
                
                if isCutOffTimeGoing{
                    
                    let tempHabits = arrFilteredEveningHabits
                    arrFilteredEveningHabits.removeAll()
                    for i in 0..<tempHabits.count{
                        if tempHabits[i].isPriorityHigh{
                            arrFilteredEveningHabits.append(tempHabits[i])
                        }else{
                            addLog(text: "evening habit skipped:- Global cutoffTime passed and this habit is not high priority habit:- \(tempHabits[i].name)  \(tempHabits[i].id)") // remove this
                        }
                    }
                    
                    if arrFilteredEveningHabits.count == 0{
                        abortAllProcess()
                        
                        addLog(text: "No activities with high Priority found:- showing ShutOff screen with no activities warning")// v 2.28.450
                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                        
                        let curreentDate = Date()
                        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                        }
                        
                        
                        if !(mainWindowControllerObj?.window!.isVisible)! {
                            mainWindowControllerObj?.showWindow(self)
                        }
                        showBlankWindowInSecondaryMonitor()
                        getHabitsVcObject().shutOffMac()
                        getHabitsVcObject().showAlertNoHighPriorityActivities()
                        return;
                    }
                    
                }
            }
        }
        
        
        if arrFilteredEveningHabits.count == 0{
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let curreentDate = Date()
            if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            }
            isHabitAlreadyShowed = false
            addLog(text: "evening habit already Done for today")
            if mainWindowControllerObj?.window?.isVisible ?? false{// close here at cut off time it will show automatically
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
                
                UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffCancelledForEveningRoutine)
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitSavedNotes)
                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastCustomRoutineHabitSavedNotes)
                leftMenuVcObj?.habitOver()
                currentHabitIndex = -1
            }
            return;
        }
        
        isHighPrioritySequenceGoing = false
        if !self.isProcessingHabitRoutine{
            self.isProcessingHabitRoutine = true
            var shutoffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            if Date().compare(shutoffDate) == .orderedAscending{//<  check for after 12 am
                shutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: shutoffDate) ?? shutoffDate
            }
            addLog(text: "get Last Activity Info process Evening Habit")
            if isMainWindowLoaded{// if main window is visible show loader
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    getHabitsVcObject().showLoaderView()
                }
            }
            allApiObject.getLastActivityInfo(completionHandler: { json in
                DispatchQueue.main.async {
                    
                    if isMainWindowLoaded{
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            getHabitsVcObject().removeSubViews()
                        }
                    }
                    getHabitsVcObject().hideLoaderView()
                    if json != nil{
                        
                        // check is there any change in settings
                        if let lastSettingsModifiedDateString = json?.value(forKey: "last_time_user_settings_modified") as? String{
                            if let lastSettingsModifiedDate = getDateFromStringInUtc(date: lastSettingsModifiedDateString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                if applastSettingsGetTime != nil{
                                    if lastSettingsModifiedDate.compare(applastSettingsGetTime!) == .orderedDescending{//if lastSettingsModifiedDate > applastSettingsGetTime
                                        settingsChangedDuringHabitsCurrentActivityProps()
                                        return;
                                    }
                                }
                            }
                        }
                        
                        // additional check that if user change pc and there is not locally save that evening routine is done today than  check is there morning routine done by user or not
                        if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                            if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                if let sequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
                                    if lastCompletedSequenceId == sequenceID{
                                        if let lastCompletedSequenceStartedAt = json?.value(forKey: "last_completed_sequence_started_at") as? String{
                                            if let activityStartDate = getDateFromStringInUtc(date: lastCompletedSequenceStartedAt, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                
                                                if activityStartDate.compare(shutoffDate) == .orderedDescending{//if activityAssignedDate > shutoffDate
                                                    // aaj hi hui hai/
                                                    
                                                    if startTime == nil || shutOffTime == nil{
                                                        isHabitAlreadyShowed = false
                                                        self.isProcessingHabitRoutine = false
                                                        return;
                                                    }
                                                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                                                    
                                                    let curreentDate = Date()
                                                    if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                                                        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                                                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                                    }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                                                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                                    }
                                                    isHabitAlreadyShowed = false
                                                    self.isProcessingHabitRoutine = false
                                                    if leftMenuVcObj?.boxHabits.isSelected ?? false{
                                                        leftMenuVcObj?.selectableListBoxDidChangeSelectionByUser(leftMenuVcObj!.boxHabits)// added 3.32.491
                                                    }
                                                    addLog(text: "evening habit already Done for today")
                                                    return
                                                }
                                                
                                            }
                                        }
                                        
                                        
                                    }
                                }
                            }
                        }
                        
                        if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                            captureDayPlanCompletedIds(todayRoutineProgress)
                            if let eveningRoutine = todayRoutineProgress.value(forKey: "evening_routine") as? NSDictionary,let sequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
                                if let todaySequenceId = eveningRoutine.value(forKey: "sequence_id") as? String, let status = eveningRoutine.value(forKey: "status") as? String{
                                    if todaySequenceId == sequenceID && status.lowercased() == "completed"{
                                        addLog(text: "evening habit already shown for today - reason (backend return status is completed)")
                                        
                                        if startTime == nil || shutOffTime == nil{
                                            isHabitAlreadyShowed = false
                                            self.isProcessingHabitRoutine = false
                                            return;
                                        }
                                        
                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                                        
                                        let curreentDate = Date()
                                        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                                            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                        }
                                        isHabitAlreadyShowed = false
                                        self.isProcessingHabitRoutine = false
                                        if leftMenuVcObj?.boxHabits.isSelected ?? false{
                                            leftMenuVcObj?.selectableListBoxDidChangeSelectionByUser(leftMenuVcObj!.boxHabits)// added 3.32.491
                                        }
                                        
                                        addLog(text: "evening habit already Done for today")
                                        return
                                    }
                                }
                            }
                        }
                        
                        if let todayRoutineProgress = json?.value(forKey: "today_routine_progress") as? NSDictionary{
                            captureDayPlanCompletedIds(todayRoutineProgress)
                            if let morningRoutine = todayRoutineProgress.value(forKey: "evening_routine") as? NSDictionary,let sequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
                                if let todaySequenceId = morningRoutine.value(forKey: "sequence_id") as? String, let status = morningRoutine.value(forKey: "status") as? String{
                                    let statusLowerCased = status.lowercased()
                                    if todaySequenceId == sequenceID && (statusLowerCased == "in_progress" || statusLowerCased == "postponed"){
                                        
                                        
                                        addLog(text: "evening habit sequnce is pending. start from current pending habit")// it was morning in logs til v 2.27.418
                                        self.isProcessingHabitRoutine = false
                                        var skippedActivities = [String]()
                                        if let activities = morningRoutine.value(forKey: "skipped_habit_ids") as? [String]{
                                            skippedActivities = activities
                                        }//current_sequence_completed_activities
                                        
                                        var completedActivities = [String]()
                                        if let activities = morningRoutine.value(forKey: "completed_habit_ids") as? [String]{
                                            completedActivities = activities
                                        }
                                        // need to calculate activityId here
                                        
                                        self.showEveningHabit(activityId: nil, skippedActivities: skippedActivities, completedActivities: completedActivities, needToCreateActivityId: true)
                                        return;
                                        
                                    }
                                }
                            }
                        }
                        
                        addLog(text: "start new evening routine sequence. evening habit sequnce is not pending.")
                        self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                        self.isProcessingHabitRoutine = false
                        
                        
                    }else{
                        addLog(text: "func processEveningHabit:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitsStartedDate) as? Date{
                            
                            addLog(text: "start new evening routine sequence:-LastHabitsStartedDate found")
                            if date.compare(shutoffDate) == .orderedDescending{//if
                                if let lastActivityId = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitID) as? String{
                                    for i in 0..<arrFilteredEveningHabits.count{
                                        if arrFilteredEveningHabits[i].id == lastActivityId{
                                            addLog(text: "start new evening routine sequence:- Last Habit id is from evening habit, show eveningHabit from last habit id found in userdefaults")
                                            self.isProcessingHabitRoutine = false
                                            self.showEveningHabit(activityId: arrFilteredEveningHabits[i+1].id, skippedActivities:[], completedActivities: [])
                                            return;
                                        }
                                    }
                                    
                                    addLog(text: "start new evening routine sequence:- Last Habit id is not from evening habit")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                    
                                }else{
                                    addLog(text: "start new evening routine sequence:- Last Habit id is nil")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                }
                            }else{
                                addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is not from current day")
                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                self.isProcessingHabitRoutine = false
                            }
                        }else{
                            addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is nil")
                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                            self.isProcessingHabitRoutine = false
                        }
                        
                    }
                }
            }
            )
        }
    }
    
    /// A cutoff time just ended the running evening habit — the automatic twin of the user pressing
    /// Skip, which calls this same lifecycle point (`skipHabitVc`). Without it an ALLOWED-ACTIVITY habit
    /// ended this way is still "holding the screen" as far as window routing knows, so the
    /// `showHabitsView()` that follows shrinks the window again and the rest of the routine runs
    /// windowed instead of in borderless full screen (2026-09-24 17:37: the "Life Admin" habit hit its
    /// cutoff, then `leaveFullScreen (routing … holding=true leftForHabit=true)` and nothing restored it).
    /// Must run before the window is re-routed. A no-op when the skipped habit was an ordinary one.
    private func releaseFullScreenAfterCutoffSkip() {
        applyFullScreen(forAllowedActivityHabit: false)
    }

    func abortAllProcess(){// do not change current state and current action inside this function
        addLog(text: "call abort all process.")
        // Only forget the step-aside when the routine is genuinely over. This function is NOT only
        // an abort: finishing a habit and starting the next one runs through it too (35 times in one
        // evening), and resetting there wiped the marker between a habit starting and ending — so
        // the routine never returned to full screen (report 2026-09-21_10-04-09, follow-up).
        if AllowedActivityFullScreen.shouldForgetStepAside(routineState: currentState) {
            allowedActivityFullScreenCoordinator.reset()
        }
        //        if (mainWindowControllerObj?.window!.isVisible)! {// jaruri ni h ki window dikh hi rhi ho
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._BREATHING_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        
                        //focusButtonService---//
                        focusButtonServiceObject.pauseHabit()
                        //--------------//
                        
                        enableSystemSleep()
                        if timerViewcontrollerObj?.isVideoLodded ?? false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                        
                        refreshFocusModeData()
                        isAnyAllowedFocusModeActivityRunning = false
                        isAllowedActivityHabitPlaying = false   // #2050: clear alongside the focus-mode flag so an aborted allowed-activity habit doesn't leave minimise in "background without postpone" mode
                        closePupUpBlockIfVisible()
                        
                        currentHabitPlaying = nil
                        habitBlockTimerHelper.stopUrlTimer()
                        timerAllowAppForActivity?.invalidate()
                        currentActivityPlaying = nil
                    
                        closeSmallCountDownTimerBoxIfVisible()
                        
                        if relaxModeWcObj != nil{
                            if relaxModeWcObj!.window?.isVisible ?? false{
                                getRelaxModeVcObject().closeTimerBox()
                            }
                        }
                    }
                    DispatchQueue.global().async {// did this beacuse some times action is in progress but timer is not initialized and it takes 1 second to initialize
                        DispatchQueue.main.async {
                            if timerViewcontrollerObj?.timer != nil {
                                timerViewcontrollerObj?.timer?.invalidate()
                                enableSystemSleep()
                                if timerViewcontrollerObj?.isVideoLodded ?? false{
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                                
                                refreshFocusModeData()
                                isAnyAllowedFocusModeActivityRunning = false
                                isAllowedActivityHabitPlaying = false   // #2050: clear alongside so an aborted allowed-activity habit doesn't leave minimise in "background without postpone" mode
                                currentHabitPlaying = nil
                                habitBlockTimerHelper.stopUrlTimer()
                                self.timerAllowAppForActivity?.invalidate()
                                currentActivityPlaying = nil
                                closePupUpBlockIfVisible()

                                closeSmallCountDownTimerBoxIfVisible()
                                
                                if relaxModeWcObj != nil{
                                    if relaxModeWcObj!.window?.isVisible ?? false{
                                        getRelaxModeVcObject().closeTimerBox()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //skipped activities will always there in completed activities
    @objc func startHabitsCall(activityId:String?, skippedActivities:[String], completedActivities:[String], needToCreateActivityId:Bool = false){
        // A custom routine owns the routine window while it runs. Starting morning habits here
        // calls abortAllProcess() below and tears it down — the user sees the custom routine they
        // just started exit straight back into the morning routine. See MorningRoutineStartGuard.
        guard MorningRoutineStartGuard.shouldStartMorningRoutine(currentState: currentState) else {
            addLog(text: "func startHabitsCall:- skipped, a custom routine is currently running.")
            return
        }
        addLog(text: "Initiating morning habits.")
        additionalHabitTotalCompletedSeconds = 0
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
        
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeEndDate)
        UserDefaults.standard.removeObject(forKey: kUserDefaultsLastRoutinePostponeState)
        
        checkTrialExpire()
        if isUserOnMeeting{
            addLog(text: "isUserOnMeeting True: Morning Habits skipped for some time.")
            return
        }
        if isHabitAlreadyShowed{
            return;
        }
        if arrFilteredMorningHabits.count != 0 {
            
            checkSystemTimeAndShowWindow()
            
            self.abortAllProcess()
            
            //** code added on 26/4/25 // need to do this because now code has been updated according to "today_routine_progress". in witch we are not getting "current_activity" so need to calculate "current_activity "**//  in version 1.22.362
            var activityId = activityId
            if activityId == nil && needToCreateActivityId{
                if skippedActivities.count != 0 || completedActivities.count != 0{
                    
                    var isActivityFound = false
                    for i in 0..<arrFilteredMorningHabits.count{
                        if !completedActivities.contains(arrFilteredMorningHabits[i].id){
                            activityId = arrFilteredMorningHabits[i].id
                            isActivityFound = true
                        }
                        if isActivityFound{
                            break;
                        }
                    }
                }
            }
            //------------------------------------//
            
            
            if activityId == nil{
                arrPreFilteredMorningHabits = arrFilteredMorningHabits
                //  //Let user temporarily customise routine before starting#938
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                
                if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                    if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                        if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && date.compare(startDate) == .orderedDescending{
                            if arrHabitIds.count != 0{
                                arrFilteredMorningHabits.removeAll()
                                
                                for habit in arrPreFilteredMorningHabits{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                if arrFilteredMorningHabits.count == 0{
                                    arrFilteredMorningHabits = arrPreFilteredMorningHabits
                                }
                            }else{
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                            }
                        }
                    }
                }
                //
                
                //focusButtonService-------//
                focusButtonServiceObject.sendMorningHabitsToFocusDevice()
                //---------//
                
                
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                getHabitsVcObject().showAllMorningHabits()
            }else{
                let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                arrFilteredMorningHabits.removeAll()
                
                var isActivityFound = false
                for i in 0..<arrTempFilteredMorningHabits.count{
                    
                    if arrTempFilteredMorningHabits[i].id == activityId!{
                        arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                        isActivityFound = true
                    }else if isActivityFound{
                        if !completedActivities.contains(arrTempFilteredMorningHabits[i].id){
                            arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                        }else{
                            if !skippedActivities.contains(arrTempFilteredMorningHabits[i].id){
                                if arrTempFilteredMorningHabits[i].useTimer{
                                    additionalHabitTotalCompletedSeconds += arrTempFilteredMorningHabits[i].durationSeconds
                                }
                            }
                        }
                    }else{
                        arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                    }
                    
                }
                
                arrPreFilteredMorningHabits = arrFilteredMorningHabits
                //  //Let user temporarily customise routine before starting#938
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                    if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                        if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && date.compare(startDate) == .orderedDescending{
                            if arrHabitIds.count != 0{
                                arrFilteredMorningHabits.removeAll()
                                var isActivityFound = false
                                for habit in arrPreFilteredMorningHabits{
                                    if habit.id == activityId!{
                                        if arrHabitIds.contains(habit.id){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                        isActivityFound = true
                                    }else if isActivityFound{
                                        if arrHabitIds.contains(habit.id){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                    }else{
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                if arrFilteredMorningHabits.count == 0{
                                    arrFilteredMorningHabits = arrPreFilteredMorningHabits
                                }
                            }else{
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                            }
                        }
                    }
                }
                //
                //focusButtonService-------//
                focusButtonServiceObject.sendMorningHabitsToFocusDevice()
                //---------//
                
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                isActivityFound = false
                for i in 0..<arrFilteredMorningHabits.count{
                    if arrFilteredMorningHabits[i].id == activityId!{
                        isActivityFound = true
                        if i == 0{
                            getHabitsVcObject().startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                        }else {
                            if skippedActivities.count == 0{
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    if arrFilteredMorningHabits[j].useTimer{
                                        habitTotalCompletedSeconds += arrFilteredMorningHabits[j].durationSeconds!
                                    }
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrFilteredMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                }
                                
                                
                                getHabitsVcObject().startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                            }else{
                                var isLastActivitySkipped = false
                                if let lastActivityId = arrFilteredMorningHabits[i-1].id{
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                        isLastActivitySkipped = true
                                    }
                                    habitTotalCompletedSeconds = 0
                                    for j in 0..<i{
                                        let habit = arrFilteredMorningHabits[j]
                                        if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                            //skiped
                                        }else{
                                            if habit.useTimer{
                                                habitTotalCompletedSeconds += habit.durationSeconds!
                                            }
                                            //completed
                                        }
                                        
                                    }
                                    if i-1 >= 0{
                                        UserDefaults.standard.set(arrFilteredMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                    }
                                    
                                }
                                
                                
                                getHabitsVcObject().startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:isLastActivitySkipped)
                                
                            }
                            
                        }
                        break;
                    }
                }
                if !isActivityFound{
                    addLog(text: "func startHabitsCall:- current activity id from actiity props not found in habit list.")
                    
                    //******************************************************************//
                    //Doing this because if current habit id is not in selected habits list then we will found next habit to do according to selected list and if we can't find any current habit then show all habits
                    var lastActivityFoundIndex = -1
                    var isLastActivitySkipped = false
                    for i in 0..<arrFilteredMorningHabits.count{
                        if completedActivities.contains(arrFilteredMorningHabits[i].id){
                            lastActivityFoundIndex = i+1// start next habit
                            if skippedActivities.contains(arrFilteredMorningHabits[i].id){
                                isLastActivitySkipped = true
                            }else{
                                isLastActivitySkipped = false
                            }
                        }
                    }
                    if lastActivityFoundIndex == -1{
                        getHabitsVcObject().showAllMorningHabits()
                    }else{
                        getHabitsVcObject().startDirectIncompleteMorningHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped)
                    }
                    
                }
                
            }
        }
    }
    
    func checkSystemTimeAndShowWindow(){
        addLog(text: "func checkSystemTimeAndShowWindow")
        if let now = client.referenceTime?.now(){
            //                print(now)
            let currentDate = Date()
            let diffHours = Calendar.current.dateComponents([.hour], from: now, to: currentDate).hour ?? 0
            if diffHours > 24 || diffHours < -24{
                let nowString = getStringFromDate(date: now, dateFormat: "yyyy-MM-dd HH:mm:ss")
                let currentDateString = getStringFromDate(date: currentDate, dateFormat: "yyyy-MM-dd HH:mm:ss")
                
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                }
                var timeIncorrectText = "Your system time seems to be incorrect - it's saying the current time is <SYSTEM_TIME> but the actual time is <TRUE_TIME>. Focus Bear won't work properly if you don't have your system time configured correctly. Once you have adjusted the time settings, click \"I am ready to start my habits\" button below."
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    timeIncorrectText = common.value(forKey: "timeIncorrectText") as? String ?? timeIncorrectText
                }
                
                timeIncorrectText = timeIncorrectText.replacingOccurrences(of: "<SYSTEM_TIME>", with: currentDateString)
                timeIncorrectText = timeIncorrectText.replacingOccurrences(of: "<TRUE_TIME>", with: nowString)
                addLog(text: "checkSystemTimeAndShowWindow:- time is not correct:- show window")
                getIncorrectTimeVcObject().loadView()
                getIncorrectTimeVcObject().lblTitle.stringValue = timeIncorrectText
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.runModal(for: getIncorrectTimeWindowObject().window!)
                
            }
        }
    }
    func checkTrialExpire(){
        if isPurchased == true{
            return;
        }
        if isExpired{
            return;
        }
        addLog(text: "checkTrialExpire")
        
        if isPurchased == false && daysLeft <= 0{//
            quitAndRestartApp()
        }
    }
    @objc func menuItem_Preferences() {
        if !(mainWindowControllerObj?.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(self)
        }
        leftMenuVcObj?.showSettingsView()

        addLog(text: "Showing preferences")
        NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
        // Full-screen (borderless kiosk) mode is a lock — opening Settings must NOT break out of it and
        // expose other apps. Re-assert the full-screen window + bring it to front so Settings shows inside
        // the lock. checkIsFullScreenNeeded keeps full-screen when the setting is on (no-op otherwise).
        if checkIsFullScreenEnabled() {
            mainViewControllerObj?.checkIsFullScreenNeeded()
            mainWindowControllerObj?.window?.makeKeyAndOrderFront(self)
        }
    }
    
    
    @objc func menuItem_Quit() {
        addLog(text: "App quit clicked by user")
        //        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        stopMainAppForceQuitMonitoring()
        terminateFromSelf = true
        quitApplicationSmoothly()
    }
    
    @objc func quitAppForUser(){
        sharedDefaults?.setValue(Date(), forKeyPath: kUserdefaultsAppQuitForUser)
        sharedDefaults?.synchronize()
        
        let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
        DistributedNotificationCenter.default().post(name: mainAppQuitByUser,object: mainAppBundelId)
        menuItem_Quit()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        ManagedBlockingRuntime.shared.stop()
        // Insert code here to tear down your application
        addLog(text: "Application Will Terminate")
        UserDefaults.standard.set(true, forKey: kUserdefaultsAppQuitProperly)
        print("applicationWillTerminate")
        TalkingClockManager.shared.stop()
        teacherSessionManagerObject.sendFinalHeartbeatBeforeTerminate()// best-effort {in_focus:false} beat, server also infers quit from the heartbeat gap
        flaskServerObject.stopFlaskServer()
        firefoxServer.stop()
        EventBuffer.shared.flushEvents()
        focusButtonServiceObject.stop()
        
        closeAllCsvFiles()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        addLog(text: "application Should Terminate")
        print("applicationShouldTerminate")
        if terminateFromSelf {
            terminateFromSelf = false
            return .terminateNow
        }else {
            if ManagedBlockingRuntime.shared.isSettingsLocked {
                _ = ManagedBlockingRuntime.shared.allowLegacySettingsMutation()
                return .terminateCancel
            }
            // Teacher session:- block user-initiated quit (Cmd+Q / dock / menu) so a student can't
            // quit the app to escape a class focus session. Show the teacher-locked alert (with Request
            // unlock) instead. Placed before the quit flow below so it also covers the case where the
            // main window is visible (which otherwise routes to abortCurrentState, not showQuitWindow).
            if teacherSessionManagerObject.isTeacherSessionActive(){
                addLog(text: "[user-action] quit blocked during teacher session — showing locked alert")
                teacherSessionManagerObject.showTeacherSessionLockedAlert()
                return .terminateCancel
            }
            if currentState == ._ONBOARDING_{
                
                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        sharedDefaults?.removeObject(forKey: kUserdefaultsSharedAccessToken)
                        sharedDefaults?.setValue(globalUUID, forKeyPath: kUserdefaultsSharedUserId)
                        sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsOnboardingIncompleted)
                        sharedDefaults?.setValue(Date(), forKeyPath: kUserdefaultsAppQuitForUser)
                        sharedDefaults?.synchronize()
                        
                        let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
                        DistributedNotificationCenter.default().post(name: mainAppQuitByUser,object: mainAppBundelId)
                    }
                }
                return .terminateNow// quit without login check here
            }
            if self.user == nil{
                return .terminateNow
            }
            addLog(text: "[user-action] menu item Quit clicked from dock or activity monitor")
            if quittingWcObj != nil{
                if quittingWcObj?.window?.isVisible ?? false{
                    addLog(text: "Quit window already visible")
                    return .terminateCancel
                }
            }
            
            if mainWindowControllerObj?.window?.isVisible ?? false{
                getHabitsVcObject().abortCurrentState()
            }else{
                showQuitWindow()
            }
            
            return .terminateCancel
        }
    }
    
    /// The Dock-icon path. Clicking the Dock icon and ⌘-Tabbing are the same request — "show me Focus
    /// Bear" — so both go through `restoreMainWindowOnActivationIfNeeded()` first. Popping the menu-bar
    /// menu, which is all a Dock click used to do, stays as the fallback for the states where the main
    /// window is deliberately absent (a running routine, onboarding).
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        print("applicationShouldHandleReopen")

        if blankLayerWcObj != nil{
            if blankLayerWcObj?.window != nil{
                if blankLayerWcObj!.window!.isVisible{
                    return false
                }
            }
        }
        if restoreMainWindowOnActivationIfNeeded(){
            return true
        }
        var isAnyStanderdWindowVisible = false
        
        for win in NSApp.windows{
            if win.isVisible && win.hasTitleBar{
                isAnyStanderdWindowVisible = true
            }
        }
        
        if !isFocusBearMenuVisible() && !isAnyStanderdWindowVisible{
            //            if !isCustomBarIsInFocus{
            statusbutton?.performClick(self)
            //            }
        }else{
            if floatingTopBarVcObj != nil && !isFocusBearMenuVisible(){
                floatingTopBarVcObj?.boxMain.isHidden = false
                floatingTopBarVcObj?.boxMoreItems.isHidden = false
            }
        }
        return true
    }
    
    // did this because we user closes last window than app should  deactivate beacuse we need to show popover if user clicks on dock icon and if app is allready active we cant get actual state of dock icon click that's why we are doing this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed")
        addLog(text: "applicationShouldTerminateAfterLastWindowClosed")
        if SettingsManagerObject.isMenuPopoverEnabled{
            if popover.isShown{
                return false
            }
        }else{
            if getMenuWindowObject().window?.isVisible ?? false{
                return false
            }
        }
        
        if nudgeFocusAlignmentScoreDippingWcObject != nil{
            if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
                return false
            }
        }
        
        for window in NSApp.windows{// sometimes nsalert visible but app
            if window.isModalPanel{
                return false
            }
        }
        if NSApp.isActive{
            addLog(text: "hide app")
            NSApp.hide(self)
        }
        return false
    }
    
    // didnot do this work in applicationShouldHandleReopen because applicationShouldHandleReopen calls again and aain if reload after force quit setting is enabled
    /// ⌘-Tab cannot be detected as a keystroke — the system app switcher consumes it and never delivers
    /// it to the app — but the activation it causes lands here, on every single switch-to. This used to
    /// log and stop, so ⌘-Tabbing back to Focus Bear with its window closed showed nothing at all
    /// (report 2026-09-16_16-01-15). The decision is scheduled rather than taken here — at this instant a
    /// menu-bar click's popover is opening but not yet open, and a self-activation has not necessarily
    /// declared itself yet; see `scheduleMainWindowRestoreAfterActivation()`.
    func applicationDidBecomeActive(_ notification: Notification) {

        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
        addLog(text: "applicationDidBecomeActive")
        print("applicationDidBecomeActive")
        scheduleMainWindowRestoreAfterActivation()
    }

    func applicationDidResignActive(_ notification: Notification) {
        print("applicationDidResignActive")
        addLog(text: "applicationDidResignActive")
        cancelScheduledMainWindowRestore()
        
        makeAllAlertWindowToTopLevelWindow()
        
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                if !SettingsManagerObject.isFullScreenEnabled{
                    setTimerMoveWindowToCenter()
                }
            }
        }
        //Improve experience after they get logged out #1235   15/3/25
        if askLogInWcObj != nil{
            if askLogInWcObj?.window?.isVisible ?? false{
                setTimerMoveWindowToCenter()
            }
        }
        
        //Set the onboarding permissions window to maintain focus when users request browser, accessibility, or system permissions. Currently, the window level resets to normal during these prompts, which may cause users to forget they were in the onboarding process. This adjustment will ensure better user awareness and completion of the setup.// added on 23/7/25 version 1.26.393
        
        if permissionBlockDistractionWcObj != nil{
            if permissionBlockDistractionWcObj?.window?.isVisible ?? false{
                setTimerMoveWindowToCenter()
            }
        }
        
        
    }
    
    var timerMoveWindowToCenter:Timer?
    
    func setTimerMoveWindowToCenter(){
        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
        self.timerMoveWindowToCenter = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(self.moveWindowToCenter), userInfo: nil, repeats: false)
    }
    
    
    @objc func moveWindowToCenter() {
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._CUSTOM_ROUTINE_{
            if !SettingsManagerObject.isFullScreenEnabled{
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    // #2091: same center()+activate as before, but also records that a re-centre has
                    // happened this session — so a subsequent user drag asks to postpone (see
                    // scheduleDragAwayCheck) instead of silently re-centring again.
                    mainWindowControllerObj?.recenterRoutineWindowForAwayTimer()
                }
            }
        }
        
        if askLogInWcObj != nil{
            if askLogInWcObj?.window?.isVisible ?? false{
                askLogInWcObj?.window?.center()
                //                NSApp.activate(ignoringOtherApps: true)
                NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            }
        }
        
        
        if self.timerMoveWindowToCenter != nil{
            self.timerMoveWindowToCenter?.invalidate()
            self.timerMoveWindowToCenter = nil
        }
        
        if permissionBlockDistractionWcObj != nil{
            if permissionBlockDistractionWcObj?.window?.isVisible ?? false{
                //                NSApp.activate(ignoringOtherApps: true)
                permissionBlockDistractionWcObj?.window?.center()
                NSRunningApplication.current.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }
    
    func makeAllAlertWindowToTopLevelWindow(){
        for window in NSApp.windows{
            if window.isModalPanel{
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
            }
        }
    }
    
    @objc func showAlertOnboardingVideo(){
        let alert = NSAlert()
        alert.setSharingType()
        var messageText = "You'll be able to use the Focus Bear menu as soon as you have finished watching the onboarding video."
        addLog(text: "show Alert Onboarding Video")
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            messageText = common.value(forKey: "alertOnboardingVideoText") as? String ?? messageText
        }
        alert.messageText = messageText
        alert.addButton(withTitle: buttonOkText)
        alert.runModal()
    }
    
    
    func setFocusModeTimer(hour:Int?, minute:Int?){
        addLog(text: "setFocusModeTimer")
        DispatchQueue.global().sync {
            focusModeMinutesToPerform = minute ?? 0
            
            //hour ni aayga kabhi . minut hi beje hai
            
            if timerForFocusMode != nil{
                timerForFocusMode?.invalidate()
                
            }
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
            var time = 0
            if hour != nil{
                time = hour!*60*60
            }else if minute != nil{
                time = minute!*60
            }else{
                time = 60*60
            }
            
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = time
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(time), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
        }
    }
    
    /// Start a focus session directly from the menu-bar overlay with a chosen block list (focus
    /// mode), duration and intention — no config window. Mirrors the tail of the simple-pomodoro
    /// start so blocking (`workBeforeFocusBegin`), DND, the timers, the Focus Button and
    /// `focusModeStartted` all engage exactly as they do from the pomodoro flow.
    /// - Parameter isAutoStarted: the app started this session, not the user — a meeting detected on
    ///   the calendar, or an approved postpone. Those are the sessions that get dismissed seconds
    ///   later, so their Do Not Disturb request is given longer to settle before it costs a click.
    @objc func startFocusFromMenu(focusModeId: String, minutes: Int, intention: String,
                                  isAutoStarted: Bool = false, initialTaskQueue: String? = nil) {
        let minute = max(1, minutes)
        endFocusModeTime = Calendar.current.date(byAdding: .minute, value: minute, to: Date())

        minFocusAlignmentScoreToShowDistractingPopUp = 99.9
        if SettingsManagerObject.isDataCollectionModeEnabled {
            minFocusAlignmentScoreToShowDistractingPopUp = 0
        }

        // The focus modes may not be loaded into the global yet (the pomodoro screen normally does it),
        // so hydrate from UserDefaults first — otherwise the menu could start nothing.
        if arrFocusType.isEmpty, let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String:Any]] {
            arrFocusType = arr
        }
        // Resolve which block list / focus mode to run: the chosen id, else the default one, else the
        // deep-work one, else the first available. This mirrors how the pomodoro flow picks a default.
        var startedIndex = arrFocusType.firstIndex { ($0["id"] as? String ?? "") == focusModeId }
        if startedIndex == nil { startedIndex = arrFocusType.firstIndex { ($0["isDefault"] as? Bool) == true } }
        if startedIndex == nil { startedIndex = arrFocusType.firstIndex { ($0["isDeepWorkFocus"] as? Bool) == true } }
        if startedIndex == nil, !arrFocusType.isEmpty { startedIndex = 0 }
        guard let i = startedIndex else {
            addLog(text: "startFocusFromMenu: no focus modes available; aborting")
            return
        }
        arrFocusType[i]["isOn"] = true
        arrFocusType[i]["lastStartedDate"] = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        if let end = endFocusModeTime {
            arrFocusType[i]["lastScheduledEndDate"] = getStringFromDate(date: end, dateFormat: "yyyy-MM-dd HH:mm:ss")
        }
        arrFocusType[i]["lastIntentionUsed"] = intention
        // #777: remember the chosen duration per focus mode, so each mode defaults to its own last
        // duration next time (persisted with arrFocusType below and synced via updateAllFocusModes).
        arrFocusType[i]["lastDurationUsed"] = minute
        if isAccessibilityEnabled(isPrompt: true) {
            DNDManager.shared.setDND(true, settle: isAutoStarted ? .autoStartedSession : .standard)
        }
        workBeforeFocusBegin(index: i)
        setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[i]["color"] as? String ?? "")
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        updateAllFocusModes()

        isFocusModeRunning = true
        setStatusBarButtonTitleForFocusMode(title: intention)
        statusbutton?.imagePosition = .imageLeft

        timerForFocusMode?.invalidate(); timerForFocusMode = nil
        timerForFocusModeEndNotification?.invalidate(); timerForFocusModeEndNotification = nil

        setFocusModeTimer(hour: nil, minute: minute)
        focusButtonServiceObject.startFocusSession(seconds: minute * 60)

        isFocusModeStartedFromPomodoroMode = true
        isSkipBreakActivityDuringPomodoro = true
        whatToAchieveInFocusBlock = intention
        // A new session starts only with tasks explicitly selected for it. `lastTaskUsed` is a
        // persistence snapshot for resuming a session, not a reusable queue for unrelated work.
        focusModeTaskString = initialTaskQueue ?? "[]"
        arrFocusType[i]["lastTaskUsed"] = focusModeTaskString
        updateAllFocusModes()
        focusModeStartted(isStartedByPusher: false)

        // Remember this duration so the menu defaults to it next time.
        UserDefaults.standard.set(minute, forKey: kUserdefaultsLastFocusModeMinutes)
        // #777: a focus mode started from the menu becomes the pomodoro screen's last-used mode too, so
        // opening pomodoro pre-selects it. kUserdefaultsLastPomodoroFocusModeId is the pomodoro-specific
        // "last mode" (not clobbered by scheduled blocking, unlike kUserdefaultsLastFocusModeId).
        UserDefaults.standard.set(arrFocusType[i]["id"] as? String ?? "", forKey: kUserdefaultsLastPomodoroFocusModeId)

        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled {
            // #2163: starting a focus session straight from the menu overlay on a fresh launch (main
            // window never opened) showed a BLANK Todo Player — the webview had never loaded its URL,
            // and this path only showed the window without loading it. Load the view (guarded so we
            // don't rebuild an already-loaded webview) and its request, and flag a reload so reloadData
            // injects the token/duration once shown — mirroring the resume and pusher-event paths.
            if !getTaskPlayerVcObject().isViewLoaded {
                getTaskPlayerVcObject().loadView()
            }
            getTaskPlayerVcObject().loadRequest()
            shouldReloadTaskPlayer = true
            showRunningFocusSessionWindow()
        }
    }

    func setFocusModeTimerForExtendAfterComplete(hour:Int?, minute:Int?){
        addLog(text: "setFocusModeTimer")
        // The blocking context in force before the extension is re-applied below, after this method
        // re-reads `currentRunningFocusType` out of `arrFocusType` — otherwise a stale copy of the
        // block list could quietly change whether AI relevance checking applies to the extra minutes.
        let blockingContextBeforeExtension = FocusSessionExtension.captureBlockingContext()
        DispatchQueue.global().sync {
            focusModeMinutesToPerform += minute ?? 0
            
            //hour ni aayga kabhi . minut hi beje hai
            
            if timerForFocusMode != nil{
                timerForFocusMode?.invalidate()
                
            }
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
            var time = 0
            if hour != nil{
                time = hour!*60*60
            }else if minute != nil{
                time = minute!*60
            }else{
                time = 60*60
            }
            
            //focusButtonService
            focusButtonServiceObject.updateFocusDuration(seconds: time)
            //------------
            
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = time
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(time), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > warningShowSecondsBeforeFocusModeEndTime{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - warningShowSecondsBeforeFocusModeEndTime), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
            
            DispatchQueue.main.async {
                playFocusModeStartedSound()
                closeSmallCountDownTimerBoxIfVisible()
                
                if addFocusTempUrlsOrAppsWcObj != nil{
                    if addFocusTempUrlsOrAppsWcObj?.window?.isVisible ?? false{
                        addFocusTempUrlsOrAppsWcObj?.window?.close()
                    }
                }
                
                
                
                var stringTime = ""
                
                if let date = endFocusModeTime{
                    stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
                }
                
                for dic in arrFocusType{
                    if dic["isOn"] as? Bool == true{
                        currentRunningFocusType = FocusSessionExtension.focusModePreservingAI(
                            dic, before: blockingContextBeforeExtension)
                        let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                        addLog(text: "\(currentRunningFocusModeName) extended until - \(stringTime)")
                    }
                }
                isFocusModeRunning = true
                FocusSessionExtension.reapplyBlockingContext(blockingContextBeforeExtension)
                if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
                    if  isRelaxFocus{
                        showSavedSitesForLaterWindowForBreaks()
                    }
                }
                
                self.frontApplicationChanged()
                
                DispatchQueue.global().sync {
                    self.timerCheckAllowedApps?.invalidate()
                    self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
                    RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
                }
                menuViewControllerObj?.showFocusModeCountDownIfNeeded()
                
                
                menuViewControllerObj?.reloadIfNeeded()
            }
            
        }
    }
    
    
    
    
    @objc func showFocusModeFinishNotification(){
        addLog(text: "func showFocusModeEndWarningWindow")
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        // A teacher-controlled class session ends on its own (class-session-ended / scheduled finish
        // time) and the student can't extend or act on the end warning, so don't show it.
        if teacherSessionManagerObject.isTeacherSessionActive(){
            addLog(text: "showFocusModeFinishNotification: skipped — teacher session active")
            return;
        }
        if isFocusModeOn(){
            // Previously, being on a meeting silently auto-extended the session by 5 minutes and
            // re-armed this warning timer, so the countdown visibly jumped up (e.g. 2 min -> 5 min)
            // and looped for the whole call with no way to opt out (#2207). Instead, show the same
            // end-warning window as any other session — it already offers an extend-by-N-minutes
            // picker and an "I'm done, End focus session" button — so the user stays in control.
            if breakWarningWcObj != nil{
                if breakWarningWcObj?.window?.isVisible ?? false{
                    addLog(text: "func showFocusModeEndWarningWindow: return reason breakWarning window is visible")
                    return;
                }
            }
            showFocusEndWarningWindow()
        }
    }
    
    
    @objc func focusModeTimerFinished(){
        tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:true, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
    }
    
    
    
    @objc func tryFocusModeFinished(isSilent:Bool, isShutOffTime:Bool, isMorningRoutineTime:Bool, allowExtend:Bool, isCustomRoutineTime:Bool, shouldUpdateFocusButton:Bool = false){
        if teacherSessionManagerObject.isTeacherSessionActive(){// teacher controlled class session:- only legit ends are class-session-ended or scheduled_finish_time
            if teacherSessionManagerObject.canTeacherSessionFinishNow(){
                teacherSessionManagerObject.teacherSessionFinished(reason: "scheduled finish time reached")
            }else{
                addLog(text: "focus mode finish blocked:- teacher session is active")
                teacherSessionManagerObject.showTeacherSessionLockedAlert()
            }
            return;
        }
        addLog(text: "focus mode finished")
        taskPlayerVcObj?.getToDosFromPlayer()
        
        
        setAppIconForFocusModeScore(probability: nil)
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0
        
        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        if focusEndWarningWcObj != nil{
            if focusEndWarningWcObj?.window?.isVisible ?? false{
                focusEndWarningWcObj?.window?.close()
            }
        }
        if savedSitesForLaterWcObj != nil{
            if savedSitesForLaterWcObj!.window?.isVisible ?? false{
                savedSitesForLaterWcObj!.close()
            }
        }
        // Ending the focus session must always dismiss the block overlays. They were previously only
        // closed inside specific browser/URL branches later in this function, so stopping while the
        // "set intention" (blocked-URL) window was up left it stranded on screen — and since the focus
        // timer that watches for tab/window changes is invalidated above, nothing would close it
        // afterwards either (it kept showing even when the user switched tab/window). Close both
        // block windows unconditionally here.
        closeSetIntentionBlockedUrlsWinddowIfVisible()
        closeIntentionBlockedUrlsWinddowIfVisible()
        if isFocusModeOn(){// is paused then already calculated
            let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
            focusModeActualDurationPerformed += totalSeconds
        }
        // Hard safety cap for meeting sessions: a meeting focus block can never record more than the
        // meeting's expected length plus a short grace. Belt-and-suspenders against any path (a missed
        // auto-end, a clock jump, wake after an overnight sleep) inflating a meeting to many hours — the
        // way a stale start time once logged a ~10-minute meeting as 13–15h. Read the cap here, before
        // currentAccountabilityBuddySession is cleared below.
        if let meetingSession = currentAccountabilityBuddySession, meetingSession.isMeeting {
            let maxMeetingSeconds = meetingSession.durationMinutes * 60 + Int(meetingSessionAutoEndGraceSeconds) + 300
            if focusModeActualDurationPerformed > maxMeetingSeconds {
                addLog(text: "meeting focus block duration \(focusModeActualDurationPerformed)s exceeds cap \(maxMeetingSeconds)s — clamping")
                focusModeActualDurationPerformed = maxMeetingSeconds
            }
        }
        focusModeFinishedCapturePosthog()
        
        var currentFocusModeName = ""
        var currentFocusModeId = ""
        // Clear EVERY running/paused mode, not just the first: if two entries were ever `isOn`
        // simultaneously, stopping after the first left one on, so the menu stayed on "Stop Focus
        // Session" and a new session couldn't start. The per-mode cleanup (DND, workAfterFocusBegin)
        // still runs once, for the first — matching the previous single-session behaviour.
        var didHandleFirstRunningMode = false
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                arrFocusType[i]["isPaused"] = false
                if !didHandleFirstRunningMode{
                    didHandleFirstRunningMode = true
                    currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
                    currentFocusModeId = arrFocusType[i]["id"] as? String ?? ""

                    // A session that ends into the "extend?" screen has not really ended yet: the
                    // user can put it straight back. Releasing DND on that edge and re-taking it
                    // seconds later cost two synthetic menu-bar clicks for one continuous session,
                    // so the release settles for long enough that an extension collapses it away.
                    if DNDManager.shared.isDndEnabled{
                        DNDManager.shared.setDND(false, settle: allowExtend ? .sessionMayBeExtended : .standard)
                    }
                    workAfterFocusBegin(index: i)
                }
            }
        }
        
        isFocusModeRunning = false
        // Preserve the buddy session across the completed screen so its "Extend Session" button can
        // re-activate the AI accountability buddy (same goal + allow-list + strict AI). Only when an
        // extend is actually offered; otherwise the buddy is genuinely over. A non-buddy finish sets
        // this to nil (currentAccountabilityBuddySession is nil), so no stale buddy leaks into a later
        // normal extend.
        lastCompletedAccountabilityBuddySession = allowExtend ? currentAccountabilityBuddySession : nil
        currentAccountabilityBuddySession = nil   // end the accountability-buddy allow-list with the session
        clearPersistedAccountabilityBuddySession()   // don't restore it on the next launch
        // NOTE: isFocusSessionAutoStarted is deliberately NOT reset here. The backend can still report
        // this session as running (its finish PATCH may not have landed before the app was killed), and
        // checkIsAnyOldFoucsModeRemaining would then resurrect it on the next launch — which must come
        // back stoppable, not as a locked super-strict session. The marker is overwritten by the next
        // start instead, in focusModeStartted(); see FocusSessionStopPermission.swift.

        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
            
            self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString:nil)
            self.statusbutton?.title = ""
        }
        focusModeHelper.stopUrlTimer()
        
        timerCheckAllowedApps?.invalidate()
        menuViewControllerObj?.stopFocusModeCountDownTimer()
        DispatchQueue.main.async {
            
            arrKeywordsToAllowInFocus.removeAll()
            
            if !self.isAutoMeetingsModeStarted && !isSilent{
                allApiObject.getKeyWords(completionHandler: {dic  in
                    
                })
            }
            
        }
        //focusButtonService
        if shouldUpdateFocusButton{
            focusButtonServiceObject.finishFocusSession()
        }
        
        if self.isAutoMeetingsModeStarted{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "Meeting using {\(self.appUsedInAutoMeetingFocusMode)}", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            
            allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), rating:nil, completionHandler: {newDic in
                DispatchQueue.main.async {
                    
                }
            })
            focusModeFinishedResetAllData()
        }else{
            if isSilent{
                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
                
                allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), rating:nil, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
                focusModeFinishedResetAllData()
            }else if isShutOffTime{
                lastFocusModeTempInfo = nil
                
                DispatchQueue.main.async {
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
                    if !(focusCompletedFullScreenVcObj?.isViewLoaded ?? false){
                        // Force-load via .view, not loadView() directly. Calling loadView() on a storyboard
                        // VC re-enters nib loading and can raise nibForStoryboardNibNamed → SIGABRT on first
                        // completion (#1948). Accessing .view runs loadView()+viewDidLoad once, in the
                        // supported order (still before resetData, so behaviour is unchanged).
                        _ = focusCompletedFullScreenVcObj?.view
                    }
                    focusCompletedFullScreenVcObj?.allowExtend = allowExtend
                    
                    getHabitsVcObject().showDayEndFocusCompletedView()
                    focusCompletedFullScreenVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: isShutOffTime)
                }
            }else if isMorningRoutineTime || isCustomRoutineTime{
                lastFocusModeTempInfo = nil
                
                DispatchQueue.main.async {
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
                    if !(focusCompletedFullScreenVcObj?.isViewLoaded ?? false){
                        // Force-load via .view, not loadView() directly. Calling loadView() on a storyboard
                        // VC re-enters nib loading and can raise nibForStoryboardNibNamed → SIGABRT on first
                        // completion (#1948). Accessing .view runs loadView()+viewDidLoad once, in the
                        // supported order (still before resetData, so behaviour is unchanged).
                        _ = focusCompletedFullScreenVcObj?.view
                    }
                    focusCompletedFullScreenVcObj?.allowExtend = allowExtend
                    
                    if isMorningRoutineTime{
                        getHabitsVcObject().showMorningRoutineFocusCompletedView()
                    }else{
                        getHabitsVcObject().showCustomRoutineFocusCompletedView()
                    }
                    focusCompletedFullScreenVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: isShutOffTime)
                }
            }else{
                if arrAllowedAppsInCuddlyModeCurrentFocus.count != 0 || arrAllowedUrlsInCuddlyModeCurrentFocus.count != 0{
                    lastFocusModeTempInfo = lastFocusTempInfo(id: currentFocusModeId, arrAllowedAppsInCuddlyModeCurrentFocus: arrAllowedAppsInCuddlyModeCurrentFocus, arrAllowedUrlsInCuddlyModeCurrentFocus: arrAllowedUrlsInCuddlyModeCurrentFocus)
                }else{
                    lastFocusModeTempInfo = nil
                }
                
                DispatchQueue.main.async {
                    if !(focusCompletedVcObj?.isViewLoaded ?? false){
                        // Force-load via .view, not loadView() directly (see #1948): loadView() on a
                        // storyboard VC can raise nibForStoryboardNibNamed → SIGABRT. .view loads once.
                        _ = focusCompletedVcObj?.view
                    }
                    focusCompletedVcObj?.allowExtend = allowExtend
                    focusCompletedVcObj?.currentFocusModeId = currentFocusModeId
                    self.showFocusCompletedView()
                    focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: false)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.global().async {
                        DispatchQueue.main.async {
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
                }
            }
        }
        self.isAutoMeetingsModeStarted = false
        self.appUsedInAutoMeetingFocusMode = ""
        
        
        
        
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
            menuViewControllerObj?.reloadIfNeeded()
            closeNudgeFocusAlignmentScoreWindow()
            
            leftMenuVcObj?.focusModeOrFocusModeHabitFinished()
            leftMenuVcObj?.resetFocusModeTitle()
        }
        DispatchQueue.main.async {
            stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
        }
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastRunningFocusModeInfo)
    }
    

    func showFocusCompletedView(){
        addLog(text: "show Focus Completed View")
        mainWindowControllerObj?.showWindow(self)
        // Assert the window size the user actually asked for before drawing the screen, the same
        // order every other main-window state uses (showWelcomeWindow, completeRemainingOnboarding).
        // Without it the focus-completed screen — the one offering "Do break habits" — inherited
        // whatever size the window happened to have, so a user with full screen ON got a small
        // window at exactly the moment the app is meant to pull them back into their routine
        // (report 2026-09-21_10-04-09). checkIsFullScreenNeeded is a no-op when the setting is off,
        // and keeps the window alone while an allowed-activity habit is playing.
        mainViewControllerObj?.checkIsFullScreenNeeded()
        leftMenuVcObj!.showFocusCompletedView()
    }

    @objc func focusModeStartted(isStartedByPusher:Bool){
        addLog(text: "focus Mode Started called")
        // Reset the postpone-origin flag at every session start; the postpone-pomodoro path re-sets it to
        // true right after calling this (see pomodoroVc), so non-postpone sessions start clean.
        isFocusSessionStartedFromPostponeIntention = false
        addLog(text: "getBlockedAppsToBlock:- \(getBlockedAppsToBlock())")
        if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            customBlockingScheduleManagerObj.customBlockingScheduleFinished()
        }
        
        focusModeStarttedResetAllData()
        // Every session starts USER-started. The auto-started paths (startScopedAiFocusSession: the LNM
        // meeting session and the approved-postpone buddy) reach this via startFocusFromMenu and then set
        // the marker back to true, so resetting it here can't strand them — but it does stop a session the
        // user starts themselves from inheriting a previous auto-started session's password-gate bypass.
        // Deliberately NOT in focusModeStarttedResetAllData(): resumeFocusModeAfterAppStartted calls that
        // too, and a session resumed after a relaunch must keep the marker it restored.
        setFocusSessionAutoStarted(false)
        playFocusModeStartedSound()
        
        closeSmallCountDownTimerBoxIfVisible()
        
        if addFocusTempUrlsOrAppsWcObj != nil{
            if addFocusTempUrlsOrAppsWcObj?.window?.isVisible ?? false{
                addFocusTempUrlsOrAppsWcObj?.window?.close()
            }
        }
        
        if !isStartedByPusher{
            if let startTime = startFocusModeTime, let endTime = endFocusModeTime{
                allApiObject.startFocusMode(id: getRunningFocusModeId(), intention: whatToAchieveInFocusBlock, start_time: startTime, finish_time: endTime, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
            }
        }
        
        var stringTime = ""
        
        if let date = endFocusModeTime{
            stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
        }
        
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                currentRunningFocusType = dic
                lastRunningFocusModeId = dic["id"] as? String ?? ""
                UserDefaults.standard.set(lastRunningFocusModeId, forKey: kUserdefaultsLastFocusModeId)
                let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                addLog(text: "\(currentRunningFocusModeName) Started until - \(stringTime)")
            }
        }
        isFocusModeRunning = true
        if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
            if  isRelaxFocus{
                showSavedSitesForLaterWindowForBreaks()
            }
        }
        
        frontApplicationChanged()// call it because front application is active already
        
        DispatchQueue.global().sync {
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
        }
        refreshFocusModeData()
        
        arrKeywordsToAllowInFocus.removeAll()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
        menuViewControllerObj?.reloadIfNeeded()
        if leftMenuVcObj != nil{
            leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
            leftMenuVcObj?.resetFocusModeTitle()
        }
        menuViewControllerObj?.showFocusModeCountDownIfNeeded()
        currentFocusAlignmentScore = 100
        getArrayOfTaskForApi()
        FocusMusicPromptManager.maybeShowPrompt(isStartedByPusher: isStartedByPusher)
    }
    
    
    var timerCheckAllowedApps:Timer?
    var timerAllowAppForActivity:Timer?
    var timerBlockUrl:Timer?//block urls list
    

    @objc func frontApplicationChanged(){

        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool != nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) != nil{
                if !isSettingsLoddedInAppdelegate{
                    return;
                }
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if !tryBlockingVcShownInOnboarding{
                    return;
                }
            }
        }
        
        //  if app is in shutoff state user can't use any app
        if currentState == ._SHUTOFFMAC_{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if !focusDefaultAllowApps.contains(nameLowercased) && nameLowercased != selfAppName.lowercased(){
                            exitFullScreen(runningApp:runningApp)
                        }
                    }
                }
                return;
            }
        }
        
        timerBlockUrl?.invalidate()
        habitBlockTimerHelper.stopUrlTimer()
        currentBrowserUrlForAi = ""
        currentRunningAppNameForAi = ""
        // // close set Intention Blocked Urls window if front application changed////
        if setIntentionBlockedUrlsWcObj != nil{
            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            let pid = runningApp.processIdentifier
                            if setIntentionBlockedUrlsVcObj?.currentPid != pid{
                                setIntentionBlockedUrlsVcObj?.closeWindow()
                            }
                        }
                    }
                }
            }
        }
        
        suggestWorkFocusManagerObject.stopUrlTimer()
        
        // // close  Intention Blocked Urls window if front application changed////
        if intentionBlockedUrlsWcObj != nil{
            if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            let pid = runningApp.processIdentifier
                            if intentionBlockedUrlsVcObj?.currentPid != pid{
                                intentionBlockedUrlsWcObj?.window?.close()
                            }
                        }
                    }
                }
            }
        }
        
        // // close  Intention Blocked Urls window if front application changed////
        if intentionBlockedAppsWcObj != nil{
            if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            if let bundleURL = runningApp.bundleURL{
                                if intentionBlockedAppsVcObj!.blockedAppName != bundleURL.deletingPathExtension().lastPathComponent{
                                    intentionBlockedAppsWcObj?.window?.close()
                                }
                            }
                        }
                    }
                }
            }
        }
        //  ////////////////////////////////////////////////////////////////////////////
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent
                let nameLowercased = name.lowercased()
                if runningApp.bundleIdentifier != Bundle.main.bundleIdentifier{
                    if !arrExcludeAppsInBreaksBrainDumpLastActivateApp.contains(nameLowercased){
                        lastFrontMostApplication = runningApp
                    }
                }
                if permissionBlockDistractionWcObj != nil && tryBlockUrlVcObj != nil{
                    if permissionBlockDistractionWcObj!.window?.isVisible ?? false{
                        if permissionBlockDistractionWcObj?.contentViewController == tryBlockUrlVcObj{
                            addLog(text: "Try website blocking view is visible and current app is:- \(nameLowercased)")
                        }
                    }
                }
                
            }
        }
        
        if currentState == ._EVENING_HABIT_ && currentRelaxHabitPlaying != nil && currentAction == ._INPROGRESS_{
            if currentRelaxHabitPlaying!.showSavedDistractingWebsites{
                return;
            }
        }
        
        if (currentState == ._MICRO_BREAK_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    let localizedNameLowercased = runningApp.localizedName?.lowercased()
                    var isAppAllowed = false
                    var isSelfApp = false
                    DispatchQueue.global().sync {
                        if !isAnyAllowedFocusModeActivityRunning{
                            if focusDefaultAllowApps.contains(nameLowercased) || nameLowercased == selfAppName.lowercased(){
                                isAppAllowed = true
                            }else{
                                var allowApps = [String]()
                                
                                if currentHabitPlaying != nil{
                                    allowApps = currentHabitPlaying!.allowApps
                                }else if currentActivityPlaying != nil{
                                    allowApps = currentActivityPlaying!.allowApps
                                }
                                
                                for appName in allowApps{
                                    let allowAppLowercased = appName.lowercased()
                                    if allowAppLowercased == nameLowercased || allowAppLowercased == localizedNameLowercased{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                                
                                
                                for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                                
                            }
                            
                            if !isAppAllowed{
                                exitFullScreen(runningApp:runningApp)
                                runningApp.hide()
                                allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
                                return
                            }
                            
                        }else{
                            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                            let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                            let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                            focusModeCloseCurrentUrlForAlignmentScore()
                            tabMatricsObject.frontAppChanged(name: name)// tab matrics work // 22/1/25
                            
                            
                            var isAppBlocked = false
                            if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentAppForAlignmentScore()
                                return;
                            }
                            
                            for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                    
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                    return;
                                }
                            }
                            tabMatricsObject.currentAppTabCount = 1
                            for path in blockAppsPath{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    isAppBlocked = true
                                    break;
                                }
                            }
                            var isAllowedAppIsDefault = false
                            if isAllowedAllAppsInFocus{
                                isAppAllowed = true
                                if nameLowercased == selfAppName.lowercased(){
                                    isSelfApp = true
                                    isAllowedAppIsDefault = true
                                }
                            }else{
                                
                                if nameLowercased == selfAppName.lowercased(){
                                    isSelfApp = true
                                    isAppAllowed = true
                                    isAllowedAppIsDefault = true
                                }else if focusDefaultAllowApps.contains(nameLowercased){
                                    isAppAllowed = true
                                    isAllowedAppIsDefault = true
                                }else{
                                    if isRunningAppInAllowedApps(allowAppsPath, runningAppNameLowercased: nameLowercased){
                                        isAppAllowed = true
                                    }
                                }
                            }
                            
                            var isAppAllowedByCuddlyMode = false
                            if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                                isAppAllowed = true
                                isAppAllowedByCuddlyMode = true
                            }
                            
                            if !isAppAllowed{
                                var isAppAllowedByUser = false
                                let arrBlockedApps = getBlockedAppsToBlock()
                                addLog(text: "app is:- \(nameLowercased)") // need to delete in next  build
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                        isAppAllowed = false
                                        if popUpBlockConfirmWcObj != nil{
                                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                                    popUpBlockConfirmVcObj?.closeWindow()
                                                }
                                            }
                                        }
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if !result{// it means not allowed by user(intention is not set)
                                            isAppAllowedByUser = true
                                            isAppAllowed = true
                                        }
                                        if !isAppAllowedByUser{
                                            closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        setFocusBearIconToNormal()
                                        focusModeCloseCurrentAppForAlignmentScore()
                                        return;
                                    }
                                }
                            }else{
                                if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                    let arrBlockedApps = getBlockedAppsToBlock()
                                    addLog(text: "app is:- \(nameLowercased)") // need to delete in next  build
                                    for path in arrBlockedApps{
                                        let url = URL(fileURLWithPath: path)
                                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                            if popUpBlockConfirmWcObj != nil{
                                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                                        popUpBlockConfirmVcObj?.closeWindow()
                                                    }
                                                }
                                            }
                                            let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                            if result{// it means not allowed by user(intention is not set)
                                                closeIntentionBlockedAppsWinddowIfVisible()
                                            }
                                            setFocusBearIconToNormal()
                                            focusModeCloseCurrentAppForAlignmentScore()
                                            return;
                                        }
                                    }
                                }
                            }
                            if isAppBlocked{
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true, isAppBlockByAi: false)
                                habitBlockTimerHelper.stopUrlTimer()
                                setFocusBearIconToNormal()
                                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                                return;
                            }else if !isAppAllowed{
                                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                                focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name, appNameLowercased: nameLowercased)
                                
                                return;
                            }else{
                                if isSelfApp{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                    return;
                                }
                                if isAllowedAppIsDefault{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                }else{
                                    if !isAppAllowedByCuddlyMode{
                                        focusModeSetCurrentAppAllowedForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 1.0, appName: name)
                                    }else{
                                        focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                                    }
                                }
                                DispatchQueue.main.async {
                                    closePupUpBlockIfVisible()
                                }
                            }
                        }
                        setTimeCheckUrlsForHabits(nameLowercased: nameLowercased)
                        
                    }
                }
            }
        }else if isFocusModeOn() || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    
                    if customBlockingScheduleManagerObj.isAnyCustomScheduleOn && !isFocusModeRunning{
                        if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_ && currentState != ._FOCUS_SUMMARY_ && currentState != ._MICRO_BREAK_ && currentState != ._BREATHING_ && currentState != ._SHUTOFFMAC_{
                            suggestWorkFocusManagerObject.startUrlTimer(browserName: nameLowercased, runningApp: runningApp)// added v 3.32.489
                        }
                    }
                    
                    var isAppAllowed = false
                    var isSelfApp = false
                    
                    let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                    let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                    if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
                        if  isRelaxFocus{
                            return;
                        }
                    }
                    focusModeCloseCurrentUrlForAlignmentScore()
                    tabMatricsObject.frontAppChanged(name: name)// tab matrics work // 22/1/25
                    
                    var isAppBlocked = false
                    
                    if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                        setFocusBearIconToNormal()
                        focusModeCloseCurrentAppForAlignmentScore()
                        return;
                    }
                    
                    for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                            setFocusBearIconToNormal()
                            focusModeCloseCurrentAppForAlignmentScore()
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            return;
                        }
                    }
                    
                    tabMatricsObject.currentAppTabCount = 1
                    for path in blockAppsPath{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                            isAppBlocked = true
                            break;
                        }
                    }
                    var isAllowedAppIsDefault = false
                    if isAllowedAllAppsInFocus{
                        isAppAllowed = true
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                            isAllowedAppIsDefault = true
                        }
                    }else{
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                            isAppAllowed = true
                            isAllowedAppIsDefault = true
                        }else if focusDefaultAllowApps.contains(nameLowercased){//if nameLowercased == "finder" || nameLowercased == "universalaccessauthwarn"{
                            isAppAllowed = true
                            isAllowedAppIsDefault = true
                        }else{
                            if isRunningAppInAllowedApps(allowAppsPath, runningAppNameLowercased: nameLowercased){
                                isAppAllowed = true
                            }
                        }
                    }
                    var isAppAllowedByCuddlyMode = false
                    if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                        isAppAllowed = true
                        isAppAllowedByCuddlyMode = true
                    }
                    
                    if !isAppAllowed{
                        var isAppAllowedByUser = false
                        let arrBlockedApps = getBlockedAppsToBlock()
                        
                        addLog(text: "app is:- \(nameLowercased)") // need to delete in next  build
                        for path in arrBlockedApps{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                isAppAllowed = false
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                if !result{// it means allowed by user(intention set by user)
                                    isAppAllowedByUser = true
                                    isAppAllowed = true
                                }
                                if !isAppAllowedByUser{
                                    closeIntentionBlockedAppsWinddowIfVisible()
                                }
                                setFocusBearIconToNormal()
                                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                                return;
                            }
                        }
                    }else{
                        if !SettingsManagerObject.immediatelyBlockDistractingApps{
                            let arrBlockedApps = getBlockedAppsToBlock()
                            
                            addLog(text: "app is:- \(nameLowercased)") // need to delete in next  build
                            for path in arrBlockedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                    let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                    if result{// it means allowed by user(intention set by user)
                                        closeIntentionBlockedAppsWinddowIfVisible()
                                    }
                                    setFocusBearIconToNormal()
                                    focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                                    return;
                                }
                            }
                        }
                    }
                    
                    var appAllowedBeacuseDefaultFocusModeRunning = false
                    if !isAppAllowed{
                        if let isDefault = currentRunningFocusType["isDefault"] as? Bool{//this key will only be awailable in default focus type
                            if  isDefault{
                                isAppAllowed = true
                                appAllowedBeacuseDefaultFocusModeRunning = true
                            }
                        }
                    }
                    if isAppBlocked{
                        if popUpBlockConfirmWcObj != nil{
                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                        }
                        focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true, isAppBlockByAi: false)
                        focusModeHelper.stopUrlTimer()
                        setFocusBearIconToNormal()
                        focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                        return;
                    }else if !isAppAllowed{


                        focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                        focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name, appNameLowercased: nameLowercased)
                        // focusTryToBlockUnwantedApp may SYNCHRONOUSLY allow a browser: tryCheckAppFromAi
                        // appends it to arrAllowedAppsInCuddlyModeCurrentFocus (strictness != normal, or
                        // data-collection mode) — in both cuddly and teacher/AI mode. When that happens the
                        // browser IS now allowed, so its URLs must be checked: (re)start the URL timer
                        // instead of stopping it. Previously this branch ALWAYS stopped the timer and
                        // returned before reaching setTimeCheckUrlsForFocusMode below, so on the FIRST visit
                        // to a browser no sites were blocked — only the SECOND visit (browser already in the
                        // allowed list, so it takes the allowed branch) started URL checking.
                        if arrBrowsersLowerCasedNames.contains(nameLowercased), arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                            setTimeCheckUrlsForFocusMode(nameLowercased: nameLowercased)
                        }else{
                            focusModeHelper.stopUrlTimer()
                        }

                        return;
                    }else{
                        if isSelfApp{
                            setFocusBearIconToNormal()
                            focusModeCloseCurrentAppForAlignmentScore()
                            return;
                        }
                        if isAllowedAppIsDefault{
                            setFocusBearIconToNormal()
                            focusModeCloseCurrentAppForAlignmentScore()
                        }else{
                            if !isAppAllowedByCuddlyMode && !appAllowedBeacuseDefaultFocusModeRunning{
                                focusModeSetCurrentAppAllowedForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 1.0, appName: name)
                            }else{
                                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            closePupUpBlockIfVisible()
                        }
                    }
                    
                    setTimeCheckUrlsForFocusMode(nameLowercased: nameLowercased)
                }
            }
        }else if let runningApp = NSWorkspace.shared.frontmostApplication, let appUrl = runningApp.bundleURL{
            if isAppEnable{//Deactivate should stop always blocked URLs#663
                
                let name = appUrl.deletingPathExtension().lastPathComponent
                let nameLowercased = name.lowercased()
 
                var isOnboardingCheckBlockingTime = false
                
                if permissionBlockDistractionWcObj != nil && tryBlockUrlVcObj != nil{// added on 30/8/25  on version 2.27.407
                    if permissionBlockDistractionWcObj!.window?.isVisible ?? false{
                        if permissionBlockDistractionWcObj?.contentViewController == tryBlockUrlVcObj{
                            isOnboardingCheckBlockingTime = true
                        }
                    }
                }
                if !isOnboardingCheckBlockingTime{
                    if currentState != ._MORNING_HABIT_ && currentState != ._EVENING_HABIT_ && currentState != ._FOCUS_SUMMARY_ && currentState != ._MICRO_BREAK_ && currentState != ._BREATHING_ && currentState != ._SHUTOFFMAC_{
                        suggestWorkFocusManagerObject.startUrlTimer(browserName: nameLowercased, runningApp: runningApp)
                    }
                }
                
                if isFocusBreakOn{
                    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                        if state{
                            return;
                        }
                    }
                }
                if currentState == ._MICRO_BREAK_{
                    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                        if state{
                            return;
                        }
                    }
                }
                
                
                if !isOnboardingCheckBlockingTime{
                    if isUserOnMeeting && !SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled{
                        return;
                    }
                }
                
                var shouldCheckBlockedUrls = false
                // for try block url if blocking schedule is != _UNTIL_I_FINISH_WORK_
                if isOnboardingCheckBlockingTime{// now super distarcting sites will block only in focus modes and custom blocking schedules  24/9/25 version 2.27.417
                    shouldCheckBlockedUrls = true
                }

                if shouldCheckBlockedUrls{
                    
                    if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                        return;
                    }
                    var isAppAllowed = true
                    var isAppAllowedByUser = false
                    let arrBlockedApps = getBlockedAppsToBlock()
                    
                    addLog(text: "app is:- \(nameLowercased)") // need to delete in next  build
                    for path in arrBlockedApps{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                            isAppAllowed = false
                            let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                            if !result{// it means allowed by user(intention set by user)
                                isAppAllowedByUser = true
                                isAppAllowed = true
                            }
                            DispatchQueue.global().async {
                                DispatchQueue.main.async {
                                    self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                }
                            }
                            break;
                        }
                    }
                    
                    
                    if nameLowercased != selfAppName.lowercased(){
                        if isAppAllowed{
                            if !isAppAllowedByUser{
                                closeIntentionBlockedAppsWinddowIfVisible()
                            }
                            DispatchQueue.global().sync {
                                if arrBrowsersLowerCasedNames.contains(nameLowercased){
                                    if nameLowercased == "sigmaos"{
                                        sigmaOsBrowserName = "SigmaOs"
                                    }else if nameLowercased == "sigmaos_latest"{
                                        sigmaOsBrowserName = "SigmaOS_latest"
                                    }
                                    addLog(text: "Set timer block urls in background")
                                    timerBlockUrl?.invalidate()
                                    self.timerBlockUrl = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.blockUrlsInBackground), userInfo: nil, repeats: true)
                                    RunLoop.main.add(self.timerBlockUrl!, forMode: RunLoop.Mode.common)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func setTimeCheckUrlsForFocusMode(nameLowercased:String){
        print("setTimeCheckUrlsForFocusMode*********")
        focusModeHelper.startUrlTimer(browserName: nameLowercased)
    }
    
    func setTimeCheckUrlsForHabits(nameLowercased:String){
        print("setTimeCheckUrlsForHabits*********")
        habitBlockTimerHelper.startUrlTimer(browserName: nameLowercased)
    }
    
    @objc func blockUrlsInBackground(){
        ManagedBlockingRuntime.shared.checkCurrentBrowserNow()
        addLog(text:"func call:- blockUrlsInBackground")
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            addLog(text:"Browsers Permissions not set by user return;")
            return;
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if UserDefaults.standard.object(forKey: kUserdefaultsControllingBrowserVcShown) == nil{
                    self.timerBlockUrl?.invalidate()
                    addLog(text:"Onboarding time:- return;")
                    return;
                }
            }
        }
        let isCurrentUrlAllowedInFocsMode = false
        
        currentBrowserUrlForAi = ""
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
        
        if currentState == ._EVENING_HABIT_ && currentRelaxHabitPlaying != nil && currentAction == ._INPROGRESS_{
            if currentRelaxHabitPlaying!.showSavedDistractingWebsites{
                return;
            }
        }
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let name = runningApp.localizedName{
                var script: String = ""
                var tabUrl:String = ""
                var blockItem = ""
                var currentBrowser:BROWSER!
                let nameLowercased = name.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    currentBrowser = browser
                }else{
                    self.timerBlockUrl?.invalidate()
                    if setIntentionBlockedUrlsWcObj != nil{
                        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                            setIntentionBlockedUrlsVcObj?.closeWindow()
                            return;
                        }
                    }
                    return;
                }
                var defaultPageOfBrowser = ""
                if currentBrowser == ._SAFARI_{
                    defaultPageOfBrowser = "favorites:"
                }else if currentBrowser == ._MICROSOFT_EDGE_{
                    defaultPageOfBrowser = "edge://newtab"
                }else if currentBrowser == ._SIGMA_OS_{
                    defaultPageOfBrowser = "sigma://newpage"
                }else{
                    defaultPageOfBrowser = "chrome:"
                }
                
                
                if var url = getActiveTabUrlOf(browser: currentBrowser){
                    if ManagedBlockingRuntime.shared.shouldDeferLegacyURL(url) { return }
                    
                    if currentBrowser == ._OPERA_GX_{
                        if url.contains("gxcorner.games"){ //  alllow gxcorner (default url)
                            closeSetIntentionBlockedUrlsWinddowIfVisible()
                            closeIntentionBlockedUrlsWinddowIfVisible()
                            return;
                        }
                    }
                    
                    //Allow unblocking super distracting URL in cuddly bear mode #432
                    if url.localizedCaseInsensitiveContains("unblock_it=true"){
                        allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
                        
                        //if change anything in always block site code then a change also done in checkinbackground function
                        var extractedUrl: String = ""
                        extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") ?? ""
                        if extractedUrl.isEmpty{
                            extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") ?? ""
                        }
                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                        if currentBrowser == ._FIREFOX_{
                            extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl// not Encoding in first time so encoding here again for firefox
                        }
                        if !extractedUrl.isEmpty {
                            let extractedPath = getDomainFromUrl(url: extractedUrl)
                            if url.localizedCaseInsensitiveContains("unlock_duration_minutes"){// new blocking page work if browser full screen
                                var minutesToUnlock = 0
                                var intentionToShow = ""
                                let urlInfo = url.components(separatedBy: "&")
                                if urlInfo.count > 1{
                                    for info in urlInfo{
                                        if info.localizedCaseInsensitiveContains("unlock_duration_minutes"){
                                            let durationInfo = info.components(separatedBy: "=")
                                            if durationInfo.count > 1{
                                                let minutesString = durationInfo[1]
                                                let minutes = Int(minutesString)
                                                minutesToUnlock = minutes ?? 0
                                            }
                                            
                                        }else if info.localizedCaseInsensitiveContains("distraction_intention"){
                                            let intentionInfo = info.components(separatedBy: "=")
                                            if intentionInfo.count > 1{
                                                intentionToShow = intentionInfo[1]
                                                intentionToShow = intentionToShow.removingPercentEncoding ?? intentionToShow
                                            }
                                            
                                        }
                                    }
                                }
                                for i in 0..<arrAlwaysBlockedSitesData.count{
                                    let dictionary = arrAlwaysBlockedSitesData[i]
                                    if let blockUrl = dictionary["url"] as? String{
                                        if blockUrl.lowercased() == extractedPath.lowercased(){
                                            arrAlwaysBlockedSitesData.remove(at: i)
                                            break;
                                        }
                                    }
                                }
                                saveIntentionForBlockedUrl(url: extractedPath, script: "", browser: nil, intention: intentionToShow, seconds: minutesToUnlock * 60, currentPid: nil)
                                
                                
                                allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                            }else{
                                for i in 0..<arrAlwaysBlockedSitesData.count{
                                    let dictionary = arrAlwaysBlockedSitesData[i]
                                    if let blockUrl = dictionary["url"] as? String{
                                        if blockUrl.lowercased() == extractedPath.lowercased(){
                                            arrAlwaysBlockedSitesData.remove(at: i)
                                            break;
                                        }
                                    }
                                }
                                allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                                
                                // doing this because if immidiatly block url setting is on then after unblock click we are not showing ask intention box again thats why after clicking unblock it is blocking again. to handle this problem if immidiatly block setting is on then allwing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
                                if SettingsManagerObject.immediatelyBlockDistractingSites{
                                    let seconds =  24*60*60
                                    let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                                    arrAlwaysBlockedSitesData.append(["url": extractedPath, "isBlocked": false, "intention" : "", "closed":false, "endTime": endTime, "duration": seconds, "allowFor24Hours": true])
                                }
                            }
                            
                        } else {
                            print("Substring not found.")
                        }
                    }
                    
                    if !url.contains(defaultPageOfBrowser) && !url.contains(blockWebUrlString){
                        let domain = getDomainFromUrl(url: url)//getDomainFromUrl(url: url)
                        tabUrl = domain
                        if setIntentionBlockedUrlsWcObj != nil{
                            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                                    exitFullScreen(runningApp: runningApp)
                                    return;
                                }else{
                                    setIntentionBlockedUrlsVcObj?.closeWindow()
                                }
                            }
                        }
                        
                        var arrBlockedUrls = getBlockedUrlsToBlock()
                        
                        if permissionBlockDistractionWcObj != nil && tryBlockUrlVcObj != nil{
                            if permissionBlockDistractionWcObj!.window?.isVisible ?? false{
                                if permissionBlockDistractionWcObj?.contentViewController == tryBlockUrlVcObj{
                                    if arrBlockedUrls.count == 0{
                                        arrBlockedUrls = ["facebook.com"] // for try block url if no blocked url is set
                                    }
                                    addLog(text: "Try website blocking view is visible and current app is:- \(nameLowercased) and current url is:- \(url)")
                                }
                            }
                        }
                        
                        var bool = false
                        for turl in arrBlockedUrls{
                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                            bool = validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)//.isUrlValid(urlToCheck: url, allowUrl: turl)
                            if bool{
                                blockItem = turl
                                break;
                            }
                        }
                        if bool{
                            url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                            
                            switch currentBrowser{
                                
                            case ._SAFARI_:
                                script = getSafariBlockScript(url:url)
                                
                            case ._GOOGLE_CHROME_:
                                script = getGoogleChromeBlockScript(url:url)
                                
                            case ._OPERA_:
                                script = getOperaBlockScript(url:url)
                                
                            case ._OPERA_GX_:
                                script = getOperaGxBlockScript(url:url)
                                
                            case ._VIVALDI_:
                                script = getVivaldiBlockScript(url:url)
                                
                            case ._BRAVE_BROWSER_:
                                script = getBraveBrowserBlockScript(url:url)
                                
                            case ._SIDEKICK_:
                                script = getSidekickBlockScript(url:url)
                                
                            case ._MICROSOFT_EDGE_:
                                script = getMicrosoftEdgeBlockScript(url:url)
                                
                            case ._ARC_:
                                script = getArcBlockScript(url:url)
                                
                            case ._FIREFOX_:
                                script = getFirefoxBlockScript(url:url)
                                
                            case ._SIGMA_OS_:
                                script = getSigmaOsBrowserBlockScript(url: url)
                            case ._COMET_:
                                script = getCometBlockScript(url: url)
                            case .none:
                                
                                return
                            }
                            
                        }else{
                            if setIntentionBlockedUrlsWcObj != nil{
                                if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    setIntentionBlockedUrlsVcObj?.closeWindow()
                                    return;
                                }
                            }
                            closeIntentionBlockedUrlsWinddowIfVisible()
                            return;
                        }
                    }else{
                        if setIntentionBlockedUrlsWcObj != nil{
                            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                setIntentionBlockedUrlsVcObj?.closeWindow()
                                return;
                            }
                        }
                        closeIntentionBlockedUrlsWinddowIfVisible()
                        return;
                    }
                    
                }else{
                    if setIntentionBlockedUrlsWcObj != nil{
                        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                            setIntentionBlockedUrlsVcObj?.closeWindow()
                            return;
                        }
                    }
                    closeIntentionBlockedUrlsWinddowIfVisible()
                    return;
                }//
                
                var modeString = ""
                if SettingsManagerObject.isCuddlyModeEnabled{
                    modeString = "&block_mode=cuddly"
                }else{
                    modeString = "&block_mode=grizzly"
                }
                var isOnboardingString = ""
                
                let blockPageTourShowed = UserDefaults.standard.object(forKey: kUserDefaultsBlockPageTourShowed) as? Bool ?? false
                var shouldShowTour = !blockPageTourShowed
                
                
                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        shouldShowTour = false
                    }
                }
                //
                if shouldShowTour{
                    isOnboardingString = "&show_tour=true"
                    UserDefaults.standard.set(true, forKey: kUserDefaultsBlockPageTourShowed)
                }
                
                
                if isCurrentUrlAllowedInFocsMode{
                    
                    var cuddly_bear_modeString = ""
                    var aiReasonToBlockString = ""
                    if isStrictnessLevelNormal(){
                        cuddly_bear_modeString = "&cuddly_bear_mode=true"
                        aiReasonToBlockString = "&reason=This site is always blocked."//The website URL is allowed in focus mode
                    }
                    if isAnyAllowedFocusModeActivityRunning == true{
                        var blockType = ""
                        if currentState == ._MICRO_BREAK_{
                            blockType = "break-activity"
                        }else if currentState == ._MORNING_HABIT_{
                            blockType = "morning-habit"
                        }else if currentState == ._EVENING_HABIT_{
                            blockType = "evening-habit"
                        }else if currentState == ._SPECIAL_ACTIVITY_{
                            blockType = "special-activity"
                        }else if currentState == ._CUSTOM_ROUTINE_{
                            blockType = "custom-routine"
                        }
                        
                        script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)\(modeString)")
                    }else{
                        var focusMode = ""
                        let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                        for dic in arrFocusType{
                            if dic["isOn"] as? Bool == true{
                                focusMode = dic["name"] as? String ?? ""
                                break;
                            }
                        }
                        var stringTime: String = ""
                        if let date = endFocusModeTime{
                            stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                        }
                        let focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
                        script = script.replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                    }
                }else{
                    script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=always-blocked\(modeString)\(isOnboardingString)")
                }
                if script.isEmpty{
                    return
                }
                tryToBlockAlwaysBlockedUrl(script: script, url: tabUrl, browser: currentBrowser, runningApp: runningApp, blockItem: blockItem)
                
            }
        }
    }
    
    
    @objc func checkFcousAllowedApp(){
        // Re-attach a persisted accountability-buddy session to the focus session the app restored on
        // restart, so its AI overrides don't get lost — the "AI blocking removed after restart" symptom.
        // Retried each tick until it attaches or the persisted session expires: the focus-mode restore is
        // async, so the first tick often runs before isFocusModeRunning is true. The function owns the
        // done flag, and sets it only on a terminal outcome.
        if !didAttemptAccountabilityBuddyRestore {
            restoreAccountabilityBuddySessionIfNeeded()
        }
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning{
            addEntryInProductivityStatsCsv()
        }
        if isShowTimerInFocusEnabled{
            self.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        }
        let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
        
        if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
            if  isRelaxFocus{
                return;
            }
        }
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                
                var isAppAllowed = false
                var isAppBlocked = false
                var isSelfApp = false
                if name == selfAppName.lowercased() || name == focusBearTimeTrackerAppName{
                    return;
                }

                // No need to (re)start the URL-blocking timer here: it's started at session start by
                // focusModeStartted() → frontApplicationChanged() (which catches the already-frontmost
                // browser — see startTeacherSession), and every real app switch restarts it via
                // frontApplicationChanged(). A per-tick self-heal for the "no app-switch notification"
                // case is therefore redundant.
                for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
                    let url = URL(fileURLWithPath: path)
                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                        DispatchQueue.main.async {
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                        }
                        return;
                    }
                }
                let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                for path in blockAppsPath{
                    let url = URL(fileURLWithPath: path)
                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                        isAppBlocked = true
                        break;
                    }
                }
                
                if isAllowedAllAppsInFocus{
                    isAppAllowed = true
                    if name == selfAppName.lowercased(){
                        isSelfApp = true
                    }
                }else if name == selfAppName.lowercased(){
                    isSelfApp = true
                    isAppAllowed = true
                }else if focusDefaultAllowApps.contains(name){
                    isAppAllowed = true
                }else{
                    
                    
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    if isRunningAppInAllowedApps(allowAppsPath, runningAppNameLowercased: name){
                        isAppAllowed = true
                    }
                }
                
                
                if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                    isAppAllowed = true
                }
                
                if !isAppAllowed{
                    var isAppAllowedByUser = false
                    let arrBlockedApps = getBlockedAppsToBlock()
                    
                    addLog(text: "app is:- \(name)") // need to delete in next  build
                    for path in arrBlockedApps{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                            isAppAllowed = false
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                            if !result{// it means not allowed by user(intention is not set)
                                isAppAllowedByUser = true
                                isAppAllowed = true
                            }
                            if !isAppAllowedByUser{
                                closeIntentionBlockedAppsWinddowIfVisible()
                            }
                            return;
                        }
                    }
                }else{
                    if !SettingsManagerObject.immediatelyBlockDistractingApps{
                        let arrBlockedApps = getBlockedAppsToBlock()
                        
                        addLog(text: "app is:- \(name)") // need to delete in next  build
                        for path in arrBlockedApps{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                if result{// it means not allowed by user(intention is not set)
                                    closeIntentionBlockedAppsWinddowIfVisible()
                                }
                                return;
                            }
                        }
                    }
                }
                
                if !isAppAllowed{
                    if let isDefault = currentRunningFocusType["isDefault"] as? Bool{//this key will only be awailable in default focus type
                        if  isDefault{
                            isAppAllowed = true
                        }
                    }
                }
                if isAppBlocked{
                    if popUpBlockConfirmWcObj != nil{
                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                popUpBlockConfirmVcObj?.closeWindow()
                            }
                        }
                    }
                    focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true, isAppBlockByAi: false)
                    focusModeHelper.stopUrlTimer()
                    return;
                }else if !isAppAllowed{
                    
                    focusTryToBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, appNameLowercased: name)
                    focusModeHelper.stopUrlTimer()
                    return;
                }else{
                    if isSelfApp{
                        return;
                    }
                    DispatchQueue.main.async {
                        if popUpBlockConfirmWcObj != nil{
                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    
    // MARK: - Actual distracting-site time (#1302)

    /// When we last credited distracting time, and the sub-second remainder not yet committed.
    /// Measuring the real gap between ticks (instead of assuming each poll == 1s) keeps the total
    /// accurate under timer jitter and makes a second check fired in the same tick a no-op.
    private var lastDistractingCountTime: Date?
    private var pendingDistractingSeconds: Double = 0
    /// Longest gap between two ticks still treated as "continuously on the site". A larger gap means
    /// the user was away (or the machine slept) and is only now back, so we re-anchor without crediting it.
    private let maxDistractingTickGap: TimeInterval = 3

    /// Credit the real time elapsed since the previous tick to today's "time spent on distracting sites"
    /// total. Call once per poll while the front tab/app is an allowed (unblocked) distracting item.
    /// Accumulates actual elapsed time rather than a flat +1, so it stays exact under timer jitter and
    /// won't double-count if the check happens to run twice within the same second.
    private func accumulateActualDistractingTime(){
        let now = Date()
        if let last = lastDistractingCountTime{
            let elapsed = now.timeIntervalSince(last)
            if elapsed > 0 && elapsed <= maxDistractingTickGap{
                pendingDistractingSeconds += elapsed
            }
            // elapsed > cap ⇒ user returned after a gap; re-anchor below without crediting the gap.
        }
        lastDistractingCountTime = now

        let wholeSeconds = Int(pendingDistractingSeconds)
        guard wholeSeconds > 0 else { return }
        pendingDistractingSeconds -= Double(wholeSeconds)

        var totalDurationaSaved = 0
        if let timeSpentInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalTimeSpentOnDistractingSites) as? [String:Any],
           let date = timeSpentInfo["date"] as? Date, let duration = timeSpentInfo["duration"] as? Int,
           Calendar.current.isDateInToday(date){
            totalDurationaSaved = duration
        }
        totalDurationaSaved += wholeSeconds
        UserDefaults.standard.set(["date": Date(), "duration": totalDurationaSaved], forKey: kUserdefaultsTotalTimeSpentOnDistractingSites)
    }

    func tryToBlockAlwaysBlockedUrl(script: String, url:String, browser: BROWSER?, runningApp:NSRunningApplication, blockItem:String){
        print("tryToBlockAlwaysBlockedUrl")
        var needToBlockImmediately = SettingsManagerObject.immediatelyBlockDistractingSites
        if isFocusModeRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            if !SettingsManagerObject.isCuddlyModeEnabled{
                needToBlockImmediately = true// addded in 2.29.458
            }
        }
        
        if needToBlockImmediately{
            closeIntentionBlockedUrlsWinddowIfVisible()
            var allowFor24Hours = false
            
            // doing this because if immidiatly block url setting is on then after unblock click we are not showing ask intention box again thats why after clicking unblock it is blocking again. to handle this problem if immidiatly block setting is on then allwing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        allowFor24Hours = dictionary["allowFor24Hours"] as? Bool ?? false
                        break;
                    }
                }
            }
            
            if !allowFor24Hours{
                blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
            }
        }else{
            var isBlocked = true
            var isUrlAllreadyChecked = false
            var intention = ""
            var isClosed = false
            var alllowUrlEndTime:Date?
            var urlAllreadyCheckedIndex = -1
            var allowFor24Hours = false
            
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        isBlocked = dictionary["isBlocked"] as? Bool ?? false
                        intention = dictionary["intention"] as? String ?? ""
                        isClosed = dictionary["closed"] as? Bool ?? false
                        alllowUrlEndTime = dictionary["endTime"] as? Date
                        allowFor24Hours = dictionary["allowFor24Hours"] as? Bool ?? false
                        isUrlAllreadyChecked = true
                        urlAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            
            if isUrlAllreadyChecked{
                if isBlocked{
                    closeIntentionBlockedUrlsWinddowIfVisible()
                    blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
                }else {
                    // Credit the actual time elapsed since the last poll (not a flat +1) — issue #1302.
                    accumulateActualDistractingTime()

                    var shouldSetIntentionAgain = false
                    if alllowUrlEndTime != nil{
                        if Date().compare(alllowUrlEndTime!) == .orderedDescending{ //>
                            shouldSetIntentionAgain = true
                        }
                    }
                    if shouldSetIntentionAgain{
                        if urlAllreadyCheckedIndex != -1{
                            arrAlwaysBlockedSitesData[urlAllreadyCheckedIndex]["intention"] = ""
                            arrAlwaysBlockedSitesData[urlAllreadyCheckedIndex]["closed"] = false
                        }
                        closeIntentionBlockedUrlsWinddowIfVisible()
                        
                        if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                            let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&confirm_ai_distracting_url=true")
                            blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
                        }else{
                            exitFullScreen(runningApp: runningApp)
                            showSetIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, allreadyCheckedIndex:urlAllreadyCheckedIndex, isAppBlocking:false, currentApp:nil, blockedAppName:"", blockItem: blockItem)
                        }
                        
                        
                        
                    }else{
                        if !isClosed{
                            if intentionBlockedUrlsWcObj != nil{
                                if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    if intentionBlockedUrlsVcObj?.tabUrl == url && intentionBlockedUrlsVcObj?.browser == browser{
                                        //intentionBlockedUrlsVcObj?.timer?.invalidate()
                                        // intentionBlockedUrlsVcObj?.timer = nil
                                        return;
                                    }else{
                                        intentionBlockedUrlsVcObj?.saveLastVisibleTimeForCurrentUrl()
                                    }
                                }
                            }
                            
                            showIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, intention: intention, currentPid: nil, allowFor24Hours:allowFor24Hours)
                        }else{
                            closeIntentionBlockedUrlsWinddowIfVisible()
                        }
                    }
                    
                }
            }else{
                closeIntentionBlockedUrlsWinddowIfVisible()
                if isRunningAppFullScreen(runningApp: runningApp, browser: browser) || stageManagerObject.isStageManagerEnabled{
                    let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "&confirm_ai_distracting_url=true")
                    blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
                }else{
                    exitFullScreen(runningApp: runningApp)
                    showSetIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, allreadyCheckedIndex:urlAllreadyCheckedIndex, isAppBlocking:false, currentApp:nil, blockedAppName:"", blockItem: blockItem)
                }
            }
        }
    }
    
    func tryToBlockAlwaysBlockedApp(runningApp: NSRunningApplication, appName:String)->Bool{
        print("tryToBlockAlwaysBlockedApp*************")
        
        for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
            let url = URL(fileURLWithPath: path)
            if url.deletingPathExtension().lastPathComponent.lowercased() == appName.lowercased(){
                print("App \(appName) is in Always Allowed list, skipping block")
                return false
            }
        }
        
        exitFullScreen(runningApp:runningApp)
        
        var needToBlockImmediately = SettingsManagerObject.immediatelyBlockDistractingApps
        if isFocusModeRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            if !SettingsManagerObject.isCuddlyModeEnabled{
                needToBlockImmediately = true// addded in 2.29.458
            }
        }
        if needToBlockImmediately{
            addLog(text:"tryToBlockAlwaysBlockedApp:- \(appName)")// addded in 2.28.443
            closeIntentionBlockedAppsWinddowIfVisible()
            blockAlwaysBlockedApp(runningApp: runningApp, appName:appName)
            return true
        }else{
            if setIntentionBlockedUrlsWcObj != nil{
                if setIntentionBlockedUrlsWcObj!.window?.isVisible ?? false{
                    if setIntentionBlockedUrlsVcObj!.isAppBlocking{
                        if setIntentionBlockedUrlsVcObj?.currentApp == runningApp{
                            return true
                        }
                    }
                }
            }
            addLog(text:"tryToBlockAlwaysBlockedApp:- \(appName)")// addded in 2.28.443
            var isBlocked = true
            var isAppAllreadyChecked = false
            var intention = ""
            var isClosed = false
            var alllowAppEndTime:Date?
            var appAllreadyCheckedIndex = -1
            for i in 0..<arrAlwaysBlockedAppsData.count{
                let dictionary = arrAlwaysBlockedAppsData[i]
                if let blockApp = dictionary["app"] as? String{
                    if blockApp.lowercased() == appName.lowercased(){
                        isBlocked = dictionary["isBlocked"] as? Bool ?? false
                        intention = dictionary["intention"] as? String ?? ""
                        isClosed = dictionary["closed"] as? Bool ?? false
                        alllowAppEndTime = dictionary["endTime"] as? Date
                        isAppAllreadyChecked = true
                        appAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            
            
            
            if isAppAllreadyChecked{
                if isBlocked{
                    closeIntentionBlockedAppsWinddowIfVisible()
                    blockAlwaysBlockedApp(runningApp: runningApp, appName: appName)
                }else{
                    // Credit the actual time elapsed since the last poll (not a flat +1) — issue #1302.
                    accumulateActualDistractingTime()

                    var shouldSetIntentionAgain = false
                    if alllowAppEndTime != nil{
                        if Date().compare(alllowAppEndTime!) == .orderedDescending{ //>
                            shouldSetIntentionAgain = true
                        }
                    }
                    if shouldSetIntentionAgain{
                        if appAllreadyCheckedIndex != -1{
                            arrAlwaysBlockedAppsData[appAllreadyCheckedIndex]["intention"] = ""
                            arrAlwaysBlockedAppsData[appAllreadyCheckedIndex]["closed"] = false
                        }
                        closeIntentionBlockedAppsWinddowIfVisible()
                        showSetIntentionBlockedUrlsWindow(script: "", url: "", browser: nil, allreadyCheckedIndex:appAllreadyCheckedIndex, isAppBlocking:true, currentApp:runningApp, blockedAppName:appName, blockItem:"")
                        
                        return true
                    }else{
                        if !isClosed{
                            if intentionBlockedAppsWcObj != nil{
                                if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
                                    if intentionBlockedAppsVcObj?.currentApp == runningApp{
                                        return false
                                    }else{
                                        intentionBlockedAppsVcObj?.saveLastVisibleTimeForCurrentApp()
                                    }
                                }
                            }
                            
                            showIntentionBlockedAppsWindow(currentApp: runningApp, blockedAppName: appName, intention: intention)
                        }else{
                            closeIntentionBlockedAppsWinddowIfVisible()
                        }
                        return false
                    }
                }
            }else{
                closeIntentionBlockedAppsWinddowIfVisible()
                showSetIntentionBlockedUrlsWindow(script: "", url: "", browser: nil, allreadyCheckedIndex:-1, isAppBlocking:true, currentApp:runningApp, blockedAppName:appName, blockItem:"")
                return true
            }
            
            return true
        }
    }
    
    func blockAlwaysBlockedApp(runningApp: NSRunningApplication, appName:String){
        addLog(text:"blockAlwaysBlockedApp:- \(appName)")// addded in 2.28.443
        exitFullScreen(runningApp:runningApp)
        runningApp.hide()
        allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
        
        if !SettingsManagerObject.immediatelyBlockDistractingApps{
            var isAppAllreadyChecked = false
            var isAppAllreadyCheckedIndex = 0
            for i in 0..<arrAlwaysBlockedAppsData.count{
                let dictionary = arrAlwaysBlockedAppsData[i]
                if let blockApp = dictionary["app"] as? String{
                    if blockApp.lowercased() == appName.lowercased(){
                        isAppAllreadyChecked = true
                        isAppAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            if isAppAllreadyChecked == false{
                arrAlwaysBlockedAppsData.append(["app": appName, "isBlocked": true, "intention" : "", "closed":false])
            }else{
                arrAlwaysBlockedAppsData[isAppAllreadyCheckedIndex] = ["app": appName, "isBlocked": true, "intention" : "", "closed":false]
            }
        }
    }
    
    func blockAlwaysBlockedUrl(script: String, browser: BROWSER?, url:String){
        addLog(text:"blockAlwaysBlockedUrl:- \(url)")
        if browser == ._ARC_{
            NSWorkspace.shared.launchApplication("Arc")
        }
        let script = script.replacingOccurrences(of: "<NEWPAGE>", with: "")
        
        if browser == ._FIREFOX_{
            firefoxServer.sendBlockNow(url: url,params: script)
        }else{
            executeScript(script: script)
        }
        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"super_distracting_url"])
        
        var totalBlockedSites = 0
        if let blockInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalDistractingSitesBlocked) as? [String:Any]{
            if let date = blockInfo["date"] as? Date, let count = blockInfo["count"] as? Int{
                if Calendar.current.isDateInToday(date){
                    totalBlockedSites = count
                }
            }
        }
        totalBlockedSites += 1
        UserDefaults.standard.set(["date": Date(), "count": totalBlockedSites], forKey: kUserdefaultsTotalDistractingSitesBlocked)
        
        
        if !SettingsManagerObject.immediatelyBlockDistractingSites{
            var isUrlAllreadyChecked = false
            var isUrlAllreadyCheckedIndex = 0
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        isUrlAllreadyChecked = true
                        isUrlAllreadyCheckedIndex = i
                        break;
                    }
                }
                
            }
            if isUrlAllreadyChecked == false{
                arrAlwaysBlockedSitesData.append(["url": url, "isBlocked": true, "intention" : "", "closed":false])
            }else{
                arrAlwaysBlockedSitesData[isUrlAllreadyCheckedIndex] = ["url": url, "isBlocked": true, "intention" : "", "closed":false]
            }
        }
    }
    
    
    func saveIntentionForBlockedUrl(url: String, script: String, browser: BROWSER?, intention:String, seconds:Int, currentPid: pid_t?){
        let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
        
        var isUrlAllreadyChecked = false
        var isUrlAllreadyCheckedIndex = 0
        for i in 0..<arrAlwaysBlockedSitesData.count{
            let dictionary = arrAlwaysBlockedSitesData[i]
            if let blockUrl = dictionary["url"] as? String{
                if blockUrl.lowercased() == url.lowercased(){
                    isUrlAllreadyChecked = true
                    isUrlAllreadyCheckedIndex = i
                    break;
                }
            }
            
        }
        if isUrlAllreadyChecked{
            arrAlwaysBlockedSitesData[isUrlAllreadyCheckedIndex] = ["url": url, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds]
        }else{
            arrAlwaysBlockedSitesData.append(["url": url, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds])
        }
        
        lastFrontMostApplication?.activate()
    }
    
    func saveIntentionForBlockedApp(intention:String, seconds:Int, runningApp: NSRunningApplication, appName:String){
        let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
        
        var isUrlAllreadyChecked = false
        var isUrlAllreadyCheckedIndex = 0
        for i in 0..<arrAlwaysBlockedAppsData.count{
            let dictionary = arrAlwaysBlockedAppsData[i]
            if let app = dictionary["app"] as? String{
                if app.lowercased() == appName.lowercased(){
                    isUrlAllreadyChecked = true
                    isUrlAllreadyCheckedIndex = i
                    break;
                }
            }
            
        }
        
        if isUrlAllreadyChecked{
            arrAlwaysBlockedAppsData[isUrlAllreadyCheckedIndex] = ["app": appName, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds]
        }else{
            arrAlwaysBlockedAppsData.append(["app": appName, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds])
        }
        showIntentionBlockedAppsWindow(currentApp: runningApp, blockedAppName: appName, intention: intention)
    }
    
    func startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl:Bool){
        addLog(text:"start Timer Activities AllowedApp")
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
            if currentHabitPlaying?.run_micro_breaks ?? false{
                addLog(text:"set activity timer from morning/evening activity allowed app")
                if !(getHabitsVcObject().isBreakActivityPostponeInsideAllowedHabit ?? false){
                    getHabitsVcObject().setActivityTimer()
                }else{
                    addLog(text:"set activity timer from morning/evening activity allowed app:- break activity postpone, do not reset activity timer")
                }
            }
            
            
            if isAnyAllowedFocusModeActivityRunning{
                if let focusAlignmentScore = currentRunningFocusType["focusAlignmentScoreThreshold"] as? Int{
                    minFocusAlignmentScoreToShowDistractingPopUp = Double(focusAlignmentScore)
                }else{
                    defaultFocusAlignmentScoreToShowDistractingPopUp = 80
                    minFocusAlignmentScoreToShowDistractingPopUp = Double(defaultFocusAlignmentScoreToShowDistractingPopUp)
                }
                if SettingsManagerObject.isDataCollectionModeEnabled{
                    minFocusAlignmentScoreToShowDistractingPopUp = 0
                }
                lastFocusAlignmentShownScore = minFocusAlignmentScoreToShowDistractingPopUp
                
            }
            
            
        }
        DispatchQueue.global().sync {
            self.timerAllowAppForActivity?.invalidate()
            self.timerAllowAppForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkActivityAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerAllowAppForActivity!), forMode: RunLoop.Mode.common)
            
        }
        setDocBarTo(isHide: true)
        if shouldLaunchAppAndUrl{
            var isSpecialHabitGoing = false
            var isSpecialActivityGoing = false
            
            if currentState == ._SPECIAL_ACTIVITY_{
                if timerViewcontrollerObj?.lastCurrentSpecialHabit != nil{
                    isSpecialHabitGoing = true
                }else{
                    isSpecialActivityGoing = true
                }
            }
            
            if currentState == ._MICRO_BREAK_ || isSpecialActivityGoing{
                showPopUpCheckListWindow(title: currentActivityPlaying?.name ?? "", list: currentActivityPlaying?.checkList ?? [])
                if let apps = currentActivityPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
                        
                        
                    }
                }else{
                    
                }
                if let urls = currentActivityPlaying?.allowUrls{
                    if urls.count != 0{
                        if var url = urls.first{
                            if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                                url = "http://"+url
                            }
                            NSWorkspace.shared.open(URL(string: url)!)
                        }
                    }else{
                        
                    }
                }
            }else if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_ || isSpecialHabitGoing || currentState == ._CUSTOM_ROUTINE_{
                showPopUpCheckListWindow(title: currentHabitPlaying?.name ?? "", list: currentHabitPlaying?.checkList ?? [])
                if let apps = currentHabitPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
                        
                    }
                }else{
                    
                }
                
                if let urls = currentHabitPlaying?.allowUrls{
                    if urls.count != 0{
                        if var url = urls.first{
                            if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                                url = "http://"+url
                            }
                            NSWorkspace.shared.open(URL(string: url)!)
                        }
                    }else{
                        
                    }
                }
                
            }
        }
        
    }
    
    @objc func checkActivityAllowedApp(){
        if (currentState == ._MICRO_BREAK_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    let localizedNameLowercased = runningApp.localizedName?.lowercased()

                    // A restored habit may already have Chrome frontmost, with no activation event.
                    // App allow rules must still start the independent website restriction timer.
                    habitBlockTimerHelper.startUrlTimer(browserName: name)
                    
                    if name == selfAppName.lowercased() || name == focusBearTimeTrackerAppName{
                        return;
                    }
                    
                    for path in SettingsManagerObject.effectiveAlwaysAllowedApps{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                            DispatchQueue.main.async {
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                            }
                            return;
                        }
                    }
                    
                    var isAppAllowed = false
                    if isAnyAllowedFocusModeActivityRunning{
                        let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                        if isAllowedAllAppsInFocus{
                            
                            if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                let arrBlockedApps = getBlockedAppsToBlock()
                                addLog(text: "app is:- \(name)") // need to delete in next  build
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if result{// it means not allowed by user(intention is not set)
                                            closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        return;
                                    }
                                }
                            }
                            return;
                        }
                        var isSelfApp = false
                        var isAppBlocked = false
                        
                        let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                        for path in blockAppsPath{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                isAppBlocked = true
                                break;
                            }
                        }
                        
                        
                        if isAllowedAllAppsInFocus{
                            isAppAllowed = true
                            if name == selfAppName.lowercased(){
                                isSelfApp = true
                            }
                        }else if name == selfAppName.lowercased(){
                            isSelfApp = true
                            isAppAllowed = true
                        }else if focusDefaultAllowApps.contains(name){//if name == "finder" || name == "universalaccessauthwarn"{
                            isAppAllowed = true
                        }else{
                            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                            if isRunningAppInAllowedApps(allowAppsPath, runningAppNameLowercased: name){
                                isAppAllowed = true
                            }
                        }
                        
                        if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                            isAppAllowed = true
                        }
                        
                        if !isAppAllowed{
                            var isAppAllowedByUser = false
                            let arrBlockedApps = getBlockedAppsToBlock()
                            
                            addLog(text: "app is:- \(name)") // need to delete in next  build
                            for path in arrBlockedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                    isAppAllowed = false
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                    let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                    if !result{// it means not allowed by user(intention is not set)
                                        isAppAllowedByUser = true
                                        isAppAllowed = true
                                    }
                                    if !isAppAllowedByUser{
                                        closeIntentionBlockedAppsWinddowIfVisible()
                                    }
                                    
                                    return;
                                }
                            }
                        }else{
                            if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                let arrBlockedApps = getBlockedAppsToBlock()
                                
                                addLog(text: "app is:- \(name)") // need to delete in next  build
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if result{// it means not allowed by user(intention is not set)
                                            closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        return;
                                    }
                                }
                            }
                        }
                        
                        if isAppBlocked{
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true, isAppBlockByAi: false)
                            habitBlockTimerHelper.stopUrlTimer()
                            return;
                        }else if !isAppAllowed{
                            focusTryToBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, appNameLowercased: name)
                            habitBlockTimerHelper.stopUrlTimer()
                            return
                        }else{
                            if isSelfApp{
                                return;
                            }
                            DispatchQueue.main.async {
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                            }
                        }
                    }else{
                        
                        if focusDefaultAllowApps.contains(name) || name == selfAppName.lowercased(){
                            isAppAllowed = true
                        }else{
                            var allowApps = [String]()
                            
                            if currentHabitPlaying != nil{
                                allowApps = currentHabitPlaying!.allowApps
                            }else if currentActivityPlaying != nil{
                                allowApps = currentActivityPlaying!.allowApps
                            }
                            
                            for appName in allowApps{
                                let allowAppLowercased = appName.lowercased()
                                if allowAppLowercased == name || allowAppLowercased == localizedNameLowercased{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                        }
                        
                        
                        
                        if !isAppAllowed{
                            exitFullScreen(runningApp:runningApp)
                            runningApp.hide()
                            allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
                            habitBlockTimerHelper.stopUrlTimer()
                            return
                        }
                        
                    }
                    
                }
            }
        }
        
        
        else{
            if self.timerAllowAppForActivity != nil{
                self.timerAllowAppForActivity!.invalidate()
            }
        }
    }
    
    
    func showExtraWindows(){
        guard checkIsFullScreenEnabled(), mainWindowControllerObj?.shouldCoverSecondaryScreens == true else {
            hideBlankWindowInSecondaryMonitor()
            return
        }
        let screenList = NSScreen.screens
        if screenList.count == 1{
            if arrWindows.count != 0{
                for i in 0..<arrWindows.count{
                    let window = arrWindows[i]
                    window.orderOut(nil)
                    arrWindows[i].windowController?.window = nil
                }
                arrWindows.removeAll()
            }
            return
        }
        if arrWindows.count == 0{
            // Cover every display except the one the routine is on — the same choice its frame uses.
            let host = mainWindowControllerObj?.fullScreenDisplay
            for screen in FullScreenDisplays.screensToCover(all: screenList, host: host) {
                let window = NSWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
                
                if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                    if state{
                        window.sharingType = .none
                    }
                }
                window.contentViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blankController")) as! blankController
                arrWindows.append(resetWin(window))
            }
            
        }
        
        if arrWindows.count == 0{
            return;
        }
        if !(arrWindows.first?.isVisible)!{
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
        self.perform(#selector(setframe), with: nil, afterDelay: 0)
    }
    
    @objc func setframe(){
        //let screenList = NSScreen.screens
        for i in 0..<arrWindows.count {  // create the corresponding windows
            let window = arrWindows[i]
            window.setFrame(NSMakeRect(NSMinX(window.screen!.frame), NSMinY(window.screen!.frame), NSWidth(window.screen!.frame), NSHeight(window.screen!.frame)), display: true)
        }
    }
    
    @objc func screenChanged() {  // call back for when the user reconfigured the Screen
        if !checkIsFullScreenEnabled(){
            return;
        }
        if isMainWindowLoaded{
            if let window = mainWindowControllerObj?.window, window.isVisible,
               mainWindowControllerObj?.isFullScreenVisible == true {
                // Resize to the screen this window is actually ON. This used to take NSScreen.screens
                // first entry and place the window at a hardcoded (0, 0) — so on a multi-display setup
                // a screen reconfiguration gave the window the PRIMARY display's height while it sat on
                // another one. With a tall external next to a short laptop screen that is exactly the
                // reported "window suddenly got super tall and I couldn't see the bottom" (report
                // 2026-06-25_17-24-22): too tall for the display showing it, and its origin dragged to
                // the primary's. Non-primary screens have non-zero origins, which (0, 0) threw away.
                let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first
                if let screen = screen {
                    window.setFrame(screen.frame, display: true)
                }
                for i in 0..<arrWindows.count{
                    let window = arrWindows[i]
                    window.orderOut(nil)
                    arrWindows[i].windowController?.window = nil
                }
                arrWindows.removeAll()
                showExtraWindows()
            }
        }
    }
    
    var timerPomodoroMode: Timer?
    //Called when the "Take a five minute break" button is clicked.
    func setTimerForPomodoroMode(delay:TimeInterval){
        if isAppEnable{
            DispatchQueue.global().sync{
                if self.timerPomodoroMode != nil{
                    self.timerPomodoroMode?.invalidate()
                    self.timerPomodoroMode = nil
                }
                self.timerPomodoroMode = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(self.showAutoPomodoroModeView), userInfo: nil, repeats: false)
                RunLoop.main.add((timerPomodoroMode!), forMode: RunLoop.Mode.common)
            }
            
        }
    }
    
    
    func renewToken(window: NSWindow, completionHandler: @escaping () -> ()) {
        addLog(text: "renewToken")
        let maxRetryCount = 3
        var retryCount = 0
        
        func attemptRenewal() {
            Auth0
                .authentication()
                .renew(withRefreshToken: credential?.refreshToken ?? "")
                .start { result in
                    switch result {
                    case .success(let credentials):
                        let oldDaysLeft = daysLeft
                        daysLeft = 0
                        isPurchased = false
                        
                        let _ = self.credentialsManager.store(credentials: credentials)
                        self.credential = credentials
                        self.user = AuthUser(from: self.credential!.accessToken)
                        
                        if let subscriptionStatus = self.user?.subscriptionStatus {
                            addLog(text: "subscriptionStatus is:- \(subscriptionStatus)")
                            var activeEntitlementStatus = ""
                            if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String],
                               let status = activeEntitlements.first {
                                activeEntitlementStatus = status
                                isPurchased = ["personal", "team_member", "team_owner", "team_size_5"].contains(status)
                            }
                            if let expirations = subscriptionStatus["expirations"] as? [String: Any],
                               let trial = expirations[activeEntitlementStatus] as? [String: Any],
                               let days_left = trial["days_left"] as? Int {
                                daysLeft = days_left
                            }
                        } else {
                            addLog(text: "subscriptionStatus is:- nil")
                        }
                        
                        if oldDaysLeft > 0 {
                            if !isPurchased && daysLeft == 0 {
                                addLog(text: "Subscription over")
                                DispatchQueue.main.async { self.quitAndRestartApp() }
                            }
                        } else {
                            if daysLeft > 0 {
                                addLog(text: "Purchases found")
                                DispatchQueue.main.async { self.quitAndRestartApp() }
                            } else {
                                DispatchQueue.main.async {
                                    let alert = NSAlert()
                                    alert.setSharingType()
                                    var noPurchasesFoundText = "No active purchases found for your account."
                                    addLog(text: "No purchases found.")
                                    if let common = configjson.value(forKey: "common") as? NSDictionary {
                                        noPurchasesFoundText = common.value(forKey: "noPurchasesFoundText") as? String ?? noPurchasesFoundText
                                    }
                                    alert.messageText = noPurchasesFoundText
                                    alert.addButton(withTitle: buttonOkText)
                                    alert.beginSheetModal(for: window, completionHandler: nil)
                                }
                            }
                        }
                        if !isPurchased && daysLeft == 0 {
                            isExpired = true
                        }
                        completionHandler()
                        
                    case .failure(let error):
                        let nsError = error as NSError
                        addLog(text: "renewToken failed with error code: \(nsError.code)")
                        
                        if (500...599).contains(nsError.code) {
                            retryCount += 1
                            if retryCount < maxRetryCount {
                                addLog(text: "Retrying renewToken, attempt \(retryCount + 1)")
                                print("Retrying renewToken, attempt \(retryCount + 1)")
                                attemptRenewal()
                            } else {
                                showErrorAlert()
                            }
                        } else {
                            showErrorAlert()
                        }
                        
                        func showErrorAlert() {
                            DispatchQueue.main.async {
                                let alert = NSAlert()
                                alert.setSharingType()
                                alert.messageText = "Failed to renew token. Please check your network or try again later. If you are definitely online and are getting this error, please contact support@focusbear.io"
                                if let common = configjson.value(forKey: "common") as? NSDictionary {
                                    alert.messageText = common.value(forKey: "syncErrorAlertText") as? String ?? alert.messageText
                                }
                                alert.informativeText = error.localizedDescription
                                alert.addButton(withTitle: buttonOkText)
                                alert.beginSheetModal(for: window, completionHandler: nil)
                            }
                            completionHandler()
                        }
                    }
                }
        }
        
        attemptRenewal()
    }
    
    @IBAction func menuItemUninstallClicked(_ sender: Any) {
        if askLogInWcObj?.window != nil{
            if askLogInWcObj?.window?.isVisible ?? false{
                addLog(text: "[user-action] menu Item Uninstall Clicked")
                if uninstallingConfirmVcObj == nil{
                    uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
                }
                askLogInWcObj?.contentViewController?.presentAsSheet(uninstallingConfirmVcObj!)
            }
        }
    }

}
#if DEBUG
// MARK: - Claude debug task (one user only)
//
// Adds a Help-menu item that bundles the current debug logs into a timestamped folder and writes a
// TASK.md describing the issue, ready to hand to Claude. Gated to a single user ID AND compiled out of
// Release builds, so it never appears for anyone else.
final class ClaudeDebugTaskMenu: NSObject {
    static let shared = ClaudeDebugTaskMenu()
    private static let allowedUserId = "9884b0af-dc9f-4207-964e-e4db537a2234"
    private static let menuTitle = "Create Claude debug task…"

    /// Installs the Help-menu item if the logged-in user matches. Idempotent.
    static func installIfAllowed() {
        guard (appdelegate?.user?.userId ?? "") == allowedUserId else { return }
        guard let helpMenu = NSApp.mainMenu?.items.compactMap({ $0.submenu }).first(where: { $0.title == "Help" }) else { return }
        guard !helpMenu.items.contains(where: { $0.title == menuTitle }) else { return }
        helpMenu.addItem(.separator())
        let item = NSMenuItem(title: menuTitle, action: #selector(shared.createTask), keyEquivalent: "")
        item.target = shared
        helpMenu.addItem(item)
    }

    @objc func createTask() {
        // Ask what Claude should look into.
        let alert = NSAlert()
        alert.messageText = "Create a Claude debug task"
        alert.informativeText = "Describe what went wrong / what Claude should investigate. The current logs are bundled into a folder with this note."
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 380, height: 110))
        textView.font = .systemFont(ofSize: 12)
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 380, height: 110))
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        alert.accessoryView = scroll
        alert.window.initialFirstResponder = textView
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let note = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)

        let fm = FileManager.default
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let stamp = f.string(from: Date())
        let folder = fm.homeDirectoryForCurrentUser.appendingPathComponent("FocusBear-Claude-Tasks/\(stamp)")
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)

        // Bundle the debug logs.
        var copied: [String] = []
        if let logsURL = DebugLogsFolderURL,
           let items = try? fm.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: nil) {
            let logsDst = folder.appendingPathComponent("logs")
            try? fm.createDirectory(at: logsDst, withIntermediateDirectories: true)
            for src in items where src.pathExtension == "txt" {
                let dst = logsDst.appendingPathComponent(src.lastPathComponent)
                try? fm.copyItem(at: src, to: dst)
                copied.append("logs/\(src.lastPathComponent)")
            }
        }

        let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? appVersion
        let build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? ""
        let task = """
        # Focus Bear — Claude debug task

        - Created: \(stamp)
        - App version: \(version) (\(build))
        - User: \(appdelegate?.user?.userId ?? "")

        ## What to investigate
        \(note.isEmpty ? "_(no description provided)_" : note)

        ## Logs
        \(copied.isEmpty ? "_(no logs found)_" : copied.map { "- \($0)" }.joined(separator: "\n"))

        ---
        Hand this to Claude with: "work on the task in \(folder.path)"
        """
        try? task.write(to: folder.appendingPathComponent("TASK.md"), atomically: true, encoding: .utf8)
        // Intentionally not revealing the folder in Finder — repeated reports piled up windows for
        // the user to close. The report still lands in ~/FocusBear-Claude-Tasks for Claude to pick up.
    }
}
#endif
