//
//  ViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.


import Cocoa
import SwiftUI


class ViewController: NSViewController {
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var splitViewItemRightView: NSView!
    @IBOutlet weak var splitViewItemLeftView: NSView!
    @IBOutlet weak var boxTopButtons: NSBox!
    @IBOutlet weak var boxMinimize: NSBox!
    @IBOutlet weak var stackViewTopButtons: NSStackView!
    @IBOutlet weak var containerView: NSView!
    @IBOutlet weak var boxContainer: customBoxBg!
    
    
    var topButtonsTrackingArea: NSTrackingArea?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        topButtonsTrackingArea = NSTrackingArea.init(rect: stackViewTopButtons.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        stackViewTopButtons.addTrackingArea(topButtonsTrackingArea!)
        boxMinimize.isHidden = true

        splitViewItemLeftView.subviews.removeAll()
        splitViewItemLeftView.addSubview(getLeftMenuVcObject().view)
        splitViewItemLeftView.addConstraints(subView: getLeftMenuVcObject().view)

        // The sidebar's IB width (230) is a design-time placeholder, so at runtime the split view has
        // nothing pinning the left pane and collapses it (~113pt), clipping the menu labels ("Day
        // Plan", "Stop Focus Sess…", etc.). Give it a sensible *initial* width via the divider position
        // (once, after first layout) and let the left pane hold its width when the window resizes —
        // rather than a required width constraint, which pinned the pane (no manual resize) and
        // conflicted with the collapse/expand width changes ("Unable to simultaneously satisfy
        // constraints"). The user can still drag the divider to resize.
        splitView.setHoldingPriority(NSLayoutConstraint.Priority(260), forSubviewAt: 0)
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.splitView.subviews.count >= 2 else { return }
            self.splitView.setPosition(230, ofDividerAt: 0)
        }

