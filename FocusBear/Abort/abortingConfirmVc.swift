//
//  abortingConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/01/22.
//  
//

import Cocoa

class abortingConfirmVc: NSViewController, NSTextViewDelegate {
    
    
    @IBOutlet weak var lblBtnStartSmall_boxHabit: ignoreMouseTextField!
    @IBOutlet weak var lblBtnDontWantRoutine_boxHabit: ignoreMouseTextField!
    
    @IBOutlet weak var btnDontWantRoutine_boxHabit: NSButton!
    @IBOutlet weak var btnStartSmall_boxHabit: NSButton!
    
    @IBOutlet weak var lblTitleEmailFourthBox: NSTextField!
    
    @IBOutlet weak var lblTitleEmailSecondBox: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnDeactivate_boxSomethingElse: NSButton!
    @IBOutlet var textViewSomethingElse: NSTextView!
    @IBOutlet weak var textFieldEmail_SomethingELse: NSTextField!
    @IBOutlet weak var btnDeactivateAppBroken: NSButton!
    @IBOutlet weak var textFieldEmailAppBroken: NSTextField!
    @IBOutlet var textViewAppBroken: NSTextView!
    @IBOutlet weak var lblTimerEmergency: NSTextField!
    @IBOutlet weak var lblDescriptionFourthBox: NSTextField!
    @IBOutlet weak var lblDescriptionThirdBox: NSTextField!
    @IBOutlet weak var lblDescriptionSecondBox: NSTextField!
    @IBOutlet weak var lblDescriptionFirstBox: NSTextField!
    @IBOutlet weak var boxSomethingElse: NSBox!
    @IBOutlet weak var boxHabitsHard: NSBox!
    @IBOutlet weak var boxAppBroken: NSBox!
    @IBOutlet weak var boxEmergency: NSBox!
    @IBOutlet weak var popUpBtnReasons: NSPopUpButton!
    @IBOutlet weak var imgViewGif: NSImageView!

    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    var descriptionNewOptions = "Restoring access immediately and cancelling habits for next 4 hours.. Your normal routine will resume after that."
    var allReasons = [String]()
    
    let selectReasonIndex = 0
    let emergencyReasonIndex = 1
    let brokenAppReasonIndex = 2
    let habitsTooHardReasonIndex = 3
    let haveMeetingReasonIndex = 4
    let someOneElseReasonIndex = 5
    let appAnnoyingReasonIndex = 6
    let wantToRelaxReasonIndex = 7
    let somethingElseReasonIndex = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lblTitle.stringValue = "Aborting.."
        lblSubTitle.stringValue = "Can you share why you're aborting?"
        
        lblDescriptionFirstBox.stringValue = "Uh oh! Hope everything is ok. Restoring access immediately and cancelling habits for next 4 hours.. Your normal routine will resume after that."
        
        
        lblDescriptionSecondBox.stringValue = "Oh no! We're really sorry. We'll deactivate all popups. Can you please let us know what happened?﹡"
        lblTitleEmailSecondBox.stringValue = "Your Email (if you want us to reply):"
        btnDeactivateAppBroken.title = "Deactivate habit popups"
        
        
        
        lblDescriptionThirdBox.stringValue = "Ah understandable. Would you like to reset your habits to be 30 seconds each and max 5 minutes? A short morning routine is better than nothing. You can build from there."
        
        lblBtnStartSmall_boxHabit.stringValue = "Yeah - I'll start small"
        btnStartSmall_boxHabit.title = ""
        lblBtnStartSmall_boxHabit.textColor = buttonTitleColor
        
        lblBtnDontWantRoutine_boxHabit.stringValue = "NO I don't want a \nmorning routine at all!"
        btnDontWantRoutine_boxHabit.title = ""
        lblBtnDontWantRoutine_boxHabit.textColor = buttonTitleColor
        
        lblDescriptionFourthBox.stringValue = "Can you tell us why you want to stop getting habit + break notifications?﹡"
        lblTitleEmailFourthBox.stringValue = "Your Email (if you want us to reply):"
        btnDeactivate_boxSomethingElse.title = "Deactivate routine + breaks"
        
        
        var dropDown_0_Title = "Select a reason"
        var dropDown_1_Title = "I've got an emergency"
        var dropDown_2_Title = "The app is broken"
        var dropDown_3_Title = "My habits are too hard - I can't handle them"

        var dropDownMeeting = "I have a meeting"
        var dropDownSomeOneElse = "Someone else is using my computer"
        var dropDownAnnoying = "I'm finding Focus Bear annoying"
        var dropDownRelax = "I want to relax for a while without restrictions"
        
