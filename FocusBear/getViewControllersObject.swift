//
//  getViewControllersObject.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/07/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation




let mainStoryboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
let newStoryboard = NSStoryboard(name: NSStoryboard.Name("NewStoryboard"), bundle: nil)
let settingsStoryboard = NSStoryboard(name: NSStoryboard.Name("Settings"), bundle: nil)
let nagsStoryboard = NSStoryboard(name: NSStoryboard.Name("Nags"), bundle: nil)
let onboardingStoryboard = NSStoryboard(name: NSStoryboard.Name("Onboarding"), bundle: nil)


var mainWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("mainWindowController")) as? mainWindowController
let mainViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ViewController")) as? ViewController
let firstViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firstViewController")) as? firstViewController

let timerViewcontrollerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("timerViewcontroller")) as? timerViewcontroller


var quittingWcObj:commonWindowController?
func getQuittingWindowObject()->commonWindowController{
    if quittingWcObj == nil{
        quittingWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return quittingWcObj!
}
var uninstallingConfirmVcObj: uninstallingConfirmVc?
var visualizeInstructionsVcObj:visualizeInstructionsVc?
func getvisualizeInstructionsObject()->visualizeInstructionsVc{
    if visualizeInstructionsVcObj == nil{
        visualizeInstructionsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("visualizeInstructionsVc")) as? visualizeInstructionsVc
    }
    return visualizeInstructionsVcObj!
}


//

var breaksBrainDumpVcObj:breaksBrainDumpVc?
func getBreaksBrainDumpVcObject()->breaksBrainDumpVc{
    if breaksBrainDumpVcObj == nil{
        breaksBrainDumpVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("breaksBrainDumpVc")) as? breaksBrainDumpVc
    }
    return breaksBrainDumpVcObj!
}

//
//var quitCountDownVcObj:quitCountDownVc?
//func getQuittingCountDownVcObject()->quitCountDownVc{
//    if quitCountDownVcObj == nil{
//        quitCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quitCountDownVc")) as? quitCountDownVc
//    }
//    return quitCountDownVcObj!
//}

var askQuitVcObj:askQuitVc?
func getAskQuitVcObject()->askQuitVc{
    if askQuitVcObj == nil{
        askQuitVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askQuitVc")) as? askQuitVc
    }
    return askQuitVcObj!
}


var editHabitRoutineVcObj:editHabitRoutineVc?
func getEditHabitRoutineVcObject()->editHabitRoutineVc{
    if editHabitRoutineVcObj == nil{
        editHabitRoutineVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("editHabitRoutineVc")) as? editHabitRoutineVc
    }
    return editHabitRoutineVcObj!
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

//var smallCountDownWcObj:commonWindowController?
//func getSmallCountDownWindowObject()->commonWindowController{ // 
//    if smallCountDownWcObj == nil{
//        smallCountDownWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//        smallCountDownWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    }
//    return smallCountDownWcObj!
//}


var focusEndWarningVcObj:focusEndWarningVc?
func getFocusEndWarningVcObject()->focusEndWarningVc{
    if focusEndWarningVcObj == nil{
        focusEndWarningVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusEndWarningVc")) as? focusEndWarningVc
    }
    return focusEndWarningVcObj!
}

var focusEndWarningWcObj:commonWindowController?
func getFocusEndWarningWindowObject()->commonWindowController{
    if focusEndWarningWcObj == nil{
        focusEndWarningWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        focusEndWarningWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return focusEndWarningWcObj!
}




var quittingConfirmVcObj:quittingConfirmVc?

func getQuittingConfirmVcObject()->quittingConfirmVc{
    if quittingConfirmVcObj == nil{
        quittingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("quittingConfirmVc")) as? quittingConfirmVc
    }
    return quittingConfirmVcObj!
}


var initialQuitFeedbackVcObj:initialQuitFeedbackVc?

func getInitialQuitFeedbackVcObject()->initialQuitFeedbackVc{
    if initialQuitFeedbackVcObj == nil{
        initialQuitFeedbackVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("initialQuitFeedbackVc")) as? initialQuitFeedbackVc
    }
    return initialQuitFeedbackVcObj!
}

//var brainDumpWcObj:commonWindowController?
//func getBrainDumpWindowObject()->commonWindowController{
//    if brainDumpWcObj == nil{
//        brainDumpWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//        brainDumpWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    }
//    return brainDumpWcObj!
//}

var brainDumpVcObj:brainDumpVc?
func getBrainDumpVcObject()->brainDumpVc{
    if brainDumpVcObj == nil{
        brainDumpVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("brainDumpVc")) as? brainDumpVc
    }
    return brainDumpVcObj!
}

var browsersTabAuditVcObj:browsersTabAuditVc?
func getBrowsersTabAuditVcObject()->browsersTabAuditVc{
    if browsersTabAuditVcObj == nil{
        browsersTabAuditVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("browsersTabAuditVc")) as? browsersTabAuditVc
    }
    return browsersTabAuditVcObj!
}

var postBrowsersTabAuditVcObj:postBrowsersTabAuditVc?
func getPostBrowsersTabAuditVcObject()->postBrowsersTabAuditVc{
    if postBrowsersTabAuditVcObj == nil{
        postBrowsersTabAuditVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("postBrowsersTabAuditVc")) as? postBrowsersTabAuditVc
    }
    return postBrowsersTabAuditVcObj!
}





var askLogInWcObj:loginWc?
func getAskLogInWindowObject()->loginWc{
    if askLogInWcObj == nil{
        askLogInWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("loginWc")) as? loginWc
        askLogInWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return askLogInWcObj!
}

var askLogInVcObj:askLogInVc?
func getAskLogInVcObject()->askLogInVc{
    if askLogInVcObj == nil{
        askLogInVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askLogInVc")) as? askLogInVc
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


var upgradeToProNagWcObj:commonWindowController?
func getupgradeToProNagWindowObject()->commonWindowController{
    if upgradeToProNagWcObj == nil{
        upgradeToProNagWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        upgradeToProNagWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return upgradeToProNagWcObj!
}

var upgradeToProNagVcObj:upgradeToProNagVc?
func getUpgradeToProNagVcObject()->upgradeToProNagVc{
    if upgradeToProNagVcObj == nil{
        upgradeToProNagVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("upgradeToProNagVc")) as? upgradeToProNagVc
    }
    return upgradeToProNagVcObj!
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
        welcomeOnboardingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeOnboardingVc")) as? welcomeOnboardingVc
    }
    return welcomeOnboardingVcObj!
}

var welcomeVcObj:welcomeVc?
func getWelcomeVcObject()->welcomeVc{
    if welcomeVcObj == nil{
        welcomeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeVc")) as? welcomeVc
    }
    return welcomeVcObj!
}


var onboardingPostponeVcObj:onboardingPostponeVc?
func getOnboardingPostponeVcObject()->onboardingPostponeVc{
    if onboardingPostponeVcObj == nil{
        onboardingPostponeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingPostponeVc")) as? onboardingPostponeVc
    }
    return onboardingPostponeVcObj!
}



var onboardingVideoWcObj:commonWindowController?
func getOnboardingVideoWindowObject()->commonWindowController{//not in use
    if onboardingVideoWcObj == nil{
        onboardingVideoWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        onboardingVideoWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return onboardingVideoWcObj!
}


/* // not in use 
var onboardingVideoVcObj:thirdVc?
func getOnboardingVideoVcObject()->thirdVc{
    if onboardingVideoVcObj == nil{
        onboardingVideoVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc
    }
    return onboardingVideoVcObj!
}
 */
/* not in use 
var askOnboardingVideoVcObj:askOnboardingVideoVc?
func getAskOnboardingVideoVcObject()->askOnboardingVideoVc{
    if askOnboardingVideoVcObj == nil{
        askOnboardingVideoVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askOnboardingVideoVc")) as? askOnboardingVideoVc
    }
    return askOnboardingVideoVcObj!
}
*/

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
        customLoginVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customLoginVc")) as? customLoginVc
    }
    return customLoginVcObj!
}


//var loginHelpWcObj:commonWindowController?
//func getLoginHelpWindowObject()->commonWindowController{
//    if loginHelpWcObj == nil{
//        loginHelpWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//        loginHelpWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    }
//    return loginHelpWcObj!
//}

//var loginHelpVcObj:loginHelpVc?
//func getLoginHelpVcObject()->loginHelpVc{
//    if loginHelpVcObj == nil{
//        loginHelpVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("loginHelpVc")) as? loginHelpVc
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


var permissionBlockDistractionWcObj:commonWindowController?
func getPermissionBlockDistractionWindowObject()->commonWindowController{
    if permissionBlockDistractionWcObj == nil{
        permissionBlockDistractionWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        permissionBlockDistractionWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.assistiveTechHighWindow)))
        permissionBlockDistractionWcObj?.window?.title = appName
    }
    return permissionBlockDistractionWcObj!
}


