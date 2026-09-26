//
//  showHideWindows.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

func showAbortingFocusModeVc(forPause:Bool){// abortview for pause only in strict mode
    addLog(text: "Showing Abort focus mode view")
    if teacherSessionManagerObject.isTeacherSessionActive(){// C3:- teacher controlled sessions cannot be aborted or paused, only unlock requests
        teacherSessionManagerObject.showTeacherSessionLockedAlert()
        return;
    }
    if currentFocusModeStrictness == ._STRICT_{
        mainWindowControllerObj?.showWindow(nil)
        leftMenuVcObj!.showFocusAbortedView()
        abortingFocusModeVcObj?.ResetData(forPause: forPause)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }else{
        isHardCorePomodoroModeOn = false
        appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false, shouldUpdateFocusButton: true)
    }
}

//***********SHOW completion Requirements View***************//
func showcompletionRequirementsWindow(title: String){
    addLog(text:"showcompletionRequirementsWindow")
    getCompletionRequirementsWindowObject().contentViewController = getCompletionRequirementsVcObject()
    getCompletionRequirementsWindowObject().window?.center()
    getCompletionRequirementsWindowObject().window?.title = appName
    getCompletionRequirementsWindowObject().window?.center()
    getCompletionRequirementsWindowObject().showWindow(nil)
    getCompletionRequirementsVcObject().resetView(title:title)
    
}

//***********SHOW PopUp CheckList Window***************//
func showPopUpCheckListWindow(title: String, list: [String]){
    if list.isEmpty{
        return;
    }
    addLog(text:"showPopUpCheckListWindow")
    getPopUpCheckListWindowObject().contentViewController = getPopUpCheckListVcObject()
    getPopUpCheckListWindowObject().window?.center()
    getPopUpCheckListWindowObject().window?.title = appName
    getPopUpCheckListWindowObject().window?.center()
    getPopUpCheckListWindowObject().showWindow(nil)
    getPopUpCheckListVcObject().resetView(title:title, list: list)
}


//***********SHOW ToDoList window***************//
/// Show the to-do window and start the reschedule plan on it. The Day Plan's over-capacity banner
/// links here rather than duplicating the plan, so there is one screen that reschedules.
/// `focusing` names the day the user asked to fix, when they arrived from that day's "Fix" rather
/// than from the menu. `nil` is the general whole-backlog case and changes nothing.
func showReprioritisePlanWindow(focusing target: ForecastDayFocus.Target? = nil) {
    showToDoListWindow()
    getTodoListToolVcObject().openReprioritisePlan(focusing: target)
}

func showToDoListWindow(){
    addLog(text:"show To Do List Window")
    if !(mainWindowControllerObj?.window?.isVisible ?? false){
        mainWindowControllerObj?.showWindow(nil)
    }
    leftMenuVcObj?.showTaskPlayer()
    allApiObject.capturePosthog(event: "todo-list-popup-shown", metadata: [:])
}


//***********SHOW the running focus session***************//
/// Brings the main window to the Focus Session screen — the session itself, not a list of tasks.
/// Used when something interrupted a session and then hands control back (a micro break ending), so
/// the person lands back in the session they were pulled out of. `showToDoListWindow()` remains the
/// genuine "open my to-do list" entry point.
func showRunningFocusSessionWindow(){
    addLog(text:"show Running Focus Session Window")
    if !(mainWindowControllerObj?.window?.isVisible ?? false){
        mainWindowControllerObj?.showWindow(nil)
    }
    leftMenuVcObj?.showFocusModeStateView()
}


//***********RESTORE the main window when the app is activated***************//

/// The app's windows other than the main one that are on screen right now.
///
/// Three kinds are not windows in the sense that matters here, and are left out:
/// the menu-bar status item's, which is always there; the floating focus bar, which deliberately sits
/// alongside the main window for the whole of a focus session; and the blank covers `showExtraWindows()`
/// paints over the secondary displays in full-screen mode (`arrWindows`) — a backdrop, not something
/// the app came forward to show anyone. The cover is not a hypothetical: it is what was actually in the
/// way in report 2026-09-16_16-01-15, confirmed by the named log line
/// `opened=none other=blankController` on the build that added the naming.
///
/// Sampled twice: once at the instant of activation, once when the decision is made. The difference
/// between the two is the only thing this is used for, because it answers the one question worth
/// asking — did the app come to the front in order to put a window up?
///
/// What is on screen *already* is deliberately not consulted. Treating "anything visible" as "the app
/// has already shown you something" is what made ⌘-Tab do nothing for four rounds of that report — any
/// second window the app happened to have up was enough — and the instruction on the report is explicit
/// that an alert or a nudge must not stop the window opening.
private func nonMainWindowsOnScreen() -> [NSWindow] {
    let ignored: [NSWindow?] = [mainWindowControllerObj?.window,
                                appdelegate?.statusbutton?.window,
                                floatingTopBarWcObj?.window]
    // Same reason the main window gets this test: `isVisible` survives the display it was on being
    // unplugged, and a window the user cannot see must not be the reason they are shown nothing.
    let screenFrames = NSScreen.screens.map { $0.visibleFrame }
    return NSApp.windows.filter { window in
        window.isVisible
            && AppActivationRestore.isOnVisibleScreen(windowFrame: window.frame, screenFrames: screenFrames)
            && !ignored.contains { $0 === window }
            && !arrWindows.contains { $0 === window }
    }
}

/// Identities of those windows, so the same window can be recognised across the settle period.
func nonMainWindowIdentitiesOnScreen() -> Set<ObjectIdentifier> {
    Set(nonMainWindowsOnScreen().map(ObjectIdentifier.init))
}

/// Names windows for the decision log — the content view controller's class, not the title, because
/// nearly every one of these windows is titled "Focus Bear". Rounds two and three of this report were
/// spent guessing which window the decision had seen; it should never be a guess again.
private func describeWindows(_ windows: [NSWindow]) -> String {
    guard !windows.isEmpty else { return "none" }
    return windows.map { window in
        window.contentViewController.map { String(describing: type(of: $0)) }
            ?? String(describing: type(of: window))
    }.joined(separator: ",")
}

/// Puts the main window back when the user switches to Focus Bear and finds it has none.
///
/// Shared by ⌘-Tab / app-switcher activation (`applicationDidBecomeActive`, one settle period later) and
/// Dock clicks (`applicationShouldHandleReopen`, immediately — a reopen is unambiguously the user) so the
/// two agree: they are the same request, "show me Focus Bear". `AppActivationRestore` owns the decision;
/// this only carries it out.
///
/// - Returns: true when it put the main window on screen.
@discardableResult
func restoreMainWindowOnActivationIfNeeded() -> Bool {
    let secondsSinceLaunch = appdelegate?.secondsSinceLaunch ?? 0
    // Checked ahead of the decision as well as inside it: reading `mainWindowControllerObj?.window`
    // loads the main window from the storyboard, and the launch activation must not be what does that.
    guard secondsSinceLaunch >= AppActivationRestore.launchSettlingSeconds else { return false }
    // #2580: while the browser-permissions explainer window is open (e.g. reached from the Start Focus
    // "grant permissions" banner), don't foreground the main window on activation. The user grants
    // per-browser automation permissions in System Settings and returns to the app between each — every
    // return was popping the Start Focus screen over the permissions window. `applicationDidResignActive`
    // already keeps this window focused during those prompts; this stops the restore from fighting it.
    if permissionBlockDistractionWcObj?.window?.isVisible == true { return false }
    // A window ordered in on a monitor that is no longer attached is `isVisible` but unreachable, and
    // reading it as "already on screen" is what made the third round of this report fail.
    let mainWindow = mainWindowControllerObj?.window
    let isMainWindowStranded = (mainWindow?.isVisible ?? false)
        && !AppActivationRestore.isOnVisibleScreen(windowFrame: mainWindow?.frame ?? .zero,
                                                   screenFrames: NSScreen.screens.map { $0.visibleFrame })
    let isSelfActivation = appdelegate?.consumeSelfActivationMarker() ?? false
    let isMainWindowVisible = (mainWindow?.isVisible ?? false) && !isMainWindowStranded
    // A Dock reopen has no snapshot to compare against, and needs none: clicking the Dock icon is
    // unambiguously the user, never the app activating itself.
    let windowsAtActivation = appdelegate?.consumeWindowsOnScreenAtActivation()
    let otherWindows = nonMainWindowsOnScreen()
    let windowsOpenedSinceActivation = windowsAtActivation
        .map { atActivation in otherWindows.filter { !atActivation.contains(ObjectIdentifier($0)) } } ?? []
    // The same snapshot, read the other way: a non-main Focus Bear window that WAS on screen at activation
    // but is gone now — a popup the user just dismissed. Dismissing a popup while the app is in the
    // background activates the app and closes the popup in one click, and by decision time the front-window
    // check can't see it. A window that merely stays open across the settle (a nudge on a ⌘-Tab) is NOT in
    // this set, so it can't re-break report 2026-09-16.
    let currentOtherWindowIds = Set(otherWindows.map(ObjectIdentifier.init))
    let didAnotherWindowCloseSinceActivation = windowsAtActivation
        .map { !$0.subtracting(currentOtherWindowIds).isEmpty } ?? false
    let isMenuVisible = isFocusBearMenuVisible() || (appdelegate?.menuShownInOverlayPanel ?? false)
    // Is the window the user is actually focused on one of our OWN non-main windows (the quit window, or
    // any future window)? If so they switched back to THAT, not to summon the main window. Keyed off the
    // front (key/main) window rather than "anything visible", so an incidental nudge/alert still lets a
    // ⌘-Tab open the main window, and a new window that hits this bug is handled with no special case
    // (#2585). `otherWindows` already excludes the main window, status item, floating bar and blank covers.
    let frontFocusBearWindows: [NSWindow?] = [NSApp.keyWindow, NSApp.mainWindow]
    let isAnotherFocusBearWindowFront = otherWindows.contains { window in
        frontFocusBearWindows.contains { $0 === window }
    }
    let action = AppActivationRestore.action(
        secondsSinceLaunch: secondsSinceLaunch,
        isSelfActivation: isSelfActivation,
        isMainWindowVisible: isMainWindowVisible,
        didAnotherWindowOpenSinceActivation: !windowsOpenedSinceActivation.isEmpty,
        didAnotherWindowCloseSinceActivation: didAnotherWindowCloseSinceActivation,
        isMenuVisible: isMenuVisible,
        isAnotherFocusBearWindowFront: isAnotherFocusBearWindowFront,
        state: currentState,
        isMainWindowConfiguredBorderless: mainWindowControllerObj?.isFullScreenVisible ?? false)
    // Logged whichever way it goes, and with the windows named: a silent `doNothing` is
    // indistinguishable from the feature being absent, and an unnamed "something else is up" is
    // indistinguishable from a wrong guess. Both cost this report a round trip.
    addLog(text: "activation restore: \(action) state=\(currentState) self=\(isSelfActivation) "
        + "main=\(isMainWindowVisible) stranded=\(isMainWindowStranded) "
        + "opened=\(describeWindows(windowsOpenedSinceActivation)) "
        + "other=\(describeWindows(otherWindows)) menu=\(isMenuVisible) "
        + "otherFront=\(isAnotherFocusBearWindowFront) closed=\(didAnotherWindowCloseSinceActivation)")
    guard action != .doNothing else { return false }
    mainWindowControllerObj?.showWindow(nil)
    if action == .showMainWindowAsSmallWindow || isMainWindowStranded {
        // Same reopen as the login screen's: drop the borderless full-screen configuration left over
        // from a routine that has since been postponed, and give the window a sane size and position.
        // A stranded window needs the centring too — showing it where it already is shows nothing.
        mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
        mainWindowControllerObj?.window?.center()
    }
    mainWindowControllerObj?.window?.makeKeyAndOrderFront(nil)
    return true
}
//-------------------------------------------------//


