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

let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
let newStoryboard = NSStoryboard(name: NSStoryboard.Name("NewStoryboard"), bundle: nil)

let mainWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("mainWindowController")) as? mainWindowController
let mainViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ViewController")) as? ViewController
let firstViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firstViewController")) as? firstViewController

let timerViewcontrollerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("timerViewcontroller")) as? timerViewcontroller

var discourageDefaultFocusVcObj:discourageDefaultFocusVc?
func getDiscourageDefaultFocusVcObject()->discourageDefaultFocusVc{
    if discourageDefaultFocusVcObj == nil{
        discourageDefaultFocusVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("discourageDefaultFocusVc")) as? discourageDefaultFocusVc
    }
    return discourageDefaultFocusVcObj!
}
var quittingWcObj:commonWindowController?
func getQuittingWindowObject()->commonWindowController{
    if quittingWcObj == nil{
        quittingWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return quittingWcObj!
}

var visualizeInstructionsVcObj:visualizeInstructionsVc?
func getvisualizeInstructionsObject()->visualizeInstructionsVc{
    if visualizeInstructionsVcObj == nil{
        visualizeInstructionsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("visualizeInstructionsVc")) as? visualizeInstructionsVc
    }
    return visualizeInstructionsVcObj!
}

var quitCountDownVcObj:quitCountDownVc?
func getQuittingCountDownVcObject()->quitCountDownVc{
    if quitCountDownVcObj == nil{
        quitCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quitCountDownVc")) as? quitCountDownVc
    }
    return quitCountDownVcObj!
}

var askQuitVcObj:askQuitVc?
func getAskQuitVcObject()->askQuitVc{
    if askQuitVcObj == nil{
        askQuitVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askQuitVc")) as? askQuitVc
    }
    return askQuitVcObj!
}


var askPostponeVcObj:askPostponeVc?
func getAskPostponeVcObject()->askPostponeVc{
    if askPostponeVcObj == nil{
        askPostponeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askPostponeVc")) as? askPostponeVc
    }
    return askPostponeVcObj!
}

var skipHabitVcObj:skipHabitVc?
func getSkipHabitVcObject()->skipHabitVc{
    if skipHabitVcObj == nil{
        skipHabitVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("skipHabitVc")) as? skipHabitVc
    }
    return skipHabitVcObj!
}

var whySkipHabitVcObj:whySkipHabitVc?
func getWhySkipHabitVcObject()->whySkipHabitVc{
    if whySkipHabitVcObj == nil{
        whySkipHabitVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("whySkipHabitVc")) as? whySkipHabitVc
    }
    return whySkipHabitVcObj!
}

var smallCountDownVcObj:smallCountDownVc?
func getsmallCountDownVcObject()->smallCountDownVc{
    if smallCountDownVcObj == nil{
        smallCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("smallCountDownVc")) as? smallCountDownVc
    }
    return smallCountDownVcObj!
}