//var onboardingCardsVcObj:onboardingCardsVc?
//func getOnboardingCardsVcObject()->onboardingCardsVc{
//    if onboardingCardsVcObj == nil{
//        onboardingCardsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingCardsVc")) as? onboardingCardsVc
//    }
//    return onboardingCardsVcObj!
//}


var onboardingFocusExplainVcObj:onboardingFocusExplainVc?
func getOnboardingFocusExplainVcObject()->onboardingFocusExplainVc{
    if onboardingFocusExplainVcObj == nil{
        onboardingFocusExplainVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingFocusExplainVc")) as? onboardingFocusExplainVc
    }
    return onboardingFocusExplainVcObj!
}

var onboardingHabitExplainVcObj:onboardingHabitExplainVc?
func getOnboardingHabitExplainVcObject()->onboardingHabitExplainVc{
    if onboardingHabitExplainVcObj == nil{
        onboardingHabitExplainVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingHabitExplainVc")) as? onboardingHabitExplainVc
    }
    return onboardingHabitExplainVcObj!
}


var firefoxPermissionsWcObj:commonWindowController?
func getFirefoxPermissionsWindowObject()->commonWindowController{
    if firefoxPermissionsWcObj == nil{
        firefoxPermissionsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        firefoxPermissionsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        firefoxPermissionsWcObj?.window?.title = appName
    }
    return firefoxPermissionsWcObj!
}

var firefoxPermissionsVcObj:firefoxPermissionsVc?
func getFirefoxPermissionsVcObject()->firefoxPermissionsVc{
    if firefoxPermissionsVcObj == nil{
        firefoxPermissionsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firefoxPermissionsVc")) as? firefoxPermissionsVc
    }
    return firefoxPermissionsVcObj!
}



var firefoxPermissionVideoWcObj:commonWindowController?
func getFirefoxPermissionVideoWindowObject()->commonWindowController{
    if firefoxPermissionVideoWcObj == nil{
        firefoxPermissionVideoWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        firefoxPermissionVideoWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        firefoxPermissionVideoWcObj?.window?.title = appName
    }
    return firefoxPermissionVideoWcObj!
}


var firefoxPermissionVideoVcObj:firefoxPermissionVideoVc?
func getFirefoxPermissionVideoVcObject()->firefoxPermissionVideoVc{
    if firefoxPermissionVideoVcObj == nil{
        firefoxPermissionVideoVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("firefoxPermissionVideoVc")) as? firefoxPermissionVideoVc
    }
    return firefoxPermissionVideoVcObj!
}

//blockedUrlsVcObj
var blockedUrlsVcObj:blockedUrlsVc?
func getBlockedUrlsVcObject()->blockedUrlsVc{
    if blockedUrlsVcObj == nil{
        blockedUrlsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blockedUrlsVc")) as? blockedUrlsVc
    }
    return blockedUrlsVcObj!
}
//


var blockedAppsVcObj:blockedAppsVc?
func getBlockedAppsVcObject()->blockedAppsVc{
    if blockedAppsVcObj == nil{
        blockedAppsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blockedAppsVc")) as? blockedAppsVc
    }
    return blockedAppsVcObj!
}
//

var blockingScheduleVcObj:blockingScheduleVc?
func getBlockingScheduleVcObject()->blockingScheduleVc{
    if blockingScheduleVcObj == nil{
        blockingScheduleVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blockingScheduleVc")) as? blockingScheduleVc
    }
    return blockingScheduleVcObj!
}


//passwordVcObj

var passwordVcObj:passwordVc?
func getPasswordVcObject()->passwordVc{
    if passwordVcObj == nil{
        passwordVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("passwordVc")) as? passwordVc
    }
    return passwordVcObj!
}

//accountVcObj

var accountVcObj:accountVc?
func getAccountVcObject()->accountVc{
    if accountVcObj == nil{
        accountVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("accountVc")) as? accountVc
    }
    return accountVcObj!
}


//uninstallVcObj
var uninstallVcObj:uninstallVc?
func getUninstallVcObject()->uninstallVc{
    if uninstallVcObj == nil{
        uninstallVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallVc")) as? uninstallVc
    }
    return uninstallVcObj!
}

//uninstallVcObj
var permissionsVcObj:permissionsVc?
func getPermissionsVcObject()->permissionsVc{
    if permissionsVcObj == nil{
        permissionsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("permissionsVc")) as? permissionsVc
    }
    return permissionsVcObj!
}

//advancedVcObj
var advancedVcObj:advancedVc?
func getAdvancedVcObject()->advancedVc{
    if advancedVcObj == nil{
        advancedVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("advancedVc")) as? advancedVc
    }
    return advancedVcObj!
}

//addOnsVcObj
var addOnsVcObj:addOnsVc?
func getAddOnsVcObject()->addOnsVc{
    if addOnsVcObj == nil{
        addOnsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addOnsVc")) as? addOnsVc
    }
    return addOnsVcObj!
}

//toDoListVcObj
var toDoListSettingsVcObj:toDoListSettingsVc?
func getToDoListSettingsVcObject()->toDoListSettingsVc{
    if toDoListSettingsVcObj == nil{
        toDoListSettingsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("toDoListSettingsVc")) as? toDoListSettingsVc
    }
    return toDoListSettingsVcObj!
}


//meetingDetactionVcObj
var meetingDetactionVcObj:meetingDetactionVc?
func getMeetingDetactionVcObject()->meetingDetactionVc{
    if meetingDetactionVcObj == nil{
        meetingDetactionVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("meetingDetactionVc")) as? meetingDetactionVc
    }
    return meetingDetactionVcObj!
}

var settingsContainerVcObj:settingsContainerVc?



var privacyVcObj:privacyVc?
func getPrivacyVcObject()->privacyVc{
    if privacyVcObj == nil{
        privacyVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("privacyVc")) as? privacyVc
    }
    return privacyVcObj!
}

//researchVc
var researchVcObj:researchVc?
func getResearchVcObject()->researchVc{
    if researchVcObj == nil{
        researchVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("researchVc")) as? researchVc
    }
    return researchVcObj!
}


//microBreaksSettingsVcObj
var microBreaksSettingsVcObj:microBreaksSettingsVc?
func getMicroBreaksSettingsVcObject()->microBreaksSettingsVc{
    if microBreaksSettingsVcObj == nil{
        microBreaksSettingsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("microBreaksSettingsVc")) as? microBreaksSettingsVc
    }
    return microBreaksSettingsVcObj!
}



var aISettingVcObj:AISettingVc?
func getAISettingVcObject()->AISettingVc{
    if aISettingVcObj == nil{
        aISettingVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("AISettingVc")) as? AISettingVc
    }
    return aISettingVcObj!
}

//aiSettingNewVc
var aiSettingNewVcObj:aiSettingNewVc?
func getAiSettingNewVcObject()->aiSettingNewVc{
    if aiSettingNewVcObj == nil{
        aiSettingNewVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("aiSettingNewVc")) as? aiSettingNewVc
    }
    return aiSettingNewVcObj!
}

//frictionVc

var frictionVcObj:frictionVc?
func getFrictionVcObject()->frictionVc{
    if frictionVcObj == nil{
        frictionVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("frictionVc")) as? frictionVc
    }
    return frictionVcObj!
}
//focusBearModeVc

var focusBearModeVcObj:focusBearModeVc?
func getfocusBearModeVcObject()->focusBearModeVc{
    if focusBearModeVcObj == nil{
        focusBearModeVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusBearModeVc")) as? focusBearModeVc
    }
    return focusBearModeVcObj!
}

//browserTabLimiterVc
var browserTabLimiterVcObj:browserTabLimiterVc?
func getBrowserTabLimiterVcObject()->browserTabLimiterVc{
    if browserTabLimiterVcObj == nil{
        browserTabLimiterVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("browserTabLimiterVc")) as? browserTabLimiterVc
    }
    return browserTabLimiterVcObj!
}

//settingsContainerVc
var tabStrictnessContainerVcObj:tabStrictnessContainerVc?
func getTabStrictnessContainerVcObject()->tabStrictnessContainerVc{
    if tabStrictnessContainerVcObj == nil{
        tabStrictnessContainerVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("tabStrictnessContainerVc")) as? tabStrictnessContainerVc
    }
    return tabStrictnessContainerVcObj!
}


var strictnessVcObj:strictnessVc?
func getStrictnessVcObject()->strictnessVc{
    if strictnessVcObj == nil{
        strictnessVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("strictnessVc")) as? strictnessVc
    }
    return strictnessVcObj!
}


var uIVcObj:uIVc?
func getUIVcObject()->uIVc{
    if uIVcObj == nil{
        uIVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uIVc")) as? uIVc
    }
    return uIVcObj!
}

var accessibilityVcObj:accessibilityVc?
func getAccessibilityVcObject()->accessibilityVc{
    if accessibilityVcObj == nil{
        accessibilityVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("accessibilityVc")) as? accessibilityVc
    }
    return accessibilityVcObj!
}



