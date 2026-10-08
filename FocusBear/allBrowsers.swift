//
//  allBrowsers.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation
import Combine

/// A missing AppleScript descriptor can still carry a real Automation denial. Interpret the
/// error before the optional value so callers never mistake revoked access for an empty tab.
enum BrowserScriptStringResult: Equatable {
    case value(String)
    case automationDenied(application: String)
    case unavailable

    static func interpret(value: String?, hasDescriptor: Bool, errors: NSDictionary?) -> Self {
        let number = (errors?["NSAppleScriptErrorNumber"] as? NSNumber)?.intValue
            ?? Int(errors?["NSAppleScriptErrorNumber"] as? String ?? "")
        if number == -1743 {
            return .automationDenied(application: errors?["NSAppleScriptErrorAppName"] as? String ?? "")
        }
        guard hasDescriptor else { return .unavailable }
        // A browser profile picker can have a descriptor with no string. Preserve its existing
        // empty-tab behavior; it is not evidence that Automation permission was denied.
        return .value(value ?? "")
    }
}

/// Shared by successful reads and explicit denials. Returns nil for an unchanged record so
/// a one-second browser poll does not repeatedly write preferences or emit the same warning.
enum BrowserPermissionRecords {
    static func updating(_ rows: [[String: Any]], browser: BROWSER, enabled: Bool) -> [[String: Any]]? {
        var updated = rows
        if let index = updated.firstIndex(where: { ($0["browser"] as? Int) == browser.rawValue }) {
            guard (updated[index]["isEnabled"] as? Bool) != enabled else { return nil }
            updated[index]["isEnabled"] = enabled
        } else {
            updated.append(["browser": browser.rawValue, "isEnabled": enabled])
        }
        return updated
    }
}

/// Only explicit denial evidence belongs here. An unconfigured browser or a timed-out read is
/// unknown; neither should tell the user that macOS has denied access.
struct BrowserAutomationDenials {
    private(set) var browsers: Set<BROWSER> = []

    @discardableResult
    mutating func record(browser: BROWSER, enabled: Bool) -> Bool {
        if enabled { return browsers.remove(browser) != nil }
        return browsers.insert(browser).inserted
    }
}

final class BrowserAutomationStatus: ObservableObject {
    static let shared = BrowserAutomationStatus()
    @Published private(set) var deniedBrowsers: Set<BROWSER> = []
    private var evidence = BrowserAutomationDenials()

    /// Called only on the main queue by the serialized preference update below.
    fileprivate func record(browser: BROWSER, enabled: Bool) -> Bool {
        guard evidence.record(browser: browser, enabled: enabled) else { return false }
        deniedBrowsers = evidence.browsers
        return true
    }
}

func recordBrowserAutomationPermission(browser: BROWSER, enabled: Bool) {
    // Browser reads run on different queues; update their shared preference snapshot serially.
    let update = {
        let changed = BrowserAutomationStatus.shared.record(browser: browser, enabled: enabled)
        let rows = UserDefaults.standard.array(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String: Any]] ?? []
        if let updated = BrowserPermissionRecords.updating(rows, browser: browser, enabled: enabled) {
            UserDefaults.standard.set(updated, forKey: kUserdefaultsAllBrowsersPermissionInfo)
        }
        // Runtime evidence has its own deduplication: the first denial must still be reported if
        // an earlier app launch already persisted isEnabled=false for this browser.
        if changed {
            addLog(text: "browser Automation permission: browser=\(browser.rawValue) available=\(enabled)\(enabled ? "" : " error=-1743; URL checks cannot run until Automation access is restored")")
        }
    }
    if Thread.isMainThread { update() } else { DispatchQueue.main.async(execute: update) }
}

/// Run an AppleScript source and return its result descriptor, ALWAYS on the main thread.
/// NSAppleScript is not thread-safe; executing it on a background queue (e.g. the URL/tab timer)
/// intermittently segfaults inside Apple's AppleScript compiler — that was the browser-tab-count crash.
/// Routes through `runAppleScriptSafely`, the single serialised AppleScript entry point, so browser
/// scripts never execute concurrently with other NSAppleScript on a different thread. NSAppleScript
/// is not thread-safe: running browser scripts on the main thread (as this used to) while other
/// scripts ran on the AppleScript serial queue segfaulted inside Apple's AppleScript compiler
/// (EXC_BAD_ACCESS during compile). The `with timeout` guard (#1950) prevents hangs but not that
/// crash — serialising every NSAppleScript execution onto one queue does.
func runBrowserAppleScript(_ source: String, timeoutSeconds: Int = 5, authorization: @escaping () -> Bool = { true }, logErrors: Bool = true) -> NSAppleEventDescriptor? {
    var errors: NSDictionary?
    let desc = runAppleScriptSafely(source, timeoutSeconds: timeoutSeconds, errors: &errors, authorization: authorization)
    if case .automationDenied(let application) = BrowserScriptStringResult.interpret(
        value: desc?.stringValue, hasDescriptor: desc != nil, errors: errors),
       let browser = getCurrentBrowserFrom(browserName: application.lowercased()) {
        // Tab-count reads can precede the URL read. Surface their confirmed denials too, without
        // printing the same AppleScript dictionary every timer tick.
        recordBrowserAutomationPermission(browser: browser, enabled: false)
    } else if logErrors && errors != nil {
        print(errors as Any)
    }
    return desc
}

//*****************all browsers Active Tab Url and Titlle*********************//

enum BROWSER:Int{
    case _GOOGLE_CHROME_ = 152, _SAFARI_, _BRAVE_BROWSER_, _SIDEKICK_, _MICROSOFT_EDGE_, _ARC_, _FIREFOX_, _OPERA_, _VIVALDI_, _OPERA_GX_, _SIGMA_OS_, _COMET_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai"
}
var sigmaOsBrowserName = "SigmaOS" // SigmaOS_latest
var arrBrowsersLowerCasedNames = ["safari", "google chrome", "sidekick", "brave browser", "microsoft edge", "arc", "firefox", "opera", "vivaldi", "opera gx", "sigmaos", "sigmaos_latest", "comet"]//if any change in this array, should also change in browsers list in onboardingcontrollingbrowservc

