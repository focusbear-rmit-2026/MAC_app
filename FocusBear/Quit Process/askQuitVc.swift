//
//  askQuitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askQuitVc: NSViewController {

    @IBOutlet weak var popUpBtnHour: NSPopUpButton!
    @IBOutlet weak var lblSelectHours: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnAppQuit: Button!
    @IBOutlet weak var btnBreakFourHours: Button!
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    
    
    var buttonBreakOneHourText = "Turn it off for 1 hour"
    var buttonBreakFewHourText = "Turn it off for <HOUR> hours"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblSelectHours.stringValue = "Select hours to turn it off"
        
        lblTitle.stringValue = "Quitting.."
        lblSubTitle.stringValue = "Do you want to quit the app completely or just take a break for a few hours?"
        btnBreakFourHours.title = "Give me a break for 4hrs"
        btnAppQuit.title = "Turn it off completely - I'll turn it back on when I'm ready"
        
        
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let quittingTitle = quitInfo.value(forKey: "quittingTitle") as? String{
                lblTitle.stringValue = quittingTitle
            }
            if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                lblSubTitle.stringValue = askQuitVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
                btnBreakFourHours.title = askQuitVcInfo.value(forKey: "buttonDiableAppText") as? String ??  btnBreakFourHours.title
                btnAppQuit.title = askQuitVcInfo.value(forKey: "buttonQuitText") as? String ?? btnAppQuit.title
                lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                buttonBreakOneHourText =  askQuitVcInfo.value(forKey: "buttonBreakOneHourText") as? String ?? buttonBreakOneHourText
                buttonBreakFewHourText =  askQuitVcInfo.value(forKey: "buttonBreakFewHourText") as? String ?? buttonBreakFewHourText
            }
        }
        
        btnAppQuit.buttonColor = NSColor.white.cgColor
        popUpBtnHour.removeAllItems()
        popUpBtnHour.addItems(withTitles: ["1", "2", "3", "4", "5"])
        popUpBtnHour.selectItem(at: 3)
        popUpBtnHourClicked(self)
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgView.image = nil
        }else{
            imgView.image = NSImage(named: "Crying_small")
            imgView.animates = true
        }
    }
    @IBAction func popUpBtnHourClicked(_ sender: Any) {
        let index = popUpBtnHour.indexOfSelectedItem
        let hour  = index + 1
        
        if hour == 1{
            btnBreakFourHours.title = buttonBreakOneHourText
        }else{
            btnBreakFourHours.title = buttonBreakFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
        }
    }
    @IBAction func btnBreakFourHoursClicked(_ sender: Any) {
        let index = popUpBtnHour.indexOfSelectedItem
        let hour  = index + 1
        
        let date = Date().addingTimeInterval(TimeInterval(hour * 60 * 60))//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Deactivated for 4 hours - I've got an emergency")

        addEntryInStatsCsv(logType: "quit abort", activity: "quit", durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "")
        mainViewControllerObj?.disableApp()
        
    }
    @IBAction func btnAppQuitClicked(_ sender: Any) {
        getQuittingWindowObject().contentViewController = getQuittingCountDownVcObject()
        getQuittingCountDownVcObject().resetData()
    }
}
