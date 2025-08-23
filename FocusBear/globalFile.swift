//
//  globalFile.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//

import Cocoa
//import IOKit
import IOKit.pwr_mgt
import SystemConfiguration// for check internet availibility code
import WebKit


let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)


func getBlockedUrlsToBlock()->[String]{
    var arrBlockedUrls = [String]()
    var blockedUrlsCount = SettingsManagerObject.arrBlockedUrls.count
    if isExpired{
        if blockedUrlsCount > alwaysBlockedUrlsCountInExpireApp{
            blockedUrlsCount = alwaysBlockedUrlsCountInExpireApp
        }
    }
    for i in 0..<blockedUrlsCount{
        let url = SettingsManagerObject.arrBlockedUrls[i]
        arrBlockedUrls.append(url)
    }
     return arrBlockedUrls
}

func getBlockedAppsToBlock()->[String]{
    var arrBlockedApps = [String]()
    var blockedAppsCount = SettingsManagerObject.arrBlockedApps.count
    if isExpired{
        if blockedAppsCount > alwaysBlockedUrlsCountInExpireApp{
            blockedAppsCount = alwaysBlockedUrlsCountInExpireApp
        }
    }
    for i in 0..<blockedAppsCount{
        let app = SettingsManagerObject.arrBlockedApps[i]
        arrBlockedApps.append(app)
    }
     return arrBlockedApps
}


let appdelegate = NSApplication.shared.delegate as? AppDelegate
var SettingsManagerObject = SettingsManager()
var isTestUser = false

var tryBlockingVcShownInOnboarding = false

var isExpired:Bool = false
let alwaysBlockedUrlsCountInExpireApp = 3
let activitiesCountInExpireApp = 3
var isActivitiesReducedInExpiredApp = false

var isHardCorePomodoroModeOn = false
var hardcodePmodoroFocusModeName:String = ""
var totalMinutesRemainingForHardcodePomodoro = 0
var currentPomodoroWorkDuration = 25
var currentPomodoroBreakDuration = 5
var totalPomodoroCountInHardCorePomodoro = 0
var completedPomodoroCountInHardcorePomodoro = 0
var isFocusBreakOn = false

var isEmailVerified = false



var configjson = NSDictionary()


var currentDeviceId = ""
var currentUserName = ""
var currentUserEmail = ""


//var shouldShowOnboardingBlockedUrlsView = true
var isAppInitialLodded = false// activation kha se show hua h menu se ya startup per iske liye iska use krenge


var areSettingsEdited = false
var isAppEnable = true// should be true here dont change
var startTimeString = ""
var shutOffTimeString = ""
var cutOffTimeString = ""

var startTime:Time?
var shutOffTime:Time?
var cutOffTime:Time?
var has_edited_settings = false

var isMainWindowLoaded = false


var isFirstRun = false


struct Time{
    var hour = 0
    var minute = 0
    var second = 0
}
extension NSScrollView{
    func scrollToLast(){
        if let documentView = documentView {
            let newOrigin = NSPoint(x: 0, y: 0)
            documentView.scroll(newOrigin)
        }
    }
}
    
    
extension NSView{
    func addConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let height = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
        self.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
        self.addConstraint(height)
    }
    func addTopRightConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        
        let top = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(top)
    }
    
    func addVerticalCenterConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
      //  let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let center = NSLayoutConstraint(item: subView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(center)
        self.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
     //   self.addConstraint(height)
    }
    
    func addBottomRightConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
    }
    
    func addBottomLeftConstraints(subView:NSView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        self.addConstraint(leading)
        self.addConstraint(bottom)
    }
    
    func addConstraints(subView:NSView, leading:CGFloat, trailing:CGFloat, bottom:CGFloat, top:CGFloat) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        let trailing = NSLayoutConstraint(item: subView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: trailing)
        let leading = NSLayoutConstraint(item: subView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: leading)
        let bottom = NSLayoutConstraint(item: subView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: bottom)
        let top = NSLayoutConstraint(item: subView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: top)
        self.addConstraint(trailing)
        self.addConstraint(bottom)
        self.addConstraint(leading)
        self.addConstraint(top)
    }
    
}
//var isBreathingGoing = false
//var isHabitGoing = false
//var isBreakActivitiesGoing = false


var occupationStudentIndex = 0
var occupationBusinessOwnerIndex = 1
var occupationEmployeeIndex = 2
var occupationFreelancerIndex = 3
var occupationOtherIndex = 4
var occupationProgrammerIndex = 5
var occupationGraphicDesignerIndex = 6
var occupationOtherOfficeWorkIndex  = 7
var occupationFieldWorkIndex = 8



var preferencesEditHabitsIndex = 3
let preferencesFocusModesIndex = 1
var preferencesSettingsIndex = 2
var preferencesBlocksIndex = 1

var arrFocusAlignmentScore = ["30", "40", "50", "60", "70", "80", "90", "95", "99"]




func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}
func getStringTimeFromSeconds(seconds : Int)->String{
    let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)" + hoursHText
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)" + minutesMText
        }else{
            stringTime += " \(m)" + minutesMText
        }
    }
    if s != 0{
        if stringTime.isEmpty{
            stringTime = "\(s)" + secondsSText
        }else{
            stringTime += " \(s)" + secondsSText
        }
    }
    return stringTime
}
func getStringTimeFromSecondsWithoutSeconds(seconds : Int)->String{// olny h and m
    let (h,m,_) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)" + hoursHText
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)" + minutesMText
        }else{
            stringTime += " \(m)" + minutesMText
        }
    }
    if stringTime.isEmpty{
        stringTime += "\(m)" + minutesMText
    }
    return stringTime
}



let avmonitor = AVMonitor()

func getTimeFromString(val:String)->Time{
    let timearr = val.components(separatedBy: ":")
    var hour = 0
    var minute = 0
    var second = 0
    if timearr.count == 3{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
        second = Int(timearr[2]) ?? 0
    }else if timearr.count == 2{
        hour = Int(timearr[0]) ?? 0
        minute = Int(timearr[1]) ?? 0
    }else if timearr.count == 1{
        hour = Int(timearr[0]) ?? 0
    }
    return Time(hour: hour, minute: minute, second: second)
}

extension Date {
    
    func fullDistance(from date: Date, resultIn component: Calendar.Component, calendar: Calendar = .current) -> Int? {
        calendar.dateComponents([component], from: self, to: date).value(for: component)
    }
    
    func distance(from date: Date, only component: Calendar.Component, calendar: Calendar = .current) -> Int {
        let days1 = calendar.component(component, from: self)
        let days2 = calendar.component(component, from: date)
        return days1 - days2
    }
    
    func hasSame(_ component: Calendar.Component, as date: Date) -> Bool {
        distance(from: date, only: component) == 0
    }

    static func from(year: Int, month: Int, day: Int, hour:Int, minute:Int, second:Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = year
        dateComponents.minute = month
        dateComponents.second = day
        return calendar.date(from: dateComponents) ?? nil
    }
    
    func dayOfWeek() -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: self).uppercased()
        // or use capitalized(with: locale) if you want
    }
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        
        let currentCalendar = Calendar.current
        
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        
        return end - start
    }
}

class CustomTextField: NSTextField, NSTextViewDelegate {
    override func rightMouseDown(with event: NSEvent) {
        
    }
    func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        return nil
    }
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {

        NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
        return false
    }
}
class ignoreMouseTextField: NSTextField, NSTextViewDelegate {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

class PasteView: NSTextView, NSTextViewDelegate {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func paste(_ sender: Any?) {
        Swift.print("user tries to paste")
        // super.pasteAsPlainText(nil)
    }
}
class CustomWindow: NSWindow {//bacause titleless window per textfield kaam ni kar rhi
    override var canBecomeKey: Bool{
        return true
    }
}

func attechIconWithString(text:String)->NSMutableAttributedString{
    if text.localizedCaseInsensitiveContains("<icon>"){
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let arr = text.components(separatedBy: "<icon>")
        let mainstr =  NSMutableAttributedString()
        for i in 0..<arr.count{
            let string = arr[i]
            if !string.isEmpty{
                let str = NSMutableAttributedString(string: string, attributes: attrs)
                if i != arr.count - 1{
                    let attachmentCell: NSTextAttachmentCell = NSTextAttachmentCell.init(imageCell: NSImage(named: NSImage.Name("Bear-Small")))
                    let attachment: NSTextAttachment = NSTextAttachment()
                    attachment.attachmentCell = attachmentCell
                    let attrString: NSAttributedString = NSAttributedString(attachment: attachment)
                    str.append(attrString)
                }
                mainstr.append(str)
            }
        }
        return mainstr
    }else{
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.labelColor, NSAttributedString.Key.paragraphStyle: paragraph]
        let str = NSMutableAttributedString(string: text, attributes: attrs)
        return str
    }
    
}


enum ACTION:Int{
    case _START_ = 11, _INPROGRESS_, _END_, _VISUALIZE_, _BRAIN_DUMP_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}

var applastSettingsGetTime:Date?

enum CURRENTSTATE:Int{
    case _NOTHING_ = 111, _MORNING_HABIT_, _EVENING_HABIT_, _MICRO_BREAK_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FOCUS_SUMMARY_, _POSTPON_MORNING_HABIT_, _POSTPON_EVENING_HABIT_, _POSTPON_FOCUS_SUMMARY_, _POSTPON_ONBOARDING_HABIT_, _ASK_APP_WORK_, _SPECIAL_ACTIVITY_, _CUSTOM_ROUTINE_//_POSTPON_BREAK_ACTIVITY_
}//_POSTPON_BREAK_ACTIVITY_ iski need nahi h qki normal timer utne hi time baad ka laga dete hai

var lastCurrentStateSaved:CURRENTSTATE = ._NOTHING_

var currentState:CURRENTSTATE = ._NOTHING_{
    didSet{
        if currentState == ._NOTHING_ && lastCurrentStateSaved == ._CUSTOM_ROUTINE_{// if currest state was custom routine and custom routine was started during postpone morning/evening routine state then after complete or abort custom routine set postpone state again
            if isCustomRoutineWasRunningInPostponeEveningHabit && !isCustomRoutineWasRunningBetweenEveningHabit{
                currentState = ._POSTPON_EVENING_HABIT_
            }
            
            if isCustomRoutineWasRunningInPostponeMorningHabit && !isCustomRoutineWasRunningBetweenMorningHabit{
                currentState = ._POSTPON_MORNING_HABIT_
            }
        }
        if currentState != ._CUSTOM_ROUTINE_{
            isCustomRoutineWasRunningInPostponeMorningHabit = false
            isCustomRoutineWasRunningInPostponeEveningHabit = false
        }
        lastCurrentStateSaved = currentState
        
        if currentState == ._MORNING_HABIT_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._EVENING_HABIT_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._FOCUS_SUMMARY_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }else if currentState == ._SHUTOFFMAC_{
            if oldValue != currentState{
                leftMenuVcObj?.habitStarted()
            }
        }
//        else if currentState == ._CUSTOM_ROUTINE_{
//            if oldValue != currentState{
//                leftMenuVcObj?.customRoutineStarted()
//            }
//        }
    }
}


var currentAction:ACTION = ACTION._START_

var lastCurrentState:CURRENTSTATE = ._NOTHING_//abort  cancel ho to to pta krne k liye 
var lastCurrentAction:ACTION = ACTION._START_



func playEveryActivitySound(){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            NSSound(named: sound)?.play()
        }
        addLog(text: "Play Every Activity Sound")
    }
    
}

func playAfterMorningEveningRoutineSound(isMorning:Bool){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if isMorning{
            if let sound = arrCompletingWholeMorningRoutineSound.randomElement(){
                addLog(text: "Sound name: \(sound)")
                NSSound(named: sound)?.play()
            }
            addLog(text: "Play Morning Routine End Sound")
        }else{
            if let sound = arrCompletingWholeEveningRoutineSound.randomElement(){
                addLog(text: "Sound name: \(sound)")
                NSSound(named: sound)?.play()
            }
            addLog(text: "Play Evening Routine End Sound")
        }
    }
}

func playFocusModeStartedSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartFocusSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            NSSound(named: sound)?.play()
        }
        addLog(text: "Play Focus Mode Started Sound")
    }
}
func playStartMorningEveningRoutineSound(){
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartingMorningEveningRoutineSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            NSSound(named: sound)?.play()
        }
        addLog(text: "Play Start Morning Evening Routine Sound")
    }
}
func playFocusPomodorBreakEndsSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            addLog(text: "Sound name: \(sound)")
            NSSound(named: sound)?.play()
        }
        addLog(text: "Play Focus Pomodor Break Ends Sound")
    }
}


var arrStartingMorningEveningRoutineSound = ["Starting the Morning:Evening Routine_2",
                                             "Starting the Morning:Evening Routine_4",
                                             "Starting the Morning:Evening Routine_5"]

var arrStartFocusSound = ["Start Focus Button_1",
                          "Start Focus Button_2"]


var arrCompletingWholeMorningRoutineSound = ["Completing the Whole Morning Routine_2.2",
                                             "Completing the Whole Morning Routine_3.1"]

var arrCompletingWholeEveningRoutineSound = ["Completing the Whole Evening Routine_4",
                                             "Completing the Whole Evening Routine_5",
                                             "Completing the Whole Evening Routine_7"]

var arrCompletingHabitSound = ["Completing a Habit_4", "grunz__success-low"]


var activitySkippedWhatNextSoundText = "<ACTIVITY> skipped. Guess Whats next?"
var activityFinishedWhatNextSoundText = "<ACTIVITY> finished. Guess Whats next?"
var activitySkippedNextActivitySoundText = "<ACTIVITY> skipped. Next up is <NEXTACTIVITY>."
var activityFinishedNextActivitySoundText = "<ACTIVITY> finished. Next up is <NEXTACTIVITY>."
var activitySkippedUnlockNowSoundText = "<ACTIVITY> skipped. You’ve earned your screen time."
var activityFinishedUnlockNowSoundText = "<ACTIVITY> finished. You’ve earned your screen time."


var startNonTimerActivityButtonText = "Start <NAME>"

var startActivityButtonText = "Start <TIME> <NAME>"
var unlockMachineButtonText = "Unlock the machine"
var activityFinishedText = "<ACTIVITY> finished!✅"
var lastActivityFinishedText = "<ACTIVITY> finished!✅ You’ve earned your screen time. 💪"
var activitySkippedText = "<ACTIVITY> skipped!"
var lastActivitySkippedText = "<ACTIVITY> skipped! You’ve earned your screen time. 💪"
var startBreakActivityTitleText = "It’s time for a break. Do <TIME> of <ACTIVITY> to earn more screentime."
var startNonTimerBreakActivityTitleText = "It’s time for a micro break. Let’s do <ACTIVITY> to keep your mind and body sharp."
var doSomeActivityText = "Do some <ACTIVITY>."
var startMorningHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."
var startEveningHabitTitleText = "Good Evening! It’s time to Focus Bear. Here are the habits you need to accomplish before you can leave for the day."
var startCustomRoutineHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."

var emailID = "team@focusbear.io"
var appName = "Focus Bear"
var buttonCancelText = "Cancel"
var buttonOkText = "OK"
var buttonStatusStateFocusText = "FOCUS"
var buttonStatusStateOffText = "OFF"
var buttonStatusStateCallText = "MEETING"
var buttonYesText = "Yes"
var buttonNoText = "No"
var buttonContinueText = "Continue"

var secondsText = "seconds"
var minuteText = "minute"
var minutesText = "minutes"
var hourText = "hour"
var hoursText = "hours"

var graphQuantityText = "Quantity"
var graphMinutesText = "Minutes"
var graphDateText = "Date"
var graphTimeText = "Time"

var hoursHText = "h"
var minutesMText = "m"
var secondsSText = "s"

var windDownText = "Time to wind down"

var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"

//var upgradeNowUrl = "https://dashboard.focusbear.io/manage-subscription"//https://dashboard.focusbear.io/profile"
var buttonMoreActionsText = "More Actions"
var appAllowedInFocusModeText = "\"<APP>\" is allowed in \"<FOCUSMODE>\" focus mode."
var appNotAllowedInFocusModeText = "\"<APP>\" is not allowed in \"<FOCUSMODE>\" focus mode."

