//
//  abortingConfirmVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/01/22.
//  
//

import Cocoa

class quittingConfirmVc: NSViewController, NSTextViewDelegate {


 
 
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
 
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var textFieldEmail: NSTextField!
    @IBOutlet weak var btnQuit: NSButton!

    @IBOutlet weak var lblTitleEmail: NSTextField!
    
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!


    @IBOutlet weak var popUpBtnReasons: NSPopUpButton!
    @IBOutlet weak var imgViewGif: NSImageView!

    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTitle.stringValue = "Quitting.."
        lblSubTitle.stringValue = "Can you share why you're quitting?"
        
        
        
        lblTitleEmail.stringValue = "Your Email (if you want us to reply):"
        btnQuit.title = "Quit"


        var dropDown_0_Title = "Select a reason"
        var dropDown_1_Title = "I've got an emergency"
        var dropDown_2_Title = "The app is broken"

        
        var dropDownMeeting = "I have a meeting"
        var dropDownSomeOneElse = "Someone else is using my computer"
        var dropDownAnnoying = "I'm finding Focus Bear annoying"
        var dropDownRelax = "I want to relax for a while without restrictions"
        
        var dropDown_3_Title = "Something else"
        
        
        
        
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
                
                if let dropDown_2 = quittingConfirmInfo.value(forKey: "dropDown_2") as? NSDictionary{
                    if let title = dropDown_2.value(forKey: "title") as? String{
                        dropDown_2_Title = title
                    }
                    if let description = dropDown_2.value(forKey: "description") as? String{
                        dropDown_2_Description = description
                    }

                    if let finalDescription = dropDown_2.value(forKey: "finalDescription") as? String{
                        dropDown_2_FinalDescription = finalDescription
                    }
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
            
        }
        allReasons = [dropDown_0_Title,dropDown_1_Title, dropDown_2_Title, dropDownMeeting, dropDownSomeOneElse, dropDownAnnoying, dropDownRelax, dropDown_3_Title]
        
        popUpBtnReasons.removeAllItems()
        