//***********SHOW Create Task window***************//
func showCreateTaskWindow(dueDate:Date){
    addLog(text:"show Create Task Window")
    allApiObject.capturePosthog(event: "create-task-window-shown", metadata: [:])
    getCreateTaskWcObject().contentViewController = getCreateTaskVcObject()
    getCreateTaskWcObject().window?.title = "Focus Bear - Create New Task"
    if let createTaskVcInfo = configjson.value(forKey: "createTaskVcInfo") as? NSDictionary{
        getCreateTaskWcObject().window?.title = createTaskVcInfo.value(forKey: "title") as? String ?? "Focus Bear - Create New Task"
    }
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let windowFrame = getCreateTaskWcObject().window?.frame ?? NSRect(x: 0, y: 0, width: 450, height: 542)
    let screenFrameCenterPoint = NSPoint(x: screenFrame.maxX / 2, y: screenFrame.maxY / 2)
    let windowOrigin = NSPoint(x: (screenFrameCenterPoint.x - (windowFrame.width / 2)), y: (screenFrameCenterPoint.y - (windowFrame.height / 2)))
    
    createTaskWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.minX + windowOrigin.x, y: screenFrame.minY + windowOrigin.y))
    getCreateTaskWcObject().showWindow(nil)
    getCreateTaskVcObject().resetData(dueDate: dueDate)
}



//***********SHOW RelaxMode window***************//
func showRelaxModeWindow(durationSeconds: Int, currentTimerValue:Int){
    allApiObject.capturePosthog(event: "relax-mode-window-shown", metadata: [:])
    addLog(text:"show RelaxMode Window")
    getRelaxModeWindowObject().contentViewController = getRelaxModeVcObject()
    getRelaxModeWindowObject().window?.title = appName
    getRelaxModeWindowObject().window?.center()
    getRelaxModeWindowObject().showWindow(nil)
    relaxModeVcObj?.startTimerHabit(durationSeconds: durationSeconds, currentTimerValue: currentTimerValue)
}

//***********Show Saved Sites For Later Window For Breaks***************//
func showSavedSitesForLaterWindowForBreaks(){
    addLog(text:"show Saved Sites For Later during breaks in pomodoro")
    getSavedSitesForLaterWindowObject().contentViewController = getSavedSitesForLaterVcObject()
    getSavedSitesForLaterWindowObject().window?.title = appName
    getSavedSitesForLaterWindowObject().window?.center()
    getSavedSitesForLaterWindowObject().showWindow(nil)
    savedSitesForLaterVcObj?.reloadData()
}

//***********show Confirm Run Script Window***************//
func showConfirmRunScriptWindow(focusMode:String, scriptPath:String?, shellCommand:String?){
    addLog(text:"show Saved Sites For Later during breaks in pomodoro")
    getConfirmRunScriptWindowObject().contentViewController = getConfirmRunScriptVcObject()
    getConfirmRunScriptWindowObject().window?.title = appName
    getConfirmRunScriptWindowObject().window?.center()
    getConfirmRunScriptWindowObject().showWindow(nil)
    getConfirmRunScriptVcObject().reloadData(focusMode:focusMode, scriptPath: scriptPath, shellCommand: shellCommand)
}



//***********SHOW BRAIN DUMP WINDOW***************//

func showBrainDumpWindow(){
    addLog(text: "func:- showBrainDumpWindow")
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showBrainDump()
}
//-------------------------------------------------//

//***********SHOW BRAIN DUMP WINDOW***************//

func showBrowsersTabAuditView(){
    addLog(text: "func:- showBrowsersTabAuditView")
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showBrowsersTabAuditView()
}
//-------------------------------------------------//


func showPopupBlockConfirmWindow(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool, browser:BROWSER?, tabTitle:String?, fullUrl:String, aiBlockReason:String?, isTimeOut:Bool, isBlockByAi:Bool, scoreForThisSiteApp: Double?, payload: [String : Any]?, isBrowser:Bool, suggestedTask:String?, suggestedTaskId:String?, isTaskMisalignedWithIntention: Bool? = nil){
    addLog(text: "func:- PopupBlockConfirmWindow")
    // Exit the app's fullscreen so this block-confirm popup is actually visible. Done here (rather than
    // before the block/allow decision) so an app that ends up allowed is never pulled out of fullscreen.
    // Only for app blocks — URL popups pass currentApp: nil and exit fullscreen on their own paths.
    if let currentApp = currentApp {
        exitFullScreen(runningApp: currentApp)
    }
    var currentPid: pid_t?
    if let runningApp = NSWorkspace.shared.frontmostApplication{
        let pid = runningApp.processIdentifier
        currentPid = pid
        // For Chrome, place the blur/popup over the REAL browsing window (the one whose active tab
        // was blocked), not the front "about:blank" window a Meet call opens — see
        // getGoogleChromeBlockingWindowBounds. nil (other browsers / read failed) keeps the old
        // "first sizeable frontmost window" behaviour.
        let chromeTargetBounds = (browser == ._GOOGLE_CHROME_) ? getGoogleChromeBlockingWindowBounds() : nil

        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]

        for info in windowInfoList! {
            let windowPID = info["kCGWindowOwnerPID"] as! UInt32
            if  windowPID == pid {
                if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                    let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                    let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                    let x = windowFrame.value(forKey: "X") as? Int ?? 0
                    let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                    // Skip any window that isn't the blocked Chrome browsing window (e.g. the front
                    // about:blank call window).
                    if let t = chromeTargetBounds, (abs(x - t.x) > 30 || abs(y - t.y) > 30) {
                        continue
                    }
                    if height > 250{
                        var frame = NSRect(x: x, y: y, width: width, height: height)
                        if browser != nil{
                            frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser!)
                        }
                        showBlurWindow(frame: frame, browser: browser)
                        break;
                    }

                }
            }
        }
    }
    // AI-block redesign: when the AI relevance check decides the current app/site is NOT relevant to the
    // focus intention + top task, route the moment through the SwiftUI accountability-buddy screen
    // (top-3 Day Plan tasks, save-side-quest, argue-with-AI) instead of the legacy popup. Everything
    // else (non-AI block-list blocks, super-distracting mode) still uses the legacy popup below.
    if shouldUseAiBlockBuddy(isBlockByAi: isBlockByAi, isBrowser: isBrowser) {
        // The AI relevance verdict is async — the app was captured when the check STARTED, but by the time
        // it returns the user may have switched away. Presenting the check-in then flags the WRONG window
        // (e.g. iTerm while Chrome is now frontmost). For an app block, only present if the flagged app is
        // still the one the user is actually on; otherwise drop it and let the focus loop re-check whatever
        // they moved to. (URL blocks keep their own handling — the caught page can persist in a background
        // browser tab.)
        if isBlockApp, let flagged = currentApp?.bundleIdentifier,
           let nowFront = currentUserFacingApp()?.bundleIdentifier, flagged != nowFront {
            addLog(text: "AI-block buddy: dropping stale app nudge for \(blockedAppName) — user is now on \(nowFront)")
            // The block flow already raised the blur backdrop before we got here. Dropping the nudge without
            // tearing it down left the blur orphaned on screen — no popup on top and nothing owning it to
            // dismiss, so it got stuck (user had to force-quit). Close it as we bail.
            blurWcObj?.window?.close()
            return
        }
        let context = AiBlockContext(blockedAppName: blockedAppName, currentApp: currentApp, url: url,
                                     fullUrl: fullUrl, script: script, browser: browser,
                                     isAppBlocking: isBlockApp, isBrowser: isBrowser,
                                     aiBlockReason: aiBlockReason, scoreForThisSiteApp: scoreForThisSiteApp,
                                     payload: payload, isTaskMisalignedWithIntention: isTaskMisalignedWithIntention)
        // A meeting is happening now and this is a meeting app/site — allow it silently, never block a
        // live call. Read LIVE (meeting state changes). Otherwise present the buddy.
        if autoAllowMeetingRelatedIfNeeded(context: context) { return }
        showAiBlockBuddyWindow(context: context)
        return
    }

    if popUpBlockConfirmWcObj == nil{
        getPopUpBlockConfirmWindowObject().contentViewController = getPopUpBlockConfirmVcObject()
        popUpBlockConfirmWcObj?.window?.styleMask.remove(.closable)
        popUpBlockConfirmWcObj?.window?.title = appName
        popUpBlockConfirmWcObj?.window?.backgroundColor = NSColor.clear
        popUpBlockConfirmWcObj?.window?.isMovable = false
    }
    
    if !(popUpBlockConfirmVcObj?.isViewLoaded ?? false){
        popUpBlockConfirmVcObj?.loadView()
    }
    let blurWindowFrame = blurWcObj?.window?.frame
    var midX = blurWindowFrame?.midX ?? 0
    var midY = blurWindowFrame?.midY ?? 0
    let width = popUpBlockConfirmVcObj?.view.frame.width ?? 500
    let height = popUpBlockConfirmVcObj?.view.frame.height ?? 500
    
    if !(blurWcObj?.window?.isVisible ?? false){
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        midX = screenFrame.width / 2
        midY = screenFrame.height / 2
    }
    
    popUpBlockConfirmVcObj?.resetView(blockedAppName: blockedAppName, currentApp:currentApp, url:url, script:script, isBlockApp:isBlockApp, browser:browser, currentPid: currentPid, tabTitle: tabTitle, fullUrl: fullUrl, aiBlockReason:aiBlockReason, isTimeOut:isTimeOut, isBlockByAi: isBlockByAi, scoreForThisSiteApp: scoreForThisSiteApp, payload: payload, isBrowser:isBrowser, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId)
    popUpBlockConfirmWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
    
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            let width = popUpBlockConfirmVcObj?.view.frame.width ?? 500
            let height = popUpBlockConfirmVcObj?.view.frame.height ?? 500
            popUpBlockConfirmWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
        }
    }
    popUpBlockConfirmWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********Popup Set Intention Blocked urls Window***************//
