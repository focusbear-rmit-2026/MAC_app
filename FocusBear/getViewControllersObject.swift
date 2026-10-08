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

var itemActionBarPlayVcObj: itemActionBarVc?
func getItemActionBarPlayVcObject()->itemActionBarVc{
    if itemActionBarPlayVcObj == nil{
        itemActionBarPlayVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("itemActionBarVc")) as? itemActionBarVc
    }
    return itemActionBarPlayVcObj!
}

var itemActionBarDoneVcObj: itemActionBarVc?
func getItemActionBarDoneVcObject()->itemActionBarVc{
    if itemActionBarDoneVcObj == nil{
        itemActionBarDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("itemActionBarVc")) as? itemActionBarVc
    }
    return itemActionBarDoneVcObj!
}

var itemActionBarSkipVcObj: itemActionBarVc?
func getItemActionBarSkipVcObject()->itemActionBarVc{
    if itemActionBarSkipVcObj == nil{
        itemActionBarSkipVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("itemActionBarVc")) as? itemActionBarVc
    }
    return itemActionBarSkipVcObj!
}

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

var routinePostponedInfoVcObj:routinePostponedInfoVc?
func getRutinePostponedInfoVcObject()->routinePostponedInfoVc{
    if routinePostponedInfoVcObj == nil{
        routinePostponedInfoVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("routinePostponedInfoVc")) as? routinePostponedInfoVc
    }
    return routinePostponedInfoVcObj!
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


//breakStartVc — the SwiftUI break start screen (the micro-break habit list + office/WFH toggle).
var breakStartVcObj:breakStartVc?
func getBreakStartVcObject()->breakStartVc{
    if breakStartVcObj == nil{
        // Built in code (SwiftUI-hosted), not from the storyboard.
        breakStartVcObj = breakStartVc()
    }
    return breakStartVcObj!
}

var brainDumpVcObj:brainDumpVc?
func getBrainDumpVcObject()->brainDumpVc{
    if brainDumpVcObj == nil{
        // Built in code (SwiftUI-hosted), not from the storyboard.
        brainDumpVcObj = brainDumpVc()
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



var welcomeVcObj:welcomeVc?
func getWelcomeVcObject()->welcomeVc{
    if welcomeVcObj == nil{
        welcomeVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeVc")) as? welcomeVc
    }
    return welcomeVcObj!
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
        customLoginVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customLoginVc")) as? customLoginVc
    }
    return customLoginVcObj!
}

var holdOnVcObj:holdOnVc?
func getHoldOnVcObject()->holdOnVc{
    if holdOnVcObj == nil{
        holdOnVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("holdOnVc")) as? holdOnVc
    }
    return holdOnVcObj!
}

var setUpHabitsVcObj:setUpHabitsVc?
func getSetUpHabitsVcObject()->setUpHabitsVc{
    if setUpHabitsVcObj == nil{
        setUpHabitsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("setUpHabitsVc")) as? setUpHabitsVc
    }
    return setUpHabitsVcObj!
}

var startSetUpHabitsVcObj:startSetUpHabitsVc?
func getStartSetUpHabitsVcObject()->startSetUpHabitsVc{
    if startSetUpHabitsVcObj == nil{
        startSetUpHabitsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("startSetUpHabitsVc")) as? startSetUpHabitsVc
    }
    return startSetUpHabitsVcObj!
}




var permissionBlockDistractionWcObj:commonWindowController?
func getPermissionBlockDistractionWindowObject()->commonWindowController{
    if permissionBlockDistractionWcObj == nil{
        permissionBlockDistractionWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
        //permissionBlockDistractionWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.assistiveTechHighWindow)))
        permissionBlockDistractionWcObj?.window?.title = appName
    }
    return permissionBlockDistractionWcObj!
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

var alwaysAllowedAppsVcObj:alwaysAllowedAppsVc?
func getAlwaysAllowedAppsVcObject()->alwaysAllowedAppsVc{
    if alwaysAllowedAppsVcObj == nil{
        alwaysAllowedAppsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("alwaysAllowedAppsVc")) as? alwaysAllowedAppsVc
    }
    return alwaysAllowedAppsVcObj!
}


