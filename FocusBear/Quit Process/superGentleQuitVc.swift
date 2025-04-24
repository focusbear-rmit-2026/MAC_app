//
//  superGentleQuitVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 19/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class superGentleQuitVc: NSViewController {

    @IBOutlet weak var loader: NSProgressIndicator!
    @IBOutlet weak var popUpBtn: NSPopUpButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnTurnOff: Button!
    
    let oneHourIndex = 3
    var buttonBreakOneHourText = "Turn it off for 1 hour"
    var buttonBreakFewHourText = "Turn it off for <HOUR> hours"
    var buttonBreakFewMinutesText = "Turn it off for <MINUTE> minutes"
    let fiveMinutesIndex = 0
    let fifteenMinutesIndex = 1
    let thirtyMinutesIndex = 2
    let twoHourIndex = 4
    let fourHourIndex = 5
    let twelveHourIndex = 6
    let twentyFourHourIndex = 7
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Choose how long to turn it off for"
        popUpBtn.removeAllItems()
        popUpBtn.addItems(withTitles: ["5 \(minutesText)", "15 \(minutesText)", "30 \(minutesText)", "1 \(hourText)", "2 \(hoursText)", "4 \(hoursText)", "12 \(hoursText)", "24 \(hoursText)"])
        
        if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
            if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                buttonBreakOneHourText =  askQuitVcInfo.value(forKey: "buttonBreakOneHourText") as? String ?? buttonBreakOneHourText
                buttonBreakFewHourText =  askQuitVcInfo.value(forKey: "buttonBreakFewHourText") as? String ?? buttonBreakFewHourText
                buttonBreakFewMinutesText =  askQuitVcInfo.value(forKey: "buttonBreakFewMinutesText") as? String ?? buttonBreakFewMinutesText
                lblTitle.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblTitle.stringValue
            }
        }
    }
    
    override func viewWillAppear() {
        popUpBtn.selectItem(at: 3)
    }
    
    @IBAction func popUpBtnClicked(_ sender: Any) {
        let index = popUpBtn.indexOfSelectedItem
        if index == oneHourIndex{
            btnTurnOff.title = buttonBreakOneHourText
        }else if index < oneHourIndex{
            var minutes = 30
            switch index {
            case fiveMinutesIndex:
                minutes = 5
            case fifteenMinutesIndex:
                minutes = 15
            case thirtyMinutesIndex:
                minutes = 30
            default:
                minutes = 30
            }
            btnTurnOff.title = buttonBreakFewMinutesText.replacingOccurrences(of: "<MINUTE>", with: "\(minutes)")
        }else{
            var hour  = 4
            switch index {
            case twoHourIndex:
                hour = 2
            case fourHourIndex:
                hour = 4
            case twelveHourIndex:
                hour = 12
            case twentyFourHourIndex:
                hour = 24
            default:
                hour = 4
            }
            
            btnTurnOff.title = buttonBreakFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
            
        }
    }
    
    @IBAction func btnTurnItOffClicked(_ sender: Any) {
        deavtivateApp()
    }
    
    func deavtivateApp(){
        let minutes = getMinutes()
        let date = Date().addingTimeInterval(TimeInterval(minutes * 60))//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
        UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Deactivated for \(minutes) minutes - I've got an emergency")
        allApiObject.capturePosthog(event: "turn-it-off-for-x-duration", metadata: [:])
        addEntryInStatsCsv(logType: "quit abort", activity: "quit", durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "", tags:"")
        loader.startAnimation(self)
        btnTurnOff.isEnabled = false
        DispatchQueue.global().async {//waiting for posthog
            sleep(1)
            DispatchQueue.main.async {
                self.loader.stopAnimation(self)
                mainViewControllerObj?.disableApp()
            }
        }
    }
    
    func getMinutes()-> Int{
        let index = popUpBtn.indexOfSelectedItem
        var minutes = 0
        
        if index == oneHourIndex{
            minutes = 60
        }else if index < oneHourIndex{
            switch index {
            case fiveMinutesIndex:
                minutes = 5
            case fifteenMinutesIndex:
                minutes = 15
            case thirtyMinutesIndex:
                minutes = 30
            default:
                minutes = 30
            }
        }else{
            switch index {
            case twoHourIndex:
                minutes = 120
            case fourHourIndex:
                minutes = 240
            case twelveHourIndex:
                minutes = 720
            case twentyFourHourIndex:
                minutes = 1440
            default:
                minutes = 4
            }
        }
        return minutes
    }
}