func showSetIntentionBlockedUrlsWindow(script: String, url:String, browser:BROWSER?, allreadyCheckedIndex:Int, isAppBlocking:Bool, currentApp:NSRunningApplication?, blockedAppName:String, blockItem:String){
    addLog(text: "func:- showSetIntentionBlockedUrlsWindow :- currentApp: \(currentApp?.localizedName ?? ""), url: \(url)")
    print("showSetIntentionBlockedUrlsWindow*************")
    var currentPid: pid_t?
    if let runningApp = NSWorkspace.shared.frontmostApplication{

        let pid = runningApp.processIdentifier
        currentPid = pid
        // See showBlockConfirmWindow: for Chrome, place the blur/popup over the real blocked browsing
        // window, not the front about:blank Meet call window.
        let chromeTargetBounds = (browser == ._GOOGLE_CHROME_) ? getGoogleChromeBlockingWindowBounds() : nil

        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]

        for info in windowInfoList! {
            let windowPID = info["kCGWindowOwnerPID"] as! UInt32
            if  windowPID == pid {

                if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                    let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                    let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                    let x = windowFrame.value(forKey: "X") as? Int ?? 0
                    let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                    if let t = chromeTargetBounds, (abs(x - t.x) > 30 || abs(y - t.y) > 30) {
                        continue
                    }
                    if height > 250{
                        var frame = NSRect(x: x, y: y, width: width, height: height)
                        if browser != nil{
                            frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser!)
                        }
                        showBlurWindow(frame: frame, browser: browser)
                        break;
                    }
                    
                }
            }
        }
    }

    if setIntentionBlockedUrlsWcObj == nil{
        getSetIntentionBlockedUrlsWindowObject().contentViewController = getSetIntentionBlockedUrlsVcObject()
        setIntentionBlockedUrlsWcObj?.window?.styleMask.remove(.closable)
        setIntentionBlockedUrlsWcObj?.window?.title = appName
        setIntentionBlockedUrlsWcObj?.window?.backgroundColor = NSColor.clear

        setIntentionBlockedUrlsWcObj?.window?.isMovable = false
    }
    if !(setIntentionBlockedUrlsVcObj?.isViewLoaded ?? false){
        setIntentionBlockedUrlsVcObj?.loadView()
    }
    if !(setIntentionBlockedUrlsWcObj?.isWindowLoaded ?? false){
        setIntentionBlockedUrlsWcObj?.loadWindow()
    }
    
    let blurWindowFrame = blurWcObj?.window?.frame
    var midX = blurWindowFrame?.midX ?? 0
    var midY = blurWindowFrame?.midY ?? 0
    let width = setIntentionBlockedUrlsWcObj?.window?.frame.width ?? 500
    let height = setIntentionBlockedUrlsWcObj?.window?.frame.height ?? 500
    if !(blurWcObj?.window?.isVisible ?? false){
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        midX = screenFrame.width / 2
        midY = screenFrame.height / 2
    }
    
    setIntentionBlockedUrlsVcObj?.resetView(script: script, url: url, currentPid: currentPid, browser:browser, allreadyCheckedIndex:allreadyCheckedIndex, isAppBlocking:isAppBlocking, currentApp:currentApp, blockedAppName:blockedAppName, blockItem:blockItem)
    let x = (midX-(width/2))
    let y = (midY-(height/2))
    setIntentionBlockedUrlsWcObj?.window?.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            let width = setIntentionBlockedUrlsVcObj?.view.frame.width ?? 500
            let height = setIntentionBlockedUrlsVcObj?.view.frame.height ?? 500
            setIntentionBlockedUrlsWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
        }
    }
    setIntentionBlockedUrlsWcObj!.showWindow(nil)
    
}
//-----------------------------------------------------//

//***********Popup Intention urls Window***************//

func showIntentionBlockedUrlsWindow(script: String, url:String, browser:BROWSER?, intention: String, currentPid: pid_t?, allowFor24Hours:Bool){
    print("showIntentionBlockedUrlsWindow***************")
    if intentionBlockedUrlsWcObj == nil{
        getIntentionBlockedUrlsWindowObject().contentViewController = getIntentionBlockedUrlsVcObject()
        intentionBlockedUrlsWcObj?.window?.title = appName
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        intentionBlockedUrlsWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (intentionBlockedUrlsVcObj?.view.frame.width)!, y: 0)) //  22 status bar heigh
    }
    var pid: pid_t?
    if currentPid == nil{
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            pid = runningApp.processIdentifier
        }
    }else{
        pid = currentPid
    }
    intentionBlockedUrlsWcObj!.showWindow(nil)
    intentionBlockedUrlsVcObj?.resetView(script: script, url: url, browser: browser, intention: intention, currentPid: pid, allowFor24Hours: allowFor24Hours)
}
//-----------------------------------------------------//

//***********Popup Intention apps Window***************//

func showIntentionBlockedAppsWindow(currentApp:NSRunningApplication?, blockedAppName:String, intention:String){
    print("showIntentionBlockedAppsWindow***************")
    if intentionBlockedAppsWcObj == nil{
        getIntentionBlockedAppsWindowObject().contentViewController = getIntentionBlockedAppsVcObject()
        intentionBlockedAppsWcObj?.window?.title = appName
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        intentionBlockedAppsWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (intentionBlockedAppsVcObj?.view.frame.width)!, y: 200))
    }
    intentionBlockedAppsWcObj!.showWindow(nil)
    intentionBlockedAppsVcObj?.resetView(currentApp:currentApp, blockedAppName:blockedAppName, intention:intention)
}
//-----------------------------------------------------//


//***********show Break Warning Window***************//