var customBlockingSchedulesVcObj:customBlockingSchedulesVc?
func getCustomBlockingSchedulesVcObject()->customBlockingSchedulesVc{
    if customBlockingSchedulesVcObj == nil{
        customBlockingSchedulesVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("customBlockingSchedulesVc")) as? customBlockingSchedulesVc
    }
    return customBlockingSchedulesVcObj!
}

var blockingScheduleEditorVCObj:blockingScheduleEditorVC?
func getBlockingScheduleEditorVCObject()->blockingScheduleEditorVC{
    if blockingScheduleEditorVCObj == nil{
        blockingScheduleEditorVCObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blockingScheduleEditorVC")) as? blockingScheduleEditorVC
    }
    return blockingScheduleEditorVCObj!
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

func getKeyboardShortcutsSettingsVcObject() -> keyboardShortcutsSettingsVc {
    if keyboardShortcutsSettingsVcObj == nil {
        keyboardShortcutsSettingsVcObj = keyboardShortcutsSettingsVc()
        keyboardShortcutsSettingsVcObj?.loadView()
        keyboardShortcutsSettingsVcObj?.viewDidLoad()
    }
    return keyboardShortcutsSettingsVcObj!
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

//talkingClockSettingsVcObj
var talkingClockSettingsVcObj:talkingClockSettingsVc?
func getTalkingClockSettingsVcObject()->talkingClockSettingsVc{
    if talkingClockSettingsVcObj == nil{
        talkingClockSettingsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("talkingClockSettingsVc")) as? talkingClockSettingsVc
    }
    return talkingClockSettingsVcObj!
}

//microBreaksSettingsVcObj
var microBreaksSettingsVcObj:microBreaksSettingsVc?
func getMicroBreaksSettingsVcObject()->microBreaksSettingsVc{
    if microBreaksSettingsVcObj == nil{
        microBreaksSettingsVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("microBreaksSettingsVc")) as? microBreaksSettingsVc
    }
    return microBreaksSettingsVcObj!
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



// todoList Tool object
var todoListToolVcObj:todoListToolVc?
func getTodoListToolVcObject()->todoListToolVc{
    if todoListToolVcObj == nil{
        // Built in code (SwiftUI-hosted), not from the storyboard.
        todoListToolVcObj = todoListToolVc()
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


var askOccupationVcObj:askOccupationVc?
func getAskOccupationVcObject()->askOccupationVc{
    if askOccupationVcObj == nil{
        askOccupationVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askOccupationVc")) as? askOccupationVc
    }
    return askOccupationVcObj!
}

var enableAIBlockingVcObj:enableAIBlockingVc?
func getEnableAIBlockingVcObject()->enableAIBlockingVc{
    if enableAIBlockingVcObj == nil{
        enableAIBlockingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("enableAIBlockingVc")) as? enableAIBlockingVc
    }
    return enableAIBlockingVcObj!
}

var askSetDistractionsVcObj:askSetDistractionsVc?
func getAskSetDistractionsVcObject()->askSetDistractionsVc{
    if askSetDistractionsVcObj == nil{
        askSetDistractionsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askSetDistractionsVc")) as? askSetDistractionsVc
    }
    return askSetDistractionsVcObj!
}


var onboardingVcObj:onboardingVc?
func getOnboardingVcObject()->onboardingVc{
    if onboardingVcObj == nil{
        onboardingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingVc")) as? onboardingVc
    }
    return onboardingVcObj!
}

//Allowed Urls vc object
var onboardingAllowedUrlsVcObj:onboardingAllowedUrlsVc?
func getOnboardingAllowedUrlsVcObject()->onboardingAllowedUrlsVc{
    if onboardingAllowedUrlsVcObj == nil{
        onboardingAllowedUrlsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingAllowedUrlsVc")) as? onboardingAllowedUrlsVc
    }
    return onboardingAllowedUrlsVcObj!
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


var onboardingPrivacyTipVcObj:onboardingPrivacyTipVc?
func getOnboardingPrivacyTipVcObject()->onboardingPrivacyTipVc{
    if onboardingPrivacyTipVcObj == nil{
        onboardingPrivacyTipVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingPrivacyTipVc")) as? onboardingPrivacyTipVc
    }
    return onboardingPrivacyTipVcObj!
}


var welcomeAdhdVcObj:welcomeAdhdVc?
func getWelcomeAdhdVcObject()->welcomeAdhdVc{
    if welcomeAdhdVcObj == nil{
        welcomeAdhdVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeAdhdVc")) as? welcomeAdhdVc
    }
    return welcomeAdhdVcObj!
}


var welcomeLetsDoItVcObj:welcomeLetsDoItVc?
func getWelcomeLetsDoItVcObject()->welcomeLetsDoItVc{
    if welcomeLetsDoItVcObj == nil{
        welcomeLetsDoItVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("welcomeLetsDoItVc")) as? welcomeLetsDoItVc
    }
    return welcomeLetsDoItVcObj!
}

var setUpAccountVcObj:setUpAccountVc?
func getSetUpAccountVcObject()->setUpAccountVc{
    if setUpAccountVcObj == nil{
        setUpAccountVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("setUpAccountVc")) as? setUpAccountVc
    }
    return setUpAccountVcObj!
}



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

// allSetVc
var allSetVcObj:allSetVc?
func getAllSetVcObject()->allSetVc{
    if allSetVcObj == nil{
        allSetVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("allSetVc")) as? allSetVc
    }
    return allSetVcObj!
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
func getTryBlockUrlVcObject()->tryBlockUrlVc{// always catch a new object 
    tryBlockUrlVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("tryBlockUrlVc")) as? tryBlockUrlVc
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




let activityCompletionVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("activityCompletionVc")) as? activityCompletionVc


let shutOffTimeVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("shutOffTimeVc")) as? shutOffTimeVc

let abortingCountDownVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCountDownVc")) as? abortingCountDownVc
let abortingConfirmVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingConfirmVc")) as? abortingConfirmVc
let abortDoneVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortDoneVc")) as? abortDoneVc




let abortingCantHandleVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCantHandleVc")) as? abortingCantHandleVc
let logQuantityVcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("logQuantityVc")) as? logQuantityVc


var menuViewControllerObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("menuViewController")) as? menuViewController

let addWebUrlVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addWebUrlVc")) as? addWebUrlVc
let addFocusTypeVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("addFocusTypeVc")) as? addFocusTypeVc



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


var confirmBlockingScheduleCreationVcObj:confirmBlockingScheduleCreationVc?
func getConfirmBlockingScheduleCreationVcObj()->confirmBlockingScheduleCreationVc{
    if confirmBlockingScheduleCreationVcObj == nil{
        confirmBlockingScheduleCreationVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("confirmBlockingScheduleCreationVc")) as? confirmBlockingScheduleCreationVc
    }
    return confirmBlockingScheduleCreationVcObj!
}

var createFirstBlockingScheduleVcObj:createFirstBlockingScheduleVc?
func getCreateFirstBlockingScheduleVcObj()->createFirstBlockingScheduleVc{
    if createFirstBlockingScheduleVcObj == nil{
        createFirstBlockingScheduleVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("createFirstBlockingScheduleVc")) as? createFirstBlockingScheduleVc
    }
    return createFirstBlockingScheduleVcObj!
}

var onboardingBlockingSchedulePresetsVcObj: onboardingBlockingSchedulePresetsVc?
func getOnboardingBlockingSchedulePresetsVcObject() -> onboardingBlockingSchedulePresetsVc {
    if onboardingBlockingSchedulePresetsVcObj == nil {
        onboardingBlockingSchedulePresetsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("onboardingBlockingSchedulePresetsVc")) as? onboardingBlockingSchedulePresetsVc
    }
    return onboardingBlockingSchedulePresetsVcObj!
}

var askPermissionsVcObj:askPermissionsVc?
func getAskPermissionsVcObj()->askPermissionsVc{
    if askPermissionsVcObj == nil{
        askPermissionsVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("askPermissionsVc")) as? askPermissionsVc
    }
    return askPermissionsVcObj!
}



var installHabitPacksVcObj:installHabitPacksVc?
func getInstallHabitPacksVcObj()->installHabitPacksVc{
    if installHabitPacksVcObj == nil{
        installHabitPacksVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("installHabitPacksVc")) as? installHabitPacksVc
    }
    return installHabitPacksVcObj!
}