var pomodoroSettingsVcObj:pomodoroSettingsVc?
func getPomodoroSettingsVcObject()->pomodoroSettingsVc{
    if pomodoroSettingsVcObj == nil{
        pomodoroSettingsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroSettingsVc")) as? pomodoroSettingsVc
    }
    return pomodoroSettingsVcObj!
}



var settingsSideBarVcObj:settingsSideBarVc?
var generalVcObj:generalVc?


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

// completion Requirements window object
var completionRequirementsWcObj:commonWindowController?
func getCompletionRequirementsWindowObject()->commonWindowController{
    if completionRequirementsWcObj == nil{
        completionRequirementsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        completionRequirementsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return completionRequirementsWcObj!
}

// completion Requirements
var completionRequirementsVcObj:completionRequirementsVc?
func getCompletionRequirementsVcObject()->completionRequirementsVc{
    if completionRequirementsVcObj == nil{
        completionRequirementsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("completionRequirementsVc")) as? completionRequirementsVc
    }
    return completionRequirementsVcObj!
}


// completion Requirements window object
var popUpCheckListWcObj:commonWindowController?
func getPopUpCheckListWindowObject()->commonWindowController{
    if popUpCheckListWcObj == nil{
        popUpCheckListWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        popUpCheckListWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return popUpCheckListWcObj!
}

// popUp CheckList object
var popUpCheckListVcObj:popUpCheckListVc?
func getPopUpCheckListVcObject()->popUpCheckListVc{
    if popUpCheckListVcObj == nil{
        popUpCheckListVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpCheckListVc")) as? popUpCheckListVc
    }
    return popUpCheckListVcObj!
}


// custom notification vc object
var customTooltipVcObj:customTooltipVc?
func getCustomTooltipVcObject()->customTooltipVc{
    if customTooltipVcObj == nil{
        customTooltipVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customTooltipVc")) as? customTooltipVc
    }
    return customTooltipVcObj!
}




// information Popover Vc Obj
var informationPopoverVcObj:informationPopoverVc?
func getInformationPopoverVcObject()->informationPopoverVc{
    if informationPopoverVcObj == nil{
        informationPopoverVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("informationPopoverVc")) as? informationPopoverVc
    }
    return informationPopoverVcObj!
}

// custom notification vc object
var focusStartHelpImgVcObj:focusStartHelpImgVc?
func getFocusStartHelpImgVcObject()->focusStartHelpImgVc{
    if focusStartHelpImgVcObj == nil{
        focusStartHelpImgVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusStartHelpImgVc")) as? focusStartHelpImgVc
    }
    return focusStartHelpImgVcObj!
}


// toolBox window object
//var toolBoxWcObj:commonWindowController?
//func getToolBoxWindowObject()->commonWindowController{//// not in use now  removed on 1/9/25  on version 2.27.408
//    if toolBoxWcObj == nil{
//        toolBoxWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//        toolBoxWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    }
//    return toolBoxWcObj!
//}

// toolBox vc object
//var toolBoxVcObj:toolBoxVc?
//func getToolBoxVcObject()->toolBoxVc{// not in use now  removed on 1/9/25  on version 2.27.408
//    if toolBoxVcObj == nil{
//        toolBoxVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("toolBoxVc")) as? toolBoxVc
//    }
//    return toolBoxVcObj!
//}

// toDoList window object
//var toDoListWcObj:commonWindowController?
//func getToDoListWcObject()->commonWindowController{
//    if toDoListWcObj == nil{
//        toDoListWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//        toDoListWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    }
//    return toDoListWcObj!
//}

// todoList Tool object
var todoListToolVcObj:todoListToolVc?
func getTodoListToolVcObject()->todoListToolVc{
    if todoListToolVcObj == nil{
        todoListToolVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("todoListToolVc")) as? todoListToolVc
    }
    return todoListToolVcObj!
}

// createTask window object
var createTaskWcObj:commonWindowController?
func getCreateTaskWcObject()->commonWindowController{
    if createTaskWcObj == nil{
        createTaskWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        createTaskWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        createTaskWcObj?.window?.styleMask.remove(.closable)
    }
    return createTaskWcObj!
}

// createTaskVc  object
var createTaskVcObj:createTaskVc?
func getCreateTaskVcObject()->createTaskVc{
    if createTaskVcObj == nil{
        createTaskVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("createTaskVc")) as? createTaskVc
    }
    return createTaskVcObj!
}



// relaxMode  window object
var relaxModeWcObj:commonWindowController?
func getRelaxModeWindowObject()->commonWindowController{
    if relaxModeWcObj == nil{
        relaxModeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        relaxModeWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return relaxModeWcObj!
}

// getSavedSitesForLater  window object
var savedSitesForLaterWcObj:commonWindowController?
func getSavedSitesForLaterWindowObject()->commonWindowController{
    if savedSitesForLaterWcObj == nil{
        savedSitesForLaterWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        savedSitesForLaterWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return savedSitesForLaterWcObj!
}


// relaxMode vc object
var relaxModeVcObj:relaxModeVc?
func getRelaxModeVcObject()->relaxModeVc{
    if relaxModeVcObj == nil{
        relaxModeVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("relaxModeVc")) as? relaxModeVc
    }
    return relaxModeVcObj!
}
// savedSitesForLater vc object
var savedSitesForLaterVcObj:savedSitesForLaterVc?
func getSavedSitesForLaterVcObject()->savedSitesForLaterVc{
    if savedSitesForLaterVcObj == nil{
        savedSitesForLaterVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("savedSitesForLaterVc")) as? savedSitesForLaterVc
    }
    return savedSitesForLaterVcObj!
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
        askAppWorkVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askAppWorkVc")) as? askAppWorkVc
    }
    return askAppWorkVcObj!
}

var achieveWithFocusBearVcObj:achieveWithFocusBearVc?
func getAchieveWithFocusBearVcObject()->achieveWithFocusBearVc{
    if achieveWithFocusBearVcObj == nil{
        achieveWithFocusBearVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("achieveWithFocusBearVc")) as? achieveWithFocusBearVc
    }
    return achieveWithFocusBearVcObj!
}


var askOccupationVcObj:askOccupationVc?
func getAskOccupationVcObject()->askOccupationVc{
    if askOccupationVcObj == nil{
        askOccupationVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askOccupationVc")) as? askOccupationVc
    }
    return askOccupationVcObj!
}




// ask work time vc object
var askWorkTimeVcObj:askWorkTimeVc?
func getAskWorkTimeVcObject()->askWorkTimeVc{
    if askWorkTimeVcObj == nil{
        askWorkTimeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askWorkTimeVc")) as? askWorkTimeVc
    }
    return askWorkTimeVcObj!
}

// confirm Evening Routine Time VcObj
var confirmEveningRoutineTimeVcObj:confirmEveningRoutineTimeVc?
func getConfirmEveningRoutineTimeVcObject()->confirmEveningRoutineTimeVc{
    if confirmEveningRoutineTimeVcObj == nil{
        confirmEveningRoutineTimeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("confirmEveningRoutineTimeVc")) as? confirmEveningRoutineTimeVc
    }
    return confirmEveningRoutineTimeVcObj!
}

// confirm Morning Routine Time VcObj
var confirmMorningRoutineTimeVcObj:confirmMorningRoutineTimeVc?
func getConfirmMorningRoutineTimeVcObject()->confirmMorningRoutineTimeVc{
    if confirmMorningRoutineTimeVcObj == nil{
        confirmMorningRoutineTimeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("confirmMorningRoutineTimeVc")) as? confirmMorningRoutineTimeVc
    }
    return confirmMorningRoutineTimeVcObj!
}


//// select Habit Packs
//var selectHabitPacksVcObj:selectHabitPacksVc?
//func getSelectHabitPacksVcObject()->selectHabitPacksVc{
//    if selectHabitPacksVcObj == nil{
//        selectHabitPacksVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectHabitPacksVc")) as? selectHabitPacksVc
//    }
//    return selectHabitPacksVcObj!
//}
// additionalGoals vc object
var additionalGoalsVcObj:additionalGoalsVc?
func getAdditionalGoalsVcObject()->additionalGoalsVc{
    if additionalGoalsVcObj == nil{
        additionalGoalsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("additionalGoalsVc")) as? additionalGoalsVc
    }
    return additionalGoalsVcObj!
}

// selectHabitsLaterInfo vc object
var selectHabitsLaterInfoVcObj:selectHabitsLaterInfoVc?
func getSelectHabitsLaterInfoVcObject()->selectHabitsLaterInfoVc{
    if selectHabitsLaterInfoVcObj == nil{
        selectHabitsLaterInfoVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectHabitsLaterInfoVc")) as? selectHabitsLaterInfoVc
    }
    return selectHabitsLaterInfoVcObj!
}