        splitViewItemLeftView.addObserver(self, forKeyPath: "frame", options: [.old, .new], context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" {
            let width = (object as? NSView)?.frame.width ?? 0
            if width < 100{
                leftMenuVcObj?.boxMainItems.titleLabel.isHidden = true
                leftMenuVcObj?.boxToolsItems.titleLabel.isHidden = true
                leftMenuVcObj?.boxPreferences.titleLabel.isHidden = true
            }else{
                leftMenuVcObj?.boxMainItems.titleLabel.isHidden = false
                leftMenuVcObj?.boxToolsItems.titleLabel.isHidden = false
                leftMenuVcObj?.boxPreferences.titleLabel.isHidden = false
            }
        }
    }

    var shouldIgnoreViewWilDisappear = false
    var lastSmallWindowFrame:NSRect?
    func checkIsFullScreenNeeded() {
        if checkIsFullScreenEnabled(){
            if !(self.view.window?.styleMask.contains(.fullScreen) ?? false){// Don’t do this if the user is already in fullscreen. Wait until the user toggles back to a small screen, then check the setting again.
                shouldIgnoreViewWilDisappear = true
                mainWindowControllerObj?.showFullSizeWindow()// This will cause the viewWillDisappear function to be called
                boxTopButtons.isHidden = false
                lastSmallWindowFrame = self.view.window?.frame
                shouldIgnoreViewWilDisappear = false
            }
        }else{
            mainWindowControllerObj?.showSmallSizeWindow()
            boxTopButtons.isHidden = true
        }
        
        if checkIsFullScreenEnabled(){
            if !(self.view.window?.styleMask.contains(.fullScreen) ?? false){// Don’t do this if the user is already in fullscreen. Wait until the user toggles back to a small screen, then check the setting again.
                setframe()
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.setframe()
                    }
                }
            }
        }else{
            if self.view.window != nil{
                if isBreakActivityShowingWhileMeeting && currentState == ._MICRO_BREAK_{
                    let screenList = NSScreen.screens
                    for screen in screenList {
                        let screenHeight = screen.frame.height
                        let screenWidth = screen.frame.width
                        let width = self.view.window?.minSize.width ?? 1000
                        let height = self.view.window?.minSize.height ?? 1000
                        
                        let x = ((screenWidth/2) - (width/2))
                        let y = ((screenHeight/2) - (height/2))
                        
                        let newFrame = NSRect(origin: NSPoint(x: x, y: y), size: self.view.window!.minSize)
                        self.view.window?.setFrame(newFrame, display: true)
                        break;
                    }
                    
                }else{
                    if let screen = self.view.window?.screen{ //
                        self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
                    }else{
                        let screenList = NSScreen.screens
                        for screen in screenList {
                            self.view.window?.setFrame(screen.visibleFrame, display: true)
                            break;
                        }
                    }
                }
            }
        }
    }
    
    func showSmallScreen(showMinimumSize:Bool = false){
        mainWindowControllerObj?.showSmallSizeWindow()
        let screenList = NSScreen.screens
        
        if !(self.view.window?.styleMask.contains(.fullScreen) ?? false) && showMinimumSize{
            
          //  self.view.window?.center()
            let currentSize = self.view.frame.size
            let widthToSet = mainWindowControllerObj?.smallWindowAvgWidth ?? 500
            let heightToSet = mainWindowControllerObj?.smallWindowAvgHeight ?? 500
            let newSize = NSSize(width: widthToSet, height: heightToSet)
            
            
            // Calculate differences
            let widthDiff = abs(currentSize.width - newSize.width)
            let heightDiff = abs(currentSize.height - newSize.height)

            // Only set if difference > 100 px
            if widthDiff > 100 || heightDiff > 100 { // check added on 3/9/25 version 2.27.410
                self.view.window?.setContentSize(newSize)
            }
        }else{
            if let screen = self.view.window?.screen{ //
                self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
            }else{
                for screen in screenList {
                    self.view.window?.setFrame(screen.visibleFrame, display: true, animate: false)
                    break;
                }
            }
        }
        boxTopButtons.isHidden = true
    }

    @objc func setframe() {
        let screenList = NSScreen.screens
        for screen in screenList {
            self.view.window?.setFrame(NSMakeRect(NSMinX(screen.frame), NSMinY(screen.frame), NSWidth(screen.frame), NSHeight(screen.frame)), display: true) //  uncomment this line 
//            self.view.window?.setFrame(NSMakeRect(100, 100, NSWidth(screen.frame) - 200, NSHeight(screen.frame) - 200) , display: true)//  comment this //  do this
            
            break;
        }
    }//
    
    override func viewWillAppear() {
        super.viewWillAppear()
        // bug solved v 3.33.494 Option-clicking outside the window making blank screen when shows again
        // Normally, another flow restores the content inside containerView.
        // In some cases (e.g. Option-clicking outside the window), all subviews
        // may have been removed in viewWillDisappear() and not restored.
        // and user may click on dock icon to show window again
        // Delay the check slightly to allow the normal UI setup flow to complete.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            let viewsArr = self.containerView.subviews
            if viewsArr.count == 0{
                addLog(text: "InstallHabitVC - containerView is empty, restoring last selected view")
                if let leftMenuVcObj = leftMenuVcObj, let lastSelectedBox = leftMenuVcObj.lastSelectedBox{
                    leftMenuVcObj.selectableListBoxDidChangeSelectionByUser(lastSelectedBox)
                }
            }
        }
    }
    
    override func viewWillDisappear() {
        if !shouldIgnoreViewWilDisappear{
            removeSubViews()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == topButtonsTrackingArea{
            boxMinimize.isHidden = false
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == topButtonsTrackingArea{
            boxMinimize.isHidden = true
        }
    }
    
    @IBAction func btnMinimizeClicked(_ sender: Any) {
        addLog(text: "[user-action] button Minimize Clicked")// added on 10/4/25 in 1.21.356
        
        let fullScreen = mainWindowControllerObj?.window?.styleMask.contains(.fullScreen) ?? false
        let isPaused = timerViewcontrollerObj?.isActivityPaused ?? false
        addLog(text: "minimise: allowedActivity=\(isAllowedActivityHabitCurrentlyRunning) paused=\(isPaused) flag=\(isAllowedActivityHabitPlaying) focusAllowed=\(isAnyAllowedFocusModeActivityRunning) fullScreen=\(fullScreen) subviews=\(getHabitsVcObject().view.subviews.count)")

        // While an allowed-activity habit is ACTIVELY running, a floating timer keeps it going in the
        // background, so the minimise button should just get the main window out of the way — never the
        // abort/postpone flow. Check this BEFORE the subviews guard below so it works regardless of
        // what's layered in the habits view. The habit window is borderless (kiosk-style), so
        // miniaturize() is a no-op on it — close it instead; the floating timer keeps the habit running
        // and the user can reopen from the Dock. If the habit is PAUSED, the user isn't doing the
        // allowed activity, so fall through to the normal postpone flow instead.
        if isAllowedActivityHabitCurrentlyRunning && !isPaused {
            mainWindowControllerObj?.window?.close()
            return
        }

        // Otherwise minimise must go through the abort/postpone prompt — full-screen mode exists to
        // remove escape loopholes, so the window must NOT silently minimise from Help/Settings/Tools or
        // any other screen unless an allowed-activity habit is playing (handled above).
        let views = getHabitsVcObject().view.subviews
        if views.count != 1{// it means sub views are added so nothing will happen, user will need to close subviews first(logquantity view, password box)
            return
        }

        habitsVcObj?.abortCurrentState()
    }

    
    func newUrlOrAppAdded(){// show permissions if not added 
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You can block distracting websites and distracting apps. You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"

            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningSetDistractionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                
                if modalResponse == .alertFirstButtonReturn{
                    showExplainingPermissionsWindow(showingFromPomodoro: false)
                    self.view.window?.close()
                }
                
            })
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return;
        }
    }
 
    @objc func showLoaderView(){
        addLog(text: "Showing Loader")
        self.view.addSubview(getLoaderVcObj().view)
        self.view.addConstraints(subView: getLoaderVcObj().view)
    }
    
    @objc func hideLoaderView(){
        addLog(text: "Hide Loader")
        if loaderVcPbj != nil{
            if self.view.subviews.contains(loaderVcPbj!.view){
                loaderVcPbj?.view.removeFromSuperview()
            }
        }
    }

    func checkIsAnyUserInputSubViewAdded()->Bool{
        if logQuantityVcObj != nil{
            if self.view.subviews.contains(logQuantityVcObj!.view){
                return true
            }
        }
        
        if takeActivityNotesVcObj != nil{
            if self.view.subviews.contains(takeActivityNotesVcObj!.view){
                return true
            }
        }
        
        if focusCompletedForActivityVcObj != nil{
            if self.view.subviews.contains(focusCompletedForActivityVcObj!.view){
                return true
            }
        }
        return false
    }


    func showPasswordView(){
        self.view.addSubview(enterPasswordVcObj!.view)
        self.view.addConstraints(subView: enterPasswordVcObj!.view)
        enterPasswordVcObj?.removeConstraints()
        enterPasswordVcObj?.parentVc = nil
        enterPasswordVcObj?.pendingAction = nil
        enterPasswordVcObj?.cancelAction = nil
        addLog(text: "Showing enter password view")
    }


    func disableApp(){
        addLog(text: "App Deactivated by user (Aborted)")
        UserDefaults.standard.set(false, forKey: kUserdefaultsIsAppEnabled)
        SettingsManagerObject.disableAppWriteSettings()
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastAppAbortedDate)
        appdelegate?.quitAndRestartApp()
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    func removeSubViews(){
        let viewsArr = containerView.subviews
        for subview in viewsArr {
            subview.removeFromSuperview()
        }
        let views = self.view.subviews
        if views.count != 1{
            for subview in views {
                if subview != boxContainer{
                    subview.removeFromSuperview()
                }
            }
        }
        
    }
    

    func showAskOccupationVc(){
        addLog(text: "Showing Ask App Work view.")
        removeSubViews()
        
        containerView.addSubview(getAskOccupationVcObject().view)
        containerView.addConstraints(subView: getAskOccupationVcObject().view)
        currentState = ._ONBOARDING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showEnableAIBlockingVc(){
        addLog(text: "Showing Enable AI Blocking view.")
        removeSubViews()
        
        containerView.addSubview(getEnableAIBlockingVcObject().view)
        containerView.addConstraints(subView: getEnableAIBlockingVcObject().view)
        currentState = ._ONBOARDING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    

    
    func showOnboardingVc(){
        addLog(text: "Showing Onboarding view.")
        removeSubViews()
        
        containerView.addSubview(getOnboardingVcObject().view)
        containerView.addConstraints(subView: getOnboardingVcObject().view)
        currentState = ._ONBOARDING_
        currentAction = ._START_
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showAskLogInVc(){
        addLog(text: "Showing Ask LogIn view.")
        removeSubViews()
        
        containerView.addSubview(getAskLogInVcObject().view)
        containerView.addConstraints(subView: getAskLogInVcObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func showCustomLoginVc(){
        addLog(text: "Showing LogIn view.")
        removeSubViews()
        
        containerView.addSubview(getCustomLoginVcObject().view)
        containerView.addConstraints(subView: getCustomLoginVcObject().view)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func showCustomMessageView(msg:String){
        addLog(text: "show Custom Message View")
        self.view.addSubview(getCustomMessageVcObject().view)
        self.view.addConstraints(subView: getCustomMessageVcObject().view)
        customMessageVcObj?.lblMessage.stringValue = msg
    }
    
    func showOneClickSkipHabitView(completionHandler: @escaping() -> ()){
        addLog(text: "Show One Click Skip Habit View")
        self.view.addSubview(getSkipHabitVcObject().view)
        self.view.addConstraints(subView: getSkipHabitVcObject().view)
        getSkipHabitVcObject().requestAuthorization(
            action: {
                completionHandler()
            }
        )
    }
    
    
    @IBAction func btnHiddenClicked(_ sender: Any) {
        //mainWindowControllerObj?.window?.close()
    }
    
    func askPasswordForSettingsIfNeeded(){
        if isPasswordRequireInOpenSettings(){
            askPasswordForSettings()
        }
    }
    
    func askPasswordForSettings(){
        self.view.addSubview(getEnterPasswordVcObjForPreferences().view)
        self.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
        getEnterPasswordVcObjForPreferences().parentVc = nil
        getEnterPasswordVcObjForPreferences().pendingAction = nil
        getEnterPasswordVcObjForPreferences().cancelAction = nil
        enterPasswordVcObjForPreferences?.removeConstraints()
        addLog(text: "Showing enter password view inside edit habits")
    }
    
    func isEnterPasswordForPreferencesViewVisible()->Bool{
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(getEnterPasswordVcObjForPreferences().view){
                return true
            }
        }
        return false
    }
    
    func isEnterPasswordViewVisible()->Bool{
        if enterPasswordVcObj == nil{
            return false
        }
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                return true
            }
        }
        return false
    }
    
    func showHabitsView(){
        self.removeSubViews()
        containerView.addSubview(getHabitsVcObject().view)
        containerView.addConstraints(subView: getHabitsVcObject().view)
    }
    
    func showFocusSessionView(pomodoroView:NSView){
        self.removeSubViews()
        containerView.addSubview(pomodoroView)
        if containerView.subviews.contains(pomodoroView){// if auto super pomodoro has started then may be task player was shown from inside pomodoro so current view is not pomodoro after this. to prevent crash we are doing this  v 2.28.440
            containerView.addConstraints(subView: pomodoroView)
        }
    }
    
    func showConfirmBlockingScheduleView(){
        self.removeSubViews()
        containerView.addSubview(getConfirmBlockingScheduleCreationVcObj().view)
        containerView.addConstraints(subView: getConfirmBlockingScheduleCreationVcObj().view)
    }
    
    func showBrainDumpView(){
        self.removeSubViews()
        containerView.addSubview(getBrainDumpVcObject().view)
        containerView.addConstraints(subView: getBrainDumpVcObject().view)
    }
    
    func showBrowsersTabAuditView(){
        self.removeSubViews()
        containerView.addSubview(getBrowsersTabAuditVcObject().view)
        containerView.addConstraints(subView: getBrowsersTabAuditVcObject().view)
    }
    
    func showAllTracksView(){
        self.removeSubViews()
        containerView.addSubview(getAllTracksVcObj().view)
        containerView.addConstraints(subView: getAllTracksVcObj().view)
    }
    
    func showTaskView(){
        self.removeSubViews()
        if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            if taskPlayerVcObj == nil{
                getTaskPlayerVcObject().loadView()// handled in v2.27.435 otherwise app can be crash when focus resumes automatically after app opens(remaining focus mode)
            }
            containerView.addSubview(taskPlayerVcObj!.view)
            containerView.addConstraints(subView: taskPlayerVcObj!.view)
            if shouldReloadTaskPlayer{
                shouldReloadTaskPlayer = false
                taskPlayerVcObj?.reloadData(totalDuration: focusModeMinutesToPerform, intention:whatToAchieveInFocusBlock)
            }
        }else{
            containerView.addSubview(getTodoListToolVcObject().view)
            containerView.addConstraints(subView: getTodoListToolVcObject().view)
            todoListToolVcObj?.reloadData()
        }
    }
    
    func showFocusCompletedView(){
        self.removeSubViews()
        containerView.addSubview(focusCompletedVcObj!.view)
        containerView.addConstraints(subView: focusCompletedVcObj!.view)
    }
    
    func isFocusCompletedViewVisible()-> Bool{
        if let focusCompletedVcObj = focusCompletedVcObj, focusCompletedVcObj.isViewLoaded{
            if containerView.subviews.contains(focusCompletedVcObj.view){
                return true
            }
        }
        return false
    }
    
    func showFocusAbortedView(){
        self.removeSubViews()
        containerView.addSubview(abortingFocusModeVcObj!.view)
        containerView.addConstraints(subView: abortingFocusModeVcObj!.view)
    }
    
    
    
    func showMotivationView(){
        self.removeSubViews()
        containerView.addSubview(getSetUpVcObject().view)
        containerView.addConstraints(subView: getSetUpVcObject().view)
        if getSetUpVcObject().widthConstraint != nil{
            getSetUpVcObject().widthConstraint.isActive = false
        }
    }
    
    func showFocusModeState(){
        addLog(text: "showFocusModeState")
        self.removeSubViews()
        containerView.addSubview(getFocusModeStateVcObject().view)
        containerView.addConstraints(subView: getFocusModeStateVcObject().view)
    }
    
    func showHelpView(){
        self.removeSubViews()
        containerView.addSubview(getHelpVcObject().view)
        containerView.addConstraints(subView: getHelpVcObject().view)
    }

    func showBlocksPreferencesView(){
        allApiObject.capturePosthog(event: "open-blocking", metadata: [:])
        self.removeSubViews()
        containerView.addSubview(getTabStrictnessContainerVcObject().view)
        containerView.addConstraints(subView: getTabStrictnessContainerVcObject().view)
    }
    
    func showFocusPreferencesView(){
        showBlocksPreferencesView()
        getTabStrictnessContainerVcObject().showFocusPreferences()
    }
    
    func showSettingsView(){
        allApiObject.capturePosthog(event: "open-preferences", metadata: [:])
        self.removeSubViews()
        containerView.addSubview(getSettingsSplitViewControllerObject().view)
        containerView.addConstraints(subView: getSettingsSplitViewControllerObject().view)
    }

    // MARK: - Tools (surfaced in the left-menu TOOLS group, out of Settings > Add-Ons)

    func showFocusButtonToolView(){
        self.removeSubViews()
        if #available(macOS 11.0, *) {
            let host = NSHostingView(rootView: FocusButtonToolView(model: FocusButtonToolModel()))
            host.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(host)
            containerView.addConstraints(subView: host)
        }
    }

    func showTimeTrackerToolView(){
        self.removeSubViews()
        // Time Tracker is a Pro feature — gate to trial or subscription; otherwise show the upgrade screen.
        if #available(macOS 11.0, *), !(isPurchased || daysLeft > 0) {
            let model = TodayTrackerViewModel()
            model.hasAccess = false
            model.isLoading = false
            model.onUpgrade = { showUpgradeNowWindow() }
            hostScrolledFBTT(model)
            return
        }
        // If FBTT is installed and has tracked data, show its read-only Today view inline (PR #1956).
        // Host the SwiftUI view directly (not via TodayTrackerVc) so its window-oriented
        // preferredContentSize / fixed container frame don't resize the main window.
        if FBTTReader.isFBTTInstalled, FBTTReader.hasData, #available(macOS 11.0, *) {
            let model = TodayTrackerViewModel()
            model.onOpenFBTT = { openFBTTApp() }
            hostScrolledFBTT(model)
            DispatchQueue.global(qos: .userInitiated).async {
                let summary = FBTTReader.todaySummary()
                let f = DateFormatter(); f.dateFormat = "HH:mm"
                let stamp = f.string(from: Date())
                DispatchQueue.main.async {
                    model.summary = summary; model.updatedAt = stamp; model.isLoading = false
                }
            }
            return
        }
        guard #available(macOS 11.0, *) else { return }
        let view = ExternalToolView(
            title: "Time Tracker",
            description: "Focus Bear Time Tracker analyses your productivity by tracking time spent on websites and apps, and can auto-categorise logs into projects.",
            model: ExternalToolModel(appPath: "/Applications/Focus Bear Time Tracker.app",
                                     runningMatch: "focus bear time tracker"),
            primaryAction: {
                if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app") {
                    enableTimeTracker()
                } else if let url = URL(string: "https://downloads.focusbear.io/fbtt/FocusBearTimeTracker.dmg") {
                    NSWorkspace.shared.open(url)
                }
            })
        hostToolView(view)
    }

    func showLateNoMoreToolView(){
        self.removeSubViews()
        guard #available(macOS 11.0, *) else { return }
        let view = ExternalToolView(
            title: "Late No More",
            description: "An ADHD-friendly calendar notification app. Alerts escalate in intensity as the start time approaches, with verbal alerts (or a song) once you're late.",
            model: ExternalToolModel(appPath: "/Applications/Late No More.app",
                                     runningMatch: "late no more"),
            primaryAction: {
                let path = "/Applications/Late No More.app"
                if FileManager.default.fileExists(atPath: path) {
                    NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: path), configuration: NSWorkspace.OpenConfiguration())
                } else if let url = URL(string: "https://www.focusbear.io/late-no-more") {
                    NSWorkspace.shared.open(url)
                }
            })
        hostToolView(view)
    }

    @available(macOS 11.0, *)
    private func hostToolView<V: View>(_ view: V) {
        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(host)
        containerView.addConstraints(subView: host)
    }

    /// Host FBTTTodayView inline in the Tools pane. The pane's container hugs the hosting view's
    /// height, and FBTTTodayView normally fills its parent (maxHeight: .infinity), which made the
    /// pane grow past the bottom of the window. Render it at natural height (fillsParent: false)
    /// inside a ScrollView so tall content scrolls instead of overflowing.
    @available(macOS 11.0, *)
    private func hostScrolledFBTT(_ model: TodayTrackerViewModel) {
        let root = ScrollView { FBTTTodayView(model: model, fillsParent: false) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        hostToolView(root)
    }
    
    func showEditHabitsView(){
        allApiObject.capturePosthog(event: "open-edit-habits", metadata: [:])
        self.removeSubViews()
        containerView.addSubview(getSelectJsonVcObject().view)
        containerView.addConstraints(subView: getSelectJsonVcObject().view)
    }
    
    func toggleLeftPaneWidth(){
        guard splitView.subviews.count >= 2 else { return }
        let leftView = splitView.subviews[0]
        if leftView.frame.width == 50{
            expandLeftPanel()
        }else{
            collapseLeftPanel()
        }
    }
    
    func expandLeftPanel(){
        setLeftPaneWidthTemporarily(to: 230)
    }
    
    func collapseLeftPanel(){
        setLeftPaneWidthTemporarily(to: 50)
    }
    
    private var leftWidthConstraint: NSLayoutConstraint?

    func setLeftPaneWidthTemporarily(to newWidth: CGFloat) {
        guard splitView.subviews.count >= 2 else { return }

        let leftView = splitView.subviews[0]

        // Remove any previous constraint first
        if let existing = leftWidthConstraint {
            existing.isActive = false
            leftView.removeConstraint(existing)
            leftWidthConstraint = nil
        }

        // Disable autoresizing mask
        leftView.translatesAutoresizingMaskIntoConstraints = false

        // Create temporary width constraint
        let constraint = leftView.widthAnchor.constraint(equalToConstant: newWidth)
        constraint.priority = .required
        constraint.isActive = true
        leftWidthConstraint = constraint

        // Animate change
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            splitView.layoutSubtreeIfNeeded()
        }, completionHandler: {
            // Remove constraint so user can drag again
            if let existing = self.leftWidthConstraint {
                existing.isActive = false
                leftView.removeConstraint(existing)
                self.leftWidthConstraint = nil
            }
            leftView.translatesAutoresizingMaskIntoConstraints = true
            self.splitView.adjustSubviews()
        })
    }

    func onboardingFinishedUnlockMachine(){
        addLog(text: "Onboarding finished")
        removeSubViews()
        currentState = ._NOTHING_
        
        mainWindowControllerObj?.window?.close()
        hideBlankWindowInSecondaryMonitor()
        
        UserDefaults.standard.removeObject(forKey: kUserdefaultsPasswordSetInOnboarding)
        SettingsManagerObject.isFullScreenEnabled = false
        SettingsManagerObject.isCuddlyModeEnabled = true
        SettingsManagerObject.isEasySkipEnabled = true
        SettingsManagerObject.doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue = true
        SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
        SettingsManagerObject.immediatelyBlockDistractingSites = false
        SettingsManagerObject.immediatelyBlockDistractingApps = false
        
        SettingsManagerObject.isGeekModeEnabled = false // for new user app is in simple mode
        
        if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == false{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        }
        appdelegate!.needToCheckEmailVerification = false// if onboarding then dont show till menu tour is over
        appdelegate!.getUserSubscriptionInfo()
        appdelegate!.statusbutton?.action = nil
        UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                stageManagerObject.isStageManagerEnabled = stageManagerObject.checkIsStageManagerEnabled()
            }
        }
        
        // added 3.31.476
        addLog(text: "Onboarding completed: Forcefully writing user local device settings for first-time setup")
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
}