var smallCountDownWcObj:commonWindowController?
func getSmallCountDownWindowObject()->commonWindowController{
    if smallCountDownWcObj == nil{
        smallCountDownWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        smallCountDownWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return smallCountDownWcObj!
}

var quittingConfirmVcObj:quittingConfirmVc?

func getQuittingConfirmVcObject()->quittingConfirmVc{
    if quittingConfirmVcObj == nil{
        quittingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quittingConfirmVc")) as? quittingConfirmVc
    }
    return quittingConfirmVcObj!
}

var brainDumpWcObj:commonWindowController?
func getBrainDumpWindowObject()->commonWindowController{
    if brainDumpWcObj == nil{
        brainDumpWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        brainDumpWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return brainDumpWcObj!
}

var brainDumpVcObj:brainDumpVc?
func getBrainDumpVcObject()->brainDumpVc{
    if brainDumpVcObj == nil{
        brainDumpVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("brainDumpVc")) as? brainDumpVc
    }
    return brainDumpVcObj!
}

var askLogInWcObj:commonWindowController?
func getAskLogInWindowObject()->commonWindowController{
    if askLogInWcObj == nil{
        askLogInWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        askLogInWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return askLogInWcObj!
}

var askLogInVcObj:askLogInVc?
func getAskLogInVcObject()->askLogInVc{
    if askLogInVcObj == nil{
        askLogInVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askLogInVc")) as? askLogInVc
    }
    return askLogInVcObj!
}

var upgradeNowWcObj:commonWindowController?
func getUpgradeNowWindowObject()->commonWindowController{
    if upgradeNowWcObj == nil{
        upgradeNowWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        upgradeNowWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return upgradeNowWcObj!
}

var upgradeNowVcObj:upgradeNowVc?
func getUpgradeNowVcObject()->upgradeNowVc{
    if upgradeNowVcObj == nil{
        upgradeNowVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("upgradeNowVc")) as? upgradeNowVc
    }
    return upgradeNowVcObj!
}

var welcomeOnboardingWcObj:commonWindowController?
func getWelcomeOnboardingWindowObject()->commonWindowController{
    if welcomeOnboardingWcObj == nil{
        welcomeOnboardingWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        welcomeOnboardingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return welcomeOnboardingWcObj!
}

var welcomeOnboardingVcObj:welcomeOnboardingVc?
func getWelcomeOnboardingVcObject()->welcomeOnboardingVc{
    if welcomeOnboardingVcObj == nil{
        welcomeOnboardingVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeOnboardingVc")) as? welcomeOnboardingVc
    }
    return welcomeOnboardingVcObj!
}
var onboardingPostponeVcObj:onboardingPostponeVc?
func getOnboardingPostponeVcObject()->onboardingPostponeVc{
    if onboardingPostponeVcObj == nil{
        onboardingPostponeVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingPostponeVc")) as? onboardingPostponeVc
    }
    return onboardingPostponeVcObj!
}



var onboardingVideoWcObj:commonWindowController?
func getOnboardingVideoWindowObject()->commonWindowController{
    if onboardingVideoWcObj == nil{
        onboardingVideoWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        onboardingVideoWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return onboardingVideoWcObj!
}

var onboardingVideoVcObj:thirdVc?
func getOnboardingVideoVcObject()->thirdVc{
    if onboardingVideoVcObj == nil{
        onboardingVideoVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc
    }
    return onboardingVideoVcObj!
}

var customMessageVcObj:customMessageVc?
func getCustomMessageVcObject()->customMessageVc{
    if customMessageVcObj == nil{
        customMessageVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customMessageVc")) as? customMessageVc
    }
    return customMessageVcObj!
}


var customLoginVcObj:customLoginVc?
func getCustomLoginVcObject()->customLoginVc{
    if customLoginVcObj == nil{
        customLoginVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customLoginVc")) as? customLoginVc
    }
    return customLoginVcObj!
}


var loginHelpWcObj:commonWindowController?
func getLoginHelpWindowObject()->commonWindowController{
    if loginHelpWcObj == nil{
        loginHelpWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        loginHelpWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return loginHelpWcObj!
}

//var loginHelpVcObj:loginHelpVc?
//func getLoginHelpVcObject()->loginHelpVc{
//    if loginHelpVcObj == nil{
//        loginHelpVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("loginHelpVc")) as? loginHelpVc
//    }
//    return loginHelpVcObj!
//}

var onboardingCardsWcObj:commonWindowController?
func getOnboardingCardsWindowObject()->commonWindowController{
    if onboardingCardsWcObj == nil{
        onboardingCardsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        onboardingCardsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        onboardingCardsWcObj?.window?.title = appName
    }
    return onboardingCardsWcObj!
}

var onboardingCardsVcObj:onboardingCardsVc?
func getOnboardingCardsVcObject()->onboardingCardsVc{
    if onboardingCardsVcObj == nil{
        onboardingCardsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingCardsVc")) as? onboardingCardsVc
    }
    return onboardingCardsVcObj!
}

var incorrectTimeWcObj:commonWindowController?
func getIncorrectTimeWindowObject()->commonWindowController{
    if incorrectTimeWcObj == nil{
        incorrectTimeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        incorrectTimeWcObj?.window?.title = appName
        incorrectTimeWcObj!.window?.styleMask.remove(.closable)
        incorrectTimeWcObj?.contentViewController = getIncorrectTimeVcObject()
        incorrectTimeWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        
    }
    return incorrectTimeWcObj!
}

var incorrectTimeVcObj:incorrectTimeVc?
func getIncorrectTimeVcObject()->incorrectTimeVc{
    if incorrectTimeVcObj == nil{
        incorrectTimeVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("incorrectTimeVc")) as? incorrectTimeVc
    }
    return incorrectTimeVcObj!
}


// custom notification window object
var customNotificationWcObj:commonWindowController?
func getCustomNotificationWindowObject()->commonWindowController{
    if customNotificationWcObj == nil{
        customNotificationWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        customNotificationWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return customNotificationWcObj!
}

// custom notification vc object
var customNotificationVcObj:customNotificationVc?
func getCustomNotificationVcObject()->customNotificationVc{
    if customNotificationVcObj == nil{
        customNotificationVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customNotificationVc")) as? customNotificationVc
    }
    return customNotificationVcObj!
}


// custom notification vc object
var customTooltipVcObj:customTooltipVc?
func getCustomTooltipVcObject()->customTooltipVc{
    if customTooltipVcObj == nil{
        customTooltipVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customTooltipVc")) as? customTooltipVc
    }
    return customTooltipVcObj!
}



// toolBox window object
var toolBoxWcObj:commonWindowController?
func getToolBoxWindowObject()->commonWindowController{
    if toolBoxWcObj == nil{
        toolBoxWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        toolBoxWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return toolBoxWcObj!
}

// toolBox vc object
var toolBoxVcObj:toolBoxVc?
func getToolBoxVcObject()->toolBoxVc{
    if toolBoxVcObj == nil{
        toolBoxVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("toolBoxVc")) as? toolBoxVc
    }
    return toolBoxVcObj!
}



// AppWork window object
var askAppWorkWcObj:commonWindowController?
func getAskAppWorkWindowObject()->commonWindowController{
    if askAppWorkWcObj == nil{
        askAppWorkWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        askAppWorkWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return askAppWorkWcObj!
}

// AppWork vc object
var askAppWorkVcObj:askAppWorkVc?
func getAskAppWorkVcObject()->askAppWorkVc{
    if askAppWorkVcObj == nil{
        askAppWorkVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askAppWorkVc")) as? askAppWorkVc
    }
    return askAppWorkVcObj!
}

// habit SkipEasiness object
var habitSkipEasinessVcObj:habitSkipEasinessVc?
func getHabitSkipEasinessVcObject()->habitSkipEasinessVc{
    if habitSkipEasinessVcObj == nil{
        habitSkipEasinessVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("habitSkipEasinessVc")) as? habitSkipEasinessVc
    }
    return habitSkipEasinessVcObj!
}

// AppWork vc object
var onboardingBlockedUrlsVcObj:onboardingBlockedUrlsVc?
func getOnboardingBlockedUrlsVcObject()->onboardingBlockedUrlsVc{
    if onboardingBlockedUrlsVcObj == nil{
        onboardingBlockedUrlsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingBlockedUrlsVc")) as? onboardingBlockedUrlsVc
    }
    return onboardingBlockedUrlsVcObj!
}

// custom notification window object
var breakWarningWcObj:commonWindowController?
func getBreakWarningWindowObject()->commonWindowController{
    if breakWarningWcObj == nil{
        breakWarningWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        breakWarningWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return breakWarningWcObj!
}

// break Warning vc object
var breakWarningVcObj:breakWarningVc?
func getBreakWarningVcObject()->breakWarningVc{
    if breakWarningVcObj == nil{
        breakWarningVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("breakWarningVc")) as? breakWarningVc
    }
    return breakWarningVcObj!
}


// easy postpone window object
var easyPostponeWcObj:commonWindowController?
func getEasyPostponeWindowObject()->commonWindowController{
    if easyPostponeWcObj == nil{
        easyPostponeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        easyPostponeWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return easyPostponeWcObj!
}

// easy postpone vc object
var easyPostponeVcObj:easyPostponeVc?
func getEasyPostponeVcObject()->easyPostponeVc{
    if easyPostponeVcObj == nil{
        easyPostponeVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("easyPostponeVc")) as? easyPostponeVc
    }
    return easyPostponeVcObj!
}

// popUpOffline window object
var popUpOfflineWcObj:commonWindowController?
func getPopUpOfflineWindowObject()->commonWindowController{
    if easyPostponeWcObj == nil{
        popUpOfflineWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        popUpOfflineWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return popUpOfflineWcObj!
}

// popUpOffline vc object
var popUpOfflineVcObj:popUpOfflineVc?
func getPopUpOfflineVcObject()->popUpOfflineVc{
    if popUpOfflineVcObj == nil{
        popUpOfflineVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpOfflineVc")) as? popUpOfflineVc
    }
    return popUpOfflineVcObj!
}



// popUp Block Confirm window object
var popUpBlockConfirmWcObj:commonWindowController?
func getPopUpBlockConfirmWindowObject()->commonWindowController{
    if popUpBlockConfirmWcObj == nil{
        popUpBlockConfirmWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        popUpBlockConfirmWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return popUpBlockConfirmWcObj!
}

// popUp Block Confirm vc object
var popUpBlockConfirmVcObj:popUpBlockConfirmVc?
func getPopUpBlockConfirmVcObject()->popUpBlockConfirmVc{
    if popUpBlockConfirmVcObj == nil{
        popUpBlockConfirmVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpBlockConfirmVc")) as? popUpBlockConfirmVc
    }
    return popUpBlockConfirmVcObj!
}


let thirdVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc

//let selectJsonWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonWindowController")) as? selectJsonWindowController
var selectJsonVcObj:selectJsonVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
let shutOffTimeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shutOffTimeVc")) as? shutOffTimeVc

let abortingCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCountDownVc")) as? abortingCountDownVc
let abortingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingConfirmVc")) as? abortingConfirmVc
let abortDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortDoneVc")) as? abortDoneVc

let activationWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("activationWindowController")) as? activationWindowController

let sevenDaysTrialvcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("sevenDaysTrialvc")) as? sevenDaysTrialvc
let activateNowvcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("activateNowvc")) as? activateNowvc

let abortingCantHandleVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCantHandleVc")) as? abortingCantHandleVc
let logQuantityVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("logQuantityVc")) as? logQuantityVc

let preferencesWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preferencesWindowController")) as? preferencesWindowController

let menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController

//let focusPreferencesWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesWc")) as? focusPreferencesWc
var focusPreferencesVcObj:focusPreferencesVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesVc")) as? focusPreferencesVc
var blockedUrlsVcObj:blockedUrlsVc?

let addWebUrlVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addWebUrlVc")) as? addWebUrlVc
let addFocusTypeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addFocusTypeVc")) as? addFocusTypeVc

let pomodoroWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroWindowController")) as? pomodoroWindowController
let pomodoroVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroVc")) as? pomodoroVc
let focusCompletedVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusCompletedVc")) as? focusCompletedVc


let startingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController


var endingFocusWindowControllerObj: commonWindowController?

func getEndFocusModeWindowControllerObj()->commonWindowController{
    if endingFocusWindowControllerObj == nil{
        endingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        endingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return endingFocusWindowControllerObj!
}
var rememberNextHabitVcObj:rememberNextHabitVc?

func getRememberNextHabitVcObj()->rememberNextHabitVc{
    if rememberNextHabitVcObj == nil{
        rememberNextHabitVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("rememberNextHabitVc")) as? rememberNextHabitVc
    }
    return rememberNextHabitVcObj!
}


var preloadFocusModesWindowControllerObj: commonWindowController?

func getPreloadFocusModesWindowControllerObj()->commonWindowController{
    if preloadFocusModesWindowControllerObj == nil{
        preloadFocusModesWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        preloadFocusModesWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return preloadFocusModesWindowControllerObj!
}


var preloadFocusModesVcObj:preloadFocusModesVc?

func getPreloadFocusModesVcObj()->preloadFocusModesVc{
    if preloadFocusModesVcObj == nil{
        preloadFocusModesVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preloadFocusModesVc")) as? preloadFocusModesVc
    }
    return preloadFocusModesVcObj!
}

var preloadFocusModeAppsVcObj:preloadFocusModeAppsVc?

func getPreloadFocusModeAppsVcObj()->preloadFocusModeAppsVc{
    if preloadFocusModeAppsVcObj == nil{
        preloadFocusModeAppsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preloadFocusModeAppsVc")) as? preloadFocusModeAppsVc
    }
    return preloadFocusModeAppsVcObj!
}



var focusTipsVcObj:focusTipsVc?

func getFocusTipsVcObjObj()->focusTipsVc{
    if focusTipsVcObj == nil{
        focusTipsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusTipsVc")) as? focusTipsVc
    }
    return focusTipsVcObj!
}


let startingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startingFocusModeVc")) as? startingFocusModeVc
let abortingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingFocusModeVc")) as? abortingFocusModeVc

let focusSummaryVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusSummaryVc")) as? focusSummaryVc


let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as?enterPasswordVc

var focusPreferencesAdvancedVcObj:focusPreferencesAdvancedVc?

let appdelegate = NSApplication.shared.delegate as? AppDelegate

var SettingsManagerObject = SettingsManager()

var isHardCorePomodoroModeOn = false
var hardcodePmodoroFocusModeIndex = 0
var totalMinutesRemainingForHardcodePomodoro = 0
var currentPomodoroWorkDuration = 25
var currentPomodoroBreakDuration = 5
var totalPomodoroCountInHardCorePomodoro = 0
var completedPomodoroCountInHardcorePomodoro = 0

var activityPostponeCount = 0
var activitySkipCount = 0
//var isMorningRoutinePostpone = false


var isPromptToRememberHabitShowedInLastHabit = false///   reason:-Make sure it doesn't happen twice in a row though. 

var configjson = NSDictionary()


var currentDeviceId = ""
var currentUserName = ""
var currentUserEmail = ""


var kUserdefaultsDontTellAgain = "kUserdefaultsDontTellAgain"
var kUserdefaultsAppQuitProperly = "kUserdefaultsAppQuitProperly"


var kUserdefaultsDeviceId = "kUserdefaultsDeviceId"
let kUserdefaultsSelectedJson = "kUserdefaultsSelectedJson"



let kUserdefaultsFirstRunDate = "kUserdefaultsFirstRunDate"// system app first run date hai
//let kUserdefaultsFirstHabitDay = "kUserdefaultsFirstHabitDay"//

let kUserdefaultsFirstRun = "kUserdefaultsFirstRun"// first habit k liye use ful hai
let kUserdefaultsVideoShown = "kUserdefaultsVideoShown"
var kUserdefaultsShowDockIcon = "kUserdefaultsShowDockIcon"

let kUserdefaultsLastHabitShowDate = "UserdefaultsLastHabitShowDate"

var kUserdefaultsLastHabitsStartedDate = "kUserdefaultsLastHabitsStartedDate"
var kUserdefaultsLastHabitID = "kUserdefaultsLastHabitID"

var kUserdefaultsIsAppEnabled = "kUserdefaultsIsAppEnabled"


var kUserdefaults4HourReActivateTime = "kUserdefaults4HourReActivateTime"
var kUserdefaultsShutdownAborted = "kUserdefaultsShutdownAborted"
var kUserdefaultsEveningHabitsShowedTillDate = "kUserdefaultsEveningHabitsShowedTillDate"//agar evening habit ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to evening habit vapas na aay
var kUserdefaultsFocusSummaryShowedTillDate = "kUserdefaultsFocusSummaryShowedTillDate"//agar Focus Summary ak bar show ho gai h to agle din start habit tk ki date save kr lenge taki jab bhi vps shut off ho same day hi to Focus Summary vapas na aay


var isAppInitialLodded = false// activation kha se show hua h menu se ya startup per iske liye iska use krenge 

var isHabitsDisabled = false
var kUserdefaultsIsHabitsDisabled = "kUserdefaultsIsHabitsDisabled"

var kUserdefaultsHabitSkipEasinessFromOnboarding = "kUserdefaultsHabitSkipEasinessFromOnboarding"
var kUserdefaultsBlockedUrlsFromOnboarding = "kUserdefaultsBlockedUrlsFromOnboarding"


//var kUserdefaultsSelectedFolder = "kUserdefaultsSelectedFolder"

var kUserdefaultsArrFocusTypes = "kUserdefaultsArrFocusTypes"
var kUserdefaults24HoursClearPasswordTime = "kUserdefaults24HoursClearPasswordTime"
var kUserdefaultsSelectedLanguage = "kUserdefaultsSelectedLanguage"

let kUserdefaultsFocusAddedFromFirstHabit = "kUserdefaultsFocusAddedFromFirstHabit"
var kUserdefaultsDontShowToolBoxAutomatically = "kUserdefaultsShowToolBoxAutomatically"

var isAppEnable = true
var startTime:Time?
var shutOffTime:Time?

var upgradeButtonWasClicked = false

var isMainWindowLodded = false
var isPomodoroWindowLodded = false
var isHabitAlreadyShowed = true
var isFirstRun = false

var lastActivityPerformedTime:Date?
struct Time{
    var hour = 0
    var minute = 0
    var second = 0
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
}
//var isBreathingGoing = false
//var isHabitGoing = false
//var isBreakActivitiesGoing = false


var currentHabitIndex = -1
var currentActivityIndex = -1
var randomActivityIndex = 0
var currentActivityPlaying:breakActivity?
var currentHabitPlaying:habit?

var habitTotalCompletedSeconds = 0
var arrAllMorningHabits = [habit]()
var arrAllEveningHabits = [habit]()
var isLastActivityStoppedInRunningState = false
var lastActivityRunningId = ""
var lastActivityStoppedTimerCount = 0
struct habit {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var urlsArray:[String]
    var logQuantity:Bool!
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var allowedFocusMode:String!
    var activity_sequence_id:String!
    init(id:String, name:String, durationSeconds:Int, urlsArray:[String], logQuantity:Bool, logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],allowedFocusMode:String, activity_sequence_id:String) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.allowedFocusMode = allowedFocusMode
        self.activity_sequence_id = activity_sequence_id
    }
}




var introActivity:habit?

func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
    return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
}
func getStringTimeFromSeconds(seconds : Int)->String{
    let (h,m,s) = secondsToHoursMinutesSeconds(seconds: seconds)
    var stringTime: String = ""
    if h != 0{
        stringTime = "\(h)h"
    }
    if m != 0{
        if stringTime.isEmpty{
            stringTime = "\(m)m"
        }else{
            stringTime += " \(m)m"
        }
    }
    if s != 0{
        if stringTime.isEmpty{
            stringTime = "\(s)s"
        }else{
            stringTime += " \(s)s"
        }
    }
    return stringTime
}
var fireFoxNotificationShownForCurrentFocusMode = false// show a notification when they open firefox during a focus mode (only show it once per focus block)// so after showing notification once turn this var to true for current focus mode 


var activityAllowedFocusApps = [String]()
var activityAllowedFocusUrls = [String]()
//var showEveryBreak = false
var isAnyMandatoryActivityIncluded = false
var isMandatoryActivityGoing = false
var breakAfterMinutes = 0
var arrAllbreakActivities = [breakActivity]()
var arrActivitiesIncludeInEveryBreak = [breakActivity]()
var arrActivitiesExcludeInEveryBreak = [breakActivity]()
struct breakActivity {
    var id:String!
    var name:String!
    var durationSeconds:Int!
    var IncludeInEveryBreak:Bool!
    var urlsArray:[String]
    var logQuantity:Bool!
    var isRandomChoice:Bool!
    var choices:[activityChoice]
    var logQuantityQuestion:String?
    var openSpecificApps:Bool!
    var allowUrls:[String]!
    var allowApps:[String]!
    var isOfficeFriendly:Bool!
    var allowedFocusMode:String!
    var logQuantityType:String!
    var activity_sequence_id:String!
    init(id:String, name:String, durationSeconds:Int, IncludeInEveryBreak:Bool, urlsArray:[String], logQuantity:Bool,isRandomChoice:Bool,choices:[activityChoice],logQuantityQuestion:String?, openSpecificApps:Bool,allowUrls:[String],allowApps:[String],isOfficeFriendly:Bool,allowedFocusMode:String,logQuantityType:String,activity_sequence_id:String) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.IncludeInEveryBreak = IncludeInEveryBreak
        self.urlsArray = urlsArray
        self.logQuantity = logQuantity
        self.isRandomChoice = isRandomChoice
        self.choices = choices
        self.logQuantityQuestion = logQuantityQuestion
        self.openSpecificApps = openSpecificApps
        self.allowUrls = allowUrls
        self.allowApps = allowApps
        self.isOfficeFriendly = isOfficeFriendly
        self.allowedFocusMode = allowedFocusMode
        self.logQuantityType = logQuantityType
        self.activity_sequence_id = activity_sequence_id
    }
}