// ask Break time vc object
var askBreakTimeVcbj:askBreakTimeVc?
func getaskBreakTimeVcObject()->askBreakTimeVc{
    if askBreakTimeVcbj == nil{
        askBreakTimeVcbj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askBreakTimeVc")) as? askBreakTimeVc
    }
    return askBreakTimeVcbj!
}

// take Breaks Info Vc object
var takeBreaksInfoVcbj:takeBreaksInfoVc?
func geTakeBreaksInfoVcObject()->takeBreaksInfoVc{
    if takeBreaksInfoVcbj == nil{
        takeBreaksInfoVcbj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("takeBreaksInfoVc")) as? takeBreaksInfoVc
    }
    return takeBreaksInfoVcbj!
}


// habit SkipEasiness object
var habitSkipEasinessVcObj:habitSkipEasinessVc?
func getHabitSkipEasinessVcObject()->habitSkipEasinessVc{
    if habitSkipEasinessVcObj == nil{
        habitSkipEasinessVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("habitSkipEasinessVc")) as? habitSkipEasinessVc
    }
    return habitSkipEasinessVcObj!
}

// onboarding Blocked Urls object
var onboardingBlockedUrlsVcObj:onboardingBlockedUrlsVc?
func getOnboardingBlockedUrlsVcObject()->onboardingBlockedUrlsVc{
    if onboardingBlockedUrlsVcObj == nil{
        onboardingBlockedUrlsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingBlockedUrlsVc")) as? onboardingBlockedUrlsVc
    }
    return onboardingBlockedUrlsVcObj!
}


// onboarding Blocked Apps object
var onboardingBlockedAppsVcObj:onboardingBlockedAppsVc?
func getOnboardingBlockedAppsVcObject()->onboardingBlockedAppsVc{
    if onboardingBlockedAppsVcObj == nil{
        onboardingBlockedAppsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingBlockedAppsVc")) as? onboardingBlockedAppsVc
    }
    return onboardingBlockedAppsVcObj!
}


// Distraction Types object
var onboardingDistractionTypesVcObj:onboardingDistractionTypesVc?
func getOnboardingDistractionTypesVcObject()->onboardingDistractionTypesVc{
    if onboardingDistractionTypesVcObj == nil{
        onboardingDistractionTypesVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingDistractionTypesVc")) as? onboardingDistractionTypesVc
    }
    return onboardingDistractionTypesVcObj!
}

var onboardingPrivacyTipVcObj:onboardingPrivacyTipVc?
func getOnboardingPrivacyTipVcObject()->onboardingPrivacyTipVc{
    if onboardingPrivacyTipVcObj == nil{
        onboardingPrivacyTipVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingPrivacyTipVc")) as? onboardingPrivacyTipVc
    }
    return onboardingPrivacyTipVcObj!
}

//var onboardingBlockingScheduleVcObj:onboardingBlockingScheduleVc?
//func getOnboardingBlockingScheduleVcObject()->onboardingBlockingScheduleVc{
//    if onboardingBlockingScheduleVcObj == nil{
//        onboardingBlockingScheduleVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingBlockingScheduleVc")) as? onboardingBlockingScheduleVc
//    }
//    return onboardingBlockingScheduleVcObj!
//}



var explainingPermissionsVcObj:explainingPermissionsVc?
func getExplainingPermissionsVcObject()->explainingPermissionsVc{
    if explainingPermissionsVcObj == nil{
        explainingPermissionsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("explainingPermissionsVc")) as? explainingPermissionsVc
    }
    return explainingPermissionsVcObj!
}


// systemEventsPermissionVc
var systemEventsPermissionVcObj:systemEventsPermissionVc?
func getSystemEventsPermissionVcObject()->systemEventsPermissionVc{
    if systemEventsPermissionVcObj == nil{
        systemEventsPermissionVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("systemEventsPermissionVc")) as? systemEventsPermissionVc
    }
    return systemEventsPermissionVcObj!
}

// onboardingControllingBrowserVc
var onboardingControllingBrowserVcObj:onboardingControllingBrowserVc?
func getOnboardingControllingBrowserVcObject()->onboardingControllingBrowserVc{
    if onboardingControllingBrowserVcObj == nil{
        onboardingControllingBrowserVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingControllingBrowserVc")) as? onboardingControllingBrowserVc
    }
    return onboardingControllingBrowserVcObj!
}


// accessibilityPermissionVc
var accessibilityPermissionVcObj:accessibilityPermissionVc?
func getAccessibilityPermissionVcObject()->accessibilityPermissionVc{
    if accessibilityPermissionVcObj == nil{
        accessibilityPermissionVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("accessibilityPermissionVc")) as? accessibilityPermissionVc
    }
    return accessibilityPermissionVcObj!
}


// tryBlockUrlVc
var tryBlockUrlVcObj:tryBlockUrlVc?
func getTryBlockUrlVcObject()->tryBlockUrlVc{
    if tryBlockUrlVcObj == nil{
        tryBlockUrlVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("tryBlockUrlVc")) as? tryBlockUrlVc
    }
    return tryBlockUrlVcObj!
}


// askDetailsNotBlockingVc
var askDetailsNotBlockingVcObj:askDetailsNotBlockingVc?
func getAskDetailsNotBlockingVcObject()->askDetailsNotBlockingVc{
    if askDetailsNotBlockingVcObj == nil{
        askDetailsNotBlockingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askDetailsNotBlockingVc")) as? askDetailsNotBlockingVc
    }
    return askDetailsNotBlockingVcObj!
}


//var askBuildHabitsVcObj:askBuildHabitsVc?
//func getAskBuildHabitsVcObject()->askBuildHabitsVc{
//    if askBuildHabitsVcObj == nil{
//        askBuildHabitsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askBuildHabitsVc")) as? askBuildHabitsVc
//    }
//    return askBuildHabitsVcObj!
//}


var askAccountVcObj:askAccountVc?
func getAskAccountVcObject()->askAccountVc{
    if askAccountVcObj == nil{
        askAccountVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askAccountVc")) as? askAccountVc
    }
    return askAccountVcObj!
}



