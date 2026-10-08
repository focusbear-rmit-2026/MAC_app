//
//  taskPlayerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/05/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import WebKit
import SwiftUI

class taskPlayerVc: NSViewController, WKNavigationDelegate, webViewLoadFailedDelegate {

    // The player UI is now SwiftUI (TaskPlayerView) with the web-rendered player hosted below a native
    // top bar. The WKWebView is created in code (not a storyboard outlet) so all the JS-bridge /
    // navigation-delegate logic below keeps driving the same instance.
    var webView: WKWebView!

    private let headerModel = TaskPlayerHeaderModel()
    private let musicModel = FocusMusicViewModel.shared

    let handler = MessageHandler()
    var totalDuration = 0
    var intention = ""

    var lastWindowFrame:NSRect = NSRect(x: 50, y: 50, width: 500, height: 500)
    var isSnapLeft = true
    var isSnappingGoing = false
    var isMouseEntering = false
    var isViewVisible = false
    var taskToLoadForFirstTime:String?
    var arrAllTasks = [NSDictionary]()

    override func loadView() {
        // Build the WKWebView (with its message handlers) before the SwiftUI view that embeds it.
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(handler, name: "close_focus_player_ui")
        configuration.userContentController.add(handler, name: "send_new_task_added_to_todo_player")
        configuration.userContentController.add(handler, name: "send_brain_dump_content")
        configuration.userContentController.add(handler, name: "send_intention")
        configuration.userContentController.add(AccessTokenRequestHandler.shared, name: AccessTokenRequestHandler.messageName)
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self

        var playFocusMusicTooltip = "Play focus music"
        var stopFocusSessionLabel = "Stop focus session"
        var changeTrackTooltip = "Change focus music"
        if let taskPlayerVcInfo = configjson.value(forKey: "taskPlayerVcInfo") as? NSDictionary {
            playFocusMusicTooltip = taskPlayerVcInfo.value(forKey: "playFocusMusicTooltip") as? String ?? playFocusMusicTooltip
            stopFocusSessionLabel = taskPlayerVcInfo.value(forKey: "stopFocusSessionLabel") as? String ?? stopFocusSessionLabel
            changeTrackTooltip = taskPlayerVcInfo.value(forKey: "changeTrackTooltip") as? String ?? changeTrackTooltip
        }
        var nowPlayingLabel = "Now Playing"
        if let focusMusicInfo = configjson.value(forKey: "focusMusicInfo") as? NSDictionary {
            nowPlayingLabel = focusMusicInfo.value(forKey: "nowPlayingLabelText") as? String ?? nowPlayingLabel
        }

        let rootView = TaskPlayerView(
            headerModel: headerModel,
            musicModel: musicModel,
            webView: webView,
            stopFocusSessionLabel: stopFocusSessionLabel,
            playFocusMusicTooltip: playFocusMusicTooltip,
            changeTrackTooltip: changeTrackTooltip,
            nowPlayingLabel: nowPlayingLabel,
            onEndSession: { menuViewControllerObj?.stopFocusMode() },
            onOpenFocusMusic: { showAllTracksWindow() }
        )
        view = NSHostingView(rootView: rootView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.window?.backgroundColor = NSColor.clear
    }

    override func viewWillAppear() {
        isViewVisible = true
        // Hide "end focus session" while a blocking session is running (it can't be ended from here).
        headerModel.showEndButton = !(isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn)
        musicModel.refresh()
    }


    override func viewWillDisappear() {
        isViewVisible = false
    }

    func setFocusAlignmentScore(){
        if SettingsManagerObject.isAIBlockingEnabled(){
            updateAlignmentScoreToPlayer()
        }
    }

    func reloadData(totalDuration:Int, intention:String){
        self.totalDuration = totalDuration
        self.intention = intention
        if !self.intention.isEmpty{
            self.intention = self.intention.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self.intention
        }
        setAccessTokenToWebView()
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


    func setAccessTokenToWebView(requestId: String? = nil){
        let theme = getWindowTheme()
        
        let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex].webFontName
        // #2142: the brain dump is now API-backed — the task player loads it from the API, so we no
        // longer push the legacy local kUserdefaultsFocusModeNotes into the webview.
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
        
        var stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"isOnboarding\":\(isFirstTime),\"focusmode_endtime\":\"\(finish_time_string)\",\"is_super_strict_mode\":\(isSuperStrictMode)}"
        
        if !focusModeTaskStringIsEmpty(){
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":\(focusModeTaskString),\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"isOnboarding\":\(isFirstTime),\"focusmode_endtime\":\"\(finish_time_string)\",\"is_super_strict_mode\":\(isSuperStrictMode)}"
        }
        // #2216: class focus session — hand off an empty task list + the class_session_id; the frontend
        // loads and completes the class checklist itself via class-session APIs (parity with windows#1393).
        if !classSessionTodoSessionId.isEmpty{
            stringJson = "{\"access_token\": \"\(appdelegate!.credential?.accessToken ?? "")\",\"platform\":\"mac\",\"lang\":\"\(currentLanguageCode)\",\"tasks\":[],\"class_session_id\":\"\(classSessionTodoSessionId)\",\"font\":\"\(selectedFont)\",\"theme\":\"\(theme)\",\"total_duration\":\"\(totalDuration)\",\"intention\":\"\(intention)\",\"isOnboarding\":\(isFirstTime),\"focusmode_endtime\":\"\(finish_time_string)\",\"is_super_strict_mode\":\(isSuperStrictMode)}"
        }
        if let requestId = requestId {
            stringJson = String(stringJson.dropLast()) + ",\"requestId\":\"\(requestId)\"}"
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
        let script = "loadIntentionForToDoPlayer('\(intention)');"
        
        webView?.evaluateJavaScript(script,completionHandler: { (html: Any?, error: Error?) in
            print(error)
            print(html)
            if let error = error {
                addLog(text: "loadIntentionForToDoPlayer:- JavaScript evaluation error: \(error)")// v 2.28.441
            }
        })
        
        // Notify Focus Button of the updated goal
        focusButtonServiceObject.updateFocusGoal(goal: focusButtonServiceObject.currentFocusGoal())
    }
    
    func updateAlignmentScoreToPlayer(){
        let taskData: [String: Any] = [
            "focusAlignmentScore": currentFocusAlignmentScore
        ]
        
       // . Create main payload
        let payload: [String: Any] = [
            "todoPlayer": taskData
        ]
        
       // let script = "syncWithDevices('\(payload)');"
        
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
    
    func addAndPlayTaskInCurrentList(taskName: String, id:String, duration:Int, shouldCompleteCurrentTask:Bool) {
        addLog(text: "func:- addAndPlayTaskInCurrentList taskName: \(LogPrivacy.text(taskName)), duration: \(duration), shouldCompleteCurrentTask: \(shouldCompleteCurrentTask), id: \(id)")
        taskCreatedByBlockPopup = taskName
        // Reflect the changed task on the Focus Button device. getCurrentTaskInFocusMode() returns
        // taskCreatedByBlockPopup first, so currentFocusGoal() already reflects the new task here. This
        // covers every task-change entry point (e.g. changing the task from focusModeStateVc), not just
        // the intention-update flow that previously was the only caller of updateFocusGoal.
        focusButtonServiceObject.updateFocusGoal(goal: focusButtonServiceObject.currentFocusGoal())
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
        addLog(text: "syncWithDevices payload is:- \(LogPrivacy.structure(payload))")
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
    
    
    /// Prepopulate the player with the day-plan tasks assigned to the current habit. Sent as one
    /// `newTasks` batch; the JS waits for the player to be ready. Each task carries its source to-do id
    /// where known, so a task already in the player isn't duplicated. No-op if there are none.
    func prepopulateTasks(_ tasks: [[String: Any]]) {
        guard !tasks.isEmpty else { return }
        let payload: [String: Any] = ["todoPlayer": ["newTasks": tasks]]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            addLog(text: "prepopulateTasks: JSON serialization failed")
            return
        }
        // Separate interval key from addTaskInCurrentList so the two don't clobber each other.
        let jsFunction = """
        (function() {
            if (window.__prefillInterval) { clearInterval(window.__prefillInterval); }
            window.__prefillInterval = setInterval(() => {
                if (window.syncWithDevices) {
                    try { syncWithDevices(\(jsonString)); }
                    catch (error) { console.error('JS Error:', error); }
                    clearInterval(window.__prefillInterval);
                    delete window.__prefillInterval;
                }
            }, 100);
        })();
        """
        webView.evaluateJavaScript(jsFunction) { _, error in
            if let error = error { addLog(text: "prepopulateTasks JS error: \(error)") }
        }
    }

    func addTaskInCurrentList(taskName: String, id:String, duration:Int) {
        addLog(text: "func:- addTaskInCurrentList taskName: \(LogPrivacy.text(taskName)), duration: \(duration), id: \(id)")
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
}