        var dropDown_4_Title = "Something else"
        
        if let abortInfo = configjson.value(forKey: "abortInfo") as? NSDictionary{
            if let abortingTitle = abortInfo.value(forKey: "abortingTitle") as? String{
                lblTitle.stringValue = abortingTitle
            }
            if let abortingConfirmInfo = abortInfo.value(forKey: "abortingConfirmInfo") as? NSDictionary{
                if let subTitle = abortingConfirmInfo.value(forKey: "subTitle") as? String{
                    lblSubTitle.stringValue = subTitle
                }
                
                if let dropDown_0 = abortingConfirmInfo.value(forKey: "dropDown_0") as? NSDictionary{
                    if let title = dropDown_0.value(forKey: "title") as? String{
                        dropDown_0_Title = title
                    }
                }
                
                if let dropDown_1 = abortingConfirmInfo.value(forKey: "dropDown_1") as? NSDictionary{
                    if let title = dropDown_1.value(forKey: "title") as? String{
                        dropDown_1_Title = title
                    }
                    if let description = dropDown_1.value(forKey: "description") as? String{
                        lblDescriptionFirstBox.stringValue = description
                    }
                }
                if let dropDown_2 = abortingConfirmInfo.value(forKey: "dropDown_2") as? NSDictionary{
                    if let title = dropDown_2.value(forKey: "title") as? String{
                        dropDown_2_Title = title
                    }
                    if let description = dropDown_2.value(forKey: "description") as? String{
                        lblDescriptionSecondBox.stringValue = description
                    }
                    
                    if let emailTitle = dropDown_2.value(forKey: "emailTitle") as? String{
                        lblTitleEmailSecondBox.stringValue = emailTitle
                    }
                    
                    if let buttonDeactivateText = dropDown_2.value(forKey: "buttonDeactivateText") as? String{
                        btnDeactivateAppBroken.title = buttonDeactivateText
                    }
                    
                }
                
                if let dropDown_3 = abortingConfirmInfo.value(forKey: "dropDown_3") as? NSDictionary{
                    if let title = dropDown_3.value(forKey: "title") as? String{
                        dropDown_3_Title = title
                    }
                    if let description = dropDown_3.value(forKey: "description") as? String{
                        lblDescriptionThirdBox.stringValue = description
                    }
                    
                    if let buttonStartSmallText = dropDown_3.value(forKey: "buttonStartSmallText") as? String{
                        lblBtnStartSmall_boxHabit.stringValue = buttonStartSmallText
                    }
                    
                    if let buttonDontWantText = dropDown_3.value(forKey: "buttonDontWantText") as? String{
                        lblBtnDontWantRoutine_boxHabit.stringValue = buttonDontWantText
                    }
                    
                }
                if let dropDown_4 = abortingConfirmInfo.value(forKey: "dropDown_4") as? NSDictionary{
                    if let title = dropDown_4.value(forKey: "title") as? String{
                        dropDown_4_Title = title
                    }
                    if let description = dropDown_4.value(forKey: "description") as? String{
                        lblDescriptionFourthBox.stringValue = description
                    }
                    
                    if let emailTitle = dropDown_4.value(forKey: "emailTitle") as? String{
                        lblTitleEmailFourthBox.stringValue = emailTitle
                    }
                    
                    if let buttonDeactivateText = dropDown_4.value(forKey: "buttonDeactivateText") as? String{
                        btnDeactivate_boxSomethingElse.title = buttonDeactivateText
                    }
                }
                dropDownMeeting = abortingConfirmInfo.value(forKey: "dropDownMeeting") as? String ?? dropDownMeeting
                dropDownSomeOneElse = abortingConfirmInfo.value(forKey: "dropDownSomeOneElse") as? String ?? dropDownSomeOneElse
                dropDownAnnoying = abortingConfirmInfo.value(forKey: "dropDownAnnoying") as? String ?? dropDownAnnoying
                dropDownRelax = abortingConfirmInfo.value(forKey: "dropDownRelax") as? String ?? dropDownRelax
                descriptionNewOptions = abortingConfirmInfo.value(forKey: "descriptionNewOptions") as? String ?? descriptionNewOptions
            }
            
            
            
        }
        allReasons = [dropDown_0_Title,dropDown_1_Title, dropDown_2_Title, dropDown_3_Title, dropDownMeeting, dropDownSomeOneElse, dropDownAnnoying, dropDownRelax, dropDown_4_Title]

        popUpBtnReasons.removeAllItems()
        