var setScheduledDistractionBlockingVcObj:setScheduledDistractionBlockingVc?
func getSetScheduledDistractionBlockingVcObj()->setScheduledDistractionBlockingVc{
    if setScheduledDistractionBlockingVcObj == nil{
        setScheduledDistractionBlockingVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("setScheduledDistractionBlockingVc")) as? setScheduledDistractionBlockingVc
    }
    return setScheduledDistractionBlockingVcObj!
}



var changeFrictionLevelVcObj:changeFrictionLevelVc?
func getChangeFrictionLevelVcObj()->changeFrictionLevelVc{
    if changeFrictionLevelVcObj == nil{
        changeFrictionLevelVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("changeFrictionLevelVc")) as? changeFrictionLevelVc
    }
    return changeFrictionLevelVcObj!
}


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


//var breakSurveyVcObj:breakSurveyVc?
//func getBreakSurveyVcObject()->breakSurveyVc{
//    if breakSurveyVcObj == nil{
//        breakSurveyVcObj = newStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("breakSurveyVc")) as? breakSurveyVc
//    }
//    return breakSurveyVcObj!
//}
//
//var breakSurveyWcObj:commonWindowController?
//func getBreakSurveyWindowObject()->commonWindowController{
//    if breakSurveyWcObj == nil{
//        breakSurveyWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
//    }
//    return breakSurveyWcObj!
//}


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


// Custom suggest focus mode window

var suggestFocusModeVcObj:suggestFocusModeVc?
func getSuggestFocusModeVcObject()->suggestFocusModeVc{
    if suggestFocusModeVcObj == nil{
        suggestFocusModeVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("suggestFocusModeVc")) as? suggestFocusModeVc
    }
    return suggestFocusModeVcObj!
}

var suggestFocusModeWcObj:commonWindowController?
func getSuggestFocusModeWindowObject()->commonWindowController{
    if suggestFocusModeWcObj == nil{
        suggestFocusModeWcObj = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("commonWindowController")) as? commonWindowController
    }
    return suggestFocusModeWcObj!
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
        // canJoinAllSpaces + fullScreenAuxiliary so the menu also appears over another app's native
        // full-screen space (Chrome/etc. green-button full screen); canJoinAllSpaces also keeps it
        // visible under Stage Manager. // 19/6/25, full-screen fix
        menuWcObj?.window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
        // Built in code (SwiftUI-hosted Stats screen), not from the storyboard.
        setUpVcObj = setUpVc()
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


var abortingCustomScheduleBlockingVcObj:abortingCustomScheduleBlockingVc?
func getAbortingCustomScheduleBlockingVcObject()->abortingCustomScheduleBlockingVc{
    if abortingCustomScheduleBlockingVcObj == nil{
        abortingCustomScheduleBlockingVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("abortingCustomScheduleBlockingVc")) as? abortingCustomScheduleBlockingVc
    }
    return abortingCustomScheduleBlockingVcObj!
}




var focusPreferencesVcObj:focusPreferencesVc?
func getFocusPreferencesVcObject()->focusPreferencesVc{
    if focusPreferencesVcObj == nil{
        focusPreferencesVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("focusPreferencesVc")) as? focusPreferencesVc
    }
    return focusPreferencesVcObj!
}

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
        // Built in code, not from the storyboard — the screen is SwiftUI hosted in loadView().
        focusModeStateVcObj = focusModeStateVc()
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




//messageBoxVc
var messageBoxVcObj:messageBoxVc?
func getMessageBoxVcObject()->messageBoxVc{
    if messageBoxVcObj == nil{
        messageBoxVcObj = nagsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("messageBoxVc")) as? messageBoxVc
    }
    return messageBoxVcObj!
}


// officeModeSettingsVcObj — Office Mode settings: direct Office/WFH toggle + Wi-Fi auto-switching (#1000)
// Note: officeModeSettingsVc creates its UI programmatically; no storyboard scene required.
var officeModeSettingsVcObj: officeModeSettingsVc?
func getOfficeModeSettingsVcObject() -> officeModeSettingsVc {
    if officeModeSettingsVcObj == nil {
        officeModeSettingsVcObj = officeModeSettingsVc()
    }
    return officeModeSettingsVcObj!
}