func showBreakWarningWindow(){
    if checkIsFullScreenEnabled(){
        getTransparentWindowObject().showWindow(nil)
    }
    addLog(text:"showBreakWarningWindow")
    allApiObject.capturePosthog(event: "break-warning-shown", metadata: [:])
    getBreakWarningWindowObject().contentViewController = getBreakWarningVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getBreakWarningWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (breakWarningVcObj?.view.frame.width)!, y: screenFrame.height - (breakWarningVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    
    breakWarningWcObj?.window?.title = appName
    breakWarningWcObj!.showWindow(nil)
    breakWarningVcObj!.resetView()
}
//-------------------------------------------------//

//***********show Deactivate Breaks Window***************//

func showDeactivateBreaksWindow(){
    addLog(text:"showDeactivateBreaksWindow")
    allApiObject.capturePosthog(event: "deactivate-breaks-window-shown", metadata: [:])
    getDeactivateBreaksWindowObject().contentViewController = getDeactivateBreaksVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getDeactivateBreaksWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (deactivateBreaksVcObj?.view.frame.width)!, y: screenFrame.height - (deactivateBreaksVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    deactivateBreaksWcObj?.window?.styleMask.remove(.closable)
    deactivateBreaksWcObj?.window?.title = appName
    deactivateBreaksWcObj!.showWindow(nil)
}
//-------------------------------------------------//


//***********show alertReasonAutoAllowSite Window***************//

func showNaturalBreakDetectionWindow(duration:Int){// not in use 
    print("showNaturalBreakDetectionWindow")
    if naturalBreaksDetectionVcObj != nil{
        if naturalBreaksDetectionVcObj?.isViewVisible ?? false{
            return;
        }
    }
    addLog(text:"showNaturalBreakDetectionWindow")
    allApiObject.capturePosthog(event: "natural-break-detection-window-shown", metadata: [:])
    
    naturalBreaksDetectionVcObj = nil// always catch a fresh object
    if mainWindowControllerObj?.window?.isVisible ?? false{
        addLog(text:"Natural Break view presenting by sheet")
        mainViewControllerObj?.presentAsSheet(getNaturalBreaksDetectionVcObject())
        getNaturalBreaksDetectionVcObject().resetView(duration:duration)
    }else{
        addLog(text:"Natural Break view presenting as window")
        getNaturalBreaksDetectionWindowObject().contentViewController = getNaturalBreaksDetectionVcObject()
        getNaturalBreaksDetectionWindowObject().window?.styleMask.remove(.closable)
        getNaturalBreaksDetectionWindowObject().window?.center()
        getNaturalBreaksDetectionWindowObject().window?.title = appName
        getNaturalBreaksDetectionWindowObject().showWindow(nil)
        getNaturalBreaksDetectionVcObject().resetView(duration:duration)
    }
}

func closeNaturalBreakDetectionWindowIfVisible(){// added on 9/9/25 in 2.27.413
    addLog(text: "closeNaturalBreakDetectionWindowIfVisible")
    if naturalBreaksDetectionVcObj != nil{
        if naturalBreaksDetectionVcObj?.isViewVisible ?? false{
            if naturalBreaksDetectionVcObj != nil{
                if naturalBreaksDetectionVcObj?.presentingViewController == mainViewControllerObj{
                    naturalBreaksDetectionVcObj?.closeForecefully()
                }
            }
        }
    }
}

//-------------------------------------------------//

//***********show Popup Appointment Time Window***************//

func showPopupAppointmentWindow(title:String, startTime:Date?, endTime:Date){
    addLog(text:"showPopupAppointmentWindow")
    // Mirror the Late No More appointment reminder onto the Focus Button.
    focusButtonServiceObject.showNotification(text: title)
    FocusGlowBorderManager.shared.pulseWorm()
    getPopupAppointmentTimeWindowObject().contentViewController = getPopupAppointmentTimeVcObject()
    getPopupAppointmentTimeWindowObject().window?.styleMask.remove(.closable)
    getPopupAppointmentTimeWindowObject().window?.center()
    getPopupAppointmentTimeWindowObject().window?.title = appName
    getPopupAppointmentTimeWindowObject().showWindow(nil)
    getPopupAppointmentTimeVcObject().resetView(title:title, startTime:startTime, endTime:endTime)
}
//-------------------------------------------------//


//***********show Alert Max Tab Limit Window***************//

func showAlertMaxTabLimitWindow(){
    addLog(text:"showAlertMaxTabLimitWindow")
    DispatchQueue.main.async {
        getAlertMaxTabLimitWindowObject().contentViewController = getAlertMaxTabLimitVcObject()
        getAlertMaxTabLimitWindowObject().window?.styleMask.remove(.closable)
        getAlertMaxTabLimitWindowObject().window?.center()
        getAlertMaxTabLimitWindowObject().window?.title = appName
        getAlertMaxTabLimitWindowObject().showWindow(nil)
    }
}
//-------------------------------------------------//

//***********show Blur Window***************//

func showBlurWindow(frame:NSRect, browser:BROWSER?){
    addLog(text:"show Blur Window")
    if blurWcObj == nil{
        getBlurWindowObject().contentViewController = getBlockBlurVcObject()
        getBlurWindowObject().window?.styleMask = .borderless
        
        blurWcObj?.window?.backgroundColor = NSColor.clear
        blurWcObj?.window?.isOpaque = false
        // MUST stay 1. NSVisualEffectView's `behindWindow` blur is disabled whenever the window's
        // alphaValue < 1, so at 0.98 the frosted panel wasn't actually blurring and the blocked site
        // stayed readable through it ("it doesn't blur enough"). Full opacity re-enables the real blur.
        blurWcObj?.window?.alphaValue = 1
    }
    guard let screen = NSScreen.main else{
        return;
    }
    let screenFrame = screen.frame
    let firstScreenFrame = NSScreen.screens.first?.frame ?? screenFrame
    let finalFrame: NSRect = NSRect(x: frame.minX, y: (firstScreenFrame.height - (frame.minY + frame.height)), width: frame.width, height: frame.height)

    getBlurWindowObject().window?.setFrame(finalFrame, display: true)
    
    if !(blurWcObj?.window?.isVisible ?? false){
        blurWcObj!.showWindow(nil)
    }
    if browser != nil{
        if browser == ._ARC_{
            blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }else{
            blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }

    }else{
        blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }

}
//-------------------------------------------------//

//***********show Blur Backdrop For Frontmost App***************//

/// Raise the blur backdrop sized to the frontmost app's main window — the same backdrop the block popup
/// shows. Used by the AI-block buddy's time-boxed re-prompt to re-raise the backdrop when a temporary
/// allow expires (the original entry computes this inline alongside `currentPid`, which the re-prompt
/// doesn't need).
func showBlurBackdropForFrontmostApp(browser: BROWSER?) {
    guard let runningApp = NSWorkspace.shared.frontmostApplication else { return }
    let pid = runningApp.processIdentifier
    let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
    guard let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0)),
          let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]] else { return }
    for info in windowInfoList {
        guard let windowPID = info["kCGWindowOwnerPID"] as? UInt32, windowPID == pid,
              let windowFrame = info["kCGWindowBounds"] as? NSDictionary else { continue }
        let height = windowFrame.value(forKey: "Height") as? Int ?? 0
        guard height > 250 else { continue }
        let width = windowFrame.value(forKey: "Width") as? Int ?? 0
        let x = windowFrame.value(forKey: "X") as? Int ?? 0
        let y = windowFrame.value(forKey: "Y") as? Int ?? 0
        var frame = NSRect(x: x, y: y, width: width, height: height)
        if let browser = browser {
            frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser)
        }
        showBlurWindow(frame: frame, browser: browser)
        break
    }
}
//-------------------------------------------------//

//***********show Break Warning Window***************//

func showAllTracksWindow(){
    addLog(text:"showAllTracksWindow")

    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showAllTracks()
    // Focus Bear is a menu-bar (accessory) app, so showWindow alone leaves the window behind other
    // apps — clicking "Focus Music" looked like nothing happened. Activate so it comes to the front.
    NSApplication.shared.activate(ignoringOtherApps: true)
    return;
}
//-------------------------------------------------//



//***********show share Feedback Window***************//

func showShareFeedbackWindow(){
    addLog(text:"showShareFeedbackWindow")
    getShareFeedbackWindowControllerObj().contentViewController = getShareFeedbackVcObj()
    
    shareFeedbackWindowControllerObj?.window?.center()
    shareFeedbackWindowControllerObj?.window?.styleMask.remove(.closable)
    shareFeedbackWindowControllerObj?.window?.title = appName
    shareFeedbackWindowControllerObj?.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//




//***********showaddFocusTempUrlsOrAppsWindow***************//

func showaddFocusTempUrlsOrAppsWindow(){
    addLog(text:"func:- showaddFocusTempUrlsOrAppsWindow")
    if !SettingsManagerObject.isGeekModeEnabled{
        addLog(text:"Simple mode is enabled:- return")
        return;
    }
    // dont show for Default focus mode / v 2.28.449 
    if let currentFocusModeId = lastFocusModeTempInfo?.id{
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String  == currentFocusModeId{
                if let isDefault = arrFocusType[i]["isDefault"] as? Bool{
                    if  isDefault{
                        addLog(text:"Default focus mode:- return")
                        return;
                    }
                }
                break;
            }
        }
    }
    
    getAddFocusTempUrlsOrAppsWcObj().contentViewController = getAddFocusTempUrlsOrAppsVcObj()
    
    getAddFocusTempUrlsOrAppsWcObj().window?.center()
    
    
    var titleWindowText = "Teach Focus Bear how you focus"
    if let addFocusTempUrlsOrAppsVcInfo = configjson.value(forKey: "addFocusTempUrlsOrAppsVcInfo") as? NSDictionary{
        titleWindowText = addFocusTempUrlsOrAppsVcInfo.value(forKey: "titleWindowText") as? String ?? titleWindowText
    }
    getAddFocusTempUrlsOrAppsWcObj().window?.title = titleWindowText
    
    getAddFocusTempUrlsOrAppsWcObj().showWindow(nil)
    addFocusTempUrlsOrAppsVcObj?.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********showSurveyWindow***************//
func showSurveyWindow(){
    addLog(text:"showSurveyWindow")
    getSurveyWcObject().contentViewController = getSurveyVcObject()
    getSurveyWcObject().window?.center()
    getSurveyWcObject().window?.title = appName
    getSurveyWcObject().showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    allApiObject.capturePosthog(event: "survey-window-shown", metadata: [:])
}
//-------------------------------------------------//


//***********showAudhdResultsWindow***************//
// Retained so the window/controller isn't deallocated while shown.
var audhdResultsVcObj: AudhdResultsWebViewVc?
private var audhdResultsWindow: NSWindow?

// Opens the gated "advanced AuDHD results" in a full-screen WKWebView with no URL bar.
// Reached from the `focusbear://view-audhd-results?test-code=<CODE>` deep link.
func showAudhdResultsWindow(testCode: String, onClose: (() -> Void)? = nil) {
    addLog(text: "showAudhdResultsWindow")

    let vc = audhdResultsVcObj ?? AudhdResultsWebViewVc()
    audhdResultsVcObj = vc
    vc.onClose = onClose

    let window = audhdResultsWindow ?? NSWindow(
        contentRect: (NSScreen.main ?? NSScreen.screens.first)?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800),
        styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
        backing: .buffered,
        defer: false
    )
    audhdResultsWindow = window
    // NSWindow.isReleasedWhenClosed defaults to true, so closing the window would deallocate it while the
    // audhdResultsWindow global still points at it — reopening then dereferences a dangling pointer and
    // crashes (EXC_BAD_ACCESS). Keep it alive so it can be reused; the global holds the only strong ref.
    window.isReleasedWhenClosed = false
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.title = appName
    window.contentViewController = vc
    // The VC is the window's delegate so it can fire the "results closed" analytics event on ✕
    // (see AudhdResultsWebViewVc.windowWillClose). NSWindow.delegate is weak; the globals hold the strong refs.
    window.delegate = vc
    if let screen = NSScreen.main ?? NSScreen.screens.first {
        window.setFrame(screen.visibleFrame, display: true)
    }
    window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.maximumWindow)))
    vc.present(testCode: testCode)
    window.makeKeyAndOrderFront(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    allApiObject.capturePosthog(event: AudhdResults.resultsShownEvent, metadata: [:])

    // Stitch the web-quiz PostHog identity onto this app's person. The public
    // AuDHD test identifies its PostHog person by the retest code, so aliasing the
    // same test-code here merges the two — otherwise the quiz -> download -> sign-up
    // journey shows up as two disjoint people and looks like nobody converts.
    // capturePosthogIdentify sends $create_alias(alias = testCode, distinct_id =
    // current app user), matching the mobile and Windows stitches.
    allApiObject.capturePosthogIdentify(sAliasID: testCode, completionHandler: { _ in })
}
//-------------------------------------------------//