func readConfigFile(){
    addLog(text: "read Config File")
    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
        startActivityButtonText = activityInfo.value(forKey: "startActivityButtonText") as? String ?? startActivityButtonText
        startNonTimerActivityButtonText = activityInfo.value(forKey: "startNonTimerActivityButtonText") as? String ?? startNonTimerActivityButtonText
        activityFinishedText = activityInfo.value(forKey: "activityFinishedText") as? String ?? activityFinishedText
        lastActivityFinishedText = activityInfo.value(forKey: "lastActivityFinishedText") as? String ?? lastActivityFinishedText
        startBreakActivityTitleText = activityInfo.value(forKey: "startBreakActivityTitleText") as? String ?? startBreakActivityTitleText
        startNonTimerBreakActivityTitleText = activityInfo.value(forKey: "startNonTimerBreakActivityTitleText") as? String ?? startNonTimerBreakActivityTitleText
        doSomeActivityText = activityInfo.value(forKey: "doSomeActivityText") as? String ?? doSomeActivityText
        startMorningHabitTitleText = activityInfo.value(forKey: "startMorningHabitTitleText") as? String ?? startMorningHabitTitleText
        startEveningHabitTitleText = activityInfo.value(forKey: "startEveningHabitTitleText") as? String ?? startEveningHabitTitleText
        activitySkippedText = activityInfo.value(forKey: "activitySkippedText") as? String ?? activitySkippedText
        lastActivitySkippedText = activityInfo.value(forKey: "lastActivitySkippedText") as? String ?? lastActivitySkippedText
        
        activitySkippedWhatNextSoundText = activityInfo.value(forKey: "activitySkippedWhatNextSoundText") as? String ?? activitySkippedWhatNextSoundText
        activityFinishedWhatNextSoundText = activityInfo.value(forKey: "activityFinishedWhatNextSoundText") as? String ?? activityFinishedWhatNextSoundText
        activitySkippedNextActivitySoundText = activityInfo.value(forKey: "activitySkippedNextActivitySoundText") as? String ?? activitySkippedNextActivitySoundText
        activityFinishedNextActivitySoundText = activityInfo.value(forKey: "activityFinishedNextActivitySoundText") as? String ?? activityFinishedNextActivitySoundText
        activitySkippedUnlockNowSoundText = activityInfo.value(forKey: "activitySkippedUnlockNowSoundText") as? String ?? activitySkippedUnlockNowSoundText
        activityFinishedUnlockNowSoundText = activityInfo.value(forKey: "activityFinishedUnlockNowSoundText") as? String ?? activityFinishedUnlockNowSoundText
        buttonMoreActionsText = activityInfo.value(forKey: "buttonMoreActionsText") as? String ?? buttonMoreActionsText
    }
    
    
    if let languageInfo = configjson.value(forKey: "languageInfo") as? NSDictionary{
        arrLanguageDic[0]["name"] = languageInfo.value(forKey: "languageEnglish") as? String ?? arrLanguageDic[0]["name"]
        arrLanguageDic[1]["name"] = languageInfo.value(forKey: "languageSpanish") as? String ?? arrLanguageDic[1]["name"]
    }
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        emailID = common.value(forKey: "emailId") as? String ?? emailID
        appName = common.value(forKey: "appName") as? String ?? appName
        buttonCancelText = common.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        buttonOkText = common.value(forKey: "buttonOkText") as? String ?? buttonOkText
        buttonYesText = common.value(forKey: "yesText") as? String ?? buttonYesText
        buttonContinueText = common.value(forKey: "buttonContinueText") as? String ?? buttonContinueText
        buttonNoText = common.value(forKey: "noText") as? String ?? buttonNoText
        unlockMachineButtonText = common.value(forKey: "unlockMachineButtonText") as? String ?? unlockMachineButtonText
        webhookUrl = common.value(forKey: "webhookUrl") as? String ?? webhookUrl
        buttonStatusStateFocusText = common.value(forKey: "buttonStatusStateFocusText") as? String ?? buttonStatusStateFocusText
        buttonStatusStateOffText = common.value(forKey: "buttonStatusStateOffText") as? String ?? buttonStatusStateOffText
        buttonStatusStateCallText = common.value(forKey: "buttonStatusStateCallText") as? String ?? buttonStatusStateCallText
        
        secondsText = common.value(forKey: "secondsText") as? String ?? secondsText
        minuteText = common.value(forKey: "minuteText") as? String ?? minuteText
        minutesText = common.value(forKey: "minutesText") as? String ?? minutesText
        hourText = common.value(forKey: "hourText") as? String ?? hourText
        hoursText = common.value(forKey: "hoursText") as? String ?? hoursText
        
        graphQuantityText = common.value(forKey: "graphQuantityText") as? String ?? graphQuantityText
        graphMinutesText = common.value(forKey: "graphMinutesText") as? String ?? graphMinutesText
        graphDateText = common.value(forKey: "graphDateText") as? String ?? graphDateText
        graphTimeText = common.value(forKey: "graphTimeText") as? String ?? graphTimeText
        
        hoursHText = common.value(forKey: "hoursHText") as? String ?? hoursHText
        minutesMText = common.value(forKey: "minutesMText") as? String ?? minutesMText
        secondsSText = common.value(forKey: "secondsSText") as? String ?? secondsSText
       
        appAllowedInFocusModeText = common.value(forKey: "appAllowedInFocusModeText") as? String ?? appAllowedInFocusModeText
        appNotAllowedInFocusModeText = common.value(forKey: "appNotAllowedInFocusModeText") as? String ?? appNotAllowedInFocusModeText
    }
    
    if let shutOffTimeInfo = configjson.value(forKey: "shutOffTimeInfo") as? NSDictionary{
        if let title = shutOffTimeInfo.value(forKey: "title") as? String{
            windDownText = title
        }
    }
    
//    upgradeNowUrl = configjson.value(forKey: "upgradeNowUrl") as? String ?? upgradeNowUrl
    
}
func getDoSomeActivityText(activityName:String)->String{
    return doSomeActivityText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
}

func getStartBreakActivityTitleText(seconds:Int, activityName:String)->String{
    var title = ""
    if seconds == 86400{
        title = startNonTimerBreakActivityTitleText
        title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }else{
        let stringTime = getStringTime(seconds: seconds)
        title = startBreakActivityTitleText.replacingOccurrences(of: "<TIME>", with: stringTime)
        title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }
    return title
    
}
func getActivityFinishedText(isLast:Bool, activityName:String)->String{
    if currentState == ._EVENING_HABIT_ && isLast{
        return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName) + " " + windDownText
    }else{
        if isLast{
            return lastActivityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }else{
            return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }
    }
}
func getActivitySkippedText(isLast:Bool, activityName:String)->String{
    if currentState == ._EVENING_HABIT_ && isLast{
        return activitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName) + " " + windDownText
    }else{
        if isLast{
            return lastActivitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }else{
            return activitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
        }
    }
}

func playActivityFinishedSound(lastActivity:String, nextActivity:String, isSkipped:Bool, isAskNext:Bool){
    if !SettingsManagerObject.isAnnouncementEnabled{
        return;
    }
    if appdelegate!.isUserOnMeeting{//Don't play sound effects during mid-meeting breaks#662
        return;
    }
    var text = ""
    if isAskNext{
        if isSkipped{
            text = activitySkippedWhatNextSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
        }else{
            text = activityFinishedWhatNextSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
        }
    }else{
        if isSkipped{
            if !nextActivity.isEmpty{
                text = activitySkippedNextActivitySoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
                text = text.replacingOccurrences(of: "<NEXTACTIVITY>", with: nextActivity)
            }else{
                text = activitySkippedUnlockNowSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
            }
        }else{
            if !nextActivity.isEmpty{
                text = activityFinishedNextActivitySoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
                text = text.replacingOccurrences(of: "<NEXTACTIVITY>", with: nextActivity)
            }else{
                text = activityFinishedUnlockNowSoundText.replacingOccurrences(of: "<ACTIVITY>", with: lastActivity)
            }
        }
    }
    
    
    let task = Process()
    task.arguments = ["-c", "say \"\(text)\""]//-v \"\(popUpBtn.titleOfSelectedItem ?? "")\""]
    task.launchPath = "/bin/zsh"
    task.standardInput = nil
    task.launch()
}

func getStringTime(seconds:Int)->String{
    var stringTime = ""
    
    let hours = seconds / 3600
    let mins = (seconds % 3600) / 60;
    let secs = seconds % 60
    if (hours > 0 && mins > 0 && secs > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(mins)" + " " + (mins > 1 ? minutesText : minuteText) + " " + "\(secs)" + " " + secondsText
    }else if (hours > 0 && mins > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(mins)" + " " + (mins > 1 ? minutesText : minuteText)
    }else if (hours > 0 && secs > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText) + " " + "\(secs)" + " " + secondsText
    }else if (mins > 0 && secs > 0){
        stringTime = "\(mins)" + " " + (mins > 1 ? minutesText : minuteText) + " " + "\(secs)" + " " + secondsText
    }else if (hours > 0){
        stringTime = "\(hours)" + " " + (hours > 1 ? hoursText : hourText)
    }else if (mins > 0){
        stringTime = "\(mins)" + " " + (mins > 1 ? minutesText : minuteText)
    }else if (secs > 0){
        stringTime = "\(secs)" + " " + secondsText
    }
    if stringTime.isEmpty{
        stringTime = "\(secs)" + " " + secondsText
    }
    return stringTime
}




func getstartActivityButtonText(seconds:Int, name:String)->String{
    var title = startActivityButtonText
    if seconds == 86400{
        title = startNonTimerActivityButtonText
        if title.localizedCaseInsensitiveContains("<NAME>"){
            title = title.replacingOccurrences(of: "<NAME>", with: name)
        }
    }else{
        let stringTime = getStringTime(seconds: seconds)
        
        if title.localizedCaseInsensitiveContains("<TIME>"){
            title = title.replacingOccurrences(of: "<TIME>", with: stringTime)
        }
        if title.localizedCaseInsensitiveContains("<NAME>"){
            title = title.replacingOccurrences(of: "<NAME>", with: name)
        }
    }
    
    return title
}


class cursorSegmentedControl: NSSegmentedControl {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}


class shadowScrollViewForTextView: NSScrollView {
    
    var shadowOpacity:Float = 0.3
    var shadowOffset: CGSize = NSMakeSize(0, 5)
    var shadowRadius: CGFloat = 5
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setShadow()
    }
    
    func setShadow(){
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = shadowOpacity
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = shadowOffset
        self.layer?.shadowRadius = shadowRadius
    }
}

class shadowView: NSBox {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, -2)
        self.layer?.shadowRadius = 3
    }
}

class shadowTextField: NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, 2)
        self.layer?.shadowRadius = 3
    }
    
    
}

class menuItemLabel: NSTextField {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.textColor = NSColor.black//buttonTitleColor
        
    }
}

class shadowSecureTextField: NSSecureTextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.wantsLayer = true
        self.shadow = NSShadow()
        self.layer?.shadowOpacity = 0.3
        self.layer?.shadowColor = NSColor.black.cgColor
        self.layer?.shadowOffset = NSMakeSize(0, 2)
        self.layer?.shadowRadius = 3
    }
    
    
}
var isGettingSchema = false



let allApiObject = AllApi()
let pusherEventsObject = pusherEvents()

var applicationSupportURL: URL?
var localFlaskServerFolderURL:URL!
var trackFilesFolderURL:URL!
var DebugLogsFolderURL:URL!
var DebugLogsURL:URL!
var DebugGraphLogsURL:URL!

//var habitInfoFileURL:URL!
var settingForScreeenTimeFileURL:URL!
var newLocalSettingsFileURL:URL!
var arrNonTimerBasedHabitsDurationsPlistFileUrl:URL!


//var blockURL:URL!
var blockWebUrlString = ""
class Log: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        
        if let log = DebugLogsURL{//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
}

class Log_Graphs: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        
        if let log = DebugGraphLogsURL{//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
            if let handle = try? FileHandle(forWritingTo: log) {
                handle.seekToEndOfFile()
                handle.write(string.data(using: .utf8)!)
                handle.closeFile()
            } else {
                try? string.data(using: .utf8)?.write(to: log)
            }
        }
    }
    static var log_Graphs: Log_Graphs = Log_Graphs()
    private init() {} // we are sure, nobody else could create it
}

func addGraphsLog(text:String){
    // if isDebugModeEnabled{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    
    print(now , " - ", text, to: &Log_Graphs.log_Graphs)
    //}
}

func addLog(text:String){
    // if isDebugModeEnabled{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let now = df.string(from: Date())
    
    print(now , " - ", text, to: &Log.log)
    //}
}

func getStringFromDate(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    let now = df.string(from: date)
    return now
}
func getStringFromDateInUtc(date:Date, dateFormat:String)->String{
    let df = DateFormatter()
    df.dateFormat = dateFormat
    df.timeZone = TimeZone(abbreviation: "UTC")
    let now = df.string(from: date)
    return now
}
func getDateFromString(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter.date(from: string)
}

func getDateFromStringInUtc(date:String, dateFormat:String)->Date?{
    let string = date
    // Create Date Formatter
    let dateFormatter = DateFormatter()
    // Set Date Format
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    dateFormatter.dateFormat = dateFormat
    // Convert String to Date
    return dateFormatter.date(from: string)
}

func getFirstRunDateString()->String{
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let myDateString = formatter.string(from: firstRunDate)
    return myDateString
}
func getDaysSinceAppInstalled()->Int{
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
    return diffDays
}

//******************************************CreateDirectoryIfNotExist*******************************************************//
func CreateDirectoryIfNotExist(path:String){
    if !FileManager.default.fileExists(atPath: path){
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }catch{
            
        }
    }
}



////////////////////////////////activation text field ///////////////////////////////////
class CustomTextFieldCell: NSTextFieldCell {
    
    func adjustedFrame(toVerticallyCenterText rect: NSRect) -> NSRect {
        // super would normally draw text at the top of the cell
        var titleRect = super.titleRect(forBounds: rect)
        
        let minimumHeight = self.cellSize(forBounds: rect).height
        titleRect.origin.y += (titleRect.height - minimumHeight) / 2
        titleRect.size.height = minimumHeight
        
        return titleRect
    }
    
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, event: event)
    }
    
    override func select(withFrame rect: NSRect, in controlView: NSView, editor textObj: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: adjustedFrame(toVerticallyCenterText: rect), in: controlView, editor: textObj, delegate: delegate, start: selStart, length: selLength)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: adjustedFrame(toVerticallyCenterText: cellFrame), in: controlView)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.draw(withFrame: cellFrame, in: controlView)
    }
}
class Editing: NSTextField {
    
    private let commandKey = NSEvent.ModifierFlags.command.rawValue
    private let commandShiftKey = NSEvent.ModifierFlags.command.rawValue | NSEvent.ModifierFlags.shift.rawValue
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEvent.EventType.keyDown {
            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}




//


// #MARK:- Check Internet connectivity
public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        
        let isReachable = flags == .reachable
        let needsConnection = flags == .connectionRequired
        
        return isReachable && !needsConnection
        
    }
}
var isPurchased = false
var daysLeft = 0
let daysFreeTrial  = 31


//func  purchaseNow_clicked(){
//    let buynow_path = "https://focusbear.io/buynow"
//    NSWorkspace.shared.open(URL(string: buynow_path)!)
//}


//class customBox: NSBox { not in use 
//    var mouseDown = false
//    var tagValue = 0
//    var isTableView = false
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
//        
//    }
//    
//    override func mouseEntered(with event: NSEvent) {
//        super.mouseEntered(with: event)
//        NSCursor.pointingHand.set()
//    }
//    
//    override func mouseDown(with event: NSEvent) {
//        // super.mouseDown(with: event)
//        print("mouse down")
//        if isTableView{
//            mouseDown = true
//            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
//            NSCursor.pointingHand.set()
//        }else{
//            super.mouseDown(with: event)
//        }
//    }
//    
//    override func mouseUp(with event: NSEvent) {
//        super.mouseUp(with: event)
//        print("mouse up")
//        if mouseDown {
//            mouseDown = false
//            
//            NSCursor.pointingHand.set()
//            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
//        }else{
//            return;
//        }
//        
//        
//        if isTableView{
//            focusModeClicked(index: tagValue)
//        }
//    }
//    
//    func focusModeClicked(index:Int){
//        addLog(text:"[user-action] focusModeClicked")
//        if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//            if trialExpiredNagWcObj != nil{
//                if trialExpiredNagWcObj?.window?.isVisible ?? false{
//                    return;
//                }
//            }
//            showUpgradeNowWindow()
//            return;
//        }
//        
//        if endingFocusWindowControllerObj != nil{
//            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
//                addLog(text: "focus mode clicked:- focus mode completed Window is visible:- return")
//                return;
//            }
//        }
////        if endingFocusWindowControllerObj != nil{
////            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
////                if addTaskVcObj != nil{
////                    if addTaskVcObj!.presentingViewController == focusCompletedVcObj{
////                        return;
////                    }
////                }
////            }
////        }
//        if arrFocusType[index]["isOn"] as? Bool == true || arrFocusType[index]["isPaused"] as? Bool == true{
//            //abort focus mode
//            // new work 13/3/22
//            
//            if arrFocusType[index]["isOn"] as? Bool == true{
//                if currentFocusModeStrictness == ._SUPER_STRICT_{
//                    addLog(text: "can't stop focus mode in super strict focus mode :- return")
//                    var cantStopFocusModeText = "Super strict mode activated: You cannot stop this focus session until it ends."
//                    if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                        cantStopFocusModeText = menuInfo.value(forKey: "cantStopFocusModeText") as? String ?? cantStopFocusModeText
//                    }
//                    showTooltip(sender: self, msg: cantStopFocusModeText, preferredEdge: .minX, maxWidthVal: 250)
//                    return;
//                }
//                var menuItemPauseFocusModeTitle = "Pause this focus mode"
//                var menuItemStopFocusModeTitle = "Stop this focus mode"
//                
//                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                    menuItemPauseFocusModeTitle = menuInfo.value(forKey: "menuItemPauseFocusModeTitle") as? String ?? menuItemPauseFocusModeTitle
//                    menuItemStopFocusModeTitle = menuInfo.value(forKey: "menuItemStopFocusModeTitle") as? String ?? menuItemStopFocusModeTitle
//                }
//                
//                let menu = NSMenu()
//                if timerForFocusMode != nil{
//                    let menuItemPause = NSMenuItem(title: menuItemPauseFocusModeTitle, action: #selector(pauseFocusMode), keyEquivalent: "")
//                    menuItemPause.image = NSImage(named: NSImage.touchBarPauseTemplateName)
//                    menuItemPause.target = self
//                    menu.addItem(menuItemPause)
//                }
//                
//                let menuItemStop = NSMenuItem(title: menuItemStopFocusModeTitle, action: #selector(stopFocusMode), keyEquivalent: "")
//                menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
//                menuItemStop.target = self
//                menu.addItem(menuItemStop)
//                menu.minimumWidth = self.frame.width
//                let p = NSPoint(x: self.frame.origin.x, y: self.frame.origin.y )
//                menu.popUp(positioning: nil, at: p, in: self.superview)
//                return;
//            }else if arrFocusType[index]["isPaused"] as? Bool == true{
//                var menuItemStopFocusModeTitle = "Stop this focus mode"
//                var menuItemResumeFocusModeTitle = "Resume this focus mode"
//                if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
//                    menuItemStopFocusModeTitle = menuInfo.value(forKey: "menuItemStopFocusModeTitle") as? String ?? menuItemStopFocusModeTitle
//                    menuItemResumeFocusModeTitle = menuInfo.value(forKey: "menuItemResumeFocusModeTitle") as? String ?? menuItemResumeFocusModeTitle
//                }
//                
//                let menu = NSMenu()
//                let menuItemResume = NSMenuItem(title: menuItemResumeFocusModeTitle, action: #selector(resumeFocusMode), keyEquivalent: "")
//                menuItemResume.image = NSImage(named: NSImage.touchBarPlayTemplateName)
//                menuItemResume.target = self
//                menu.addItem(menuItemResume)
//                
//                let menuItemStop = NSMenuItem(title: menuItemStopFocusModeTitle, action: #selector(stopFocusMode), keyEquivalent: "")
//                menuItemStop.image = NSImage(named: NSImage.Name("NSTouchBarRecordStopTemplate"))
//                menuItemStop.target = self
//                menu.addItem(menuItemStop)
//                
//                
//                menu.minimumWidth = self.frame.width
//                let p = NSPoint(x: self.frame.origin.x, y: self.frame.origin.y )
//                menu.popUp(positioning: nil, at: p, in: self.superview)
//                return;
//            }
//        }else{
//            if isHardCorePomodoroModeOn{
//                
//                return;
//            }
//            for i in 0..<arrFocusType.count{
//                if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
//                    let alert = NSAlert()
//                    alert.setSharingType()
//                    alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
//                    var buttonStopFocusText = "Stop current focus mode and start this one"
//                    
//                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                        if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
//                            alert.messageText = focusAlreadyRunningText
//                        }
//                    }
//                    
//                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                            buttonStopFocusText = startingFocusModeInfo.value(forKey: "buttonStopFocusText") as? String ?? buttonStopFocusText
//                        }
//                    }
//                    
//                    alert.addButton(withTitle: buttonOkText)
//                    alert.addButton(withTitle: buttonStopFocusText)
//                    NSApplication.shared.activate(ignoringOtherApps: true)
//                    let result = alert.runModal()
//                    if result == .alertSecondButtonReturn{
//                        addLog(text: "Stop current focus from alert and show start focus view")
//                        appdelegate?.tryFocusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false)
//                        
//                        let isRelaxFocus = arrFocusType[index]["isRelaxFocus"] as? Bool ?? false
//                        if isRelaxFocus{
//                            if shouldAskPassword(){
//                                if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
//                                    menuViewControllerObj?.showPasswordWindow()
//                                    menuViewControllerObj?.isShowingPasswordForRelaxFocusMode = true
//                                }else{
//                                    showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//                                }
//                            }else{
//                                showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//                            }
//                        }else{
//                            showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//                        }
//                    }
//                    return;
//                }
//            }
//            
//            // //prvent user from start a focus mode while runnning a activity
//            
//            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._MICRO_BREAK_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._CUSTOM_ROUTINE_{
//                addLog(text: "Activity is running: Can not start a focus mode")
//                let alert = NSAlert()
//                alert.setSharingType()
//                alert.messageText = "You can not start a focus mode while an activity is running."
//                
//                if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
//                    if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
//                        alert.messageText = startingFocusModeInfo.value(forKey: "activityRunningCantStartFocusText") as? String ?? alert.messageText
//                    }
//                }
//                NSApplication.shared.activate(ignoringOtherApps: true)
//                alert.runModal()
//                return;
//            }
//            
//            
//            
//            
//            let isRelaxFocus = arrFocusType[index]["isRelaxFocus"] as? Bool ?? false
//            if isRelaxFocus{
//                if shouldAskPassword(){
//                    if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
//                        menuViewControllerObj?.showPasswordWindow()
//                        menuViewControllerObj?.isShowingPasswordForRelaxFocusMode = true
//                    }else{
//                        showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//                    }
//                }else{
//                    showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//                }
//            }else{
//                showStartingFocusMode(focusModeIndex: index, focusType: arrFocusType[index]["name"] as? String ?? "")
//            }
//            
//            return;
//            
//        }
//    }
//    @objc func pauseFocusMode(){
//        if currentFocusModeStrictness == ._STRICT_{
//            showAbortingFocusModeVc(forPause: true)
//        }else{
//            appdelegate?.pauseFocusMode(index: tagValue)
////            menuViewControllerObj?.tblViewFocusMode.reloadData()
//        }
//    }
//    
//    @objc func stopFocusMode(){
//        if isHardCorePomodoroModeOn{
//            if shouldAskPassword(){
//                if SettingsManagerObject.isPasswordRequireInStopPomodoro{
//                    menuViewControllerObj?.showPasswordWindow()
//                    addLog(text: "Showing enter password view from hardcore pomodoro stop from focus stop menu")
//                }else{
//                    showAbortingFocusModeVc(forPause: false)
//                }
//            }else{
//                showAbortingFocusModeVc(forPause: false)
//            }
//        }else{
//            showAbortingFocusModeVc(forPause: false)
//        }
//    }
//    
//    @objc func resumeFocusMode(){
//        appdelegate?.resumeFocusMode(index: tagValue)
////        menuViewControllerObj?.tblViewFocusMode.reloadData()
////        menuViewControllerObj?.startFocusRemainingTimer()
//    }
//    override func mouseExited(with event: NSEvent) {
//        super.mouseExited(with: event)
//        mouseDown = false
//        NSCursor.arrow.set()
//        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
//    }
//}






