//
//  breaksData.swift
//  FocusBear
//
//  Created by Manish Jain on 17/06/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var breakAfterMinutes = 0
var arrAllbreakActivities = [breakActivity]()
var arrFinalBreakActivities = [breakActivityFilter]()
struct breakActivityFilter{
    var activity:breakActivity!
    var randomChoice:activityChoice?
}

struct breakActivity {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var IncludeInEveryBreak:Bool!
    var urlsArray:[String]
    var logQuantity:Bool!
    var choiceType:CHOICETYPE!
    var choices:[activityChoice]
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var isOfficeFriendly:Bool!
    var allowedFocusMode:String!
    var logQuantityType:String!
    var activity_sequence_id:String!
    var take_notes:String!
    var text_instructions = ""
    var imgUrls = [String]()
    var completion_requirements = ""
    var useTimer:Bool = true
    var logQuantityQuestions = [quantityQuestion]()
    var checkList = [String]()
    init(id:String, name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, urlsArray:[String], logQuantity:Bool,choiceType:CHOICETYPE,choices:[activityChoice],logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],isOfficeFriendly:Bool,allowedFocusMode:String,logQuantityType:String,activity_sequence_id:String,take_notes:String, text_instructions:String, imgUrls:[String], completion_requirements:String, useTimer:Bool, checkList:[String]) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.IncludeInEveryBreak = IncludeInEveryBreak
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.choiceType = choiceType
        self.choices = choices
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.isOfficeFriendly = isOfficeFriendly
        self.allowedFocusMode = allowedFocusMode
        self.logQuantityType = logQuantityType
        self.activity_sequence_id = activity_sequence_id
        self.take_notes = take_notes
        self.text_instructions = text_instructions
        self.imgUrls = imgUrls
        self.completion_requirements = completion_requirements
        self.useTimer = useTimer
        self.checkList = checkList
    }
}


var idleTimeValueForNaturalBreak = 600
func detectNatualBreaks(){
    var lastEvent:CFTimeInterval = 0
    lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
    
    let idleTimeValue = Int(lastEvent)
    if currentState != ._MORNING_HABIT_ && currentState != ._ACTIVITY_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !appdelegate!.isUserOnMeeting{
        checkIsNaturalBreakWindowNeedToShow(idleTimeValue: idleTimeValue)
    }else{
        if naturalBreaksDetectionWcObj != nil{
            if naturalBreaksDetectionWcObj?.window?.isVisible ?? false{
                naturalBreaksDetectionVcObj?.btnFirstClicked(appdelegate!)
                if breakWarningWcObj != nil{
                    if breakWarningWcObj?.window?.isVisible ?? false{
                        getBreakWarningVcObject().reloadTimeSinceLastBreak()
                    }
                }
                naturalBreaksDetectionWcObj?.window?.close()
            }
        }
    }
}

func checkIsNaturalBreakWindowNeedToShow(idleTimeValue:Int){
    if idleTimeValue > idleTimeValueForNaturalBreak{// 600 kro
        // if !appdelegate!.isScreenLocked && !appdelegate!.isSystemSleep && !appdelegate!.isScreenSaverStart{ // 
        var shouldShowAlert = true
        if naturalBreaksDetectionWcObj != nil{
            if naturalBreaksDetectionWcObj?.window?.isVisible ?? false{
                shouldShowAlert = false
            }
        }
        if currentState == ._POSTPON_MORNING_HABIT_{
            if !SettingsManagerObject.IsShowBreaksInPostponeEnabled{
                shouldShowAlert = false
            }
        }
        if shouldShowAlert{
            if appdelegate!.checkIsAnyVideoWebsiteIsRunning(){
                shouldShowAlert = false
            }
        }
        if shouldShowAlert{
            showNaturalBreakDetectionWindow(duration:idleTimeValue)
        }
        //}
    }
}
