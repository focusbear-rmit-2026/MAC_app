//
//  firstViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {
    
   
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
//    var isGetKookyButtonVisible = false
    var isFirstTime = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnStartFirstHabit.cell?.wraps = true
        lblBeforeYouStart.isHidden = true
//        lblTitle.font = NSFont(name: "Fenwick", size: lblTitle.font?.pointSize ?? 24)!
    }

    override func viewWillAppear() {
        
        lbltimer.isHidden = true
        if isFirstTime{
            btnPostponeBreak.isHidden = true
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
            let welcomeText = "Welcome to Focus Bear"
            
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "welcomeMessageHeading") as? String ?? welcomeText
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
                
                if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                    let name = arr.first?.value(forKey: "name") as? String ?? ""
                    let durationSeconds = arr.first?.value(forKey: "duration_seconds") as? Int ?? 0
                    let videoUrl = arr.first?.value(forKey: "video_urls") as? [String] ?? []
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                    btnStartFirstHabit.toolTip = btnStartFirstHabit.title
                    introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [])
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    btnStartFirstHabit.toolTip = btnStartFirstHabit.title
                    introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [])
                }
            }else{
                introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [])
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                btnStartFirstHabit.toolTip = btnStartFirstHabit.title
            }
        }else{
            
            if currentState == ._MORNING_HABIT_{

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
                btnPostponeBreak.isHidden = false
                lblProgress.isHidden = false
                
                
                btnPostponeBreak.title = "Postpone break for five minutes"
                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
                    btnPostponeBreak.title = activityInfo.value(forKey: "buttonPostponeBreakText") as? String ?? btnPostponeBreak.title
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
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0

    @IBAction func btnPostponeClicked(_ sender: Any) {
        thirdVcObj?.btnSkipHabitClicked(self)
    }
    func startTimer(duration:Int) {
        if isTimerGoingOn{
            btnStartFirstHabit.isHidden = true
            lbltimer.isHidden = false
            return
        }
        btnStartFirstHabit.isHidden = true
        lbltimer.isHidden = false
        isTimerGoingOn = true
        currentTimer = 0
        totalDuration = duration
        let (_,m,s) = secondsToHoursMinutesSeconds(seconds: self.totalDuration-currentTimer)
        var minute = "\(m)"
        var second = "\(s)"
        if minute.count == 1 {
            minute = "0\(m)"
        }
        if second.count == 1 {
            second = "0\(s)"
        }
        self.lbltimer.stringValue = "\(minute):\(second)"
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
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
            self.lbltimer.isHidden = false
            self.lbltimer.stringValue = "\(minute):\(second)"
        }
        if self.totalDuration <= self.currentTimer {
            
            self.timer?.invalidate()
            DispatchQueue.main.async {
                self.btnStartFirstHabit.isHidden = false
                self.lbltimer.isHidden = true
                self.isTimerGoingOn = false
                
                if currentState == ._MORNING_HABIT_{
                    if arrFilteredMorningHabits.count != 0 {
                        let time = arrFilteredMorningHabits[0].durationSeconds!
                        self.btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredMorningHabits[0].name!)
                        self.btnStartFirstHabit.toolTip = self.btnStartFirstHabit.title
                    }
                }else if currentState == ._EVENING_HABIT_{
                    if arrFilteredEveningHabits.count != 0 {
                        let time = arrFilteredEveningHabits[0].durationSeconds!
                        self.btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrFilteredEveningHabits[0].name!)
                        self.btnStartFirstHabit.toolTip = self.btnStartFirstHabit.title
                    }
                }
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
                cell.lblTitle.stringValue  = "\(row + 1).   \(activityName) - \(getStringTime(seconds: duration))"
                
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
}
