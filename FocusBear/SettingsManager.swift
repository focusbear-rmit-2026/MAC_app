//
//  SettingsManager.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 04/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class SettingsManager:NSObject{
    
    let strictnessLevelSuperGentle = 1
    let strictnessLevelGentle = 2
    let strictnessLevelSlightlyStrict = 3
    let strictnessLevelStrict = 4
    let strictnessLevelSuperStrict = 5
    
    var isSettingsChanged = false
    var isSoundEnabled = true
    var isAnnouncementEnabled = false
    var isGeekModeEnabled = true
    var isMenuPopoverEnabled = false // menu is popover or a a window
    var isAdvancedAnalyticsInFocusModeEnabled = false// Advance analytics during focus mode //27/1/25 //  default  will be false
    var isDataCollectionModeEnabled = false// equvalent of the focus alignment score cutoff being set to 0% //30/5/25 //  default  will be false
    
    var isDetectNatualBreaksEnabled = true// 19/7/25 version 1.26.392   "Don't show this again" option for natural break detection popups #1466
    
    var isFocusVisualIndicatorEnabled = true
    
    var isPasswordRequireInChangeSettings = true
    var isPasswordRequireInSkipMorning = true
    var isPasswordRequireInSkipEvening = true
    var isPasswordRequireInSkipEveningAfterCutOff = true
    var isPasswordRequireInAbortShutoff = true
    var isPasswordRequireInStopPomodoro = true
    var isPasswordRequireInQuitApp = true
    var isPasswordRequireInUseRelaxFocusMode = true
    var isPasswordRequireInCircumventingBlocks = true
    var isPasswordRequireInPreferencesAfterCutoff = true
    
    
    var isCuddlyModeEnabled = true
    var immediatelyBlockDistractingSites = false
    var immediatelyBlockDistractingApps = false
    
    var startPomodoroShortcutChar = "P"
    var startPomodoroShortcutFlags:[Int] = [shortcutFlags._COMMAND_.rawValue, shortcutFlags._CONTROL_.rawValue, shortcutFlags._OPTION_.rawValue]
    
    
    var isMotivationalMessageEnabled = true
    var isAiCheckUrlEnabled = true
    //    var isAiAllowUrlShowAlertEnabled = true
    
    
    // **blocked urls**
    var arrBlockedUrls = [String]()
    var arrBlockedApps = [String]()
    var isOfficeModeEnabled = true
    var kIsReducedMotion = false
    var isMeetingDetectionEnabled = true
    var isBlockDistractingSitesDuringMeetingsEnabled = false
    var showMeetingDetectionAlert = false
    var isHideDockInActivity = false
    var isPromptToRememberHabit = true
    var isEasySkipEnabled = true
    var isOutOfOrderHabitsAllowed = true
    var isRequiredIntentionInPostpone = false
    var IsShowBreaksInPostponeEnabled = false
    var IsShowBreaksInCallEnabled = false
    var isTabLimiterEnabled = false
    var isFullScreenEnabled = false// always set false here for onboarding
    
    var showToDoPlayerAutomaticallyEnabled = true
    var showBrainDumpAfterMorningRoutineEnabled = false
    var isMicroBreaksEnabled = true
    var blockingSchedule:BLOCKINGSCHEDULE = ._WHEN_START_FOCUS_SESSION_// not in use need to remove soon // todo 
    
    
    var brainDumpCustomUrlEnabled = false
    var brainDumpCustomUrlValue = ""
    
    var shouldReloadAfterForceQuitEnabled = false
    var selectedFontIndex = 0
    var cuddlyModeProgressCount = 0
    var doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue = false// default vale
    
    
    var selectedAppAppearanceIndex = 0
    var maxTabLimitCount = 5
    
    
    var kUserdefaultsAppPassword = "kUserdefaultsAppPassword"
    
    var kUserdefaultsPasswordRequireInChangeSettings = "kUserdefaultsPasswordRequireInChangeSettings"
    var kUserdefaultsPasswordRequireInSkipMorning = "kUserdefaultsPasswordRequireInSkipMorning"
    var kUserdefaultsPasswordRequireInSkipEvening = "kUserdefaultsPasswordRequireInSkipEvening"
    var kUserdefaultsPasswordRequireInSkipEveningAfterCutOff = "kUserdefaultsPasswordRequireInSkipEveningAfterCutOff"
    var kUserdefaultsPasswordRequireInAbortShutoff = "kUserdefaultsPasswordRequireInAbortShutoff"
    var kUserdefaultsPasswordRequireInStopPomodoro = "kUserdefaultsPasswordRequireInStopPomodoro"
    var kUserdefaultsPasswordRequireInQuitApp = "kUserdefaultsPasswordRequireInQuitApp"
    var kUserdefaultsPasswordRequireInUseRelaxFocusMode = "kUserdefaultsPasswordRequireInUseRelaxFocusMode"
    
    
    
    var kUserdefaultsArrBlockedUrls = "kUserdefaultsArrBlockedUrls"
    var kUserdefaultsArrBlockedApps = "kUserdefaultsArrBlockedApps"
    
    var kUserdefaultsOfficeModeEnabled = "kUserdefaultsOfficeModeEnabled"
    var kUserdefaultsReducedMotion = "kUserdefaultsReducedMotion"
    
    var kUserdefaultsMeetingDetectionEnabled = "kUserdefaultsMeetingDetectionEnabled"
    var kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled = "kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled"
    var kUserdefaultsShowMeetingDetectionAlert = "kUserdefaultsShowMeetingDetectionAlert"
    
    var kUserdefaultsHideDockInActivity = "kUserdefaultsHideDockInActivity"
    var kUserdefaultsShowBreaksInPostponing = "kUserdefaultsShowBreaksInPostponing"
    var kUserdefaultsShowBreaksInCall = "kUserdefaultsShowBreaksInCall"
    
    var kUserdefaultsisTabLimiterEnabled = "kUserdefaultsisTabLimiterEnabled"
    var kUserdefaultsTabLimitCount = "kUserdefaultsTabLimitCount"
    
    var kUserdefaultsisFullScreenEnabled = "kUserdefaultsisFullScreenEnabled"
    var kUserdefaultsShouldReloadAfterForceQuitEnabled = "kUserdefaultsShouldReloadAfterForceQuitEnabled"
    var kUserdefaultsselectedFontIndex = "kUserdefaultsselectedFontIndex"
    var kUserdefaultsCuddlyModeProgressCount = "kUserdefaultsCuddlyModeProgressCount"
    
    var kUserdefaultsSelectedAppAppearanceIndex = "kUserdefaultsSelectedAppAppearanceIndex"
    
    
    var kUserdefaultsPromptToRememberHabit = "kUserdefaultsPromptToRememberHabit"
    var kUserdefaultsOutOfOrderHabitsAllowed = "kUserdefaultsOutOfOrderHabitsAllowed"
    var kUserdefaultsRequiredIntentionInPostpone = "kUserdefaultsRequiredIntentionInPostpone"
    
    var kUserdefaultsEasySkipEnabled = "kUserdefaultsEasySkipEnabled"
    var kUserdefaultsEnableSound = "kUserdefaultsEnableSound"
    var kUserdefaultsEnableAnnouncement = "kUserdefaultsEnableAnnouncement"
    
    var kUserdefaultsCuddlyModeEnabled = "kUserdefaultsCuddlyModeEnabled"
    var kUserdefaultsGeekModeEnabled = "kUserdefaultsGeekModeEnabled"
    
    
    var kUserdefaultsImmediatelyBlockDistractingSites = "kUserdefaultsImmediatelyBlockDistractingSites"
    var kUserdefaultsImmediatelyBlockDistractingApps = "kUserdefaultsImmediatelyBlockDistractingApps"
    
    var kUserdefaultsStartPomodoroShortcutChar = "kUserdefaultsstartPomodoroShortcutChar"
    var kUserdefaultsStartPomodoroShortcutFlags = "kUserdefaultsStartPomodoroShortcutFlags"
    
    var kUserdefaultsMotivationalMessageEnabled = "kUserdefaultsMotivationalMessageEnabled"
    var kUserdefaultsAiCheckUrlEnabled = "kUserdefaultsAiCheckUrlEnabled"
    
    var kUserdefaultsLocalDeviceSettings = "kUserdefaultsLocalDeviceSettings"
    
    //    var kUserdefaultsAiAllowUrlShowAlertEnabled = "kUserdefaultsAiAllowUrlShowAlertEnabled"
    
    var kUserdefaultsPomodoroDurationMinutes = "kUserdefaultsPomodoroDurationMinutes"
    var kUserdefaultsBreakDurationMinutes = "kUserdefaultsBreakDurationMinutes"
    var kUserdefaultsWorkRatioInPomodoro = "kUserdefaultsWorkRatioInPomodoro"
    var kUserdefaultsBreakRatioInPomodoro = "kUserdefaultsBreakRatioInPomodoro"
    
    var kUserdefaultsHideAllWindowInScreenShots = "kUserdefaultsHideAllWindowInScreenShots"
    var kUserdefaultsPomodoroModeEnabled = "kUserdefaultsPomodoroModeEnabled"
    var kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks = "kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks"
    
    var kUserdefaultsHardcorePomodoroEnabled = "kUserdefaultsHardcorePomodoroEnabled"
    var kUserdefaultsHardcorePomodoroFocusedName = "kUserdefaultsHardcorePomodoroFocusedName"
    var kUserdefaultsHardcorePomodoroFocusedCount = "kUserdefaultsHardcorePomodoroFocusedCount"
    var kUserdefaultsHardcorePomodoroSkipMicroBreaks = "kUserdefaultsHardcorePomodoroSkipMicroBreaks"
    
    var kUserdefaultsPomodoroSkipMicroBreaks = "kUserdefaultsPomodoroSkipMicroBreaks"// for local use only
    
    var kUserdefaultsHardcorePomodoroArrDays = "kUserdefaultsHardcorePomodoroArrDays"
    
    let kMonday = "Monday"
    let kTuesday = "Tuesday"
    let kWednesday = "Wednesday"
    let kThursday = "Thursday"
    let kFriday = "Friday"
    let kSaturday = "Saturday"
    let kSunday = "Sunday"
    
    func getDayOfWeek(fromDate date: Date) -> String? {
        let cal = Calendar(identifier: .gregorian)
        let dayOfWeek = cal.component(.weekday, from: date)
        switch dayOfWeek {
        case 1:
            return kSunday
        case 2:
            return kMonday
        case 3:
            return kTuesday
        case 4:
            return kWednesday
        case 5:
            return kThursday
        case 6:
            return kFriday
        case 7:
            return kSaturday
        default:
            return nil
        }
    }
    
    func resetAllKeys() {
        kUserdefaultsLocalDeviceSettings = kUserdefaultsLocalDeviceSettings + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsAppPassword = kUserdefaultsAppPassword + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsPasswordRequireInChangeSettings = kUserdefaultsPasswordRequireInChangeSettings + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInSkipMorning = kUserdefaultsPasswordRequireInSkipMorning + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInSkipEvening = kUserdefaultsPasswordRequireInSkipEvening + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInSkipEveningAfterCutOff = kUserdefaultsPasswordRequireInSkipEveningAfterCutOff + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInAbortShutoff = kUserdefaultsPasswordRequireInAbortShutoff + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInStopPomodoro = kUserdefaultsPasswordRequireInStopPomodoro + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInQuitApp = kUserdefaultsPasswordRequireInQuitApp + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInUseRelaxFocusMode = kUserdefaultsPasswordRequireInUseRelaxFocusMode + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsArrBlockedUrls = kUserdefaultsArrBlockedUrls + (appdelegate?.user?.userId ?? "")
        kUserdefaultsArrBlockedApps = kUserdefaultsArrBlockedApps + (appdelegate?.user?.userId ?? "")
        kUserdefaultsOfficeModeEnabled = kUserdefaultsOfficeModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsReducedMotion = kUserdefaultsReducedMotion + (appdelegate?.user?.userId ?? "")
        kUserdefaultsMeetingDetectionEnabled = kUserdefaultsMeetingDetectionEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled = kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsShowMeetingDetectionAlert = kUserdefaultsShowMeetingDetectionAlert + (appdelegate?.user?.userId ?? "")
        //        kUserdefaultsHideDockInActivity = kUserdefaultsHideDockInActivity + (appdelegate?.user?.userId ?? "")//no ned to do this
        kUserdefaultsPromptToRememberHabit = kUserdefaultsPromptToRememberHabit + (appdelegate?.user?.userId ?? "")
        kUserdefaultsEasySkipEnabled = kUserdefaultsEasySkipEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsShowBreaksInPostponing = kUserdefaultsShowBreaksInPostponing + (appdelegate?.user?.userId ?? "")
        kUserdefaultsShowBreaksInCall = kUserdefaultsShowBreaksInCall + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsisTabLimiterEnabled = kUserdefaultsisTabLimiterEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsTabLimitCount = kUserdefaultsTabLimitCount + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsisFullScreenEnabled = kUserdefaultsisFullScreenEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsShouldReloadAfterForceQuitEnabled = kUserdefaultsShouldReloadAfterForceQuitEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsselectedFontIndex = kUserdefaultsselectedFontIndex + (appdelegate?.user?.userId ?? "")
        kUserdefaultsCuddlyModeProgressCount = kUserdefaultsCuddlyModeProgressCount + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsSelectedAppAppearanceIndex = kUserdefaultsSelectedAppAppearanceIndex + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsCuddlyModeEnabled = kUserdefaultsCuddlyModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsGeekModeEnabled = kUserdefaultsGeekModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsImmediatelyBlockDistractingSites = kUserdefaultsImmediatelyBlockDistractingSites + (appdelegate?.user?.userId ?? "")
        kUserdefaultsImmediatelyBlockDistractingApps = kUserdefaultsImmediatelyBlockDistractingApps + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsStartPomodoroShortcutChar = kUserdefaultsStartPomodoroShortcutChar + (appdelegate?.user?.userId ?? "")
        kUserdefaultsStartPomodoroShortcutFlags = kUserdefaultsStartPomodoroShortcutFlags + (appdelegate?.user?.userId ?? "")
        
        
        kUserdefaultsMotivationalMessageEnabled = kUserdefaultsMotivationalMessageEnabled + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsAiCheckUrlEnabled = kUserdefaultsAiCheckUrlEnabled + (appdelegate?.user?.userId ?? "")
        //        kUserdefaultsAiAllowUrlShowAlertEnabled = kUserdefaultsAiAllowUrlShowAlertEnabled + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsPomodoroDurationMinutes = kUserdefaultsPomodoroDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsBreakDurationMinutes = kUserdefaultsBreakDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsWorkRatioInPomodoro = kUserdefaultsWorkRatioInPomodoro + (appdelegate?.user?.userId ?? "")
        kUserdefaultsBreakRatioInPomodoro = kUserdefaultsBreakRatioInPomodoro + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHideAllWindowInScreenShots = kUserdefaultsHideAllWindowInScreenShots + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPomodoroModeEnabled = kUserdefaultsPomodoroModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks = kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroEnabled = kUserdefaultsHardcorePomodoroEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedName = kUserdefaultsHardcorePomodoroFocusedName + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedCount = kUserdefaultsHardcorePomodoroFocusedCount + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroSkipMicroBreaks = kUserdefaultsHardcorePomodoroSkipMicroBreaks + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroArrDays = kUserdefaultsHardcorePomodoroArrDays + (appdelegate?.user?.userId ?? "")
        kUserdefaultsOutOfOrderHabitsAllowed = kUserdefaultsOutOfOrderHabitsAllowed + (appdelegate?.user?.userId ?? "")
        kUserdefaultsRequiredIntentionInPostpone = kUserdefaultsRequiredIntentionInPostpone + (appdelegate?.user?.userId ?? "")
    }
  
    func getUserLocalDeviceSettings(completionHandler: @escaping() -> ()){
        
        addLog(text: "get User Local Device Settings")
        
        //  ---------------------------SETTINGS Sound--------------------------//Do not sync it
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsEnableSound) as? Bool{
            isSoundEnabled = isEnabled
        }else{
            UserDefaults.standard.set(isSoundEnabled, forKey: kUserdefaultsEnableSound)
        }
        
        //  ---------------------------SETTINGS Announcement--------------------------//Do not sync it
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsEnableAnnouncement) as? Bool{
            isAnnouncementEnabled = isEnabled
        }else{
            UserDefaults.standard.set(isAnnouncementEnabled, forKey: kUserdefaultsEnableAnnouncement)
        }
        
        //  ---------------------------SETTINGS hide dock in activity--------------------------//Do not sync it
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsHideDockInActivity) as? Bool{
            if isEnabled{
                isHideDockInActivity = true
            }else{
                isHideDockInActivity = false
            }
        }else{
            UserDefaults.standard.set(false, forKey: kUserdefaultsHideDockInActivity)
            isHideDockInActivity = false
        }
        
        var isSettingsBlank = true // agar blank ho to upload bhi kro
        allApiObject.getUserLocalDeviceSettings(completionHandler: { [self]json in
            let kAppPassword = "kAppPassword"
            var settings: NSDictionary?
            if json != nil{
                if let dic = json?.value(forKey: "MacOS") as? NSDictionary {
                    settings = dic
                    addLog(text: "Local Device Settings json is not nil)")
                }
            }else{
                addLog(text: "Local Device Settings json is nil)")
                if let dic = UserDefaults.standard.value(forKey: kUserdefaultsLocalDeviceSettings) as? NSDictionary{
                    settings = dic
                }
            }
            
            addLog(text: "Parse local device settings")
            
            if let settings = settings{
                
                // write settings in userdefaults so that we will not need to create userdefaults for new settings (useful when internet is not working and not getting settings from api) // 15/6/24
//                if settings.value(forKey: kAppPassword) == nil{
//                    settings[kAppPassword] = ""
//                }
               // UserDefaults.standard.set(settings, forKey: kUserdefaultsLocalDeviceSettings)
                
                if let rawSettings = settings as? [String: Any] {// this will remove <null> values so saving in userdefaults will not crash app
                    // Remove NSNull and invalid values
                    let cleanedSettings = rawSettings.compactMapValues { value -> Any? in
                        if value is NSNull {
                            return nil
                        }
                        if JSONSerialization.isValidJSONObject([value]) == false {
                            return nil
                        }
                        return value
                    }

                    // Now safe to save
                    UserDefaults.standard.set(cleanedSettings, forKey: kUserdefaultsLocalDeviceSettings)
                }
                
                print(settings)
                if settings.allKeys.count == 0{
                    isSettingsBlank = true
                }else{
                    isSettingsBlank = false
                }
                let kIsReducedMotionEnabled = "kIsReducedMotion"
                let kIsMeetingDetectionEnabled = "kIsMeetingDetectionEnabled"
                let kIsBlockDistractingSitesDuringMeetingsEnabled = "kIsBlockDistractingSitesDuringMeetingsEnabled"
                let kShowMeetingDetectionAlert = "kShowMeetingDetectionAlert"
                let kIsPasswordRequireInChangeSettings = "kIsPasswordRequireInChangeSettings"
                let kIsPasswordRequireInSkipMorning = "kIsPasswordRequireInSkipMorning"
                let kIsPasswordRequireInSkipEvening = "kIsPasswordRequireInSkipEvening"
                let kIsPasswordRequireInSkipEveningAfterCutOff = "kIsPasswordRequireInSkipEveningAfterCutOff"
                let kIsPasswordRequireInAbortShutoff = "kIsPasswordRequireInAbortShutoff"
                let kIsPasswordRequireInStopPomodoro = "kIsPasswordRequireInStopPomodoro"
                let kIsPasswordRequireInQuitApp = "kIsPasswordRequireInQuitApp"
                let kIsPasswordRequireInUseRelaxFocusMode = "kIsPasswordRequireInUseRelaxFocusMode"
                let kIsPasswordRequireInCircumventingBlocks = "kIsPasswordRequireInCircumventingBlocks"
                let kIsPasswordRequireInPreferencesAfterCutoff = "kIsPasswordRequireInPreferencesAfterCutoff"
                
                let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
                let kIsEasySkipEnabled = "kIsEasySkipEnabled"
                let kIsOutOfOrderHabitsAllowed = "kIsOutOfOrderHabitsAllowed"
                let kIsRequiredIntentionInPostpone = "kIsRequiredIntentionInPostpone"
                
                let kIsShowBreaksInPostponeEnabled = "kIsShowBreaksInPostponeEnabled"
                let kIsShowBreaksInCallEnabled = "kIsShowBreaksInCallEnabled"
                
                
                let kisTabLimiterEnabled = "kisTabLimiterEnabled"
                let kTabLimitCount = "kTabLimitCount"
                
                let kisFullScreenEnabled = "kisFullScreenEnabled"
                let kShouldReloadAfterForceQuitEnabled = "kShouldReloadAfterForceQuitEnabled"
                let kselectedFontIndex = "kselectedFontIndex"
                let kCuddlyModeProgressCount = "kCuddlyModeProgressCount"
                
                
                let kSelectedAppAppearanceIndex = "kSelectedAppAppearanceIndex"
                
                let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
                //                    let kSelectedLanguage = "kSelectedLanguage"
                let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
                let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
                let kBreakDurationMinutes = "kBreakDurationMinutes"
                let kWorkRatioInPomodoro = "kWorkRatioInPomodoro"
                let kBreakRatioInPomodoro = "kBreakRatioInPomodoro"
                let kPomodoroModeEnabled = "kPomodoroModeEnabled"
                let kDoNotBlockUrlsDuringSuperPomodoroBreaks = "kDoNotBlockUrlsDuringSuperPomodoroBreaks"
                let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
                let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
                let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
                let kHardcorePomodoroSkipMicroBreaks = "kHardcorePomodoroSkipMicroBreaks"
                let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"
                
                
                let kArrBlockedUrls = "kArrBlockedUrls"
                let kArrBlockedApps = "kArrBlockedApps"
                
                let kCuddlyModeEnabled = "kCuddlyModeEnabled"
                let kIsGeekModeEnabled = "kIsGeekModeEnabled"
                let kImmediatelyBlockDistractingSites = "kImmediatelyBlockDistractingSites"
                let kImmediatelyBlockDistractingApps = "kImmediatelyBlockDistractingApps"
                
                let kStartPomodoroShortcutChar = "kStartPomodoroShortcutChar"
                let kStartPomodoroShortcutFlags = "kStartPomodoroShortcutFlags"
                
                let kMotivationalMessageEnabled = "kMotivationalMessageEnabled"
                let kAiCheckUrlEnabled = "kAiCheckUrlEnabled"
                
                let kShowToDoPlayerAutomatically = "kShowToDoPlayerAutomatically"
                let kBrainDumpCustomUrlEnabled = "kBrainDumpCustomUrlEnabled"
                let kIsMenuPopoverEnabled = "kIsMenuPopoverEnabled"
                let kIsAdvancedAnalyticsInFocusModeEnabled = "kIsAdvancedAnalyticsInFocusModeEnabled"
                let kIsDataCollectionModeEnabled = "kIsDataCollectionModeEnabled"
                let kDetectNatualBreaksEnabled = "kDetectNatualBreaksEnabled"
                
                let kIsFocusVisualIndicatorEnabled = "kIsFocusVisualIndicatorEnabled"
                let kBrainDumpCustomUrlValue = "kBrainDumpCustomUrlValue"
                let kShowBrainDumpAfterMorningRoutine = "kShowBrainDumpAfterMorningRoutine"
                let kMicroBreaksEnabled = "kMicroBreaksEnabled"
                let kBlockingSchedule = "kBlockingSchedule"
                
                //                    let kAiAllowUrlShowAlertEnabled = "kAiAllowUrlShowAlertEnabled"
                
                addLog(text: "Parse ReducedMotion")
                if let val = settings.value(forKey: kIsReducedMotionEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsReducedMotion)
                }
                
                if let val = settings.value(forKey: kIsMeetingDetectionEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsMeetingDetectionEnabled)
                }
                if let val = settings.value(forKey: kIsBlockDistractingSitesDuringMeetingsEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled)
                }
                
                if let val = settings.value(forKey: kShowMeetingDetectionAlert) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsShowMeetingDetectionAlert)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInChangeSettings) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInChangeSettings)
                }
                if let val = settings.value(forKey: kIsPasswordRequireInSkipMorning) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInSkipMorning)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInSkipEvening) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInSkipEvening)
                }
                addLog(text: "Parse PasswordRequireInSkipEvenin")
                if let val = settings.value(forKey: kIsPasswordRequireInSkipEveningAfterCutOff) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInSkipEveningAfterCutOff)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInAbortShutoff) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInAbortShutoff)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInStopPomodoro) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInStopPomodoro)
                }
                addLog(text: "Local PasswordRequireInStopPomodoro")
                if let val = settings.value(forKey: kIsPasswordRequireInQuitApp) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInQuitApp)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInUseRelaxFocusMode) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInUseRelaxFocusMode)
                }
                
                if let val = settings.value(forKey: kIsPasswordRequireInCircumventingBlocks) as? Bool{
                    isPasswordRequireInCircumventingBlocks = val
                }
                if let val = settings.value(forKey: kIsPasswordRequireInPreferencesAfterCutoff) as? Bool{
                    isPasswordRequireInPreferencesAfterCutoff = val
                }
                addLog(text: "Parse PromptToRememberHabit")
                if let val = settings.value(forKey: kIsPromptToRememberHabit) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPromptToRememberHabit)
                }
                
                if let val = settings.value(forKey: kIsEasySkipEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsEasySkipEnabled)
                }
                
                if let val = settings.value(forKey: kIsOutOfOrderHabitsAllowed) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsOutOfOrderHabitsAllowed)
                }
                addLog(text: "Local sOutOfOrderHabitsAllowed")
                if let val = settings.value(forKey: kIsRequiredIntentionInPostpone) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsRequiredIntentionInPostpone)
                }
                
                if let val = settings.value(forKey: kIsShowBreaksInPostponeEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsShowBreaksInPostponing)
                }
                if let val = settings.value(forKey: kIsShowBreaksInCallEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsShowBreaksInCall)
                }
                
                if let val = settings.value(forKey: kisTabLimiterEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsisTabLimiterEnabled)
                }
                if let val = settings.value(forKey: kTabLimitCount) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsTabLimitCount)
                }
                addLog(text: "Local TabLimitCount")
                if let val = settings.value(forKey: kisFullScreenEnabled) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsisFullScreenEnabled)
                }
                if let val = settings.value(forKey: kShouldReloadAfterForceQuitEnabled) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsShouldReloadAfterForceQuitEnabled)
                }
                if let val = settings.value(forKey: kselectedFontIndex) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsselectedFontIndex)
                }
                addLog(text: "Local CuddlyModeProgressCount")
                if let progress = settings.value(forKey: kCuddlyModeProgressCount) as? Int{
                    UserDefaults.standard.set(progress, forKey: self.kUserdefaultsCuddlyModeProgressCount)
                }
                
                
                if let val = settings.value(forKey: kSelectedAppAppearanceIndex) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsSelectedAppAppearanceIndex)
                }
                
                addLog(text: "Local OfficeModeEnabled")
                if let val = settings.value(forKey: kIsOfficeModeEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsOfficeModeEnabled)
                }
                
                
                if let val = settings.value(forKey: kHideAllWindowInScreenShots) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHideAllWindowInScreenShots)
                }
                addLog(text: "Local PomodoroDurationMinutes")
                if let val = settings.value(forKey: kPomodoroDurationMinutes) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPomodoroDurationMinutes)
                }
                
                if let val = settings.value(forKey: kBreakDurationMinutes) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsBreakDurationMinutes)
                }
                if let val = settings.value(forKey: kWorkRatioInPomodoro) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsWorkRatioInPomodoro)
                }
                if let val = settings.value(forKey: kBreakRatioInPomodoro) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsBreakRatioInPomodoro)
                }
                
                if let val = settings.value(forKey: kPomodoroModeEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsPomodoroModeEnabled)
                }
                addLog(text: "Local DoNotBlockUrlsDuringSuperPomodoroBreaks")
                if let val = settings.value(forKey: kDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
                }
                
                if let val = settings.value(forKey: kHardcorePomodoroEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroEnabled)
                }
                
                if let val = settings.value(forKey: kHardcorePomodoroFocusedName) as? String{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroFocusedName)
                }
                
                if let val = settings.value(forKey: kHardcorePomodoroFocusedCount) as? Int{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroFocusedCount)
                }
                addLog(text: "Local HardcorePomodoroSkipMicroBreaks")
                if let val = settings.value(forKey: kHardcorePomodoroSkipMicroBreaks) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroSkipMicroBreaks)
                }
                
                if let val = settings.value(forKey: kHardcorePomodoroArrDays) as? [String]{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroArrDays)
                }
                
                if let val = settings.value(forKey: kArrBlockedUrls) as? [String]{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsArrBlockedUrls)
                }
                if let val = settings.value(forKey: kArrBlockedApps) as? [String]{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsArrBlockedApps)
                }
                addLog(text: "Local AppPassword")
                if let val = settings.value(forKey: kAppPassword) as? String{
                    if val.isEmpty{
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsAppPassword)
                    }else{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsAppPassword)
                    }
                    
                }else{
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsAppPassword)
                }
                addLog(text: "Local CuddlyModeEnabled")
                if let val = settings.value(forKey: kCuddlyModeEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsCuddlyModeEnabled)
                }
                if let val = settings.value(forKey: kIsGeekModeEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsGeekModeEnabled)
                }
                if let val = settings.value(forKey: kImmediatelyBlockDistractingSites) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsImmediatelyBlockDistractingSites)
                }
                
                if let val = settings.value(forKey: kImmediatelyBlockDistractingApps) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsImmediatelyBlockDistractingApps)
                }
                
                if let val = settings.value(forKey: kStartPomodoroShortcutChar) as? String{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsStartPomodoroShortcutChar)
                }
                if let val = settings.value(forKey: kStartPomodoroShortcutFlags) as? [Int]{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsStartPomodoroShortcutFlags)
                }
                addLog(text: "Local MotivationalMessageEnabled")
                if let val = settings.value(forKey: kMotivationalMessageEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsMotivationalMessageEnabled)
                }
                if let val = settings.value(forKey: kAiCheckUrlEnabled) as? Bool{
                    UserDefaults.standard.set(val, forKey: self.kUserdefaultsAiCheckUrlEnabled)
                }
                
                if let val = settings.value(forKey: kBrainDumpCustomUrlEnabled) as? Bool{
                    brainDumpCustomUrlEnabled = val
                }
                
                
                if let val = settings.value(forKey: kIsMenuPopoverEnabled) as? Bool{
                    isMenuPopoverEnabled = val
                }else{
                    if isSettingsBlank{
                        isMenuPopoverEnabled = false
                    }else{
                        isMenuPopoverEnabled = true// keep enable popover for old users
                    }
                }
                
                if let val = settings.value(forKey: kIsAdvancedAnalyticsInFocusModeEnabled) as? Bool{
                    isAdvancedAnalyticsInFocusModeEnabled = val
                }
                
                if let val = settings.value(forKey: kIsDataCollectionModeEnabled) as? Bool{
                    isDataCollectionModeEnabled = val
                }
                
                if let val = settings.value(forKey: kDetectNatualBreaksEnabled) as? Bool{
                    isDetectNatualBreaksEnabled = val
                }
                
                if let val = settings.value(forKey: kIsFocusVisualIndicatorEnabled) as? Bool{
                    isFocusVisualIndicatorEnabled = val
                }
                
                if let val = settings.value(forKey: kBrainDumpCustomUrlValue) as? String{
                    brainDumpCustomUrlValue = val
                }
                
                if let val = settings.value(forKey: kShowToDoPlayerAutomatically) as? Bool{
                    showToDoPlayerAutomaticallyEnabled = val
                }
                
                if let val = settings.value(forKey: kShowBrainDumpAfterMorningRoutine) as? Bool{
                    showBrainDumpAfterMorningRoutineEnabled = val
                }
                
                
                if let val = settings.value(forKey: kMicroBreaksEnabled) as? Bool{
                    isMicroBreaksEnabled = val
                }else{
                    if let breaksEnabled = UserDefaults.standard.object(forKey: kUserdefaultsBreaksEnabledFromOnboarding) as? Bool{
                        isMicroBreaksEnabled = breaksEnabled
                    }
                }
                
                if let val = settings.value(forKey: kBlockingSchedule) as? Int{// read from settings
                    blockingSchedule = BLOCKINGSCHEDULE(rawValue: val) ?? ._WHEN_START_FOCUS_SESSION_
                }else{
                    if let val = UserDefaults.standard.object(forKey: kUserdefaultsBlockingScheduleFromOnboarding) as? Int{// read from onboarding
                        blockingSchedule = BLOCKINGSCHEDULE(rawValue: val) ?? ._WHEN_START_FOCUS_SESSION_
                    }else{
                        blockingSchedule = ._WHEN_START_FOCUS_SESSION_// default
                    }
                }
            }
            
            addLog(text: "Parse OfficeModeEnable")
            //  ---------------------------OFFICE MODE--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsOfficeModeEnabled) as? Bool{
                if isEnabled{
                    isOfficeModeEnabled = true
                    DispatchQueue.main.async {
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
                        NSApplication.shared.applicationIconImage = NSImage(named: NSImage.Name("Bear-Office-icon"))
                    }
                }else{
                    isOfficeModeEnabled = false
                    DispatchQueue.main.async {
                        NSApplication.shared.applicationIconImage = nil
                    }
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsOfficeModeEnabled)
                isOfficeModeEnabled = true
            }
            
            //  ---------------------------SETTINGS reduced motion--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsReducedMotion) as? Bool{
                if isEnabled{
                    kIsReducedMotion = true
                }else{
                    kIsReducedMotion = false
                }
            }else{
                UserDefaults.standard.set(false, forKey: kUserdefaultsReducedMotion)
                kIsReducedMotion = false
            }
            
            //  ---------------------------SETTINGS meetings detection--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsMeetingDetectionEnabled) as? Bool{
                if isEnabled{
                    isMeetingDetectionEnabled = true
                }else{
                    isMeetingDetectionEnabled = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsMeetingDetectionEnabled)
                isMeetingDetectionEnabled = true
            }
            
            addLog(text: "Parse showMeetingDetectionAlert")
            
            //  ---------------------------SETTINGS Show Meeting Detection Alert--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsShowMeetingDetectionAlert) as? Bool{
                if isEnabled{
                    showMeetingDetectionAlert = true
                }else{
                    showMeetingDetectionAlert = false
                }
            }else{
                UserDefaults.standard.set(false, forKey: kUserdefaultsShowMeetingDetectionAlert)
                showMeetingDetectionAlert = false
            }
            
            
            //  ---------------------------SETTINGS Block DistractingSites During Meetings--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled) as? Bool{
                if isEnabled{
                    isBlockDistractingSitesDuringMeetingsEnabled = true
                }else{
                    isBlockDistractingSitesDuringMeetingsEnabled = false
                }
            }else{
                UserDefaults.standard.set(isBlockDistractingSitesDuringMeetingsEnabled, forKey: kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled)
            }
            addLog(text: "Parse PasswordRequireInChangeSettings")
            //  ---------------------------SETTINGS Password Require--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInChangeSettings) as? Bool{
                if isEnabled{
                    isPasswordRequireInChangeSettings = true
                }else{
                    isPasswordRequireInChangeSettings = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInChangeSettings, forKey: kUserdefaultsPasswordRequireInChangeSettings)
            }
            
            addLog(text: "Parse PasswordRequireInSkipMorning")
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInSkipMorning) as? Bool{
                if isEnabled{
                    isPasswordRequireInSkipMorning = true
                }else{
                    isPasswordRequireInSkipMorning = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInSkipMorning, forKey: kUserdefaultsPasswordRequireInSkipMorning)
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInSkipEvening) as? Bool{
                if isEnabled{
                    isPasswordRequireInSkipEvening = true
                }else{
                    isPasswordRequireInSkipEvening = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInSkipEvening, forKey: kUserdefaultsPasswordRequireInSkipEvening)
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInSkipEveningAfterCutOff) as? Bool{
                if isEnabled{
                    isPasswordRequireInSkipEveningAfterCutOff = true
                }else{
                    isPasswordRequireInSkipEveningAfterCutOff = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInSkipEveningAfterCutOff, forKey: kUserdefaultsPasswordRequireInSkipEveningAfterCutOff)
            }
            
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInAbortShutoff) as? Bool{
                if isEnabled{
                    isPasswordRequireInAbortShutoff = true
                }else{
                    isPasswordRequireInAbortShutoff = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInAbortShutoff, forKey: kUserdefaultsPasswordRequireInAbortShutoff)
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInStopPomodoro) as? Bool{
                if isEnabled{
                    isPasswordRequireInStopPomodoro = true
                }else{
                    isPasswordRequireInStopPomodoro = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInStopPomodoro, forKey: kUserdefaultsPasswordRequireInStopPomodoro)
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInQuitApp) as? Bool{
                if isEnabled{
                    isPasswordRequireInQuitApp = true
                }else{
                    isPasswordRequireInQuitApp = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInQuitApp, forKey: kUserdefaultsPasswordRequireInQuitApp)
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInUseRelaxFocusMode) as? Bool{
                if isEnabled{
                    isPasswordRequireInUseRelaxFocusMode = true
                }else{
                    isPasswordRequireInUseRelaxFocusMode = false
                }
            }else{
                UserDefaults.standard.set(isPasswordRequireInUseRelaxFocusMode, forKey: kUserdefaultsPasswordRequireInUseRelaxFocusMode)
            }
            
            if let password = UserDefaults.standard.object(forKey: kUserdefaultsPasswordSetInOnboarding) as? String{
                if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) == nil{
                    UserDefaults.standard.set(password, forKey: self.kUserdefaultsAppPassword)
                }
                UserDefaults.standard.removeObject(forKey: kUserdefaultsPasswordSetInOnboarding)
            }
            
            //  ---------------------------SETTINGS Prompt To Remember next Habit--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPromptToRememberHabit) as? Bool{
                if isEnabled{
                    isPromptToRememberHabit = true
                }else{
                    isPromptToRememberHabit = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPromptToRememberHabit)
                isPromptToRememberHabit = true
            }
            
            
            //  ---------------------------SETTINGS Skip Habit--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsEasySkipEnabled) as? Bool{
                if isEnabled{
                    isEasySkipEnabled = true
                }else{
                    isEasySkipEnabled = false
                }
            }else{
                UserDefaults.standard.set(isEasySkipEnabled, forKey: kUserdefaultsEasySkipEnabled)
            }
            
            //  ---------------------------SETTINGS Allow Out Of Order Habits--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsOutOfOrderHabitsAllowed) as? Bool{
                if isEnabled{
                    isOutOfOrderHabitsAllowed = true
                }else{
                    isOutOfOrderHabitsAllowed = false
                }
            }else{
                UserDefaults.standard.set(isOutOfOrderHabitsAllowed, forKey: kUserdefaultsOutOfOrderHabitsAllowed)
            }
            
            //  ---------------------------SETTINGS Required Intention In Postpone Habits--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsRequiredIntentionInPostpone) as? Bool{
                isRequiredIntentionInPostpone = isEnabled
            }else{
                UserDefaults.standard.set(isRequiredIntentionInPostpone, forKey: kUserdefaultsRequiredIntentionInPostpone)
            }
            
            //  ---------------------------SETTINGS show break while postponing Habit--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsShowBreaksInPostponing) as? Bool{
                IsShowBreaksInPostponeEnabled = isEnabled
            }else{
                UserDefaults.standard.set(IsShowBreaksInPostponeEnabled, forKey: kUserdefaultsShowBreaksInPostponing)
            }
            
            //  ---------------------------SETTINGS show break while in call--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsShowBreaksInCall) as? Bool{
                IsShowBreaksInCallEnabled = isEnabled
            }else{
                UserDefaults.standard.set(IsShowBreaksInCallEnabled, forKey: kUserdefaultsShowBreaksInCall)
            }
            
            
            addLog(text: "Parse ShowBreaksInCall")
            //  ---------------------------SETTINGS Tab Limit--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsisTabLimiterEnabled) as? Bool{
                isTabLimiterEnabled = isEnabled
            }else{
                UserDefaults.standard.set(isTabLimiterEnabled, forKey: kUserdefaultsisTabLimiterEnabled)
            }
            
            //  ---------------------------SETTINGS Full Screen--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsisFullScreenEnabled) as? Bool{
                isFullScreenEnabled = isEnabled
            }else{
                isFullScreenEnabled = false
                UserDefaults.standard.set(isFullScreenEnabled, forKey: kUserdefaultsisFullScreenEnabled)
            }
            
            //  ---------------------------SETTINGS Reload After Force Quit--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsShouldReloadAfterForceQuitEnabled) as? Bool{
                shouldReloadAfterForceQuitEnabled = isEnabled
            }else{
                UserDefaults.standard.set(shouldReloadAfterForceQuitEnabled, forKey: kUserdefaultsShouldReloadAfterForceQuitEnabled)
            }
            
            //  ---------------------------SETTINGS Selected Font--------------------------
            if let font = UserDefaults.standard.object(forKey: kUserdefaultsselectedFontIndex) as? Int{
                selectedFontIndex = font
            }else{
                UserDefaults.standard.set(selectedFontIndex, forKey: kUserdefaultsselectedFontIndex)
            }
            addLog(text: "Parse selectedFontIndex")
            //  ---------------------------SETTINGS Progress Count--------------------------
            if let progressCount = UserDefaults.standard.object(forKey: kUserdefaultsCuddlyModeProgressCount) as? Int{
                cuddlyModeProgressCount = progressCount
            }else{
                UserDefaults.standard.set(cuddlyModeProgressCount, forKey: kUserdefaultsCuddlyModeProgressCount)
            }
            
            
            
            //  ---------------------------SETTINGS App Appearance --------------------------
            if let index = UserDefaults.standard.object(forKey: kUserdefaultsSelectedAppAppearanceIndex) as? Int{
                selectedAppAppearanceIndex = index
            }else{
                UserDefaults.standard.set(selectedAppAppearanceIndex, forKey: kUserdefaultsSelectedAppAppearanceIndex)
            }
            
            
            if let count = UserDefaults.standard.object(forKey: kUserdefaultsTabLimitCount) as? Int{
                maxTabLimitCount = count
            }else{
                UserDefaults.standard.set(5, forKey: kUserdefaultsTabLimitCount)
                maxTabLimitCount = 5
            }
            
            
            //  ---------------------------SETTINGS Focus bear mode--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsCuddlyModeEnabled) as? Bool{
                isCuddlyModeEnabled = isEnabled
            }else{
                UserDefaults.standard.set(isCuddlyModeEnabled, forKey: kUserdefaultsCuddlyModeEnabled)
            }
            
            
            //  ---------------------------SETTINGS App Greek mode--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsGeekModeEnabled) as? Bool{
                isGeekModeEnabled = isEnabled
            }else{
                UserDefaults.standard.set(isGeekModeEnabled, forKey: kUserdefaultsGeekModeEnabled)
            }
            addLog(text: "Parse GeekMode")
            
            //  ---------------------------SETTINGS Immediately Block Distracting Sites--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsImmediatelyBlockDistractingSites) as? Bool{
                immediatelyBlockDistractingSites =  isEnabled
            }else{
                UserDefaults.standard.set(immediatelyBlockDistractingSites, forKey: kUserdefaultsImmediatelyBlockDistractingSites)
            }
            
            //  ---------------------------SETTINGS Immediately Block Distracting Apps--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsImmediatelyBlockDistractingApps) as? Bool{
                immediatelyBlockDistractingApps =  isEnabled
            }else{
                UserDefaults.standard.set(immediatelyBlockDistractingApps, forKey: kUserdefaultsImmediatelyBlockDistractingApps)
            }
            addLog(text: "Parse PomodoroShortcut")
            //  ---------------------------SETTINGS Pomodoro Shortcut Char--------------------------
            if let val = UserDefaults.standard.object(forKey: kUserdefaultsStartPomodoroShortcutChar) as? String{
                startPomodoroShortcutChar =  val
            }else{
                UserDefaults.standard.set(startPomodoroShortcutChar, forKey: kUserdefaultsStartPomodoroShortcutChar)
            }
            
            //  ---------------------------SETTINGS Pomodoro Shortcut flags--------------------------
            if let val = UserDefaults.standard.object(forKey: kUserdefaultsStartPomodoroShortcutFlags) as? [Int]{
                startPomodoroShortcutFlags =  val
            }else{
                UserDefaults.standard.set(startPomodoroShortcutFlags, forKey: kUserdefaultsStartPomodoroShortcutFlags)
            }
            
            
            addLog(text: "Parse Motivational Message")
            //  ---------------------------SETTINGS Motivational Message--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsMotivationalMessageEnabled) as? Bool{
                if isEnabled{
                    isMotivationalMessageEnabled = true
                }else{
                    isMotivationalMessageEnabled = false
                }
            }else{
                UserDefaults.standard.set(isMotivationalMessageEnabled, forKey: kUserdefaultsMotivationalMessageEnabled)
            }
            
            //  ---------------------------SETTINGS Ai Check Url Enabled--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsAiCheckUrlEnabled) as? Bool{
                isAiCheckUrlEnabled = isEnabled
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsAiCheckUrlEnabled)
                isAiCheckUrlEnabled = true
            }
            //  ---------------------------SETTINGS Ai Allow Url Show Alert--------------------------
            //            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsAiAllowUrlShowAlertEnabled) as? Bool{
            //                if isEnabled{
            //                    isAiAllowUrlShowAlertEnabled = true
            //                }else{
            //                    isAiAllowUrlShowAlertEnabled = false
            //                }
            //            }else{
            //                UserDefaults.standard.set(true, forKey: kUserdefaultsAiAllowUrlShowAlertEnabled)
            //                isAiAllowUrlShowAlertEnabled = true
            //            }
            
            
            // ---------------------------SETTINGS Hide All Window In Screenshots--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) == nil{
                UserDefaults.standard.set(false, forKey: kUserdefaultsHideAllWindowInScreenShots)
            }
            
            //  ---------------------------SETTINGS Pomodoro duration--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) == nil{
                UserDefaults.standard.set(25, forKey: kUserdefaultsPomodoroDurationMinutes)
            }
            
            //  ---------------------------SETTINGS Break duration--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) == nil{
                UserDefaults.standard.set(5, forKey: kUserdefaultsBreakDurationMinutes)
            }
            
            //  ---------------------------SETTINGS work ratio--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsWorkRatioInPomodoro) == nil{
                UserDefaults.standard.set(5, forKey: kUserdefaultsWorkRatioInPomodoro)
            }
            
            //  ---------------------------SETTINGS Break ratio--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsBreakRatioInPomodoro) == nil{
                UserDefaults.standard.set(1, forKey: kUserdefaultsBreakRatioInPomodoro)
            }
            
            //  ---------------------------POMODORO MODE--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroModeEnabled)
            }
            
            //  ---------------------------Do Not Block Urls During Super Pomodoro Breaks--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) == nil{
                UserDefaults.standard.set(doNotBlockUrlsDuringSuperPomodoroBreaksDefaultValue, forKey: kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            }
            
            //no need to read settings from userdefaults . read from settings json direct
            addLog(text: "Parse HardcorePomodoroEnable")
            //  ---------------------------AUTO HARDCORE POMODORO MODE settings--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) == nil{
                UserDefaults.standard.set(false, forKey: kUserdefaultsHardcorePomodoroEnabled)
            }
            addLog(text: "Parse BlockedUrls")
            if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrBlockedUrls) as? [String]{
                arrBlockedUrls = arr
            }else{
                UserDefaults.standard.set(arrBlockedUrls, forKey: kUserdefaultsArrBlockedUrls)
            }
            
            if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrBlockedApps) as? [String]{
                arrBlockedApps = arr
            }else{
                UserDefaults.standard.set(arrBlockedApps, forKey: kUserdefaultsArrBlockedApps)
            }
            
            if isSettingsBlank{
                //                if let blockedUrls = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
                //                    arrBlockedUrls.removeAll()
                //                    for i in 0..<blockedUrls.count{
                //                        if let isSelected = blockedUrls[i]["isSelected"] as? Bool {
                //                            if isSelected{
                //                                arrBlockedUrls.append(blockedUrls[i]["url"] as? String ?? "")
                //                            }
                //                        }
                //                    }
                //                    //UserDefaults.standard.removeObject(forKey: kUserdefaultsBlockedUrlsFromOnboarding)//will not remove from this userdefaults, after logout we will bloock urls from this
                //                }
                
                //                UserDefaults.standard.set(arrBlockedUrls, forKey: kUserdefaultsArrBlockedUrls)//
                
                //                isSettingsChanged = true
                //                self.perform(#selector(putUserLocalDeviceSettings))
            }
            addLog(text: "Parse settings completed")
            completionHandler()
            return
        }
        )
        
    }
    
    func getLocalJsonToUpload()->[String : Any]{
        let kIsReducedMotionEnabled = "kIsReducedMotion"
        let kIsMeetingDetectionEnabled = "kIsMeetingDetectionEnabled"
        let kIsBlockDistractingSitesDuringMeetingsEnabled = "kIsBlockDistractingSitesDuringMeetingsEnabled"
        let kShowMeetingDetectionAlert = "kShowMeetingDetectionAlert"
        let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
        let kIsEasySkipEnabled = "kIsEasySkipEnabled"
        let kIsOutOfOrderHabitsAllowed = "kIsOutOfOrderHabitsAllowed"
        let kIsRequiredIntentionInPostpone = "kIsRequiredIntentionInPostpone"
        let kIsShowBreaksInPostponeEnabled = "kIsShowBreaksInPostponeEnabled"
        let kIsShowBreaksInCallEnabled = "kIsShowBreaksInCallEnabled"
        let kisTabLimiterEnabled = "kisTabLimiterEnabled"
        let kTabLimitCount = "kTabLimitCount"
        let kisFullScreenEnabled = "kisFullScreenEnabled"
        let kShouldReloadAfterForceQuitEnabled = "kShouldReloadAfterForceQuitEnabled"
        let kselectedFontIndex = "kselectedFontIndex"
        let kCuddlyModeProgressCount = "kCuddlyModeProgressCount"
        let kSelectedAppAppearanceIndex = "kSelectedAppAppearanceIndex"
        let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
        //        let kSelectedLanguage = "kSelectedLanguage"
        let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
        let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
        let kBreakDurationMinutes = "kBreakDurationMinutes"
        let kWorkRatioInPomodoro = "kWorkRatioInPomodoro"
        let kBreakRatioInPomodoro = "kBreakRatioInPomodoro"
        let kPomodoroModeEnabled = "kPomodoroModeEnabled"
        let kDoNotBlockUrlsDuringSuperPomodoroBreaks = "kDoNotBlockUrlsDuringSuperPomodoroBreaks"
        let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
        let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
        let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
        let kHardcorePomodoroSkipMicroBreaks = "kHardcorePomodoroSkipMicroBreaks"
        let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"
        
        
        let kIsPasswordRequireInChangeSettings = "kIsPasswordRequireInChangeSettings"
        let kIsPasswordRequireInSkipMorning = "kIsPasswordRequireInSkipMorning"
        let kIsPasswordRequireInSkipEvening = "kIsPasswordRequireInSkipEvening"
        let kIsPasswordRequireInSkipEveningAfterCutOff = "kIsPasswordRequireInSkipEveningAfterCutOff"
        let kIsPasswordRequireInAbortShutoff = "kIsPasswordRequireInAbortShutoff"
        let kIsPasswordRequireInStopPomodoro = "kIsPasswordRequireInStopPomodoro"
        let kIsPasswordRequireInQuitApp = "kIsPasswordRequireInQuitApp"
        let kIsPasswordRequireInUseRelaxFocusMode = "kIsPasswordRequireInUseRelaxFocusMode"
        let kIsPasswordRequireInCircumventingBlocks = "kIsPasswordRequireInCircumventingBlocks"
        let kIsPasswordRequireInPreferencesAfterCutoff = "kIsPasswordRequireInPreferencesAfterCutoff"
        
        let kAppPassword = "kAppPassword"
        let kArrBlockedUrls = "kArrBlockedUrls"
        let kArrBlockedApps = "kArrBlockedApps"
        let kCuddlyModeEnabled = "kCuddlyModeEnabled"
        let kIsGeekModeEnabled = "kIsGeekModeEnabled"
        let kImmediatelyBlockDistractingSites = "kImmediatelyBlockDistractingSites"
        let kImmediatelyBlockDistractingApps = "kImmediatelyBlockDistractingApps"
        let kStartPomodoroShortcutChar = "kStartPomodoroShortcutChar"
        let kStartPomodoroShortcutFlags = "kStartPomodoroShortcutFlags"
        
        let kMotivationalMessageEnabled = "kMotivationalMessageEnabled"
        let kAiCheckUrlEnabled = "kAiCheckUrlEnabled"
        let kShowToDoPlayerAutomatically = "kShowToDoPlayerAutomatically"
        let kBrainDumpCustomUrlEnabled = "kBrainDumpCustomUrlEnabled"
        let kIsMenuPopoverEnabled = "kIsMenuPopoverEnabled"
        let kIsAdvancedAnalyticsInFocusModeEnabled = "kIsAdvancedAnalyticsInFocusModeEnabled"
        let kIsDataCollectionModeEnabled = "kIsDataCollectionModeEnabled"
        let kDetectNatualBreaksEnabled = "kDetectNatualBreaksEnabled"
        let kIsFocusVisualIndicatorEnabled = "kIsFocusVisualIndicatorEnabled"
        let kBrainDumpCustomUrlValue = "kBrainDumpCustomUrlValue"
        let kShowBrainDumpAfterMorningRoutine = "kShowBrainDumpAfterMorningRoutine"
        let kMicroBreaksEnabled = "kMicroBreaksEnabled"
        let kBlockingSchedule = "kBlockingSchedule"
        
        //        let kAiAllowUrlShowAlertEnabled = "kAiAllowUrlShowAlertEnabled"
        let isEditBlockedUrlsOnce = UserDefaults.standard.object(forKey: kUserdefaultsEditBlockedUrlsOnce) as? Bool ?? false
        
        var json: [String: Any] = [
            kIsReducedMotionEnabled:kIsReducedMotion,//userId.removingPercentEncoding ?? "",
            kIsMeetingDetectionEnabled:isMeetingDetectionEnabled,
            kIsBlockDistractingSitesDuringMeetingsEnabled:isBlockDistractingSitesDuringMeetingsEnabled,
            kShowMeetingDetectionAlert:showMeetingDetectionAlert,
            kIsPromptToRememberHabit:isPromptToRememberHabit,
            kIsEasySkipEnabled:isEasySkipEnabled,
            kIsOutOfOrderHabitsAllowed:isOutOfOrderHabitsAllowed,
            kIsRequiredIntentionInPostpone:isRequiredIntentionInPostpone,
            kIsShowBreaksInPostponeEnabled:IsShowBreaksInPostponeEnabled,
            kIsShowBreaksInCallEnabled:IsShowBreaksInCallEnabled,
            kisTabLimiterEnabled:isTabLimiterEnabled,
            kTabLimitCount:maxTabLimitCount,
            kisFullScreenEnabled:isFullScreenEnabled,
            kShouldReloadAfterForceQuitEnabled:shouldReloadAfterForceQuitEnabled,
            kselectedFontIndex:selectedFontIndex,
            kCuddlyModeProgressCount:cuddlyModeProgressCount,
            kSelectedAppAppearanceIndex:selectedAppAppearanceIndex,
            kIsOfficeModeEnabled:isOfficeModeEnabled,
            kHideAllWindowInScreenShots:UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool ?? false,
            kPomodoroDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int ?? 0,
            kBreakDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) as? Int ?? 0,
            kWorkRatioInPomodoro:UserDefaults.standard.object(forKey: kUserdefaultsWorkRatioInPomodoro) as? Int ?? 0,
            kBreakRatioInPomodoro:UserDefaults.standard.object(forKey: kUserdefaultsBreakRatioInPomodoro) as? Int ?? 0,
            kPomodoroModeEnabled:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool ?? false,
            kDoNotBlockUrlsDuringSuperPomodoroBreaks:UserDefaults.standard.object(forKey: kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool ?? false,
            kHardcorePomodoroEnabled:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) as? Bool ?? false,
            kHardcorePomodoroFocusedName:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedName) as? String ?? "",
            kHardcorePomodoroFocusedCount:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedCount) as? Int ?? 0,
            kHardcorePomodoroSkipMicroBreaks:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroSkipMicroBreaks) as? Bool ?? false,//
            kHardcorePomodoroArrDays:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroArrDays) as? [String] ?? [],
            kArrBlockedUrls:arrBlockedUrls,
            kArrBlockedApps:arrBlockedApps,
            kCuddlyModeEnabled:isCuddlyModeEnabled,
            kIsGeekModeEnabled:isGeekModeEnabled,
            kImmediatelyBlockDistractingSites:immediatelyBlockDistractingSites,
            kImmediatelyBlockDistractingApps:immediatelyBlockDistractingApps,
            kStartPomodoroShortcutChar:startPomodoroShortcutChar,
            kStartPomodoroShortcutFlags:startPomodoroShortcutFlags,
            kIsPasswordRequireInChangeSettings:isPasswordRequireInChangeSettings,
            kIsPasswordRequireInSkipMorning:isPasswordRequireInSkipMorning,
            kIsPasswordRequireInSkipEvening:isPasswordRequireInSkipEvening,
            kIsPasswordRequireInSkipEveningAfterCutOff:isPasswordRequireInSkipEveningAfterCutOff,
            kIsPasswordRequireInAbortShutoff:isPasswordRequireInAbortShutoff,
            kIsPasswordRequireInStopPomodoro:isPasswordRequireInStopPomodoro,
            kIsPasswordRequireInQuitApp:isPasswordRequireInQuitApp,
            kIsPasswordRequireInUseRelaxFocusMode:isPasswordRequireInUseRelaxFocusMode,
            kIsPasswordRequireInCircumventingBlocks:isPasswordRequireInCircumventingBlocks,
            kIsPasswordRequireInPreferencesAfterCutoff:isPasswordRequireInPreferencesAfterCutoff,
            kMotivationalMessageEnabled:isMotivationalMessageEnabled,
            kAiCheckUrlEnabled:isAiCheckUrlEnabled,
            kShowToDoPlayerAutomatically:showToDoPlayerAutomaticallyEnabled,
            kBrainDumpCustomUrlEnabled:brainDumpCustomUrlEnabled,
            kIsMenuPopoverEnabled: isMenuPopoverEnabled,
            kIsAdvancedAnalyticsInFocusModeEnabled:isAdvancedAnalyticsInFocusModeEnabled,
            kIsDataCollectionModeEnabled:isDataCollectionModeEnabled,
            kDetectNatualBreaksEnabled:isDetectNatualBreaksEnabled,
            kIsFocusVisualIndicatorEnabled:isFocusVisualIndicatorEnabled,
            kBrainDumpCustomUrlValue:brainDumpCustomUrlValue,
            kShowBrainDumpAfterMorningRoutine:showBrainDumpAfterMorningRoutineEnabled,
            kMicroBreaksEnabled:isMicroBreaksEnabled,
            kBlockingSchedule:blockingSchedule.rawValue,
            "has_edited_blocked_urls":isEditBlockedUrlsOnce
            //            kAiAllowUrlShowAlertEnabled:isAiAllowUrlShowAlertEnabled,
        ]
        
        if let password = UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) as? String{
            if !password.isEmpty{
                json[kAppPassword] = password
            }
        }
        return json
    }
    
    @objc func putUserLocalDeviceSettings(){
        addLog(text: "put User Local Device Settings")
        if isSettingsChanged{
            isSettingsChanged = false
        }else{
            return;
        }
        UserDefaults.standard.set(kIsReducedMotion, forKey: kUserdefaultsReducedMotion)
        UserDefaults.standard.set(isMeetingDetectionEnabled, forKey: kUserdefaultsMeetingDetectionEnabled)
        UserDefaults.standard.set(isBlockDistractingSitesDuringMeetingsEnabled, forKey: kUserdefaultsBlockDistractingSitesDuringMeetingsEnabled)
        UserDefaults.standard.set(showMeetingDetectionAlert, forKey: kUserdefaultsShowMeetingDetectionAlert)
        UserDefaults.standard.set(isHideDockInActivity, forKey: kUserdefaultsHideDockInActivity)
        UserDefaults.standard.set(isPromptToRememberHabit, forKey: kUserdefaultsPromptToRememberHabit)
        UserDefaults.standard.set(isEasySkipEnabled, forKey: kUserdefaultsEasySkipEnabled)
        UserDefaults.standard.set(isOutOfOrderHabitsAllowed, forKey: kUserdefaultsOutOfOrderHabitsAllowed)
        UserDefaults.standard.set(isRequiredIntentionInPostpone, forKey: kUserdefaultsRequiredIntentionInPostpone)
        UserDefaults.standard.set(IsShowBreaksInPostponeEnabled, forKey: kUserdefaultsShowBreaksInPostponing)
        UserDefaults.standard.set(IsShowBreaksInCallEnabled, forKey: kUserdefaultsShowBreaksInCall)
        UserDefaults.standard.set(isTabLimiterEnabled, forKey: kUserdefaultsisTabLimiterEnabled)
        UserDefaults.standard.set(maxTabLimitCount, forKey: kUserdefaultsTabLimitCount)
        UserDefaults.standard.set(isFullScreenEnabled, forKey: kUserdefaultsisFullScreenEnabled)
        UserDefaults.standard.set(shouldReloadAfterForceQuitEnabled, forKey: kUserdefaultsShouldReloadAfterForceQuitEnabled)
        UserDefaults.standard.set(selectedFontIndex, forKey: kUserdefaultsselectedFontIndex)
        UserDefaults.standard.set(cuddlyModeProgressCount, forKey: kUserdefaultsCuddlyModeProgressCount)
        UserDefaults.standard.set(selectedAppAppearanceIndex, forKey: kUserdefaultsSelectedAppAppearanceIndex)
        UserDefaults.standard.set(isOfficeModeEnabled, forKey: kUserdefaultsOfficeModeEnabled)
        UserDefaults.standard.set(isCuddlyModeEnabled, forKey: kUserdefaultsCuddlyModeEnabled)
        UserDefaults.standard.set(isGeekModeEnabled, forKey: kUserdefaultsGeekModeEnabled)
        UserDefaults.standard.set(immediatelyBlockDistractingSites, forKey: kUserdefaultsImmediatelyBlockDistractingSites)
        UserDefaults.standard.set(immediatelyBlockDistractingApps, forKey: kUserdefaultsImmediatelyBlockDistractingApps)
        UserDefaults.standard.set(startPomodoroShortcutChar, forKey: kUserdefaultsStartPomodoroShortcutChar)
        UserDefaults.standard.set(startPomodoroShortcutFlags, forKey: kUserdefaultsStartPomodoroShortcutFlags)
        
        UserDefaults.standard.set(isSoundEnabled, forKey: kUserdefaultsEnableSound)//do not sync it
        UserDefaults.standard.set(isAnnouncementEnabled, forKey: kUserdefaultsEnableAnnouncement)//do not sync it
        
        UserDefaults.standard.set(isPasswordRequireInChangeSettings, forKey: kUserdefaultsPasswordRequireInChangeSettings)
        UserDefaults.standard.set(isPasswordRequireInSkipMorning, forKey: kUserdefaultsPasswordRequireInSkipMorning)
        UserDefaults.standard.set(isPasswordRequireInSkipEvening, forKey: kUserdefaultsPasswordRequireInSkipEvening)
        UserDefaults.standard.set(isPasswordRequireInSkipEveningAfterCutOff, forKey: kUserdefaultsPasswordRequireInSkipEveningAfterCutOff)
        UserDefaults.standard.set(isPasswordRequireInAbortShutoff, forKey: kUserdefaultsPasswordRequireInAbortShutoff)
        UserDefaults.standard.set(isPasswordRequireInStopPomodoro, forKey: kUserdefaultsPasswordRequireInStopPomodoro)
        UserDefaults.standard.set(isPasswordRequireInQuitApp, forKey: kUserdefaultsPasswordRequireInQuitApp)
        UserDefaults.standard.set(isPasswordRequireInUseRelaxFocusMode, forKey: kUserdefaultsPasswordRequireInUseRelaxFocusMode)
        
        UserDefaults.standard.set(isMotivationalMessageEnabled, forKey: kUserdefaultsMotivationalMessageEnabled)
        UserDefaults.standard.set(isAiCheckUrlEnabled, forKey: kUserdefaultsAiCheckUrlEnabled)
        //        UserDefaults.standard.set(isAiAllowUrlShowAlertEnabled, forKey: kUserdefaultsAiAllowUrlShowAlertEnabled)
        
        let json = getLocalJsonToUpload()
        
        let dic: [String: [String:Any]] = [
            "MacOS": json
        ]
        allApiObject.putUserLocalDeviceSettings(settings: dic, completionHandler: {dic  in
            DispatchQueue.main.async {
                
                
                if dic == nil{
                    
                }else{
                    
                    do {
                        _ =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                        
                    } catch let myJSONError {
                        print(myJSONError)
                    }
                    
                }
            }
        })
        
    }
    
    
    
    
    
    
    
    
    
    var appEnableDate:Date?
    var appDisableDate:Date?
    var totalAppEnableTime = 0
    var totalAppDisableTime = 0
    func disableAppWriteSettings(){
        appDisableDate = Date()
        let diffSeconds = Calendar.current.dateComponents([.second], from: appEnableDate ?? Date(), to: appDisableDate!).second ?? 0
        totalAppEnableTime += diffSeconds
        appEnableDate = nil
        writeLocalSettings()
    }
    func enableAppWriteSettings(){
        appEnableDate = Date()
        let diffSeconds = Calendar.current.dateComponents([.second], from: appDisableDate ?? Date(), to: appEnableDate!).second ?? 0
        totalAppDisableTime += diffSeconds
        appDisableDate = nil
        writeLocalSettings()
    }
    
    
    func writeLocalSettings(){
        var dicContent = ["totalAppEnableTime":totalAppEnableTime, "totalAppDisableTime":totalAppDisableTime] as [String : Any]
        let isAppEnable = UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) as? Bool ?? true
        if isAppEnable{
            if appEnableDate != nil{
                if !Calendar.current.isDateInToday(appEnableDate!){
                    appEnableDate = Date()
                }
            }else{
                appEnableDate = Date()
            }
            dicContent["appEnableDate"] = appEnableDate!
        }else{
            if appDisableDate != nil{
                if !Calendar.current.isDateInToday(appDisableDate!){
                    appDisableDate = Date()
                }
            }else{
                appDisableDate = Date()
            }
            dicContent["appDisableDate"] = appDisableDate!
        }
        
        
        let plistContent = NSDictionary(dictionary: dicContent)
        let _ = plistContent.write(toFile: newLocalSettingsFileURL!.path, atomically: true)
    }
    
    func readLocalSettings(){
        if let settingsDictionary = NSDictionary(contentsOfFile: newLocalSettingsFileURL!.path){
            
            totalAppEnableTime = settingsDictionary.value(forKey: "totalAppEnableTime") as? Int ?? 0
            totalAppDisableTime = settingsDictionary.value(forKey: "totalAppDisableTime") as? Int ?? 0
            
            
            if let date = settingsDictionary.value(forKey: "appEnableDate") as? Date{
                appEnableDate = date
            }else{
                appEnableDate = Date()
            }
            if !Calendar.current.isDateInToday(appEnableDate!){
                appEnableDate = Date()
                totalAppEnableTime = 0
                totalAppDisableTime = 0
            }
            
            if let date = settingsDictionary.value(forKey: "appDisableDate") as? Date{
                appDisableDate = date
            }else{
                appDisableDate = Date()
            }
            if !Calendar.current.isDateInToday(appDisableDate!){
                appDisableDate = Date()
                totalAppDisableTime = 0
                totalAppEnableTime = 0
            }
            writeLocalSettings()
            
        }else{
            if isAppEnable{
                appEnableDate = Date()
            }else{
                appDisableDate = Date()
            }
            writeLocalSettings()
        }
    }
    
    
    func getCurrentStrictnessLevel()-> Int{
        var superGentleSettingsEnableCount = 0
        var gentleSettingsEnableCount = 0
        var slightlyStrictSettingsEnableCount = 0
        var strictSettingsEnableCount = 0
        var superStrictSettingsEnableCount = 0
        
        if isFullScreenEnabled{
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
            superStrictSettingsEnableCount += 1
        }else{
            superGentleSettingsEnableCount += 1
        }
        
        if isCuddlyModeEnabled{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
        }else{
            superStrictSettingsEnableCount += 1
        }
        
        if isEasySkipEnabled{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
        }else{
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
            superStrictSettingsEnableCount += 1
        }
        
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool ?? false{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
        }else{
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
            superStrictSettingsEnableCount += 1
        }
        
        if shouldReloadAfterForceQuitEnabled{
            strictSettingsEnableCount += 1
            superStrictSettingsEnableCount += 1
        }else{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
        }
        
        if immediatelyBlockDistractingSites{
            superStrictSettingsEnableCount += 1
        }else{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
        }
        
        if immediatelyBlockDistractingApps{
            superStrictSettingsEnableCount += 1
        }else{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
        }
        
        if isRequiredIntentionInPostpone{
            superStrictSettingsEnableCount += 1
            strictSettingsEnableCount += 1
        }else{
            superGentleSettingsEnableCount += 1
            gentleSettingsEnableCount += 1
            slightlyStrictSettingsEnableCount += 1
        }
        
        let arrSettingsEnableCount = [superGentleSettingsEnableCount,
                                      gentleSettingsEnableCount,
                                      slightlyStrictSettingsEnableCount,
                                      strictSettingsEnableCount,
                                      superStrictSettingsEnableCount]
        
        let maxValue = arrSettingsEnableCount.max()
        var currentStrictnessLevel = 1
        if maxValue == superGentleSettingsEnableCount{
            currentStrictnessLevel = strictnessLevelSuperGentle
        }else if maxValue == gentleSettingsEnableCount{
            currentStrictnessLevel = strictnessLevelGentle
        }else if maxValue == slightlyStrictSettingsEnableCount{
            currentStrictnessLevel = strictnessLevelSlightlyStrict
        }else if maxValue == strictSettingsEnableCount{
            currentStrictnessLevel = strictnessLevelStrict
        }else if maxValue == superStrictSettingsEnableCount{
            currentStrictnessLevel = strictnessLevelSuperStrict
        }
        return currentStrictnessLevel
    }
    
    func isStrictnessLevelSuperGentle()->Bool{
        let level = getCurrentStrictnessLevel()
        if level == strictnessLevelSuperGentle{
            return true
        }
        return false
    }
    
    func isAIBlockingEnabled()->Bool{
        if customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
            return customBlockingScheduleManagerObj.isAIBlockingEnabled()
        }
        return isAiCheckUrlEnabled
    }
    
}