func getBrowserAllTabUrl(browser:BROWSER)->[String]?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    // Don't script an ungranted browser (the meeting-detection timer calls this every few seconds,
    // so it would loop the OS consent dialog); raise the one-time consent prompt instead.
    if shouldSkipBrowserAppleEvent(browser) {
        requestBrowserAutomationOnceIfNeeded(browser)
        return nil
    }
    var browserName = ""
    
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._FIREFOX_{
        if let url = getFirefoxActiveTabUrl(){
            return [url]
        }
    }else if browser == ._SIGMA_OS_{
        if let url = getSigmaOSBrowserActiveTabUrl(){
            return [url]
        }
    }else if browser == ._COMET_{
        browserName = "Comet"
    }
    
    var script: String = ""
    
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set end of arrayTabs to URL of theTab
        end repeat
        return arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set the_wnd to front window
        set allTabs to tabs in the_wnd
        set arrayTabs to {}
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set end of arrayTabs to taburl
        end repeat
        return the arrayTabs
        end tell
        """
    }
    
    
    if let desc = runBrowserAppleScript(script) {
        return desc.toStringArray()
    }
    return nil
}


func getBrowserAllTabUrlAndTitle(browser:BROWSER)->[(title: String, url: String)]?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    // Same gate as getBrowserAllTabUrl — don't loop the consent dialog for an ungranted browser.
    if shouldSkipBrowserAppleEvent(browser) {
        requestBrowserAutomationOnceIfNeeded(browser)
        return nil
    }
    var browserName = ""
    
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._FIREFOX_{
        if let url = getFirefoxActiveTabUrl(), let title = getFirefoxActiveTabTitle(){
            return [(title, url)]
        }
    }else if browser == ._SIGMA_OS_{
        if let url = getSigmaOSBrowserActiveTabUrl(), let title = getSigmaOSBrowserActiveTabTitle(){
            return [(title, url)]
        }
    }else if browser == ._COMET_{
        browserName = "Comet"
    }
    

    
    
    var script: String = ""
    
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set tabTitle to title of theTab
        set tabURL to URL of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        return arrayTabs
        end tell
        """
    }else if browser == ._SAFARI_{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayTabs to {}
        repeat with the_wnd in allWinds
        set allTabs to tabs in the_wnd
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set tabTitle to name of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        end repeat
        return the arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayTabs to {}
        repeat with the_wnd in allWinds
        set allTabs to tabs of the_wnd
        repeat with theTab in allTabs
        set tabTitle to title of theTab
        set tabURL to URL of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        end repeat
        return arrayTabs
        end tell
        """
    }
    

    
    
    if let desc = runBrowserAppleScript(script) {
        return desc.toTwoColumnStringArray()
    }
    return nil
}



/// Whether the per-second "what is the active tab?" AppleScript is actually answering.
///
/// Report 2026-09-11_16-56-33 ("it's not blocking anything"): the read started returning nil after
/// the screen locked, and kept doing so for three hours. Nothing was logged — `getActiveTabUrl` was
/// called every second, no URL ever came back, so `focusTryToBlockUnwantedUrl` was never reached and
/// every site stayed open — while the menu's own self-check still reported no blocking issue.
///
/// A single nil is normal (a browser window closing, a slow tab, a script that timed out once), so
/// only a run of failures counts, and the state is reported once per transition rather than per tick.
struct BrowserUrlReadHealth: Equatable {
    /// Consecutive failures before the reads are called broken — at one read per second, a handful
    /// of ticks is long enough to rule out a single slow answer.
    static let failureThreshold = 8
    private(set) var consecutiveFailures = 0
    private(set) var isFailing = false
    private(set) var failingSince: Date?

    /// Records one read. Returns true when this read changed the verdict, so the caller logs the
    /// transition instead of every tick.
    @discardableResult
    mutating func record(succeeded: Bool, at now: Date = Date()) -> Bool {
        if succeeded {
            consecutiveFailures = 0
            guard isFailing else { return false }
            isFailing = false; failingSince = nil
            return true
        }
        consecutiveFailures += 1
        guard !isFailing, consecutiveFailures >= Self.failureThreshold else { return false }
        isFailing = true; failingSince = now
        return true
    }
}

private let browserUrlReadHealthLock = NSLock()
private var browserUrlReadHealthStorage = BrowserUrlReadHealth()

/// True when the active-tab reads have been failing long enough to be a real fault, not a blip.
var isBrowserUrlReadFailing: Bool {
    browserUrlReadHealthLock.lock(); defer { browserUrlReadHealthLock.unlock() }
    return browserUrlReadHealthStorage.isFailing
}

func recordBrowserUrlRead(succeeded: Bool, browser: BROWSER) {
    browserUrlReadHealthLock.lock()
    let changed = browserUrlReadHealthStorage.record(succeeded: succeeded)
    let failing = browserUrlReadHealthStorage.isFailing
    let failures = browserUrlReadHealthStorage.consecutiveFailures
    browserUrlReadHealthLock.unlock()
    guard changed else { return }
    addLog(text: failing
           ? "browser url read: FAILING after \(failures) consecutive empty reads (browser=\(browser)) — websites cannot be checked"
           : "browser url read: recovered (browser=\(browser))")
}

func getActiveTabUrlForBlocking(browser:BROWSER)->String?{
    addLog(text:"func call:- getActiveTabUrlForBlocking")

    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        addLog(text:"Browsers Permissions is not Set By User return;")
        return nil
    }
    // This is the variant the always-on suggest/block timers use (getURLSafeInBackground). Don't
    // script an ungranted browser (its consent dialog would loop); instead raise the consent prompt
    // exactly once (blocking, so it waits for the answer rather than re-firing).
    if shouldSkipBrowserAppleEvent(browser) {
        requestBrowserAutomationOnceIfNeeded(browser)
        return nil
    }
    var url:String?
    if browser == ._SAFARI_{
        url = getSafariActiveTabUrl()
    }else if browser == ._GOOGLE_CHROME_{
        url = getGoogleChromeActiveTabUrl()
    }else if browser == ._OPERA_{
        url = getOperaActiveTabUrl()
    }else if browser == ._OPERA_GX_{
        url = getOperaGxActiveTabUrl()
    }else if browser == ._VIVALDI_{
        url = getVivaldiActiveTabUrl()
    }else if browser == ._BRAVE_BROWSER_{
        url = getBraveBrowserActiveTabUrl()
    }else if browser == ._SIDEKICK_{
        url = getSidekickBrowserActiveTabUrl()
    }else if browser == ._MICROSOFT_EDGE_{
        url = getMicrosoftEdgeActiveTabUrl()
    }else if browser == ._ARC_{
        url = getArcBrowserActiveTabUrl()
    }else if browser == ._FIREFOX_{
        url = getFirefoxActiveTabUrl()
    }else if browser == ._SIGMA_OS_{
        url = getSigmaOSBrowserActiveTabUrl()
    }else if browser == ._COMET_{
        url = getCometActiveTabUrl()
    }

    // check which browser is allowed in automation
    if url != nil{
        recordBrowserAutomationPermission(browser: browser, enabled: true)
    }else if browser == ._FIREFOX_{// may be extension not installed. for old users because from now firefox blocking is based on extension v 2.27.435
        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
            for i in 0..<arrBrowsersInfo.count{
                let info = arrBrowsersInfo[i]
                let browserRawValue = info["browser"] as? Int ?? 0
                if browser.rawValue == browserRawValue{
                    arrBrowsersInfo[i]["isEnabled"] = false
                    break;
                }
            }
            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
        }
    }
    if let url = url{
        if url.isEmpty{
            addLog(text:"url is empty return;")
            recordBrowserUrlRead(succeeded: false, browser: browser)
            return nil;  //is blank then return nil so we will not read this // 26/4/25
        }
    }
    recordBrowserUrlRead(succeeded: url != nil, browser: browser)
    return url
}


/// True while an explicit "Request Permission" flow is showing the blocking OS Automation consent
/// dialog for a browser. While set, passive URL probes below are skipped so they can't tear down the
/// pending dialog (AEDetermine/AppleScript against the same target would). See permissionsVc /
/// onboardingControllingBrowserVc, which request permission via AEDeterminePermissionToAutomateTarget.
var isBrowserAutomationRequestInFlight = false

/// Whether the user has granted automation for `browser`, per the app's OWN permission store
/// (kUserdefaultsAllBrowsersPermissionInfo, isEnabled per browser — set when the user grants via the
/// Request-Permission flow). This is a plain UserDefaults read: NO Apple Event, so it can't itself
/// trigger the OS Automation consent dialog (AEDeterminePermissionToAutomateTarget can, even with
/// askUserIfNeeded:false — which is exactly what we must avoid in the always-on probes).
func isBrowserPermissionGranted(_ browser: BROWSER) -> Bool {
    guard let arr = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String: Any]] else {
        return false
    }
    for info in arr {
        if (info["browser"] as? Int) == browser.rawValue {
            return info["isEnabled"] as? Bool ?? false
        }
    }
    return false
}

/// Whether we should NOT directly send a scripting Apple Event (get URL / get title) to `browser`
/// right now: either a consent request is already showing its dialog, or the user hasn't granted this
/// browser yet. Firefox is exempt (extension-based, no Apple Events). When this returns true the
/// caller should also give requestBrowserAutomationOnceIfNeeded() a chance to raise the one-time
/// consent prompt.
func shouldSkipBrowserAppleEvent(_ browser: BROWSER) -> Bool {
    if isBrowserAutomationRequestInFlight { return true }
    if browser == ._FIREFOX_ { return false }
    return !isBrowserPermissionGranted(browser)
}

/// Browsers we've already raised the automation consent prompt for this session (so a denial isn't
/// re-asked every tick). Reset on relaunch.
var browsersAutoPromptAttempted = Set<Int>()

/// Persist that `browser` is granted, in the app's own permission store.
func markBrowserGrantedInStore(_ browser: BROWSER) {
    var arr = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String: Any]] ?? []
    var found = false
    for i in 0..<arr.count {
        if (arr[i]["browser"] as? Int) == browser.rawValue {
            arr[i]["isEnabled"] = true
            found = true
            break
        }
    }
    if !found { arr.append(["browser": browser.rawValue, "isEnabled": true]) }
    UserDefaults.standard.set(arr, forKey: kUserdefaultsAllBrowsersPermissionInfo)
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil {
        UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
    }
}

/// For an ungranted browser, raise the OS Automation consent dialog exactly ONCE (this session) using
/// a BLOCKING AEDeterminePermissionToAutomateTarget(askUserIfNeeded:true): it shows the dialog and
/// waits for the user's answer, so — unlike sending the AppleScript and letting runAppleScriptSafely
/// time out — it never tears the dialog down and re-fires it in a loop. While it's up,
/// isBrowserAutomationRequestInFlight makes every probe skip. On allow we mark the browser granted so
/// blocking resumes; on deny we just don't ask again this session.
func requestBrowserAutomationOnceIfNeeded(_ browser: BROWSER) {
    if browser == ._FIREFOX_ || UITestHost.suppressesEnforcement { return }
    if isBrowserAutomationRequestInFlight { return }
    if isBrowserPermissionGranted(browser) { return }
    if browsersAutoPromptAttempted.contains(browser.rawValue) { return }
    let appName = getCurrentBrowserNameFrom(browser: browser) ?? ""
    let bundleId = appName.isEmpty ? "" : (Bundle(path: "/Applications/\(appName).app")?.bundleIdentifier ?? "")
    guard !bundleId.isEmpty else { return }
    browsersAutoPromptAttempted.insert(browser.rawValue)
    isBrowserAutomationRequestInFlight = true
    DispatchQueue.global().async {
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleId)
        let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
        DispatchQueue.main.async {
            isBrowserAutomationRequestInFlight = false
            if status == noErr {
                markBrowserGrantedInStore(browser)
                addLog(text: "Automation granted for \(browser) via one-time prompt")
            } else {
                addLog(text: "Automation not granted for \(browser) (status \(status)) — won't re-prompt this session")
            }
        }
    }
}

func getActiveTabUrlOf(browser:BROWSER)->String?{
    addLog(text:"func call:- getActiveTabUrl")

    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        addLog(text:"Browsers Permissions is not Set By User return;")
        return nil
    }
    // Don't script an ungranted browser (its consent dialog would loop); raise the consent prompt
    // exactly once instead — see requestBrowserAutomationOnceIfNeeded.
    if shouldSkipBrowserAppleEvent(browser) {
        requestBrowserAutomationOnceIfNeeded(browser)
        return nil
    }
    var url:String?
    if browser == ._SAFARI_{
        url = getSafariActiveTabUrl()
    }else if browser == ._GOOGLE_CHROME_{
        url = getGoogleChromeActiveTabUrl()
    }else if browser == ._OPERA_{
        url = getOperaActiveTabUrl()
    }else if browser == ._OPERA_GX_{
        url = getOperaGxActiveTabUrl()
    }else if browser == ._VIVALDI_{
        url = getVivaldiActiveTabUrl()
    }else if browser == ._BRAVE_BROWSER_{
        url = getBraveBrowserActiveTabUrl()
    }else if browser == ._SIDEKICK_{
        url = getSidekickBrowserActiveTabUrl()
    }else if browser == ._MICROSOFT_EDGE_{
        url = getMicrosoftEdgeActiveTabUrl()
    }else if browser == ._ARC_{
        url = getArcBrowserActiveTabUrl()
    }else if browser == ._FIREFOX_{
        url = getFirefoxActiveTabUrl()
    }else if browser == ._SIGMA_OS_{
        url = getSigmaOSBrowserActiveTabUrl()
    }else if browser == ._COMET_{
        url = getCometActiveTabUrl()
    }

    //--------------------------------------------//
    // A real URL read is the evidence that clears an earlier Automation denial.
    if url != nil {
        recordBrowserAutomationPermission(browser: browser, enabled: true)
    }
    if let url = url{
        if url.isEmpty{
            addLog(text:"url is empty return;")
            return nil;  //is blank then return nil so we will not read this // 26/4/25
        }
    }
    return url
}

func getActiveTabTitleOf(browser:BROWSER)->String?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    // Same gate as getActiveTabUrlOf — the always-on suggest-focus / focus timers call this every
    // second, so an unauthorized browser would otherwise loop the OS Automation consent dialog.
    if shouldSkipBrowserAppleEvent(browser) {
        addLog(text:"getActiveTabTitle: skipping Apple Event for \(browser) (unauthorized or request in flight)")
        return nil
    }
    if browser == ._SAFARI_{
        return getSafariActiveTabTitle()
    }else if browser == ._GOOGLE_CHROME_{
        return getGoogleChromeActiveTabTitle()
    }else if browser == ._OPERA_{
        return getOperaActiveTabTitle()
    }else if browser == ._OPERA_GX_{
        return getOperaGxActiveTabTitle()
    }else if browser == ._VIVALDI_{
        return getVivaldiActiveTabTitle()
    }else if browser == ._BRAVE_BROWSER_{
        return getBraveBrowserActiveTabTitle()
    }else if browser == ._SIDEKICK_{
        return getSidekickBrowserActiveTabTitle()
    }else if browser == ._MICROSOFT_EDGE_{
        return getMicrosoftEdgeActiveTabTitle()
    }else if browser == ._ARC_{
        return getArcBrowserActiveTabTitle()
    }else if browser == ._FIREFOX_{
        return getFirefoxActiveTabTitle()
    }else if browser == ._SIGMA_OS_{
        return getSigmaOSBrowserActiveTabTitle()
    }else if browser == ._COMET_{
        return getCometActiveTabTitle()
    }
    return nil
}






/// Chrome can have several running instances (and cloned apps with its bundle ID).
/// Address the process explicitly; LaunchServices name resolution can select a background copy.
enum ChromeProcessTabs {
    private static let diagnosticLock = NSLock()
    private static var lastDiagnostic = ""
    private static func diagnostic(_ message: String) {
        diagnosticLock.lock()
        let changed = lastDiagnostic != message
        lastDiagnostic = message
        diagnosticLock.unlock()
        if changed { addLog(text: "Chrome tab snapshot: " + message) }
    }

    static func code(_ text: String) -> OSType {
        text.utf8.reduce(0) { ($0 << 8) | OSType($1) }
    }

    static var allItems: NSAppleEventDescriptor {
        // formAbsolutePosition requires typeAbsoluteOrdinal, not a generic enumerated value.
        NSAppleEventDescriptor(descriptorType: code("abso"), data: NSAppleEventDescriptor(enumCode: code("all ")).data)!
    }

    static func object(_ kind: String, form: String, key: NSAppleEventDescriptor,
                       container: NSAppleEventDescriptor = .null()) -> NSAppleEventDescriptor {
        let record = NSAppleEventDescriptor.record()
        record.setDescriptor(.init(typeCode: code(kind)), forKeyword: code("want"))
        record.setDescriptor(.init(enumCode: code(form)), forKeyword: code("form"))
        record.setDescriptor(key, forKeyword: code("seld"))
        record.setDescriptor(container, forKeyword: code("from"))
        return record.coerce(toDescriptorType: code("obj "))!
    }

    static func property(_ name: String, of object: NSAppleEventDescriptor) -> NSAppleEventDescriptor {
        self.object("prop", form: "prop", key: .init(typeCode: code(name)), container: object)
    }

    static func send(pid: pid_t, object: NSAppleEventDescriptor, command: String = "getd", timeout: TimeInterval = 1) throws -> NSAppleEventDescriptor {
        let event = NSAppleEventDescriptor(eventClass: code("core"), eventID: code(command),
            targetDescriptor: .init(processIdentifier: pid), returnID: -1, transactionID: 0)
        event.setParam(object, forKeyword: code("----"))
        let reply = try event.sendEvent(options: [.waitForReply, .neverInteract], timeout: timeout)
        if let error = reply.paramDescriptor(forKeyword: code("errn")), error.int32Value != 0 {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(error.int32Value))
        }
        return reply.paramDescriptor(forKeyword: code("----")) ?? .null()
    }

    static func isUserBrowser(bundleIdentifier: String?, bundleName: String?,
                              activationPolicy: NSApplication.ActivationPolicy, arguments: [String] = []) -> Bool {
        // Headless Chrome registers the same bundle/path but cannot present a user interface.
        // Its automation tabs must not consume the user's tab allowance.
        bundleIdentifier == "com.google.Chrome" && bundleName == "Google Chrome.app" &&
            activationPolicy != .prohibited && !arguments.contains { $0 == "--headless" || $0.hasPrefix("--headless=") }
    }

    /// Headless Chrome can become a regular NSRunningApplication after automation. Read argv,
    /// not its UI policy alone. Never log the arguments (they can include private URLs).
    static func processArguments(_ pid: pid_t) -> [String] {
        var mib: [Int32] = [CTL_KERN, KERN_PROCARGS2, pid]
        var size = 0
        guard sysctl(&mib, 3, nil, &size, nil, 0) == 0, size > 4, size <= 1_048_576 else { return [] }
        var data = Data(count: size)
        let result = data.withUnsafeMutableBytes { sysctl(&mib, 3, $0.baseAddress, &size, nil, 0) }
        guard result == 0 else { return [] }
        return decodeProcessArguments(data.prefix(size))
    }

    static func decodeProcessArguments(_ data: Data) -> [String] {
        guard data.count > 4 else { return [] }
        let argc = data.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        guard argc > 0, argc < 65536 else { return [] }
        let bytes = Array(data.dropFirst(4))
        guard let executableEnd = bytes.firstIndex(of: 0) else { return [] }
        var cursor = executableEnd + 1
        while cursor < bytes.count && bytes[cursor] == 0 { cursor += 1 }
        var arguments: [String] = []
        for _ in 0..<argc {
            guard cursor < bytes.count, let end = bytes[cursor...].firstIndex(of: 0),
                  let value = String(bytes: bytes[cursor..<end], encoding: .utf8) else { return [] }
            arguments.append(value)
            cursor = end + 1
        }
        return arguments
    }

    static func applications() -> [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter {
            guard !$0.isTerminated,
                  isUserBrowser(bundleIdentifier: $0.bundleIdentifier, bundleName: $0.bundleURL?.lastPathComponent,
                                activationPolicy: $0.activationPolicy) else { return false }
            return isUserBrowser(bundleIdentifier: $0.bundleIdentifier, bundleName: $0.bundleURL?.lastPathComponent,
                activationPolicy: $0.activationPolicy, arguments: processArguments($0.processIdentifier))
        }
    }

    static func windows() -> [String: [String]]? {
        windows(processIDs: applications().map(\.processIdentifier)) { pid, object in
            try send(pid: pid, object: object)
        }
    }

    static func windows(processIDs: [pid_t], read: (pid_t, NSAppleEventDescriptor) throws -> NSAppleEventDescriptor) -> [String: [String]]? {
        guard !processIDs.isEmpty else { return nil }
        var result: [String: [String]] = [:]
        var stage = "windows"
        do {
            for pid in Set(processIDs).sorted() {
                stage = "pid=\(pid) window IDs"
                let allWindows = object("cwin", form: "indx", key: allItems)
                let ids = try read(pid, property("ID  ", of: allWindows))
                guard ids.descriptorType == code("list") else { diagnostic("\(stage) unexpected type=\(ids.descriptorType)"); return nil }
                for index in 0..<ids.numberOfItems {
                    guard let id = ids.atIndex(index + 1), let value = id.stringValue else { diagnostic("\(stage) missing ID value"); return nil }
                    let window = object("cwin", form: "ID  ", key: id)
                    let tabs = object("CrTb", form: "indx", key: allItems, container: window)
                    stage = "pid=\(pid) window=\(value) tab URLs"
                    let urls = try read(pid, property("URL ", of: tabs))
                    guard urls.descriptorType == code("list") else { diagnostic("\(stage) unexpected type=\(urls.descriptorType)"); return nil }
                    result["\(pid):\(value)"] = (0..<urls.numberOfItems).map {
                        urls.atIndex($0 + 1)?.stringValue ?? ""
                    }
                }
            }
            diagnostic("read \(result.count) windows across \(Set(processIDs).count) processes")
            return result
        } catch {
            diagnostic("\(stage) error=\((error as NSError).code)")
            if (error as NSError).code == -1743 {
                recordBrowserAutomationPermission(browser: ._GOOGLE_CHROME_, enabled: false)
            }
            return nil
        }
    }

    static func close(index: Int, windowKey: String) {
        let components = windowKey.split(separator: ":")
        guard components.count == 2, let pid = pid_t(components[0]),
              applications().contains(where: { $0.processIdentifier == pid }) else { return }
        let window = object("cwin", form: "ID  ", key: .init(string: String(components[1])))
        let tab = object("CrTb", form: "indx", key: .init(int32: Int32(index + 1)), container: window)
        do { _ = try send(pid: pid, object: tab, command: "clos") }
        catch {
            if (error as NSError).code == -1743 {
                recordBrowserAutomationPermission(browser: ._GOOGLE_CHROME_, enabled: false)
            }
        }
    }
}

func getAllBrowsersTabCount()->Int{
    var totalTabsCount = 0
    let runningApps = NSWorkspace.shared.runningApplications
    var isSafariRunning = false
    var isChromeRunning = false
    var isBraveRunning = false
    var isEdgeRunning = false
    var isSideKickRunning = false
    var isArcRunning = false
    var isOperaRunning = false
    var isVivaldiRunning = false
    var isOperaGxRunning = false
    var isCometRunning = false

    var countedBrowserNames: Set<String> = []
    for app in runningApps{
        guard app.activationPolicy != .prohibited else { continue }
        if let appUrl = app.bundleURL{
            let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
            guard countedBrowserNames.insert(nameLowercased).inserted else { continue }
            if nameLowercased == "safari"{
                let keys = safariWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = safariWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isSafariRunning = true
            }else if nameLowercased == "google chrome"{
                let keys = googleChromeWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = googleChromeWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isChromeRunning = true
            }else if nameLowercased == "opera"{
                let keys = operaWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = operaWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isOperaRunning = true
            }else if nameLowercased == "opera gx"{
                let keys = operaGxWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = operaGxWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isOperaGxRunning = true
            }else if nameLowercased == "vivaldi"{
                let keys = vivaldiWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = vivaldiWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isVivaldiRunning = true
            }else if nameLowercased == "brave browser"{
                let keys = braveBrowserWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = braveBrowserWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isBraveRunning = true
            }else if nameLowercased == "sidekick"{
                let keys = sidekickWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = sidekickWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isSideKickRunning = true
            }else if nameLowercased == "microsoft edge"{
                let keys = microsoftEdgeWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = microsoftEdgeWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isEdgeRunning = true
            }else if nameLowercased == "arc"{
                totalTabsCount += arcBrowserTabsInfo.count
                isArcRunning = true
            }else if nameLowercased == "comet"{
                let keys = cometWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = cometWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isCometRunning = true
            }
        }
    }
    if !isSafariRunning{
        safariWindowsInfo.removeAll()
    }
    
    if !isChromeRunning{
        googleChromeWindowsInfo.removeAll()
    }
    if !isOperaRunning{
        operaWindowsInfo.removeAll()
    }
    
    if !isOperaGxRunning{
        operaGxWindowsInfo.removeAll()
    }
    
    if !isVivaldiRunning{
        vivaldiWindowsInfo.removeAll()
    }
    if !isBraveRunning{
        braveBrowserWindowsInfo.removeAll()
    }
    if !isEdgeRunning{
        microsoftEdgeWindowsInfo.removeAll()
    }
    if !isSideKickRunning{
        sidekickWindowsInfo.removeAll()
    }
    if !isArcRunning{
        arcBrowserTabsInfo.removeAll()
    }
    if !isCometRunning{
        cometWindowsInfo.removeAll()
    }
    return totalTabsCount
}


func getBrowserAllWindowStruct(browser:BROWSER)->[String:[String]]?{
    // Don't script a browser the user hasn't granted (would pop/loop the OS Automation consent
    // dialog); raise the one-time consent prompt instead. shouldSkipBrowserAppleEvent checks the
    // per-browser grant store, so a browser granted via Settings still works even if onboarding
    // permissions were skipped.
    if shouldSkipBrowserAppleEvent(browser) {
        requestBrowserAutomationOnceIfNeeded(browser)
        return nil
    }
    if browser == ._GOOGLE_CHROME_ { return ChromeProcessTabs.windows() }
    var browserName = ""

    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._COMET_{
        browserName = "Comet"
    }

    // Firefox (extension-based) and SigmaOS (accessibility-based) have no scriptable window struct and
    // leave browserName empty. Running `tell application ""` pops the macOS "Choose Application /
    // Where is ?" app-locator panel — so bail here instead. (Arc uses its own hardcoded script below.)
    if browserName.isEmpty && browser != ._ARC_ {
        return nil
    }

    var script: String = ""

    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set end of arrayTabs to URL of theTab
        end repeat
        return arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayWinds to {}
            
        repeat with the_wnd in allWinds
        set arrayTabs to {}
        set allTabs to tabs in the_wnd
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set end of arrayTabs to taburl
        end repeat
        set idWind to id of the_wnd
        set arr to {idWind, arrayTabs}
        set end of arrayWinds to arr
        end repeat
        return the arrayWinds
        end tell
        """
        
    }
    
    
    if let desc = runBrowserAppleScript(script) {
        if browser == ._ARC_{
            return ["window": desc.toStringArray()]
        }
        return desc.toAnyArray()
    }
    return nil
}