var focusDefaultAllowApps = ["finder", "universalaccessauthwarn", "system preferences", "loginwindow", "screensaverengine", "osascript", "late no more", "focus bear time tracker"]
var arrExcludeAppsInBreaksBrainDumpLastActivateApp = ["finder", "universalaccessauthwarn", "system preferences", "loginwindow", "screensaverengine", "osascript", "late no more", "focus bear time tracker"]

let focusBearTimeTrackerAppName = "focus bear time tracker"


var selfAppName = Bundle.main.infoDictionary!["CFBundleName"] as! String




var lastFrontMostApplication:NSRunningApplication?


func getColorString(color:NSColor)->String{
    let ciColor:CIColor = CIColor(color: color)!
    let hexString = String(format: "%02X%02X%02X", Int(ciColor.red * 0xff), Int(ciColor.green * 0xff), Int(ciColor.blue * 0xff))
    return hexString
}
func HexToColor(hexString: String, alpha:CGFloat? = 1.0) -> NSColor {
    // Convert hex string to an integer
    let hexint = Int(intFromHexString(hexStr: hexString))
    let red = CGFloat((hexint & 0xff0000) >> 16) / 255.0
    let green = CGFloat((hexint & 0xff00) >> 8) / 255.0
    let blue = CGFloat((hexint & 0xff) >> 0) / 255.0
    let alpha = alpha!
    // Create color object, specifying alpha as well
    let color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
    return color
}
func intFromHexString(hexStr: String) -> UInt32 {
    var hexInt: UInt32 = 0
    // Create scanner
    let scanner: Scanner = Scanner(string: hexStr)
    // Tell scanner to skip the # character
    scanner.charactersToBeSkipped = NSCharacterSet(charactersIn: "#") as CharacterSet
    // Scan hex value
    scanner.scanHexInt32(&hexInt)
    return hexInt
}



func isBlockSuperDistractingFocusModeOn()->Bool{
    if currentRunningFocusType["isDefault"] as? Bool == true {
        return true
    }
    return false
}

//pomodoro
func resetPomodoroVcFocusListIfNeeded(){
    if pomodoroWindowControllerObj != nil{
        if pomodoroWindowControllerObj != nil{
            if (pomodoroWindowControllerObj?.window!.isVisible)!{
                if pomodoroWindowControllerObj?.contentViewController == pomodoroVcObj{
                    pomodoroVcObj?.reFillFocusTypeList()
                }
            }
        }
    }
}


var assertionIDDisableSleep: IOPMAssertionID = 0
func disableSystemSleep(){
    addLog(text:"disableSystemSleep")
    let reasonForActivity = "Reason for activity" as CFString
    //    var assertionID: IOPMAssertionID = 0
    var success = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                               IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                               reasonForActivity,
                                               &assertionIDDisableSleep )
    //    if success == kIOReturnSuccess {
    //        // Add the work you need to do without the system sleeping here.
    //
    //        success = IOPMAssertionRelease(assertionIDDisableSleep);
    //        // The system will be able to sleep again.
    //    }
}
func enableSystemSleep(){
    IOPMAssertionRelease(assertionIDDisableSleep);
}


var isFocusMusicPausedAutomatically = false
func pauseAutomaticallyIfAnyFocusMusicPlaying(){
    if allTracksVcObj != nil{
        for i in 0..<arrAllTracks.count{
            if arrAllTracks[i]["isPlaying"] as? Bool == true{
                arrAllTracks[i]["isPlaying"] = false
                arrAllTracks[i]["isPaused"] = true
                if allTracksVcObj?.currentSound?.isPlaying ?? false{
                    allTracksVcObj?.currentSound?.pause()
                    isFocusMusicPausedAutomatically = true
                }
                if allTracksWindowControllerObj != nil{
                    if allTracksWindowControllerObj?.window?.isVisible ?? false{
                        allTracksVcObj?.tblView.reloadData()
                    }
                }
                break;
            }
        }
    }
}
func resumeIfAnyFocusMusicStoppedAutomatically(){
    if isFocusMusicPausedAutomatically{
        isFocusMusicPausedAutomatically = false
        if allTracksVcObj != nil{
            for i in 0..<arrAllTracks.count{
                if arrAllTracks[i]["isPaused"] as? Bool == true{
                    arrAllTracks[i]["isPlaying"] = true
                    arrAllTracks[i]["isPaused"] = false
                    allTracksVcObj?.currentSound?.resume()
                    if allTracksWindowControllerObj != nil{
                        if allTracksWindowControllerObj?.window?.isVisible ?? false{
                            allTracksVcObj?.tblView.reloadData()
                        }
                    }
                    break;
                }
            }
        }
    }
}


func checkIsFullScreenEnabled()-> Bool{
    if currentState == ._MICRO_BREAK_{
        if isBreakActivityShowingWhileMeeting{
            return false
        }
    }
    
    return SettingsManagerObject.isFullScreenEnabled
}



var newGifsNamesArray = ["Glasses-Bear-250-px_V3", "cheer_250px_trans_centered", "Finger-and-Sign-Bear-250px", "Weight-bear-250-px_V2", "Whistle-bear-250-px"]


extension String {
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
}

//

func wildcard(_ string: String, pattern: String) -> Bool {
    let pred = NSPredicate(format: "self LIKE %@", pattern)
    return !NSArray(object: string).filtered(using: pred).isEmpty
}

func getDomainFromUrl(url:String) -> String{
    let mainurl = NSURL(string: url)
    var domain = mainurl?.host ?? ""
    
    if domain.contains("www."){
        domain = domain.replacingOccurrences(of: "www.", with: "")
    }
    return domain
}

func getPathFromUrl(url:String) -> String{
    let domain = getDomainFromUrl(url: url)
    
    var path = url.replacingOccurrences(of: "http://", with: "")
    path = path.replacingOccurrences(of: "https://", with: "")
    if path.contains("www."){
        path = path.replacingOccurrences(of: "www.", with: "")
    }

    if domain == "youtube.com"{
        return path
    }else{
        if path.contains("?"){
            path = path.components(separatedBy: "?")[0]
        }
    }
    return path
}

func getPathFromUrl(url:String, domain:String) -> String{
    var path = url.replacingOccurrences(of: "http://", with: "")
    path = path.replacingOccurrences(of: "https://", with: "")
    if path.contains("www."){
        path = path.replacingOccurrences(of: "www.", with: "")
    }

    if domain == "youtube.com"{
        return path
    }else{
        if path.contains("?"){
            path = path.components(separatedBy: "?")[0]
        }
    }
    return path
}


func isPreventUserIdleDisplaySleepOn()-> Bool{
    var assertions: Unmanaged<CFDictionary>?
    if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
        fatalError("Error with assertions")
    }
    var dic = [AnyHashable : Any]()

    if assertions != nil{
        
        let val = assertions!.takeRetainedValue()

        if let dictionary = val as? [AnyHashable : Any]{
            dic = dictionary
        }else{
            addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
            return false
        }
    }else{
        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
        return false
    }

    let processArray = ["zoom.us", "teams"]// lowercased names aynge sirf

    let keys  = dic.keys
    for key in keys{
        if let arr = dic[key] as? NSArray{
            var isArrayContainAudioIn = false
            var isArrayContainAudioIOut = false
            var isArrayContainColonOutput = false
            var isArrayContainColonInput = false
            var isArrayContainAppleHDAEngineOutput = false
            
            for item in arr{
                if let itemDic = item as? NSDictionary{
                    if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                        if let name = itemDic.value(forKey: "Process Name") as?  String{
                            let processName = name.lowercased()
                            if processName != selfAppName.lowercased(){
                                if processArray.contains(processName){
                                    addLog(text: "is Prevent UserIdle Display SleepOn return true")
                                    return true
                                }
                            }
                            
                        }
                    }else if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleSystemSleep"{
                        if var resourcesUsedArr = itemDic.value(forKey: "ResourcesUsed") as?  [String]{
                            resourcesUsedArr = resourcesUsedArr.map {$0.lowercased()}
                            var isContainAudioIn = false
                            var isContainAudioIOut = false
                            if resourcesUsedArr.contains("audio-in"){
                                isContainAudioIn = true
                                isArrayContainAudioIn = true
                            }
                            if resourcesUsedArr.contains("audio-out"){
                                isContainAudioIOut = true
                                isArrayContainAudioIOut = true
                            }
                            
                            if isContainAudioIn && isContainAudioIOut{
                                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and audioOut found in resources")
                                return true
                            }else if isContainAudioIOut{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":input"){
                                        addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and colonOut found in resources")
                                        return true
                                    }
                                }
                            }
                            if !isContainAudioIOut{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":output"){
                                        isArrayContainColonOutput = true
                                    }else if resource.contains("applehdaengineoutput:"){
                                        isArrayContainAppleHDAEngineOutput = true
                                    }
                                }
                            }
                            if !isContainAudioIn{
                                for resource in resourcesUsedArr{
                                    if resource.contains(":input"){
                                        isArrayContainColonInput = true
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            
            if isArrayContainAudioIn && isArrayContainAudioIOut{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and audioOut found in array")
                return true
            }else if isArrayContainAudioIn && isArrayContainColonOutput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and colonOut found in array")
                return true
            }else if isArrayContainAudioIOut && isArrayContainColonInput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioOut and colonIn found in array")
                return true
            }else if isArrayContainAudioIn && isArrayContainAppleHDAEngineOutput{
                addLog(text: "is Prevent UserIdle System SleepOn return true:- audioIn and AppleHDAEngineOutput found in array")
                return true
            }
        }
    }
    
    //    addLog(text: "is Prevent UserIdle Display SleepOn return false")
    return false
}


func isAnyPresentationOrVideoShowing()-> Bool{
    var assertions: Unmanaged<CFDictionary>?
    if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
        fatalError("Error with assertions")
    }
    var dic = [AnyHashable : Any]()
    
    if assertions != nil{
        
        let val = assertions!.takeRetainedValue()
        
        if let dictionary = val as? [AnyHashable : Any]{
            dic = dictionary
        }else{
            addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
            return false
        }
    }else{
        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
        return false
    }
    
    let keys  = dic.keys
    for key in keys{
        if let arr = dic[key] as? NSArray{
            for item in arr{
                if let itemDic = item as? NSDictionary{
                    if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                        if let name = itemDic.value(forKey: "Process Name") as?  String{
                            let processName = name.lowercased()
                            if processName != selfAppName.lowercased(){
                                return true
                            }
                            
                        }
                    }
                    
                }
            }
        }
    }
    return false
}



var lastShownRandomChoiceDic = [String:activityChoice]()



let mainAppBundelId = Bundle.main.bundleIdentifier ?? ""
//func createLaunchAgent(){//  comment this
//    addLog(text: "func:- createLaunchAgent")
//    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
//    let path = Bundle.main.bundlePath
//    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
//        for uLA in userLA {
//            if uLA.isCurrentlyLoaded{
//                if let arguments = uLA.programArguments as? [String]{
//                    if arguments.contains(where: {$0.caseInsensitiveCompare(path) == .orderedSame}) {
//                        addLog(text: "LaunchAgent already created return")
//                        return;
//                    }
//                }
//            }
//        }
//    }
//    //
//    
//    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
//    if !FileManager.default.fileExists(atPath: destination) {
//        do {
//            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
//        } catch {}
//        
//    }
//    
//    // saves the agent plist file
//    let userLaunchAgentsPath = "\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"
//    
//    let dicContent = ["Label": "\(mainAppBundelId).plist", "ProgramArguments":["/usr/bin/open","-F","-g",path,"--args"],"RunAtLoad":true,"KeepAlive":true] as [String : Any]
//    
//    let plistContent = NSDictionary(dictionary: dicContent)
//    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
//    if success {
//        print("file has been created!")
//    }else{
//        print("unable to create the file")
//    }
//    shell(launchPath: "/bin/launchctl", arguments: ["load","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
//    addLog(text: "createLaunchAgent done")
//}

var helperUrl: URL = {

    let helperURL = URL(fileURLWithPath: "Contents/Resources/FBHelper.app", relativeTo: Bundle.main.bundleURL)
    return helperURL
}()

func createLaunchAgentForHelperApp(){
    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
    let helperBundleID = "com.focusbear.focusbearhelper"
    let path = helperUrl.path
    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
        for uLA in userLA {
            if uLA.isCurrentlyLoaded{
                if let arguments = uLA.programArguments as? [String]{
                    if arguments.contains(where: {$0.caseInsensitiveCompare(path) == .orderedSame}) {
                        return;
                    }
                }
            }
            
            
        }
    }
    //
    
    
    
    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
    if !FileManager.default.fileExists(atPath: destination) {
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
    }
    
    // saves the agent plist file
    let userLaunchAgentsPath = "\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(helperBundleID).plist")"
    
    let dicContent = ["Label": "\(helperBundleID).plist", "ProgramArguments":["/usr/bin/open","-F","-g",path,"--args"],"RunAtLoad":true,"KeepAlive":true] as [String : Any]
    
    let plistContent = NSDictionary(dictionary: dicContent)
    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
    if success {
        print("file has been created!")
    }else{
        print("unable to create the file")
    }
    shell(launchPath: "/bin/launchctl", arguments: ["load","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(helperBundleID).plist")"])
}

func deleteLaunchAgent(){
    addLog(text: "func:- deleteLaunchAgent")
    //Background process "open" modified when Focus Bear opened?  #409 It shouldn't appear every time the app is restarted
    let path = Bundle.main.bundlePath
    if let userLA = AHLaunchCtl.allJobsFromFiles(in: AHLaunchDomain.userLaunchAgent) as? [AHLaunchJob] {
        for uLA in userLA {
            if uLA.isCurrentlyLoaded{
                if let arguments = uLA.programArguments as? [String]{
                    if arguments.contains(where: {$0.caseInsensitiveCompare(path) == .orderedSame}) {
                        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                        addLog(text: "deleteLaunchAgent done")
                        return;
                    }
                }
            }
            
            
        }
    }
    //
    
}



