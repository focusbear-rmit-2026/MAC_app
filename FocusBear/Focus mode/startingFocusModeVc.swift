//
//  startingFocusModeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class startingFocusModeVc: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var lblTimerUnfocused: NSTextField!
    @IBOutlet weak var lblExplanation: NSTextField!
    @IBOutlet weak var lblLockedFocusDescription: NSTextField!
    @IBOutlet weak var lblMinute: NSTextField!
    @IBOutlet weak var lblHour: NSTextField!
    @IBOutlet weak var textFieldMinutesValue: NSTextField!
    @IBOutlet weak var textFieldHourValue: NSTextField!
    @IBOutlet weak var lblHowMuchTime: NSTextField!
    @IBOutlet weak var btnStartFocus: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblQuestion: NSTextField!
    @IBOutlet var textViewQuestion: NSTextView!
    
    var focusIndex = 0
    var focusType = ""
    var titleText = "Starting Focus type - <FOCUSTYPE>"
    var timerText = "Time spend unfocused: <TIME>"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        focusModeStartWindowLodded = true
        btnStartFocus.title = "Start Focus"
        lblHowMuchTime.stringValue = "How much time to focus for:"
        lblHour.stringValue = "hours"
        lblMinute.stringValue = "minutes"
        textFieldMinutesValue.delegate = self
        textFieldHourValue.delegate = self
        lblQuestion.stringValue = "What do you plan to achieve during this focus block?"
        
        lblLockedFocusDescription.stringValue = "You'll only be able to use {URL} in {APP}"
        
        lblExplanation.stringValue = "Setting an intention for the focus block helps prime your brain to accomplish that task. To edit the intention after starting the focus mode, click Brain Dump in the menu bar."
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                if let title = startingFocusModeInfo.value(forKey: "title") as? String{
                    titleText = title
                }
                if let questionText = startingFocusModeInfo.value(forKey: "questionText") as? String{
                    lblQuestion.stringValue = questionText
                }
                if let buttonStartFocusText = startingFocusModeInfo.value(forKey: "buttonStartFocusText") as? String{
                    btnStartFocus.title = buttonStartFocusText
                }
                if let howMuchTimeText = startingFocusModeInfo.value(forKey: "howMuchTimeText") as? String{
                    lblHowMuchTime.stringValue = howMuchTimeText
                }
                if let hoursText = startingFocusModeInfo.value(forKey: "hoursText") as? String{
                    lblHour.stringValue = hoursText
                }
                if let minutesText = startingFocusModeInfo.value(forKey: "minutesText") as? String{
                    lblMinute.stringValue = minutesText
                }
                lblExplanation.stringValue = startingFocusModeInfo.value(forKey: "explanationText") as? String ?? lblExplanation.stringValue
                
            }
        }
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            timerText = pomodoroInfo.value(forKey: "timerText") as? String ?? timerText
        }
    }

    override func viewWillAppear() {
        textViewQuestion.string = ""
        startTimer()
    }
    override func viewWillDisappear() {
        timer?.invalidate()
        timer = nil
    }
    var timer:Timer?
    var currentTimer = 0
    func startTimer() {
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }

        currentTimer = unfocusedTime
        let (h,m,s) = secondsToHoursMinutesSeconds(seconds: currentTimer)
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
//        if h == 0{
//            self.lblTimer.stringValue = "\(minute):\(second)"Time spend unfocused 00:00:00
//        }else{
        self.lblTimerUnfocused.stringValue = timerText.replacingOccurrences(of: "<TIME>", with: "\(hour):\(minute):\(second)")//"Time spend unfocused: \(hour):\(minute):\(second)"//