func closeTabAt(index:Int, browser:BROWSER, windowID: String? = nil){
    if browser == ._GOOGLE_CHROME_, let windowID = windowID, windowID.contains(":") {
        ChromeProcessTabs.close(index: index, windowKey: windowID)
        return
    }
    let tab = index + 1// browser first tab index is 1 not 0

    var browserName = ""
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._COMET_{
        browserName = "Comet"
    }

    // IDs originate in a browser snapshot, but only interpolate validated numeric identifiers.
    let windowTarget = windowID.flatMap(Int.init).map { "window id \($0)" } ?? "front window" // i18n-ignore: AppleScript syntax, not display text.
    var script: String = ""

    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        close item \(tab) of tabs in front window
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set the_wnd to \(windowTarget)
        set allTabs to tabs in the_wnd
        set active_tab to item \(tab) of allTabs
        active_tab close
        end tell
        """
    }
    executeScript(script: script)
}


/// Well-known bundle identifiers for the browsers Focus Bear can read tabs from. Used to recognise a
/// browser even when its *app name* is NOT one of `arrBrowsersLowerCasedNames` — e.g. a Chrome
/// site-specific-browser / PWA / `--app` shortcut window ("Safe FB Team Comms"), which runs under Chrome's
/// bundle id (or a `com.google.Chrome.app.<id>` child) but shows a custom app name, so name-based
/// detection misses it.
let kBrowserBundleIds: [String: BROWSER] = [
    "com.apple.Safari": ._SAFARI_,
    "com.google.Chrome": ._GOOGLE_CHROME_,
    "com.brave.Browser": ._BRAVE_BROWSER_,
    "com.microsoft.edgemac": ._MICROSOFT_EDGE_,
    "company.thebrowser.Browser": ._ARC_,
    "org.mozilla.firefox": ._FIREFOX_,
    "com.operasoftware.Opera": ._OPERA_,
    "com.operasoftware.OperaGX": ._OPERA_GX_,
    "com.vivaldi.Vivaldi": ._VIVALDI_,
    "com.pushplaylabs.sidekick": ._SIDEKICK_,
]

/// Resolve a running app's bundle identifier to the browser Focus Bear can query — matching an exact known
/// browser bundle id, or a child bundle id (e.g. `com.google.Chrome.app.<hash>` for an installed PWA). Nil
/// when the bundle id isn't a recognised browser.
func browserFromBundleId(_ bundleId: String) -> BROWSER? {
    if let exact = kBrowserBundleIds[bundleId] { return exact }
    return kBrowserBundleIds.first { bundleId.hasPrefix($0.key + ".") }?.value
}

func getCurrentBrowserFrom(browserName:String)->BROWSER?{
    if browserName == "safari"{
        return ._SAFARI_
    }else if browserName == "google chrome"{
        return ._GOOGLE_CHROME_
    }else if browserName == "opera"{
        return ._OPERA_
    }else if browserName == "opera gx"{
        return ._OPERA_GX_
    }else if browserName == "vivaldi"{
        return ._VIVALDI_
    }else if browserName == "sidekick" {
        return ._SIDEKICK_
    }else if browserName == "brave browser"{
        return ._BRAVE_BROWSER_
    }else if browserName == "microsoft edge"{
        return ._MICROSOFT_EDGE_
    }else if browserName == "arc"{
        return ._ARC_
    }else if browserName == "firefox"{
        return ._FIREFOX_
    }else if browserName == "sigmaos"{
        return ._SIGMA_OS_
    }else if browserName == "sigmaos_latest"{
        return ._SIGMA_OS_
    }else if browserName == "comet"{
        return ._COMET_
    }else{
        return nil
    }
}

func getCurrentBrowserNameFrom(browser:BROWSER)->String?{
    if browser == ._SAFARI_{
        return "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        return "Google Chrome"
    }else if browser == ._OPERA_{
        return "Opera"
    }else if browser == ._OPERA_GX_{
        return "Opera GX"
    }else if browser == ._VIVALDI_{
        return "Vivaldi"
    }else if browser == ._SIDEKICK_ {
        return "Sidekick"
    }else if browser == ._BRAVE_BROWSER_{
        return "Brave Browser"
    }else if browser == ._MICROSOFT_EDGE_{
        return "Microsoft Edge"
    }else if browser == ._ARC_{
        return "Arc"
    }else if browser == ._FIREFOX_{
        return "Firefox"
    }else if browser == ._SIGMA_OS_{
        return sigmaOsBrowserName
    }else if browser == ._COMET_{
        return "Comet"
    }else{
        return nil
    }
}

func setUrlToBrowser(browser:BROWSER, url:String){
    guard !ManagedBlockingRuntime.shared.shouldDeferLegacyURL(url) else { return }
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return;
    }
    var script = ""
    var browserName = ""
    
    switch browser {
    case ._GOOGLE_CHROME_:
        browserName = "Google Chrome"
    case ._OPERA_:
        browserName = "Opera"
    case ._OPERA_GX_:
        browserName = "Opera GX"
    case ._VIVALDI_:
        browserName = "Vivaldi"
    case ._SAFARI_:
        browserName = "Safari"
    case ._BRAVE_BROWSER_:
        browserName = "Brave Browser"
    case ._SIDEKICK_:
        browserName = "Sidekick"
    case ._MICROSOFT_EDGE_:
        browserName = "Microsoft Edge"
    case ._ARC_:
        browserName = "Arc"
    case ._FIREFOX_:
        browserName = "Firefox"
    case ._SIGMA_OS_:
        browserName = sigmaOsBrowserName
    case ._COMET_:
        browserName = "Comet"
    }
    
    
    if browser == ._SAFARI_{
        script = """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set URL of active_tab to "\(url)"
    end tell
    """
    }else if browser == ._ARC_{
        script = """
                tell application \(browserName)
                set URL of active tab in front window to "\(url)"
                end tell
                """
    }else if browser == ._FIREFOX_{
        
        firefoxServer.sendUnBlockNow(url: url)
        return;//
        
//        if isVersionLower(currentVersion: fireFoxLatestVersion, referenceVersion: "133.0.3"){
//            script = """
//                    tell application "System Events" to set value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(url)"
//                    tell application "Firefox"
//                    activate
//                    end tell
//                    tell application "System Events" to key code 36
//                    """
//        }else{
//            script = """
//                    tell application "System Events" to set value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(url)"
//                    tell application "Firefox"
//                    activate
//                    end tell
//                    tell application "System Events" to key code 36
//                    """
//        }
        
    }else if browser == ._SIGMA_OS_{
        script = """
                tell application "\(sigmaOsBrowserName)" to activate
                 delay 0.2
                 tell application "System Events"
                     key code 53 -- press Escape to dismiss any popover
                     keystroke "l" using {command down} -- focus the address bar
                     delay 0.2
                     tell application process "SigmaOS"
                         -- Focus the URL text field
                         set urlField to text field 1 of group 1 of window 1
                         tell urlField
                             -- perform action "AXPress"
                             set value to "\(url)"
                         end tell
                         
                         -- Simulate pressing Return to load the URL
                         keystroke return
                     end tell
                 end tell
                """
    }else{
        script = """
    tell application "\(browserName)"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(url)"
    end tell
    """
    }
    _ = runBrowserAppleScript(script, authorization: {
        !ManagedBlockingRuntime.shared.shouldDeferLegacyURL(url)
    }, logErrors: false)
}