// break Warning window object
var breakWarningWcObj:commonWindowController?
func getBreakWarningWindowObject()->commonWindowController{
    if breakWarningWcObj == nil{
        breakWarningWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        breakWarningWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
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




var askIntentionAllowedFocusModeActivityObj:askIntentionAllowedFocusModeActivity?
func getAskIntentionAllowedFocusModeActivityObject()->askIntentionAllowedFocusModeActivity{
    if askIntentionAllowedFocusModeActivityObj == nil{
        askIntentionAllowedFocusModeActivityObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askIntentionAllowedFocusModeActivity")) as? askIntentionAllowedFocusModeActivity
    }
    return askIntentionAllowedFocusModeActivityObj!
}


// deactivate Breaks window object
var deactivateBreaksWcObj:commonWindowController?
func getDeactivateBreaksWindowObject()->commonWindowController{
    if deactivateBreaksWcObj == nil{
        deactivateBreaksWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        deactivateBreaksWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    return deactivateBreaksWcObj!
}

// deactivate Breaks object
var deactivateBreaksVcObj:deactivateBreaksVc?
func getDeactivateBreaksVcObject()->deactivateBreaksVc{
    if deactivateBreaksVcObj == nil{
        deactivateBreaksVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("deactivateBreaksVc")) as? deactivateBreaksVc
    }
    return deactivateBreaksVcObj!
}





// naturalBreaksDetectionWcObj  window object
var naturalBreaksDetectionWcObj:commonWindowController?
func getNaturalBreaksDetectionWindowObject()->commonWindowController{
    if naturalBreaksDetectionWcObj == nil{
        naturalBreaksDetectionWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        naturalBreaksDetectionWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return naturalBreaksDetectionWcObj!
}


var naturalBreaksDetectionVcObj:naturalBreaksDetectionVc?
func getNaturalBreaksDetectionVcObject()->naturalBreaksDetectionVc{
    if naturalBreaksDetectionVcObj == nil{
        naturalBreaksDetectionVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("naturalBreaksDetectionVc")) as? naturalBreaksDetectionVc
    }
    return naturalBreaksDetectionVcObj!
}


//



// getPopupAppointmentTimeWindowObject  window object
var popupAppointmentTimeWcObj:commonWindowController?
func getPopupAppointmentTimeWindowObject()->commonWindowController{
    if popupAppointmentTimeWcObj == nil{
        popupAppointmentTimeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        popupAppointmentTimeWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return popupAppointmentTimeWcObj!
}


var popupAppointmentTimeVcObj:popupAppointmentTimeVc?
func getPopupAppointmentTimeVcObject()->popupAppointmentTimeVc{
    if popupAppointmentTimeVcObj == nil{
        popupAppointmentTimeVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popupAppointmentTimeVc")) as? popupAppointmentTimeVc
    }
    return popupAppointmentTimeVcObj!
}



// alertMaxTabLimitWcObj  window object
var alertMaxTabLimitWcObj:commonWindowController?
func getAlertMaxTabLimitWindowObject()->commonWindowController{
    if alertMaxTabLimitWcObj == nil{
        alertMaxTabLimitWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        alertMaxTabLimitWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return alertMaxTabLimitWcObj!
}


var alertMaxTabLimitVcObj:alertMaxTabLimitVc?
func getAlertMaxTabLimitVcObject()->alertMaxTabLimitVc{
    if alertMaxTabLimitVcObj == nil{
        alertMaxTabLimitVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("alertMaxTabLimitVc")) as? alertMaxTabLimitVc
    }
    return alertMaxTabLimitVcObj!
}




//

// Get Blur Window Object
var blurWcObj:commonWindowController?
func getBlurWindowObject()->commonWindowController{
    if blurWcObj == nil{
        blurWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        blurWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        blurWcObj?.window?.ignoresMouseEvents = true
    }
    return blurWcObj!
}



// Blur vc object
var blockBlurVcObj:blockBlurVc?
func getBlockBlurVcObject()->blockBlurVc{
    if blockBlurVcObj == nil{
        blockBlurVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blockBlurVc")) as? blockBlurVc
    }
    return blockBlurVcObj!
}

var transparentWcObj:commonWindowController?
func getTransparentWindowObject()->commonWindowController{
    if transparentWcObj == nil{
        transparentWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        transparentWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))

        transparentWcObj?.window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
        transparentWcObj?.window?.canHide = false
        transparentWcObj?.window?.isExcludedFromWindowsMenu = true
        transparentWcObj?.window?.hidesOnDeactivate = false
        transparentWcObj?.window?.isRestorable = false
        transparentWcObj?.window?.animationBehavior = .none
        transparentWcObj?.window?.styleMask = .borderless
        transparentWcObj?.window?.backingType = .buffered
        transparentWcObj?.window?.minSize = NSSize(width: 900, height: 500)
        transparentWcObj?.window?.title = ""
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        transparentWcObj?.window?.setFrame(NSMakeRect(0, 0, NSWidth(screenFrame), NSHeight(screenFrame)), display: true)
        transparentWcObj?.window?.ignoresMouseEvents = true
    }
    transparentWcObj?.window?.alphaValue = 0
    return transparentWcObj!
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
    if popUpOfflineWcObj == nil{
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
        popUpBlockConfirmWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
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



// popUp setIntentionBlockedUrls window object
var setIntentionBlockedUrlsWcObj:commonWindowController?
func getSetIntentionBlockedUrlsWindowObject()->commonWindowController{
    if setIntentionBlockedUrlsWcObj == nil{
        setIntentionBlockedUrlsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        setIntentionBlockedUrlsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    }
    return setIntentionBlockedUrlsWcObj!
}

// popUp Set Intention Blocked Url vc object
var setIntentionBlockedUrlsVcObj:setIntentionBlockedUrlsVc?
func getSetIntentionBlockedUrlsVcObject()->setIntentionBlockedUrlsVc{
    if setIntentionBlockedUrlsVcObj == nil{
        setIntentionBlockedUrlsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("setIntentionBlockedUrlsVc")) as? setIntentionBlockedUrlsVc
    }
    return setIntentionBlockedUrlsVcObj!
}


// popUp IntentionBlockedUrls window object
var intentionBlockedUrlsWcObj:commonWindowController?
func getIntentionBlockedUrlsWindowObject()->commonWindowController{
    if intentionBlockedUrlsWcObj == nil{
        intentionBlockedUrlsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        intentionBlockedUrlsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    }
    return intentionBlockedUrlsWcObj!
}

// popUp Intention Blocked Url vc object
var intentionBlockedUrlsVcObj:intentionBlockedUrlsVc?
func getIntentionBlockedUrlsVcObject()->intentionBlockedUrlsVc{
    if intentionBlockedUrlsVcObj == nil{
        intentionBlockedUrlsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("intentionBlockedUrlsVc")) as? intentionBlockedUrlsVc
    }
    return intentionBlockedUrlsVcObj!
}


// popUp IntentionBlockedAppswindow object
var intentionBlockedAppsWcObj:commonWindowController?
func getIntentionBlockedAppsWindowObject()->commonWindowController{
    if intentionBlockedAppsWcObj == nil{
        intentionBlockedAppsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        intentionBlockedAppsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow)))
    }
    return intentionBlockedAppsWcObj!
}

// popUp Intention Blocked Url vc object
var intentionBlockedAppsVcObj:intentionBlockedUrlsVc?
func getIntentionBlockedAppsVcObject()->intentionBlockedUrlsVc{
    if intentionBlockedAppsVcObj == nil{
        intentionBlockedAppsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("intentionBlockedUrlsVc")) as? intentionBlockedUrlsVc
    }
    return intentionBlockedAppsVcObj!
}


// menuTour window object
var menuTourWcObj:commonWindowController?
func getMenuTourWcObject()->commonWindowController{
    if menuTourWcObj == nil{
        menuTourWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        menuTourWcObj?.window!.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
        menuTourWcObj?.window!.canHide = false
        menuTourWcObj?.window!.isExcludedFromWindowsMenu = true
        menuTourWcObj?.window!.hidesOnDeactivate = false
        menuTourWcObj?.window!.isRestorable = false
        menuTourWcObj?.window!.animationBehavior = .none
        menuTourWcObj?.window!.styleMask = .borderless
        menuTourWcObj?.window!.backingType = .buffered
        menuTourWcObj?.window?.title = ""
        menuTourWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        menuTourWcObj?.window?.backgroundColor = NSColor.clear
    }
    return menuTourWcObj!
}

// menuTour  vc object
var menuTourVcObj:menuTourVc?
func getMenuTourVcObject()->menuTourVc{
    if menuTourVcObj == nil{
        menuTourVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuTourVc")) as? menuTourVc
    }
    return menuTourVcObj!
}




let thirdVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("thirdVc")) as? thirdVc

//let selectJsonWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonWindowController")) as? selectJsonWindowController
//var selectJsonVcObj:selectJsonVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
let shutOffTimeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shutOffTimeVc")) as? shutOffTimeVc

let abortingCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCountDownVc")) as? abortingCountDownVc
let abortingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingConfirmVc")) as? abortingConfirmVc
let abortDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortDoneVc")) as? abortDoneVc




let abortingCantHandleVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCantHandleVc")) as? abortingCantHandleVc
let logQuantityVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("logQuantityVc")) as? logQuantityVc

//let preferencesWindowControllerObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preferencesWindowController")) as? preferencesWindowController

var menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController


//var focusPreferencesVcObj:focusPreferencesVc?


let addWebUrlVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addWebUrlVc")) as? addWebUrlVc
let addFocusTypeVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addFocusTypeVc")) as? addFocusTypeVc

var pomodoroWindowControllerObj:pomodoroWindowController?

func getPomodoroWindowControllerObj()->pomodoroWindowController{
    if pomodoroWindowControllerObj == nil{
        pomodoroWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroWindowController")) as? pomodoroWindowController
    }
    return pomodoroWindowControllerObj!
}

var simplePomodoroVcObj: simplePomodoroVc?
func getSimplePomodoroVcObj()->simplePomodoroVc{
    if simplePomodoroVcObj == nil{
        simplePomodoroVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("simplePomodoroVc")) as? simplePomodoroVc
    }
    return simplePomodoroVcObj!
}


let pomodoroVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("pomodoroVc")) as? pomodoroVc
let focusCompletedVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusCompletedVc")) as? focusCompletedVc

let focusCompletedFullScreenVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusCompletedVc")) as? focusCompletedVc

//let startingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController


//var endingFocusWindowControllerObj: commonWindowController?

//func getEndFocusModeWindowControllerObj()->commonWindowController{// do not delete. this this is resizable but not full screen. code is usable
//    if endingFocusWindowControllerObj == nil{
//        endingFocusWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//    }
//    if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsCompletedFocusWindowOnTop) as? Bool{
//        if state{
//            endingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//        }else{
//            endingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
//        }
//    }else{
//        UserDefaults.standard.set(false, forKey: kUserdefaultsIsCompletedFocusWindowOnTop)
//        endingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
//    }
//    endingFocusWindowControllerObj?.window?.styleMask.insert(.resizable)
////    endingFocusWindowControllerObj?.window?.styleMask.remove(.fullScreen)
//    endingFocusWindowControllerObj?.window?.collectionBehavior = [.fullScreenNone]
//    return endingFocusWindowControllerObj!
//}
var rememberNextHabitVcObj:rememberNextHabitVc?

func getRememberNextHabitVcObj()->rememberNextHabitVc{
    if rememberNextHabitVcObj == nil{
        rememberNextHabitVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("rememberNextHabitVc")) as? rememberNextHabitVc
    }
    return rememberNextHabitVcObj!
}

var loaderVcPbj:loaderVc?
func getLoaderVcObj()->loaderVc{
    if loaderVcPbj == nil{
        loaderVcPbj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("loaderVc")) as? loaderVc
    }
    return loaderVcPbj!
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