        popUpBtnReasons.addItems(withTitles: allReasons)
        textView.delegate = self
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgViewGif.image = nil
        }else{
            imgViewGif.image = NSImage(named: "Crying_small")
            imgViewGif.animates = true
        }
    }
    override func viewWillDisappear() {
        self.timer?.invalidate()
        self.timer = nil
    }
    func resetData(){
        popUpBtnReasons.isEnabled = true
        popUpBtnReasons.selectItem(at: 0)
        btnQuit.isEnabled = false
        lblTimer.stringValue = "00:01"
        scrollView.isHidden = true
        scrollView.isHidden = true
        lblDescription.isHidden = true
        lblTimer.isHidden = true
        btnQuit.isHidden = true
        lblTitleEmail.isHidden = true
        textFieldEmail.isHidden = true
    }
    
    func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else{
            return
        }
        if textView == self.textView{
            if textView.string.isEmpty{
                btnQuit.isEnabled = false
            }else{
                btnQuit.isEnabled = true
            }
        }
    }

    @IBAction func popUpBtnReasonsClicked(_ sender: Any) {
        let index = popUpBtnReasons.indexOfSelectedItem
        switch index {
        case 0:
            resetData()
        case 1:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true//
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDown_1_Description
            popUpBtnReasons.isEnabled = false
            startTimer()
        case 2:

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
        case 3:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true//
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDownMeetingDescription
            popUpBtnReasons.isEnabled = false
            startTimer()
        case 4:
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
        
        case 5:
            btnQuit.isHidden = false
            scrollView.isHidden = false
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = false
            textFieldEmail.isHidden = false
            textView.string = ""
            btnQuit.isEnabled = false
            textFieldEmail.stringValue = ""
            lblDescription.stringValue = dropDownAnnoyingDescription
            
        case 6:
            btnQuit.isHidden = true
            scrollView.isHidden = true
            lblTimer.isHidden = true//
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = true
            textFieldEmail.isHidden = true
            lblTimer.stringValue = "00:01"
            lblDescription.stringValue = dropDownRelaxDescription
            popUpBtnReasons.isEnabled = false
            startTimer()
        case 7:
            btnQuit.isHidden = false
            scrollView.isHidden = false
            lblTimer.isHidden = true
            lblDescription.isHidden = false
            lblTitleEmail.isHidden = false
            textFieldEmail.isHidden = false
            textView.string = ""
            btnQuit.isEnabled = false
            textFieldEmail.stringValue = ""
            lblDescription.stringValue = dropDown_3_Description
   
        default:
            resetData()
        }
    }
    func startTimer() {
        currentTimer = 0
        totalDuration = 1
//        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
//        var minute = "\(m)"
//        var second = "\(s)"
//        if minute.count == 1 {
//            minute = "0\(m)"
//        }
//        if second.count == 1 {
//            second = "0\(s)"
//        }
//        self.lblTimer.stringValue = "\(minute):\(second)"//
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
            
        }
    }
    @objc func performTimerCount() {
        
        currentTimer += 1
//        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
//        var minute = "\(m)"
//        var second = "\(s)"
//
//        if minute.count == 1 {
//            minute = "0\(m)"
//        }
//        if second.count == 1 {
//            second = "0\(s)"
//        }
        
        DispatchQueue.main.async {
//            self.lblTimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            self.timer?.invalidate()
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    
                    if self.popUpBtnReasons.indexOfSelectedItem == 1{
                        addLog(text: "App Quit - I've got an emergency")
                        
                        let logType = "Quit"
                        let activity = ""//
                        
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "")
                        appdelegate?.menuItem_Quit()
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 2{
                        addLog(text: "App Quit - The app is broken")
                        allApiObject.getQuitJsonToUpload(emailAddress: currentUserEmail, feedback: self.textView.string, quitReason: "The app is broken", completionHandler: {dic in
                            DispatchQueue.main.async {
                                appdelegate?.menuItem_Quit()
                            }
                        })
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 3{
                        addLog(text: "App Quit - I have a meeting")
                        
                        let logType = "Quit"
                        let activity = ""//
                        
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I have a meeting", feedback: "")
                        appdelegate?.menuItem_Quit()
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 4{
                        addLog(text: "App Quit - Someone else is using my computer")
                        
                        let logType = "Quit"
                        let activity = ""//
                        
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Someone else is using my computer", feedback: "")
                        appdelegate?.menuItem_Quit()
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 5{
                        addLog(text: "App Quit - I'm finding Focus Bear annoying")
                        allApiObject.getQuitJsonToUpload(emailAddress: currentUserEmail, feedback: self.textView.string, quitReason: "I'm finding Focus Bear annoying", completionHandler: {dic in
                            DispatchQueue.main.async {
                                appdelegate?.menuItem_Quit()
                            }
                        })
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 6{
                        addLog(text: "App Quit - I want to relax for a while without restrictions")
                        
                        let logType = "Quit"
                        let activity = ""//
                        
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I want to relax for a while without restrictions", feedback: "")
                        appdelegate?.menuItem_Quit()
                    }else if self.popUpBtnReasons.indexOfSelectedItem == 7{
                        addLog(text: "App Quit - Something else")
                        let logType = "Quit"//
                        let activity = ""
                        
                        addEntryInStatsCsv(logType: logType, activity: activity, durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "Something else", feedback: self.textView.string)
                        appdelegate?.menuItem_Quit()
                    }
                }
            }
        }
    }

   
    @IBAction func btnQuitClicked(_ sender: Any) {
        addLog(text: "quittingConfirmVc - btnQuitClicked")//
        self.btnQuit.isHidden = true
        self.scrollView.isHidden = true
        self.lblTimer.isHidden = true//
        self.lblDescription.isHidden = false
        self.lblTitleEmail.isHidden = true
        self.textFieldEmail.isHidden = true
        self.lblTimer.stringValue = "00:01"
        self.lblDescription.stringValue = self.dropDown_1_Description
        
        if self.popUpBtnReasons.indexOfSelectedItem == 2{
            self.lblDescription.stringValue = dropDown_2_FinalDescription
        }else if self.popUpBtnReasons.indexOfSelectedItem == 7{
            self.lblDescription.stringValue = dropDown_3_FinalDescription
        }else if self.popUpBtnReasons.indexOfSelectedItem == 5{
            self.lblDescription.stringValue = dropDownAnnoyingFinalDescription
        }
        self.popUpBtnReasons.isEnabled = false
        self.startTimer()
    }
    

}




