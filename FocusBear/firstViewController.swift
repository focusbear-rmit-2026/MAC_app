//
//  firstViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {
    
   
    @IBOutlet weak var btnEditHabits: Button!
    @IBOutlet weak var lblTitleSelectActivity: NSTextField!
    @IBOutlet weak var lblTitleEnterActivityName: NSTextField!
    @IBOutlet weak var textFieldActivity: NSTextField!
    @IBOutlet weak var popUpBtnActivities: NSPopUpButton!
    @IBOutlet weak var boxSelectActivities: NSBox!
    @IBOutlet weak var lblProgress: NSTextField!
    @IBOutlet weak var btnPostponeBreak: underLineButton!
    @IBOutlet weak var btnTopSpace: NSLayoutConstraint!
    @IBOutlet weak var btnBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewTopSpace: NSLayoutConstraint!
    @IBOutlet weak var imgViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lbltimer: NSTextField!
    @IBOutlet weak var scrollViewHabits: NSScrollView!
    @IBOutlet weak var lblBeforeYouStart: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    //    @IBOutlet weak var btnWidth: NSLayoutConstraint!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStartFirstHabit: NSButton!
    @IBOutlet weak var tblViewHabits: NSTableView!
    @IBOutlet weak var btnInfo: cursorButton!
    //    var isGetKookyButtonVisible = false
    var isFirstTime = false
    var introActivities = [NSDictionary]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnStartFirstHabit.cell?.wraps = true
        lblBeforeYouStart.isHidden = true