var aiPermissionVcObj:aiPermissionVc?

func getAiPermissionVcObj()->aiPermissionVc{
    if aiPermissionVcObj == nil{
        aiPermissionVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("aiPermissionVc")) as? aiPermissionVc
    }
    return aiPermissionVcObj!
}

var preloadFocusModeAppsVcObj:preloadFocusModeAppsVc?

func getPreloadFocusModeAppsVcObj()->preloadFocusModeAppsVc{
    if preloadFocusModeAppsVcObj == nil{
        preloadFocusModeAppsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("preloadFocusModeAppsVc")) as? preloadFocusModeAppsVc
    }
    return preloadFocusModeAppsVcObj!
}


var allTracksWindowControllerObj: commonWindowController?

func getAllTracksWindowControllerObj()->commonWindowController{
    if allTracksWindowControllerObj == nil{
        allTracksWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return allTracksWindowControllerObj!
}


var allTracksVcObj:allTracksVc?

func getAllTracksVcObj()->allTracksVc{
    if allTracksVcObj == nil{
        allTracksVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("allTracksVc")) as? allTracksVc
    }
    return allTracksVcObj!
}


var takeActivityNotesVcObj:takeActivityNotesVc?

func getTakeActivityNotesVcObj()->takeActivityNotesVc{
    if takeActivityNotesVcObj == nil{
        takeActivityNotesVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("takeActivityNotesVc")) as? takeActivityNotesVc
    }
    return takeActivityNotesVcObj!
}

var onboardingProgressVcObj:onboardingProgressVc?

func getOnboardingProgressVcObj()->onboardingProgressVc{
    if onboardingProgressVcObj == nil{
        onboardingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingProgressVc")) as? onboardingProgressVc
    }
    return onboardingProgressVcObj!
}

var bellVcObj:bellVc?

func getBellVcObj()->bellVc{
    if bellVcObj == nil{
        bellVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("bellVc")) as? bellVc
    }
    return bellVcObj!
}



var bellSuggestionsVcObj:bellSuggestionsVc?

func getBellSuggestionsVcObj()->bellSuggestionsVc{
    if bellSuggestionsVcObj == nil{
        bellSuggestionsVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("bellSuggestionsVc")) as? bellSuggestionsVc
    }
    return bellSuggestionsVcObj!
}

var focusCompletedForActivityVcObj:focusCompletedForActivityVc?

func getFocusCompletedForActivityVcObj()->focusCompletedForActivityVc{
    if focusCompletedForActivityVcObj == nil{
        focusCompletedForActivityVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusCompletedForActivityVc")) as? focusCompletedForActivityVc
    }
    return focusCompletedForActivityVcObj!
}



var logsUploadingVcObj:logsUploadingVc?

func getLogsUploadingVcObjObj()->logsUploadingVc{
    if logsUploadingVcObj == nil{
        logsUploadingVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("logsUploadingVc")) as? logsUploadingVc
    }
    return logsUploadingVcObj!
}

var shareFeedbackWindowControllerObj: commonWindowController?

func getShareFeedbackWindowControllerObj()->commonWindowController{
    if shareFeedbackWindowControllerObj == nil{
        shareFeedbackWindowControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        shareFeedbackWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return shareFeedbackWindowControllerObj!
}


var shareFeedbackVcObj:shareFeedbackVc?

func getShareFeedbackVcObj()->shareFeedbackVc{
    if shareFeedbackVcObj == nil{
        shareFeedbackVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shareFeedbackVc")) as? shareFeedbackVc
    }
    return shareFeedbackVcObj!
}


var trialExpiredNagWcObj: commonWindowController?

func getTrialExpiredWindowControllerObj()->commonWindowController{
    if trialExpiredNagWcObj == nil{
        trialExpiredNagWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        trialExpiredNagWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return trialExpiredNagWcObj!
}


var trialExpiredNagObj:trialExpiredNag?

func getTrialExpiredNagVcObj()->trialExpiredNag{
    if trialExpiredNagObj == nil{
        trialExpiredNagObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("trialExpiredNag")) as? trialExpiredNag
    }
    return trialExpiredNagObj!
}


var manageSubscriptionVcObj:manageSubscriptionVc?
func getManageSubscriptionVcObject()->manageSubscriptionVc{
    if manageSubscriptionVcObj == nil{
        manageSubscriptionVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("manageSubscriptionVc")) as? manageSubscriptionVc
    }
    return manageSubscriptionVcObj!
}


var addFocusTempUrlsOrAppsWcObj: commonWindowController?

func getAddFocusTempUrlsOrAppsWcObj()->commonWindowController{
    if addFocusTempUrlsOrAppsWcObj == nil{
        addFocusTempUrlsOrAppsWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        addFocusTempUrlsOrAppsWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return addFocusTempUrlsOrAppsWcObj!
}


var addFocusTempUrlsOrAppsVcObj:addFocusTempUrlsOrAppsVc?

func getAddFocusTempUrlsOrAppsVcObj()->addFocusTempUrlsOrAppsVc{
    if addFocusTempUrlsOrAppsVcObj == nil{
        addFocusTempUrlsOrAppsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addFocusTempUrlsOrAppsVc")) as? addFocusTempUrlsOrAppsVc
    }
    return addFocusTempUrlsOrAppsVcObj!
}


var focusTipsVcObj:focusTipsVc?

func getFocusTipsVcObjObj()->focusTipsVc{
    if focusTipsVcObj == nil{
        focusTipsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusTipsVc")) as? focusTipsVc
    }
    return focusTipsVcObj!
}
//var howHeardVcObj:howHeardVc?
//
//func getHowHeardVcObj()->howHeardVc{
//    if howHeardVcObj == nil{
//        howHeardVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("howHeardVc")) as? howHeardVc
//    }
//    return howHeardVcObj!
//}


var onboardingFeedbackVcObj:onboardingFeedbackVc?
func getOnboardingFeedbackVcObj()->onboardingFeedbackVc{
    if onboardingFeedbackVcObj == nil{
        onboardingFeedbackVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingFeedbackVc")) as? onboardingFeedbackVc
    }
    return onboardingFeedbackVcObj!
}


var askProcrastinatingVcObj:askProcrastinatingVc?
func getAskProcrastinatingVcObj()->askProcrastinatingVc{
    if askProcrastinatingVcObj == nil{
        askProcrastinatingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askProcrastinatingVc")) as? askProcrastinatingVc
    }
    return askProcrastinatingVcObj!
}


//var chooseFrictionLevelVcObj:chooseFrictionLevelVc?
//func getChooseFrictionLevelVcObj()->chooseFrictionLevelVc{
//    if chooseFrictionLevelVcObj == nil{
//        chooseFrictionLevelVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("chooseFrictionLevelVc")) as? chooseFrictionLevelVc
//    }
//    return chooseFrictionLevelVcObj!
//}

var installHabitPacksVcObj:installHabitPacksVc?
func getInstallHabitPacksVcObj()->installHabitPacksVc{
    if installHabitPacksVcObj == nil{
        installHabitPacksVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("installHabitPacksVc")) as? installHabitPacksVc
    }
    return installHabitPacksVcObj!
}


var changeFrictionLevelVcObj:changeFrictionLevelVc?
func getChangeFrictionLevelVcObj()->changeFrictionLevelVc{
    if changeFrictionLevelVcObj == nil{
        changeFrictionLevelVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("changeFrictionLevelVc")) as? changeFrictionLevelVc
    }
    return changeFrictionLevelVcObj!
}

//var onboardingSetPasswordVcObj:onboardingSetPasswordVc?
//func getOnboardingSetPasswordVcObj()->onboardingSetPasswordVc{
//    if onboardingSetPasswordVcObj == nil{
//        onboardingSetPasswordVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingSetPasswordVc")) as? onboardingSetPasswordVc
//    }
//    return onboardingSetPasswordVcObj!
//}

//let startingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startingFocusModeVc")) as? startingFocusModeVc
let abortingFocusModeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingFocusModeVc")) as? abortingFocusModeVc

let focusSummaryVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusSummaryVc")) as? focusSummaryVc


let enterPasswordVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc



var enterPasswordVcObjForPreferences:enterPasswordVc?
func getEnterPasswordVcObjForPreferences()->enterPasswordVc{
    if enterPasswordVcObjForPreferences == nil{
        enterPasswordVcObjForPreferences = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enterPasswordVc")) as? enterPasswordVc
        enterPasswordVcObjForPreferences?.loadView()
        enterPasswordVcObjForPreferences?.blockingView.isHidden = false
    }
    return enterPasswordVcObjForPreferences!
}



var addTaskVcObj:addTaskVc?
func getAddTaskVcObject()->addTaskVc{
    //if addTaskVcObj == nil{
    addTaskVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addTaskVc")) as? addTaskVc
    //}
    return addTaskVcObj!
}


