//
//  askQuitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/11/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class askQuitVc: NSViewController {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var btnAppQuit: Button!
    @IBOutlet weak var btnBreakFourHours: Button!
    
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
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
            }
        }
        btnAppQuit.buttonColor = NSColor.white.cgColor
        
    }
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgView.image = nil
        }else{
            imgView.image = NSImage(named: "Crying_small")
            imgView.animates = true
        }
    }
    @IBAction func btnBreakFourHoursClicked(_ sender: Any) {
        let date = Date().addingTimeInterval(4 * 60 * 60)//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Deactivated for 4 hours - I've got an emergency")

        addEntryInCsv(logType: "quit abort", activity: "quit", durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "")
        mainViewControllerObj?.disableApp()
        
    }
    @IBAction func btnAppQuitClicked(_ sender: Any) {
        getQuittingWindowObject().contentViewController = getQuittingCountDownVcObject()
        getQuittingCountDownVcObject().resetData()
    }
}