//        lblTitle.font = NSFont(name: "Fenwick", size: lblTitle.font?.pointSize ?? 24)!
        btnEditHabits.title = "Customise my habits first"
        lblTitleSelectActivity.stringValue = "What 30 seconds of activity do you want to do?"
        lblTitleEnterActivityName.stringValue = "Enter name of activity"
        
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            lblTitleSelectActivity.stringValue = dic.value(forKey: "titleSelectActivity") as? String ?? lblTitleSelectActivity.stringValue
            lblTitleEnterActivityName.stringValue = dic.value(forKey: "titleEnterActivityName") as? String ?? lblTitleEnterActivityName.stringValue
            btnEditHabits.title = dic.value(forKey: "buttonEditHabitsText") as? String ?? btnEditHabits.title
        }
        textFieldActivity.delegate = self
        
        btnEditHabits.buttonColor = NSColor.white.cgColor
    }

    @IBAction func btnInfoClicked(_ sender: Any) {
        btnInfo.isHidden = true
        if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
            if isHabitsDisabled{
                lblSubTitle.stringValue = "Throughout the day, I'll remind you to take regular breaks to keep your mind sharp and your body flexible. Here's an example of a break activity: 30 seconds of deep breathing."
                if let subTitle = dic.value(forKey: "welcomeMessageOnlyBreakIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
            }else{
                if let subTitle = dic.value(forKey: "welcomeMessageIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
            }
        }
    }
    override func viewWillAppear() {
        boxSelectActivities.isHidden = true
        lbltimer.isHidden = true
        btnStartFirstHabit.isEnabled = true
        btnInfo.isHidden = true
        btnEditHabits.isHidden = true
        if isFirstTime{
            textFieldActivity.isHidden = true
            lblTitleEnterActivityName.isHidden = true
            allApiObject.capturePosthog(event: "start-onboarding-activity-shown", metadata: [:])
            btnPostponeBreak.isHidden = false
            btnPostponeBreak.title = "Skip"
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                btnPostponeBreak.title = dic.value(forKey: "buttonSkipText") as? String ?? btnPostponeBreak.title
            }
            lblProgress.isHidden = true
            imgView.image = NSImage(named: "icon 130")//
            imgViewHeight.constant = 160
            imgViewTopSpace.constant = 35
            imgViewBottomSpace.constant = 5
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            scrollViewHabits.isHidden = true
            btnBottomSpace.constant = 63
            btnTopSpace.constant = 171
            let welcomeText = "Let’s take a quick 30 second break"
            btnInfo.isHidden = false
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "welcomeMessageHeading") as? String ?? welcomeText
                
                lblSubTitle.stringValue = "Taking breaks throughout the day helps with stress and focus."
                if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                    if let subTitle = dic.value(forKey: "takingBreaksText") as? String{
                        lblSubTitle.stringValue = subTitle
                    }
                }
                
                if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                    introActivities = arr
                    let name = arr.first?.value(forKey: "name") as? String ?? ""
                    let durationSeconds = arr.first?.value(forKey: "duration_seconds") as? Int ?? 0
                    let videoUrl = arr.first?.value(forKey: "video_urls") as? [String] ?? []
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                    introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[])
                    btnStartFirstHabit.isEnabled = true
                    
                    
                    popUpBtnActivities.removeAllItems()
                    for item in arr{
                        popUpBtnActivities.addItem(withTitle: item.value(forKey: "name") as? String ?? "")
                    }
                    popUpBtnActivities.selectItem(at: 0)
                    boxSelectActivities.isHidden = false
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    btnStartFirstHabit.toolTip = btnStartFirstHabit.title
                    introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[])
                }
            }else{
                introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[])
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                btnStartFirstHabit.toolTip = btnStartFirstHabit.title
            }
        }else{
            
            if currentState == ._MORNING_HABIT_{
                if !has_edited_settings{
                    btnEditHabits.isHidden = false
                }
                btnPostponeBreak.isHidden = true
                lblProgress.isHidden = true
                btnBottomSpace.constant = 63
                btnTopSpace.constant = 171
                if SettingsManagerObject.kIsReducedMotion{
                    imgView.image = nil
                    imgViewHeight.constant = 40
                    imgViewTopSpace.constant = 35
                    imgViewBottomSpace.constant = 5
                }else{
                    imgViewHeight.constant = 160
                    imgViewTopSpace.constant = 15
                    imgViewBottomSpace.constant = 0
                    imgView.image = NSImage(named: "Waking up _ SMall")
                    imgView.animates = true
                }
                habitTotalCompletedSeconds = 0
                lblTitle.stringValue = startMorningHabitTitleText
//                if isGetKookyButtonVisible{
                    btnStartFirstHabit.title = "Begin"
                    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                        btnStartFirstHabit.title = activityInfo.value(forKey: "buttonBeginText") as? String ?? btnStartFirstHabit.title
                    }
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                
                
            }else if currentState == ._EVENING_HABIT_{

                if !has_edited_settings{
                    btnEditHabits.isHidden = false
                }
                btnPostponeBreak.isHidden = true
                lblProgress.isHidden = true
                btnTopSpace.constant = 171
                btnBottomSpace.constant = 63
                imgView.image = nil
                imgViewHeight.constant = 40
                imgViewTopSpace.constant = 35
                imgViewBottomSpace.constant = 5
                lblTitle.stringValue = startEveningHabitTitleText
                habitTotalCompletedSeconds = 0
                
                
//                if isGetKookyButtonVisible{
                    btnStartFirstHabit.title = "Begin"
                    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                        btnStartFirstHabit.title = activityInfo.value(forKey: "buttonBeginText") as? String ?? btnStartFirstHabit.title
                    }
//                }else{
//                    if arrFilteredEveningHabits.count != 0 {
//                        let time = arrFilteredEveningHabits[0].durationSeconds!
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[0].name!)
//                        btnStartFirstHabit.toolTip = btnStartFirstHabit.title
//                    }
//                }

                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
            }else if currentState == ._ACTIVITY_{
                btnEditHabits.isHidden = true
                btnPostponeBreak.isHidden = false
                lblProgress.isHidden = false


                btnPostponeBreak.title = "Skip this habit for today"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnPostponeBreak.title = activityInfo.value(forKey: "buttonSkipHabitText") as? String ?? btnPostponeBreak.title
                }
                
                lblTitle.stringValue = thirdVcObj?.lblTitle.stringValue ?? ""
                btnStartFirstHabit.title = thirdVcObj?.btnMain.title ?? ""

                lblProgress.stringValue = thirdVcObj?.lblProgress.stringValue ?? ""
                
                
                btnTopSpace.constant = 134
                btnBottomSpace.constant = 100
                imgView.image = nil
                imgViewHeight.constant = 40
                imgViewTopSpace.constant = 35
                imgViewBottomSpace.constant = 5
                habitTotalCompletedSeconds = 0

                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                lblSubTitle.isHidden = true
            }
        }
        
    }
    @IBAction func popUpBtnActivitiesClicked(_ sender: Any) {
        let index = popUpBtnActivities.indexOfSelectedItem
        let name = introActivities[index].value(forKey: "name") as? String ?? ""
        let durationSeconds = introActivities[index].value(forKey: "duration_seconds") as? Int ?? 0
        let videoUrl = introActivities[index].value(forKey: "video_urls") as? [String] ?? []
        btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
        introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[])
        