//--------------------------------------------//

func getSafariActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getSafariActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set tabtitle to name of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
/*
 
 tell application "System Events" to set isFocused to focused of UI element 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 if isFocused = false then
     tell application "System Events" to set urlValue to value of UI element 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 end if
 */

/*
 
 tell application "System Events" to set isFocused to focused of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 if isFocused = false then
     
     tell application "System Events" to set urlValue to value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 end if
 
 */
var fireFoxLatestVersion = ""
func getFireFoxVersion()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Firefox"
    set firefoxVersion to (get version)
    end tell
    """
    return executeScriptAndReturnString(script: script)
}

func isVersionLower(currentVersion: String, referenceVersion: String) -> Bool {
    return currentVersion.compare(referenceVersion, options: .numeric) == .orderedAscending
}

func getFirefoxActiveTabUrl()->String?{
    return firefoxServer.currentTabUrl
    
//    var script: String = ""
//    if let currentVersion = getFireFoxVersion(){
//        fireFoxLatestVersion = currentVersion
//        print("version of firefox is:-")
//        print(currentVersion)
//        
//        if isVersionLower(currentVersion: currentVersion, referenceVersion: "133.0.3"){
//            script =
//            """
//            tell application "System Events" to set isFocused to focused of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            if isFocused = false then
//                        
//            tell application "System Events" to set urlValue to value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            end if
//            """
//        }else{
//            script =
//            """
//            tell application "System Events" to set urlValue to value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            """
//        }
//    }else{
//        script =
//        """
//        tell application "System Events" to set urlValue to value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//        """
//    }
//    
//    if let appleScript = NSAppleScript(source: script) {
//        var errors : NSDictionary? = nil
//        let desc = appleScript.executeAndReturnError(&errors)
//        if errors != nil {
//            print(errors!)
//            if let errorCode = errors?.value(forKey: "NSAppleScriptErrorNumber") as? Int{
//                if let browser = getCurrentBrowserFrom(browserName: "firefox"){
//                    if errorCode == -1743{
//                        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
//                            for i in 0..<arrBrowsersInfo.count{
//                                let info = arrBrowsersInfo[i]
//                                let browserRawValue = info["browser"] as? Int ?? 0
//                                if browser.rawValue == browserRawValue{
//                                    arrBrowsersInfo[i]["isEnabled"] = false
//                                    break;
//                                }
//                            }
//                            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
//                        }
//                    }else if desc.stringValue == nil{
//                        return ""
//                    }
//                }
//            }
//        }
//        return desc.stringValue?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//    }
//    return nil
}

