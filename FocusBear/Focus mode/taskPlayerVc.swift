//
//  taskPlayerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/05/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit

class taskPlayerVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var btnStartFocusMusic: cursorButton!
    @IBOutlet weak var btnEndFocusSession: cursorButton!
    @IBOutlet weak var boxExtraOptions: NSBox!
    @IBOutlet weak var boxForHoverEffect: NSBox!
    @IBOutlet weak var boxBg: NSBox!
    //    @IBOutlet weak var constraintWidthTitleBar: NSLayoutConstraint!
    @IBOutlet weak var imgViewAppIcon: NSImageView!
    @IBOutlet weak var btnBackToOriginalPosition: mouseDownMoveWindowButton!
    @IBOutlet weak var boxTitleBar: NSBox!
    @IBOutlet weak var boxBackToOriginalPosition: NSBox!
    @IBOutlet weak var stackViewTopButtons: NSStackView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var boxMinimize: NSBox!
    @IBOutlet weak var boxMaximize: NSBox!
    @IBOutlet weak var boxClose: NSBox!
    
    @IBOutlet weak var imgViewMinimize: NSImageView!
    @IBOutlet weak var imgViewMaximize: NSImageView!
    @IBOutlet weak var imgViewClose: NSImageView!
    
    @IBOutlet weak var btnArrowRight: cursorButton!
    @IBOutlet weak var btnArrowLeft: cursorButton!
    var topButtonsTrackingArea: NSTrackingArea?
    let handler = MessageHandler()
    var totalDuration = 0
    var intention = ""
    var trackingAreaWebView: NSTrackingArea?
    
    var trackingAreaStopFocusMode: NSTrackingArea?
    var trackingAreaPlayFocusMusic: NSTrackingArea?
    
    var lastWindowFrame:NSRect = NSRect(x: 50, y: 50, width: 500, height: 500)
    var isSnapLeft = true
    var isSnappingGoing = false
    var isMouseEntering = false
    var isViewVisible = false
    var taskToLoadForFirstTime:String?
    var arrAllTasks = [NSDictionary]()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        webView.configuration.userContentController.add(handler, name: "close_focus_player_ui")
        webView.configuration.userContentController.add(handler, name: "send_new_task_added_to_todo_player")
        webView.configuration.userContentController.add(handler, name: "send_brain_dump_content")
        webView.configuration.userContentController.add(handler, name: "send_intention")
        
        topButtonsTrackingArea = NSTrackingArea.init(rect: stackViewTopButtons.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        stackViewTopButtons.addTrackingArea(topButtonsTrackingArea!)
        
        self.view.window?.backgroundColor = NSColor.clear
        
        
        createTrackingArea()
        
        
        btnArrowLeft.toolTip = "Snap to left"
        btnArrowRight.toolTip = "Snap to right"
        
        if let taskPlayerVcInfo = configjson.value(forKey: "taskPlayerVcInfo") as? NSDictionary{
            btnArrowLeft.toolTip = taskPlayerVcInfo.value(forKey: "toolTipSnapLeft") as? String ?? btnArrowLeft.toolTip
            btnArrowRight.toolTip = taskPlayerVcInfo.value(forKey: "toolTipSnapRight") as? String ?? btnArrowRight.toolTip
        }
        
        btnArrowLeft.isHidden = true
        btnArrowRight.isHidden = true
        boxBackToOriginalPosition.isHidden = true
        
        
        trackingAreaStopFocusMode = NSTrackingArea.init(rect: self.btnEndFocusSession.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.btnEndFocusSession.addTrackingArea(trackingAreaStopFocusMode!)
        
        trackingAreaPlayFocusMusic = NSTrackingArea.init(rect: self.btnStartFocusMusic.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.btnStartFocusMusic.addTrackingArea(trackingAreaPlayFocusMusic!)
    }
    
    override func viewWillAppear() {
        isViewVisible = true
        if isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            btnEndFocusSession.isHidden = true
        }else{
            btnEndFocusSession.isHidden = false
        }
    }
    
    
    override func viewWillDisappear() {
        isViewVisible = false
        if boxClose.isHidden{
            boxClose.isHidden = false
            boxMinimize.isHidden = false
            boxExtraOptions.isHidden = false
            self.view.window!.setFrame(lastWindowFrame, display: true)
            boxBackToOriginalPosition.isHidden = true
//            taskPlayerWcObj?.window?.styleMask.insert(.resizable)
            imgViewAppIcon.isHidden = true
        }
    }
    
    override func viewDidLayout() {
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
            }
        }
    }
    
    override func viewDidAppear() {
        updateTrackingAreaIfNeeded()
        if SettingsManagerObject.isAIBlockingEnabled() && !isBlockSuperDistractingFocusModeOn(){
            lblFocusAlignmentScore.isHidden = false
        }else{
            lblFocusAlignmentScore.isHidden = true
        }
    }
    
    func setFocusAlignmentScore(){
        if lblFocusAlignmentScore.isHidden{
            return;
        }
        let totalAlignmentScore:Double = currentFocusAlignmentScore//(totalAlignmentScore*100).rounded()/100
        var focusAlignmentScoreText = "Focus alignment score = <SCORE>"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            focusAlignmentScoreText = menuInfo.value(forKey: "focusAlignmentScoreText") as? String ?? focusAlignmentScoreText
        }
        lblFocusAlignmentScore.stringValue = focusAlignmentScoreText.replacingOccurrences(of: "<SCORE>", with: "\(totalAlignmentScore)%")
    }
    
    func updateTrackingAreaIfNeeded() {
        // Remove the old tracking area if it exists
        if let trackingArea = self.trackingAreaWebView {
            webView.removeTrackingArea(trackingArea)
        }
        // Recreate the tracking area with the updated bounds
        createTrackingArea()
    }
    
    func createTrackingArea(){
        trackingAreaWebView = NSTrackingArea.init(rect: self.boxBg.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.boxBg.addTrackingArea(trackingAreaWebView!)
    }
    
    func windowDragged(){
        if !boxBackToOriginalPosition.isHidden{
            let midXPoint = (self.view.window?.screen?.frame.midX ?? 0) - 1
            if (self.view.window?.frame.midX)! > midXPoint{
                isSnapLeft = false
            }else{
                isSnapLeft = true
            }
            if stageManagerObject.isStageManagerEnabled{
                isSnapLeft = false
            }
            mouseActiveSetSmallWindowFrame()
        }
    }

    
    override func mouseEntered(with event: NSEvent) {
        if isSnappingGoing{
            return;
        }
        if event.trackingArea == topButtonsTrackingArea{
            imgViewClose.isHidden = false
            imgViewMaximize.isHidden = false
            imgViewMinimize.isHidden = false
        }else if event.trackingArea == trackingAreaWebView || event.trackingArea == topButtonsTrackingArea{
            if btnBackToOriginalPosition.isHidden{
                btnBackToOriginalPosition.isHidden = false
                mouseActiveSetSmallWindowFrame()
                isMouseEntering = true
                DispatchQueue.global().async {
                    DispatchQueue.main.async {
                        self.isMouseEntering = false
                    }
                }
            }
        }else if event.trackingArea == trackingAreaPlayFocusMusic{
            var playFocusMusicTooltip = "Play focus music"
            if let taskPlayerVcInfo = configjson.value(forKey: "taskPlayerVcInfo") as? NSDictionary{
                playFocusMusicTooltip = taskPlayerVcInfo.value(forKey: "playFocusMusicTooltip") as? String ?? playFocusMusicTooltip
            }
            showTooltip(sender: btnStartFocusMusic, msg: playFocusMusicTooltip, preferredEdge: .minX, maxWidthVal: 250, autoCloseOnMouseExit: true)
        }else if event.trackingArea == trackingAreaStopFocusMode{
            var endFocusSessionTooltip = "End focus session"
            if let taskPlayerVcInfo = configjson.value(forKey: "taskPlayerVcInfo") as? NSDictionary{
                endFocusSessionTooltip = taskPlayerVcInfo.value(forKey: "endFocusSessionTooltip") as? String ?? endFocusSessionTooltip
            }
            showTooltip(sender: btnEndFocusSession, msg: endFocusSessionTooltip, preferredEdge: .minX, maxWidthVal: 250, autoCloseOnMouseExit: true)
        }
    }
    
    func mouseActiveSetSmallWindowFrame(){
        if !boxBackToOriginalPosition.isHidden{
            if isSnapLeft{
                let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 1
                animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 180, height: self.view.window!.frame.height), duration: 0)
                imgViewAppIcon.isHidden = true
            }else{
                let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 1
                let width:CGFloat = 180
                let xPoint = maxXPoint - width
                
                animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 180, height: self.view.window!.frame.height), duration: 0)
                imgViewAppIcon.isHidden = true
                
                
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        if isSnappingGoing{
            return;
        }
        if isMouseEntering{
            return;
        }
        if event.trackingArea == topButtonsTrackingArea{
            imgViewClose.isHidden = true
            imgViewMaximize.isHidden = true
            imgViewMinimize.isHidden = true
        }else if event.trackingArea == trackingAreaWebView || event.trackingArea == topButtonsTrackingArea{
            btnBackToOriginalPosition.isHidden = true
            if !boxBackToOriginalPosition.isHidden{
                if isSnapLeft{
                    let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 1
                    animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: 60, height: self.view.window!.frame.height), duration: 0)
                    imgViewAppIcon.isHidden = false
                }else{
                    let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 1
                    let width:CGFloat = 60
                    let xPoint = maxXPoint - width
                    animateWindowFrameChange(window: self.view.window!, newFrame: NSRect(x: xPoint , y: self.view.window!.frame.minY, width: width, height: self.view.window!.frame.height), duration: 0)
                    imgViewAppIcon.isHidden = false
                }
                
            }
        }else if event.trackingArea == trackingAreaStopFocusMode || event.trackingArea == trackingAreaPlayFocusMusic{
            closePopoverTooltipIfVisible()
        }
    }
    
    var isAnimationGoing = false
    func animateWindowFrameChange(window: NSWindow, newFrame: NSRect, duration: TimeInterval) {
        if isAnimationGoing{
            isAnimationGoing = false
            window.setFrame(newFrame, display: true, animate: false)
            return;
        }
        
        if duration == 0{
            window.setFrame(newFrame, display: true, animate: false)
        }else{
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = duration
                window.animator().setFrame(newFrame, display: true)
                isAnimationGoing = true
            }, completionHandler: {
                // Completion handler if needed
                print("Animation completed")
                self.isAnimationGoing = false
            })
        }
    }
    
    
    func reloadData(totalDuration:Int, intention:String){
        if !boxBackToOriginalPosition.isHidden{
            btnBackToOriginalPositionClicked(self)
        }
        
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        imgViewAppIcon.isHidden = true
        boxBackToOriginalPosition.isHidden = true
        boxClose.isHidden = false
        boxMinimize.isHidden = false
        boxExtraOptions.isHidden = false
        btnBackToOriginalPosition.isHidden = true
        
        self.totalDuration = totalDuration
        self.intention = intention
        if !self.intention.isEmpty{
            self.intention = self.intention.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self.intention
        }
        setAccessTokenToWebView()
        boxBackToOriginalPosition.isHidden = true
        btnBackToOriginalPosition.isHidden = true
    }
    
    func reloadView(){
        if !boxBackToOriginalPosition.isHidden{
            btnBackToOriginalPositionClicked(self)
        }
        
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        imgViewAppIcon.isHidden = true
        boxBackToOriginalPosition.isHidden = true
        boxClose.isHidden = false
        boxMinimize.isHidden = false
        boxExtraOptions.isHidden = false
        btnBackToOriginalPosition.isHidden = true
    }
    func loadRequest(){
        let webUrl = "https://dashboard.focusbear.io/webview/todo-player?bust_cache=\(getUuid())"
        let link = URL(string:webUrl)!
        let request = URLRequest(url: link)
        self.webView.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.global().async {
            sleep(1)
            DispatchQueue.main.async {
                self.removeWebViewLoadFailedView(webView: webView)
                if self.isViewVisible{// do not remoev this check otherwise this setAccessTokenToWebView will call 2 times 
                    self.setAccessTokenToWebView()
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
        loadRequest()
    }
    
    @IBAction func btnCloseClicked(_ sender: Any) {
        if taskPlayerVcObj != nil && UserDefaults.standard.object(forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime) == nil && SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            UserDefaults.standard.set(true, forKey: kUserdefaultsToDoPlayerWindowClosedFirstTime)
            let alert = NSAlert()
            alert.setSharingType()
            
            var alertStopLaunchingToDoPlayer = "Do you want to stop the To Do player from launching automatically?"
            var buttonKeepItText = "Keep it"
            var buttonDontShowText = "Don't Show it Again"
            
            if let toDoPlayerVcInfo = configjson.value(forKey: "toDoPlayerVcInfo") as? NSDictionary{
                alertStopLaunchingToDoPlayer = toDoPlayerVcInfo.value(forKey: "alertStopLaunchingToDoPlayer") as? String ?? alertStopLaunchingToDoPlayer
                buttonKeepItText = toDoPlayerVcInfo.value(forKey: "buttonKeepItText") as? String ?? buttonKeepItText
                buttonDontShowText = toDoPlayerVcInfo.value(forKey: "buttonDontShowText") as? String ?? buttonDontShowText
            }
            
            alert.messageText = alertStopLaunchingToDoPlayer
            alert.addButton(withTitle: buttonKeepItText)
            alert.addButton(withTitle: buttonDontShowText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
                if result == .alertSecondButtonReturn{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                self.view.window?.close()
                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
            })
        }else{
            self.view.window?.close()
            allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
        }
    }
    
    @IBAction func btnMinimizeClicked(_ sender: Any) {
        imgViewClose.isHidden = true
        imgViewMaximize.isHidden = true
        imgViewMinimize.isHidden = true
        if stageManagerObject.isStageManagerEnabled{
            btnArrowRightClicked(self)
        }else{
            if isSnapLeft{
                btnArrowLeftClicked(self)
            }else{
                btnArrowRightClicked(self)
            }
        }
    }
    
    @IBAction func btnMaximizeClicked(_ sender: Any) {
        self.view.window?.zoom(nil)
    }
    func setAccessTokenToWebView(){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        var brainDump = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        brainDump = brainDump.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? brainDump
        
        var isFirstTime = false
        if UserDefaults.standard.object(forKey: kUserDefaultsOpenTodoPlayerFirstTime) == nil{
            UserDefaults.standard.set(true, forKey: kUserDefaultsOpenTodoPlayerFirstTime)
            isFirstTime = true
        }
        var finish_time_string = ""
        if let endFocusModeTime = endFocusModeTime{
            finish_time_string = getStringFromDateInUtc(date: endFocusModeTime, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
        }
        
        
        
        let isSuperStrictMode = currentFocusModeStrictness == ._SUPER_STRICT_
        
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"brain_dump\":\"\(brainDump)\",\"isOnboarding\":\(isFirstTime),\"focusmode_endtime\":\"\(finish_time_string)\",\"is_super_strict_mode\":\(isSuperStrictMode)}"
        
        if !focusModeTaskStringIsEmpty(){
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":\(focusModeTaskString),\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"brain_dump\":\"\(brainDump)\",\"isOnboarding\":\(isFirstTime),\"focusmode_endtime\":\"\(finish_time_string)\",\"is_super_strict_mode\":\(isSuperStrictMode)}"
        }
        let settingsFunc = String(format: "let waitForAppLoaded = setInterval(() => { if (window.loadMetaDataForToDoPlayer) { loadMetaDataForToDoPlayer(%@); clearInterval(waitForAppLoaded); } }, 100);", stringJson)
        
        webView.evaluateJavaScript(settingsFunc,completionHandler: { [self] (html: Any?, error: Error?) in
            print(error as Any)
            print("****error")
            print(html as Any)
            if let error = error {
                addLog(text: "loadIntentionForToDoPlayer:- JavaScript evaluation error: \(error)")// v 2.28.441
            }else if let taskToLoadForFirstTime = self.taskToLoadForFirstTime{
                var taskAlreadyAdded = false
                var taskAddedIndex = 0
                for i in 0..<arrAllTasks.count{
                    let task = arrAllTasks[i]
                    let taskName = task.value(forKey: "title") as? String ?? ""
                    if taskName.lowercased() == taskToLoadForFirstTime.lowercased(){
                        taskAlreadyAdded = true
                        taskAddedIndex = i
                        break;
                    }
                }
                
                
                self.taskToLoadForFirstTime = nil
                if !taskAlreadyAdded{
                    let today = Date()
                    let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
                    let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                    allApiObject.addTask(title: taskToLoadForFirstTime, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
                        if result{
                            addLog(text: "\(taskToLoadForFirstTime) task created successfully.")
                            DispatchQueue.main.async { [self] in
                                if let json = json{
                                    if let id = json.value(forKey: "id") as? String{
                                        addAndPlayTaskInCurrentList(taskName: taskToLoadForFirstTime, id: id, duration: 600, shouldCompleteCurrentTask: false)
                                    }
                                }
                            }
                        }
                        
                    })
                }else{
                    let task = arrAllTasks[taskAddedIndex]
                    if let id = task.value(forKey: "id") as? String, let taskTitle = task.value(forKey: "title") as? String{
                        taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: false)
                    }
                }
            }
        })
    }
    
    func getToDosFromPlayer(){
        addLog(text: "func:- getToDosFromPlayer")
        let script = "getToDosFromPlayer();"
        webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
            print(html)
            if let error = error {
                addLog(text: "loadIntentionForToDoPlayer:- JavaScript evaluation error: \(error)")// v 2.28.441
            }
        })
    }
    
    func updateIntentionToPlayer(){
        intention = whatToAchieveInFocusBlock
//        if !self.intention.isEmpty{
//            self.intention = self.intention.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self.intention
//        }
        let script = "loadIntentionForToDoPlayer('\(intention)');"
        
        webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print(html)
            if let error = error {
                addLog(text: "loadIntentionForToDoPlayer:- JavaScript evaluation error: \(error)")// v 2.28.441
            }
        })
    }
    
    func updateBrainDumpToPlayer(){
        let brainDump = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeNotes) as? String ?? ""
        let script = "updateBrainDumpFromDesktopApp('\(brainDump)');"
        
        webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print(html)
            if let error = error {
                addLog(text: "loadIntentionForToDoPlayer:- JavaScript evaluation error: \(error)")// v 2.28.441
            }
        })
    }
    
    func addAndPlayTaskInCurrentList(taskName: String, id:String, duration:Int, shouldCompleteCurrentTask:Bool) {
        addLog(text: "func:- addAndPlayTaskInCurrentList taskName: \(taskName), duration: \(duration), shouldCompleteCurrentTask: \(shouldCompleteCurrentTask), id: \(id)")
        taskCreatedByBlockPopup = taskName
        let taskDic:[String:Any] = [
            "id": id,
            "title": taskName,
            "duration": duration
        ]
        var selectedTaskDic = taskDic
        selectedTaskDic["isPlaying"] = true
        if shouldCompleteCurrentTask{
            selectedTaskDic["markCurrentTaskAsComplete"] = true
        }
        let taskData: [String: Any] = [
            "selectedTask": selectedTaskDic
        ]
        
       // . Create main payload
        let payload: [String: Any] = [
            "todoPlayer": taskData
        ]
        addLog(text: "syncWithDevices payload is:- \(payload)")
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Failed to convert JSON data to string")
                addLog(text: "Failed to convert JSON data to string")// v 2.28.441
                return
            }
            
            // 5. Create JavaScript with proper variable handling
            let jsFunction = """
            (function() {
                if (window.__taskInterval) {
                    clearInterval(window.__taskInterval);
                }
                
                window.__taskInterval = setInterval(() => {
                    if (window.syncWithDevices) {
                        try {
                            const data = \(jsonString);
                            syncWithDevices(data);
                            clearInterval(window.__taskInterval);
                            delete window.__taskInterval;
                        } catch (error) {
                            console.error('JS Error:', error);
                            clearInterval(window.__taskInterval);
                            delete window.__taskInterval;
                        }
                    }
                }, 100);
            })();
            """
            
            // Execute JavaScript
            webView.evaluateJavaScript(jsFunction) { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                    addLog(text: "JavaScript evaluation error: \(error)")// v 2.28.441
                }else{
                    addLog(text: "addAndPlayTaskInCurrentList:- success")// v 2.28.444
                }
            }
        } catch {
            print("JSON serialization error: \(error)")
            addLog(text: "JSON serialization error: \(error)")// v 2.28.441
        }
    }
    
    
    func addTaskInCurrentList(taskName: String, id:String, duration:Int) {
        addLog(text: "func:- addTaskInCurrentList taskName: \(taskName), duration: \(duration), id: \(id)")
        let taskDic:[String:Any] = [
            "id": id,
            "title": taskName,
            "duration": duration
        ]
        let taskData: [String: Any] = [
            "newTasks": [taskDic]
        ]
        let payload: [String: Any] = [
            "todoPlayer": taskData
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Failed to convert JSON data to string")
                addLog(text: "Failed to convert JSON data to string")// v 2.28.441
                return
            }
            
            // 5. Create JavaScript with proper variable handling
            let jsFunction = """
            (function() {
                if (window.__taskInterval) {
                    clearInterval(window.__taskInterval);
                }
                
                window.__taskInterval = setInterval(() => {
                    if (window.syncWithDevices) {
                        try {
                            const data = \(jsonString);
                            syncWithDevices(data);
                            clearInterval(window.__taskInterval);
                            delete window.__taskInterval;
                        } catch (error) {
                            console.error('JS Error:', error);
                            clearInterval(window.__taskInterval);
                            delete window.__taskInterval;
                        }
                    }
                }, 100);
            })();
            """
            
            // Execute JavaScript
            webView.evaluateJavaScript(jsFunction) { result, error in
                if let error = error {
                    print("JavaScript evaluation error: \(error)")
                    addLog(text: "JavaScript evaluation error: \(error)")// v 2.28.441
                }
            }
        } catch {
            print("JSON serialization error: \(error)")
            addLog(text: "JSON serialization error: \(error)")// v 2.28.441
        }
    }
    
    
    func notifyToDoPlayerPauseState(isPaused: Bool) {
        addLog(text: "func:- notifyToDoPlayerPauseState: \(isPaused)")
        do {
            let pausedValue = isPaused ? "true" : "false"
            
            let script = """
                (function() {
                    if (window.setFocusPausedFromDesktopApp) {
                        window.setFocusPausedFromDesktopApp(\(pausedValue));
                    }
                })();
                """
            
            webView.evaluateJavaScript(script) { _, error in
                if let error = error {
                    addLog(text: "NotifyToDoPlayerPauseState JS error - \(error.localizedDescription)")
                }
            }
            
        } catch {
            addLog(text: "NotifyToDoPlayerPauseState ex - \(error.localizedDescription)")
        }
    }
    
    @IBAction func btnArrowLeftClicked(_ sender: Any) {// will be a samll window in left side
        self.isSnappingGoing = true
        lastWindowFrame = self.view.window?.frame ?? lastWindowFrame
        let xPoint = (self.view.window?.screen?.frame.minX ?? 0) - 1
        self.view.window!.setFrame(NSRect(x: xPoint , y: self.view.window!.frame.midY, width: 60, height: 180), display: true)
        boxBackToOriginalPosition.isHidden = false
        imgViewAppIcon.isHidden = false
//        taskPlayerWcObj?.window?.styleMask.remove(.resizable)
        btnBackToOriginalPosition.isHidden = true
        isSnapLeft = true
        boxClose.isHidden = true
        boxMinimize.isHidden = true
        boxExtraOptions.isHidden = true
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
                self.isSnappingGoing = false
            }
        }
    }
    
    @IBAction func btnArrowRightClicked(_ sender: Any) {// will be a samll window in right side
        isSnappingGoing = true
        lastWindowFrame = self.view.window?.frame ?? lastWindowFrame
        let maxXPoint = (self.view.window?.screen?.frame.maxX ?? 0) + 1
        let width:CGFloat = 60
        let xPoint = maxXPoint - width
        self.view.window!.setFrame(NSRect(x: xPoint , y: self.view.window!.frame.midY, width: width, height: 180), display: true)
        boxBackToOriginalPosition.isHidden = false
        imgViewAppIcon.isHidden = false
//        taskPlayerWcObj?.window?.styleMask.remove(.resizable)
        btnBackToOriginalPosition.isHidden = true
        isSnapLeft = false
        boxClose.isHidden = true
        boxMinimize.isHidden = true
        boxExtraOptions.isHidden = true
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                self.updateTrackingAreaIfNeeded()
                self.isSnappingGoing = false
            }
        }
    }
    
    @IBAction func btnBackToOriginalPositionClicked(_ sender: Any) {
        boxClose.isHidden = false
        boxMinimize.isHidden = false
        boxExtraOptions.isHidden = false
        self.view.window!.setFrame(lastWindowFrame, display: true)
        boxBackToOriginalPosition.isHidden = true
//        taskPlayerWcObj?.window?.styleMask.insert(.resizable)
        btnBackToOriginalPosition.isHidden = true
        imgViewAppIcon.isHidden = true
    }
    
    @IBAction func btnEndFocusSessionClicked(_ sender: Any) {
//        if currentFocusModeStrictness == ._SUPER_STRICT_{
//            addLog(text: "can't stop focus mode in super strict focus mode :- return")
//            var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
//            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
//            }
//            showTooltip(sender: btnEndFocusSession, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
//            return;
//        }
        menuViewControllerObj?.stopFocusMode()
    }
    
    @IBAction func btnStartFocusMusicClicked(_ sender: Any) {
        showAllTracksWindow()
    }
}


