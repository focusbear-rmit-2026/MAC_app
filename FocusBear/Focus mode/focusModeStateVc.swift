//
//  focusModeStateVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class focusModeStateVc: NSViewController {
    
    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var lblGettingTasks: NSTextField!
    @IBOutlet weak var boxEditFocusMode: NSBox!
    @IBOutlet weak var btnDecreaseDuration: toolTipButton!
    @IBOutlet weak var btnIncreaseDuration: toolTipButton!
    @IBOutlet weak var lblTitleCurrentTask: NSTextField!
    @IBOutlet weak var lblTitleIntention: NSTextField!
    @IBOutlet weak var comboBoxTask: searchableComboBox!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStopFocusMode: Button!
    @IBOutlet weak var lblTitleFocusModeTime: NSTextField!
    @IBOutlet weak var lblTimerFocusMode: NSTextField!
    @IBOutlet weak var boxFocusModeRemainingTime: NSBox!
    
    var isViewVisible = false
    var arrAllTasks = [NSDictionary]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitleIntention.stringValue = "Focus Goal:"
        lblTitleCurrentTask.stringValue = "Current task:"
        btnIncreaseDuration.customToolTip = "Increase duration by 1 minute"
        btnDecreaseDuration.customToolTip = "Decrease duration by 1 minute"
        
        lblGettingTasks.stringValue = "Fetching tasks..."
        
        lblTitleFocusModeTime.stringValue = "Focus mode ends in:"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            if let focusEndsText = common.value(forKey: "focusEndsText") as? String {
                lblTitleFocusModeTime.stringValue = focusEndsText + ":"
            }
        }
        
        if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
            lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "fetchingTaskText") as? String ?? lblGettingTasks.stringValue
        }
        
        
        if let focusStateVcInfo = configjson.value(forKey: "focusStateVcInfo") as? NSDictionary{
            lblTitleIntention.stringValue = focusStateVcInfo.value(forKey: "titleIntention") as? String ?? lblTitleIntention.stringValue
            lblTitleCurrentTask.stringValue = focusStateVcInfo.value(forKey: "titleTask") as? String ?? lblTitleCurrentTask.stringValue
            btnIncreaseDuration.customToolTip = focusStateVcInfo.value(forKey: "toolTipIncreaseDuration") as? String ?? btnIncreaseDuration.customToolTip
            btnDecreaseDuration.customToolTip = focusStateVcInfo.value(forKey: "toolTipDecreaseDuration") as? String ?? btnDecreaseDuration.customToolTip
        }
        
        
        lblTitle.stringValue = ""
        
        
        comboBoxTask.customDelegate = self
        comboBoxTask.stringValue = ""
        
        comboBoxTask.items.removeAll()
        arrAllTasks.removeAll()
        comboBoxTask.reloadData()
        textView.delegate = self
    }
    
    override func viewWillAppear() {
        reloadData()
        isViewVisible = true
    }
    
    func reloadData(){
        let isFocusModeOn = isFocusModeOn()
        let isFocusModePaused = isFocusModePaused()
        stopFocusModeCountDownTimer()
        
        lblGettingTasks.isHidden = true
        boxEditFocusMode.isHidden = true
        lblGettingTasks.stringValue = "Fetching tasks..."
        if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
            lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "fetchingTaskText") as? String ?? lblGettingTasks.stringValue
        }
        if isFocusModeOn{
            showFocusModeCountDownIfNeeded()
            btnStopFocusMode.title = "Stop Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? btnStopFocusMode.title
            }
            if endFocusModeTime != nil{
                boxEditFocusMode.isHidden = false
                let currentTaskInToDoPlayer = getCurrentTaskInFocusMode() ?? ""
                textView.string = whatToAchieveInFocusBlock
                loader.startAnimation(self)
                comboBoxTask.isEnabled = false
                comboBoxTask.stringValue = ""
                
                comboBoxTask.items.removeAll()
                arrAllTasks.removeAll()
                lblGettingTasks.isHidden = false
                allApiObject.getAllTasks(completionHandler: {json in
                    DispatchQueue.main.async { [self] in
                        comboBoxTask.isEnabled = true
                        lblGettingTasks.isHidden = true
                        if let json = json{
                            let sortedTasks = json.sorted { t1, t2 in
                                let s1 = t1.value(forKey: "created_at") as? String ?? ""
                                let s2 = t2.value(forKey: "created_at") as? String ?? ""
                                
                                let d1 = getDateFromStringInUtc(dateString: s1) ?? Date.distantPast
                                let d2 = getDateFromStringInUtc(dateString: s2) ?? Date.distantPast
                                
                                return d1 > d2
                            }
                            arrAllTasks = sortedTasks
                            for task in arrAllTasks{
                                let title = task.value(forKey: "title") as? String ?? ""
                                comboBoxTask.items.append(title)
                                print(title)
                            }
                            func getDateFromStringInUtc(dateString: String) -> Date? {
                                let df = DateFormatter()
                                df.locale = Locale(identifier: "en_US_POSIX")
                                df.timeZone = TimeZone(secondsFromGMT: 0)
                                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" // matches your examples
                                return df.date(from: dateString)
                            }
                        }
                        comboBoxTask.reloadData()
                        loader.stopAnimation(self)
                        comboBoxTask.stringValue = currentTaskInToDoPlayer
                    }
                })
            }
        }else if isFocusModePaused{
            lblTitle.isHidden = false
            btnStopFocusMode.title = "Resume Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? btnStopFocusMode.title
            }
            
            lblTitle.stringValue = "Focus Session is paused."
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                if let focusSessionPausedText = common.value(forKey: "focusSessionPausedText") as? String {
                    lblTitle.stringValue = focusSessionPausedText
                }
            }
            boxFocusModeRemainingTime.isHidden = true
        }else if isHardCorePomodoroModeOn{
            lblTitle.isHidden = true
            boxFocusModeRemainingTime.isHidden = true
            btnStopFocusMode.title = "Stop Super Focus Session"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                btnStopFocusMode.title = leftMenuVcInfo.value(forKey: "menuStopSuperFocusSession") as? String ?? btnStopFocusMode.title
            }
        }
    }
    
    override func viewWillDisappear() {
        stopFocusModeCountDownTimer()
        isViewVisible = false
    }
    
    var timerFocusModeCoundDown:Timer?
    func setFocusModeCoundDownTimer(){
        lblTitle.isHidden = true
        stopFocusModeCountDownTimer()
        boxFocusModeRemainingTime.isHidden = false
        DispatchQueue.global().sync {
            self.timerFocusModeCoundDown = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performFocusModeCoundDown), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerFocusModeCoundDown!), forMode: RunLoop.Mode.common)
        }
        performFocusModeCoundDown()
    }
    
    
    func showFocusModeCountDownIfNeeded(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning) && endFocusModeTime != nil{
            setFocusModeCoundDownTimer()
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    
    @objc func performFocusModeCoundDown(){
        if (isFocusModeRunning || isAnyAllowedFocusModeActivityRunning){
            if let date = endFocusModeTime{
                let secondsBetween = date.timeIntervalSince(Date())
                if secondsBetween < 0{
                    stopFocusModeCountDownTimer()
                }
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
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
                

                let finalTitle = "\(hour):\(minute):\(second)"
                lblTimerFocusMode.stringValue = finalTitle
            }else{
                stopFocusModeCountDownTimer()
            }
        }else{
            stopFocusModeCountDownTimer()
        }
    }
    
    
    func stopFocusModeCountDownTimer(){
        self.timerFocusModeCoundDown?.invalidate()
        self.timerFocusModeCoundDown = nil
        boxFocusModeRemainingTime.isHidden = true
    }
    
    @IBAction func btnStopFocusModeClicked(_ sender: Any) {
//        if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
//            addLog(text: "focus mode clicked:- focus mode completed Window is visible:- return")
//            return;
//        }

        var isFocusModeOn = false
        
        for index in 0..<arrFocusType.count{
            if arrFocusType[index]["isOn"] as? Bool == true || arrFocusType[index]["isPaused"] as? Bool == true{
                //abort focus mode
                // new work 13/3/22
                isFocusModeOn = true
                if arrFocusType[index]["isOn"] as? Bool == true{
//                    if currentFocusModeStrictness == ._SUPER_STRICT_{
//                        addLog(text: "can't stop focus mode in super strict focus mode :- return")
//                        var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
//                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                            cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
//                        }
//                        showTooltip(sender: btnStopFocusMode, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
//                        return;
//                    }
                    
                    let menu = NSMenu()
                    if timerForFocusMode != nil{
                        let menuItemPause = NSMenuItem(title: "Pause Focus Session", action: #selector(pauseFocusMode), keyEquivalent: "")
                        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                            menuItemPause.title = menuInfo.value(forKey: "menuItemPauseFocusTitle") as? String ?? menuItemPause.title
                        }
                        menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
                        menuItemPause.target = self
                        menu.addItem(menuItemPause)
                    }
                    
                    let menuItemStop = NSMenuItem(title: "Stop Focus Session", action: #selector(stopFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemStop.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? menuItemStop.title
                    }
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    menu.minimumWidth = btnStopFocusMode.frame.width
                    let p = NSPoint(x: btnStopFocusMode.frame.origin.x, y: btnStopFocusMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopFocusMode)
                    
                    break;
                }else if arrFocusType[index]["isPaused"] as? Bool == true{
                    
                    let menu = NSMenu()
                    let menuItemResume = NSMenuItem(title: "Resume Focus Session", action: #selector(resumeFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemResume.title = leftMenuVcInfo.value(forKey: "menuResumeFocusSession") as? String ?? menuItemResume.title
                    }
                    menuItemResume.image = NSImage(named: NSImage.touchBarPlayTemplateName)
                    menuItemResume.target = self
                    menu.addItem(menuItemResume)
                    
                    let menuItemStop = NSMenuItem(title: "Stop Focus Session", action: #selector(stopFocusMode), keyEquivalent: "")
                    if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                        menuItemStop.title = leftMenuVcInfo.value(forKey: "menuStopFocusSession") as? String ?? menuItemStop.title
                    }
                    menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
                    menuItemStop.target = self
                    menu.addItem(menuItemStop)
                    
                    
                    menu.minimumWidth = btnStopFocusMode.frame.width
                    let p = NSPoint(x: btnStopFocusMode.frame.origin.x, y: btnStopFocusMode.frame.origin.y )
                    menu.popUp(positioning: nil, at: p, in: btnStopFocusMode)
                    break;
                }
            }
        }
        
        
        
        if !isFocusModeOn{
            if isHardCorePomodoroModeOn{
                if shouldAskPassword(){
                    if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                        menuViewControllerObj?.showPasswordWindow()
                        addLog(text: "Showing enter password view from hardcodre pomodoro stop from menu")
                    }else{
                        isHardCorePomodoroModeOn = false
                        reloadData()
                        leftMenuVcObj?.boxFocusSession.isSelected = true
                        if SettingsManagerObject.isGeekModeEnabled{
                            appdelegate?.menuShowPomodoroModeView()
                        }else{
                            appdelegate?.menuShowSimplePomodoroModeView()
                        }
                    }
                }else{
                    isHardCorePomodoroModeOn = false
                    reloadData()
                    if SettingsManagerObject.isGeekModeEnabled{
                        appdelegate?.menuShowPomodoroModeView()
                    }else{
                        appdelegate?.menuShowSimplePomodoroModeView()
                    }
                }
            }else{
               
            }
        }else{
            
        }
    }
    
    @objc func pauseFocusMode(){
        menuViewControllerObj?.pauseFocusModeClicked()
    }
    
    @objc func stopFocusMode(){
        menuViewControllerObj?.stopFocusMode()
    }
    
    @objc func resumeFocusMode(){
        menuViewControllerObj?.resumeFocusMode()
    }
    
    @IBAction func btnIncreaseDurationClicked(_ sender: Any) {
        appdelegate?.extendFocusModeFor(minutes: 1)
    }
    
    @IBAction func btnDecreaseDurationClicked(_ sender: Any) {
        appdelegate?.reduceFocusModeFor(minutes: 1)
    }
}