var impactMeasurementVcObj:impactMeasurementVc?
func getImpactMeasurementVcObject()->impactMeasurementVc{
    if impactMeasurementVcObj == nil{
        impactMeasurementVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("impactMeasurementVc")) as? impactMeasurementVc
    }
    return impactMeasurementVcObj!
}



var surveyWcObj: commonWindowController?
func getSurveyWcObject()->commonWindowController{
    if surveyWcObj == nil{
        surveyWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        surveyWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    return surveyWcObj!
}


var surveyVcObj:surveyVc?
func getSurveyVcObject()->surveyVc{
    if surveyVcObj == nil{
        surveyVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("surveyVc")) as? surveyVc
    }
    return surveyVcObj!
}

var lateMorningHabitPopupVcObj:lateMorningHabitPopupVc?
func getLateMorningHabitPopupVcObject()->lateMorningHabitPopupVc{
    if lateMorningHabitPopupVcObj == nil{
        lateMorningHabitPopupVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("lateMorningHabitPopupVc")) as? lateMorningHabitPopupVc
    }
    return lateMorningHabitPopupVcObj!
}




var alertLimitedUsageVcObj:alertLimitedUsageVc?
func getAlertLimitedUsageVcObject()->alertLimitedUsageVc{
    if alertLimitedUsageVcObj == nil{
        alertLimitedUsageVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("alertLimitedUsageVc")) as? alertLimitedUsageVc
    }
    return alertLimitedUsageVcObj!
}


var confirmRoutineDurationVcObj:confirmRoutineDurationVc?
func getConfirmRoutineDurationVcObject()->confirmRoutineDurationVc{
    if confirmRoutineDurationVcObj == nil{
        confirmRoutineDurationVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("confirmRoutineDurationVc")) as? confirmRoutineDurationVc
    }
    return confirmRoutineDurationVcObj!
}


//confirmRunScript
var confirmRunScriptWcObj:commonWindowController?
func getConfirmRunScriptWindowObject()->commonWindowController{
    if confirmRunScriptWcObj == nil{
        confirmRunScriptWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        confirmRunScriptWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return confirmRunScriptWcObj!
}

var confirmRunScriptVcObj:confirmRunScriptVc?
func getConfirmRunScriptVcObject()->confirmRunScriptVc{
    if confirmRunScriptVcObj == nil{
        confirmRunScriptVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("confirmRunScriptVc")) as? confirmRunScriptVc
    }
    return confirmRunScriptVcObj!
}


var timeTrackerWcObj: commonWindowController?
func getTimeTrackerWcObject()->commonWindowController{
    if timeTrackerWcObj == nil{
        timeTrackerWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        timeTrackerWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    return timeTrackerWcObj!
}


var timeTrackerVcObj:timeTrackerVc?
func getTimeTrackerVcObject()->timeTrackerVc{
    if timeTrackerVcObj == nil{
        timeTrackerVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("timeTrackerVc")) as? timeTrackerVc
    }
    return timeTrackerVcObj!
}
var askPostponeIntentionVcObj:askPostponeIntentionVc?
func getAskPostponeIntentionVcObject()->askPostponeIntentionVc{
    if askPostponeIntentionVcObj == nil{
        askPostponeIntentionVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askPostponeIntentionVc")) as? askPostponeIntentionVc
    }
    return askPostponeIntentionVcObj!
}


var lateNoMorePopUpWcObj: commonWindowController?
func getLateNoMorePopUpWcObject()->commonWindowController{
    if lateNoMorePopUpWcObj == nil{
        lateNoMorePopUpWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        lateNoMorePopUpWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    return lateNoMorePopUpWcObj!
}

var lateNoMorePopUpVcObj:lateNoMorePopUpVc?
func getLateNoMorePopUpVcObject()->lateNoMorePopUpVc{
    if lateNoMorePopUpVcObj == nil{
        lateNoMorePopUpVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("lateNoMorePopUpVc")) as? lateNoMorePopUpVc
    }
    return lateNoMorePopUpVcObj!
}


//var taskPlayerWcObj:taskPlayerWc?
//func getTaskPlayerWindowObject()->taskPlayerWc{
//    if taskPlayerWcObj == nil{
//        taskPlayerWcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("taskPlayerWc")) as? taskPlayerWc
//    }
//    return taskPlayerWcObj!
//}



var taskPlayerVcObj:taskPlayerVc?
func getTaskPlayerVcObject()->taskPlayerVc{
    if taskPlayerVcObj == nil{
        taskPlayerVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("taskPlayerVc")) as? taskPlayerVc
    }
    return taskPlayerVcObj!
}


var longTermGoalsVcObj:longTermGoalsVc?
func getLongTermGoalsVcObject()->longTermGoalsVc{
    if longTermGoalsVcObj == nil{
        longTermGoalsVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("longTermGoalsVc")) as? longTermGoalsVc
    }
    return longTermGoalsVcObj!
}

var blankLayerWcObj:blankLayerWc?
func getBlankLayerWcObject()->blankLayerWc{
    if blankLayerWcObj == nil{
        blankLayerWcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blankLayerWc")) as? blankLayerWc
    }
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    blankLayerWcObj?.window?.setFrame(NSMakeRect(screenFrame.minX, screenFrame.minY, NSWidth(screenFrame), NSHeight(screenFrame)), display: true)
    blankLayerWcObj?.window?.makeKey()
    blankLayerWcObj?.window?.makeFirstResponder(blankLayerWcObj?.window)
    return blankLayerWcObj!
}

var blankLayerVcObj: blankLayerVc?
var focusPreferencesAdvancedVcObj:focusPreferencesAdvancedVc?


var breakSurveyVcObj:breakSurveyVc?
func getBreakSurveyVcObject()->breakSurveyVc{
    if breakSurveyVcObj == nil{
        breakSurveyVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("breakSurveyVc")) as? breakSurveyVc
    }
    return breakSurveyVcObj!
}

var breakSurveyWcObj:commonWindowController?
func getBreakSurveyWindowObject()->commonWindowController{
    if breakSurveyWcObj == nil{
        breakSurveyWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return breakSurveyWcObj!
}


// Custom Alert

var customAlertVcObj:customAlertVc?
func getCustomAlertVcObject()->customAlertVc{
    if customAlertVcObj == nil{
        customAlertVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customAlertVc")) as? customAlertVc
    }
    return customAlertVcObj!
}

var customAlertWcObj:commonWindowController?
func getCustomAlertWindowObject()->commonWindowController{
    if customAlertWcObj == nil{
        customAlertWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return customAlertWcObj!
}


//// unverifiedEmail window
var unverifiedEmailVcObj: unverifiedEmailVc?
func getUnverifiedEmailVcObject()->unverifiedEmailVc{
    if unverifiedEmailVcObj == nil{
        unverifiedEmailVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("unverifiedEmailVc")) as? unverifiedEmailVc
    }
    return unverifiedEmailVcObj!
}

var unverifiedEmailWcObj:commonWindowController?
func getUnverifiedEmailWindowObject()->commonWindowController{
    if unverifiedEmailWcObj == nil{
        unverifiedEmailWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return unverifiedEmailWcObj!
}


func getWebViewLoadFailedVcObject()->webViewLoadFailedVc{
    let webViewLoadFailedVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("webViewLoadFailedVc")) as? webViewLoadFailedVc
    return webViewLoadFailedVcObj!
}


var menuWcObj:commonWindowController?
func getMenuWindowObject()->commonWindowController{
    if menuWcObj == nil{
        menuWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        menuWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        menuWcObj?.window?.standardWindowButton(.zoomButton)?.isHidden = true
        menuWcObj?.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        menuWcObj?.window?.collectionBehavior = .stationary // make it visible even if stage manager is on // 19/6/25
    }
    return menuWcObj!
}

var nudgeFocusAlignmentScoreDippingVcObj:nudgeFocusAlignmentScoreDippingVc?
func getNudgeFocusAlignmentScoreDippingVcObject()->nudgeFocusAlignmentScoreDippingVc{
    if nudgeFocusAlignmentScoreDippingVcObj == nil{
        nudgeFocusAlignmentScoreDippingVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("nudgeFocusAlignmentScoreDippingVc")) as? nudgeFocusAlignmentScoreDippingVc
    }
    return nudgeFocusAlignmentScoreDippingVcObj!
}



//nudgeStartAnotherFocusSession
var nudgeStartAnotherFocusSessionWcObj:commonWindowController?
func getNudgeStartAnotherFocusSessionWcObject()->commonWindowController{
    if nudgeStartAnotherFocusSessionWcObj == nil{
        nudgeStartAnotherFocusSessionWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return nudgeStartAnotherFocusSessionWcObj!
}


var nudgeStartAnotherFocusSessionVcObj:nudgeStartAnotherFocusSessionVc?
func getNudgeStartAnotherFocusSessionVcObject()->nudgeStartAnotherFocusSessionVc{
    if nudgeStartAnotherFocusSessionVcObj == nil{
        nudgeStartAnotherFocusSessionVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("nudgeStartAnotherFocusSessionVc")) as? nudgeStartAnotherFocusSessionVc
    }
    return nudgeStartAnotherFocusSessionVcObj!
}