struct activityChoice {
    var id:String!
    var name:String!
    var urlsArray:[String]
    var logQuantityQuestion:String!
    var logQuantity:Bool!
    var logQuantityType:String!
    init(name:String, urlsArray:[String], logQuantityQuestion:String, logQuantity:Bool, logQuantityType:String, id:String) {
        self.id = id
        self.name = name
        self.urlsArray = urlsArray
        self.logQuantityQuestion = logQuantityQuestion
        self.logQuantity = logQuantity
        self.logQuantityType = logQuantityType
    }
}

let avmonitor = AVMonitor()

//////////////////////////////////////////////////////////START AT LOGIN//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//class LaunchOnStartup {
//    static func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItem?, lastReference: LSSharedFileListItem?) {
//        let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
//        let loginItemsRef = LSSharedFileListCreate(
//            nil,
//            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
//            nil
//        )!.takeRetainedValue() as LSSharedFileList?
//        if loginItemsRef != nil {
//            let loginItems = LSSharedFileListCopySnapshot(loginItemsRef!, nil)!.takeRetainedValue() as Array
//
//            if loginItems.count == 0 {
//                return (nil, kLSSharedFileListItemBeforeFirst.takeRetainedValue())
//            }
//
//            let lastItemRef: LSSharedFileListItem = loginItems.last as! LSSharedFileListItem
//
//            for currentItemRef in loginItems as! [LSSharedFileListItem] {
//                if let itemUrl = LSSharedFileListItemCopyResolvedURL(currentItemRef, 0, nil) {
//                    if (itemUrl.takeRetainedValue() as URL) == appUrl {
//                        return (currentItemRef, lastItemRef)
//                    }
//                }
//            }
//
//            return (nil, lastItemRef)
//        }
//        return (nil, nil)
//    }
    
//    static func setLaunchAtStartup(_ shouldLaunch: Bool) {
//
//        let itemReferences = itemReferencesInLoginItems()
//        let alreadyExists = (itemReferences.existingReference != nil)
//        let loginItemsRef = LSSharedFileListCreate(
//            nil,
//            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
//            nil
//        )!.takeRetainedValue() as LSSharedFileList?
//
//        if loginItemsRef != nil
//        {
//            if shouldLaunch
//            {
//                if !alreadyExists
//                {
//
//                    let appUrl = URL(fileURLWithPath: Bundle.main.bundlePath) as CFURL
//                    LSSharedFileListInsertItemURL(
//                        loginItemsRef!,
//                        itemReferences.lastReference!,
//                        nil,
//                        nil,
//                        appUrl,
//                        nil,
//                        nil
//                    )
//                }
//            }
//            else
//            {
//                if alreadyExists
//                {
//                    let WTLObject: addLoginitem = addLoginitem()
//                    //                    let WTLMemoryObject: WTLMemory = WTLMemory()
//                    let deletitem=WTLObject.itemRefInLoginItems()
//                    print(deletitem)
//
//
//                }
//            }
//
//        }
//    }
//}








extension Date {
    
    /// Create a date from specified parameters
    ///
    /// - Parameters:
    ///   - year: The desired year
    ///   - month: The desired month
    ///   - day: The desired day
    /// - Returns: A `Date` object
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
}
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
        //        if event.type == NSEvent.EventType.keyDown {
        //            if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
        //                switch event.charactersIgnoringModifiers! {
        //                case "x":
        //                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
        //                case "c":
        //                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
        //                case "v":
        //                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
        //                case "z":
        //                    if NSApp.sendAction(Selector(("undo:")), to:nil, from:self) { return true }
        //                case "a":
        //                    if NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to:nil, from:self) { return true }
        //                default:
        //                    break
        //                }
        //            }
        //            else if (event.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
        //                if event.charactersIgnoringModifiers == "Z" {
        //                    if NSApp.sendAction(Selector(("redo:")), to:nil, from:self) { return true }
        //                }
        //            }
        //        }
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
    case _START_ = 11, _INPROGRESS_, _END_, _VISUALIZE_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}



enum CURRENTSTATE:Int{
    case _NOTHING_ = 111, _MORNING_HABIT_, _EVENING_HABIT_, _ACTIVITY_, _SHUTOFFMAC_, _BREATHING_, _ABORT_, _FOCUS_SUMMARY_, _POSTPON_MORNING_HABIT_, _POSTPON_EVENING_HABIT_, _POSTPON_FOCUS_SUMMARY_, _POSTPON_ONBOARDING_HABIT_, _ASK_APP_WORK_//_POSTPON_BREAK_ACTIVITY_
}//_POSTPON_BREAK_ACTIVITY_ iski need nahi h qki normal timer utne hi time baad ka laga dete hai
var currentState:CURRENTSTATE = ._NOTHING_
var currentAction:ACTION = ACTION._START_

var lastCurrentState:CURRENTSTATE = ._NOTHING_//abort  cancel ho to to pta krne k liye 
var lastCurrentAction:ACTION = ACTION._START_



func playEveryActivitySound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
        
}

func playAfterMorningEveningRoutineSound(isMorning:Bool){
    if SettingsManagerObject.isSoundEnabled{
        if isMorning{
            if let sound = arrCompletingWholeMorningRoutineSound.randomElement(){
                NSSound(named: sound)?.play()
            }
        }else{
            if let sound = arrCompletingWholeEveningRoutineSound.randomElement(){
                NSSound(named: sound)?.play()
            }
        }
    }
    //    NSSound(named: "afterMorningRoutine")?.play()
}

func playFocusModeStartedSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartFocusSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
}
func playStartMorningEveningRoutineSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrStartingMorningEveningRoutineSound.randomElement(){
            NSSound(named: sound)?.play()
        }
    }
}
func playFocusPomodorBreakEndsSound(){
    if SettingsManagerObject.isSoundEnabled{
        if let sound = arrCompletingHabitSound.randomElement(){
            NSSound(named: sound)?.play()
        }
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


//var arrAllSounds = arrCompletingHabitSound + arrCompletingWholeEveningRoutineSound + arrCompletingWholeMorningRoutineSound + arrStartFocusSound + arrStartingMorningEveningRoutineSound





var startActivityButtonText = "Start <TIME> <NAME>"
var unlockMachineButtonText = "Unlock the machine"
var activityFinishedText = "<ACTIVITY> finished!✅"
var lastActivityFinishedText = "<ACTIVITY> finished!✅ You’ve earned your screen time. 💪"
var activitySkippedText = "<ACTIVITY> skipped!"
var lastActivitySkippedText = "<ACTIVITY> skipped! You’ve earned your screen time. 💪"
var startBreakActivityTitleText = "It’s time for a break. Do <TIME> of <ACTIVITY> to earn more screentime."
var doSomeActivityText = "Do some <ACTIVITY>."
var startMorningHabitTitleText = "Good Morning! It’s time to Focus Bear. Here are the habits you need to accomplish before you can use your computer."
var startEveningHabitTitleText = "Good Evening! It’s time to Focus Bear. Here are the habits you need to accomplish before you can leave for the day."
var emailID = "team@focusbear.io"
var appName = "Focus Bear"
var buttonCancelText = "Cancel"
var buttonOkText = "OK"
var buttonStatusStateFocusText = "FOCUS"
var buttonStatusStateOffText = "OFF"
var buttonStatusStateCallText = "CALL"
var buttonYesText = "Yes"
var buttonNoText = "No"

var secondsText = "seconds"
var minuteText = "minute"
var minutesText = "minutes"
var hourText = "hour"
var hoursText = "hours"

var graphQuantityText = "Quantity"
var graphMinutesText = "Minutes"
var graphDateText = "Date"
var graphTimeText = "Time"



var webhookUrl = "https://hooks.zapier.com/hooks/catch/326116/b98ovxc/"

var upgradeNowUrl = "https://dashboard.focusbear.io/subscription"
func readConfigFile(){
    addLog(text: "read Config File")
    if let activityInfo = configjson.value(forKey: "activityInfo") as? NSDictionary{
        startActivityButtonText = activityInfo.value(forKey: "startActivityButtonText") as? String ?? startActivityButtonText
        activityFinishedText = activityInfo.value(forKey: "activityFinishedText") as? String ?? activityFinishedText
        lastActivityFinishedText = activityInfo.value(forKey: "lastActivityFinishedText") as? String ?? lastActivityFinishedText
        startBreakActivityTitleText = activityInfo.value(forKey: "startBreakActivityTitleText") as? String ?? startBreakActivityTitleText
        doSomeActivityText = activityInfo.value(forKey: "doSomeActivityText") as? String ?? doSomeActivityText
        startMorningHabitTitleText = activityInfo.value(forKey: "startMorningHabitTitleText") as? String ?? startMorningHabitTitleText
        startEveningHabitTitleText = activityInfo.value(forKey: "startEveningHabitTitleText") as? String ?? startEveningHabitTitleText
        activitySkippedText = activityInfo.value(forKey: "activitySkippedText") as? String ?? activitySkippedText
        lastActivitySkippedText = activityInfo.value(forKey: "lastActivitySkippedText") as? String ?? lastActivitySkippedText
    }
    
    if let common = configjson.value(forKey: "common") as? NSDictionary{
        emailID = common.value(forKey: "emailId") as? String ?? emailID
        appName = common.value(forKey: "appName") as? String ?? appName
        buttonCancelText = common.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        buttonOkText = common.value(forKey: "buttonOkText") as? String ?? buttonOkText
        buttonYesText = common.value(forKey: "yesText") as? String ?? buttonYesText
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

        
    }
    upgradeNowUrl = configjson.value(forKey: "upgradeNowUrl") as? String ?? upgradeNowUrl

}
func getDoSomeActivityText(activityName:String)->String{
    return doSomeActivityText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
}

func getStartBreakActivityTitleText(seconds:Int, activityName:String)->String{
    let stringTime = getStringTime(seconds: seconds)
    var title = startBreakActivityTitleText.replacingOccurrences(of: "<TIME>", with: stringTime)
    title = title.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    return title
}
func getActivityFinishedText(isLast:Bool, activityName:String)->String{
    if isLast{
        return lastActivityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }else{
        return activityFinishedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }
}
func getActivitySkippedText(isLast:Bool, activityName:String)->String{
    if isLast{
        return lastActivitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }else{
        return activitySkippedText.replacingOccurrences(of: "<ACTIVITY>", with: activityName)
    }
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

    
//    if seconds < 60{
//        stringTime = "\(seconds) " + secondsText
//    }else{
//        let minutes = seconds/60
//
//        if minutes<60{
//            if minutes == 1 {
//                stringTime = "\(minutes) " + minuteText
//            }else {
//                stringTime = "\(minutes) " + minutesText
//            }
//        }else{
//            let hour = minutes/60
//            if hour == 1 {
//                stringTime = "\(hour) " + hourText
//            }else {
//                stringTime = "\(hour) " + hoursText
//            }
//        }
//
//    }
    return stringTime
}




func getstartActivityButtonText(seconds:Int, name:String)->String{
    var title = startActivityButtonText
    let stringTime = getStringTime(seconds: seconds)
    
    if title.localizedCaseInsensitiveContains("<TIME>"){
        title = title.replacingOccurrences(of: "<TIME>", with: stringTime)
    }
    if title.localizedCaseInsensitiveContains("<NAME>"){
        title = title.replacingOccurrences(of: "<NAME>", with: name)
    }
    return title
}

class cursorButton: NSButton {
    
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

class underLineButton: cursorButton {
    
    var titleColor = NSColor.labelColor
    func setDisable(title:String){
        isEnabled = false
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attrs = [NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    func setEnable(title:String){
        isEnabled = true
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = self.alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
        let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
        self.attributedTitle = attrString
    }
    
    override var title: String {
        didSet {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = self.alignment
            paragraph.lineBreakMode = .byTruncatingTail
            let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue] as [NSAttributedString.Key : Any]
            let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
            self.attributedTitle = attrString
        }
    }
}

let buttonTitleColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1)
let buttonBgColor = NSColor(red: 255/255, green: 228/255, blue: 198/255, alpha: 1)
class Button: NSButton {
    var mouseDown = false
    
    let titleDisableColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 1)
    @IBInspectable var horizontalPadding   : CGFloat = 50
    @IBInspectable var verticalPadding    : CGFloat = 50
    
    @IBInspectable var isForPrefrences    : Bool = false
    
    var borderWidth: CGFloat = 1{
        didSet{
            self.layer?.borderWidth = borderWidth
        }
    }
    var currentTitle = ""
    var buttonColor = buttonBgColor.cgColor{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = buttonTitleColor
            }else{
                self.layer?.backgroundColor = NSColor.lightGray.cgColor
                self.layer?.borderColor = NSColor.lightGray.cgColor
                self.titleColor = titleDisableColor
            }
        }
    }
    
    
    var buttonDownColor = NSColor(red: 226/255, green: 203/255, blue: 177/255, alpha: 1).cgColor
    var titleColor = buttonTitleColor{
        didSet{
            self.title = currentTitle
        }
    }
    var borderColor = NSColor(red: 232/255, green: 136/255, blue: 0/255, alpha: 1).cgColor
    override func awakeFromNib() {
        super.awakeFromNib()
        
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        self.isBordered = false
        self.layer?.cornerRadius = self.frame.height/7
        self.layer?.backgroundColor = buttonColor
//        if self.image == nil{
//            self.layer?.borderWidth = 1
//        }else{
//            self.layer?.borderWidth = 2
//        }
        self.layer?.borderWidth = borderWidth
        self.layer?.borderColor = borderColor
        self.contentTintColor = titleColor
    }
    
    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        if self.image == nil{// if not an image button than
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }else{
//            size.width += 20
//            let originalBounds = self.bounds
//            defer { self.bounds = originalBounds }
//
//            // Inset bounds by the image padding
//            self.bounds = originalBounds.insetBy(
//                dx: 10,
//                dy: 0
//            )
            size.width += self.horizontalPadding
            size.height += self.verticalPadding
        }
        return size;
    }
    override func draw(_ dirtyRect: NSRect) {
       // if self.image != nil{
            let originalBounds = self.bounds
            defer { self.bounds = originalBounds }

            // Inset bounds by the image padding
            self.bounds = originalBounds.insetBy(
                dx: 10,
                dy: 0
            )
        //}
        // Draw the button content with padding
        super.draw(dirtyRect)
    }
    
    
    override var title: String {
        didSet {
            currentTitle = title
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            let fontManager = NSFontManager.shared
            if !isForPrefrences{
                let boldFont = fontManager.font(
                    withFamily: "Courier New",
                    traits: [.boldFontMask],
                    weight: 0,
                    size: self.font?.pointSize ?? 50)
                let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, .font:boldFont ?? NSFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
                let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
                self.attributedTitle = attrString
            }else{
                let attrs = [NSAttributedString.Key.foregroundColor: titleColor, NSAttributedString.Key.paragraphStyle: paragraph, .font:self.font ?? NSFont.systemFont(ofSize: 12)] as [NSAttributedString.Key : Any]
                let attrString: NSAttributedString = NSAttributedString(string: title, attributes: attrs)
                self.attributedTitle = attrString
            }
        }
    }
    
    override var isEnabled: Bool{
        didSet{
            if isEnabled{
                self.layer?.backgroundColor = buttonColor
                self.layer?.borderColor = borderColor
                self.titleColor = buttonTitleColor
            }else{
                self.layer?.backgroundColor = NSColor.lightGray.cgColor
                self.layer?.borderColor = NSColor.lightGray.cgColor
                self.titleColor = titleDisableColor
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = buttonDownColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                if isEnabled{// possible to be in disable state after mouse down
                    NSCursor.pointingHand.set()
                }
            }
            if isEnabled{// possible to be in disable state after mouse down
                self.layer?.backgroundColor = buttonColor
            }
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        if self.isEnabled{
            NSCursor.arrow.set()
            self.layer?.backgroundColor = buttonColor
        }
    }
}


