//
//  customRoutineStateVc.swift
//  FocusBear
//
//  Created by Manish Jain on 16/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class customRoutineStateVc: NSViewController {

    @IBOutlet weak var btnStartCustomRoutine: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var customRoutinesMenu:NSMenu!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = ""// v 2.28.453
        btnStartCustomRoutine.title = "Begin On-Demand Routine"
        if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
            btnStartCustomRoutine.title = habitsStateVcInfo.value(forKey: "buttonBeginCustomRoutine") as? String ?? btnStartCustomRoutine.title
        }
    }
    
    override func viewWillAppear() {
        reloadData()
    }
    
    func reloadData(){
        addLog(text:"customRoutineStateVc:- reloadData")
        customRoutinesMenu = NSMenu()
        for i in 0..<arrAllCustomRoutine.count{
            let routine = arrAllCustomRoutine[i]
            if routine.triggerOnDemand{
                let menuItem = NSMenuItem(title: routine.title, action: #selector(menuItemStartRoutineClicked(sender:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.tag = i
                customRoutinesMenu.addItem(menuItem)
            }
        }
        
        if customRoutinesMenu.items.count == 0{
            btnStartCustomRoutine.isHidden = true
        }else{
            btnStartCustomRoutine.isHidden = false
        }
        
        if !isAppEnable{
            lblTitle.stringValue = "Distraction Blocking is currently paused. You can turn it back on anytime to stay focused."
            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                lblTitle.stringValue = habitsStateVcInfo.value(forKey: "titleAppDisabled") as? String ?? lblTitle.stringValue
            }
            return;
        }
        
        if !isShutOffTimeGoing(){
            let (nextRoutine, nextRoutineName, nextRoutineIsEveningRoutine) = getNextRoutineInfo()
            
            var timeFormat = "h:mm a"
            if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
                print(dict)
                if let isShow24Hour = dict["Show24Hour"] as? Bool {
                    if isShow24Hour{
                        timeFormat = "H:mm"
                    }
                }
            }
            let (dateString) = getStringFromDate(date: nextRoutine, dateFormat: timeFormat)

            var nextRoutineText = "Great job staying on track! Your next scheduled routine (<ROUTINE>) is set for <TIME>. Be ready to jump back in and continue building those healthy habits. You've got this!"
            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                nextRoutineText = habitsStateVcInfo.value(forKey: "nextRoutineText") as? String ?? nextRoutineText
            }
            nextRoutineText = nextRoutineText.replacingOccurrences(of: "<ROUTINE>", with: nextRoutineName)
            nextRoutineText = nextRoutineText.replacingOccurrences(of: "<TIME>", with: dateString)
            lblTitle.stringValue = nextRoutineText
        }else{
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                if Date().compare(date) == .orderedAscending {
                    lblTitle.stringValue = "Shutoff aborted. Your computer is now accessible again."
                    if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                        lblTitle.stringValue = habitsStateVcInfo.value(forKey: "shutoffAbortedText") as? String ?? lblTitle.stringValue
                    }
                }
            }
            
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                if Date().compare(date) == .orderedAscending {//"Evening habits already shown for today
                    if isShutOffTimeGoing() && !isCutOffTimeGoing(){
                        if let cutOffTime = cutOffTime{
                            let cutOffdate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                            
                            var timeFormat = "h:mm a"
                            if let dict = UserDefaults.standard.persistentDomain(forName: "com.apple.menuextra.clock") {
                                print(dict)
                                if let isShow24Hour = dict["Show24Hour"] as? Bool {
                                    if isShow24Hour{
                                        timeFormat = "H:mm"
                                    }
                                }
                            }
                            let cutOffDateString = getStringFromDate(date: cutOffdate, dateFormat: timeFormat)
                            var freeTimeText = "Well done! You've got free time until <CUTOFFTIME>"// v 2.28.453
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                freeTimeText = habitsStateVcInfo.value(forKey: "freeTimeText") as? String ?? freeTimeText
                            }
                            
                            lblTitle.stringValue = freeTimeText.replacingOccurrences(of: "<CUTOFFTIME>", with: cutOffDateString)
                        }else{//// v  2.28.453
                            var setSleepTime = "You do not have sleep time set."
                            if let habitsStateVcInfo = configjson.value(forKey: "habitsStateVcInfo") as? NSDictionary{
                                setSleepTime = habitsStateVcInfo.value(forKey: "setSleepTime") as? String ?? setSleepTime
                            }
                            
                            lblTitle.stringValue = setSleepTime
                        }
                        
                    }
                }
            }
        }
    }
    

    @IBAction func btnStartCustomRoutineClicked(_ sender: Any) {
        addLog(text:"[user-action] customRoutineStateVc:- btnStartCustomRoutineClicked")
        customRoutinesMenu.minimumWidth = btnStartCustomRoutine.frame.width
        let p = NSPoint(x: (sender as AnyObject).frame.origin.x, y: (sender as AnyObject).frame.origin.y )
        customRoutinesMenu.popUp(positioning: nil, at: p, in: (sender as AnyObject).superview)
    }
    
    @objc func menuItemStartRoutineClicked(sender:NSMenuItem){
        addLog(text:"[user-action] customRoutineStateVc:- menuItemStartRoutineClicked")
        if isPurchased == false && daysLeft <= 0{
            showUpgradeNowWindow()
            return;
        }
        startCustomRoutine(index: sender.tag, isOnDemand:true)
    }
}