func getFirefoxActiveTabTitle()->String?{//
    return firefoxServer.currentTabTitle
    
//    var script: String = ""
//    
//    script =
//    """
//    tell application "Firefox"
//    set the_title to name of windows's item 1
//    end tell
//    """
//    
//    return executeScriptAndReturnString(script: script)
}







/// One browser observation keeps URL, title and bounds tied to the same window.
struct ChromeActiveTabSnapshot: Equatable {
    let windowID: Int32
    let url: String
    let title: String
    let bounds: [Int]

    static func select(frontWindowID: Int32, windows: [Self]) -> Self? {
        // Window enumeration is not an authority for which window the user is looking at.
        // A failed front-window read must not silently select an unrelated background page.
        guard let front = windows.first(where: { $0.windowID == frontWindowID }), !front.url.isEmpty else { return nil }
        guard front.url == "about:blank" else { return front }
        // Preserve the existing Meet call-window exception, only for a confirmed blank front tab.
        return windows.first(where: { !$0.url.isEmpty && $0.url != "about:blank" }) ?? front
    }
}

/// Read a single, explicitly addressed user browser. Never resolve Chrome by application name:
/// a headless automation process can have the same name, bundle ID and executable path.
enum ChromeActiveTabReader {
    private static let lock = NSLock()
    private static var previousPID: pid_t?
    private static var lastDiagnostic = ""