//reportBadAIResponse


var reportBadAIResponseWcObj:commonWindowController?
func getReportBadAIResponseWindowObject()->commonWindowController{
    if reportBadAIResponseWcObj == nil{
        reportBadAIResponseWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        reportBadAIResponseWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        reportBadAIResponseWcObj?.window?.standardWindowButton(.zoomButton)?.isHidden = true
        reportBadAIResponseWcObj?.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }
    return reportBadAIResponseWcObj!
}



var reportBadAIResponseVcObj:reportBadAIResponseVc?
func getReportBadAIResponseVcObject()->reportBadAIResponseVc{
    if reportBadAIResponseVcObj == nil{
        reportBadAIResponseVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("reportBadAIResponseVc")) as? reportBadAIResponseVc
    }
    return reportBadAIResponseVcObj!
}




// custom Routine Time window object
var customRoutineTimeWcObj:commonWindowController?
func getCustomRoutineTimeWindowObject()->commonWindowController{
    if customRoutineTimeWcObj == nil{
        customRoutineTimeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        customRoutineTimeWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    }
    return customRoutineTimeWcObj!
}

// customRoutineTime Vc object
var customRoutineTimeVcObj:customRoutineTimeVc?
func getCustomRoutineTimeVcObject()->customRoutineTimeVc{
    if customRoutineTimeVcObj == nil{
        customRoutineTimeVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customRoutineTimeVc")) as? customRoutineTimeVc
    }
    return customRoutineTimeVcObj!
}



// super Gentle Quit window object
var superGentleQuitWcObj:commonWindowController?
func getSuperGentleQuitWindowObject()->commonWindowController{
    if superGentleQuitWcObj == nil{
        superGentleQuitWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        superGentleQuitWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    return superGentleQuitWcObj!
}

// super Gentle Quit vc object
var superGentleQuitVcObj:superGentleQuitVc?
func getSuperGentleQuitVcObject()->superGentleQuitVc{
    if superGentleQuitVcObj == nil{
        superGentleQuitVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("superGentleQuitVc")) as? superGentleQuitVc
    }
    return superGentleQuitVcObj!
}



// loading window object
var splashWcObj:commonWindowController?
func getSplashWindowObject()->commonWindowController{
    if splashWcObj == nil{
        splashWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        splashWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))

//        splashWcObj?.window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
//        splashWcObj?.window?.canHide = false
//        splashWcObj?.window?.isExcludedFromWindowsMenu = true
//        splashWcObj?.window?.hidesOnDeactivate = false
//        splashWcObj?.window?.isRestorable = false
//        splashWcObj?.window?.animationBehavior = .none
//        splashWcObj?.window?.styleMask = .borderless
//        splashWcObj?.window?.backingType = .buffered
//        splashWcObj?.window?.minSize = NSSize(width: 900, height: 500)
        splashWcObj?.window?.title = ""
        
        
        splashWcObj?.window?.styleMask.insert(.fullSizeContentView)
        splashWcObj?.window?.titlebarAppearsTransparent = true
        splashWcObj?.window?.standardWindowButton(.zoomButton)?.isHidden = true
        splashWcObj?.window?.standardWindowButton(.closeButton)?.isHidden = true
        splashWcObj?.window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
        
        
        splashWcObj?.window?.center()
    }
    return splashWcObj!
}


// splash vc object
var splashVcObj:splashVc?
func getSplashVcObject()->splashVc{
    if splashVcObj == nil{
        splashVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("splashVc")) as? splashVc
    }
    return splashVcObj!
}




// popUpFocusGoalConfirmationVc object
var popUpFocusGoalConfirmationVcObj:popUpFocusGoalConfirmationVc?
func getPopUpFocusGoalConfirmationVcObject()->popUpFocusGoalConfirmationVc{
    if popUpFocusGoalConfirmationVcObj == nil{
        popUpFocusGoalConfirmationVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpFocusGoalConfirmationVc")) as? popUpFocusGoalConfirmationVc
    }
    return popUpFocusGoalConfirmationVcObj!
}


// popUpAddNewFocusGoalVc object
var popUpAddNewFocusGoalVcObj:popUpAddNewFocusGoalVc?
func getPopUpAddNewFocusGoalVcObject()->popUpAddNewFocusGoalVc{
    if popUpAddNewFocusGoalVcObj == nil{
        popUpAddNewFocusGoalVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpAddNewFocusGoalVc")) as? popUpAddNewFocusGoalVc
    }
    return popUpAddNewFocusGoalVcObj!
}

// popUpSaveThisTaskForLaterVc object
var popUpSaveThisTaskForLaterVcObj:popUpSaveThisTaskForLaterVc?
func getPopUpSaveThisTaskForLaterVcObject()->popUpSaveThisTaskForLaterVc{
    if popUpSaveThisTaskForLaterVcObj == nil{
        popUpSaveThisTaskForLaterVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("popUpSaveThisTaskForLaterVc")) as? popUpSaveThisTaskForLaterVc
    }
    return popUpSaveThisTaskForLaterVcObj!
}


//leftMenuVc
var leftMenuVcObj:leftMenuVc?
func getLeftMenuVcObject()->leftMenuVc{
    if leftMenuVcObj == nil{
        leftMenuVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("leftMenuVc")) as? leftMenuVc
    }
    return leftMenuVcObj!
}



//habitsVc
var habitsVcObj:habitsVc?
func getHabitsVcObject()->habitsVc{
    if habitsVcObj == nil{
        habitsVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("habitsVc")) as? habitsVc
    }
    return habitsVcObj!
}



//setUpVc
var setUpVcObj:setUpVc?
func getSetUpVcObject()->setUpVc{
    if setUpVcObj == nil{
        setUpVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("setUpVc")) as? setUpVc
    }
    return setUpVcObj!
}


//habitsStateVc
var habitsStateVcObj:habitsStateVc?
func getHabitsStateVcObject()->habitsStateVc{
    if habitsStateVcObj == nil{
        habitsStateVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("habitsStateVc")) as? habitsStateVc
    }
    return habitsStateVcObj!
}



//customRoutineStateVc
var customRoutineStateVcObj:customRoutineStateVc?
func getCustomRoutineStateVcObject()->customRoutineStateVc{
    if customRoutineStateVcObj == nil{
        customRoutineStateVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customRoutineStateVc")) as? customRoutineStateVc
    }
    return customRoutineStateVcObj!
}



var focusPreferencesVcObj:focusPreferencesVc?
func getFocusPreferencesVcObject()->focusPreferencesVc{
    if focusPreferencesVcObj == nil{
        focusPreferencesVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesVc")) as? focusPreferencesVc
    }
    return focusPreferencesVcObj!
}
//getTabStrictnessContainerVcObject  getFocusPreferencesVcObject getSettingsSplitViewControllerObject getSelectJsonVcObject

//settingsSplitViewController
var settingsSplitViewControllerObj:settingsSplitViewController?
func getSettingsSplitViewControllerObject()->settingsSplitViewController{
    if settingsSplitViewControllerObj == nil{
        settingsSplitViewControllerObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingsSplitViewController")) as? settingsSplitViewController
    }
    return settingsSplitViewControllerObj!
}

var selectJsonVcObj:selectJsonVc?// = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
func getSelectJsonVcObject()->selectJsonVc{
    if selectJsonVcObj == nil{
        selectJsonVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("selectJsonVc")) as? selectJsonVc
    }
    return selectJsonVcObj!
}


//breaksStateVc
var breaksStateVcObj:breaksStateVc?
func getBreaksStateVcObject()->breaksStateVc{
    if breaksStateVcObj == nil{
        breaksStateVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("breaksStateVc")) as? breaksStateVc
    }
    return breaksStateVcObj!
}


//helpVc
var helpVcObj:helpVc?
func getHelpVcObject()->helpVc{
    if helpVcObj == nil{
        helpVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("helpVc")) as? helpVc
    }
    return helpVcObj!
}


//focusModeStateVc
var focusModeStateVcObj:focusModeStateVc?
func getFocusModeStateVcObject()->focusModeStateVc{
    if focusModeStateVcObj == nil{
        focusModeStateVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusModeStateVc")) as? focusModeStateVc
    }
    return focusModeStateVcObj!
}


//floatingTopBarVc
var floatingTopBarVcObj:floatingTopBarVc?
func getFloatingTopBarVObject()->floatingTopBarVc{
    if floatingTopBarVcObj == nil{
        floatingTopBarVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("floatingTopBarVc")) as? floatingTopBarVc
    }
    return floatingTopBarVcObj!
}

//floatingTopBarWc
var floatingTopBarWcObj:commonWindowController?
func getFloatingTopBarWObject()->commonWindowController{
    if floatingTopBarWcObj == nil{
        floatingTopBarWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return floatingTopBarWcObj!
}