//***********showTimeTrackerWindow***************//
func showTimeTrackerWindow(showingAutomatically:Bool){
    addLog(text:"showTimeTrackerWindow")
    let wc = getTimeTrackerWcObject()
    // Once FBTT is installed and has tracked data, show the read-only Today view
    // (reads FBTT's own SQLite store) instead of the promo/enable screen.
    wc.contentViewController = getTimeTrackerVcObject()
    timeTrackerVcObj!.showingAutomatically = showingAutomatically
    wc.window?.styleMask.remove(.closable)
    wc.window?.center()
    wc.window?.title = appName
    wc.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    allApiObject.capturePosthog(event: "show-timetracker-window", metadata: [:])
}
//-------------------------------------------------//

var shouldReloadTaskPlayer = true

/// Refreshes the To-do Player webview when a session-start path has asked for it.
///
/// The player has no screen of its own any more, but it is still the JS bridge that syncs
/// `focusModeTaskString`, so it has to be reloaded when a session starts, resumes or changes length.
/// That reload used to happen as a side effect of *displaying* the player; now that nothing displays
/// it, the session lifecycle drives it directly.
func reloadHeadlessToDoPlayerIfPending(){
    // "Anything is blocking", not "a session is running": the player has to be in sync for a blocking
    // schedule too. `isFocusModeRunning` (rather than `isFocusModeOn()`) keeps a *paused* session out,
    // which is what this path has always done.
    let isBlockingActive = FocusSessionPresence.isBlockingActive(
        isInSession: isFocusModeRunning,
        isAllowedActivityRunning: isAnyAllowedFocusModeActivityRunning,
        isCustomScheduleOn: customBlockingScheduleManagerObj.isAnyCustomScheduleOn)
    guard FocusSessionRouting.shouldReloadHeadlessPlayer(isReloadPending: shouldReloadTaskPlayer,
                                                        isBlockingActive: isBlockingActive) else { return }
    if !getTaskPlayerVcObject().isViewLoaded{
        getTaskPlayerVcObject().loadView()// handled in v2.27.435 otherwise app can crash when focus resumes automatically after app opens
    }
    shouldReloadTaskPlayer = false
    taskPlayerVcObj?.reloadData(totalDuration: focusModeMinutesToPerform, intention: whatToAchieveInFocusBlock)
}
//-------------------------------------------------//



//***********showCustomAlert***************//
func showCustomAlert(title:String, body:String?, buttonOkText:String, buttonCancelText:String?, checkBoxText:String?, autoClose:Bool, buttonLinkUrl:String?, buttonLinkText:String?, completionHandler: @escaping (Bool) -> Void){
    if customAlertWcObj == nil{
        getCustomAlertWindowObject().contentViewController = getCustomAlertVcObject()
    }
    getCustomAlertWindowObject().window?.center()
    getCustomAlertWindowObject().window?.styleMask.remove(.closable)
    getCustomAlertWindowObject().window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    getCustomAlertWindowObject().showWindow(nil)
    customAlertVcObj?.resetData(title: title, body: body, buttonOkText: buttonOkText, buttonCancelText: buttonCancelText, checkBoxText: checkBoxText, autoClose:autoClose, buttonLinkUrl: buttonLinkUrl, buttonLinkText:buttonLinkText, completionHandler: {isOkClicked in
        completionHandler(isOkClicked)
    })
}
//-------------------------------------------------//


//***********showCustomAlert***************//
func showSuggestFocusWindow(title:String, body:String?, buttonOkText:String, buttonCancelText:String?, checkBoxText:String?, autoClose:Bool, completionHandler: @escaping (Bool, Int?, String?) -> Void){
    if suggestFocusModeWcObj == nil{
        getSuggestFocusModeWindowObject().contentViewController = getSuggestFocusModeVcObject()
    }
    getSuggestFocusModeWindowObject().window?.center()
    getSuggestFocusModeWindowObject().window?.styleMask.remove(.closable)
    getSuggestFocusModeWindowObject().window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    getSuggestFocusModeWindowObject().showWindow(nil)
    getSuggestFocusModeVcObject().resetData(title: title, body: body, buttonOkText: buttonOkText, buttonCancelText: buttonCancelText, checkBoxText: checkBoxText, autoClose:autoClose, completionHandler: {isOkClicked, duration, intention in
        completionHandler(isOkClicked, duration, intention)
    })
}
//-------------------------------------------------//

//***********unverifiedEmailVc***************//
func showUnverifiedEmailWindow(){
    addLog(text:"showUnverifiedEmailWindow")
    if unverifiedEmailWcObj == nil{
        getUnverifiedEmailWindowObject().contentViewController = getUnverifiedEmailVcObject()
    }
    getUnverifiedEmailWindowObject().window?.center()
    getUnverifiedEmailWindowObject().window?.styleMask.remove(.closable)
    getUnverifiedEmailWindowObject().window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    getUnverifiedEmailWindowObject().showWindow(nil)
    getUnverifiedEmailVcObject().isAWindow = true
}
//-------------------------------------------------//




//***********showLateNoMoreWindow***************//
func showLateNoMoreWindow(){
    if FileManager.default.fileExists(atPath: "/Applications/Late No More.app"){
        return;
    }
    addLog(text:"showLateNoMoreWindow")
    getLateNoMorePopUpWcObject().contentViewController = getLateNoMorePopUpVcObject()
    getLateNoMorePopUpWcObject().window?.center()
    getLateNoMorePopUpWcObject().window?.title = appName
    getLateNoMorePopUpWcObject().window?.styleMask.remove(.closable)
    getLateNoMorePopUpWcObject().window?.level = .floating
    getLateNoMorePopUpWcObject().showWindow(nil)
    // Float the reminder above the user's current app WITHOUT activating Focus Bear — calling
    // NSApp.activate here also dragged the main window to the foreground over the user's work.
    getLateNoMorePopUpWcObject().window?.orderFrontRegardless()
    allApiObject.capturePosthog(event: "show-latenomore-window", metadata: [:])
}
//-------------------------------------------------//



//***********show Easy Postpone Window***************//