class mouseDownEffectButton: NSButton {
    var mouseDown = false

    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))
        self.wantsLayer = true
        
        if let box = self.superview?.superview as? NSBox{
            self.layer?.cornerRadius = box.cornerRadius
        }
    }
    override func mouseDown(with event: NSEvent) {
        //        super.mouseDown(with: event)
        if self.isEnabled{
            print("mouseDown")
            mouseDown = true
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.2).cgColor
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        // super.mouseUp(with: event)
        if self.isEnabled{
            print("mouseUP")
            if mouseDown {
                mouseDown = false
                if self.action != nil{
                    NSApp.sendAction(self.action!, to: self.target, from: self)
                }
                
                NSCursor.pointingHand.set()
            }
            self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
        }
    }
    override func mouseEntered(with event: NSEvent) {
        if self.isEnabled{
            NSCursor.pointingHand.set()
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
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
//func getSchemsFile(completionHandler: @escaping(_ result: NSDictionary?) -> ()) {
//    if let myUrl = NSURL(string: "https://focus-bear.github.io/assets/config/settings-schema.json"){
//
//        let request = NSMutableURLRequest(url:myUrl as URL);
//        request.httpMethod = "GET";
//
//        let task = URLSession.shared.dataTask(with: request as URLRequest) {
//            data, response, error in
//
//            if let httpResponse = response as? HTTPURLResponse {
//                if httpResponse.statusCode == 200{
//
//                    if data != nil{
//
//                        do {
//                            if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data!, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//
//                                print(jsonResult)
//                                completionHandler(jsonResult)
//                                return
//                            }
//
//                        }catch{
//                            print(error)
//                        }
//
//                    }
//                    completionHandler(nil)
//                    return
//                }else{
//                    completionHandler(nil)
//                    return
//                }
//            }
//            if error != nil {
//                completionHandler(nil)
//                return
//            }
//            completionHandler(nil)
//        }
//        task.resume()
//    }else{
//        completionHandler(nil)
//    }
//}


let allApiObject = AllApi()


var DebugLogsFolderURL:URL!
var DebugLogsURL:URL!
var quantityCsvURL:URL!
//var blockURL:URL!
var blockWebUrlString = ""
class Log: TextOutputStream {
    
    func write(_ string: String) {
        //        let fm = FileManager.default
        let log = DebugLogsURL!//fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Debug_Logs.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
    static var log: Log = Log()
    private init() {} // we are sure, nobody else could create it
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


class customBox: NSBox {
    var mouseDown = false
    var tagValue = 0
    var isTableView = false
    override func awakeFromNib() {
        super.awakeFromNib()
        addTrackingArea(NSTrackingArea(rect: bounds, options: [.activeAlways, .inVisibleRect, .mouseEnteredAndExited], owner: self, userInfo: nil))

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
        
        
        if isTableView{
            if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                showUpgradeNowWindow()
                return;
            }
            
            if arrFocusType[tagValue]["isOn"] as? Bool == true{
                //abort focus mode
                if isHardCorePomodoroModeOn{
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        if SettingsManagerObject.isPasswordRequireInStopPomodoro{
                            menuViewControllerObj?.showPasswordWindow()
                            addLog(text: "Showing enter password view from hardcodre pomodoro stop from focus stop menu")
                        }else{
                            showAbortingFocusModeVc()
                        }
                        
                    }else{
                        showAbortingFocusModeVc()
                    }
                }else{
                    showAbortingFocusModeVc()
                }
            }else{
                if isHardCorePomodoroModeOn{
                    
                    return;
                }
                for i in 0..<arrFocusType.count{
                    if arrFocusType[i]["isOn"] as? Bool == true{
                        let alert = NSAlert()
                        alert.setSharingType()
                        alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
                        
                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                            if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
                                alert.messageText = focusAlreadyRunningText
                            }
                        }
                        alert.runModal()
                        return;
                    }
                }
                
                
                
                
                // new work starting foces mode
                
                //                if arrFocusType[tagValue]["isDefault"] as? Bool == true{
                //                    if focusPreferencesVcObj != nil{// Discourage Default Focus Vc se pahle preferences band kr denege taki vha se koi focus mode chalu na kar pay
                //
                //                        if preferencesWindowControllerObj?.window?.isVisible ?? false{
                //                            preferencesWindowControllerObj?.window?.close()
                //                        }
                //                    }
                //                    if focusModeStartWindowLodded{
                //                        if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                //                            startingFocusWindowControllerObj!.window?.close()
                //                        }
                //                    }
                //                    menuViewControllerObj!.presentAsSheet(getDiscourageDefaultFocusVcObject())
                //                    getDiscourageDefaultFocusVcObject().resetData()
                //                }else{
                
                showStartingFocusMode(focusModeIndex: tagValue, focusType: arrFocusType[tagValue]["name"] as? String ?? "")
                //                startingFocusWindowControllerObj?.window.
                
                //                }
                
                
                
                return;
                
            }
            
            
        }
    }
    
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
//        self.fillColor = NSColor.clear
        mouseDown = false
        NSCursor.arrow.set()
        self.layer?.backgroundColor = NSColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0).cgColor
    }
}
var isDiscourageDefaultFocusVcVisible = false
var focusModeStartWindowLodded = false
var isFocusModeStartedFromPomodoroMode = false
var isSkipBreakActivityDuringPomodoro = false
func showStartingFocusMode(focusModeIndex: Int, focusType: String){
    addLog(text: "Showing Starting Focus Mode view")
    startingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    startingFocusWindowControllerObj?.contentViewController = startingFocusModeVcObj
    startingFocusWindowControllerObj?.showWindow(nil)
    startingFocusModeVcObj?.ResetData(focusModeIndex: focusModeIndex, focusType: focusType)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
func showAbortingFocusModeVc(){
    addLog(text: "Showing Abort focus mode view")
    startingFocusWindowControllerObj?.contentViewController = abortingFocusModeVcObj
    startingFocusWindowControllerObj?.showWindow(nil)
    abortingFocusModeVcObj?.ResetData()
    NSApplication.shared.activate(ignoringOtherApps: true)
}

let jobTypeProgramming = "Programming"
let jobTypeGraphicDesign = "GraphicDesign"
let jobTypeDataAnalysis = "DataAnalysis"
let jobTypeSomethingElse = "SomethingElse"

var focusDefaultAllowApps = ["finder", "universalaccessauthwarn", "system preferences", "loginwindow", "screensaverengine"]
var arrFocusType = [[String:Any]]()
var isAllowedAllAppsInFocus = false
var isAllowedAllUrlsInFocus = false
var isBlockedAllUrlsInFocus = false
var isAllowedListApproachInFocus = true
var selfAppName = Bundle.main.infoDictionary!["CFBundleName"] as! String


var whatToAchieveInFocusBlock = ""
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

var timerForFocusMode:Timer?//jab bhi focus mode disable krenge timer bhi check krenge valid ua to invalidate krenge
var isFocusTimeType:FocusModeTimeType = ._NONE_
var endFocusModeTime:Date?// ye to vo h jo start foccus k time per hisab lgaya ki end focus ka time kya hoga
var startFocusModeTime:Date?
var startFocusModeTimeForPauseAndResume:Date?
var focusModeActualDurationPerformed:Int = 0// ye kaam aaygi log vali file jo export hoti hai . usme likhvane k liye.. jese fi focus mode finish hoga duuration is var mai likhva lenge fir log mai add krenge (fir ussse focus summary dikhaynge )
var focusModeMinutesToPerform = 0
var focusModeSecondsToPerform = 0 //pause// resume k liye 
enum FocusModeTimeType:Int{
    case _HOUR_ = 11, _TILL_SHUTOFF_, _NONE_
}

func isFocusModeOn()->Bool{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return true
        }
    }
    return false
}

func getRunningFocusModeId()->String{
    for dic in arrFocusType{
        if dic["isOn"] as? Bool == true{
            return dic["id"] as? String ?? ""
        }
    }
    return ""
}

//pomodoro
func resetPomodoroVcFocusListIfNeeded(){
    if isPomodoroWindowLodded{
        if pomodoroWindowControllerObj != nil{
            if (pomodoroWindowControllerObj?.window!.isVisible)!{
                if pomodoroWindowControllerObj?.contentViewController == pomodoroVcObj{
                    pomodoroVcObj?.reFillFocusTypeList()
                }
            }
        }
    }
}


//CSV new entry
func addEntryInCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        csv = csv.appending(csvString)
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