func shell(launchPath: String, arguments: [String] = [])  {
    addLog(text: "func shell")
    let task = Process()
    task.launchPath = launchPath
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
}


func isShutOffTimeGoing()->Bool{
    if startTime == nil || shutOffTime == nil{
        return false
    }
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    let currentDate = Date()
    
    var isShutOffTime = false
    
    if  startDate.compare(shutOffdate) == .orderedDescending{//(start date jyada ho shut off date se ) ex shut off 5 bje start date 8 bje
        if currentDate.compare(startDate) == .orderedAscending  && currentDate.compare(shutOffdate) == .orderedDescending{
            isShutOffTime = true
        }
        
    }else if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
        isShutOffTime = true
    }
    return isShutOffTime
}


func showNotificationWithMessage(msg:String){
    let notification = NSUserNotification()
    //notification.informativeText = ""
    notification.title = msg
    notification.soundName = NSUserNotificationDefaultSoundName
    NSUserNotificationCenter.default.deliver(notification)
}






//***********Popup Block Confirm Window***************//
func getBlurFrameForBrowser(x:Int, y:Int, width:Int, height:Int, browser:BROWSER)->NSRect{
    switch browser{
    case ._SAFARI_:
        return NSRect(x: x, y: y + 81, width: width, height: height - 81)
    case . _GOOGLE_CHROME_:
        return NSRect(x: x, y: y + 85, width: width, height: height - 85)
    case . _OPERA_:
        return NSRect(x: x, y: y + 82, width: width, height: height - 82)
    case . _OPERA_GX_:
        return NSRect(x: x, y: y + 76, width: width, height: height - 76)
    case . _VIVALDI_:
        return NSRect(x: x, y: y + 67, width: width, height: height - 67)
    case ._BRAVE_BROWSER_:
        return NSRect(x: x, y: y + 77, width: width, height: height - 77)
    case ._SIDEKICK_:
        return NSRect(x: x, y: y + 79, width: width, height: height - 79)
    case ._MICROSOFT_EDGE_:
        return NSRect(x: x, y: y + 79, width: width, height: height - 79)
    case ._ARC_:
        return NSRect(x: x + 213, y: y + 40, width: width - 213, height: height - 40)
    case ._FIREFOX_:
        return NSRect(x: x, y: y + 81, width: width, height: height - 81)
    case ._SIGMA_OS_:
        return NSRect(x: x + 288, y: y + 48, width: width - 288, height: height - 48)
    }
}



func runAppleScriptFile(path:String){
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = [path]
    
    task.launch()
}

func runShellCommand(command:String){
    let task = Process()
    var args: [AnyHashable] = []
    args.append("-c")
    args.append(command)
    task.launchPath = "/bin/sh"
    task.arguments = args as? [String]
    task.launch()
}

func workBeforeFocusBegin(index:Int){
    var appleScriptPath:String?
    var shellCommand:String?
    
    if let isScriptBeforeFocusEnabled = arrFocusType[index]["isScriptBeforeFocusEnabled"] as? Bool{
        if isScriptBeforeFocusEnabled{
            if let path = arrFocusType[index]["scriptPathBeforeFocus"] as? String{
                appleScriptPath = path
            }
        }
    }
    
    if let isShellCommandBeforeFocusEnabled = arrFocusType[index]["isShellCommandBeforeFocusEnabled"] as? Bool{
        if isShellCommandBeforeFocusEnabled{
            if let text = arrFocusType[index]["shellCommandBeforeFocusText"] as? String{
                if !text.isEmpty{
                    shellCommand = text
                }
            }
        }
    }
    
    if appleScriptPath == nil && shellCommand == nil{
        return;
    }

    var shouldShowConfirmationForScript = true
    
    if let state = UserDefaults.standard.object(forKey: kUserdefaultsDontConfirmBeforeExecuteScript) as? Bool{
        shouldShowConfirmationForScript = !state
    }else{
        UserDefaults.standard.set(false, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
    }
    
    if shouldShowConfirmationForScript{
        let name = arrFocusType[index]["name"] as? String ?? ""
        showConfirmRunScriptWindow(focusMode: name, scriptPath: appleScriptPath, shellCommand: shellCommand)
    }else{
        if let appleScriptPath = appleScriptPath{
            runAppleScriptFile(path: appleScriptPath)
        }
        if let shellCommand = shellCommand{
            runShellCommand(command: shellCommand)
        }
    }
}

func workAfterFocusBegin(index:Int){
    var appleScriptPath:String?
    var shellCommand:String?
    
    if let isScriptAfterFocusEnabled = arrFocusType[index]["isScriptAfterFocusEnabled"] as? Bool{
        if isScriptAfterFocusEnabled{
            if let path = arrFocusType[index]["scriptPathAfterFocus"] as? String{
                appleScriptPath = path
            }
        }
    }
    
    
    if let isShellCommandAfterFocusEnabled = arrFocusType[index]["isShellCommandAfterFocusEnabled"] as? Bool{
        if isShellCommandAfterFocusEnabled{
            if let text = arrFocusType[index]["shellCommandAfterFocusText"] as? String{
                if !text.isEmpty{
                    shellCommand = text
                }
            }
        }
    }
    
    if appleScriptPath == nil && shellCommand == nil{
        return;
    }

    var shouldShowConfirmationForScript = true
    
    if let state = UserDefaults.standard.object(forKey: kUserdefaultsDontConfirmBeforeExecuteScript) as? Bool{
        shouldShowConfirmationForScript = !state
    }else{
        UserDefaults.standard.set(false, forKey: kUserdefaultsDontConfirmBeforeExecuteScript)
    }
    
    if shouldShowConfirmationForScript{
        let name = arrFocusType[index]["name"] as? String ?? ""
        showConfirmRunScriptWindow(focusMode: name, scriptPath: appleScriptPath, shellCommand: shellCommand)
    }else{
        if let appleScriptPath = appleScriptPath{
            runAppleScriptFile(path: appleScriptPath)
        }
        if let shellCommand = shellCommand{
            runShellCommand(command: shellCommand)
        }
    }
}

//*****************************Read data from csv******************************//
func readDataFromCSV(url:URL)-> [[String]]{
    var arrItems = [[String]]()
    if let string = try? String(contentsOf: url){
        let arrCsv = csv(data: string)
        for item in arrCsv{
            if let row = item.first{
                var arrHeaders = [String]()
                let arrString = getArrItem(data: row)
                for header in arrString{
                    if header != "\r"{
                        arrHeaders.append(header)
                    }
                }
                arrItems.append(arrHeaders)
            }
        }
    }
    return arrItems
}
func csv(data: String) -> [[String]] {
    var result: [[String]] = []
    let rows = data.components(separatedBy: "\n")
    for row in rows {
        let columns = row.components(separatedBy: ";")
        result.append(columns)
    }
    return result
}
func getArrItem(data: String) -> [String] {
    var result: [String] = []
    result = data.components(separatedBy: ",")
    return result
}


var arrLanguageDic = [["name":"English", "id":"en", "languageName":"English"], ["name":"Spanish", "id":"es", "languageName":"Spanish"]]
var currentLanguageCode = ""


class PopoverAwareTextField: NSTextField, NSPopoverDelegate {// not in use 
    
    var parentVcObj:rememberNextHabitVc?
    var itemsArr = [String]()
    var popoverViewControllerObj:PopoverViewController?// = PopoverViewController()
    var selectedItemId = -1
    
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = -1
            
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: itemsArr)
            popoverViewControllerObj!.tblView.reloadData()
            let range = self.currentEditor()?.selectedRange
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        }
        
        return super.becomeFirstResponder()
    }
    
    
    
    @objc func Close(){
        popoverViewControllerObj!.view.isHidden = true
    }
    
    override func keyUp(with theEvent: NSEvent) {
        
        if theEvent.keyCode == 53 || theEvent.keyCode == 48{//esc,tab
            super.keyUp(with: theEvent)
            popoverViewControllerObj?.view.isHidden = true
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{//enter
            if popoverViewControllerObj!.view.isHidden == false{
                popoverViewControllerObj!.doubleClicked()
            }else{
                
            }
            super.keyUp(with: theEvent)
            return
        }
        if theEvent.keyCode == 126{//// up key
            popoverViewControllerObj!.selectPrevious()
            return
        }
        if theEvent.keyCode == 125{//down key (go next)
            if popoverViewControllerObj!.view.isHidden == true{
                popoverViewControllerObj!.view.isHidden = false
            }else{
                popoverViewControllerObj!.selectNext()
            }
            return
        }
        self.complete(self)
        super.keyUp(with: theEvent)
    }
    
    override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        var matches = [String]()
        selectedItemId = -1
        if self.itemsArr.count != 0 {
            matches.removeAll()
            for result in self.itemsArr {
                if result.localizedStandardContains(self.stringValue){
                    matches.append(result)
                }
            }
            
        }
        
        if lengthOfWord == 0{
            matches = self.itemsArr
        }
        if matches.count > 0 {
            let range = self.currentEditor()?.selectedRange
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: matches)
            popoverViewControllerObj!.tblView.reloadData()
            
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        } else{
            popoverViewControllerObj!.view.isHidden = true
        }
    }
    
}
class PopoverAwareSearchField: NSSearchField, NSPopoverDelegate {
    
    var parentVcObj:settingsSideBarVc?
    var itemsArr = [[String:Any]]()
    var popoverViewControllerObj:PopoverViewControllerForSearch?// = PopoverViewController()
    var selectedItemId = ""
    
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = ""
            
            
            //            self.superview?.addSubview(popoverViewControllerObj.view)
            //            addConstraints()
            //            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)
            popoverViewControllerObj!.view.isHidden = true
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: itemsArr)
            popoverViewControllerObj!.tblView.reloadData()
            let range = self.currentEditor()?.selectedRange
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        }
        
        return super.becomeFirstResponder()
    }
    
    
    @objc func Close(){
        popoverViewControllerObj!.view.isHidden = true
    }
    
    override func keyUp(with theEvent: NSEvent) {
        
        if theEvent.keyCode == 53 || theEvent.keyCode == 48{//esc,tab
            super.keyUp(with: theEvent)
            popoverViewControllerObj?.view.isHidden = true
            return
        }
        if theEvent.keyCode == 36 || theEvent.keyCode == 76{//enter
            if popoverViewControllerObj!.view.isHidden == false{
                popoverViewControllerObj!.doubleClicked()
            }else{
                
            }
            super.keyUp(with: theEvent)
            return
        }
        if theEvent.keyCode == 126{//// up key
            popoverViewControllerObj!.selectPrevious()
            return
        }
        if theEvent.keyCode == 125{//down key (go next)
            if popoverViewControllerObj!.view.isHidden == true{
                popoverViewControllerObj!.view.isHidden = false
            }else{
                popoverViewControllerObj!.selectNext()
            }
            return
        }
        self.complete(self)
        super.keyUp(with: theEvent)
    }
    
    override func complete(_ sender: Any?) {
        let lengthOfWord = self.stringValue.count
        if lengthOfWord == 0{
            popoverViewControllerObj!.view.isHidden = true
            return;
        }
        var matches = [[String:Any]]()
        selectedItemId = ""
        if self.itemsArr.count != 0 {
            matches.removeAll()
            for result in self.itemsArr {
                if ((result)["title"] as? String ?? "").localizedStandardContains(self.stringValue){
                    matches.append(result)
                }
            }
            
        }
        
        if lengthOfWord == 0{
            matches = self.itemsArr
        }
        if matches.count > 0 {
            let range = self.currentEditor()?.selectedRange
            //            popover.show(relativeTo: self.frame, of: self, preferredEdge: .maxY)
            //            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)//////
            popoverViewControllerObj!.view.isHidden = false
            popoverViewControllerObj!.textFieldObj = self
            popoverViewControllerObj!.ReloadData(arr: matches)
            popoverViewControllerObj!.tblView.reloadData()
            
            self.selectText(self)
            self.currentEditor()?.selectedRange = range ?? NSMakeRange(0, 0)
        } else{
            //            popover.close()/////
            popoverViewControllerObj!.view.isHidden = true
        }
    }
    
}

func roundToHundred(number : Int) -> Int {
    let rounded = Int(number + 50)/100 * 100
    print(rounded) // 1398000
    return rounded
}
func roundToTen(number : Int) -> Int {
    let rounded = (number + 5)/10 * 10
    print(rounded) // 1398000
    return rounded
}
func roundOffValue(number : Int) -> Int {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}

func roundToHundred(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/100 * 100)
    print(rounded) // 1398000
    return rounded
}

func roundToTen(number : Double) -> Double {
    let rounded:Double = Double(Int(number + 5)/10 * 10)
    print(rounded) // 1398000
    return rounded
}

func roundOffValue(number : Double) -> Double {
    if number < 99{
        return roundToTen(number: number)
    }else{
        return roundToHundred(number: number)
    }
}

func roundDoubleValue(val:Double)->Double{
    return Double(round(10 * val) / 10)
}


extension NSTextField{
    func setFocus(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: self.stringValue.count, length: 0)
    }
    
    func setFocusAndSelectText(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: 0, length: self.stringValue.count)
    }
}



func getUuid()->String{
    return UUID().uuidString.lowercased()
}


func showAlertNoInternet(window:NSWindow){
    var noInternetTitle = "No Internet Connection"
    var noInternetSubTitle = "Make sure your device is connected to the internet."
    addLog(text: "No Internet Connection")
    if let activationNagInfo = configjson.value(forKey: "activationNagInfo") as? NSDictionary{//useful text
        if let text = activationNagInfo.value(forKey: "noInternetTitle") as? String{
            noInternetTitle = text
        }
        if let text = activationNagInfo.value(forKey: "noInternetSubTitle") as? String{
            noInternetSubTitle = text
        }
    }
    let alert = NSAlert()
    alert.setSharingType()
    alert.messageText = noInternetTitle
    alert.informativeText = noInternetSubTitle
    alert.alertStyle = .warning
    alert.addButton(withTitle:  buttonOkText)
    alert.beginSheetModal(for: window, completionHandler: {_ in
        window.close()
    }) 
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

var allActivityTodaySummaryData:NSDictionary?
var graphOneMonthData:NSDictionary?
var graphOneDayData:[NSDictionary]?
var graphOneDayDataForQuantity:NSDictionary?

var focusModeTemplateData:[NSDictionary]?
var habitPacksData:[NSDictionary]?

extension NSAppleEventDescriptor {
    
    func toStringArray() -> [String] {
        guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
            return []
        }
        
        return (0..<listDescriptor.numberOfItems)
            .compactMap { listDescriptor.atIndex($0 + 1)?.stringValue }
    }
    func toAnyArray() -> [String:[String]] {
        guard let listDescriptor = self.coerce(toDescriptorType: typeAEList) else {
            return [:]
        }
        var tabStruct = [String:[String]]()
        
        for i in 0..<listDescriptor.numberOfItems{
            guard let listWindDescriptor = listDescriptor.atIndex(i + 1)?.coerce(toDescriptorType: typeAEList) else {
                return [:]
            }
            var currentKey = ""
            for j in 0..<listWindDescriptor.numberOfItems{
                
                if  let listTabDescriptor = listWindDescriptor.atIndex(j + 1)?.coerce(toDescriptorType: typeAEList){
                    
                    for k in 0..<listTabDescriptor.numberOfItems{
                        if let stringValue = listTabDescriptor.atIndex(k + 1)?.stringValue{
                            
                            if let id  = Int(stringValue){
                                currentKey = stringValue
                                var arrTabs = [String]()
                                tabStruct[currentKey] = arrTabs
                            }else{
                                if !currentKey.isEmpty{
                                    var tabArr = tabStruct[currentKey] ?? []
                                    tabArr.append(stringValue)
                                    tabStruct[currentKey] = tabArr
                                }
                            }
                            
                        }
                        
                    }
                    
                }
            }
        }
        
        return tabStruct;
    }
}

func setDocBarTo(isHide:Bool){
    DispatchQueue.global().async {
        if !SettingsManagerObject.isHideDockInActivity{
            return
        }
        var script: String = ""
        var hideVal = "true"
        if isHide{
            addLog(text:"set Doc Bar To hide")
            hideVal = "true"
        }else{
            addLog(text:"set Doc Bar To unhide")
            hideVal = "false"
        }
        
        script =
        """
        tell application "System Events"
        set autohide of dock preferences to \(hideVal)
        end tell
        """
        
        executeScript(script: script)
    }
}