func showEasyPostponeWindow(){
    addLog(text:"showEasyPostponeWindow")
    allApiObject.capturePosthog(event: "easy-postpone-window-shown", metadata: [:])
    
    easyPostponeVcObj = nil// always get a fresh object
    if mainWindowControllerObj?.window?.isVisible ?? false{
        mainViewControllerObj?.presentAsSheet(getEasyPostponeVcObject())
    }else{
        getEasyPostponeWindowObject().contentViewController = getEasyPostponeVcObject()
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        easyPostponeWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (easyPostponeVcObj?.view.frame.width)!, y: screenFrame.height - (easyPostponeVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
        
        easyPostponeWcObj!.window?.styleMask.remove(.closable)
        easyPostponeWcObj?.window?.title = appName
        easyPostponeWcObj!.showWindow(nil)
    }
    easyPostponeVcObj?.isForExtendPostponeDuringCustomRoutine = false
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


func closeEasyPostponeWindowIfVisible(){
    if easyPostponeVcObj != nil{
        if easyPostponeVcObj?.isViewVisible ?? false{
            easyPostponeVcObj?.closeView()
        }
    }
}


//***********show Super Gentle Quit Window***************//

func showSuperGentleQuitWindow(){
    addLog(text:"showSuperGentleQuitWindow")
    allApiObject.capturePosthog(event: "super-gentle-quit-window-shown", metadata: [:])
    getSuperGentleQuitWindowObject().contentViewController = getSuperGentleQuitVcObject()
    
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    superGentleQuitWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (superGentleQuitVcObj?.view.frame.width)!, y: screenFrame.height - (superGentleQuitVcObj?.view.frame.height)! - 22)) //  22 status bar heigh

    superGentleQuitWcObj?.window?.title = appName
    superGentleQuitWcObj!.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//




//***********show PopUp Offline Window***************//

func showPopUpOfflineWindow(){
    addLog(text:"showPopUpOfflineWindow")
    getPopUpOfflineWindowObject().contentViewController = getPopUpOfflineVcObject()
    
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    popUpOfflineWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (popUpOfflineVcObj?.view.frame.width)!, y: screenFrame.height - (popUpOfflineVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    popUpOfflineWcObj?.window?.title = appName
    popUpOfflineWcObj!.showWindow(nil)
    //    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//

//***********SHOW Ask Login Window ***************//

func showAskLoginWindow(){
    addLog(text:"showAskLoginWindow")
    if currentState != ._ONBOARDING_{
        if !(mainWindowControllerObj?.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(nil)
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            mainWindowControllerObj?.window?.center()
        }
        
        mainViewControllerObj!.showAskLogInVc()
        // Set the login state BEFORE disabling tabs, so the alwaysEnabled guard (Todo List) sees
        // ._LOGIN_ and lets disableAllTabForOnboarding() actually keep it disabled.
        currentState = ._LOGIN_
        leftMenuVcObj?.disableAllTabForOnboarding()
        mainViewControllerObj?.collapseLeftPanel()
        // Logged out: the menu-bar click must foreground this window (it was a no-op because the
        // action stayed nil on this screen). Set target + action explicitly so dispatch is guaranteed.
        appdelegate!.statusbutton?.target = appdelegate
        appdelegate!.statusbutton?.action = #selector(AppDelegate.bringMainWindowToForeground(_:))
        return;
    }
    appdelegate!.statusbutton?.target = appdelegate
    appdelegate!.statusbutton?.action = #selector(AppDelegate.bringMainWindowToForeground(_:))
    getOnboardingVcObject().navigate(to: ._CREATE_ACCOUNT_)
}
//-------------------------------------------------//



//***********SHOW Custom Login Window ***************//

func showCustomLoginWindow(isLogin:Bool){
    addLog(text:"showCustomLoginWindow")
    if customLoginVcObj == nil{
        getCustomLoginVcObject().loadView()
    }
    if currentState != ._ONBOARDING_{
        if !(mainWindowControllerObj?.window?.isVisible ?? false){
            mainWindowControllerObj?.showWindow(nil)
            mainViewControllerObj?.showSmallScreen(showMinimumSize: true)
            mainWindowControllerObj?.window?.center()
        }
        
        mainViewControllerObj!.showCustomLoginVc()
        // Set the login state BEFORE disabling tabs, so the alwaysEnabled guard (Todo List) sees
        // ._LOGIN_ and lets disableAllTabForOnboarding() actually keep it disabled.
        currentState = ._LOGIN_
        leftMenuVcObj?.disableAllTabForOnboarding()
        mainViewControllerObj?.collapseLeftPanel()
        customLoginVcObj?.isLogin = isLogin
        appdelegate!.statusbutton?.action = #selector(AppDelegate.bringMainWindowToForeground(_:))
        return;
    }

    customLoginVcObj?.isLogin = isLogin
    getOnboardingVcObject().navigate(to: ._LOGIN_)
    appdelegate!.statusbutton?.action = #selector(AppDelegate.bringMainWindowToForeground(_:))
}
//-------------------------------------------------//


func showConfirmBlockingScheduleWindow(){
    addLog(text:"showConfirmBlockingScheduleWindow")
    allApiObject.capturePosthog(event: "show_confirm_blocking_schedule_screen", metadata: [:])
    mainWindowControllerObj?.showWindow(nil)
    mainViewControllerObj?.showConfirmBlockingScheduleView()
}

func showFirefoxPermissionWindow(showingFromOnboarding:Bool, currentBrowser:BROWSER){
    addLog(text:"showFirefoxPermissionWindow")
    getFirefoxPermissionsWindowObject().contentViewController = getFirefoxPermissionsVcObject()
    firefoxPermissionsWcObj!.window?.styleMask.remove(.closable)
    firefoxPermissionsWcObj!.showWindow(nil)
    firefoxPermissionsWcObj?.window?.center()
    firefoxPermissionsVcObj?.showingFromOnboarding = showingFromOnboarding
    firefoxPermissionsVcObj?.currentBrowser = currentBrowser
    firefoxPermissionsVcObj?.resetView()
    if currentBrowser == ._FIREFOX_{
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirefoxPermissionShown)
    }else if currentBrowser == ._SIGMA_OS_{
        UserDefaults.standard.set(true, forKey: kUserdefaultsSigmaOSPermissionShown)
    }
}



func showMenuTourWindow(){
    addLog(text:"showMenuTourWindow")
    allApiObject.capturePosthog(event: "show_menu_tour", metadata: [:])
    if menuTourWcObj == nil{
        getMenuTourWcObject().contentViewController = getMenuTourVcObject()
    }
    getMenuTourWcObject().showWindow(nil)
    
    
    let screenList = NSScreen.screens
    for screen in screenList {
        menuTourWcObj?.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
        break;
    }
}

//-------------------------------------------------//


//***********Show Explaining Permissions Window***************//
func showExplainingPermissionsWindow(showingFromPomodoro:Bool, showingFromBlockingSchedule:Bool = false){
    addLog(text:"showSetFocusWindow")
    isExplainingPermissionsWindowShowingFromPomodoro = showingFromPomodoro
    isExplainingPermissionsWindowShowingFromBlockingSchedule = showingFromBlockingSchedule
    getPermissionBlockDistractionWindowObject().contentViewController = getExplainingPermissionsVcObject()
    getPermissionBlockDistractionWindowObject().window?.center()
    //    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
    getPermissionBlockDistractionWindowObject().showWindow(nil)
    getPermissionBlockDistractionWindowObject().window?.center()
}

//***********SHOW Upgrade Now Window ***************//
func showUpgradeNowWindow(reason: String = "unknown"){
    addLog(text:"showUpgradeNowWindow reason:\(reason)")

    if upgradeNowVcObj != nil{
        if upgradeNowVcObj?.isViewVisible ?? false{
            upgradeNowVcObj?.closeView()
        }
    }

    upgradeNowVcObj = nil

    let vc = getUpgradeNowVcObject()
    vc.nagShownReason = reason

    if mainWindowControllerObj?.window?.isVisible ?? false{
        mainViewControllerObj?.presentAsSheet(vc)
    }else{
        let window = getUpgradeNowWindowObject()
        window.contentViewController = vc
        window.showWindow(nil)
    }
    vc.captureNagShownEvent()   // fire once here (deterministic), not in viewWillAppear
}
//-------------------------------------------------//


//***********SHOW Upgrade To Pro Window ***************//
func showUpgradeToProNagWindow(titleText:String, reason:String){
    addLog(text:"showUpgradeToProNagWindow reason:\(reason)")

    let vc = getUpgradeToProNagVcObject()
    vc.nagShownReason = reason

    let window = getupgradeToProNagWindowObject()
    window.contentViewController = vc
    // Restore the transparent full-size titlebar look (dropped in the rewrite; the window factory
    // doesn't set it) so the pro nag doesn't render with a normal opaque title bar.
    window.window?.styleMask.insert(.fullSizeContentView)
    window.window?.titlebarAppearsTransparent = true
    window.window?.title = ""
    window.window?.center()
    window.showWindow(nil)

    vc.resetData(titleText: titleText)
    vc.captureNagShownEvent()
}
//-------------------------------------------------//


//***********SHOW Welcome window ***************//


/// Fresh-install entry point used in place of a direct `showWelcomeWindow()` call. If a Focus Bear AuDHD
/// retest code is sitting on the clipboard (checked exactly once — see
/// `AudhdResults.clipboardCheckedDefaultsKey`), show the gated results window first and only proceed to
/// the welcome window (and everything downstream: signup, onboarding) once the user closes it. With no
/// code on the clipboard — the common case — this is identical to calling `showWelcomeWindow()` directly.
func showWelcomeWindowOrAudhdResultsFirst(){
    if !UserDefaults.standard.bool(forKey: AudhdResults.clipboardCheckedDefaultsKey) {
        UserDefaults.standard.set(true, forKey: AudhdResults.clipboardCheckedDefaultsKey)
        if let clip = NSPasteboard.general.string(forType: .string),
           let testCode = AudhdResults.testCode(fromClipboard: clip) {
            showAudhdResultsWindow(testCode: testCode, onClose: { showWelcomeWindow() })
            return
        }
    }
    showWelcomeWindow()
}
//-------------------------------------------------//

func showWelcomeWindow(){
    addLog(text:"showWelcomeOnboardingWindow")
    if !getHabitsVcObject().isViewLoaded{
        getHabitsVcObject().loadView()
    }
    currentState = ._ONBOARDING_
    mainWindowControllerObj?.showWindow(nil)
    mainViewControllerObj?.checkIsFullScreenNeeded()
    mainViewControllerObj!.showOnboardingVc()
    getOnboardingVcObject().navigate(to: ._WELCOME_)
    leftMenuVcObj?.disableAllTabForOnboarding()
    mainViewControllerObj?.collapseLeftPanel()
}
//-------------------------------------------------//


//---------------------ShowQuitWindow----------------------------//

func showQuitWindow(){
    addLog(text: "[user-action] - func showQuitWindow")

    // Teacher session:- the student can't quit the app to escape a class focus session. Show the
    // teacher-locked alert (with Request unlock) instead of the quit flow.
    if teacherSessionManagerObject.isTeacherSessionActive(){
        addLog(text: "[user-action] quit blocked during teacher session — showing locked alert")
        teacherSessionManagerObject.showTeacherSessionLockedAlert()
        return
    }

    showQuittingConfirmView()
    quittingWcObj?.showWindow(appdelegate!)
    quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))//modalPanelWindow
    NSApplication.shared.activate(ignoringOtherApps: true)
}

func showQuittingConfirmView(){
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
    
    // The new two-step quit popup is the single front door for every user (regardless of how long they've
    // had the app installed). The historic "shown" events still fire, keyed on install age, so the
    // existing dashboards keep working; the popup itself routes broken/annoying quits into the reason
    // capture and "just turning off" into the pause/off-until-tomorrow choice.
    let shownEvent = diffDays > 2 ? "show-quit-confirm-screen" : "show-quit-within-48-hrs-feedback-screen"
    addLog(text: "[user-action] - Show quit popup (diffDays: \(diffDays))")
    allApiObject.capturePosthog(event: shownEvent, metadata: [:])
    getQuittingWindowObject().contentViewController = getInitialQuitFeedbackVcObject()
    getInitialQuitFeedbackVcObject().resetData()
}


var popoverInformation:NSPopover?// = NSPopover()
func showInformationPopover(sender:NSView, preferredEdge: NSRectEdge,mainTitle: String, title: String, description: String) {
    if popoverInformation == nil{
        popoverInformation = NSPopover()
        popoverInformation!.behavior = .transient
        popoverInformation!.animates = false
        //        popoverTooltip!.delegate = appdelegate
    }
    if popoverInformation!.isShown{
        popoverInformation?.close()
    }
    let vc = getInformationPopoverVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    vc.showCurrentMessage(mainTitle: mainTitle, title: title, description: description)
    popoverInformation!.contentViewController = vc
    popoverInformation!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
}


//  /////////////////////////////////////////////////////////////////////////

