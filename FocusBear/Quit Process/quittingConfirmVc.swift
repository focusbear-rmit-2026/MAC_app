//
//  abortingConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/01/22.
//  
//

import Cocoa

class quittingConfirmVc: NSViewController, NSTextViewDelegate {

    @IBOutlet weak var popUpBtnAppNotWorking: NSPopUpButton!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var textFieldEmail: NSTextField!
    @IBOutlet weak var btnQuit: Button!
    @IBOutlet weak var lblTitleEmail: NSTextField!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var popUpBtnReasons: NSPopUpButton!
    @IBOutlet weak var imgViewGif: NSImageView!
    @IBOutlet weak var btnCancelQuit: Button!
    
    var currentTimer = 0
    var totalDuration = 10
    var timer:Timer?
    
    var allReasons = [String]()
    var dropDown_1_Description = "Uh oh! Hope everything is ok. Restoring access immediately and quitting app."
    var dropDown_2_Description = "Oh no! We're really sorry. Can you please let us know what happened?﹡"
    var dropDown_3_Description = "Can you tell us why you want to stop getting habit + break notifications?﹡"
    
    var dropDownMeetingDescription = "We hope you will start the habits back soon! See you soon."
    var dropDownSomeOneElseDescription = "We hope you will start the habits back soon! See you soon."
    var dropDownAnnoyingDescription = "Oh no! We're really sorry. Can you please let us know what happened?﹡"
    var dropDownRelaxDescription = "We hope you will start the habits back soon! See you soon."
    
    
    
    var dropDown_2_FinalDescription = "We hope you will start the habits back soon! See you soon."
    var dropDown_3_FinalDescription = "We hope you will start the habits back soon! See you soon."
    
    var dropDownAnnoyingFinalDescription = "We hope you will start the habits back soon! See you soon."
    
    let emergencyReasonIndex = 1
    let brokenAppReasonIndex = 2
    let haveMeetingReasonIndex = 3
    let someOneElseReasonIndex = 4
    let appAnnoyingReasonIndex = 5
    let wantToRelaxReasonIndex = 6
    let somethingElseReasonIndex = 7
    let selectReasonIndex = 0
    
    
    let reasonFocusModeIndex = 1
    let reasonHabitsIndex = 2
    let reasonBlockingIndex = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Quitting.."
        lblSubTitle.stringValue = "Can you share why you're quitting?"
        lblTitleEmail.stringValue = "Your Email (if you want us to reply):"
        btnQuit.title = "Quit"

        var dropDown_0_Title = "Select a reason"
        var dropDown_1_Title = "I've got an emergency"
        var dropDown_2_Title = "App not working properly"
        var dropDownMeeting = "I have a meeting"
        var dropDownSomeOneElse = "Someone else is using my computer"
        var dropDownAnnoying = "I'm finding Focus Bear annoying"
        var dropDownRelax = "I want to relax for a while without restrictions"
        var dropDown_3_Title = "Something else"
        