//        }
        
        DispatchQueue.main.async {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    func setProgres(){
        let remainingSeconds = currentTimer
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
            self.lblTimerUnfocused.stringValue = self.timerText.replacingOccurrences(of: "<TIME>", with: "\(hour):\(minute):\(second)")//"Time spend unfocused: \(hour):\(minute):\(second)"//
        }
    }
    @objc func performTimerCount() {
        if !appdelegate!.isSystemSleep && !appdelegate!.isScreenSaverStart && currentState != ._ACTIVITY_{
            currentTimer += 1
        }
        setProgres()
    }
    @IBAction func btnStartFocusClicked(_ sender: Any) {
        addLog(text: "startingFocusModeVc - btnStartFocusClicked")//

        if getEndFocusModeWindowControllerObj().window!.isVisible{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "")
            getEndFocusModeWindowControllerObj().window?.close()
        }
        let calendar = Calendar.current
        let totoalMinutes = (textFieldHourValue.integerValue * 60) + textFieldMinutesValue.integerValue
        endFocusModeTime = calendar.date(byAdding: .minute, value: totoalMinutes, to: Date())
        startFocusModeTime = Date()
        arrFocusType[focusIndex]["isOn"] = true
        
        workBeforeFocusBegin(index: focusIndex)

        
        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[focusIndex]["color"] as? String ?? "")
        appdelegate!.setStatusBarButtonTitleForFocusMode(title: textViewQuestion.string)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        isFocusTimeType = ._HOUR_
        appdelegate?.setFocusModeTimer(hour: nil, minute: totoalMinutes)
        isFocusModeStartedFromPomodoroMode = false
        if isPomodoroWindowLodded{
            if pomodoroWindowControllerObj!.window!.isVisible{
                pomodoroWindowControllerObj?.window?.close()
            }
        }
        whatToAchieveInFocusBlock = textViewQuestion.string
        appdelegate!.focusModeStartted()
        if arrFocusType[focusIndex]["isLockedFocus"] as? Bool == true{
            allApiObject.capturePosthog(event: "start-lock-in-current-focus", metadata: [:])
        }
        
        allApiObject.capturePosthog(event: "start-focus-mode-manually", metadata: [:])
        appdelegate!.setIntensionInBrainDumpWindow()
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        self.view.window?.close()
    }
        
    
    func ResetData(focusModeIndex:Int, focusType:String){
        if isPomodoroWindowLodded{
            if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                pomodoroWindowControllerObj?.window?.close()
            }
        }
        self.focusType = focusType
        self.focusIndex = focusModeIndex
        textFieldHourValue.stringValue = "00"
        textFieldMinutesValue.stringValue = "20"
        btnStartFocus.isEnabled = true
        lblTitle.stringValue = titleText.replacingOccurrences(of: "<FOCUSTYPE>", with: focusType)//"Starting Focus type - \(focusType)"
        
        
        if arrFocusType[focusModeIndex]["isDefault"] as? Bool == true{
            showDiscourageFocusView()
        }
        
        if arrFocusType[focusIndex]["isLockedFocus"] as? Bool == true{
            lblLockedFocusDescription.isHidden = false
            
            
            var appsArray = [String]()
            var appsUrlArray = [String]()
            if lastFrontMostApplication != nil{
                appsArray.append(lastFrontMostApplication!.bundleURL?.path ?? "")
                var appName = ""
                var appUrl = ""
                if let name = lastFrontMostApplication!.localizedName{
                    appName = name
                    let nameLowercased = name.lowercased()
                    
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        var defaultPageOfBrowser = ""
                        if browser == ._SAFARI_{
                            defaultPageOfBrowser = "favorites:"
                        }else{
                            defaultPageOfBrowser = "chrome:"
                        }
                        
                        if let url = getActiveTabUrlOf(browser: browser){
                            if !url.contains(defaultPageOfBrowser){
                                let domain = getDomainFromUrl(url: url)
                                appsUrlArray = [domain]
                                appUrl = domain
                            }
                        }
                    }
                }
                
                if appsUrlArray.count == 0{
                    var onlyAllowSelectedAppText = "You'll only be able to use <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppText") as? String ?? onlyAllowSelectedAppText
                        }
                    }
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppText.replacingOccurrences(of: "<APP>", with: appName)//(in: "<APP>", with: appName)
                }else{
                    var onlyAllowSelectedAppAndUrlText = "You'll only be able to use \"<URL>\" in <APP>"
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                            onlyAllowSelectedAppAndUrlText = startingFocusModeInfo.value(forKey: "onlyAllowSelectedAppAndUrlText") as? String ?? onlyAllowSelectedAppAndUrlText
                        }
                    }
                    onlyAllowSelectedAppAndUrlText = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<APP>", with: appName)
                    lblLockedFocusDescription.stringValue = onlyAllowSelectedAppAndUrlText.replacingOccurrences(of: "<URL>", with: appUrl)
                }
            }else{
                lblLockedFocusDescription.isHidden = true
            }
             
            var dic = arrFocusType[focusIndex]
            dic["allowed_urls"] = appsUrlArray
            dic["allowed_apps"] = appsArray
            dic["isAllowedAllApps"] = false
//            dic["isAllowedAllUrls"] = false#453
            dic["isAllowedListApproach"] = true
            arrFocusType[focusIndex] = dic

        }else{
            lblLockedFocusDescription.isHidden = true
        }
    }
    
    @objc func showDiscourageFocusView(){
        addLog(text: "startingFocusModeVc - showDiscourageFocusView")//
        self.presentAsSheet(getDiscourageDefaultFocusVcObject())
        getDiscourageDefaultFocusVcObject().resetData()
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldHourValue{
                var count = textfield.integerValue
                if count > 12{
                    count = 12
                }
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
                
                if textfield.stringValue.count > 2{
                    textfield.stringValue = "12"
                }
                
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }else if textfield == textFieldMinutesValue{
                let count = textfield.integerValue
//                if count > 59{
//                    count = 59
//                }
                if count < 10{
                    textfield.stringValue = "0\(count)"
                }else{
                    textfield.stringValue = "\(count)"
                }
//                if textfield.stringValue.count > 2{
//                    textfield.stringValue = "59"
//                }
                if textFieldMinutesValue.stringValue == "00" && textFieldHourValue.stringValue == "00"{
                    btnStartFocus.isEnabled = false
                }else{
                    btnStartFocus.isEnabled = true
                }
            }
        }
    }
}