// MARK: - Focus Button tool screen (SwiftUI)
//
// Surfaces the Focus Button connection UI as a first-class Tools screen (out of Settings > Add-Ons).
// `SwiftUI.Button` is qualified because the app declares its own `Button` type.

@available(macOS 11.0, *)
final class FocusButtonToolModel: ObservableObject {
    @Published var isConnected = false
    @Published var statusMessage = ""
    @Published var connecting = false
    private var timer: Timer?
    private var savedOnError: ((String) -> Void)?
    private var savedOnConnected: ((String) -> Void)?

    func start() {
        // Remember the app's existing callbacks so leaving the screen doesn't clobber them.
        savedOnError = focusButtonServiceObject.onError
        savedOnConnected = focusButtonServiceObject.onDeviceConnected
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in self?.refresh() }
    }
    func stop() {
        timer?.invalidate(); timer = nil
        focusButtonServiceObject.onError = savedOnError
        focusButtonServiceObject.onDeviceConnected = savedOnConnected
    }
    func refresh() { isConnected = focusButtonServiceObject.isRunning }

    /// Manually disconnect: closes the serial port and stays disconnected (frees it for reflashing);
    /// tapping Connect again reconnects.
    func disconnect() {
        focusButtonServiceObject.manualDisconnect()
        connecting = false
        statusMessage = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.refresh() }
    }

    func connect() {
        connecting = true
        statusMessage = "Searching for a connected Focus Button…"
        focusButtonServiceObject.onDeviceConnected = { [weak self] _ in
            DispatchQueue.main.async { self?.connecting = false; self?.statusMessage = ""; self?.refresh() }
        }
        attemptConnect(retriesLeft: 4)
    }

    /// The serial port list (ORSSerialPortManager) can lag a second or two after a device is plugged
    /// in — the device often enumerates as cu.usbmodem* just AFTER the first scan — so re-scan a few
    /// times before giving up rather than failing on the first miss.
    private func attemptConnect(retriesLeft: Int) {
        focusButtonServiceObject.onError = { _ in }   // suppress per-attempt errors; we retry
        if focusButtonServiceObject.start() {
            // A port was found; the open/handshake is async — confirm shortly after.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                self.refresh()
                self.connecting = false
                self.statusMessage = self.isConnected
                    ? ""
                    : "Found the device but couldn't open the connection — try unplugging and replugging it."
            }
            return
        }
        if retriesLeft > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.attemptConnect(retriesLeft: retriesLeft - 1)
            }
        } else {
            connecting = false
            statusMessage = "No Focus Button found. Make sure it's plugged in with a data USB cable (not charge-only), then tap Connect again."
        }
    }
}