var popoverFocusHelp:NSPopover?//
var popoverTooltip:NSPopover?// = NSPopover()
func showTooltip(sender:NSView, msg:String, preferredEdge: NSRectEdge, maxWidthVal:CGFloat, autoCloseOnMouseExit:Bool = false) {
    if popoverTooltip == nil{
        popoverTooltip = NSPopover()
        popoverTooltip!.animates = false
    }
    
    popoverTooltip!.behavior = .transient
    if popoverTooltip!.isShown{
        popoverTooltip?.close()
    }
    let vc = getCustomTooltipVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    if vc.maxWidthVal != maxWidthVal{
        vc.maxWidthVal = maxWidthVal
        vc.resetView()
    }
    
    popoverTooltip!.contentViewController = vc
    popoverTooltip!.contentSize = vc.view.frame.size
    
    popoverTooltip!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
    vc.lblTitle.stringValue = msg
}

func showTooltipWithOsTahoe(sender:NSView, msg:String, preferredEdge: NSRectEdge, maxWidthVal:CGFloat, autoCloseOnMouseExit:Bool = false) {
    if popoverTooltip == nil{
        popoverTooltip = NSPopover()
        popoverTooltip!.animates = false
    }
    popoverTooltip!.behavior = .applicationDefined
    if popoverTooltip!.isShown{
        popoverTooltip?.close()
    }
    let vc = getCustomTooltipVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    if vc.maxWidthVal != maxWidthVal{
        vc.maxWidthVal = maxWidthVal
        vc.resetView()
    }
    
    popoverTooltip!.contentViewController = vc
    popoverTooltip!.contentSize = vc.view.frame.size
    
    popoverTooltip!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
    vc.lblTitle.stringValue = msg
}



func closePopoverTooltipIfVisible(){
    if popoverTooltip != nil{
        if popoverTooltip!.isShown{
            popoverTooltip?.close()
        }
    }
}

func closePupUpBlockIfVisible(){
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            popUpBlockConfirmVcObj?.closeWindow()
        }else if popUpBlockConfirmVcObj != nil{
            popUpBlockConfirmVcObj?.currentApp = nil
        }
    }
}

func closePopupBlockWindowIfRunningForUrl(){
    currentBrowserUrlForAi = ""
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            if !popUpBlockConfirmVcObj!.isAppBlocking{
                popUpBlockConfirmVcObj?.closeWindow()
            }
        }
    }
}


func showNudgeFocusAlignmentScoreWindow(score:Double){
    if !SettingsManagerObject.isFocusVisualIndicatorEnabled{
        if nudgeFocusAlignmentScoreDippingWcObject != nil{
            if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
                nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
            }
            nudgeFocusAlignmentScoreDippingWcObject?.window?.close()
        }
        return;
    }
    
    if nudgeFocusAlignmentScoreDippingVcObj == nil{
        getNudgeFocusAlignmentScoreDippingVcObject().loadView()
    }
    
    
    ///If the big floating bear is open, I don’t think we need the little one as well.
    
    getNudgeFocusAlignmentScoreDippingVcObject().isFloatingTopBarRemovedByNudge = false
    if floatingTopBarWcObj != nil{
        if getFloatingTopBarWObject().window?.isVisible ?? false{
            if !getFloatingTopBarVObject().boxMain.isHidden{
                getFloatingTopBarVObject().boxMain.isHidden = true
                getFloatingTopBarVObject().boxMoreItems.isHidden = true
                getNudgeFocusAlignmentScoreDippingVcObject().isFloatingTopBarRemovedByNudge = true
            }
        }
    }
    
    
    if nudgeFocusAlignmentScoreDippingWcObject == nil{
        nudgeFocusAlignmentScoreDippingWcObject = nudgeFocusAlignmentScoreDippingWc()
    }else{
        if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){// if window is not visible but isNudgeVisible is true then make isNudgeVisible false
            if !(nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false){
                nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible = false
            }
        }
    }
    
    if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
        getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: score, isNudgeVisible: true)
        lastFocusAlignmentShownScore = score
        return;
    }
    
    
    
    if !(nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false){
        nudgeFocusAlignmentScoreDippingWcObject?.showWindow(nil)
    }
    
    let screenFrame = NSScreen.main?.frame ?? NSRect.zero
    let viewFrame = getNudgeFocusAlignmentScoreDippingVcObject().view.frame
    
    let xPoint = screenFrame.width - (viewFrame.width + 50)
    if !isNudgeDraggedInCurrentFocusSession{
        let frame = NSRect(x: xPoint, y: 0 - viewFrame.height, width: viewFrame.width, height: viewFrame.height)
        nudgeFocusAlignmentScoreDippingWcObject?.window?.setFrameOrigin(frame.origin)
    }
    
    nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible = false
    
    if !(nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
        nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
    }
    getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: score, isNudgeVisible: false)
    lastFocusAlignmentShownScore = score
    getNudgeFocusAlignmentScoreDippingVcObject().setTimerStopAniumation()
}


func closeNudgeFocusAlignmentScoreWindow(){
    if nudgeFocusAlignmentScoreDippingWcObject != nil{
        if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
            nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
            
            ///If the big floating bear is open, I don’t think we need the little one as well.
            if floatingTopBarWcObj != nil && !isFocusBearMenuVisible(){
                if getFloatingTopBarWObject().window?.isVisible ?? false{
                    getFloatingTopBarVObject().boxMain.isHidden = false
                    getFloatingTopBarVObject().boxMoreItems.isHidden = false
                }
            }
        }
        nudgeFocusAlignmentScoreDippingWcObject?.window?.close()
    }
}



func showReportBadAIResponseWindow(url:String?, app:String?, payload:[String:Any]?, onReported:(() -> Void)? = nil){
    getReportBadAIResponseWindowObject().contentViewController = getReportBadAIResponseVcObject()
    getReportBadAIResponseWindowObject().window?.center()
    getReportBadAIResponseWindowObject().showWindow(nil)
    getReportBadAIResponseVcObject().resetData(url: url, app: app, payload: payload, onReported: onReported)
}



//***********show Custom Routine Time Window***************//