        var reasonFocusMode = "My focus modes are not working properly"
        var reasonHabits = "My habits are not working properly"
        var reasonBlocking = "The blocking features are not working properly"
        
        
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingTitle = quitInfo.value(forKey: "quittingTitle") as? String{
                lblTitle.stringValue = quittingTitle
            }
            if let quittingConfirmInfo = quitInfo.value(forKey: "quittingConfirmInfo") as? NSDictionary{
                if let subTitle = quittingConfirmInfo.value(forKey: "subTitle") as? String{
                    lblSubTitle.stringValue = subTitle
                }
                if let buttonQuitText = quittingConfirmInfo.value(forKey: "buttonQuitText") as? String{
                    btnQuit.title = buttonQuitText
                }
                if let emailTitle = quittingConfirmInfo.value(forKey: "emailTitle") as? String{
                    lblTitleEmail.stringValue = emailTitle
                }
                
                if let dropDown_0 = quittingConfirmInfo.value(forKey: "dropDown_0") as? NSDictionary{
                    if let title = dropDown_0.value(forKey: "title") as? String{
                        dropDown_0_Title = title
                    }
                }
                if let dropDown_1 = quittingConfirmInfo.value(forKey: "dropDown_1") as? NSDictionary{
                    if let title = dropDown_1.value(forKey: "title") as? String{
                        dropDown_1_Title = title
                    }
                    if let description = dropDown_1.value(forKey: "description") as? String{
                        dropDown_1_Description = description
                    }
                }
                
                if let dropDownAppNotWorking = quittingConfirmInfo.value(forKey: "dropDownAppNotWorking") as? NSDictionary{
                    if let title = dropDownAppNotWorking.value(forKey: "title") as? String{
                        dropDown_2_Title = title
                    }
                    if let description = dropDownAppNotWorking.value(forKey: "description") as? String{
                        dropDown_2_Description = description
                    }

                    if let finalDescription = dropDownAppNotWorking.value(forKey: "finalDescription") as? String{
                        dropDown_2_FinalDescription = finalDescription
                    }
                    reasonFocusMode = dropDownAppNotWorking.value(forKey: "reasonFocusMode") as? String ?? reasonFocusMode
                    reasonHabits = dropDownAppNotWorking.value(forKey: "reasonHabits") as? String ?? reasonHabits
                    reasonBlocking = dropDownAppNotWorking.value(forKey: "reasonBlocking") as? String ?? reasonBlocking
                }
                if let dropDown_3 = quittingConfirmInfo.value(forKey: "dropDown_3") as? NSDictionary{
                    if let title = dropDown_3.value(forKey: "title") as? String{
                        dropDown_3_Title = title
                    }
                    if let description = dropDown_3.value(forKey: "description") as? String{
                        dropDown_3_Description = description
                    }
                    if let finalDescription = dropDown_3.value(forKey: "finalDescription") as? String{
                        dropDown_3_FinalDescription = finalDescription
                    }
                }
                
                if let dropDown = quittingConfirmInfo.value(forKey: "dropDownMeeting") as? NSDictionary{
                    if let title = dropDown.value(forKey: "title") as? String{
                        dropDownMeeting = title
                    }
                    if let description = dropDown.value(forKey: "description") as? String{
                        dropDownMeetingDescription = description
                    }
                }
                
                if let dropDown = quittingConfirmInfo.value(forKey: "dropDownSomeOneElse") as? NSDictionary{
                    if let title = dropDown.value(forKey: "title") as? String{
                        dropDownSomeOneElse = title
                    }
                    if let description = dropDown.value(forKey: "description") as? String{
                        dropDownSomeOneElseDescription = description
                    }
                }
                if let dropDown = quittingConfirmInfo.value(forKey: "dropDownAnnoying") as? NSDictionary{
                    if let title = dropDown.value(forKey: "title") as? String{
                        dropDownAnnoying = title
                    }
                    if let description = dropDown.value(forKey: "description") as? String{
                        dropDownAnnoyingDescription = description
                    }
                    if let finalDescription = dropDown.value(forKey: "finalDescription") as? String{
                        dropDownAnnoyingFinalDescription = finalDescription
                    }
                }
                
                if let dropDown = quittingConfirmInfo.value(forKey: "dropDownRelax") as? NSDictionary{
                    if let title = dropDown.value(forKey: "title") as? String{
                        dropDownRelax = title
                    }
                    if let description = dropDown.value(forKey: "description") as? String{
                        dropDownRelaxDescription = description
                    }
                }
            }
            if let abortInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let quittingCountDownInfo = abortInfo.value(forKey: "quittingCountDownInfo") as? NSDictionary{
                    btnCancelQuit.title = quittingCountDownInfo.value(forKey: "buttonQuitCancelText") as? String ?? btnCancelQuit.title
                }
            }
        }
        allReasons = [dropDown_0_Title,dropDown_1_Title, dropDown_2_Title, dropDownMeeting, dropDownSomeOneElse, dropDownAnnoying, dropDownRelax, dropDown_3_Title]
        
        popUpBtnReasons.removeAllItems()
        
        popUpBtnReasons.addItems(withTitles: allReasons)
        textView.delegate = self
        
        
        popUpBtnAppNotWorking.removeAllItems()
        popUpBtnAppNotWorking.addItems(withTitles: [dropDown_0_Title, reasonFocusMode, reasonHabits, reasonBlocking])
        popUpBtnAppNotWorking.selectItem(at: selectReasonIndex)
        popUpBtnAppNotWorking.isHidden = true
        btnQuit.buttonColor = NSColor.white.cgColor
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
            imgViewGif.isHidden = true
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
            imgViewGif.isHidden = false
        }
    }
    override func viewWillDisappear() {
        self.timer?.invalidate()
        self.timer = nil
        if enterPasswordVcObj != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                enterPasswordVcObj?.view.removeFromSuperview()
            }
        }
    }

    var enterPasswordVcObj: enterPasswordVc?
    func resetData(){
        popUpBtnAppNotWorking.isHidden = true
        popUpBtnAppNotWorking.selectItem(at: selectReasonIndex)
        popUpBtnReasons.isEnabled = true
        popUpBtnReasons.selectItem(at: selectReasonIndex)
        btnQuit.isEnabled = false
        lblTimer.stringValue = "00:01"
        scrollView.isHidden = true
        scrollView.isHidden = true
        lblDescription.isHidden = true
        lblTimer.isHidden = true
        btnQuit.isHidden = true
        lblTitleEmail.isHidden = true
        textFieldEmail.isHidden = true
        
        if shouldAskPassword(){
            if SettingsManagerObject.isPasswordRequireInQuitApp{
                if self.enterPasswordVcObj == nil{
                    self.enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc
                }
                self.view.addSubview(self.enterPasswordVcObj!.view)
                self.view.addConstraints(subView: self.enterPasswordVcObj!.view)
                self.enterPasswordVcObj?.removeConstraints()
                addLog(text: "Showing enter password view from quit")
            }
            
        }
    }

    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if popUpBtnReasons.indexOfSelectedItem == brokenAppReasonIndex{
            return;
        }