func checkDocBarState()->String?{
    var script: String = ""
    
    script =
    """
    tell application "System Events"
    set val to autohide of dock preferences
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors!)
        }
        return desc.stringValue
    }
    return nil
}



extension NSLayoutConstraint {
    /**
     Change multiplier constraint
     
     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
     */
    func setMultiplier(multiplier:CGFloat) -> NSLayoutConstraint {
        
        NSLayoutConstraint.deactivate([self])
        
        let newConstraint = NSLayoutConstraint(
            item: firstItem,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)
        
        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier
        
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

var backgroundColor = NSColor(named: "backgroundColor") ?? NSColor.windowBackgroundColor
class customBoxBg:NSBox{
    //    override func draw(_ dirtyRect: NSRect) {

    override func draw(_ dirtyRect: NSRect) {
        // Make the pattern tile repeat from the top of the view.
        let yOffset = NSMaxY(self.convert(self.frame, to: nil))
        NSGraphicsContext.current?.patternPhase = NSMakePoint(0, yOffset)
        
        super.draw(dirtyRect)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.fillColor = backgroundColor
        //let image = #imageLiteral(resourceName: "background")
        //self.contentView?.backgroundcolor = NSColor(patternImage: image)
    }
}



class CustomImageView: NSImageView {
    override var mouseDownCanMoveWindow: Bool{
        return true
    }
}

//MARK: Custom Popover Background and Arrow
class PopoverContentView:NSView {
    var backgroundView:PopoverBackgroundView?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if SettingsManagerObject.isMenuPopoverEnabled{
            if let frameView = self.window?.contentView?.superview {
                if backgroundView == nil {
                    backgroundView = PopoverBackgroundView(frame: frameView.bounds)
                    backgroundView!.autoresizingMask = NSView.AutoresizingMask([.width, .height]);
                    frameView.addSubview(backgroundView!, positioned: NSWindow.OrderingMode.below, relativeTo: frameView)
                }
            }
        }else if backgroundView != nil{
            backgroundView?.removeFromSuperview()
            backgroundView = nil
        }
    }
}

class PopoverBackgroundView:NSView {
    override func draw(_ dirtyRect: NSRect) {
        backgroundColor.set()
        //  NSRectFill(self.bounds)
        bounds.fill()
        
    }
}



class PopoverContentViewForMenuTour:NSView {
    var backgroundView:PopoverBackgroundViewForMenuTour?
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let frameView = self.window?.contentView?.superview {
            if backgroundView == nil {
                backgroundView = PopoverBackgroundViewForMenuTour(frame: frameView.bounds)
                backgroundView!.autoresizingMask = NSView.AutoresizingMask([.width, .height]);
                frameView.addSubview(backgroundView!, positioned: NSWindow.OrderingMode.below, relativeTo: frameView)
            }
        }
    }
}

class PopoverBackgroundViewForMenuTour:NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.set()
        //  NSRectFill(self.bounds)
        bounds.fill()
        
    }
}



//var headercolor = NSColor(red: 62/255, green: 70/255, blue: 106/255, alpha: 1)
class CustomScroller: NSScroller {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.set()
        dirtyRect.fill()
        self.drawKnob()
    }
    
    override func drawKnob() {
        var knobSlot: NSRect = rect(for: .knob)
        let orientation = self.accessibilityOrientation()
        if orientation.rawValue == 2  {
            //Horizontal
            knobSlot.size.height = 20
            knobSlot.origin.y = 4
        } else {
            knobSlot.size.width = 7
            knobSlot.origin.x = 3
        }
        
        let path = NSBezierPath(roundedRect: knobSlot, xRadius: 5, yRadius: 5)
        NSColor.black.withAlphaComponent(0.5).set()
        path.fill()
    }
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        var newRect: NSRect = slotRect
        let orientation = self.accessibilityOrientation()
        
        if orientation.rawValue == 2 {
            newRect.origin.y = 4
        } else {
            newRect.origin.x = 3
        }
        super.drawKnobSlot(in: newRect, highlight: flag)
    }
    
}

class CustomScrollerForSettiings: NSScroller {
    
    override func draw(_ dirtyRect: NSRect) {
        NSColor.tertiaryLabelColor.withAlphaComponent(0.1).set()
        dirtyRect.fill()
        self.drawKnob()
    }
    
    override func drawKnob() {
        var knobSlot: NSRect = rect(for: .knob)
        let orientation = self.accessibilityOrientation()
        if orientation.rawValue == 2  {
            //Horizontal
            knobSlot.size.height = 20
            knobSlot.origin.y = 4
        } else {
            knobSlot.size.width = 8
            knobSlot.origin.x = 3
        }
        
        let path = NSBezierPath(roundedRect: knobSlot, xRadius: 5, yRadius: 5)
        NSColor.secondaryLabelColor.set()
        path.fill()
    }
    
    override func drawKnobSlot(in slotRect: NSRect, highlight flag: Bool) {
        var newRect: NSRect = slotRect
        let orientation = self.accessibilityOrientation()
        
        if orientation.rawValue == 2 {
            newRect.origin.y = 4
        } else {
            newRect.origin.x = 3
        }
        super.drawKnobSlot(in: newRect, highlight: flag)
    }
    
}

var defaultBrowser: String? {
    NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http://")!)
        .flatMap(Bundle.init(url:))
        .flatMap {
            $0.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? $0.object(forInfoDictionaryKey: "CFBundleName")
        }.flatMap {
            $0 as? String
        }
}

var isBreakActivityShowingWhileMeeting = false

func getAppVersionInString()-> String{
    if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
        return version + "." + build
    }
    return ""
}


var appVersion = ""
var macOSVersion = ""


// **************************Font Work*******************************//
var systemFontIndex = 0
var intelOneMonoIndex = 7
var openDyslexicIndex = 8
var poppinsIndex = 9
let arrFont:[fontStyle] = [fontStyle(name: "System Font", regularFontName: "System Font", boldFontName: "System Font Bold", webFontName: "San Francisco"),
                           fontStyle(name: "Arial", regularFontName: "Arial", boldFontName: "Arial Bold", webFontName: "Arial"),
                           fontStyle(name: "Comic Sans MS", regularFontName: "Comic Sans MS", boldFontName: "Comic Sans MS Bold", webFontName: "Comic Sans MS"),
                           fontStyle(name: "Verdana", regularFontName: "Verdana", boldFontName: "Verdana Bold", webFontName: "Verdana"),
                           fontStyle(name: "Tahoma", regularFontName: "Tahoma", boldFontName: "Tahoma Bold", webFontName: "Tahoma"),
                           fontStyle(name: "Trebuchet MS", regularFontName: "Trebuchet MS", boldFontName: "Trebuchet MS Bold", webFontName: "Trebuchet MS"),
                           fontStyle(name: "Helvetica", regularFontName: "Helvetica", boldFontName: "Helvetica Bold", webFontName: "Helvetica"),
                           fontStyle(name: "IntelOneMono", regularFontName: "IntelOneMono-Regular", boldFontName: "IntelOneMono-Regular", webFontName: "Intel One Mono"),
                           fontStyle(name: "OpenDyslexic", regularFontName: "OpenDyslexicThree-Regular", boldFontName: "OpenDyslexicThree-Regular", webFontName: "Open Dyslexic"),
                           fontStyle(name: "Poppins", regularFontName: "Poppins-Regular", boldFontName: "Poppins-Regular", webFontName: "Poppins")]

struct fontStyle{
    var name = ""
    var regularFontName = ""
    var boldFontName = ""
    var webFontName = ""
    
    init(name:String, regularFontName:String, boldFontName:String, webFontName:String){
        self.name = name
        self.regularFontName = regularFontName
        self.boldFontName = boldFontName
        self.webFontName = webFontName
    }
}

let intelOneMonoFontIndex = 7
let openDyslexicFontIndex = 8
let selectedFont = arrFont[SettingsManagerObject.selectedFontIndex]

func getRegularFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.systemFont(ofSize: size)
    }
    return NSFont(name: selectedFont.regularFontName, size: size) ?? NSFont.systemFont(ofSize: size)
}
func getBoldFont(size: CGFloat)->NSFont{
    if SettingsManagerObject.selectedFontIndex == systemFontIndex{
        return NSFont.boldSystemFont(ofSize: size)
    }
    return NSFont(name: selectedFont.boldFontName, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}

// This font is from storybord change this according to user settings
extension NSTextField {//CourierNewPSMT // CourierNewPS-BoldMT
    open override func awakeFromNib() {
        super.awakeFromNib()

        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SFNS-Bold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }
}

extension NSButton {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }
}
extension NSSegmentedControl {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font?.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else if self.font?.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }else{
            font = getRegularFont(size: self.font?.pointSize ?? 24)
        }
    }
}

extension NSTabView {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font.fontName == "CourierNewPS-BoldMT"{
            font = getBoldFont(size: self.font.pointSize)
        }else if self.font.fontName == "CourierNewPSMT"{
            font = getRegularFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFontBold"{
            font = getBoldFont(size: self.font.pointSize)
        }else if self.font.fontName == ".AppleSystemUIFont"{
            font = getRegularFont(size: self.font.pointSize)
        }else if self.font.fontName == ".SF NS Regular"{
            font = getRegularFont(size: self.font.pointSize)
        }else{
            font = getRegularFont(size: self.font.pointSize)
        }
    }
}

extension NSTextView {
    open override func awakeFromNib() {
        super.awakeFromNib()
        if self.font != nil{
            if self.font!.fontName == "CourierNewPS-BoldMT"{
                font = getBoldFont(size: self.font!.pointSize)
            }else if self.font!.fontName == "CourierNewPSMT"{
                font = getRegularFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".AppleSystemUIFontBold"{
                font = getBoldFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".AppleSystemUIFont"{
                font = getRegularFont(size: self.font!.pointSize)
            }else if self.font!.fontName == ".SF NS Regular"{
                font = getRegularFont(size: self.font!.pointSize)
            }else{
                font = getRegularFont(size: self.font!.pointSize)
            }
        }else{
            font = getRegularFont(size: 13)
        }
    }
}


extension NSFont {
    
    func getFontWeight() -> NSFont.Weight {
        
        let fontAttributeKey = NSFontDescriptor.AttributeName.init(rawValue: "NSCTFontUIUsageAttribute")
        if let fontWeight = self.fontDescriptor.fontAttributes[fontAttributeKey] as? String {
            switch fontWeight {
                
            case "CTFontBoldUsage":
                return NSFont.Weight.bold
                
            case "CTFontBlackUsage":
                return NSFont.Weight.black
                
            case "CTFontHeavyUsage":
                return NSFont.Weight.heavy
                
            case "CTFontUltraLightUsage":
                return NSFont.Weight.ultraLight
                
            case "CTFontThinUsage":
                return NSFont.Weight.thin
                
            case "CTFontLightUsage":
                return NSFont.Weight.light
                
            case "CTFontMediumUsage":
                return NSFont.Weight.medium
                
            case "CTFontDemiUsage":
                return NSFont.Weight.semibold
                
            case "CTFontRegularUsage":
                return NSFont.Weight.regular
                
            default:
                return NSFont.Weight.regular
            }
        }
        
        return NSFont.Weight.regular
    }
}









func fileCreationDate(url: URL) -> Date? {
    do {
        let attr = try FileManager.default.attributesOfItem(atPath: url.path)
        return attr[FileAttributeKey.creationDate] as? Date
    } catch {
        return nil
    }
}

func checkLogFileRotation(){
    addLog(text: "func:- checkLogFileRotation")
    if let date = fileCreationDate(url: DebugLogsURL){
        print(date)
        let diffInDays = Date().interval(ofComponent: .day, fromDate: date)
        print(diffInDays)
        
        if diffInDays > 3{
            let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd")
            let oldDebugLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Logs - \(timestamp).txt")
            addLog(text: "func:- checkLogFileRotation:- log file will move")
            do{
                try  FileManager.default.moveItem(at: DebugLogsURL, to: oldDebugLogsURL)
            }catch{
                print(error)
            }
        }
        
    }
    addLog(text: "func:- checkLogFileRotation:- checkCount")
    let properties = [URLResourceKey.localizedNameKey, URLResourceKey.creationDateKey, URLResourceKey.contentModificationDateKey, URLResourceKey.localizedTypeDescriptionKey,URLResourceKey.nameKey]
    let array = try? FileManager.default.contentsOfDirectory(at: DebugLogsFolderURL!, includingPropertiesForKeys: properties, options: .skipsHiddenFiles)
    if array != nil{
        var arrayOfPath = [[String:Any]]()
        for url in array!{
            
            if url.pathExtension == "txt"{
                print(url)
                if let date = fileCreationDate(url: url){
                    arrayOfPath.append(["url":url, "date":date])
                }
            }
            
        }
        if arrayOfPath.count > 5{
            arrayOfPath = arrayOfPath.sorted(by: { ($0["date"] as! Date).compare($1["date"] as! Date) == .orderedDescending })
            
            while arrayOfPath.count > 5{
                do{
                    try FileManager.default.removeItem(at: arrayOfPath[5]["url"] as! URL)
                }catch{
                    print(error)
                }
                arrayOfPath.remove(at: 5)
            }
        }
    }
}




//*************Do not disturb enable disable work*****************//
var isDndEnabled = false
func enableDND(){
    isDndEnabled = true
    if #available(OSX 12.0, *) {
        setDoNotDisturbMonterey(enable: true)
        return
    }else{
        CFPreferencesSetValue("dndStart" as CFString, CGFloat(0) as CFPropertyList, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        CFPreferencesSetValue("dndEnd" as CFString, CGFloat(1440) as CFPropertyList, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        CFPreferencesSetValue("doNotDisturb" as CFString, true as CFPropertyList, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        commitDNDChanges()
    }
    
    
}

func disableDND(){
    isDndEnabled = false
    if #available(OSX 12.0, *) {
        setDoNotDisturbMonterey(enable: false)
        return
    }else{
        CFPreferencesSetValue("dndStart" as CFString, nil, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        CFPreferencesSetValue("dndEnd" as CFString, nil, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        CFPreferencesSetValue("doNotDisturb" as CFString, false as CFPropertyList, "com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
        
        commitDNDChanges()
    }
}
func commitDNDChanges(){
    CFPreferencesSynchronize("com.apple.notificationcenterui" as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost)
    DistributedNotificationCenter.default().postNotificationName(NSNotification.Name(rawValue: "com.apple.notificationcenterui.dndprefs_changed"), object: nil, userInfo: nil, deliverImmediately: true)
}

func setDoNotDisturbMonterey(enable: Bool) {
    
    let apps = NSWorkspace.shared.runningApplications
    
    guard let controlCenter = apps.first(where: {$0.bundleIdentifier == "com.apple.controlcenter"}) else {
        print("Control Center App not found!")
        return
    }
    
    let target = AXUIElementCreateApplication(controlCenter.processIdentifier)
    
    guard let menubar = getElement(target: target, name: "AXExtrasMenuBar") else {
        print("AXExtrasMenuBar not found!")
        return
    }
    
    guard let controlCenterMenu = getChild(parent: menubar, withTitle: "Control Centre") else {
        print("\nControl Center not found !!")
        return
    }
    
    //        print("\nControl Center\n===========")
    
    // Press the menu
    AXUIElementPerformAction(controlCenterMenu, kAXPressAction as CFString)
    
    // Now get the apps main window children since it will be showing
    guard let dialog = getElement(target: target, name: "AXFocusedWindow") else {
        print("AXFocusedWindow not found!")
        return
    }
    
    //        print("\nControl Center Window\n===========")
    
    if enable {
        if let focusMenu = getChild(parent: dialog, withTitle: "Focus") {
            
            print("\nFocus found !!")
            
            // Press the menu
            AXUIElementPerformAction(focusMenu, kAXPressAction as CFString)
            
            
        } else {
            print("\nFocus NOT found !!")
        }
    }
    else {
        if let doNotDisturbMenu = getChild(parent: dialog, withTitle: "Do Not Disturb") {
            
            print("\nDo Not Disturb found !!")
            
            // Press the menu
            AXUIElementPerformAction(doNotDisturbMenu, kAXPressAction as CFString)
            
        } else {
            print("\nDo Not Disturb NOT found !!")
        }
    }
    AXUIElementPerformAction(controlCenterMenu, kAXPressAction as CFString)
}

func getElement(target: AXUIElement, name: String) -> AXUIElement?{
    
    var attributes: CFArray? = nil
    
    AXUIElementCopyAttributeNames(target, &attributes);
    
    guard let attributes = attributes else {
        return nil
    }
    
    for attribute in attributes as NSArray {
        print(attribute as! CFString)
    }
    
    assert((attributes as NSArray).contains(name))
    
    
    var element: CFTypeRef?
    AXUIElementCopyAttributeValue(target, name as CFString, &element)
    
    guard let element = element else {
        return nil
    }
    
    return element as! AXUIElement?
}

func getChild(parent: AXUIElement, withTitle: String) -> AXUIElement? {
    
    var children: CFTypeRef?
    AXUIElementCopyAttributeValue(parent, "AXChildren" as CFString, &children)
    
    guard let children = children else {
        return nil
    }
    
    guard let items = children as? NSArray else {
        return nil
    }
    for x in items {
        let child = x as! AXUIElement
        
        var title: CFTypeRef?
        AXUIElementCopyAttributeValue(child, "AXTitle" as CFString, &title)
        
        guard let title = title else {
            continue
        }
        
        assert(CFGetTypeID(title) == CFStringGetTypeID())
        
        if ((title as! CFString) as String) == withTitle {
            
            return child
        }
    }
    
    return nil
}

func isAccessibilityEnabled(isPrompt: Bool) -> Bool {// if  isPrompt is true it means setting prompt will be visible
    if #available(OSX 12.0, *) {
        if isPrompt{
            let checkOptionPromptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
            let opts = [checkOptionPromptKey: isPrompt] as CFDictionary
            return AXIsProcessTrustedWithOptions(opts)
        }else{
            return AXIsProcessTrusted()
        }
    }else{
        return true
    }
    
}
//*********************************************************//


//************* andom color**************//
extension NSColor {
    static var random: NSColor {
        let r:CGFloat  = .random(in: 0...1)
        let g:CGFloat  = .random(in: 0...1)
        let b:CGFloat  = .random(in: 0...1)
        return NSColor(red: r, green: g, blue: b, alpha: 1)
    }
}




extension NSAlert{
    func setSharingType() {
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.window.sharingType = .none
            }
        }
    }
}


func forceCompleteIfAnyHabitGoing(){
    
    addLog(text: "get Last Activity Info - forceCompleteIfAnyActivityGoing")
    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    
    var sequenceId = ""
    if lastCurrentState == ._MORNING_HABIT_{// no need to force complete in morning routine
//        sequenceId = arrFilteredMorningHabits.first?.activity_sequence_id ?? ""
//        UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
    }else if lastCurrentState == ._FOCUS_SUMMARY_ || lastCurrentState == ._EVENING_HABIT_{
        sequenceId = arrFilteredEveningHabits.first?.activity_sequence_id ?? ""
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }
    }else{
        addLog(text: "force Complete Current Sequence - no Sequence found to complete")
        return
    }
    
    if sequenceId.isEmpty{
        addLog(text: "force Complete Current Sequence - SequenceId is blank :- return")
        return
    }
    addLog(text: "force Complete Current Sequence - forceCompleteIfAnyActivityGoing")
    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
        
        // and strt break activity
        DispatchQueue.main.async {
            
        }
    })
    
    
}



// zip a folder 
public extension URL {
    
    /// Creates a zip archive of the file/folder represented by this URL and returns a references to the zipped file
    ///
    /// - parameter dest: the destination URL; if nil, the destination will be this URL with ".zip" appended
    func zip(dest: URL) throws -> URL {
        let destURL = dest// ?? self.URLByAppendingPathExtension("zip")
        
        let fm = FileManager.default
        if fm.fileExists(atPath: destURL.path){
            do{
                try fm.removeItem(at: destURL)
            }catch{
                print(error.localizedDescription)
            }
        }
        var isDir: ObjCBool = false
        
        let srcDir: URL
        let srcDirIsTemporary: Bool
        let path = self.path //{
        
        srcDir = self
        srcDirIsTemporary = false
        
        let coord = NSFileCoordinator()
        var error: NSError?
        
        // coordinateReadingItemAtURL is invoked synchronously, but the passed in zippedURL is only valid
        // for the duration of the block, so it needs to be copied out
        coord.coordinate(readingItemAt: srcDir as URL, options: NSFileCoordinator.ReadingOptions.forUploading, error: nil) { (zippedURL: URL) -> Void in
            do {
                try fm.copyItem(at: zippedURL, to: destURL as URL)
            } catch let err {
                error = err as NSError
            }
        }
        
        if srcDirIsTemporary { try fm.removeItem(at: srcDir as URL) }
        if let error = error { throw error }
        return destURL
    }
    
    
}
func zipTextFile(inputFilePath: String, outputZipPath: String) throws {
    let fm = FileManager.default
    if fm.fileExists(atPath: outputZipPath){
        do{
            try fm.removeItem(atPath: outputZipPath)
        }catch{
            print(error.localizedDescription)
        }
    }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    // Define arguments for the `zip` command
    let fileName = (inputFilePath as NSString).lastPathComponent
    process.arguments = ["-j", outputZipPath, inputFilePath]
    
    // Run the process
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("Zipped file created at \(outputZipPath)")
    } else {
        throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to zip file."])
    }
}





var arrAllTracks = [[String:Any]]()

func checkAllTracksDownloadState(){
    for track in arrAllTracks{
        let thumbnailLocalUrlString = track["thumbnailLocalUrl"] as? String ?? ""
        let thumbnailLocalUrl = URL(fileURLWithPath: thumbnailLocalUrlString)
        let thumbnail_download_urlString = track["thumbnail_download_url"] as? String ?? ""
        let thumbnail_download_url = URL(string: thumbnail_download_urlString)//URL(fileURLWithPath: download_urlString)
        
        if !FileManager.default.fileExists(atPath: thumbnailLocalUrlString){
            allApiObject.downloadFileAsync(url: thumbnail_download_url, destinationUrl: thumbnailLocalUrl){ (success, error) in
                checkAllTracksDownloadState()
                DispatchQueue.main.async {
                    if allTracksVcObj != nil && allTracksWindowControllerObj != nil{
                        if allTracksWindowControllerObj?.window?.isVisible ?? false{
                            allTracksVcObj?.tblView.reloadData()
                        }
                    }
                }
            }
            break;
        }
    }
}

func shouldDoHabits()->Bool{//after onboarding cards morning evening routine should not show till 2 hours
    if let date = UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) as? Date{
        let currentDate = Date()
        let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
        if diffHours > 1{//it means after onboarding cards morning evening routine will not show till 2 hours
            return true
        }else{
            return false
        }
    }
    return true
}


extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}



func getLastHabitDoneDuration(lastHabit:habit)->Int{
    var duration = 0
    if lastHabit.useTimer{
        duration = lastHabit.durationSeconds!
    }else{
        duration = Calendar.current.dateComponents([.second], from: lastActivityPerformedTime!, to: Date()).second ?? 0
    }
    return duration
}


func getLastActivityDoneDuration(lastActivity:breakActivity)->Int{
    var duration = 0
    if lastActivity.useTimer{
        duration = lastActivity.durationSeconds!
    }else{
        duration = Calendar.current.dateComponents([.second], from: lastActivityPerformedTime!, to: Date()).second ?? 0
    }
    return duration
}


var arrForSearchFromSettings = [[String:Any]]()
var arrForSearchFromSimpleModeSettings = [[String:Any]]()

var arrAlwaysBlockedSitesData = [[String:Any]]()
var arrAlwaysBlockedAppsData = [[String:Any]]()

var defaultBreakDurationValue = 20

var macGoesInSleepTime:Date?
var shouldShowPomodoroAfterBreak = false
var shouldEndPomodoroBreakAtTime:Date?


var arrFocusBlockNotificationShownForApps = [""]


func executeScript(script:String){
    if let appleScript = NSAppleScript(source: script) {
        var errors : NSDictionary? = nil
        appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors!)
        }
    }
}

func executeScriptAndReturnBool(script:String)->Bool{
    if let appleScript = NSAppleScript(source: script) {
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors!)
        }
        return desc.booleanValue
    }
    return false
}

func executeScriptAndReturnString(script:String)->String?{
    if let appleScript = NSAppleScript(source: script) {
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors!)
            if let appName = errors?.value(forKey: "NSAppleScriptErrorAppName") as? String, let errorCode = errors?.value(forKey: "NSAppleScriptErrorNumber") as? Int{
                let lowerCaseAppName = appName.lowercased()
                if let browser = getCurrentBrowserFrom(browserName: lowerCaseAppName){
                    if errorCode == -1743{
                        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
                            for i in 0..<arrBrowsersInfo.count{
                                let info = arrBrowsersInfo[i]
                                let browserRawValue = info["browser"] as? Int ?? 0
                                if browser.rawValue == browserRawValue{
                                    arrBrowsersInfo[i]["isEnabled"] = false
                                    break;
                                }
                            }
                            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
                        }
                        return nil
                    }else if desc.stringValue == nil{// && errorCode == -1719{// doing this beacuse in gogle chrome in slect profile screen we can't get url so handle this situation and return a blank string so ask permission alert will not be visible  again for chrome
                        return ""
                    }
                }
            }
        }
        return desc.stringValue ?? ""
    }
    return nil
}

func showFocusAppBlockNotification(appName:String){
    addLog(text: "show Focus App Block Notification called")
    if arrFocusBlockNotificationShownForApps.contains(appName){
        addLog(text: "func showFocusAppBlockNotification:- Notification already shown:- return")
        return;
    }
    let arrAppsAvoidNotification = ["loginwindow", "screensaverengine"]//lowercased
    
    if arrAppsAvoidNotification.contains(appName.lowercased()){
        addLog(text: "func showFocusAppBlockNotification:- AppsAvoidNotification contain app:- return")
        return;
    }
    arrFocusBlockNotificationShownForApps.append(appName)
    var msg = "<APP_NAME> isn't allowed in the <FOCUS_NAME> focus mode."
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        msg = common.value(forKey: "appBlockNotificationTitle") as? String ?? msg
    }
    
    var focusMode = ""
    
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            focusMode = dic["name"] as? String ?? ""
            break;
        }
    }
    addLog(text: "func showFocusAppBlockNotification:- show notification for app:- \(appName)")
    msg = msg.replacingOccurrences(of: "<APP_NAME>", with: appName)
    msg = msg.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
    showNotificationWithMessage(msg: msg)
}

//*******************GET APP APPEARANCE******************//

func getAppAppearance()->NSAppearance?{
    var appearance: NSAppearance?
    switch SettingsManagerObject.selectedAppAppearanceIndex {
    case 0:
        appearance = NSApp!.appearance
    case 1:
        appearance = NSAppearance(named: .darkAqua)
    case 2:
        appearance = NSAppearance(named: .aqua)
    default:
        break;
    }
    return appearance
}

//*******************CUSTOM SLIDER CLASS ******************//

class CustomSliderCell: NSSliderCell {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override func drawBar(inside aRect: NSRect, flipped: Bool) {
        var rect = aRect
        rect.size.height = aRect.height
        let barRadius = CGFloat(2.5)
        let value = CGFloat((self.doubleValue - self.minValue) / (self.maxValue - self.minValue))
        let finalWidth = CGFloat(value * (self.controlView!.frame.size.width - 8))
        var leftRect = rect
        leftRect.size.width = finalWidth
        let bg = NSBezierPath(roundedRect: rect, xRadius: barRadius, yRadius: barRadius)
        NSColor.lightGray.setFill()
        bg.fill()
    }
}
class CustomSlider: NSSlider {
    init() {
        super.init(frame: NSZeroRect)
        addFilter()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addFilter()
    }
    
    func addFilter() {
        let colorFilter = CIFilter(name: "CIFalseColor")!
        colorFilter.setDefaults()
        colorFilter.setValue(CIColor(cgColor: NSColor.lightGray.cgColor), forKey: "inputColor1")
        self.contentFilters = [colorFilter]
    }
}
//------------------------------------------------------------------------//


//******GET OR CREATE FOCUS MODE TAG ID********//

func getIdForTag(tag:String)->String{
    for tagInfo in arrAllFocusModeTags{
        if let oldTag = tagInfo["text"]{
            if oldTag.lowercased() == tag.lowercased(){
                return tagInfo["id"] ?? getUuid()
            }
        }
    }
    let id = getUuid()
    arrAllFocusModeTags.append(["id": id, "text": tag])
    return id
}
//------------------------------------------------------------------------//


//*********************POMODORO SHORTCUT WORK***********************//
var char = ""
var flags = NSEvent.modifierFlags
enum shortcutFlags:Int{
    case _COMMAND_ = 11, _CONTROL_, _OPTION_, _SHIFT_
}


func updateFlags(sflags:[Int]){
    flags = NSEvent.modifierFlags
    for falg in sflags{
        if falg == shortcutFlags._CONTROL_.rawValue{
            flags.update(with: .control)
        }
        if falg == shortcutFlags._OPTION_.rawValue{
            flags.update(with: .option)
        }
        if falg == shortcutFlags._SHIFT_.rawValue{
            flags.update(with: .shift)
        }
        if falg == shortcutFlags._COMMAND_.rawValue{
            flags.insert(.command)
        }
    }
}
//------------------------------------------------------------------------//




extension NSWindow {
    var hasDarkAppearance: Bool {
        if #available(OSX 10.14, *) {
            switch effectiveAppearance.name {
            case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark:
                return true
            default:
                return false
            }
        } else {
            switch effectiveAppearance.name {
            case .vibrantDark:
                return true
            default:
                return false
            }
        }
    }
}


func calculateBackoffWithJitter(baseDelayMs: Int, retry: Int) -> Int {
    addLog(text: "CalculateBackoffWithJitter()")
    let maxDelayMs = 120000 // Maximum delay in milliseconds
    let exponentialDelay = Int(pow(2.0, Double(retry)) * Double(baseDelayMs))
    let jitter = Int.random(in: 1...baseDelayMs/2)  // Adding jitter within half of the base delay
    let delayMs = min(exponentialDelay + jitter, maxDelayMs)
    return delayMs
}



extension NSView {

    var backgroundcolor: NSColor? {
        get {
            guard let layer = layer, let backgroundColor = layer.backgroundColor else { return nil }
            return NSColor(cgColor: backgroundColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }

}


func writeStringToHabitInfo(isFinishTime:Bool, activityName:String){
    var outString = ""
    if isFinishTime{
        outString = "finishTime:"
    }else{
        outString = "startTime:"
    }
    
    let time = getStringFromDate(date:Date(), dateFormat:"yyyy-MM-dd HH-mm-ss")
    outString =  outString + time
    
    outString = outString + ",name:" + activityName
    writeSettingForScreeenTime(habitInfo: outString)
}

func writeSettingForScreeenTime(habitInfo:String){
    var language = "es"
    language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String ?? language
    var isScreenTimeEnabled = false
    isScreenTimeEnabled = UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool ?? isScreenTimeEnabled
     
    var dicContent = ["language":language, "isScreenTimeEnabled":isScreenTimeEnabled, "habitInfo":habitInfo, "userID":appdelegate!.user?.userId ?? "", "isPurchased":isPurchased, "startup_time":startTimeString, "shutdown_time":shutOffTimeString, "cutoff_time":cutOffTimeString, "isUserOnMeeting":appdelegate!.isUserOnMeeting] as [String : Any]
    
    if appdelegate?.isUserOnMeeting ?? false{
        if let meetingStartTime = appdelegate?.meetingStartTime{
            let time = getStringFromDate(date: meetingStartTime, dateFormat:"yyyy-MM-dd HH-mm-ss")
            dicContent["meetingStartTime"] = time
        }
    }
    
    let plistContent = NSDictionary(dictionary: dicContent)
    let _ = plistContent.write(toFile: settingForScreeenTimeFileURL!.path, atomically: true)
}


func enableTimeTracker(){
    allApiObject.capturePosthog(event: "settings-changed-enable-time-tracker", metadata: [:])
    UserDefaults.standard.set(true, forKey: kUserdefaultsScreenTimeEnabled)
    UserDefaults.standard.set(true, forKey: kUserdefaultsScreenTimeEnabledOneTime)
    UserDefaults.standard.set(true, forKey: kUserdefaultsEnableScreenTimeShown)
    
    let appPath = "/Applications/Focus Bear Time Tracker.app"
    let configuration = NSWorkspace.OpenConfiguration()//.arguments = [appPath]
    NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: appPath), configuration: configuration)
    writeSettingForScreeenTime(habitInfo: "")
}




extension Date {
    static var yesterday: Date { return Date().dayBefore }
    static var tomorrow:  Date { return Date().dayAfter }
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
    var month: Int {
        return Calendar.current.component(.month,  from: self)
    }
    var isLastDayOfMonth: Bool {
        return dayAfter.month != month
    }
}



var lastAppUnlockTime:Date?

func shouldAskPassword()->Bool{
    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
        if let lastAppUnlockTime = lastAppUnlockTime{
            let diffSeconds = Calendar.current.dateComponents([.second], from: lastAppUnlockTime, to: Date()).second ?? 0
            if diffSeconds > 120{
                return true
            }else{
                return false
            }
        }else{
            return true
        }
    }
    return false
}

func isPasswordRequireInOpenSettings() -> Bool{
    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
        if let lastAppUnlockTime = lastAppUnlockTime{
            let diffSeconds = Calendar.current.dateComponents([.second], from: lastAppUnlockTime, to: Date()).second ?? 0
            if diffSeconds > 120{
                return isPasswordRequireInOpenSettingsEnabled()
            }else{
                return false
            }
        }else{
            return isPasswordRequireInOpenSettingsEnabled()
        }
    }
    return false
}

func isPasswordRequireInOpenSettingsEnabled() -> Bool{
    //Super strict focus sessions should block changing settings #1423
    if isFocusModeOn(){
        if !isCuddlyModeEnabled(){
            return true
        }
    }
    //
    
    if isCutOffTimeGoing(){
        if SettingsManagerObject.isPasswordRequireInPreferencesAfterCutoff{
            return true
        }
    }else{
        if SettingsManagerObject.isPasswordRequireInChangeSettings{
            return true
        }
    }
    return false
}


extension String {
    var length:Int {
        return self.count
    }
    func indexOf(target: String) -> Int? {
        let range = (self as NSString).range(of: target)
        guard range.toRange() != nil else {
            return nil
        }
        return range.location
    }
    func lastIndexOf(target: String) -> Int? {
        let range = (self as NSString).range(of: target, options: NSString.CompareOptions.backwards)
        
        guard range.toRange() != nil else {
            return nil
        }
        return self.length - range.location - 1
    }
    func contains(s: String) -> Bool {
        return (self.range(of: s) != nil) ? true : false
    }
}




func randomString(length: Int) -> String {
  let letters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}


var defaultStartTime = "08:30"
var defaultShutDownTime = "18:30"
var defaultSleepTime = "21:30"



//--------------------------------custom New Item Badge Box----------------------------//

class customNewBadgeBox: NSBox {
    var mouseDown = false
    var tagValue = 0
    var isTableView = false
    var label:NSTextField!
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.boxType = .custom
        self.borderWidth = 0
        self.cornerRadius = self.frame.height / 2
        self.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        var newBadgeText = "New"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            newBadgeText = common.value(forKey: "newBadgeText") as? String ?? newBadgeText
        }
        label = NSTextField(string: newBadgeText)
        label.isBordered = false
        label.backgroundColor = NSColor.clear
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = NSColor.black
        label.isEditable = false
        label.isSelectable = false
        self.addSubview(label)
        self.addVerticalCenterConstraints(subView: label)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseDown(with event: NSEvent) {
        // super.mouseDown(with: event)
        print("mouse down")
        if isTableView{
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }else{
            super.mouseDown(with: event)
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouse up")
        if mouseDown {
            mouseDown = false
            
            NSCursor.pointingHand.set()
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }else{
            return;
        }
    }
    

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}
//--------------------------------Onboarding Progress----------------------------//

func showOnboardingProgress(view:NSView, progress:Int){
    view.addSubview(getOnboardingProgressVcObj().view)
    view.addBottomRightConstraints(subView: getOnboardingProgressVcObj().view)
    onboardingProgressVcObj?.resetData(progress: progress)
}
func hideOnboardingProgress(view:NSView){
    if onboardingProgressVcObj != nil{
        if view.subviews.contains(getOnboardingProgressVcObj().view){
            getOnboardingProgressVcObj().view.removeFromSuperview()
        }
    }
}
//-------------------------------------------------------------------------//

//--------------------------------Onboarding Bell icon----------------------------//

func showOnboardingBellIcon(view:NSView, screen:String){
    view.addSubview(getBellVcObj().view)
    view.addBottomLeftConstraints(subView: getBellVcObj().view)
    bellVcObj?.screen = screen
}
func hideOnboardingBellIcon(view:NSView){
    if bellVcObj != nil{
        if view.subviews.contains(getBellVcObj().view){
            getBellVcObj().view.removeFromSuperview()
        }
    }
}
//-------------------------------------------------------------------------//



//Fix posthog identify call#884//
//--------------------------------globalUUID----------------------------//
var globalUUID = ""

func checkAndGetGlobalUUID(){
    if let id = UserDefaults.standard.object(forKey: kUserdefaultsGlobalUUID) as? String{
        globalUUID = id
    }else{
        globalUUID = "fake-" + getUuid()
        UserDefaults.standard.set(globalUUID, forKey: kUserdefaultsGlobalUUID)
    }
}

func deleteGlobalUUID(){
    globalUUID = ""
    UserDefaults.standard.removeObject(forKey: kUserdefaultsGlobalUUID)
}

func connectGlobalAndMacIDWithDistinctUserID(){
    kUserdefaultsIsGlobalUUIDLinked = kUserdefaultsIsGlobalUUIDLinked + (appdelegate!.user?.userId ?? "")
    kUserdefaultsIsMacIdLinked = kUserdefaultsIsMacIdLinked + (appdelegate!.user?.userId ?? "")
    
    if UserDefaults.standard.object(forKey: kUserdefaultsIsGlobalUUIDLinked) == nil{
        allApiObject.capturePosthogIdentify(sAliasID: globalUUID, completionHandler: {boolValue in
            if boolValue{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsGlobalUUIDLinked)
                deleteGlobalUUID()
            }
        })
    }
    if UserDefaults.standard.object(forKey: kUserdefaultsIsMacIdLinked) == nil{
        allApiObject.capturePosthogIdentify(sAliasID: macAddress, completionHandler: {boolValue in
            if boolValue{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsMacIdLinked)
            }
        })
    }
}


//-------------------------------------------------------------------------//


func setAppIconForFocusModeScore(probability:Double?){
    if probability == nil{
        setFocusBearIconToNormal()
        focusModeCloseCurrentUrlForAlignmentScore()
        focusModeCloseCurrentAppForAlignmentScore()
    }else{
        if probability! >= 0.70{
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("productive_icon"))
        }else{
            appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("notProductive_icon"))
        }
    }
}
func setFocusBearIconToNormal(){
    boxForStatusBarForTooltip?.customToolTip = ""
    if SettingsManagerObject.isOfficeModeEnabled{
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
    }else{
        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
    }
}




var boxForStatusBar: customStatusBarBox!
class customStatusBarBox: NSBox {
    var count = 0
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if count == 0{
            count = 1
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if isPurchased == false && daysLeft <= 0{
            return;
        }
        if !SettingsManagerObject.isGeekModeEnabled{
            return;
        }
        if appdelegate?.popover.isShown ?? false{
            return;
        }
        
        if !NSEvent.modifierFlags.contains(.control){
            return;
        }
        getBlankLayerWcObject().showWindow(nil)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        
    }
}

var boxForStatusBarForTooltip: customStatusBarBoxForTooltip!
class customStatusBarBoxForTooltip: NSBox {
    var count = 0
    var customToolTip = ""
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if count == 0{
            count = 1
            addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        }
    }
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        if appdelegate?.popover.isShown ?? false{
            return;
        }
        if !self.customToolTip.isEmpty{
            showTooltip(sender: self, msg: customToolTip, preferredEdge: .minY, maxWidthVal: 300)
        }else if appdelegate!.isUserOnMeeting{
            if !SettingsManagerObject.IsShowBreaksInCallEnabled{
                var toolTipMeetingsText = "We've detected that you're in a video call and won't show breaks during this time"
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    toolTipMeetingsText = common.value(forKey: "toolTipMeetingsText") as? String ?? toolTipMeetingsText
                }
                showTooltip(sender: self, msg: toolTipMeetingsText, preferredEdge: .minY, maxWidthVal: 300)
            }
        }else{
            print("customToolTip is blank")
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        if popoverTooltip != nil{
            if popoverTooltip!.isShown{
                popoverTooltip?.close()
            }
        }
    }
}



//************************json for new params in block script*************************//

var totalFocuseTime:Double = 0
var totalDeepFocusedTime:Double = 0 // according to alignment score %
var arrLongTermGoals = [String]()
func getTotalFocuedTime(){
    totalFocuseTime = 0
    totalDeepFocusedTime = 0
    allApiObject.getAllActivityDaySummary(completionHandler: {dic in
        if allActivityTodaySummaryData != nil{
            if let arr = allActivityTodaySummaryData!.value(forKey: "focusSummary") as? [[String:Any]]{
                for item in arr{
                    let duration = item["duration"] as? Double ?? 0
                    totalFocuseTime += duration
                    
                    if let metadata = item["metadata"] as? [String:Any]{
                        if let focus_alignment_score = metadata["focus_alignment_score"] as? String{ 
                            let score = Double(focus_alignment_score) ?? 0
                            let deepWorkDuration = (duration * score) / 100
                            totalDeepFocusedTime += deepWorkDuration
                        }else{
                            totalDeepFocusedTime += duration
                        }
                    }
                    
                }
            }
        }
    })
}


func getAllLongTermGoals(){
    arrLongTermGoals.removeAll()
    allApiObject.getuserLongTermGoals(completionHandler: {arrGoals in
        if let arrGoals = arrGoals{
            arrLongTermGoals = arrGoals
        }
    })
}
func getGoalsAndFocusdJsonForBlockedScript()-> String{
    let json: [String: Any] = [
        "focused_time": totalFocuseTime,
        "long_term_goals": arrLongTermGoals
    ]
    var jsonString =  String(describing: json)
    jsonString = jsonString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? jsonString
    do {
        let jsonResultData =  try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
        if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
            return backToString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? backToString
        }
    } catch let myJSONError {
        print(myJSONError)
    }
    
    return jsonString
}




protocol toggleButtonBoxDelegate {
    func toggleButtonBoxClicked(box:NSBox)
}
class toggleButtonBox: NSBox {
    var mouseDown = false
    var isSelected = false
    var customDelegate: toggleButtonBoxDelegate?
    var normalColor = NSColor(red: 204/255, green: 204/255, blue: 204/255, alpha: 1)
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.fillColor = buttonBgColor
        NSCursor.pointingHand.set()
    }
    override func mouseDown(with event: NSEvent) {
        // super.mouseDown(with: event)
        print("mouse down")
        mouseDown = true
        self.fillColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        NSCursor.pointingHand.set()
        
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        print("mouse up")
        if mouseDown {
            mouseDown = false
            NSCursor.pointingHand.set()
            self.fillColor = buttonBgColor
            self.isSelected = true
            self.borderWidth = 1
            self.borderColor = .separatorColor
            customDelegate?.toggleButtonBoxClicked(box:self)
        }

    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        mouseDown = false
        NSCursor.arrow.set()
        if !isSelected{
            self.fillColor = normalColor
        }
    }
}







class GeekModeSegmentedControl: NSSegmentedControl {

    var segmentGeekModeTrackingArea: NSTrackingArea?
    let geekModeIndex = 0
    let simpleModeIndex = 1
    var isMenuButton = false
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectedSegmentBezelColor = NSColor(named: "dark_OrangeColor") ?? NSColor.blue
        
        var titleGeekMode = "🤓 Geek Mode"
        var titleSimpleMode = "😎 Simple Mode"
        
        if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
            titleGeekMode = geekModeInfo.value(forKey: "titleGeekMode") as? String ?? titleGeekMode
            titleSimpleMode = geekModeInfo.value(forKey: "titleSimpleMode") as? String ?? titleSimpleMode
        }
        self.setLabel(titleGeekMode, forSegment: geekModeIndex)
        self.setLabel(titleSimpleMode, forSegment: simpleModeIndex)
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        segmentGeekModeTrackingArea = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.addTrackingArea(segmentGeekModeTrackingArea!)
        
        
        let customBox = NSBox()
        customBox.boxType = .custom
        customBox.borderWidth = 0
        customBox.fillColor = NSColor.clear
        self.superview?.addSubview(customBox)
//        self.addConstraints(subView: customBox)
        
        
        customBox.translatesAutoresizingMaskIntoConstraints = false
        //Trailing
        let trailing = NSLayoutConstraint(item: customBox, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        //Leading
        let leading = NSLayoutConstraint(item: customBox, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        //Bottom
        let bottom = NSLayoutConstraint(item: customBox, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        //Height to be fixed for SubView same as AdHeight
        let height = NSLayoutConstraint(item: customBox, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        self.superview?.addConstraint(trailing)
        self.superview?.addConstraint(bottom)
        self.superview?.addConstraint(leading)
        //Add height constraint to the subview, as subview owns it.
        self.superview?.addConstraint(height)
        
    }

    
    override func mouseEntered(with event: NSEvent) {
        if SettingsManagerObject.isGeekModeEnabled{
            var tooltipGeekMode = "Geek Mode active! Advanced features activated. Overwhelmed? Toggle the switch to go back to Simple Mode"
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                tooltipGeekMode = geekModeInfo.value(forKey: "tooltipGeekMode") as? String ?? tooltipGeekMode
            }
            showTooltip(sender: self, msg: tooltipGeekMode, preferredEdge: NSRectEdge.minX, maxWidthVal:230)
        }else{
            var tooltipSimpleMode = "Simple Mode active - only basic features shown. Toggle the switch to activate Geek Mode"
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                tooltipSimpleMode = geekModeInfo.value(forKey: "tooltipSimpleMode") as? String ?? tooltipSimpleMode
            }
            showTooltip(sender: self, msg: tooltipSimpleMode, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
        }
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == segmentGeekModeTrackingArea{
            if popoverTooltip != nil{
                if popoverTooltip!.isShown{
                    popoverTooltip?.close()
                }
            }
        }
        NSCursor.arrow.set()
    }
    
    func changeAppModeTo(geekMode:Bool){
        //--------------------------------------------------------------------//
        //Support freemium#1066
        //only simple mode allowed
        addLog(text:"func changeAppModeTo geekMode \(geekMode)")
        if isExpired && geekMode{
            var titleNoGeekMode = "Geek mode is only supported in Pro edition."
            if let upgradeToProNagVcInfo = configjson.value(forKey: "upgradeToProNagVcInfo") as? NSDictionary{
                titleNoGeekMode = upgradeToProNagVcInfo.value(forKey: "titleNoGeekMode") as? String ?? titleNoGeekMode
            }
            showUpgradeToProNagWindow(titleText: titleNoGeekMode, reason: "activate_geek_mode")
            if SettingsManagerObject.isGeekModeEnabled{
                self.setSelected(true, forSegment: 0)
            }else{
                self.setSelected(true, forSegment: 1)
            }
            return;
        }
        //-----------------------------------------------------------------------//
        if SettingsManagerObject.isGeekModeEnabled == geekMode{
            return;
        }
        
        if geekMode{
            let dontShowGeekModeConfirmAlert = UserDefaults.standard.object(forKey: kUserdefaultsDontShowConfirmGeekModeAlert) as? Bool ?? false
            if !dontShowGeekModeConfirmAlert{
                allApiObject.capturePosthog(event: "waiting-to-confirm-wants-to-switch-to-geek-mode", metadata: [:])
                
                var alertConfirmSwitchGeekMode = "Geek Mode activates a lot more features and can be overwhelming. We recommend you stick with Simple Mode for the first few days."
                var buttonActivateGeekModeText = "Activate Geek Mode"
                var buttonStickSimpleModeText = "Stick with Simple Mode"
                var buttonDontShowAgainText = "Don't show again"
                var alertConfirmSwitchGeekModeDescription = "You can switch the modes from Preferences -> Settings tab"
                
                if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                    alertConfirmSwitchGeekMode = geekModeInfo.value(forKey: "alertConfirmSwitchGeekMode") as? String ?? alertConfirmSwitchGeekMode
                    buttonActivateGeekModeText = geekModeInfo.value(forKey: "buttonActivateGeekModeText") as? String ?? buttonActivateGeekModeText
                    buttonStickSimpleModeText = geekModeInfo.value(forKey: "buttonStickSimpleModeText") as? String ?? buttonStickSimpleModeText
                    buttonDontShowAgainText = geekModeInfo.value(forKey: "buttonDontShowAgainText") as? String ?? buttonDontShowAgainText
                    alertConfirmSwitchGeekModeDescription = geekModeInfo.value(forKey: "alertConfirmSwitchGeekModeDescription") as? String ?? alertConfirmSwitchGeekModeDescription
                }
            
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = alertConfirmSwitchGeekMode
                if isMenuButton{
                    alert.informativeText = alertConfirmSwitchGeekModeDescription
                }
                alert.addButton(withTitle: buttonStickSimpleModeText)
                alert.addButton(withTitle: buttonActivateGeekModeText)
                
                alert.showsSuppressionButton = true
                alert.suppressionButton?.title = buttonDontShowAgainText
                NSApplication.shared.activate(ignoringOtherApps: true)
                let result = alert.runModal()
                if result == .alertFirstButtonReturn{
                    self.setSelected(true, forSegment: 1)
                    allApiObject.capturePosthog(event: "stick-to-simple-mode", metadata: [:])
                }else if result == .alertSecondButtonReturn{
                    SettingsManagerObject.isGeekModeEnabled = geekMode
                    appModeChangeDone(geekMode: geekMode)
                }
                if alert.suppressionButton?.state == .on{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsDontShowConfirmGeekModeAlert)
                }
            }else{
                SettingsManagerObject.isGeekModeEnabled = geekMode
                appModeChangeDone(geekMode: geekMode)
            }
        }else{
            SettingsManagerObject.isGeekModeEnabled = geekMode
            appModeChangeDone(geekMode: geekMode)
        }
    }
    
    func appModeChangeDone(geekMode:Bool){
        if !geekMode{
            SettingsManagerObject.isCuddlyModeEnabled = true
        }else{
            // doing this because in simple mode when user start a pomodoro mode with blocking style (AI) we change local var isAiCheckUrlEnabled to true and if user starts pomodoro with blockDistractingsites/apps focus mode we change isAiCheckUrlEnabled to false but doesn't upload it so when user change app mode to geek mode we need to reload this setting from userdefaults
            if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAiCheckUrlEnabled) as? Bool{
                SettingsManagerObject.isAiCheckUrlEnabled = isEnabled
            }
        }
        SettingsManagerObject.isSettingsChanged = true
        
        if isFocusBearMenuVisible(){
            menuViewControllerObj?.reloadData()
        }
        if SettingsManagerObject.isGeekModeEnabled{
            preferencesSettingsIndex = 3
            preferencesEditHabitsIndex = 4
            preferencesBlocksIndex = 2
            leftMenuVcObj?.boxFocusModeSettings.isHidden = false
        }else{
            preferencesSettingsIndex = 2
            preferencesEditHabitsIndex = 3
            preferencesBlocksIndex = 1
            leftMenuVcObj?.boxFocusModeSettings.isHidden = true
        }
//        if preferencesWindowControllerObj?.window?.isVisible ?? false{ //  rmeove this block 
//            if let tabview = preferencesWindowControllerObj?.contentViewController as? preferencesTabViewController{
//                tabview.reloadDataForAppMode()
//                let tabViewItem = tabview.tabViewItems[tabview.selectedTabViewItemIndex]
//                if tabViewItem.identifier as? String == idSettings{
//                    settingsSideBarVcObj?.reloadDataForAppMode()
//                    if geekMode{
//                        settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: geekModeIndex)
//                    }else{
//                        settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: simpleModeIndex)
//                    }
//                    
//                    let selectedRow = settingsSideBarVcObj?.tblView.selectedRow ?? 0
//                    let arrSettingsList = settingsSideBarVcObj?.arrSettingsList ?? []
//                    let id = arrSettingsList[selectedRow]["id"] as? String ?? ""
//                    
//                    switch id {
//                    case idUi:
//                        uIVcObj?.reloadDataForAppMode()
//                    case idAccesibility:
//                        break;
//                    case idAi:
//                        break;
//                    case idPomodoro:
//                        break;
//                    case idStrictness:
//                        strictnessVcObj?.reloadDataForAppMode()
//                    case idAdvanced:
//                        break;
//                    case idAccount:
//                        break;
//                    case idUninstall:
//                        break;
//                    case idPermissions:
//                        break;
//                    default:
//                        break;
//                    }
//                }
//                
//            }
//        }
        if leftMenuVcObj?.boxSettings.isSelected ?? false{
            settingsSideBarVcObj?.reloadDataForAppMode()
            if geekMode{
                settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: geekModeIndex)
            }else{
                settingsContainerVcObj?.segmentControlGeekMode.setSelected(true, forSegment: simpleModeIndex)
            }
            
            let selectedRow = settingsSideBarVcObj?.tblView.selectedRow ?? 0
            let arrSettingsList = settingsSideBarVcObj?.arrSettingsList ?? []
            let id = arrSettingsList[selectedRow]["id"] as? String ?? ""
            
            switch id {
            case idUi:
                uIVcObj?.reloadDataForAppMode()
            case idAccesibility:
                break;
            case idAi:
                break;
            case idPomodoro:
                break;
            case idStrictness:
                strictnessVcObj?.reloadDataForAppMode()
            case idAdvanced:
                break;
            case idAccount:
                break;
            case idUninstall:
                break;
            case idPermissions:
                break;
            default:
                break;
            }
        }
        
        if SettingsManagerObject.isGeekModeEnabled{
            allApiObject.capturePosthog(event: "switch-to-geek-mode", metadata: [:])
        }else{
            allApiObject.capturePosthog(event: "switch-to-simple-mode", metadata: [:])
        }
        
        if !geekMode{
            var msg = "Simple Mode active - only basic features shown. Focus modes, pomodoros etc. are no longer available. Toggle the switch to go back to Geek Mode."
            if let geekModeInfo = configjson.value(forKey: "geekModeInfo") as? NSDictionary{
                msg = geekModeInfo.value(forKey: "alertSimpleModeEnabled") as? String ?? msg
            }
            let alert = NSAlert()
            alert.setSharingType()
            alert.messageText = msg
            alert.addButton(withTitle: buttonOkText)
            NSApplication.shared.activate(ignoringOtherApps: true)
            alert.runModal()
        }
    }
}


func exitFullScreen(runningApp:NSRunningApplication){
    var script: String = ""
    let appName = runningApp.localizedName ?? ""
    script =
        """
        tell application "System Events" to tell process "\(appName)"
        set fullScreenStatus to value of attribute "AXFullScreen" of window 1
        if fullScreenStatus then
        tell application "System Events" to tell process "\(appName)"
        set value of attribute "AXFullScreen" of window 1 to false
        end tell
        end if
        end tell
        """
    
    
    executeScript(script: script)
}

func isRunningAppFullScreen(runningApp:NSRunningApplication, browser: BROWSER?)->Bool{
    if let browser = browser {
        if browser == ._GOOGLE_CHROME_{
            return isChromeFullScreen(runningApp:runningApp)
        }
    }
    var script: String = ""
    let appName = runningApp.localizedName ?? ""
    script =
        """
        tell application "System Events" to tell process "\(appName)"
        set fullScreenStatus to value of attribute "AXFullScreen" of window 1
        end tell
        """
    return executeScriptAndReturnBool(script: script)
}

func isChromeFullScreen(runningApp:NSRunningApplication) -> Bool {
    var script: String = ""
    let appName = runningApp.localizedName ?? ""
    script =
    """
    tell application "System Events"
    tell process "\(appName)"
    set windowCount to count of windows
    repeat with i from 1 to windowCount
    try
    set fullScreenStatus to value of attribute "AXFullScreen" of window i
    if fullScreenStatus is true then
    return true
    end if
    end try
    end repeat
    end tell
    end tell
    return false
    """
                        
    return executeScriptAndReturnBool(script: script)
}



extension NSTextField {
    var isFirstResponder: Bool {
        currentEditor() == window?.firstResponder
    }
}




class DashedView:NSView {
    var isFirst = true
    let yourViewBorder = CAShapeLayer()
    override func draw(_ dirtyRect: NSRect) {
        yourViewBorder.strokeColor = NSColor.secondaryLabelColor.cgColor
        yourViewBorder.lineDashPattern = [3, 5]
        yourViewBorder.frame = dirtyRect
        yourViewBorder.fillColor = nil//NSColor.red.cgColor
        yourViewBorder.path = NSBezierPath(rect:dirtyRect).cgPath
        yourViewBorder.lineWidth = 2
        if isFirst {
            self.layer?.addSublayer(yourViewBorder)
            isFirst = false
        }
        super.draw(dirtyRect)
    }
}
extension NSBezierPath {
    
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            case .cubicCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            @unknown default:
                break // Handle unknown cases safely
            }
        }
        
        return path
    }
}


func shutDownMac() {
    addLog(text: "shut Down Mac")
    let script = """
        tell application "System Events"
            shut down
        end tell
        """
    if let appleScript = NSAppleScript(source: script) {
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
        if let error = error {
            print("Error: \(error)")
        } else {
            print("Shutdown command executed successfully.")
        }
    } else {
        print("Failed to create AppleScript.")
    }
}


func sleepMac() {
    addLog(text: "sleep Mac")
    let script = """
        tell application "System Events"
            sleep
        end tell
        """
    if let appleScript = NSAppleScript(source: script) {
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
        if let error = error {
            print("Error: \(error)")
        } else {
            print("sleep command executed successfully.")
        }
    } else {
        print("Failed to create AppleScript.")
    }
}

func checkAutomationPermissionWithAppleScript() -> Bool {
    if checkDocBarState() == nil{
        return false
    }else{
        return true
    }
}





func getWindowFrame(pid: pid_t) -> CGRect? {
    var windowFrame: CGRect?
    
    // Get window information
    if let windowListInfo = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: AnyObject]] {
        for windowInfo in windowListInfo {
            if let id = windowInfo[kCGWindowOwnerPID as String] as? pid_t, id == pid {
                if let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] {
                    let x = bounds["X"] ?? 0
                    let y = bounds["Y"] ?? 0
                    let width = bounds["Width"] ?? 0
                    let height = bounds["Height"] ?? 0
                    
                    // Create CGRect from window bounds
                    windowFrame = CGRect(x: x, y: y, width: width, height: height)
                    break
                }
            }
        }
    }
    
    // Convert window frame to screen coordinates if windowFrame is not nil
    if var windowFrame = windowFrame {
        // Find the screen that contains the window
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(NSPoint(x: windowFrame.midX, y: windowFrame.midY), $0.frame, false) }) {
            // Convert window's frame to screen coordinates
            let screenFrame = screen.visibleFrame
            windowFrame.origin.x += screenFrame.origin.x
            windowFrame.origin.y += screenFrame.origin.y
        }
    }
    
    return windowFrame
}



func extractSubstring(from text: String, start: String, end: String) -> String? {
    guard let startRange = text.range(of: start),
          let endRange = text.range(of: end, range: startRange.upperBound..<text.endIndex) else {
        return nil
    }

    let substring = text[startRange.upperBound..<endRange.lowerBound]
    return String(substring)
}


func extractValue(from query: String, key:String) -> String? {
    let components = query.components(separatedBy: "&")
    for component in components {
        let pair = component.components(separatedBy: "=")
        if pair.count == 2, pair[0] == key {
            let value = pair[1].replacingOccurrences(of: "+", with: " ")
            return value.removingPercentEncoding
        }
    }
    return nil
}

//------------------------------------------------------------------//
//if the user has non timer based habits, add an estimate based on how long they spent on the habits the last few times
let nonTimerBasedHabitsObject = NonTimerBasedHabit()
class NonTimerBasedHabit:NSObject {
    var arrNonTimerBasedHabitsDurations = [String:[Int]]()
    
    func addDurationForHabit(id:String, duration:Int){
        var arrDurations = [Int]()
        if let arrOldDurations = arrNonTimerBasedHabitsDurations[id]{
            arrDurations = arrOldDurations
        }
        arrDurations.append(duration)
        if arrDurations.count > 10{
            arrDurations.remove(at: 0)
        }
        arrNonTimerBasedHabitsDurations[id] = arrDurations
        writeNonTimerBasedHabitsDurations()
    }

    func writeNonTimerBasedHabitsDurations(){
        let plistContent = NSDictionary(dictionary: arrNonTimerBasedHabitsDurations)
        let _ = plistContent.write(toFile: arrNonTimerBasedHabitsDurationsPlistFileUrl!.path, atomically: true)
    }

    func readNonTimerBasedHabitsDurations(){
        if let data = try? Data(contentsOf: arrNonTimerBasedHabitsDurationsPlistFileUrl) {
            if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: [Int]] { // [String: Any] which ever it is
                print(result)
                arrNonTimerBasedHabitsDurations = result
            }
        }
        print(arrNonTimerBasedHabitsDurations)
    }
}



//-----------------------------------------------//


//class CustomWKWebView: WKWebView {
//    override var mouseDownCanMoveWindow: Bool{
//        return true
//    }
//}


enum BLOCKINGSCHEDULE:Int{
    case _UNTIL_I_FINISH_WORK_ = 0, _WHEN_START_FOCUS_SESSION_, _CUSTOM_SCHEDULE_
}

func startApacheServer() {
    // Call the function to start Apache
    runCommandAsRoot(command: "/usr/sbin/apachectl", arguments: ["start"])
}
func runCommandAsRoot(command: String, arguments: [String]) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo") // Use sudo to run as root
    process.arguments = [command] + arguments

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    do {
        try process.run()
        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
            print("Command Output:\n\(output)")
        }

        if process.terminationStatus == 0 {
            print("Command executed successfully.")
        } else {
            print("Command failed with exit code: \(process.terminationStatus)")
        }
    } catch {
        print("Error: \(error.localizedDescription)")
    }
}

extension WKWebView {
    func stringByEvaluatingJavaScript(from script: String?) -> String? {
        var resultString: String? = nil
        var finished = false
        
        evaluateJavaScript(script ?? "", completionHandler: { result, error in
            if error == nil {
                if result != nil {
                    if let result = result {
                        resultString = "\(result)"
                    }
                }
            } else {
                print("evaluateJavaScript error : \(error?.localizedDescription ?? "")")
            }
            finished = true
        })
        
        while !finished {
            RunLoop.current.run(mode: .default, before: Date.distantFuture)
        }
        
        return resultString
    }
    
    class func clean() {
        //guard #available(iOS 9.0, *) else {return}
        
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                #if DEBUG
                print("WKWebsiteDataStore record deleted:", record)
                #endif
            }
        }
    }
}




func isFocusBearMenuVisible()->Bool{
    if SettingsManagerObject.isMenuPopoverEnabled{
        return appdelegate?.popover.isShown ?? false
    }else{
        return getMenuWindowObject().window?.isVisible ?? false
    }
}


func enableMenuPopover(){
    SettingsManagerObject.isMenuPopoverEnabled = true
    if getMenuWindowObject().window?.isVisible ?? false{
        getMenuWindowObject().window?.close()
    }
    appdelegate?.popover.contentViewController = menuViewControllerObj
    appdelegate?.popover.animates = false
    appdelegate?.popover.behavior = .transient
    allApiObject.capturePosthog(event: "settings-changed-menu-as-popover-enabled", metadata: [:])
    appdelegate?.showPopover()
    menuViewControllerObj?.view.window?.makeKey()
//    appdelegate?.popover.becomeFirstResponder()
}

func disableMenuPopover(){
    if appdelegate?.popover.isShown ?? false{
        appdelegate?.popover.close()
    }
    SettingsManagerObject.isMenuPopoverEnabled = false
    if let view = menuViewControllerObj?.view as? PopoverContentView{
        if view.backgroundView != nil{
            view.backgroundView?.removeFromSuperview()
            view.backgroundView = nil
        }
    }
    appdelegate?.popover.contentViewController = nil
    menuViewControllerObj?.view.removeFromSuperview()
    menuViewControllerObj = nil
    menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController
    
    getMenuWindowObject().contentViewController = menuViewControllerObj
   
    getMenuWindowObject().window?.contentView?.layoutSubtreeIfNeeded()
    if let frame = appdelegate?.statusbutton?.window?.frame{
        let height = menuViewControllerObj?.view.frame.height ?? 500
        let leading = frame.midX - (300 / 2) // 300 is view's width
        
        getMenuWindowObject().window?.setFrameOrigin(NSPoint(x: leading, y: frame.maxY - height))
    }
    
    
    allApiObject.capturePosthog(event: "settings-changed-menu-as-popover-disabled", metadata: [:])
    appdelegate?.showPopover()
}


func loadMenuWindow(){
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            if !(menuViewControllerObj?.isViewLoaded ?? false){
                menuViewControllerObj?.loadView()
                
            }
            getMenuWindowObject().loadWindow()
            if let frame = appdelegate?.statusbutton?.window?.frame{
                let height = menuViewControllerObj?.view.frame.height ?? 500
                let leading = frame.midX - (300 / 2) // 300 is view's width
                
                getMenuWindowObject().window?.setFrameOrigin(NSPoint(x: leading, y: frame.maxY - height))
            }
        }
    }
}





protocol NudgeWindowDelegate {
    func nudgeDragged()
}

class DraggableHorizontallyNudgeWindow: NSWindow {
    private var initialLocation: NSPoint = .zero
    var nudgeWindowDelegate:NudgeWindowDelegate?
    override func mouseDown(with event: NSEvent) {
        // Store the initial mouse location relative to window frame
        initialLocation = event.locationInWindow
    }

    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
//        guard let screen = screen else { return }
//        
//        // Get current window frame
//        var windowFrame = frame
//
//        // Calculate new X position while keeping Y position fixed
//        let newX = windowFrame.origin.x + (event.locationInWindow.x - initialLocation.x)
//
//        // Ensure the window remains within screen bounds
//        let maxX = screen.visibleFrame.maxX - windowFrame.width
//        let minX = screen.visibleFrame.minX
//
//        windowFrame.origin.x = min(maxX, max(minX, newX))  // Clamp X position
//
//        // Apply new frame
//        setFrame(windowFrame, display: true, animate: false)
//        nudgeWindowDelegate?.nudgeDragged()
        isNudgeDraggedInCurrentFocusSession = true
    }
}





var stageManagerObject = StageManager()
class StageManager:NSObject {
    
    var isStageManagerEnabled = false
    
    func checkIsStageManagerEnabled() -> Bool {
        guard #available(macOS 13.0, *) else {
            return false // Only available on macOS Ventura+
        }
        
        let windowInfos = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
        let appWindows = windowInfos?.filter { window in
            if let ownerName = window[kCGWindowOwnerName as String] as? String {
                return ownerName == "WindowManager"
            }
            return false
        }
        return (appWindows?.count ?? 0) >= 1
    }
}




var habitPlayingBeforeMacSleepId = ""//Focus alignment score drops to 0% after resuming from sleep #1321


func quitApplicationSmoothly() {
    addLog(text: "func :-quitApplicationSmoothly")
    // Step 1: End all attached sheets and modal sessions
    
    disableAllAlertsBeforeQuit()
    // Step 2: Wait a bit for UI to settle, then terminate
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        NSApp.terminate(nil)
    }
}

func disableAllAlertsBeforeQuit(){
    addLog(text: "func :-disableAllAlertsBeforeQuit")
    for window in NSApp.windows {
        // End any sheet attached to the window
        if let sheet = window.attachedSheet {
            window.endSheet(sheet)
        }

        // Abort any modal session running on this window
        if window == NSApp.modalWindow {
            NSApp.abortModal()
            NSApp.stopModal()
        }
    }
}




//func setupLocalCrashReporter() {
//    let config = PLCrashReporterConfig(signalHandlerType: .BSD, symbolicationStrategy: .all)
//    let reporter = PLCrashReporter(configuration: config)
//
//    if reporter.hasPendingCrashReport() {
//        do {
//            let data = try reporter.loadPendingCrashReportDataAndReturnError()
//            let crashReport = try PLCrashReport(data: data)
//            let text = PLCrashReportTextFormatter.stringValue(for: crashReport, with: .full)
//
//            // Save to disk
//            let url = FileManager.default.homeDirectoryForCurrentUser
//                .appendingPathComponent("Library/Logs/MyApp/crash_\(Date().timeIntervalSince1970).log")
//            try text.write(to: url, atomically: true, encoding: .utf8)
//
//            // Purge the crash so it's not handled again
//            reporter.purgePendingCrashReport()
//        } catch {
//            print("Failed to process crash report: \(error)")
//        }
//    }
//
//    do {
//        try reporter.enableAndReturnError()
//    } catch {
//        print("Failed to enable crash reporter: \(error)")
//    }
//}


func isCutOffTimeGoing()->Bool{
    if cutOffTime != nil{
        let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
        let currentDate = Date()
        if currentDate > cutOffDate{
            return true
        }
    }
    return false
}


func getTimeSinceLastBreak()->String?{
    var breaksEndTime = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakEndTime) as? Date
    if breaksEndTime == nil{
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        breaksEndTime = startDate
    }else{
        var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
            startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
        }
        
        if breaksEndTime!.compare(startDate) == .orderedAscending {//breaksStartTime < start date
            breaksEndTime = startDate
        }
    }
    if let breaksEndTime = breaksEndTime{
        let currentDate = Date()
        let diffSeconds = Calendar.current.dateComponents([.second], from: breaksEndTime, to: currentDate).second ?? 0
        if diffSeconds > 0{
            let time = getStringTimeFromSecondsWithoutSeconds(seconds: Int(diffSeconds))
            var lastBreakTimeText = "Time since last break: <TIME>"
            if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
                lastBreakTimeText = menuInfo.value(forKey: "lastBreakTimeText") as? String ?? lastBreakTimeText
            }
            lastBreakTimeText = lastBreakTimeText.replacingOccurrences(of: "<TIME>", with: time)
            return lastBreakTimeText
        }
    }
    return nil
}


// in macos 26 user was able to click on superview through subview in enterPasswordVc view (a button to prevent this already there but in macos 26 button was not stoppoint clickin on superview) to prevent this made this view 14/7/25 1.26.390
class BlockingView: NSView {
    override func mouseDown(with event: NSEvent) {
       // super.mouseDown(with: event)
    }
    override func mouseUp(with event: NSEvent) {
       // super.mouseDown(with: event)
    }
}


//func checkStatusItemVisibility() -> Bool {
//    guard let button = appdelegate!.statusItem.button else { return false }
//    
//    // Check if the button is actually visible on screen
//    guard let window = button.window else { return false }
//    
//    let screenRect = NSScreen.main?.frame ?? .zero
//    let buttonRect = window.frame
//    
//    // Check if the button frame intersects with the screen's visible area
//    return screenRect.intersects(buttonRect)
//}



class BlinkingNSBox: NSBox {// 22/7/25  v 1.26.393
    private var blinkTimer: Timer?
    private let colors: [NSColor] = [NSColor(named: "dark_OrangeColor") ?? NSColor.blue, NSColor(red: 249/255, green: 233/255, blue: 142/255, alpha: 1)]
    private var currentColorIndex = 0
    private let blinkInterval: TimeInterval = 0.5
    private var windowObserver: NSKeyValueObservation?
    private var blinkCount = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        self.borderWidth = 2.0
        self.borderColor = colors.first!
    }
    
    override var isHidden: Bool {
        didSet {
            if isHidden {
                stopBlinking()
            }
        }
    }
    
    func startBlinking() {
        guard !isHidden, blinkTimer == nil else { return }
        self.borderColor = self.colors.last!
        blinkCount = 0
        currentColorIndex = 0
        blinkTimer = Timer.scheduledTimer(withTimeInterval: blinkInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if blinkCount > 9{
                stopBlinking()
                return;
            }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = self.blinkInterval / 2
                self.currentColorIndex = (self.currentColorIndex + 1) % self.colors.count
                self.animator().borderColor = self.colors[self.currentColorIndex]
                self.blinkCount += 1
            }
        }
    }
    
    func stopBlinking() {
        guard blinkTimer != nil else { return }
        blinkTimer?.invalidate()
        blinkTimer = nil
        currentColorIndex = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = blinkInterval / 2
            self.animator().borderColor = self.colors.last!
        }
    }
    
    deinit {
        stopBlinking()
    }
}

var isExplainingPermissionsWindowShowingFromPomodoro = false

//var isCustomBarIsInFocus = false// when app is not in focus and user try to click close icon of custom bar . then applicationDidBecomeActive func called instead of close action because app become active and because app become active it shows menu (from inside applicationDidBecomeActive func) instead of  closing custom bar. to prevent this we are using isCustomBarIsInFocus variable. so that if user's cursor is on custom bar then menu will not show.



func startMainAppForceQuitMonitoring(){
    appdelegate!.sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsStartMainAppIfNotRunning)
    appdelegate!.sharedDefaults?.synchronize()
    let startMainAppForceQuitMonitoring = Notification.Name("startMainAppForceQuitMonitoring")
    DistributedNotificationCenter.default().post(name: startMainAppForceQuitMonitoring,object: mainAppBundelId)
}

func stopMainAppForceQuitMonitoring(){
    if let state = appdelegate!.sharedDefaults?.object(forKey: kUserdefaultsStartMainAppIfNotRunning) as? Bool{
        if state{
            appdelegate!.sharedDefaults?.setValue(false, forKeyPath: kUserdefaultsStartMainAppIfNotRunning)
            appdelegate!.sharedDefaults?.synchronize()
            
            let stopMainAppForceQuitMonitoring = Notification.Name("stopMainAppForceQuitMonitoring")
            DistributedNotificationCenter.default().post(name: stopMainAppForceQuitMonitoring,object: mainAppBundelId)
        }
    }
}