//CSV replace Last entry
func replaceLastEntryInCsv(logType:String, activity:String, durationInSeconds:String, quantityQuestion:String, quantityLogged:String, startTime:String, workAchieved:String, distractionsEncountered:String, abortReason:String, feedback:String ){
    do {
        var csv = try String(contentsOf: quantityCsvURL, encoding: .utf8)
        let timestamp = getStringFromDate(date: Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
        
        let csvString = "\(logType),\(timestamp),\(activity),\(durationInSeconds),\(quantityQuestion),\(quantityLogged),\(startTime),\(workAchieved),\(distractionsEncountered),\(abortReason),\(feedback)\n"
        
        csv = csv.replaceLastLineWith(newLine: csvString)
        
        do {
            try csv.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }catch{
        print(error)
    }
}


extension String {
    func replaceLastLineWith(newLine:String)->String {
        var comps = self.split(separator: "\n")
        comps.removeLast()
        var outputString = ""
//        var br = "\n"
        for sub in comps {
            outputString.append(String(sub)+"\n")
        }
        outputString = outputString.appending(newLine)
        return outputString
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
func showBlankWindowInSecondaryMonitor(){
//    if appdelegate!.alertSuggestFocusMode != nil{
//        if appdelegate!.alertSuggestFocusMode!.window.isVisible{
////            appdelegate!.alertSuggestFocusMode!.window.close()
//            NSApp.stopModal()
//        }
//    }
    
    // Luisa App broken bug fix 28/6/22
    let windows = NSApp.windows
    for win in windows{
        print(win)
        if win.isModalPanel{
            NSApp.stopModal()
            break;
        }
    }
    //  /////////////////////////////////
    appdelegate?.showExtraWindows()
}


func hideBlankWindowInSecondaryMonitor(){
    for i in 0..<arrWindows.count{
        let window = arrWindows[i]
        //        if let vc = window.contentViewController as? ViewController{
        //            vc.customView.cbox?.isHidden = true
        //            vc.customView.setNeedsDisplay(vc.customView.frame)
        //            vc.customView.cRect = NSRect(x: 0, y: 0, width: 0, height: 0)
        //            vc.customView.mouseDownPoint = NSPoint.zero
        //        }
        window.orderOut(nil)
        arrWindows[i].windowController?.window=nil
    }
    arrWindows.removeAll()
}
var arrWindows = [NSWindow]()


func resetWin(_ win: NSWindow) -> NSWindow {
    win.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these windows to follow Spaces around
    //use .desktopWindow for window below icons   //hack? this makes mission control and expose ignore these windows
    //        if toggleButtonHideDesktopIcons.isOn{
    //            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
    //        }else{
    win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    //        }
    // rest is to make the windows dumb
    win.canHide = false
    win.isExcludedFromWindowsMenu = true
    win.hidesOnDeactivate = false
    win.discardCursorRects()
    win.discardEvents(matching: NSEvent.EventTypeMask.any, before: nil)
    //win.ignoresMouseEvents = true
    win.orderBack(nil)
    win.isRestorable = false
    win.animationBehavior = .none
    win.backgroundColor = NSColor.clear
    return win
}

class blankController: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        lblTitle.stringValue = appName//"Focus Bear"
    }
}
//4b3eb33632184640b82aa3e3f50fe11b2cdd8b0e82ce48a8bfd1cbe26edc32f5

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
    print(domain)
    
    if domain.contains("www."){
        domain = domain.replacingOccurrences(of: "www.", with: "")
    }
    print("****")
    return domain
}

func isPreventUserIdleDisplaySleepOn()-> Bool{
    var assertions: Unmanaged<CFDictionary>?
    if IOPMCopyAssertionsByProcess(&assertions) != kIOReturnSuccess {
       fatalError("Error with assertions")
    }
    var dic = [AnyHashable : Any]()
    
   //print(assertions!.takeUnretainedValue())
    //var stringDic = "\(assertions!)"
    if assertions != nil{
        
        let val = assertions!.takeRetainedValue()
        print(val)
        
        
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
    
//    addLog(text: "is Prevent UserIdle Display SleepOn Called")
    let processArray = ["zoom.us", "teams"]// lowercased names aynge sirf
//    let dic = avmonitor.getSystemAssertionDic()
   // addLog(text: "is Prevent UserIdle Display SleepOn return \(dic)")
    //print(dic)
//    if dic == nil{
//        addLog(text: "is Prevent UserIdle Display SleepOn return false because dic is nil")
//        return false
//    }
    let keys  = dic.keys
    for key in keys{
        if let arr = dic[key] as? NSArray{
            //                addLog(text: "is Prevent UserIdle Display SleepOn success :- arr = dic?[key] as? NSArray")
            for item in arr{
                //                        print(item as? NSDictionary)
                if let itemDic = item as? NSDictionary{
                    //print(itemDic)
                    //print(itemDic.value(forKey: "AssertionTrueType") as?  String ?? "")
                    if itemDic.value(forKey: "AssertionTrueType") as?  String ?? ""  == "PreventUserIdleDisplaySleep"{
                        //print(itemDic.value(forKey: "Process Name") as?  String ?? "")
                        if let name = itemDic.value(forKey: "Process Name") as?  String{
                            let processName = name.lowercased()
                            if processName != selfAppName.lowercased(){
                                if processArray.contains(processName){
                                    //addLog(text: "is Prevent UserIdle Display SleepOn return true \(itemDic)")
                                    return true
                                }
                            }
                            
                        }
                        //                                zoom.us, teams
                    }
                    
                }
            }
        }
    }
    
//    addLog(text: "is Prevent UserIdle Display SleepOn return false")
    return false
}


//"safari", "google chrome", "sidekick", "brave browser"]// lowercased names aynge sirf
////        .zoom.us
////meet.google.com
var lastShownRandomChoiceDic = [String:activityChoice]()



let mainAppBundelId = Bundle.main.bundleIdentifier ?? ""
func createLaunchAgent(){
    
    let path = Bundle.main.bundlePath
    
    let destination = "/Users/\(NSUserName())/Library/LaunchAgents/"
    if !FileManager.default.fileExists(atPath: destination) {
        
        do {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: destination), withIntermediateDirectories: true, attributes: nil)
        } catch {}
        
    }
    
    // saves the agent plist file
    let userLaunchAgentsPath = "\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"
    
    let dicContent = ["Label": "\(mainAppBundelId).plist", "ProgramArguments":["/usr/bin/open","-F","-g",path,"--args"],"RunAtLoad":true,"KeepAlive":true] as [String : Any]
    
    let plistContent = NSDictionary(dictionary: dicContent)
    let success:Bool = plistContent.write(toFile: userLaunchAgentsPath, atomically: true)
    if success {
        print("file has been created!")
    }else{
        print("unable to create the file")
    }
    shell(launchPath: "/bin/launchctl", arguments: ["load","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
}
func shell(launchPath: String, arguments: [String] = [])  {
    
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



//***********SHOW Small Timer WINDOW***************//

func showSmallTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool, currentTimerValue:Int){
    addLog(text:"show Top Small Timer Window")
    getSmallCountDownWindowObject().contentViewController = getsmallCountDownVcObject()
    smallCountDownVcObj?.isFocusBreak = isFocusBreak
    getSmallCountDownWindowObject().window?.styleMask = .borderless
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    
    getSmallCountDownWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (smallCountDownVcObj?.view.frame.width)!, y: screenFrame.height - (smallCountDownVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    getSmallCountDownWindowObject().window?.isMovableByWindowBackground = true
    
    getSmallCountDownWindowObject().showWindow(nil)
    
    smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, msg: msg, currentTimerValue:currentTimerValue)
}


//***********SHOW Custom Notification WINDOW***************//
//func showCustomNotificationWindow(msg: String){
//    addLog(text:"show Custom Notification Window")
//    getCustomNotificationWindowObject().contentViewController = getCustomNotificationVcObject()ye view  subview bhi ban rha h to dekh k use kro agar uncomment kro to
//    getCustomNotificationWindowObject().window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//    getCustomNotificationWindowObject().window?.backgroundColor = NSColor.clear
//    getCustomNotificationWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (customNotificationVcObj?.view.frame.width)!, y: screenFrame.height - (customNotificationVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
//
//    getCustomNotificationWindowObject().showWindow(nil)
//    customNotificationVcObj?.resetView(msg: msg)
//}

//***********SHOW Custom Notification View***************//
func showCustomNotificationView(msg: String){
    if mainWindowControllerObj?.window?.isVisible ?? false{
        addLog(text:"show Custom Notification View")
        let _ = getCustomNotificationVcObject()
        mainViewControllerObj?.view.addSubview(customNotificationVcObj!.view)
        mainViewControllerObj?.view.addTopRightConstraints(subView: customNotificationVcObj!.view)
        customNotificationVcObj!.resetView(msg: msg)
    }
    
}


//***********SHOW Toolbox window***************//
func showToolboxWindow(){
    addLog(text:"show Toolbox Window")
    getToolBoxWindowObject().contentViewController = getToolBoxVcObject()
//    getCustomNotificationWindowObject().window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getToolBoxWindowObject().window?.backgroundColor = NSColor.clear
//    getToolBoxWindowObject().window?.setFrameOrigin(NSPoint(x: 0, y: ((screenFrame.height/2) - 250))) //  22 status bar height
    getToolBoxWindowObject().window?.title = "Focus Bear - Toolbox"
    if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
        getToolBoxWindowObject().window?.title = toolBoxVcInfo.value(forKey: "windowTitleText") as? String ?? "Focus Bear - Toolbox"
    }
    getToolBoxWindowObject().showWindow(nil)
    toolBoxVcObj?.resetView()
}

//***********SHOW ask appwork window***************//
func showAskAppWorkWindow(){
    addLog(text:"show ask app work Window")
    getAskAppWorkWindowObject().contentViewController = getAskAppWorkVcObject()
    getAskAppWorkWindowObject().window?.backgroundColor = NSColor.clear
    getAskAppWorkWindowObject().window?.title = appName
    getAskAppWorkWindowObject().showWindow(nil)
}

//***********SHOW BRAIN DUMP WINDOW***************//

func showBrainDumpWindow(){
    addLog(text: "func:- showBrainDumpWindow")
    if brainDumpWcObj == nil{
        getBrainDumpWindowObject().contentViewController = getBrainDumpVcObject()
        brainDumpWcObj?.window?.styleMask.insert(.resizable)
        brainDumpWcObj?.window?.title = "Focus Bear - Brain dump"
        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
            brainDumpWcObj?.window?.title = brainDumpVcInfo.value(forKey: "title") as? String ?? "Focus Bear - Brain dump"
        }
        brainDumpWcObj?.window?.standardWindowButton(.zoomButton)!.isHidden = true
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        brainDumpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (brainDumpVcObj?.view.frame.width)!, y: screenFrame.height - (brainDumpVcObj?.view.frame.height)! - 22 - 140)) //  22 status bar heigh // timer window height is 100 // 20 is title bar height  and 20 is extra space to add
    }
    
    
    brainDumpWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********Popup Block Confirm Window***************//