@available(macOS 11.0, *)
struct FocusButtonToolView: View {
    @ObservedObject var model: FocusButtonToolModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Focus Button").font(.system(size: 24, weight: .bold))
                HStack(spacing: 8) {
                    Circle().fill(model.isConnected ? Color.green : Color.gray).frame(width: 10, height: 10)
                    Text(model.isConnected ? "Connected" : "Not connected").foregroundColor(.secondary)
                }
                HStack(spacing: 10) {
                    if model.isConnected {
                        SwiftUI.Button("Disconnect") { model.disconnect() }
                    } else {
                        SwiftUI.Button("Connect") { model.connect() }
                            .disabled(model.connecting)
                    }
                    if model.connecting { ProgressView().scaleEffect(0.5).frame(width: 16, height: 16) }
                }
                if !model.statusMessage.isEmpty {
                    Text(model.statusMessage).font(.callout).foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Divider().padding(.vertical, 8)
                Text("Don't have a Focus Button yet? It's a physical timer for your desk that triggers focus sessions here.")
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let url = URL(string: "https://button.focusbear.io") {
                    SwiftUI.Link("Get yours from button.focusbear.io", destination: url)
                }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

// MARK: - External-app tool screen (Time Tracker / Late No More)

@available(macOS 11.0, *)
final class ExternalToolModel: ObservableObject {
    let appPath: String
    let runningMatch: String
    @Published var isInstalled = false
    @Published var isRunning = false
    private var timer: Timer?

    init(appPath: String, runningMatch: String) {
        self.appPath = appPath
        self.runningMatch = runningMatch
    }
    func start() {
        refresh()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }
    func stop() { timer?.invalidate(); timer = nil }
    func refresh() {
        isInstalled = FileManager.default.fileExists(atPath: appPath)
        isRunning = NSWorkspace.shared.runningApplications.contains {
            ($0.localizedName ?? "").lowercased().contains(runningMatch)
        }
    }
}

@available(macOS 11.0, *)
struct ExternalToolView: View {
    let title: String
    let description: String
    @ObservedObject var model: ExternalToolModel
    let primaryAction: () -> Void

    private var statusText: String {
        if model.isRunning { return "Running" }
        if model.isInstalled { return "Installed (not running)" }
        return "Not installed"
    }
    private var statusColor: Color {
        if model.isRunning { return .green }
        if model.isInstalled { return .orange }
        return .gray
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title).font(.system(size: 24, weight: .bold))
                HStack(spacing: 8) {
                    Circle().fill(statusColor).frame(width: 10, height: 10)
                    Text(statusText).foregroundColor(.secondary)
                }
                Text(description).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                SwiftUI.Button(model.isInstalled ? "Open" : "Download") { primaryAction() }
            }
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}
