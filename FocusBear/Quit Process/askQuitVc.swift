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
    
    @IBOutlet weak var btnSkip: underLineButton!
    
    var buttonBreakOneHourText = "Turn it off for 1 hour"
    var buttonBreakFewHourText = "Turn it off for <HOUR> hours"
    var buttonBreakFewMinutesText = "Turn it off for <MINUTE> minutes"
    
    
    var buttonPostponeOneHourText = "Postpone habits for 1 hour"
    var buttonPostponeFewHourText = "Postpone habits for <HOUR> hours"
    var buttonPostponeFewMinutesText = "Postpone habits for <MINUTE> minutes"
    
    
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
                buttonBreakFewMinutesText =  askQuitVcInfo.value(forKey: "buttonBreakFewMinutesText") as? String ?? buttonBreakFewMinutesText
                
                buttonPostponeOneHourText =  askQuitVcInfo.value(forKey: "buttonPostponeOneHourText") as? String ?? buttonPostponeOneHourText
                buttonPostponeFewHourText =  askQuitVcInfo.value(forKey: "buttonPostponeFewHourText") as? String ?? buttonPostponeFewHourText
                buttonPostponeFewMinutesText =  askQuitVcInfo.value(forKey: "buttonPostponeFewMinutesText") as? String ?? buttonPostponeFewMinutesText
                
            }
        }
        
        btnAppQuit.buttonColor = NSColor.white.cgColor
        popUpBtnHour.removeAllItems()
        popUpBtnHour.addItems(withTitles: ["5 \(minutesText)", "15 \(minutesText)", "30 \(minutesText)", "1 \(hourText)", "2 \(hoursText)", "4 \(hoursText)", "12 \(hoursText)", "24 \(hoursText)"])
        
    }
    
    var isPostponeInfoShowing = false
    //if easy postpone is going to show then close quit window and if easy postpone window is allready visible and if user click on quit then dont show about postpone in quit
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            imgView.image = nil
        }else{
            imgView.image = NSImage(named: "Crying_small")
            imgView.animates = true
        }
        var isEasyPostponeWindowVisible = false
        
        if easyPostponeWcObj != nil{
            if easyPostponeWcObj?.window?.isVisible ?? false{
                isEasyPostponeWindowVisible = true
            }
        }
        
        if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && !isEasyPostponeWindowVisible{
            popUpBtnHour.selectItem(at: 0)
            var habitName = ""
            
            if currentHabitPlaying != nil{
                habitName = currentHabitPlaying?.name ?? ""
            }
            var subTitlePostpone = "You're in the middle of your <ROUTINE> routine. Do you want to skip/postpone <HABITNAME> or turn the app off completely?"
            var routineMorningText = "morning"
            var routineEveningText = "evening"
            lblSelectHours.stringValue =  "Postpone it for"
            var skipHabitText = "Skip <HABITNAME>"
            
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                    subTitlePostpone = askQuitVcInfo.value(forKey: "subTitlePostpone") as? String ?? subTitlePostpone
                    lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                    routineMorningText = askQuitVcInfo.value(forKey: "routineMorningText") as? String ?? routineMorningText
                    routineEveningText = askQuitVcInfo.value(forKey: "routineEveningText") as? String ?? routineEveningText
                    skipHabitText = askQuitVcInfo.value(forKey: "buttonSkipText") as? String ?? skipHabitText
                    lblSelectHours.stringValue = askQuitVcInfo.value(forKey: "selectPostponeHoursText") as? String ?? lblSelectHours.stringValue
                }
            }
            
            
            var routineType = ""
            if currentState == ._MORNING_HABIT_{
                routineType = routineMorningText
            }else if currentState == ._EVENING_HABIT_{
                routineType = routineEveningText
            }
            subTitlePostpone = subTitlePostpone.replacingOccurrences(of: "<ROUTINE>", with: routineType)
            subTitlePostpone = subTitlePostpone.replacingOccurrences(of: "<HABITNAME>", with: habitName)
            
            lblSubTitle.stringValue = subTitlePostpone
            btnSkip.isHidden = false
            
            btnSkip.title = skipHabitText.replacingOccurrences(of: "<HABITNAME>", with: habitName)
            isPostponeInfoShowing = true
        }else{
            btnSkip.isHidden = true
            popUpBtnHour.selectItem(at: 3)
            lblSubTitle.stringValue = "Do you want to quit the app completely or just take a break for a few hours?"
            if let quitInfo = configjson.value(forKey: "quitInfo") as? NSDictionary{
                if let askQuitVcInfo = quitInfo.value(forKey: "askQuitVcInfo") as? NSDictionary{
                    lblSubTitle.stringValue = askQuitVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
                    lblSelectHours.stringValue =  askQuitVcInfo.value(forKey: "selectHoursText") as? String ?? lblSelectHours.stringValue
                }
            }
            isPostponeInfoShowing = false
        }
        popUpBtnHourClicked(self)
    }
    
    @IBAction func popUpBtnHourClicked(_ sender: Any) {
        let index = popUpBtnHour.indexOfSelectedItem
        if index == 3{
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeOneHourText
            }else{
                btnBreakFourHours.title = buttonBreakOneHourText
            }
        }else if index < 3{
            var minutes = 30
            switch index {
            case 0:
                minutes = 5
            case 1:
                minutes = 15
            case 2:
                minutes = 30
            default:
                minutes = 30
            }
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeFewMinutesText.replacingOccurrences(of: "<MINUTE>", with: "\(minutes)")
            }else{
                btnBreakFourHours.title = buttonBreakFewMinutesText.replacingOccurrences(of: "<MINUTE>", with: "\(minutes)")
            }
        }else{
            var hour  = 4
            switch index {
            case 4:
                hour = 2
            case 5:
                hour = 4
            case 6:
                hour = 12
            case 7:
                hour = 24
            default:
                hour = 4
            }
            
            if isPostponeInfoShowing{
                btnBreakFourHours.title = buttonPostponeFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
            }else{
                btnBreakFourHours.title = buttonBreakFewHourText.replacingOccurrences(of: "<HOUR>", with: "\(hour)")
            }
            
        }
    }
    @IBAction func btnBreakFourHoursClicked(_ sender: Any) {
        let index = popUpBtnHour.indexOfSelectedItem
        var minutes = 0
        
        if index == 3{
            minutes = 60
        }else if index < 3{
            switch index {
            case 0:
                minutes = 5
            case 1:
                minutes = 15
            case 2:
                minutes = 30
            default:
                minutes = 30
            }
        }else{
            switch index {
            case 4:
                minutes = 120
            case 5:
                minutes = 240
            case 6:
                minutes = 720
            case 7:
                minutes = 1440
            default:
                minutes = 4
            }
        }
        
        
        if  isPostponeInfoShowing{
            
            mainViewControllerObj?.stopActivityCountDownTimer()
            
            setDocBarTo(isHide: false)
            if currentHabitPlaying != nil{
                if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                    if smallCountDownWcObj?.window != nil{
                        if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                            getSmallCountDownWindowObject().window?.close()
                        }
                    }
                }
            }
            mainViewControllerObj?.stopActivityTimer()
            if currentHabitPlaying != nil{
                closePupUpBlockIfVisible()
            }
            if currentState == ._MORNING_HABIT_{
                mainViewControllerObj?.postponeMorningHabitFor(minutes: minutes, secondsToPostpone: nil)
            }else if currentState == ._EVENING_HABIT_{
                mainViewControllerObj?.postponeEveningHabitFor(minutes: minutes, secondsToPostpone: nil)
            }
            self.view.window?.close()
        }else{
            let date = Date().addingTimeInterval(TimeInterval(minutes * 60))//Calendar.current.date(bySetting: .hour, value: 4, of: Date())
            UserDefaults.standard.set(date, forKey: kUserdefaults4HourReActivateTime)
            addLog(text: "App Deactivated for \(minutes) minutes - I've got an emergency")

            addEntryInStatsCsv(logType: "quit abort", activity: "quit", durationInSeconds: "", quantityQuestion: "", quantityLogged: "", startTime: "", workAchieved: "", distractionsEncountered: "", abortReason: "I've got an emergency", feedback: "")
            mainViewControllerObj?.disableApp()
        }
        
        
    }
    
    @IBAction func btnSkipClicked(_ sender: Any) {
        mainWindowControllerObj?.window?.setIsVisible(true)
        showBlankWindowInSecondaryMonitor()
        setDocBarTo(isHide: false)
        timerViewcontrollerObj?.btnPauseClicked(self)
        
        if currentHabitPlaying != nil{
            if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                if smallCountDownWcObj?.window != nil{
                    if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                        getSmallCountDownWindowObject().window?.close()
                        if getsmallCountDownVcObject().timer != nil {
                            getsmallCountDownVcObject().timer?.invalidate()
                        }
                    }
                }
            }
        }
        currentHabitPlaying = nil
        currentActivityPlaying = nil
        if rememberNextHabitVcObj != nil{
            if thirdVcObj!.view.subviews.contains(rememberNextHabitVcObj!.view){
                rememberNextHabitVcObj!.view.removeFromSuperview()
                thirdVcObj?.boxBg.isHidden = false
            }
        }
        mainViewControllerObj?.showThirdVc()
        if currentState == ._ACTIVITY_{

        }else if currentState == ._MORNING_HABIT_{
            thirdVcObj?.morningHabitSkipped()
        }else if currentState == ._EVENING_HABIT_{
            thirdVcObj?.eveningHabitSkipped()
        }
        self.view.window?.close()
    }
    
    @IBAction func btnAppQuitClicked(_ sender: Any) {
        getQuittingWindowObject().contentViewController = getQuittingCountDownVcObject()
        getQuittingCountDownVcObject().resetData()
    }
}