func showPopupBlockConfirmWindow(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool){
    addLog(text: "func:- PopupBlockConfirmWindow")
    if popUpBlockConfirmWcObj == nil{
        getPopUpBlockConfirmWindowObject().contentViewController = getPopUpBlockConfirmVcObject()
        popUpBlockConfirmWcObj?.window?.styleMask.remove(.closable)
        popUpBlockConfirmWcObj?.window?.title = appName
        popUpBlockConfirmWcObj?.window?.backgroundColor = NSColor.clear
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        popUpBlockConfirmWcObj?.window?.setFrameOrigin(.init(x: screenFrame.width / 2, y: screenFrame.height / 2))
    }
    popUpBlockConfirmWcObj!.showWindow(nil)
    popUpBlockConfirmVcObj?.resetView(blockedAppName: blockedAppName, currentApp:currentApp, url:url, script:script, isBlockApp:isBlockApp)
}
//-------------------------------------------------//


//***********show Break Warning Window***************//

func showBreakWarningWindow(){
    addLog(text:"showBreakWarningWindow")
    getBreakWarningWindowObject().contentViewController = getBreakWarningVcObject()
//    getBreakWarningWindowObject().window?.styleMask = .borderless

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getBreakWarningWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (breakWarningVcObj?.view.frame.width)!, y: screenFrame.height - (breakWarningVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    
    breakWarningWcObj!.window?.styleMask.remove(.closable)
    breakWarningWcObj?.window?.title = appName
    breakWarningWcObj!.showWindow(nil)
    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********show Break Warning Window***************//

func showPreloadFocusModesWindow(){
    addLog(text:"showBreakWarningWindow")
    getPreloadFocusModesWindowControllerObj().contentViewController = getPreloadFocusModesVcObj()

    
    preloadFocusModesWindowControllerObj!.window?.styleMask.remove(.closable)
    preloadFocusModesWindowControllerObj?.window?.title = appName
    preloadFocusModesWindowControllerObj!.showWindow(nil)
//    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********show Break Warning Window***************//

func showEasyPostponeWindow(){
    addLog(text:"showEasyPostponeWindow")
    getEasyPostponeWindowObject().contentViewController = getEasyPostponeVcObject()

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    easyPostponeWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (easyPostponeVcObj?.view.frame.width)!, y: screenFrame.height - (easyPostponeVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    
    easyPostponeWcObj!.window?.styleMask.remove(.closable)
    easyPostponeWcObj?.window?.title = appName
    easyPostponeWcObj!.showWindow(nil)
//    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********show PopUp Offline Window***************//

func showPopUpOfflineWindow(){
    addLog(text:"showPopUpOfflineWindow")
    getPopUpOfflineWindowObject().contentViewController = getPopUpOfflineVcObject()

    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    popUpOfflineWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (popUpOfflineVcObj?.view.frame.width)!, y: screenFrame.height - (popUpOfflineVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    popUpOfflineWcObj?.window?.title = appName
    popUpOfflineWcObj!.showWindow(nil)
//    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//

//***********SHOW Ask Login Window ***************//

func showAskLoginWindow(){
    addLog(text:"showAskLoginWindow")
    getAskLogInWindowObject().contentViewController = getAskLogInVcObject()
    askLogInWcObj?.window?.title = appName
    appdelegate!.statusbutton?.action = nil
    askLogInWcObj!.showWindow(nil)
}
//-------------------------------------------------//



//***********SHOW Custom Login Window ***************//

func showCustomLoginWindow(isLogin:Bool){
    addLog(text:"showCustomLoginWindow")
    getAskLogInWindowObject().contentViewController = getCustomLoginVcObject()
    appdelegate!.statusbutton?.action = nil
    customLoginVcObj?.isLogin = isLogin
    askLogInWcObj!.showWindow(nil)
}
//-------------------------------------------------//


//***********SHOW Custom Login Window ***************//

//func showLoginHelpWindow(){
//    addLog(text:"showLoginHelpWindow")
//    getLoginHelpWindowObject().contentViewController = getLoginHelpVcObject()
//    loginHelpWcObj!.showWindow(nil)
//
//    loginHelpWcObj!.window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//
//    loginHelpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (loginHelpVcObj!.view.frame.width), y: screenFrame.height - (loginHelpVcObj!.view.frame.height) - 22)) //  22 status bar heigh
//    loginHelpWcObj!.window?.isMovableByWindowBackground = true
//
//}
//-------------------------------------------------//

//***********SHOW Onboarding Card Window ***************//

func showOnboardingCardWindow(isLogin:Bool){
    addLog(text:"showOnboardingCardWindow")
    getOnboardingCardsWindowObject().contentViewController = getOnboardingCardsVcObject()
    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
    onboardingCardsVcObj?.isLogin = isLogin
    onboardingCardsWcObj!.showWindow(nil)
    
//    loginHelpWcObj!.window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//
//    loginHelpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (loginHelpVcObj!.view.frame.width), y: screenFrame.height - (loginHelpVcObj!.view.frame.height) - 22)) //  22 status bar heigh
//    loginHelpWcObj!.window?.isMovableByWindowBackground = true

}
//-------------------------------------------------//

//***********SHOW Upgrade Now Window ***************//

func showUpgradeNowWindow(){
    addLog(text:"showUpgradeNowWindow")
    if upgradeNowWcObj == nil{
        getUpgradeNowWindowObject().contentViewController = getUpgradeNowVcObject()
        upgradeNowWcObj?.window?.title = appName
    }
    upgradeNowWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********SHOW WelcomeOnbarding window ***************//

func showWelcomeOnboardingWindow(){
    addLog(text:"showWelcomeOnboardingWindow")
    appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
    if welcomeOnboardingWcObj == nil{
        getWelcomeOnboardingWindowObject().contentViewController = getWelcomeOnboardingVcObject()
        welcomeOnboardingWcObj?.window?.title = appName
    }
    welcomeOnboardingWcObj!.showWindow(nil)
    if appdelegate!.onboardingTimer != nil{
        appdelegate!.onboardingTimer?.invalidate()
        appdelegate!.onboardingTimer = nil
    }
}
//-------------------------------------------------//

//***********SHOW Onbarding video window ***************//

var onboardingVideoStartTime:Date?
func showOnboardingVideoWindow(){
    addLog(text:"showOnboardingVideoWindow")
    appdelegate!.checkSystemTimeAndShowWindow()
    if onboardingVideoWcObj == nil{
        getOnboardingVideoWindowObject().contentViewController = getOnboardingVideoVcObject()
        onboardingVideoWcObj?.window?.title = appName
        onboardingVideoWcObj?.window?.styleMask.insert(.resizable)
        onboardingVideoWcObj?.window?.contentMinSize = NSSize(width: 1050, height: 837)
        onboardingVideoWcObj?.window?.setContentSize(NSSize(width: 1050, height: 837))
    }
    getOnboardingVideoVcObject().startOnboardingVideo()
    UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
    onboardingVideoWcObj!.showWindow(nil)
    onboardingVideoStartTime = Date()
}
//-------------------------------------------------//

func runAppleScriptFile(path:String){
    let task = Process()
    task.launchPath = "/usr/bin/osascript"
    task.arguments = [path]
    
    task.launch()
}

func workBeforeFocusBegin(index:Int){
    if let val = arrFocusType[index]["isScriptBeforeFocusEnabled"] as? Bool{
        if val{
            if let path = arrFocusType[index]["scriptPathBeforeFocus"] as? String{
                runAppleScriptFile(path: path)
            }
        }
    }
    if let val = arrFocusType[index]["isAutoDoNotDisturbEnabled"] as? Bool{
        if val{
            if isAccessibilityEnabled(isPrompt: true){
                enableDND()
            }
        }
    }
}
func workAfterFocusBegin(index:Int){
    if let val = arrFocusType[index]["isScriptAfterFocusEnabled"] as? Bool{
        if val{
            if let path = arrFocusType[index]["scriptPathAfterFocus"] as? String{
                runAppleScriptFile(path: path)
            }
        }
    }
    if let val = arrFocusType[index]["isAutoDoNotDisturbEnabled"] as? Bool{
        if val{
            if isAccessibilityEnabled(isPrompt: false){
                disableDND()
            }
        }
    }
}

//*****************************Read data from csv******************************//
func readDataFromCSV(url:URL)-> [[String]]{
    var arrItems = [[String]]()
    if let string = try? String(contentsOf: url){
        print(string)
        let arrCsv = csv(data: string)
        print(arrCsv)
        for item in arrCsv{
            if let row = item.first{
                print(row)
                var arrHeaders = [String]()
                let arrString = getArrItem(data: row)
                //                    if arrHeaders.count == 0{
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



extension Date {
    
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        
        let currentCalendar = Calendar.current
        
        guard let start = currentCalendar.ordinality(of: comp, in: .era, for: date) else { return 0 }
        guard let end = currentCalendar.ordinality(of: comp, in: .era, for: self) else { return 0 }
        
        return end - start
    }
}



var arrLanguageDic = [["name":"English", "id":"en"], ["name":"Spanish", "id":"es"]]
var currentLanguageCode = ""


class PopoverAwareTextField: NSTextField, NSPopoverDelegate {

    var parentVcObj:rememberNextHabitVc?
    var itemsArr = [String]()
    var popoverViewControllerObj:PopoverViewController?// = PopoverViewController()
    var selectedItemId = -1
//    lazy var popover: NSPopover = {
//        let popover = NSPopover()
//        popover.behavior = .semitransient
//        popover.contentViewController = popoverViewControllerObj
//        popover.delegate = self
//        return popover
//    }()
    
    override func becomeFirstResponder() -> Bool {
        
        print("becomeFirstResponder")
        if popoverViewControllerObj!.view.isHidden == false{
            return super.becomeFirstResponder()
        }
        
        if itemsArr.count != 0{
            selectedItemId = -1


//            self.superview?.addSubview(popoverViewControllerObj.view)
//            addConstraints()
//            popover.show(relativeTo: self.frame, of: NSApp.keyWindow?.contentView ?? self, preferredEdge: .minY)
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
    
//    func addConstraints() {
////        popoverViewControllerObj.view.translatesAutoresizingMaskIntoConstraints = false
//        //Trailing
//        let width = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
//        //Leading
//        let leading = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
//        //Bottom
////        let bottom = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .bottom, relatedBy: .equal, toItem: self.superview, attribute: .bottom, multiplier: 1.0, constant: 0.0)
//        //Height to be fixed for SubView same as AdHeight
//        let height = NSLayoutConstraint(item: popoverViewControllerObj.view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
//        self.addConstraint(width)
////        self.superview?.addConstraint(bottom)
//        self.superview?.addConstraint(leading)
//        //Add height constraint to the subview, as subview owns it.
//        self.addConstraint(height)
//    }
    
    @objc func Close(){
//        popover.close()/////
        popoverViewControllerObj!.view.isHidden = true
    }
//    @objc func ChangeState(){
//        isShown = false
//    }
    
//    func popoverDidClose(_ notification: Notification) {
//        self.perform(#selector(ChangeState), with: nil, afterDelay: 1)
//    }
    
//    override func keyDown(with event: NSEvent) {
//        if event.keyCode == 126{
//            return
//        }
//        if event.keyCode == 125{
//            return
//        }
//        super.keyDown(with: event)
//    }
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
//                if let _ = result.range(of: self.stringValue, options: [String.CompareOptions.anchored, .caseInsensitive]) {
//                    matches.append(result)
//                }
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


//func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
//    var error = error
//
//
//
//    let nonDigits = CharacterSet(charactersIn: "0123456789.").inverted
//
//    if (partialString as NSString).rangeOfCharacter(from: nonDigits).location != NSNotFound {
//
//        error = AutoreleasingUnsafeMutablePointer<NSString?>(mutating: "Input is not an integer")
//
//        return false
//    } else {
//
//        error = nil
//
//        return true
//    }
//}










extension NSTextField{
    func setFocus(){
        self.selectText(self)
        self.currentEditor()?.selectedRange = NSRange(location: 0, length: self.stringValue.count)
    }
}







//public extension NSTextField
//{
//    var isFocused:Bool {
//        if
//            window?.firstResponder is NSTextView,
//            let fieldEditor = window?.fieldEditor(false, for: nil),
//            let delegate = fieldEditor.delegate as? NSTextField,
//            self == delegate
//        {
//            return true
//        }
//        return false
//    }
//}


func getUuid()->String{
    return UUID().uuidString.lowercased()
}


func showAlertNoInternet(window:NSWindow){
//        if self.view.window == nil{// doing this beacuse when window is opening for the first time and if window is not completely loddded than it should wait for window (verna crash ho rha tha)
//            self.perform(#selector(showAlertNoInternet), with: nil, afterDelay: 1)
//            return;
//        }
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


//*****************Safari Chrome Active Tab Url and Titlle*********************//

enum BROWSER:Int{
    case _GOOGLE_CHROME_ = 152, _SAFARI_, _BRAVE_BROWSER_, _SIDEKICK_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}

func getSafariActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
func getSafariActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set tabtitle to name of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}




func getGoogleChromeActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}

func getGoogleChromeActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}

func getBraveBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
func getBraveBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}


func getSidekickBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}
func getSidekickBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    if let appleScript = NSAppleScript(source: script) {
        
        var errors : NSDictionary? = nil
        let desc = appleScript.executeAndReturnError(&errors)
        if errors != nil {
            print(errors)
        }
        return desc.stringValue
    }
    return nil
}

func getActiveTabUrlOf(browser:BROWSER)->String?{
    if browser == ._SAFARI_{
        return getSafariActiveTabUrl()
    }else if browser == ._GOOGLE_CHROME_{
        return getGoogleChromeActiveTabUrl()
    }else if browser == ._BRAVE_BROWSER_{
        return getBraveBrowserActiveTabUrl()
    }else if browser == ._SIDEKICK_{
        return getSidekickBrowserActiveTabUrl()
    }
    return nil
}

func getActiveTabTitleOf(browser:BROWSER)->String?{
    if browser == ._SAFARI_{
        return getSafariActiveTabTitle()
    }else if browser == ._GOOGLE_CHROME_{
        return getGoogleChromeActiveTabTitle()
    }else if browser == ._BRAVE_BROWSER_{
        return getBraveBrowserActiveTabTitle()
    }else if browser == ._SIDEKICK_{
        return getSidekickBrowserActiveTabTitle()
    }
    return nil
}

func getCurrentBrowserFrom(browserName:String)->BROWSER?{
    if browserName == "safari"{
        return ._SAFARI_
    }else if browserName == "google chrome"{
        return ._GOOGLE_CHROME_
    }else if browserName == "sidekick" {
        return ._SIDEKICK_
    }else if browserName == "brave browser"{
        return . _BRAVE_BROWSER_
    }else{
        return nil
    }
}

var arrBrowsersLowerCasedNames = ["safari", "google chrome", "sidekick", "brave browser"]
//*******************************************************//



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


func finishOldFocusModeIfRunning(startNewFocusId:String?,intention:String, start_time:Date?, finish_time:Date?){
    addLog(text: "func finish Old FocusMode If Running")
    allApiObject.getLastActivityInfo(completionHandler: { json in
     
            if json != nil{
                print(json!)

                if let currentFocusMode = json?.value(forKey: "current_focus_mode") as? NSDictionary{
                    if let currentFocusModeId = currentFocusMode.value(forKey: "id") as? String{
                        print(currentFocusModeId)
                        //arrFocusType
                        addLog(text: "old focus mode is running- finish it")
                        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), completionHandler: {newDic in
                            DispatchQueue.main.async {
                                if startNewFocusId != nil{
                                    addLog(text: "start focus mode after finish old")
                                    allApiObject.startFocusMode(id: startNewFocusId!, intention: intention, start_time: start_time!, finish_time: finish_time!, completionHandler: {newDic in
                                        
                                    })
                                }
                                
                            }
                        })
                    }
                }
            }
        
    })
}


var backgroundColor = NSColor(named: "backgroundColor") ?? NSColor.windowBackgroundColor
class customBoxBg:NSBox{
    //    override func draw(_ dirtyRect: NSRect) {
    
    
    override func draw(_ dirtyRect: NSRect) {
        // Make the pattern tile repeat from the top of the view.
        let yOffset = NSMaxY(self.convert(self.frame, to: nil))
        NSGraphicsContext.current?.patternPhase = NSMakePoint(0, yOffset)
        
        //            if let image = NSImage(named: "Bricks") {
        //                let color = NSColor.init(patternImage: image)
        //                color.setFill()
        //                dirtyRect.fill()
        //            }
        
        super.draw(dirtyRect)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        self.fillColor = backgroundColor
        let image = #imageLiteral(resourceName: "background")
        self.contentView?.backgroundcolor = NSColor(patternImage: image)
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
        if let frameView = self.window?.contentView?.superview {
            if backgroundView == nil {
                backgroundView = PopoverBackgroundView(frame: frameView.bounds)
                backgroundView!.autoresizingMask = NSView.AutoresizingMask([.width, .height]);
                frameView.addSubview(backgroundView!, positioned: NSWindow.OrderingMode.below, relativeTo: frameView)
            }
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



var defaultBrowser: String? {
    NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http://")!)
        .flatMap(Bundle.init(url:))
        .flatMap {
            $0.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? $0.object(forInfoDictionaryKey: "CFBundleName")
        }.flatMap {
            $0 as? String
        }
}



var isHabitGraphLoadedFirstTime = false
var isBreakDayGraphLoadedFirstTime = false
var isBreakMonthGraphLoadedFirstTime = false






 
func getAppVersionInString()-> String{
    if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
        return version + "." + build
    }
    return ""
}


var appVersion = ""
var macOSVersion = ""


//extension NSTextField {
//    open override func awakeFromNib() {
//        super.awakeFromNib()
////        backgroundColor = .clear
////        font = UIFont(name: "Helvetica", size: font.pointSize)
//        font = NSFont(name: "Fenwick Light", size: self.font?.pointSize ?? 24)!
//    }
//}
//
//extension NSButton {
//    open override func awakeFromNib() {
//        super.awakeFromNib()
////        backgroundColor = .clear
////        font = UIFont(name: "Helvetica", size: font.pointSize)
//        font = NSFont(name: "Fenwick Light", size: self.font?.pointSize ?? 24)!
//    }
//}


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



var popoverTooltip:NSPopover?// = NSPopover()
func showTooltip(sender:NSView, msg:String, preferredEdge: NSRectEdge) {
    
    if popoverTooltip == nil{
        popoverTooltip = NSPopover()
        popoverTooltip!.behavior = .transient
        popoverTooltip!.animates = false
//        popoverTooltip!.delegate = appdelegate
    }
    if popoverTooltip!.isShown{
        popoverTooltip?.close()
    }
    let vc = getCustomTooltipVcObject()

    
    popoverTooltip!.contentViewController = vc
    popoverTooltip!.contentSize = vc.view.frame.size
        
    popoverTooltip!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
//    appdelegate!.popover.behavior = .applicationDefined
    vc.lblTitle.stringValue = msg
}

//func showNotificationVideoCall(){
//    var notificationVideoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
//    if let common = configjson.value(forKey: "common") as? NSDictionary{
//        notificationVideoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? notificationVideoCallText
//    }
//    showCustomNotificationWindow(msg: notificationVideoCallText)
//}





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


func showQuitWindow(){
    addLog(text: "Showing quit window")
    if isAppEnable{
        getQuittingWindowObject().contentViewController = getAskQuitVcObject()//getQuittingCountDownVcObject()
        quittingWcObj?.showWindow(appdelegate!)
    }else{
        getQuittingWindowObject().contentViewController = getQuittingCountDownVcObject()
        quittingWcObj?.showWindow(appdelegate!)
        getQuittingCountDownVcObject().resetData()
    }
    
    
    quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))//modalPanelWindow
    NSApplication.shared.activate(ignoringOtherApps: true)
}



//*************Do not disturb enable disable work*****************//

func enableDND(){

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
    
    if lastCurrentState == ._FOCUS_SUMMARY_{
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
        }else{// not shut off time
            
        }
    }
    var sequenceId = ""
    if lastCurrentState == ._MORNING_HABIT_{
        sequenceId = arrAllMorningHabits.first?.activity_sequence_id ?? ""
        UserDefaults.standard.set(startDate, forKey: kUserdefaultsLastHabitShowDate)
    }else if lastCurrentState == ._FOCUS_SUMMARY_ || lastCurrentState == ._EVENING_HABIT_{
        sequenceId = arrAllEveningHabits.first?.activity_sequence_id ?? ""
        
        let curreentDate = Date()
        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
            UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
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
