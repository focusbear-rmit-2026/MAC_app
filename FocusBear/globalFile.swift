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
//import SystemConfiguration// for check internet availibility code
//import WebKit


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

var strictnessNormalText = "Normal"
var strictnessStrictText = "Strict"
var strictnessSuperStrictText = "Super strict"

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
    
    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
        if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
            strictnessNormalText = startingFocusModeInfo.value(forKey: "strictnessNormalText") as? String ?? strictnessNormalText
            strictnessStrictText = startingFocusModeInfo.value(forKey: "strictnessStrictText") as? String ?? strictnessStrictText
            strictnessSuperStrictText = startingFocusModeInfo.value(forKey: "strictnessSuperStrictText") as? String ?? strictnessSuperStrictText
        }
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



var isGettingSchema = false



let allApiObject = AllApi()
let pusherEventsObject = pusherEvents()

var applicationSupportURL: URL?
var localFlaskServerFolderURL:URL!
var trackFilesFolderURL:URL!
var DebugLogsFolderURL:URL!
var DebugLogsURL:URL!
//var DebugGraphLogsURL:URL!

//var habitInfoFileURL:URL!
var settingForScreeenTimeFileURL:URL!
var newLocalSettingsFileURL:URL!
var arrNonTimerBasedHabitsDurationsPlistFileUrl:URL!


//var blockURL:URL!
var blockWebUrlString = ""


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

func isAppInstalledWithinLast3Days() -> Bool {
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    
    let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    return firstRunDate >= threeDaysAgo
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





//



var isPurchased = false
var daysLeft = 0
let daysFreeTrial  = 31



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



var allActivityTodaySummaryData:NSDictionary?
var graphOneMonthData:NSDictionary?
var graphOneDayData:[NSDictionary]?
var graphOneDayDataForQuantity:NSDictionary?

var focusModeTemplateData:[NSDictionary]?
var habitPacksData:[NSDictionary]?



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


func zipItem(inputPath: String, outputZipPath: String) throws {
    let fm = FileManager.default
    
    // Remove old zip if it exists
    if fm.fileExists(atPath: outputZipPath) {
        try fm.removeItem(atPath: outputZipPath)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    var isDir: ObjCBool = false
    fm.fileExists(atPath: inputPath, isDirectory: &isDir)
    
    if isDir.boolValue {
        // For folder → use -r (recursive)
        let folderName = (inputPath as NSString).lastPathComponent
        let parentPath = (inputPath as NSString).deletingLastPathComponent
        
        process.currentDirectoryURL = URL(fileURLWithPath: parentPath)
        process.arguments = ["-r", outputZipPath, folderName]
    } else {
        // For file → keep -j (junk paths, no directory structure)
        process.arguments = ["-j", outputZipPath, inputPath]
    }
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Zipped at \(outputZipPath)")
    } else {
        throw NSError(
            domain: "ZipError",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Failed to zip item."]
        )
    }
}



func zipItems(inputPaths: [String], outputZipPath: String) throws {
    let fm = FileManager.default
    
    // Remove old zip if it exists
    if fm.fileExists(atPath: outputZipPath) {
        try fm.removeItem(atPath: outputZipPath)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    // Separate into parent dir + relative names (so zip doesn’t store absolute paths)
    var allArguments: [String] = ["-r", outputZipPath]
    
    var parentDir: String?
    for path in inputPaths {
        let parent = (path as NSString).deletingLastPathComponent
        if parentDir == nil { parentDir = parent }
        // Ensure all files are from same parent directory, otherwise paths get long
        allArguments.append((path as NSString).lastPathComponent)
    }
    
    if let parentDir = parentDir {
        process.currentDirectoryURL = URL(fileURLWithPath: parentDir)
    }
    
    process.arguments = allArguments
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ Zipped at \(outputZipPath)")
    } else {
        throw NSError(
            domain: "ZipError",
            code: Int(process.terminationStatus),
            userInfo: [NSLocalizedDescriptionKey: "Failed to zip items."]
        )
    }
}

func createZipArchive(zipPath: String, logFolder: String, screenshots: [URL]) throws {
    let fileManager = FileManager.default

    // Remove old zip if exists
    if fileManager.fileExists(atPath: zipPath) {
        try fileManager.removeItem(atPath: zipPath)
    }

    // Create temporary folder for Screenshots
    let logParent = URL(fileURLWithPath: logFolder).deletingLastPathComponent()
    let screenshotsFolder = logParent.appendingPathComponent("Screenshots", isDirectory: true)

    if fileManager.fileExists(atPath: screenshotsFolder.path) {
        try fileManager.removeItem(at: screenshotsFolder)
    }
    
    if screenshots.count != 0{
        try fileManager.createDirectory(at: screenshotsFolder, withIntermediateDirectories: true)
    }

    // Copy screenshots into the temporary Screenshots folder
    for sourceURL in screenshots {
        let destURL = screenshotsFolder.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: destURL.path) {
            try fileManager.removeItem(at: destURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destURL)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
    
    
    // Run /usr/bin/zip
    var arguments: [String] = ["-r", zipPath]
    var itemsToZip: [String] = []
    let logURL = URL(fileURLWithPath: logFolder)
    let parentDir = logURL.deletingLastPathComponent()
    process.currentDirectoryURL = parentDir
    itemsToZip.append(logURL.lastPathComponent)
    
    if screenshots.count != 0{
        itemsToZip.append(screenshotsFolder.lastPathComponent)
    }
    arguments.append(contentsOf: itemsToZip)
    process.arguments = arguments
    

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: .utf8) {
        print(output)
    }

    if process.terminationStatus != 0 {
        throw NSError(domain: "ZipError", code: Int(process.terminationStatus), userInfo: [
            NSLocalizedDescriptionKey: "Failed to create zip archive"
        ])
    }
    if fileManager.fileExists(atPath: screenshotsFolder.path) {
        try fileManager.removeItem(at: screenshotsFolder)
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






func calculateBackoffWithJitter(baseDelayMs: Int, retry: Int) -> Int {
    addLog(text: "CalculateBackoffWithJitter()")
    let maxDelayMs = 120000 // Maximum delay in milliseconds
    let exponentialDelay = Int(pow(2.0, Double(retry)) * Double(baseDelayMs))
    let jitter = Int.random(in: 1...baseDelayMs/2)  // Adding jitter within half of the base delay
    let delayMs = min(exponentialDelay + jitter, maxDelayMs)
    return delayMs
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






func randomString(length: Int) -> String {
  let letters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}


var defaultStartTime = "08:30"
var defaultShutDownTime = "18:30"
var defaultSleepTime = "21:30"





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


var boxForStatusBarForTooltip: customStatusBarBoxForTooltip!




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

let nonTimerBasedHabitsObject = NonTimerBasedHabit()







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


let stageManagerObject = StageManager()


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

func getWindowTheme()->String{
    var theme = "LIGHT"
    if mainWindowControllerObj != nil{
        if mainWindowControllerObj!.window?.hasDarkAppearance ?? false{
            theme = "DARK"
        }else {
            theme = "LIGHT"
        }
    }
    return theme
}