        popUpBtnReasons.addItems(withTitles: allReasons)
        textViewAppBroken.delegate = self
        textViewSomethingElse.delegate = self
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
        }
    }
    func resetData(){
        boxEmergency.isHidden = true
        boxAppBroken.isHidden = true
        boxHabitsHard.isHidden = true
        boxSomethingElse.isHidden = true
        popUpBtnReasons.isEnabled = true
        popUpBtnReasons.selectItem(at: 0)
        btnDeactivateAppBroken.isEnabled = false
        lblTimerEmergency.stringValue = "00:05"

    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == textViewAppBroken{
            if popUpBtnReasons.indexOfSelectedItem == brokenAppReasonIndex || popUpBtnReasons.indexOfSelectedItem == appAnnoyingReasonIndex{
                if textView.string.isEmpty{
                    btnDeactivateAppBroken.isEnabled = false
                }else{
                    btnDeactivateAppBroken.isEnabled = true
                }
            }
        }else if textView == textViewSomethingElse{
            if popUpBtnReasons.indexOfSelectedItem == somethingElseReasonIndex{
                if textView.string.isEmpty{
                    btnDeactivate_boxSomethingElse.isEnabled = false
                }else{
                    btnDeactivate_boxSomethingElse.isEnabled = true
                }
            }
        }
    }

    @IBAction func popUpBtnReasonsClicked(_ sender: Any) {
        let index = popUpBtnReasons.indexOfSelectedItem
        switch index {//
        case selectReasonIndex:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
        case emergencyReasonIndex:
            lblTimerEmergency.stringValue = "00:05"
            boxEmergency.isHidden = false
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            popUpBtnReasons.isEnabled = false
            startTimer()
        case brokenAppReasonIndex:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = false
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            textViewAppBroken.string = ""
            btnDeactivateAppBroken.isEnabled = false
            textFieldEmailAppBroken.stringValue = ""
        case habitsTooHardReasonIndex:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = false
            boxSomethingElse.isHidden = true
        case haveMeetingReasonIndex:
            lblTimerEmergency.stringValue = "00:05"
            lblDescriptionFirstBox.stringValue = descriptionNewOptions
            boxEmergency.isHidden = false
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            popUpBtnReasons.isEnabled = false
            startTimer()
        case someOneElseReasonIndex:
            lblTimerEmergency.stringValue = "00:05"
            lblDescriptionFirstBox.stringValue = descriptionNewOptions
            boxEmergency.isHidden = false
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            popUpBtnReasons.isEnabled = false
            startTimer()
        case appAnnoyingReasonIndex:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = false
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            textViewAppBroken.string = ""
            btnDeactivateAppBroken.isEnabled = false
            textFieldEmailAppBroken.stringValue = ""
        case wantToRelaxReasonIndex:
            lblTimerEmergency.stringValue = "00:05"
            lblDescriptionFirstBox.stringValue = descriptionNewOptions
            boxEmergency.isHidden = false
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
            popUpBtnReasons.isEnabled = false
            startTimer()
        case somethingElseReasonIndex:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = false
            textViewSomethingElse.string = ""
            btnDeactivate_boxSomethingElse.isEnabled = false
            textFieldEmail_SomethingELse.stringValue = ""
        default:
            boxEmergency.isHidden = true
            boxAppBroken.isHidden = true
            boxHabitsHard.isHidden = true
            boxSomethingElse.isHidden = true
        }
    }
    func startTimer() {
        currentTimer = 0
        totalDuration = 5
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lblTimerEmergency.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        
        if popUpBtnReasons.indexOfSelectedItem == emergencyReasonIndex{
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"I've got an emergency"])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"I've got an emergency"])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"I've got an emergency"])
            }
        }else if popUpBtnReasons.indexOfSelectedItem == haveMeetingReasonIndex{
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"I have a meeting"])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"I have a meeting"])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"I have a meeting"])
            }
        }else if popUpBtnReasons.indexOfSelectedItem == someOneElseReasonIndex{
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"Someone else is using my computer"])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"Someone else is using my computer"])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"Someone else is using my computer"])
            }
        }else if popUpBtnReasons.indexOfSelectedItem == wantToRelaxReasonIndex{
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"I want to relax for a while without restrictions"])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"I want to relax for a while without restrictions"])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"I want to relax for a while without restrictions"])
            }
        }
        
    }
    @objc func performTimerCount() {
        
        currentTimer += 1
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"

        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        
        DispatchQueue.main.async {
            self.lblTimerEmergency.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    let date = Date().addingTimeInterval(4 * 60 * 60)//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
                    UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
                    addLog(text: "App Deactivated for 4 hours - I've got an emergency")
                    
                    var logType = ""
                    var activity = ""
                    if lastCurrentState == ._MORNING_HABIT_{
                        logType = "morning routine abort"
                        activity = "morning routine"
                    }else if lastCurrentState == ._EVENING_HABIT_{
                        logType = "evening routine abort"
                        activity = "evening routine"
                    }else if lastCurrentState == ._ACTIVITY_{
                        logType = "break abort"
                        activity = "break"
                    }
                    

                    if self.popUpBtnReasons.indexOfSelectedItem == self.emergencyReasonIndex{
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "", tags:"")
                    }else if self.popUpBtnReasons.indexOfSelectedItem == self.haveMeetingReasonIndex{
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I have a meeting", feedback: "", tags:"")
                    }else if self.popUpBtnReasons.indexOfSelectedItem == self.someOneElseReasonIndex{
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Someone else is using my computer", feedback: "", tags:"")
                    }else if self.popUpBtnReasons.indexOfSelectedItem == self.wantToRelaxReasonIndex{
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I want to relax for a while without restrictions", feedback: "", tags:"")
                    }
                    
                    
                    
                    mainViewControllerObj?.disableApp()
                    
                }
            }
        }
    }
    @IBAction func btnDeactivateAppBrokenClicked(_ sender: Any) {
        
        if self.popUpBtnReasons.indexOfSelectedItem == brokenAppReasonIndex{
            addLog(text: "[user-action] btnDeactivateAppBrokenClicked")//
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"The app is broken", "detailed-reason":textViewAppBroken.string])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"The app is broken", "detailed-reason":textViewAppBroken.string])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"The app is broken", "detailed-reason":textViewAppBroken.string])
            }
            
            let alert: NSAlert = NSAlert()
            alert.setSharingType()
            alert.messageText = "Do you want to upload the logs to our server for us to review what was broken?"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                alert.messageText = common.value(forKey: "alertUploadLogText") as? String ?? alert.messageText
            }
            let yesText = buttonYesText
            let noText = buttonNoText
            
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: yesText)
            alert.addButton(withTitle: noText)


            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    print("okclicked")
                    addLog(text: "[user-action] btn Upload logs alert yes Clicked")//
                    
                    self.view.addSubview(getLogsUploadingVcObjObj().view)
                    self.view.addConstraints(subView: getLogsUploadingVcObjObj().view)
                    let abortReason = self.textViewAppBroken.string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self.textViewAppBroken.string
                    allApiObject.uploadAppLogs(feedback: abortReason, completionHandler: {json in
                        DispatchQueue.main.async {
                            getLogsUploadingVcObjObj().view.removeFromSuperview()
//                            allApiObject.getAbortJsonToUpload(emailAddress: currentUserEmail, feedback: self.textViewAppBroken.string, abortReason: "The app is broken", completionHandler: {dic in
//                                DispatchQueue.main.async {
//                                    mainViewControllerObj?.showAbortDoneView()
//                                }
//                            })
                            getHabitsVcObject().showAbortDoneView()
                        }
                    })
                }else{
//                    allApiObject.getAbortJsonToUpload(emailAddress: currentUserEmail, feedback: self.textViewAppBroken.string, abortReason: "The app is broken", completionHandler: {dic in
//                        DispatchQueue.main.async {
//                            mainViewControllerObj?.showAbortDoneView()
//                        }
//                    })
                    getHabitsVcObject().showAbortDoneView()
                }
            })
            
        }else if self.popUpBtnReasons.indexOfSelectedItem == appAnnoyingReasonIndex{
            addLog(text: "[user-action] btnFocusBearannoyingClicked")//
            if lastCurrentState == ._MORNING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"I'm finding Focus Bear annoying", "detailed-reason":textViewAppBroken.string])
            }else if lastCurrentState == ._EVENING_HABIT_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"I'm finding Focus Bear annoying", "detailed-reason":textViewAppBroken.string])
            }else if lastCurrentState == ._ACTIVITY_{
                allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"I'm finding Focus Bear annoying", "detailed-reason":textViewAppBroken.string])
            }
            
            