    static func selectProcess(frontPID: pid_t?, previousPID: pid_t?, candidates: [pid_t]) -> pid_t? {
        let candidates = Set(candidates)
        if let frontPID = frontPID, candidates.contains(frontPID) { return frontPID }
        if let previousPID = previousPID, candidates.contains(previousPID) { return previousPID }
        return candidates.count == 1 ? candidates.first : nil
    }

    private static func diagnostic(_ message: String) {
        lock.lock()
        let changed = lastDiagnostic != message
        lastDiagnostic = message
        lock.unlock()
        if changed { addLog(text: "Chrome active tab: " + message) }
    }

    static func bounds(_ descriptor: NSAppleEventDescriptor) -> [Int]? {
        if descriptor.descriptorType == ChromeProcessTabs.code("list"), descriptor.numberOfItems == 4 {
            return (1...4).compactMap { descriptor.atIndex($0).map { Int($0.int32Value) } }
        }
        // Cocoa scripting uses a native QuickDraw Rect: top, left, bottom, right (signed Int16).
        if descriptor.descriptorType == ChromeProcessTabs.code("qdrt"), descriptor.data.count == 8 {
            let values = descriptor.data.withUnsafeBytes { bytes in
                (0..<4).map { Int(bytes.loadUnaligned(fromByteOffset: $0 * 2, as: Int16.self)) }
            }
            return [values[1], values[0], values[3], values[2]]
        }
        return nil
    }