func showCustomRoutineTimeWindow(index:Int){
    addLog(text:"showCustomRoutineTimeWindow")
    allApiObject.capturePosthog(event: "custom-routine-time-window-shown", metadata: [:])
    getCustomRoutineTimeWindowObject().contentViewController = getCustomRoutineTimeVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getCustomRoutineTimeWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (customRoutineTimeVcObj?.view.frame.width)!, y: screenFrame.height - (customRoutineTimeVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    
    customRoutineTimeWcObj?.window?.title = appName
    customRoutineTimeWcObj!.showWindow(nil)
    customRoutineTimeVcObj!.resetView(index: index)
}
//------------------hideCustomRoutineTimeWindow-------------------------------//


func hideCustomRoutineTimeWindowIfVisible(){
    if customRoutineTimeWcObj != nil{
        if customRoutineTimeWcObj?.window?.isVisible ?? false{
            customRoutineTimeWcObj?.window?.close()
        }
    }
}


func showSplashWindow(){
    getSplashWindowObject().contentViewController = getSplashVcObject()
    getSplashWindowObject().showWindow(nil)
}

func closeSplashWindow(){
    if splashWcObj != nil{
        if splashWcObj?.window?.isVisible ?? false{
            getSplashWindowObject().window?.close()
        }
    }
}


/// Which display the routine's borderless full-screen window takes, and which displays get the blank
/// covers. One rule for both, so a cover can never land on the display the routine is on.
///
/// They used to disagree: the covers went on every display except `NSScreen.screens[0]`, while the
/// window sized itself to whatever display it was on. With the window on a secondary display, a cover
/// at `.maximumWindow` level went over it — and over the "Why do you want to skip?" sheet in it — so
/// skipping from the menu blanked the left screen and hid the question (report 2026-09-25_14-51-33).
enum FullScreenDisplays {
    /// The first of `preferred` that is still connected, else the primary display. Callers pass the
    /// display to use in priority order — e.g. the one with keyboard focus, then the window's own.
    static func host<Screen: Equatable>(preferred: [Screen?], all: [Screen]) -> Screen? {
        preferred.compactMap { $0 }.first(where: { all.contains($0) }) ?? all.first
    }

    /// Every display except the host. A host that is no longer connected falls back to the primary.
    static func screensToCover<Screen: Equatable>(all: [Screen], host: Screen?) -> [Screen] {
        guard let host = host, all.contains(host) else { return Array(all.dropFirst()) }
        return all.filter { $0 != host }
    }
}

var arrWindows = [NSWindow]()
func showBlankWindowInSecondaryMonitor(){
    addLog(text: "func:- showBlankWindowInSecondaryMonitor")
    // Late routine callbacks must not recreate covers or dismiss unrelated Help sheets after
    // the main window becomes a normal window or closes.
    guard checkIsFullScreenEnabled(), mainWindowControllerObj?.shouldCoverSecondaryScreens == true else {
        hideBlankWindowInSecondaryMonitor()
        return
    }

    // Luisa App broken bug fix 28/6/22
    let windows = NSApp.windows
    for win in windows{
        print(win)
        if win.isModalPanel{
            NSApp.stopModal()
            break;
        }
    }
    //  /////////////////////////////////
    appdelegate?.showExtraWindows()
}



func hideBlankWindowInSecondaryMonitor(){
    addLog(text: "func:- hideBlankWindowInSecondaryMonitor")
    for i in 0..<arrWindows.count{
        let window = arrWindows[i]
        window.orderOut(nil)
        arrWindows[i].windowController?.window=nil
    }
    arrWindows.removeAll()
}

func resetWin(_ win: NSWindow) -> NSWindow {
    win.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these windows to follow Spaces around
    //use .desktopWindow for window below icons   //hack? this makes mission control and expose ignore these windows
    //        if toggleButtonHideDesktopIcons.isOn{
    //            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
    //        }else{
    win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    //        }
    // rest is to make the windows dumb
    win.canHide = false
    win.isExcludedFromWindowsMenu = true
    win.hidesOnDeactivate = false
    win.discardCursorRects()
    win.discardEvents(matching: NSEvent.EventTypeMask.any, before: nil)
    //win.ignoresMouseEvents = true
    win.orderBack(nil)
    win.isRestorable = false
    win.animationBehavior = .none
    win.backgroundColor = NSColor.clear
    return win
}



func isFocusCompletedViewVisibled()->Bool{
    if mainWindowControllerObj?.window?.isVisible ?? false{
        if (leftMenuVcObj?.boxFocusSession.isSelected ?? false) && focusCompletedVcObj != nil{
            if focusCompletedVcObj!.isViewLoaded{
                if mainViewControllerObj!.containerView.subviews.contains(focusCompletedVcObj!.view){
                    return true
                }
            }
        }
    }
    return false
}


func showFloatingTopBarWindow(windowTopMidPoint:NSPoint){
    if floatingTopBarWcObj == nil{
        getFloatingTopBarWObject().contentViewController = getFloatingTopBarVObject()
        getFloatingTopBarWObject().window?.level = .statusBar
        getFloatingTopBarWObject().window?.isMovable = true
        getFloatingTopBarWObject().window?.isMovableByWindowBackground = true
        getFloatingTopBarWObject().window?.isOpaque = false
        getFloatingTopBarWObject().window?.hasShadow = false
        getFloatingTopBarWObject().window?.backgroundColor = NSColor.clear
        getFloatingTopBarWObject().window?.styleMask = .borderless
    }
    getFloatingTopBarWObject().showWindow(nil)
    let boxMainMaxY = floatingTopBarVcObj?.boxMain.frame.maxY ?? 134
    
    var origin = NSPoint(x: windowTopMidPoint.x - (getFloatingTopBarVObject().view.frame.width / 2), y: windowTopMidPoint.y - boxMainMaxY)// 34. box height
    if SettingsManagerObject.isMenuPopoverEnabled{
        origin = NSPoint(x: windowTopMidPoint.x - (getFloatingTopBarVObject().view.frame.width / 2), y: windowTopMidPoint.y - boxMainMaxY - 10)// 10 is arrow height
    }
    getFloatingTopBarWObject().window?.setFrameOrigin(origin)
    getFloatingTopBarVObject().boxMain.isHidden = false
    getFloatingTopBarVObject().boxMoreItems.isHidden = false
}


func closeMenuWindowIsVisible(){
    // The menu may currently be shown in the full-screen overlay panel (a separate window from the
    // popover/detached window) — dismiss that first so a menu action closes it too.
    if appdelegate?.menuShownInOverlayPanel == true {
        appdelegate?.hideMenuOverlayPanel()
        return
    }
    appdelegate?.removeMenuOutsideClickMonitors()
    if !SettingsManagerObject.isMenuPopoverEnabled{
        if menuWcObj != nil{
            if menuWcObj?.window?.isVisible ?? false{
                menuWcObj?.window?.close()
            }
        }
    }else{
        appdelegate?.popover.close()
    }
}

func closeMainMenuIfVisible(){
    if SettingsManagerObject.isMenuPopoverEnabled{
        if appdelegate?.popover.isShown ?? false{
            appdelegate?.popover.close()
        }
    }else{
        if getMenuWindowObject().window?.isVisible ?? false{
            getMenuWindowObject().window?.close()
        }
    }
}

//***********SHOW Small Timer WINDOW***************//

func showSmallTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool, currentTimerValue:Int){
    addLog(text:"show Top Small Timer Window for:- \(durationSeconds) seconds")
    closeMainMenuIfVisible()
    // Suppress the floating timer popup for allowed-app habits — their progress + Skip/Postpone are in
    // the menu now, so the popup is redundant. Breaks and ordinary habits still show it. Covers every
    // call site centrally (rather than gating each one) by keying off the habit currently playing.
    let hideWindow = !isFocusBreak && (currentHabitPlaying?.openSpecificApps ?? false)
    floatingTopBarVcObj?.showTimerWindow(durationSeconds: durationSeconds, msg: msg, isFocusBreak: isFocusBreak, currentTimerValue: currentTimerValue, hideWindow: hideWindow)

    // Lay these out normally even when suppressed — showTimerWindow only makes the window invisible
    // (alpha 0), so the 2-minutes-left reminder reveals the whole bar.
    if floatingTopBarVcObj != nil {
        floatingTopBarVcObj?.boxMain.isHidden = false
        floatingTopBarVcObj?.boxMoreItems.isHidden = false
    }
}

func showCustomBlockingScheduleStartPopUp(scheduleName: String, scheduleTime: String){
    addLog(text:"show Custom Blocking Schedule Start PopUp for:- \(scheduleTime)")
    closeMainMenuIfVisible()
    floatingTopBarVcObj?.lblScheduleName.stringValue = scheduleName
    floatingTopBarVcObj?.lblScheduleTime.stringValue = scheduleTime
    floatingTopBarVcObj?.boxCustomBlockingSchedule.isHidden = false
}

func showSmallTimerView(){
//    getsmallCountDownVcObject().view.isHidden = false
    floatingTopBarVcObj?.boxTimer.isHidden = false
    floatingTopBarVcObj?.timerBoxShown()
}

//***********SHOW Focus End Warning***************//

func showFocusEndWarningWindow(){
    addLog(text:"showFocusEndWarningWindow")
    getFocusEndWarningWindowObject().contentViewController = getFocusEndWarningVcObject()
    //    getFocusEndWarningWindowObject().window?.styleMask = .borderless
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    //    getFocusEndWarningWindowObject().window?.styleMask.remove(.closable)
    getFocusEndWarningWindowObject().window?.title = appName
    getFocusEndWarningWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (getFocusEndWarningVcObject().view.frame.width), y: screenFrame.height - (getFocusEndWarningVcObject().view.frame.height) - 22)) //  22 status bar heigh
    //    getFocusEndWarningWindowObject().window?.isMovableByWindowBackground = true
    getFocusEndWarningWindowObject().showWindow(nil)
}


//***********SHOW Custom Notification View***************//
func showCustomNotificationView(msg: String){
    if mainWindowControllerObj?.window?.isVisible ?? false{
        addLog(text:"show Custom Notification View")
        let _ = getCustomNotificationVcObject()
        getHabitsVcObject().view.addSubview(customNotificationVcObj!.view)
        getHabitsVcObject().view.addTopRightConstraints(subView: customNotificationVcObj!.view)
        customNotificationVcObj!.resetView(msg: msg)
    }
    
}


func isSmallCountDownTimerViewVisible()->Bool{
    if smallCountDownVcObj != nil{
        return !(floatingTopBarVcObj?.boxTimer.isHidden ?? false)
    }
    return false
}

func closeSmallCountDownTimerBoxIfVisible(){
    if isSmallCountDownTimerViewVisible(){
        smallCountDownVcObj?.closeTimerBox()
    }
}

func closeSmallCountDownTimerBoxIfVisibleForFocusBreak(){
    if isSmallCountDownTimerViewVisible(){
        if (smallCountDownVcObj?.isFocusBreak ?? false){
            smallCountDownVcObj?.closeTimerBox()
        }
    }
}


func closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak(){
    if isSmallCountDownTimerViewVisible(){
        if !(smallCountDownVcObj?.isFocusBreak ?? false){
            smallCountDownVcObj?.closeTimerBox()
        }
    }
}


func closeIntentionBlockedUrlsWinddowIfVisible(){
    if intentionBlockedUrlsWcObj != nil{
        if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            intentionBlockedUrlsWcObj?.window?.close()
        }
    }
}
func closeSetIntentionBlockedUrlsWinddowIfVisible(){
    if setIntentionBlockedUrlsWcObj != nil{
        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            setIntentionBlockedUrlsVcObj?.closeWindow()
        }
    }
}


func closeAlwaysBlockPopupsIfNotForeCurrentDomain(domain:String, runningApp:NSRunningApplication){
    if intentionBlockedUrlsWcObj != nil{
        if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            if intentionBlockedUrlsVcObj?.tabUrl != domain{
                intentionBlockedUrlsWcObj?.window?.close()
            }
        }
    }
    if setIntentionBlockedUrlsWcObj != nil{
        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                exitFullScreen(runningApp: runningApp)
            }else{
                setIntentionBlockedUrlsVcObj?.closeWindow()
            }
        }
    }
}

func closeIntentionBlockedAppsWinddowIfVisible(){
    if intentionBlockedAppsWcObj != nil{
        if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
            intentionBlockedAppsWcObj?.window?.close()
        }
    }
}

/// Which windows count as "inside" the menu when deciding whether a click dismissed it.
///
/// The menu's outside-click dismissal compared the clicked window against the menu window itself.
/// A sheet (the to-do task editor), a child window or an attached popover is a *different* NSWindow,
/// so the first click inside one of them read as a click outside the menu and tore the whole menu
/// down — which is what made typing a due date impossible: clicking the field closed the editor
/// before a character could be typed (report 2026-09-11_21-40-57).
///
/// Written against an opaque parent lookup so the walk is testable without real windows.
enum MenuWindowOwnership {
    /// Guards against a cycle in a malformed parent chain; menu sheets nest no deeper than this.
    static let maxDepth = 8

    static func isOwned(_ window: AnyObject, by menu: AnyObject, parent: (AnyObject) -> AnyObject?) -> Bool {
        var current: AnyObject? = window
        for _ in 0...maxDepth {
            guard let candidate = current else { return false }
            if candidate === menu { return true }
            current = parent(candidate)
        }
        return false
    }

    /// A window's owner for this purpose: the window it is a sheet on, else its parent window.
    static func owner(of window: NSWindow) -> NSWindow? { window.sheetParent ?? window.parent }

    static func isOwned(_ window: NSWindow, by menu: NSWindow) -> Bool {
        isOwned(window as AnyObject, by: menu as AnyObject) { candidate in
            (candidate as? NSWindow).flatMap(owner(of:))
        }
    }
}
