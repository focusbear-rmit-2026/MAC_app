//
//  selectJsonVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/01/22.
//  .
//

import Cocoa
import WebKit
class selectJsonVc: NSViewController, NSTextViewDelegate {

//    @IBOutlet weak var boxHeightConstraint: NSLayoutConstraint!
//    @IBOutlet weak var boxWidthConstraint: NSLayoutConstraint!
    // No longer navigated or shown — Edit Habits now shares one WKWebView with Todo List / Stats
    // via SharedDashboardWebViewManager. Kept only because removing it means editing the
    // storyboard scene.
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var customBox: NSBox!


    var timer:Timer?
    var currentTimer = 0
    var totalDuration = 0
    
    
    let viewWidthDefault = 1000
    let viewHeightDefault = 500
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLog(text: "Edit settings (selectJsonVc) viewdidload start")
        selectJsonVcObj = self

        if let settings = configjson.value(forKey: "settings") as? NSDictionary{

            if let visitText = settings.value(forKey: "visitText") as? String, let settingUrl = settings.value(forKey: "settingUrl") as? String{
                if visitText.localizedCaseInsensitiveContains("<SETTINGURL>"){
                    let paragraph = NSMutableParagraphStyle()
                    paragraph.alignment = .center
                    let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
                    let arr = visitText.components(separatedBy: "<SETTINGURL>")
                    let mainstr =  NSMutableAttributedString()
                    for i in 0..<arr.count{
                        let string = arr[i]
                        if !string.isEmpty{
                            let str = NSMutableAttributedString(string: string, attributes: attrs)
                            if i != arr.count - 1{
                                let paragraph = NSMutableParagraphStyle()
                                paragraph.alignment = .center
                                let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
                                let attrString: NSAttributedString = NSAttributedString(string: settingUrl, attributes: attrs)
                                str.append(attrString)
                            }
                            mainstr.append(str)
                        }
                    }
                }
            }

        }
        addLog(text: "Edit settings (selectJsonVc) viewdidload end")
    }

    override func viewWillAppear() {
        SharedDashboardWebViewManager.shared.present(.editHabits, in: self.view)
    }

    var alertSettingChanged:NSAlert?

    func alertSettingsNotValid(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var schemaError = "Session Expired! Please login again."
        var buttonOkText = "OK"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            schemaError = settings.value(forKey: "tokenErrorText") as? String ?? schemaError
            buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
        }
        alert.messageText = schemaError
        alert.addButton(withTitle: buttonOkText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                appdelegate?.logout(isAutomatic: true)
            }
        })
    }
    
    func alertSettingsSaved(){
        self.alertSettingChanged = NSAlert()
        self.alertSettingChanged!.setSharingType()
        self.alertSettingChanged!.alertStyle = .informational
        allApiObject.capturePosthog(event: "save-edited-habits", metadata: [:])
        var settingIsValidText = "Saved! Restarting the app so your new habit timing works."
        var buttonOkText = "Restart now"
        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
            settingIsValidText = settings.value(forKey: "settingIsValidText") as? String ?? settingIsValidText
            buttonOkText = settings.value(forKey: "buttonRestartNow") as? String ?? buttonOkText
        }
        
        self.alertSettingChanged!.messageText = settingIsValidText
        self.alertSettingChanged!.addButton(withTitle: buttonOkText)
        
        self.startTimer(durationSeconds: 15)
        
        
        self.alertSettingChanged!.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                // self.setData()
                appdelegate?.quitAndRestartApp()
            }
            
            
        })
    }
    
    func jsonReceivedFromWebView(jsonResult: NSDictionary){
        isGettingSchema = true
        addLog(text: "func jsonReceivedFromWebView")
        addLog(text: "settings json is:- \(LogPrivacy.structure(jsonResult))")

        allApiObject.isSettingsValid(settings: jsonResult, isOnboarding:false, completionHandler: {dic,statusCode  in
            DispatchQueue.main.async {
                isGettingSchema = false
                
                
                if dic == nil{
                    self.alertSettingsNotValid()
                }else{
                    
                    if statusCode == 200{
                        self.alertSettingsSaved()
                        do {
                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                            print(jsonResultData)
                            
                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                print()
                                SensitiveDefaults.set(backToString, forKey: kUserdefaultsSelectedJson)
                                
                            }
                            
                            
                        } catch let myJSONError {
                            print(myJSONError)
                        }
                    }else{
                        
                        
                        let alert = NSAlert()
                        alert.setSharingType()
                        alert.alertStyle = .informational
                        
                        var settingIsNotValidText = "Sorry it seems like your settings aren’t valid. Please generate settings at focusbear.io/settings"
                        var buttonOkText = "OK"
                        if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                            settingIsNotValidText = settings.value(forKey: "settingIsNotValidText") as? String ?? settingIsNotValidText
                            buttonOkText = settings.value(forKey: "buttonOkText") as? String ?? buttonOkText
                        }
                        
                        alert.messageText = settingIsNotValidText
                        if let message = dic?.value(forKey: "message") as? NSArray{
                            alert.informativeText = "\(message)"
                        }
                        
                        alert.addButton(withTitle: buttonOkText)
                        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                
                            }
                        })
                    }
                    
                    
                }
            }
        })
        
    }
    
    func startTimer(durationSeconds:Int) {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

        currentTimer = 0
        totalDuration = durationSeconds//durationInMinutes*60
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
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
        if h == 0{
            self.alertSettingChanged?.informativeText = "\(minute):\(second)"
        }else{
            self.alertSettingChanged?.informativeText = "\(hour):\(minute):\(second)"
        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func setProgres(){
        let remainingSeconds = self.totalDuration-currentTimer
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: remainingSeconds)
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
        
        DispatchQueue.main.async {

            if h == 0{
                self.alertSettingChanged?.informativeText = "\(minute):\(second)"
            }else{
                self.alertSettingChanged?.informativeText = "\(hour):\(minute):\(second)"
            }
            
            
            if self.totalDuration <= self.currentTimer {
                self.timer?.invalidate()
                self.alertSettingChanged?.window.close()
                appdelegate?.quitAndRestartApp()
            }
        }
    }

    @objc func performTimerCount() {
        currentTimer += 1 
        setProgres()
    }
    
}


class MessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("call back hua:- \(message.name)")
        if message.name == "close_survey_ui"{
            print(message.body)
            if surveyWcObj != nil{
                if surveyWcObj?.window?.isVisible ?? false{
                    surveyWcObj?.window?.close()
                }
            }
        }else if message.name == "close_todo_task_ui"{
            print(message.body)
            if message.body as? String == "\"close-to-do-task-ui\""{
                focusModeTaskString = ""
            }else{
                focusModeTaskString = message.body as? String ?? ""
            }
            taskCreatedByBlockPopup = ""
            addTaskVcObj!.dismiss(addTaskVcObj)
            return;
        }else if message.name == "close_todo_focus_end_ui"{
            print(message.body)
            focusModeTaskString = ""
            taskCreatedByBlockPopup = ""
            addTaskVcObj!.dismiss(addTaskVcObj)
        }else if message.name == "send_new_task_added_to_todo_player"{
            print(message.body)
            let taskString = message.body as? String ?? ""
            updateFocusModeTask(taskString: taskString)
            addLog(text: "focusMode Task String is:- \(taskString)")
            var currentFocusModeIndex = 0
            if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn){
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_{
                    for i in 0..<arrFocusType.count{
                        let dic = arrFocusType[i]
                        if dic["id"] as? String == currentRunningFocusType["id"] as? String{
                            currentFocusModeIndex = i
                            break;
                        }
                    }
                }else{
                    for i in 0..<arrFocusType.count{
                        let dic = arrFocusType[i]
                        if dic["isOn"] as? Bool == true{
                            currentFocusModeIndex = i
                            break;
                        }
                    }
                }
                arrFocusType[currentFocusModeIndex]["lastTaskUsed"] = focusModeTaskString
            }
        }else if message.name == "send_intention"{
            print(message.body)
            // In super strict mode, prevent changing the focus intention
            if currentFocusModeStrictness == ._SUPER_STRICT_ {
                addLog(text: "Cannot change focus intention in super strict mode")
                return;
            }
            let intention = message.body as? String ?? ""
            updateFocusModeIntention(intention: intention)
        }else if message.name == "send_brain_dump_content"{
            print(message.body) 
            let brainDump = message.body as? String ?? ""
            SensitiveDefaults.set(brainDump, forKey: kUserdefaultsFocusModeNotes)
        }else if message.name == "close_focus_player_ui"{
            print(message.body)
        }else if message.name == "open_marketplace"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "open_android_app"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "open_ios_app"{
            print(message.body)
            if let url = URL(string: message.body as? String ?? ""){
                NSWorkspace.shared.open(url)
            }
        }else if message.name == "get_selected_tasks"{
            if addTaskVcObj != nil{
                if addTaskVcObj?.handler == self{
                    focusModeTaskString = message.body as? String ?? ""
                    taskCreatedByBlockPopup = ""
                    addTaskVcObj!.dismiss(addTaskVcObj)
                    return;
                }
            }
        }else if message.name == "submit_completed_tasks"{
            if addTaskVcObj != nil{
                if addTaskVcObj?.handler == self{
                    focusModeTaskString = message.body as? String ?? ""
                    taskCreatedByBlockPopup = ""
                    var arrTaskNotCompleted = [[String : Any]]()
                    
                    if !focusModeTaskStringIsEmpty(){
                        if let data = focusModeTaskString.data(using: String.Encoding.utf8) {
                            do {
                                let jsonResult:[[String: Any]] = try (JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] ?? [])
                                print(jsonResult)
                                var taskString = ""
                                for i in 0..<jsonResult.count{
                                    let task = jsonResult[i]
                                    if let status = task["status"] as? String, let title = task["title"] as? String{
                                        if status != "COMPLETED"{
                                            arrTaskNotCompleted.append(task)
                                        }
                                        let status = getStatusTextForTask(status: status)
                                        if taskString.isEmpty{
                                            taskString += "\(title) (\(status))"
                                        }else{
                                            taskString += "\n" + "\(title) (\(status))"
                                        }
                                    }
                                }
                                var currentFocusModeIndex: Int = 0


                                if isFocusCompletedViewVisibled(){
                                    focusCompletedVcObj?.textFieldAchieve.stringValue = taskString
                                    focusCompletedVcObj?.textFieldAchieve.setFocus()
                                    
                                    currentFocusModeIndex = focusCompletedVcObj?.currentFocusModeIndex ?? 0
                                }
                                
                                if currentAction == ._END_ && (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._CUSTOM_ROUTINE_){
                                    if (getHabitsVcObject().habitsView.subviews.contains(activityCompletionVcObj!.view)){
                                        if focusCompletedForActivityVcObj != nil{
                                            if (getHabitsVcObject().view.subviews.contains((focusCompletedForActivityVcObj!.view))){
                                                focusCompletedForActivityVcObj?.textFieldAchieve.stringValue = taskString
                                                focusCompletedForActivityVcObj?.textFieldAchieve.setFocus()
                                                currentFocusModeIndex = focusCompletedForActivityVcObj?.currentFocusModeIndex ?? 0
                                            }
                                        }
                                    }
                                }
                                
                                if arrTaskNotCompleted.count == 0{
                                    arrFocusType[currentFocusModeIndex]["lastTaskUsed"] = ""
                                    updateAllFocusModes()
                                }else if arrTaskNotCompleted.count != jsonResult.count{
                                    do {
                                        let jsonResultData =  try JSONSerialization.data(withJSONObject: arrTaskNotCompleted, options: JSONSerialization.WritingOptions.prettyPrinted)
                                        
                                        print(jsonResultData)
                                        
                                        if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                            print(backToString)
                                            
                                            arrFocusType[currentFocusModeIndex]["lastTaskUsed"] = backToString
                                            updateAllFocusModes()
                                        }
                                        
                                        
                                    } catch let myJSONError {
                                        print(myJSONError)
                                    }
                                }else{
                                    arrFocusType[currentFocusModeIndex]["lastTaskUsed"] = focusModeTaskString
                                    updateAllFocusModes()
                                }
                                
                            }catch{
                                print(error)
                            }
                        }
                    }
                    
                    allApiObject.capturePosthog(event: "mark-tasks-on-focus-session-end-screen-saved-and-closed", metadata: [:])
                    
                    let alert = NSAlert()
                    alert.setSharingType()
                    alert.alertStyle = .informational
                    alert.messageText = "Your tasks have been saved."
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let focusCompletedInfo = focusInfo.value(forKey: "focusCompletedInfo") as? NSDictionary{
                            alert.messageText = focusCompletedInfo.value(forKey: "tasksSavedText") as? String ?? alert.messageText
                        }
                    }
                    
                    alert.addButton(withTitle: buttonOkText)
                    if let window = addTaskVcObj?.view.window{
                        alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                                
                            }
                        })
                    }else{// will not execute
                        addTaskVcObj?.dismiss(addTaskVcObj)
                    }
                    return;
                }
            }
        }else if message.name == "setting_saved"{
            if message.body as? String == "user-settings-updated"{
                if currentState == ._ONBOARDING_{
                    installHabitPacksVcObj?.showNextView()
                }else if message.webView == SharedDashboardWebViewManager.shared.webView{
                    selectJsonVcObj?.alertSettingsSaved()
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                        if (mainWindowControllerObj?.window?.isVisible ?? false) && editHabitRoutineVcObj != nil{
                            editHabitRoutineVcObj?.alertSettingsSaved()
                        }
                    }
                }
            }else if message.body as? String == "user-settings-update-failed"{
                if message.webView == SharedDashboardWebViewManager.shared.webView{
                    selectJsonVcObj?.alertSettingsNotValid()
                }else{
                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                        if (mainWindowControllerObj?.window?.isVisible ?? false) && editHabitRoutineVcObj != nil{
                            editHabitRoutineVcObj?.alertSettingsNotValid()//
                        }
                    }
                }
            }else {
                if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
                    
                    do {
                        let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                        print(jsonResult)
                        if message.webView == SharedDashboardWebViewManager.shared.webView{
                            selectJsonVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
                        }else{
                            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                                if (mainWindowControllerObj?.window?.isVisible ?? false) && editHabitRoutineVcObj != nil{
                                    editHabitRoutineVcObj?.jsonReceivedFromWebView(jsonResult: jsonResult)
                                }
                            }
                        }
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                }
            }
            
        }else if message.name == "detect_user_settings_change"{
            print("detect_user_settings_change")
            if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
                
                do {
                    let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    print(jsonResult)
                    areSettingsEdited = jsonResult.value(forKey: "areSettingsEdited") as? Bool ?? false
                }
                catch{
                    
                }
            }
        }else if message.name == "download_focus_summaries"{
            print("download_focus_summaries")
           // if let url = message.body as? String{
                //Please visit Focus Bear dashboard in your web browser to download the report.
//                Click here to visit dashboard now
            
            let alert = NSAlert()
            alert.setSharingType()
            alert.alertStyle = .informational
            var downloadReportText = "Please visit Focus Bear dashboard in your web browser to download the report."
            var buttonClickText = "Click here to visit dashboard now"
            if let settings = configjson.value(forKey: "settings") as? NSDictionary{
                downloadReportText = settings.value(forKey: "downloadReportText") as? String ?? downloadReportText
                buttonClickText = settings.value(forKey: "buttonVisitDashboardText") as? String ?? buttonClickText
            }
            alert.messageText = downloadReportText
            alert.addButton(withTitle: buttonClickText)
            alert.addButton(withTitle: buttonCancelText)
            alert.beginSheetModal(for: mainWindowControllerObj!.window!, completionHandler: { (modalResponse) in//preferencesWindowControllerObj
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    
                    NSWorkspace.shared.open(URL(string: "https://dashboard.focusbear.io/stats")!)
                }
            })
           
        }else if message.name == "save_suggested_activities"{
            print(message.body)
        }else if message.name == "edit_suggested_activities"{
            print(message.body)
        }else if message.name == "send_selected_habit_pack"{
            print(message.body) 
        }else if message.name == "send_installed_habit_pack_id"{
            print(message.body)// install habit pack
            installHabitPacksVcObj?.showNextView()
        }else if message.name == "send_suggested_activities"{
            print(message.body)// use generated habits
            installHabitPacksVcObj?.showNextView()
        }else if message.name == "send_user_subscription_status"{
            print(message.body)// use generated habits
            manageSubscriptionVcObj?.btnCloseClicked(self)
        }else if message.name == "routine_suggestions_step"{
            print(message.body)// use generated habits
            
            if let data = (message.body as? String ?? "").data(using: String.Encoding.utf8) {
                
                do {
                    let jsonResult:NSDictionary = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    print(jsonResult)

                    let val = jsonResult.value(forKey: "step") as? Int ?? 0
                    print(val)
                    if val != 0 && installHabitPacksVcObj != nil{
                        showOnboardingProgress(view: installHabitPacksVcObj!.view, progress: installHabitPacksVcObj!.currentProgressLevel + val)
                    }
                }
                catch{
                    
                }
            }
        }
    }
}