extension focusModeStateVc: SearchableComboBoxDelegate{
    func itemSelectedByUser(comboBox: searchableComboBox) {
        if !comboBox.stringValue.isEmpty{
            comboBoxTask.isEnabled = false
            let currentTask = comboBoxTask.stringValue.lowercased()
            var taskAlreadyAdded = false
            var taskAddedIndex = 0
            if !currentTask.isEmpty{
                for i in 0..<arrAllTasks.count{
                    let task = arrAllTasks[i]
                    let taskName = task.value(forKey: "title") as? String ?? ""
                    if taskName.lowercased() == currentTask{
                        taskAlreadyAdded = true
                        taskAddedIndex = i
                        break;
                    }
                }
                
                if !taskAlreadyAdded{
                    lblGettingTasks.stringValue = "Saving task..."
                    if let popUpAddNewFocusGoalVcInfo = configjson.value(forKey: "popUpAddNewFocusGoalVcInfo") as? NSDictionary{
                        lblGettingTasks.stringValue = popUpAddNewFocusGoalVcInfo.value(forKey: "SavingTaskText") as? String ?? lblGettingTasks.stringValue
                    }
                    lblGettingTasks.isHidden = false
                    loader.startAnimation(self)
                    let today = Date()
                    let taskName = comboBoxTask.stringValue
                    let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today) ?? Date()
                    let dateString = getStringFromDateInUtc(date: nextWeek, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                    addLog(text: "Create new task:- name: \(taskName)")
                    allApiObject.addTask(title: taskName, details: "", eisenhowerQuadrant: 1, dueDate: dateString, objective: "", tags: [], completionHandler: { result,json in
                        if result{
                            addLog(text: "\(taskName) task created successfully.")
                        }
                        DispatchQueue.main.async { [self] in
                            comboBoxTask.isEnabled = true
                            lblGettingTasks.isHidden = true
                            loader.stopAnimation(self)
                            if let json = json{
                                if let id = json.value(forKey: "id") as? String{
                                    taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskName, id: id, duration: 600, shouldCompleteCurrentTask: false)
                                }
                            }
                        }
                    })
                }else{
                    let task = arrAllTasks[taskAddedIndex]
                    if let id = task.value(forKey: "id") as? String, let taskTitle = task.value(forKey: "title") as? String{
                        taskPlayerVcObj?.addAndPlayTaskInCurrentList(taskName: taskTitle, id: id, duration: 600, shouldCompleteCurrentTask: false)
                    }
                    comboBoxTask.isEnabled = true
                }
            }
            return;
        }
    }
}

extension focusModeStateVc: NSTextViewDelegate{
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            if textView == self.textView{
                whatToAchieveInFocusBlock = textView.string
                taskPlayerVcObj?.updateIntentionToPlayer()
            }
        }
    }
}
