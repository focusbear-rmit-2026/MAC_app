//
//  addTaskVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/09/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
class addTaskVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var boxAverageTabCount: NSBox!
    @IBOutlet weak var boxAverageTimeSpent: NSBox!
    @IBOutlet weak var btnMoreOptions: cursorButton!
    @IBOutlet weak var lblEnableAdvancedAnalyticsSetting: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTimeToday: NSTextField!
    @IBOutlet weak var boxFocusAlignmentScore: NSBox!
    @IBOutlet weak var btnEnableAdvancedAnalytics: underLineButton! // not in use
    @IBOutlet weak var lblDeepWorkTimeToday: NSTextField!
    @IBOutlet weak var tabView: NSTabView!
    @IBOutlet weak var btnContinueHabit: Button!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnEndFocusSession: Button!
    @IBOutlet weak var btnExtendSession: Button!
    @IBOutlet weak var popUpBtnSelectMinutes: NSPopUpButton!
    @IBOutlet weak var lblSelectMinutesToExtend: NSTextField!
    @IBOutlet weak var lblTitleExtendFocus: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblIntention: NSTextField!
    @IBOutlet weak var lblTitleTime: NSTextField!
    @IBOutlet weak var lblTitleAppOrSite: NSTextField!

    @IBOutlet weak var lblAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblDeepFocusTime: NSTextField!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleAverageTimeSpentPerTab: NSTextField!
    @IBOutlet weak var lblTitleDeepWorkTime: NSTextField!
    @IBOutlet weak var lblTitleFocusAlignmentScore: NSTextField!
    @IBOutlet weak var lblTitleStats: NSTextField!
    @IBOutlet weak var lblTabCount: NSTextField!
    @IBOutlet weak var lblTitleTabCount: NSTextField!
    
    @IBOutlet weak var tabTasks: NSTabViewItem!
    @IBOutlet weak var tabStats: NSTabViewItem!
    @IBOutlet weak var webView: WKWebView!
    
    let handler = MessageHandler()
    var isAddingTask = false
    var arrAllAppsTabsData = [[String:Any]]()
    var hiddenTaskTabViewItem: NSTabViewItem?
    var alertExtendPostpone: NSAlert?
    private var approvedExtensionMinutes: Int?
    var extensionMinutesForPostpone: Int {
        approvedExtensionMinutes ?? Int(popUpBtnSelectMinutes.title) ?? 0
    }
    let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
    var focusModeFocusedTitles = [String]()
    var focusModeDecentTitles = [String]()
    var focusModeDistractedTitles = [String]()
    var titleExtendFocusMode = "You are doing well!"
    /// Generic completion titles for sessions without an alignment score (or the default focus mode);
    /// one is picked at random so the popup doesn't always read the same.
    var focusModeCompleteTitles = [String]()
    
    /// A random generic completion title; `titleExtendFocusMode` only if the list is empty.
    func randomCompletionTitle() -> String {
        focusModeCompleteTitles.randomElement() ?? titleExtendFocusMode
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.webView.navigationDelegate = self
        
        webView.configuration.userContentController.add(handler, name: "submit_completed_tasks")
        webView.configuration.userContentController.add(handler, name: "get_selected_tasks")
        webView.configuration.userContentController.add(handler, name: "close_todo_task_ui")
        webView.configuration.userContentController.add(handler, name: "close_todo_focus_end_ui")
        webView.configuration.userContentController.add(AccessTokenRequestHandler.shared, name: AccessTokenRequestHandler.messageName)
        
        btnEnableAdvancedAnalytics.titleColor = NSColor.systemBlue
        
        focusModeFocusedTitles = ["You crushed it!", "You were in the zone!", "Deep work accomplished!"]
        focusModeDecentTitles = ["Not bad", "Decent session"]
        focusModeDistractedTitles = ["A few distractions crept in", "Lock in your focus for the next one"]
        focusModeCompleteTitles = ["Nice focus!", "Is your middle name Focus?", "That's how it's done!", "Another block in the bag", "Focus level: legendary", "Your future self says thanks"]
        
        
        
        
        btnMoreOptions.title = "More Stats"
        lblTitleStats.stringValue = "Stats"
        lblTitleFocusAlignmentScore.stringValue = "Focus Alignment Score"
        lblTitleDeepWorkTime.stringValue = "Deep work time this session"
        lblTitleDeepWorkTimeToday.stringValue = "Total deep work time today"
        lblTitleAverageTimeSpentPerTab.stringValue = "Average Time Spent per Tab/App"
        lblTitleTabCount.stringValue = "Average tab count"
        lblTitleAppOrSite.stringValue = "App or site"
        lblTitleTime.stringValue = "Time"
        lblEnableAdvancedAnalyticsSetting.stringValue = "Enable the Advanced analytics setting to view detailed data about app and browser tab usage during focus mode. You can turn this on in Preferences > Settings > Advanced > Privacy (Geek mode required)."
        btnEnableAdvancedAnalytics.title = "Enable advanced analytics"
        
        
        tabStats.label = "Stats"
        tabTasks.label = "Tasks"
        btnExtendSession.title = "Extend Session"
        btnEndFocusSession.title = "End focus session"
        lblSelectMinutesToExtend.stringValue = "Select minutes to extend:"
        lblTitleExtendFocus.stringValue = "Still in the flow? Extend the session"
        lblIntention.stringValue = "Your intention for this focus mode was:- \"<INTENTION>\""
        lblTitle.stringValue = randomCompletionTitle()
        
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                lblTitleStats.stringValue = focusCompletedInfo.value(forKey: "titleStats") as? String ?? lblTitleStats.stringValue
                lblTitleFocusAlignmentScore.stringValue = focusCompletedInfo.value(forKey: "titleFocusAlignmentScore") as? String ?? lblTitleFocusAlignmentScore.stringValue
                lblTitleDeepWorkTime.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTime") as? String ?? lblTitleDeepWorkTime.stringValue
                lblTitleDeepWorkTimeToday.stringValue = focusCompletedInfo.value(forKey: "titleDeepWorkTimeToday") as? String ?? lblTitleDeepWorkTimeToday.stringValue
                lblTitleAverageTimeSpentPerTab.stringValue = focusCompletedInfo.value(forKey: "titleTimeSpentPerTab") as? String ?? lblTitleAverageTimeSpentPerTab.stringValue
                lblTitleTabCount.stringValue = focusCompletedInfo.value(forKey: "titleTabCount") as? String ?? lblTitleTabCount.stringValue
                lblTitleAppOrSite.stringValue = focusCompletedInfo.value(forKey: "titleAppOrSite") as? String ?? lblTitleAppOrSite.stringValue
                lblTitleTime.stringValue = focusCompletedInfo.value(forKey: "titleTime") as? String ?? lblTitleTime.stringValue
                btnEnableAdvancedAnalytics.title = focusCompletedInfo.value(forKey: "buttonEnableAdvancedAnalyticsText") as? String ?? btnEnableAdvancedAnalytics.title
                lblEnableAdvancedAnalyticsSetting.stringValue = focusCompletedInfo.value(forKey: "enableAdvancedAnalyticsSettingText") as? String ?? lblEnableAdvancedAnalyticsSetting.stringValue
                
                
                tabStats.label = focusCompletedInfo.value(forKey: "titleStats") as? String ?? tabStats.label
                tabTasks.label = focusCompletedInfo.value(forKey: "tabTasksText") as? String ?? tabTasks.label
                
                btnExtendSession.title = focusCompletedInfo.value(forKey: "buttonExtendSessionText") as? String ?? btnExtendSession.title
                btnEndFocusSession.title = focusCompletedInfo.value(forKey: "buttonEndFocusSessionText") as? String ?? btnEndFocusSession.title
                lblSelectMinutesToExtend.stringValue = focusCompletedInfo.value(forKey: "extendFocusMinutesText") as? String ?? lblSelectMinutesToExtend.stringValue
                lblTitleExtendFocus.stringValue = focusCompletedInfo.value(forKey: "askExtendFocusText") as? String ?? lblTitleExtendFocus.stringValue
                lblIntention.stringValue = focusCompletedInfo.value(forKey: "intentionText") as? String ?? lblIntention.stringValue
                titleExtendFocusMode = focusCompletedInfo.value(forKey: "titleExtendFocusMode") as? String ?? titleExtendFocusMode
                btnMoreOptions.title = focusCompletedInfo.value(forKey: "buttonMoreOptionsText") as? String ?? btnMoreOptions.title
                focusModeFocusedTitles = focusCompletedInfo.value(forKey: "focusModeFocusedTitles") as? [String] ?? focusModeFocusedTitles
                focusModeDecentTitles = focusCompletedInfo.value(forKey: "focusModeDecentTitles") as? [String] ?? focusModeDecentTitles
                focusModeDistractedTitles = focusCompletedInfo.value(forKey: "focusModeDistractedTitles") as? [String] ?? focusModeDistractedTitles
                focusModeCompleteTitles = focusCompletedInfo.value(forKey: "focusModeCompleteTitles") as? [String] ?? focusModeCompleteTitles
                
            }
        }
        lblTitle.stringValue = randomCompletionTitle()
        btnContinueHabit.title = buttonContinueText
        
        popUpBtnSelectMinutes.removeAllItems()
        popUpBtnSelectMinutes.addItems(withTitles: ["5", "10", "15", "20", "25", "30", "45", "90"])
        popUpBtnSelectMinutes.selectItem(at: 2)
    }
    override func viewWillDisappear() {
        isWebViewUrlLodded = false
        
        //        update all tags because it may be posssible that user has created some tags in webview
        allApiObject.getFocusModeTags(completionHandler: {arrJson in
            
        })
    }
    
    var isWebViewUrlLodded = false
    func reloadData(isAddingTask:Bool, allowExtend:Bool, isHabitGoing:Bool){
        self.isAddingTask = isAddingTask
        
        arrAllAppsTabsData.removeAll()
        
        
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            if isHabitGoing{
                arrAllAppsTabsData = focusCompletedForActivityVcObj?.arrAllAppsTabsData ?? []
            }else{
                arrAllAppsTabsData = focusCompletedVcObj?.arrAllAppsTabsData ?? []
            }
            btnEnableAdvancedAnalytics.isHidden = true
            lblEnableAdvancedAnalyticsSetting.isHidden = true
        }else{
            arrAllAppsTabsData.removeAll()
//            if isHabitGoing{
//                btnEnableAdvancedAnalytics.isHidden = true
//                lblEnableAdvancedAnalyticsSetting.isHidden = false
//            }else{
//                btnEnableAdvancedAnalytics.isHbtnEnableAdvancedAnalytics.isHidden = false
//                lblEnableAdvancedAnalyticsSetting.isHidden = true
//            }
            btnEnableAdvancedAnalytics.isHidden = true
            lblEnableAdvancedAnalyticsSetting.isHidden = false
        }
        
        tblView.reloadData()

        lblFocusAlignmentScore.stringValue = "\(currentFocusAlignmentScore)%"
        let arrAllTabsCount = tabMatricsObject.arrAllTabsCount
        let sumOfCount =  arrAllTabsCount.reduce(0, +)
        if arrAllTabsCount.count > 0{
            let average = sumOfCount / arrAllTabsCount.count
            lblTabCount.stringValue = "\(average)"
        }else{
            lblTabCount.stringValue = "0"
        }
        let duration = Double(focusModeActualDurationPerformed)
        var finalDuration = duration
        if SettingsManagerObject.isAIBlockingEnabled(){
            boxFocusAlignmentScore.isHidden = false
            let score = currentFocusAlignmentScore
            let deepWorkDurationForAlignmentScore = (duration * score) / 100
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(deepWorkDurationForAlignmentScore))
            finalDuration = deepWorkDurationForAlignmentScore
            
            if currentFocusAlignmentScore > 90 {
                lblTitle.stringValue = focusModeFocusedTitles.randomElement() ?? ""
            }else if currentFocusAlignmentScore > 70{
                lblTitle.stringValue = focusModeDecentTitles.randomElement() ?? ""
            }else{
                lblTitle.stringValue = focusModeDistractedTitles.randomElement() ?? ""
            }
            for i in 0..<arrFocusType.count{
                if arrFocusType[i]["id"] as? String  == focusCompletedVcObj?.currentFocusModeId ?? ""{
                    if let isDefault = arrFocusType[i]["isDefault"] as? Bool{
                        if  isDefault{
                            lblTitle.stringValue = randomCompletionTitle()
                        }
                    }
                    break;
                }
            }
            
        }else{
            lblTitle.stringValue = randomCompletionTitle()
            
            boxFocusAlignmentScore.isHidden = true
            lblDeepFocusTime.stringValue = getStringTimeFromSeconds(seconds: Int(duration))
        }
        let totalDeepFocusedTimeToday = totalDeepFocusedTime + finalDuration
        lblDeepWorkTimeToday.stringValue = getStringTimeFromSeconds(seconds: Int(totalDeepFocusedTimeToday))

        
        
        if isHabitGoing{
            lblAverageTimeSpentPerTab.stringValue = focusCompletedForActivityVcObj?.lblAverageTimeSpentPerTab.stringValue ?? "" 
        }else{

            if mainWindowControllerObj?.window?.isVisible ?? false{
                if getHabitsVcObject().habitsView.subviews.first == focusCompletedFullScreenVcObj?.view{
                    lblAverageTimeSpentPerTab.stringValue = focusCompletedFullScreenVcObj?.lblAverageTimeSpentPerTab.stringValue ?? ""
                }else{
                    if focusCompletedVcObj?.lblAverageTimeSpentPerTab != nil{
                        lblAverageTimeSpentPerTab.stringValue = focusCompletedVcObj?.lblAverageTimeSpentPerTab.stringValue ?? ""
                    }
                }
            }else{
                if focusCompletedVcObj?.lblAverageTimeSpentPerTab != nil{
                    lblAverageTimeSpentPerTab.stringValue = focusCompletedVcObj?.lblAverageTimeSpentPerTab.stringValue ?? ""
                }
            }
        }

        var intentionText = "Your intention for this focus mode was:- \"<INTENTION>\""
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                intentionText = focusCompletedInfo.value(forKey: "intentionText") as? String ?? intentionText
            }
        }
        lblIntention.stringValue = intentionText.replacingOccurrences(of: "<INTENTION>", with: whatToAchieveInFocusBlock)
        btnExtendSession.isSecondaryButton = true

        if isHabitGoing{
            btnContinueHabit.isHidden = false
            btnExtendSession.isHidden = true
            btnEndFocusSession.isHidden = true
            lblTitleExtendFocus.isHidden = true
            lblSelectMinutesToExtend.isHidden = true
            popUpBtnSelectMinutes.isHidden = true
        }else{
            if allowExtend{
                btnContinueHabit.isHidden = true
                btnExtendSession.isHidden = false
                btnEndFocusSession.isHidden = false
                lblTitleExtendFocus.isHidden = false
                lblSelectMinutesToExtend.isHidden = false
                popUpBtnSelectMinutes.isHidden = false
            }else{
                btnContinueHabit.isHidden = false
                btnExtendSession.isHidden = true
                btnEndFocusSession.isHidden = true
                lblTitleExtendFocus.isHidden = true
                lblSelectMinutesToExtend.isHidden = true
                popUpBtnSelectMinutes.isHidden = true
            }
        }
        
        if !focusModeTaskStringIsEmpty(){
            loadRequest()
            restoreTaskTabViewItem()
        }else{
            hideTaskTabViewItem()
        }
        reloadMoreOptionsState()
    }
    
    // Hide a tab item
    func hideTaskTabViewItem() {
        if hiddenTaskTabViewItem == nil{
            let itemToHide = tabView.tabViewItem(at: 1)
            hiddenTaskTabViewItem = itemToHide
            tabView.removeTabViewItem(itemToHide)
        }
    }
    
    // Restore the hidden tab item
    func restoreTaskTabViewItem() {
        if let itemToRestore = hiddenTaskTabViewItem {
            tabView.addTabViewItem(itemToRestore)
            hiddenTaskTabViewItem = nil
        }
    }
    
    func loadRequest(){
        if !isWebViewUrlLodded{
            let stringTime = getStringFromDateInUtc(date: Date(), dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            var webUrl:String = ""
            if self.isAddingTask{
                webUrl = "https://dashboard.focusbear.io/webview/todo-list?bust_cache=$\(stringTime)"
            }else{
                webUrl = "https://dashboard.focusbear.io/webview/focus-end?bust_cache=$\(stringTime)"
            }
            let link = URL(string:webUrl)!
            let request = URLRequest(url: link)
            isWebViewUrlLodded = true
            self.webView.load(request)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                if self.isAddingTask{
                    self.setAccessTokenToWebView()
                }else{
                    self.setAccessTokenAndTaksToWebView()
                }
            }
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleLoadError(webView: webView)
    }
  

    var webViewLoadFailedVcObj:webViewLoadFailedVc?
    func removeWebViewLoadFailedView(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.view.removeFromSuperview()
            }
        }
    }
   
    func handleLoadError(webView: WKWebView) {
        if webViewLoadFailedVcObj != nil{
            if webView.subviews.contains(webViewLoadFailedVcObj!.view){
                webViewLoadFailedVcObj?.reloadData()
                return;
            }
        }
        webViewLoadFailedVcObj = getWebViewLoadFailedVcObject()
        webViewLoadFailedVcObj!.customDelegate = self
        webViewLoadFailedVcObj?.webView = webView
        webView.addSubview(webViewLoadFailedVcObj!.view)
        webView.addConstraints(subView: webViewLoadFailedVcObj!.view)
        webViewLoadFailedVcObj?.reloadData()
    }
    
    func reloadClicked(webView:WKWebView){
        isWebViewUrlLodded = false
        loadRequest()
    }
    
    // Re-inject the freshly refreshed token via the same loader used on initial
    // load for the current mode (see webView(_:didFinish:)).
    func applyRefreshedAccessToken(requestId: String) {
        if isAddingTask {
            setAccessTokenToWebView(requestId: requestId)
        } else {
            setAccessTokenAndTaksToWebView(requestId: requestId)
        }
    }

    func setAccessTokenToWebView(requestId: String? = nil){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\"}"
        if let requestId = requestId {
            stringJson = String(stringJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadAccessTokenForToDo) { loadAccessTokenForToDo(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }

    func setAccessTokenAndTaksToWebView(requestId: String? = nil){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        
        let totalDuration = focusModeActualDurationPerformed / 60
        
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":\(focusModeTaskString),\"total_duration\":\(totalDuration),\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\"}"
        if let requestId = requestId {
            stringJson = String(stringJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
        }
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadTasks) { loadTasks(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
        })
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        if !isAddingTask{
            allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-closed", metadata: [:])
        }
        if presentingViewController != nil { self.dismiss(self) }   // guard: dismissing a non-presented VC throws NSInternalInconsistencyException (crash 1A8, when a sheet is force-ended during quit)
    }
    
    @IBAction func btnExtendSessionClicked(_ sender: Any) {
        approvedExtensionMinutes = nil
        let requestedMinutes = Int(popUpBtnSelectMinutes.title) ?? 0
        FocusSessionExtension.askWhyMoreTimeIsNeeded(minutes: requestedMinutes, presenter: self, restarting: true) { [weak self] minutes in
            guard let self = self, minutes > 0 else { return }
            self.approvedExtensionMinutes = minutes
            self.continueExtensionAfterApproval(minutes: minutes)
        }
    }

    private func continueExtensionAfterApproval(minutes requestedMinutes: Int) {
        let totalMinutes = FocusSessionExtension.cutoffLimitedMinutes(requestedMinutes, from: nil)
        guard totalMinutes > 0 else { return }
        // A focus session running under a routine postpone completed on its own: the postpone timer
        // already resumed the routine, so currentState is back to ._NOTHING_ and the live guard below
        // misses it — we'd extend focus WITHOUT re-covering the habits, and they interrupt seconds
        // later (#2213). Re-postpone from the persisted last-postpone state so the extend keeps them
        // covered.
        if currentState == ._NOTHING_, let resumingState = routinePostponeStateToReCoverOnExtend() {
            rePostponeForExtendAfterCompletion(state: resumingState, totalMinutes: totalMinutes)
            return
        }
        if currentState == ._POSTPONE_MORNING_HABIT_ || currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
            if getHabitsVcObject().postponeTimer != nil {
                if getHabitsVcObject().postponeTimer!.isValid{
                    let currentTime = Date()
                    let breakTime = getHabitsVcObject().postponeTimer!.fireDate
                    let diffMinute = Calendar.current.dateComponents([.minute], from: currentTime, to: breakTime).minute ?? 0
                    if diffMinute < totalMinutes{
                        alertExtendPostpone = NSAlert()
                        alertExtendPostpone!.setSharingType()
                        alertExtendPostpone!.messageText = "Focus duration is longer than habit postpone duration."
                        alertExtendPostpone!.informativeText = "You may want to extend the postpone duration to match the focus session duration. Click on the desired button to start the focus session."
                        var buttonExtendPostponeText = "Extend postpone duration"
                        var buttonDoNotExtendPostponeText = "Do not extend postpone duration"
                        
                        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
                            alertExtendPostpone!.messageText = pomodoroInfo.value(forKey: "alertExtendPostponeText") as? String ?? alertExtendPostpone!.messageText
                            alertExtendPostpone!.informativeText = pomodoroInfo.value(forKey: "alertExtendPostponeDescription") as? String ?? alertExtendPostpone!.informativeText
                            buttonExtendPostponeText = pomodoroInfo.value(forKey: "buttonExtendPostponeText") as? String ?? buttonExtendPostponeText
                            buttonDoNotExtendPostponeText = pomodoroInfo.value(forKey: "buttonDoNotExtendPostponeText") as? String ?? buttonDoNotExtendPostponeText
                        }
                        alertExtendPostpone!.alertStyle = NSAlert.Style.warning
                        alertExtendPostpone!.addButton(withTitle: buttonExtendPostponeText)
                        alertExtendPostpone!.addButton(withTitle: buttonDoNotExtendPostponeText)
                        
                        alertExtendPostpone!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            let totalMinutes = FocusSessionExtension.cutoffLimitedMinutes(totalMinutes, from: nil)
                            guard totalMinutes > 0 else { return }
                            if modalResponse == .alertFirstButtonReturn{
                                if currentState == ._POSTPONE_MORNING_HABIT_{
                                    if SettingsManagerObject.isEasySkipEnabled{
                                        getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        self.extendFocusMode()
                                    }else{
                                        if SettingsManagerObject.isPasswordRequireInPostponeMorning && shouldAskPassword(forPostpone: true){
                                            self.presentAsSheet(self.enterPasswordVcObj!)
                                            self.enterPasswordVcObj?.parentVc = self
                                        }else{
                                            getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                            self.extendFocusMode()
                                        }
                                    }
                                }else if currentState == ._POSTPONE_EVENING_HABIT_ || currentState == ._POSTPONE_FOCUS_SUMMARY_{
                                    
                                    var shouldAskPasswordForEvening = false
                                    if shouldAskPassword(forPostpone: true) &&  !SettingsManagerObject.isEasySkipEnabled{
                                        if isCutOffTimeGoing(){
                                            if SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff{
                                                shouldAskPasswordForEvening = true
                                            }
                                        }else{
                                            if SettingsManagerObject.isPasswordRequireInPostponeEvening{
                                                shouldAskPasswordForEvening = true
                                            }
                                        }
                                    }
                                    if shouldAskPasswordForEvening{
                                        self.presentAsSheet(self.enterPasswordVcObj!)
                                        self.enterPasswordVcObj?.parentVc = self
                                    }else{
                                        // This branch is only reached when currentState is
                                        // ._POSTPONE_EVENING_HABIT_ / ._POSTPONE_FOCUS_SUMMARY_, so the
                                        // evening check must be ._POSTPONE_EVENING_HABIT_ — comparing
                                        // against ._EVENING_HABIT_ can never be true, so evening habits
                                        // were never re-postponed on this path (#2213).
                                        if currentState == ._POSTPONE_EVENING_HABIT_{
                                            getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                                        }else if currentState == ._POSTPONE_FOCUS_SUMMARY_{
                                            getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
                                        }
                                        self.extendFocusMode()
                                    }
                                }
                            }else{
                                self.extendFocusMode()
                            }
                            
                        })
                        return;
                    }
                }
            }
        }
        
        extendFocusMode()
    }
    
    /// Re-postpone the routine when extending focus after the covering session already completed and
    /// currentState fell back to ._NOTHING_ (see routinePostponeStateToReCoverOnExtend / #2213). Mirrors
    /// the password / easy-skip gating of the live-postpone branch above.
    private func rePostponeForExtendAfterCompletion(state: CURRENTSTATE, totalMinutes: Int) {
        if state == ._POSTPONE_MORNING_HABIT_ {
            if !SettingsManagerObject.isEasySkipEnabled,
               SettingsManagerObject.isPasswordRequireInPostponeMorning, shouldAskPassword(forPostpone: true) {
                self.presentAsSheet(self.enterPasswordVcObj!)
                self.enterPasswordVcObj?.parentVc = self
            } else {
                getHabitsVcObject().postponeMorningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
                self.extendFocusMode()
            }
            return
        }
        // ._POSTPONE_EVENING_HABIT_ or ._POSTPONE_FOCUS_SUMMARY_
        var shouldAskPasswordForEvening = false
        if shouldAskPassword(forPostpone: true) && !SettingsManagerObject.isEasySkipEnabled {
            if isCutOffTimeGoing() {
                shouldAskPasswordForEvening = SettingsManagerObject.isPasswordRequireInPostponeEveningAfterCutOff
            } else {
                shouldAskPasswordForEvening = SettingsManagerObject.isPasswordRequireInPostponeEvening
            }
        }
        if shouldAskPasswordForEvening {
            self.presentAsSheet(self.enterPasswordVcObj!)
            self.enterPasswordVcObj?.parentVc = self
        } else {
            if state == ._POSTPONE_EVENING_HABIT_ {
                getHabitsVcObject().postponeEveningHabitFor(minutes: totalMinutes + 2, secondsToPostpone: nil, showAskFocusModeView: false, showAskIntention: false)
            } else {
                getHabitsVcObject().postponeFocusSummaryFor(minutes: totalMinutes + 2, showAskIntention: false)
            }
            self.extendFocusMode()
        }
    }

    func extendFocusMode(){
        // The button obtains approval before extending the routine's postpone timer or opening
        // password confirmation. Those continuations consume that same approved duration once.
        if let minutes = approvedExtensionMinutes {
            approvedExtensionMinutes = nil
            applyApprovedExtension(minutes: minutes)
            return
        }
        let minutes = Int(popUpBtnSelectMinutes.title) ?? 0
        FocusSessionExtension.askWhyMoreTimeIsNeeded(minutes: minutes, presenter: self, restarting: true) { [weak self] approved in
            self?.applyApprovedExtension(minutes: approved)
        }
    }

    private func applyApprovedExtension(minutes requestedMinutes: Int) {
        let minutes = FocusSessionExtension.cutoffLimitedMinutes(requestedMinutes, from: nil)
        guard minutes > 0 else { return }
        allApiObject.capturePosthog(event: "extend-focus-session-from-popup", metadata: [:])
        // A completed buddy needs its scoped blocking restored, but only after fresh approval.
        if let buddy = lastCompletedAccountabilityBuddySession {
            lastCompletedAccountabilityBuddySession = nil
            if presentingViewController != nil { self.dismiss(self) }
            startScopedAiFocusSession(goal: whatToAchieveInFocusBlock.isEmpty ? buddy.goal : whatToAchieveInFocusBlock,
                                      minutes: minutes,
                                      allowedApps: buddy.allowedApps, allowedUrls: buddy.allowedUrls,
                                      event: "accountability-buddy-session-extended",
                                      initialTasks: FocusSessionTaskQueue.decode(focusModeTaskString).filter { !$0.status.isCompleted })
        } else {
            applyExtension(minutes: minutes)
        }
    }

    private func applyExtension(minutes minutesToExtend: Int){
        if presentingViewController != nil { self.dismiss(self) }   // guard: dismissing a non-presented VC throws NSInternalInconsistencyException (crash 1A8, when a sheet is force-ended during quit)
        // An extension CONTINUES the session that is already running. Unlike STARTING a session
        // (AppDelegate.focusModeStartted, which deliberately supersedes a running custom blocking
        // schedule) it must not finish that schedule: doing so moved AI relevance checking onto a
        // different block list — or onto the global toggle — and so cancelled the AI blocking that was
        // in place for exactly the minutes the user asked for. See focusSessionExtension.swift.
        guard let currentFocusModeIndex = FocusSessionExtension.applyLocalExtension(
            focusModeId: focusCompletedVcObj?.currentFocusModeId ?? "",
            minutes: minutesToExtend) else {
            return;
        }

        applyAutoDoNotDisturb(forFocusModeAt: currentFocusModeIndex, includingDeepWorkAndDefault: true)
        
        workBeforeFocusBegin(index: currentFocusModeIndex)
        appdelegate!.setStatusBarButtonColorForFocusMode(color: nil, colorString:arrFocusType[currentFocusModeIndex]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        
        
        appdelegate?.setFocusModeTimerForExtendAfterComplete(hour: nil, minute: minutesToExtend)
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled && currentState != ._MICRO_BREAK_{
            showRunningFocusSessionWindow()
            leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
            leftMenuVcObj?.resetFocusModeTitle()
        }else{
            leftMenuVcObj?.focusModeOrFocusModeHabitStarted()
            leftMenuVcObj?.resetFocusModeTitle()
            if currentState != ._MICRO_BREAK_{
                mainWindowControllerObj?.window?.close()
            }else{
                leftMenuVcObj?.showBreaksView()
            }
        }
        
        if let finishTime = endFocusModeTime{
            // The server was told the session finished when it ended (#2678), so the extra minutes may
            // need a new session there rather than an extension of the finished one; the reporter knows.
            FocusSessionFinishReporter.shared.sessionExtended(
                focusModeId: arrFocusType[currentFocusModeIndex]["id"] as? String ?? "",
                from: Date(), until: finishTime)
        }
        updateAllFocusModes()
    }
    //self.view.window?.close()
    @IBAction func popUpBtnSelectMinutesClicked(_ sender: Any) {
    }
    
    @IBAction func btnEndFocusSessionClicked(_ sender: Any) {
        if presentingViewController != nil { self.dismiss(self) }   // guard: dismissing a non-presented VC throws NSInternalInconsistencyException (crash 1A8, when a sheet is force-ended during quit)
    }
    
    @IBAction func btnContinueHabitClicked(_ sender: Any) {
        if presentingViewController != nil { self.dismiss(self) }   // guard: dismissing a non-presented VC throws NSInternalInconsistencyException (crash 1A8, when a sheet is force-ended during quit)
    }
    
    @IBAction func btnEnableAdvancedAnalyticsClicked(_ sender: Any){ // not in use
        if SettingsManagerObject.isGeekModeEnabled{
            
            addLog(text: "[user-action] btnEnableAdvancedAnalyticsClicked")

            NSApplication.shared.activate(ignoringOtherApps: true)
        }else{
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = "This option is available in Geek mode only"
            
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    alert.messageText = focusCompletedInfo.value(forKey: "settingNotAvailableText") as? String ?? alert.messageText
                }
            }
            
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
                
                
            })
        }
    }
    
    func getStringTimeFromSeconds(seconds : Int)->String{
        if seconds == 0{
            return "0" + secondsSText
        }
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
        var stringTime: String = ""
        if h != 0{
            stringTime = "\(h)" + hoursHText
        }
        if m != 0{
            if stringTime.isEmpty{
                stringTime = "\(m)" + minutesMText
            }else{
                stringTime += " \(m)" + minutesMText
            }
        }
        if s != 0{
            if stringTime.isEmpty{
                stringTime = "\(s)" + secondsSText
            }else{
                stringTime += " \(s)" + secondsSText
            }
        }
        return stringTime
    }
    @IBAction func btnInfoFocusAlignmentClicked(_ sender: NSButton) {
        var msg = ""
        if SettingsManagerObject.isAIBlockingEnabled(){
            msg = "The % of the focus session that you spent on productive sites/apps based on Focus Bear's AI."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScoreAi") as? String ?? msg
                }
            }
        }else{
            msg = "The % of the focus session that you spent on productive sites/apps based on your list of blocked/allowed sites."
            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                    msg = focusCompletedInfo.value(forKey: "tooltipFocusAlignmentScore") as? String ?? msg
                }
            }
        }

        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoDeepWotkTimeThisSessionClicked(_ sender: NSButton) {
        var msg = "We multiply the focus session duration by the focus alignment score to get your deep work time"
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipDeepWotkTimeThisSession") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoTotalWotkTimeTodayClicked(_ sender: NSButton) {
        var msg = "Total deep work time accumulated from all focus sessions today, calculated using session duration and focus alignment score."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipTotalWotkTimeToday") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTimePerTabClicked(_ sender: NSButton) {
        var msg = "Focus Bear keeps track of how much time you spend in each browser tab. If you are constantly changing tabs, it indicates that you're probably multi tasking rather than sticking to one task."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTimePerTab") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAverageTabCountClicked(_ sender: NSButton) {
        var msg = "If you have a lot of tabs open, you're likely to get distracted by half finished work. Put the tasks in your to do list instead. Use Focus Bear's tab limiter feature to help avoid tab overwhelm."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAverageTabCount") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnInfoAppOrSiteClicked(_ sender: NSButton) {
        var msg = "This shows your top 5 apps/sites during this focus session. Data is only stored locally on your computer."
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                msg = focusCompletedInfo.value(forKey: "tooltipAppOrSite") as? String ?? msg
            }
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:340, autoCloseOnMouseExit: true)
    }
    
    
    @IBAction func btnMoreOptionsClicked(_ sender: Any) {
        if boxAverageTimeSpent.isHidden{
            expandMoreOptions()
            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusStatsExpanded)
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func reloadMoreOptionsState(){
        if let val = UserDefaults.standard.object(forKey: kUserdefaultsFocusStatsExpanded) as? Bool{
            if val{
                expandMoreOptions()
            }else{
                collapseMoreOptions()
            }
        }else{
            collapseMoreOptions()
            UserDefaults.standard.set(false, forKey: kUserdefaultsFocusStatsExpanded)
        }
    }
    
    func expandMoreOptions(){
        boxAverageTimeSpent.isHidden = false
        boxAverageTabCount.isHidden = false
        if SettingsManagerObject.isAIBlockingEnabled(){
            boxFocusAlignmentScore.isHidden = false
        }else{
            boxFocusAlignmentScore.isHidden = true
        }
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoDownTemplateName)
    }
    
    func collapseMoreOptions(){
        boxFocusAlignmentScore.isHidden = true
        boxAverageTimeSpent.isHidden = true
        boxAverageTabCount.isHidden = true
        btnMoreOptions.image = NSImage(named: NSImage.touchBarGoForwardTemplateName)
    }
    
}//NSTouchBarGoForwardTemplate


extension addTaskVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            return arrAllAppsTabsData.count
        }else{
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocsedCompletedItem"), owner: nil) as? tblCellFocsedCompletedItem {

            if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusAppTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }else if let title = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDomainTitle] as? String{
                cell.lblTitleName.stringValue = title
                cell.lblTitleName.toolTip = title
            }
            if let duration = arrAllAppsTabsData[row][tabMatricsObject.keyFocusDuration] as? Int{
                cell.lblDuration.stringValue = getStringTimeFromSeconds(seconds: duration)
                cell.progress.maxValue = Double(focusModeActualDurationPerformed)
                cell.progress.doubleValue = Double(duration)
            }
            
            
            return cell
        }
        
        return NSTableCellView()
    }

}
