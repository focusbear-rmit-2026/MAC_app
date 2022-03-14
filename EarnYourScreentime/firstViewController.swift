//
//  firstViewController.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa

class firstViewController: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
//    @IBOutlet weak var btnWidth: NSLayoutConstraint!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnStartFirstHabit: NSButton!
    @IBOutlet weak var tblViewHabits: NSTableView!
    var isFirstTime = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnStartFirstHabit.cell?.wraps = true
    }

    override func viewWillAppear() {
        if isFirstTime{
            imgView.image = NSImage(named: "icon 130")//
            lblSubTitle.isHidden = false
            tblViewHabits.isHidden = true
            let welcomeText = "Welcome to Earn Your Screen Time"
            
            if let dic = configjson.value(forKey: "welcomeInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "welcomeMessageHeading") as? String ?? welcomeText
                if let subTitle = dic.value(forKey: "welcomeMessageIntro") as? String{
                    lblSubTitle.stringValue = subTitle
                }
                if let arr = dic.value(forKey: "introActivities") as? [NSDictionary]{
                    let name = arr.first?.value(forKey: "name") as? String ?? ""
                    let durationSeconds = arr.first?.value(forKey: "durationSeconds") as? Int ?? 0
                    let videoUrl = arr.first?.value(forKey: "videoUrl") as? [String] ?? []
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: durationSeconds, name: name)
                    introActivity = habit(name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: false, logQuantityQuestion: nil)
                }else{
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
                    introActivity = habit(name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil)
                }
            }else{
                introActivity = habit(name: "mindful breathing", durationSeconds: 60, urlsArray: [], logQuantity: false, logQuantityQuestion: nil)
                lblTitle.stringValue = welcomeText
                btnStartFirstHabit.title = getstartActivityButtonText(seconds: 60, name: "mindful breathing")//"Start 1 minute of mindful breathing"
            }
        }else{
            
            if currentState == ._MORNING_HABIT_{
                imgView.image = NSImage(named: "Waking up _ SMall")//
                imgView.animates = true
                lblTitle.stringValue = startMorningHabitTitleText
                if arrAllMorningHabits.count != 0 {
                    let time = arrAllMorningHabits[0].durationSeconds!
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllMorningHabits[0].name!)
                    
                }
                tblViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
            }else{
                imgView.image = nil
                lblTitle.stringValue = startEveningHabitTitleText
                if arrAllEveningHabits.count != 0 {
                    let time = arrAllEveningHabits[0].durationSeconds!
                    btnStartFirstHabit.title = getstartActivityButtonText(seconds: time, name: arrAllEveningHabits[0].name!)
                    
                }
                tblViewHabits.isHidden = false
                tblViewHabits.reloadData()
                lblSubTitle.isHidden = true
            }
        }
        
    }
    @IBAction func btnStartFirstHabitClicked(_ sender: Any) {
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{//qki enter per ye button handle hai  or jha se handle h vha condition lganase accha yahi lagadi (enterv  password per bhi default enter key code h button per )
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
                mainViewControllerObj?.startFirstMorningHabit()
            }else{
                mainViewControllerObj?.startFirstEveningHabit()
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