//            allApiObject.getAbortJsonToUpload(emailAddress: currentUserEmail, feedback: textViewAppBroken.string, abortReason: "I'm finding Focus Bear annoying", completionHandler: {dic in
//                DispatchQueue.main.async {
//                    mainViewControllerObj?.showAbortDoneView()
//                }
//            })
            getHabitsVcObject().showAbortDoneView()
        }
        
    }
    @IBAction func btnStartSmallClicked(_ sender: Any) {
        addLog(text: "[user-action] btnStartSmallClicked")//
        var jsonResult = NSDictionary()
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
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            jsonResult = dicResult
                            print(jsonResult)
                        }
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        guard let mutableDic = jsonResult.mutableCopy() as? NSMutableDictionary else{
            return
        }

        var isAnyHabitRemoved = false
        if var morningHabits = mutableDic.value(forKey: "morning_activities") as? [NSDictionary] {
            for i in 0..<morningHabits.count {
                guard let habitDic = morningHabits[i].mutableCopy() as? NSMutableDictionary else{
                    return
                }
                if let durationSeconds = habitDic["duration_seconds"] as? Int{
                    if durationSeconds > 30{
                        habitDic["duration_seconds"] = 30
                    }
                }
                let newhabitDic = NSDictionary(dictionary: habitDic)
                morningHabits[i] = newhabitDic
            }
            var totalTime = morningHabits.count * 30
            
            while totalTime > 300{
                isAnyHabitRemoved = true
                morningHabits.removeLast()
                totalTime = morningHabits.count * 30
            }
            mutableDic["morning_activities"] = morningHabits
        }

        if var eveningHabits = mutableDic.value(forKey: "evening_activities") as? [NSDictionary] {
            for i in 0..<eveningHabits.count {
                //                var habitDic = morningHabits[i]
                guard let habitDic = eveningHabits[i].mutableCopy() as? NSMutableDictionary else{
                    return
                }
                if let durationSeconds = habitDic["duration_seconds"] as? Int{
                    if durationSeconds > 30{
                        habitDic["duration_seconds"] = 30
                    }
                }
                let newhabitDic = NSDictionary(dictionary: habitDic)
                eveningHabits[i] = newhabitDic
            }
            var totalTime = eveningHabits.count * 30
            
            while totalTime > 300{
                isAnyHabitRemoved = true
                eveningHabits.removeLast()
                totalTime = eveningHabits.count * 30
            }
            mutableDic["evening_activities"] = eveningHabits
        }

        if var breakActivities = mutableDic.value(forKey: "break_activities") as? [NSDictionary] {
            for i in 0..<breakActivities.count {
                //                var habitDic = morningHabits[i]
                guard let habitDic = breakActivities[i].mutableCopy() as? NSMutableDictionary else{
                    return
                }
                if let durationSeconds = habitDic["duration_seconds"] as? Int{
                    if durationSeconds > 30{
                        habitDic["duration_seconds"] = 30
                    }
                }
                let newhabitDic = NSDictionary(dictionary: habitDic)
                breakActivities[i] = newhabitDic
            }

            mutableDic["break_activities"] = breakActivities
        }
        

        allApiObject.isSettingsValid(settings: mutableDic, isOnboarding:false, completionHandler: {dic,statusCode  in
            DispatchQueue.main.async {

                
                if dic == nil{
                    
                    
                }else{
                    
                    if statusCode == 200{

                        
                        do {
                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                            
                            print(jsonResultData)
                            
                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                appdelegate?.readSettingsJsonDictionary(json: nil)
                            }
                            
                            
                        } catch let myJSONError {
                            print(myJSONError)
                        }
                        
                    }else{

                    }
                }
            }
        })
        
        getHabitsVcObject().showAbortStartSmallVc(isAnyHabitRemoved:isAnyHabitRemoved)
    }
    @IBAction func btnDontWantRoutine_boxHabitClicked(_ sender: Any) {
        addLog(text: "[user-action] btnDontWantRoutine_boxHabitClicked")//
        getHabitsVcObject().showAbortDisableMorningRoutineVc()
    }
    @IBAction func btnDeactivate_boxSomethingElseClicked(_ sender: Any) {
       addLog(text: "[user-action] btnDeactivate_boxSomethingElseClicked")//
        var logType = ""
        var activity = ""
        if lastCurrentState == ._MORNING_HABIT_{
            logType = "morning routine abort"
            activity = "morning routine"
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"morning_routine", "deactivate-reason":"Something else", "detailed-reason":textViewSomethingElse.string])
        }else if lastCurrentState == ._EVENING_HABIT_{
            logType = "evening routine abort"
            activity = "evening routine"
            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"evening_routine", "deactivate-reason":"Something else", "detailed-reason":textViewSomethingElse.string])
        }else if lastCurrentState == ._ACTIVITY_{
            logType = "break abort"
            activity = "break"

            allApiObject.capturePosthog(event: "deactivate-routine", metadata: ["routine-type":"break_activity", "deactivate-reason":"Something else", "detailed-reason":textViewSomethingElse.string])
        }
        
        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Something else", feedback: textViewSomethingElse.string, tags:"")
            
        getHabitsVcObject().showAbortDoneView()
    }
}




