//
//  firstViewController.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {
    
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
            lblBeforeYouStart.isHidden = true
            imgView.image = NSImage(named: "icon 130")//
            imgViewHeight.constant = 160
            imgViewTopSpace.constant = 35
            imgViewBottomSpace.constant = 5
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            scrollViewHabits.isHidden = true
            
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
                    introActivity = habit(id:"", name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "")
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    btnStartFirstHabit.toolTip = btnStartFirstHabit.title
                    introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "")
                }
            }else{
                introActivity = habit(id:"", name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "")
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                btnStartFirstHabit.toolTip = btnStartFirstHabit.title
            }
        }else{
            
            if currentState == ._MORNING_HABIT_{
//                var beforeYouBeginText = "Before you begin, take 30 seconds to visualise yourself performing each of the habits. This sounds kooky but research indicates that doing a mental rehearsal like this increases the likelihood of you completing the habits and makes the habits more sticky so that even if you don't have access to your computer/this app, you'll still do all the habits"
//                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
//                    beforeYouBeginText = activityInfo.value(forKey: "beforeYouBeginText") as? String ?? beforeYouBeginText
//                }
//                lblBeforeYouStart.stringValue = beforeYouBeginText
//                lblBeforeYouStart.isHidden = false
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
               
                
//                }else{
//                    if arrAllMorningHabits.count != 0 {
//                        let time = arrAllMorningHabits[0].durationSeconds!
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllMorningHabits[0].name!)
//                        btnStartFirstHabit.toolTip = btnStartFirstHabit.title
//                    }
//                }
                
                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
                
                
            }else if currentState == ._EVENING_HABIT_{
//                var beforeYouStartText = "Before you start, take a few moments to reflect on why you want to do these habits. Then visualise yourself beginning the habit sequence. Mentally walk through any of the habits that are going to be harder. This process will help reduce \"limbic friction\", i.e. prime your brain to do the habits no matter what, even if you don't have the app available."
//                if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
//                    beforeYouStartText = activityInfo.value(forKey: "beforeYouStartText") as? String ?? beforeYouStartText
//                }
//                lblBeforeYouStart.stringValue = beforeYouStartText
//                lblBeforeYouStart.isHidden = false
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
//                    if arrAllEveningHabits.count != 0 {
//                        let time = arrAllEveningHabits[0].durationSeconds!
//                        btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllEveningHabits[0].name!)
//                        btnStartFirstHabit.toolTip = btnStartFirstHabit.title
//                    }
//                }

                tblViewHabits.isHidden = false
                scrollViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
            }
        }
        
    }
    var timer:Timer?
    var currentTimer = 0
    var isTimerGoingOn = false
    var totalDuration = 0

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
        currentTimer += 1 // todo 1 kro
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
                    if arrAllMorningHabits.count != 0 {
                        let time = arrAllMorningHabits[0].durationSeconds!
                        self.btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllMorningHabits[0].name!)
                        self.btnStartFirstHabit.toolTip = self.btnStartFirstHabit.title
                    }
                }else if currentState == ._EVENING_HABIT_{
                    if arrAllEveningHabits.count != 0 {
                        let time = arrAllEveningHabits[0].durationSeconds!
                        self.btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllEveningHabits[0].name!)
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
            }else{

                mainViewControllerObj?.showVisualizeInstructionsVc()
                visualizeInstructionsVcObj?.startTimer()
                allApiObject.capturePosthog(event: "visualize-evening-routine", metadata: ["routine-type":"evening_routine"])
            }
        }
    }
}
extension firstViewController:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if currentState == ._MORNING_HABIT_{
            return  arrAllMorningHabits.count
        }else{
            return  arrAllEveningHabits.count
        }
    }
    
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellHabits"), owner: nil) as? tblCellHabits {
            if currentState == ._MORNING_HABIT_{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrAllMorningHabits[row].name ?? "")"
            }else{
                cell.lblTitle.stringValue  = "\(row + 1).   \(arrAllEveningHabits[row].name ?? "")"
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
    }
}