    static func snapshot(read: (NSAppleEventDescriptor) throws -> NSAppleEventDescriptor) throws -> ChromeActiveTabSnapshot? {
        typealias AE = ChromeProcessTabs
        let frontWindow = AE.object("cwin", form: "indx", key: .init(int32: 1))
        let frontID = try read(AE.property("ID  ", of: frontWindow))
        guard let frontKey = frontID.stringValue else { return nil }
        func window(_ id: NSAppleEventDescriptor) -> NSAppleEventDescriptor {
            AE.object("cwin", form: "ID  ", key: id)
        }
        func activeTab(_ id: NSAppleEventDescriptor) -> NSAppleEventDescriptor {
            AE.property("acTa", of: window(id))
        }
        func observation(_ id: NSAppleEventDescriptor) throws -> (ChromeActiveTabSnapshot, String)? {
            let properties = try read(AE.property("pALL", of: activeTab(id)))
            guard let tabID = properties.forKeyword(AE.code("ID  "))?.stringValue,
                  let url = properties.forKeyword(AE.code("URL "))?.stringValue, !url.isEmpty,
                  let title = properties.forKeyword(AE.code("pnam"))?.stringValue,
                  let bounds = bounds(try read(AE.property("pbnd", of: window(id)))) else { return nil }
            return (.init(windowID: id.int32Value, url: url, title: title, bounds: bounds), tabID)
        }
        guard let front = try observation(frontID) else { return nil }
        var chosen = front
        var chosenID = frontID
        // Preserve the Meet call-window exception, within the SAME normal Chrome process only.
        if front.0.url == "about:blank" {
            let all = AE.object("cwin", form: "indx", key: AE.allItems)
            let ids = try read(AE.property("ID  ", of: all))
            for index in 0..<ids.numberOfItems {
                guard let id = ids.atIndex(index + 1), id.stringValue != frontKey else { continue }
                if let candidate = try observation(id), candidate.0.url != "about:blank" {
                    chosen = candidate; chosenID = id
                    break
                }
            }
        }
        // A tab/window switch during these events makes the whole observation obsolete.
        guard try read(AE.property("ID  ", of: frontWindow)).stringValue == frontKey,
              try read(AE.property("ID  ", of: activeTab(frontID))).stringValue == front.1 else { return nil }
        if chosenID.stringValue != frontKey {
            guard try read(AE.property("ID  ", of: activeTab(chosenID))).stringValue == chosen.1 else { return nil }
        }
        return chosen.0
    }