//        if index == (introActivities.count-1){
//            btnStartFirstHabit.isEnabled = false
//            lblTitleEnterActivityName.isHidden = false
//            textFieldActivity.stringValue = ""
//            textFieldActivity.isHidden = false
//            textFieldActivity.setFocus()
//        }else{
//            btnStartFirstHabit.isEnabled = true
//            lblTitleEnterActivityName.isHidden = true
//            textFieldActivity.isHidden = true
//        }
        btnStartFirstHabit.isEnabled = true
        lblTitleEnterActivityName.isHidden = true
        textFieldActivity.isHidden = true

    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0

    @IBAction func btnPostponeClicked(_ sender: Any) {
        if currentState == ._BREATHING_{
            mainViewControllerObj?.btnAbortClicked(self)
            return;
        }
        thirdVcObj?.btnSkipHabitClicked(self)
    }

    
    @IBAction func btnEditHabitsClicked(_ sender: Any) {
        self.view.addSubview(getEditHabitRoutineVcObject().view)
        self.view.addConstraints(subView: getEditHabitRoutineVcObject().view)
    }
    override func viewWillDisappear() {
        if editHabitRoutineVcObj != nil{
            if self.view.subviews.contains(getEditHabitRoutineVcObject().view){
                getEditHabitRoutineVcObject().view.removeFromSuperview()
            }
        }
    }
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        addLog(text: "btnStartFirstHabitClicked")
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
            if enterPasswordVcObj != nil{
                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                    return;
                }
            }
        }
        if isFirstTime{
            mainViewControllerObj?.startBreathing()
        }else{
            if currentState == ._MORNING_HABIT_{
                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"morning_routine"])
            }else if currentState == ._EVENING_HABIT_{
                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-evening-routine", metadata: ["routine-type":"evening_routine"])
            }else if currentState == ._ACTIVITY_{
                thirdVcObj?.btnMainClicked(self)
            }
        }
    }
}
extension firstViewController:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if currentState == ._MORNING_HABIT_{
            return  arrFilteredMorningHabits.count
        }else if currentState == ._EVENING_HABIT_{
            return  arrFilteredEveningHabits.count
        }else if currentState == ._ACTIVITY_{
            return  arrFinalBreakActivities.count
        }else{
            return 0
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            if currentState == ._MORNING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredMorningHabits[row].name ?? "")"
            }else if currentState == ._EVENING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrFilteredEveningHabits[row].name ?? "")"
            }else if currentState == ._ACTIVITY_{
                var activityName = ""
                let duration = arrFinalBreakActivities[row].activity.durationSeconds ?? 0
                if let choice = arrFinalBreakActivities[row].randomChoice{
                    activityName = choice.name
                }else{
                    activityName = arrFinalBreakActivities[row].activity.name ?? ""
                }
                if arrFinalBreakActivities[row].activity.useTimer{
                    cell.lblTitle.stringValue  = "\(row + 1).   \(activityName) - \(getStringTime(seconds: duration))"
                }else{
                    cell.lblTitle.stringValue  = "\(row + 1).   \(activityName)"
                }
                
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
}

extension firstViewController:NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if textField == self.textFieldActivity{
                let title = textField.stringValue
                let index = popUpBtnActivities.indexOfSelectedItem
                var name = introActivities[index].value(forKey: "name") as? String ?? ""
                let durationSeconds = introActivities[index].value(forKey: "duration_seconds") as? Int ?? 0
                let videoUrl = introActivities[index].value(forKey: "video_urls") as? [String] ?? []
                if title.isEmpty{
                    btnStartFirstHabit.isEnabled = false
                }else{
                    name = title
                    btnStartFirstHabit.isEnabled = true
                }
                
                
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList:[])
                
            }
        }
    }
}