//        if textView == self.textView{
//            if textView.string.isEmpty{
//                btnQuit.isEnabled = false
//            }else{
//                btnQuit.isEnabled = true
//            }
//        }
    }

    @IBAction func popUpBtnReasonsClicked(_ sender: Any) {
        popUpBtnAppNotWorking.isHidden = true
        let index = popUpBtnReasons.indexOfSelectedItem
        switch index {
        case selectReasonIndex:
            resetData()
        case emergencyReasonIndex:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDown_1_Description
            popUpBtnReasons.isEnabled = false
            startTimer()
        case brokenAppReasonIndex:
            popUpBtnAppNotWorking.isHidden = false
            btnQuit.isHidden = false
            scrollView.isHidden = false
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = false
            textFieldEmail.isHidden = false
            textView.string = ""
            btnQuit.isEnabled = false
            textFieldEmail.stringValue = ""
            lblDescription.stringValue = dropDown_2_Description
        case haveMeetingReasonIndex:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDownMeetingDescription
            popUpBtnReasons.isEnabled = false
            startTimer()
        case someOneElseReasonIndex:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true//
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDownSomeOneElseDescription
            popUpBtnReasons.isEnabled = false
            startTimer()
        
        case appAnnoyingReasonIndex:
            btnQuit.isHidden = false
            scrollView.isHidden = false
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = false
            textFieldEmail.isHidden = false
            textView.string = ""
            btnQuit.isEnabled = true
            textFieldEmail.stringValue = ""
            lblDescription.stringValue = dropDownAnnoyingDescription
            
        case wantToRelaxReasonIndex:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDownRelaxDescription
            popUpBtnReasons.isEnabled = false
            startTimer()
        case somethingElseReasonIndex:
            btnQuit.isHidden = false
            scrollView.isHidden = false
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = false
            textFieldEmail.isHidden = false
            textView.string = ""
            btnQuit.isEnabled = true
            textFieldEmail.stringValue = ""
            lblDescription.stringValue = dropDown_3_Description
   
        default:
            resetData()
        }
    }
    func startTimer() {
        currentTimer = 0
        totalDuration = 1
        if self.popUpBtnReasons.indexOfSelectedItem == self.emergencyReasonIndex{
            addLog(text: "App Quit - I've got an emergency")
            
            let logType = "Quit"
            let activity = ""
            UserDefaults.standard.set("I've got an emergency", forKey: kUserDefaultsLastQuitReason)
            addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "", tags:"")

            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"I've got an emergency", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.brokenAppReasonIndex{
            addLog(text: "App Quit - The app is broken")
            var quitReason = "App not working properly:"
            
            if popUpBtnAppNotWorking.indexOfSelectedItem == reasonFocusModeIndex{
                quitReason = quitReason + " " + "My focus modes are not working properly"
            }else if popUpBtnAppNotWorking.indexOfSelectedItem == reasonHabitsIndex{
                quitReason = quitReason + " " + "My habits are not working properly"
            }else if popUpBtnAppNotWorking.indexOfSelectedItem == reasonBlockingIndex{
                quitReason = quitReason + " " + "The blocking features are not working properly"
            }
            UserDefaults.standard.set(quitReason, forKey: kUserDefaultsLastQuitReason)
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":quitReason, "usageStartDate":getFirstRunDateString(), "feedback":self.textView.string, "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
            
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.haveMeetingReasonIndex{
            addLog(text: "App Quit - I have a meeting")
            
            let logType = "Quit"
            let activity = ""//
            UserDefaults.standard.set("I have a meeting", forKey: kUserDefaultsLastQuitReason)
            addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I have a meeting", feedback: "", tags:"")
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"I have a meeting", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.someOneElseReasonIndex{
            addLog(text: "App Quit - Someone else is using my computer")
            
            let logType = "Quit"
            let activity = ""
            UserDefaults.standard.set("Someone else is using my computer", forKey: kUserDefaultsLastQuitReason)
            addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Someone else is using my computer", feedback: "", tags:"")
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"Someone else is using my computer", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.appAnnoyingReasonIndex{
            addLog(text: "App Quit - I'm finding Focus Bear annoying")
            UserDefaults.standard.set("I'm finding Focus Bear annoying", forKey: kUserDefaultsLastQuitReason)
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"I'm finding Focus Bear annoying", "usageStartDate":getFirstRunDateString(), "feedback":self.textView.string, "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.wantToRelaxReasonIndex{
            addLog(text: "App Quit - I want to relax for a while without restrictions")
            
            let logType = "Quit"
            let activity = ""
            UserDefaults.standard.set("I want to relax for a while without restrictions", forKey: kUserDefaultsLastQuitReason)
            addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I want to relax for a while without restrictions", feedback: "", tags:"")
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"I want to relax for a while without restrictions", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }else if self.popUpBtnReasons.indexOfSelectedItem == self.somethingElseReasonIndex{
            addLog(text: "App Quit - Something else")
            let logType = "Quit"//
            let activity = ""
            UserDefaults.standard.set("Something else", forKey: kUserDefaultsLastQuitReason)
            
            addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Something else", feedback: self.textView.string, tags:"")
            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"Something else", "usageStartDate":getFirstRunDateString(), "feedback":self.textView.string, "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled()])
        }
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        DispatchQueue.main.async {

        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
//                    appdelegate?.menuItem_Quit()
                    appdelegate?.quitAppForUser()
                }
            }
        }
    }

    @IBAction func popUpBtnAppNotWorkingClicked(_ sender: Any) {
        if popUpBtnAppNotWorking.indexOfSelectedItem == selectReasonIndex{
            btnQuit.isEnabled = false
        }else{
            btnQuit.isEnabled = true
        }
    }
    @IBAction func btnCancelQuitClicked(_ sender: Any) {
        self.view.window?.close()
    }
    @IBAction func btnQuitClicked(_ sender: Any) {
        addLog(text: "[user-action] quittingConfirmVc - btnQuitClicked")
        self.btnQuit.isHidden = true
        self.scrollView.isHidden = true
        self.lblTimer.isHidden = true
        self.lblDescription.isHidden = false
        self.lblTitleEmail.isHidden = true
        self.textFieldEmail.isHidden = true
        self.lblTimer.stringValue = "00:01"
        self.lblDescription.stringValue = self.dropDown_1_Description
        
        if self.popUpBtnReasons.indexOfSelectedItem == brokenAppReasonIndex{
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
                    addLog(text: "[user-action] btn Upload logs alert yes Clicked")
                    self.view.addSubview(getLogsUploadingVcObjObj().view)
                    self.view.addConstraints(subView: getLogsUploadingVcObjObj().view)
                    let quitReason = self.textView.string.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? self.textView.string
                    allApiObject.uploadAppLogs(feedback: quitReason, completionHandler: {json in
                        DispatchQueue.main.async {
                            getLogsUploadingVcObjObj().view.removeFromSuperview()
                            self.popUpBtnReasons.isEnabled = false
                            self.startTimer()
                        }
                    })

                }else{
                    self.popUpBtnReasons.isEnabled = false
                    self.startTimer()
                }
            })
            self.lblDescription.stringValue = dropDown_2_FinalDescription
        }else if self.popUpBtnReasons.indexOfSelectedItem == somethingElseReasonIndex{
            self.lblDescription.stringValue = dropDown_3_FinalDescription
            self.popUpBtnReasons.isEnabled = false
            self.startTimer()
        }else if self.popUpBtnReasons.indexOfSelectedItem == appAnnoyingReasonIndex{
            self.lblDescription.stringValue = dropDownAnnoyingFinalDescription
            self.popUpBtnReasons.isEnabled = false
            self.startTimer()
        }
    }
}