    static func current() -> ChromeActiveTabSnapshot? {
        guard !shouldSkipBrowserAppleEvent(._GOOGLE_CHROME_) else { return nil }
        let applications = ChromeProcessTabs.applications()
        let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        lock.lock()
        let pid = selectProcess(frontPID: frontPID, previousPID: previousPID,
                                candidates: applications.map(\.processIdentifier))
        if let pid = pid { previousPID = pid }
        lock.unlock()
        guard let pid = pid else { return nil }
        // Keep a cumulative bound, including when called on the main thread for popup geometry.
        let deadline = Date().addingTimeInterval(Thread.isMainThread ? 1.2 : 5)
        do {
            let result = try snapshot { object in
                let remaining = deadline.timeIntervalSinceNow
                guard remaining > 0 else { throw NSError(domain: NSOSStatusErrorDomain, code: -1712) }
                return try ChromeProcessTabs.send(pid: pid, object: object, timeout: min(1, remaining))
            }
            if let result = result {
                diagnostic("pid=\(pid) window=\(result.windowID)")
            } else {
                diagnostic("pid=\(pid) incomplete or changed observation")
            }
            return result
        } catch {
            diagnostic("pid=\(pid) error=\((error as NSError).code)")
            if (error as NSError).code == -1743 {
                recordBrowserAutomationPermission(browser: ._GOOGLE_CHROME_, enabled: false)
            }
            return nil
        }
    }
}

private func readGoogleChromeActiveTab() -> ChromeActiveTabSnapshot? {
    ChromeActiveTabReader.current()
}

func getGoogleChromeActiveTabUrl() -> String? {
    readGoogleChromeActiveTab()?.url
}

/// Bounds belong to the same selected window as the URL, including the blank call-window fallback.
func getGoogleChromeBlockingWindowBounds() -> (x: Int, y: Int, width: Int, height: Int)? {
    guard let bounds = readGoogleChromeActiveTab()?.bounds, bounds.count == 4 else { return nil }
    return (bounds[0], bounds[1], bounds[2] - bounds[0], bounds[3] - bounds[1])
}

func getGoogleChromeActiveTabTitle() -> String? {
    readGoogleChromeActiveTab()?.title
}

func getOperaActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaGxActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaGxActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getVivaldiActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getVivaldiActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getBraveBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getBraveBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}


func getSidekickBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getSidekickBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getMicrosoftEdgeActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getMicrosoftEdgeActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}



func getArcBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Arc"
    get URL of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getArcBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Arc"
    get title of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getSigmaOSBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "\(sigmaOsBrowserName)"
    get URL of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getSigmaOSBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "\(sigmaOsBrowserName)"
    get name of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}



func getFirefoxBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    
    return """
    old_url=\(url)&\(params)&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())&version=\(appVersion)\(newPageParam)"
    """
    
   // return; //
//    if isVersionLower(currentVersion: fireFoxLatestVersion, referenceVersion: "133.0.3"){
//        return """
//        tell application "System Events" to set value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
//        tell application "Firefox"
//        activate
//        end tell
//        tell application "System Events" to key code 36
//        """
//    }else{
//        return """
//        tell application "System Events" to set value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
//        tell application "Firefox"
//        activate
//        end tell
//        tell application "System Events" to key code 36
//        """
//    }
}

func getSigmaOsBrowserBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    
    
    return """
                 tell application "\(sigmaOsBrowserName)" to activate
                 delay 0.2
                 tell application "System Events"
                     key code 53 -- press Escape to dismiss any popover
                     keystroke "l" using {command down} -- focus the address bar
                     delay 0.2
                     tell application process "SigmaOS"
                         -- Focus the URL text field
                         set urlField to text field 1 of group 1 of window 1
                         tell urlField
                             -- perform action "AXPress"
                             set value to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
                         end tell
                         
                         -- Simulate pressing Return to load the URL
                         keystroke return
                     end tell
                 end tell
                """
}

func getSafariBlockScript(url:String)->String{//"&confirm_ai_distracting_url=true"
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getGoogleChromeBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    // Redirect the same window the URL was read from (see getGoogleChromeActiveTabUrl): the first
    // window whose active tab isn't the call's "about:blank" window — not blindly the front window,
    // which during a Meet call is the blank call window (redirecting it would break the call and
    // leave the real distracting tab unblocked).
    return """
    tell application "Google Chrome"
    repeat with w in windows
    try
    set active_tab to active tab of w
    if URL of active_tab is not "about:blank" then
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    exit repeat
    end if
    end try
    end repeat
    end tell
    """
}

func getOperaBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getOperaGxBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getVivaldiBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getBraveBrowserBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getSidekickBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getMicrosoftEdgeBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getArcBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Arc"
    set URL of active tab in front window to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getCometActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Comet"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getCometActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Comet"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getCometBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Comet"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

//*******************************************************//




func isBrowserRunning(browserName: String) -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    let lowercaseBrowserName = browserName.lowercased()

    return runningApps.contains { app in
        if let appName = app.localizedName?.lowercased() {
            return appName == lowercaseBrowserName
        }
        return false
    }
}



func getNumberOfOpenTabsPerBrowserInString()->(Int,String){
    var totalTabsCount = 0
    var allBrowsersTabCount = 0
    var title = ""
    
    var keys = safariWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = safariWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nSafari - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = googleChromeWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = googleChromeWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nGoogle Chrome - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = operaWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = operaWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nOpera - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = operaGxWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = operaGxWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nOpera GX - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    
    totalTabsCount = 0
    keys = vivaldiWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = vivaldiWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nVivaldi - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = braveBrowserWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = braveBrowserWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nBrave Browser - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = sidekickWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = sidekickWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nSidekick - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = microsoftEdgeWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = microsoftEdgeWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nMicrosoft Edge - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    totalTabsCount = arcBrowserTabsInfo.count
    if totalTabsCount != 0{
        title += "\nArc - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }

    totalTabsCount = 0
    keys = cometWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = cometWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nComet - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    return (allBrowsersTabCount, title)
}

let firefoxServer = firefoxHttpServer()// for firefox
