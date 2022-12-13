//
//  SettingsManager.swift
//  Focus Bear
//
//  Created by Vishnu Sharma on 04/08/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class SettingsManager:NSObject{
    
    
    
    
    var isSettingsChanged = false
    var isSoundEnabled = true
    
    var isPasswordRequireInChangeSettings = true
    var isPasswordRequireInSkipMorning = true
    var isPasswordRequireInSkipEvening = true
    var isPasswordRequireInAbortShutoff = true
    var isPasswordRequireInStopPomodoro = true
    var isPasswordRequireInQuitApp = true
    
    var isCuddlyModeEnabled = true
    
    // **blocked urls**
    var arrBlockedUrls = [String]()
    var isOfficeModeEnabled = false
    var kIsReducedMotion = false
    var isMeetingDetectionEnabled = true
    var isPromptToRememberHabit = true
    var isEasySkipEnabled = true
    
    
    var kUserdefaultsAppPassword = "kUserdefaultsAppPassword"
    
    var kUserdefaultsPasswordRequireInChangeSettings = "kUserdefaultsPasswordRequireInChangeSettings"
    var kUserdefaultsPasswordRequireInSkipMorning = "kUserdefaultsPasswordRequireInSkipMorning"
    var kUserdefaultsPasswordRequireInSkipEvening = "kUserdefaultsPasswordRequireInSkipEvening"
    var kUserdefaultsPasswordRequireInAbortShutoff = "kUserdefaultsPasswordRequireInAbortShutoff"
    var kUserdefaultsPasswordRequireInStopPomodoro = "kUserdefaultsPasswordRequireInStopPomodoro"
    var kUserdefaultsPasswordRequireInQuitApp = "kUserdefaultsPasswordRequireInQuitApp"
    
    
    
    
    var kUserdefaultsArrBlockedUrls = "kUserdefaultsArrBlockedUrls"
    var kUserdefaultsOfficeModeEnabled = "kUserdefaultsOfficeModeEnabled"
    var kUserdefaultsReducedMotion = "kUserdefaultsReducedMotion"
    var kUserdefaultsMeetingDetectionEnabled = "kUserdefaultsMeetingDetectionEnabled"
    var kUserdefaultsPromptToRememberHabit = "kUserdefaultsPromptToRememberHabit"
    var kUserdefaultsEasySkipEnabled = "kUserdefaultsEasySkipEnabled"
    var kUserdefaultsEnableSound = "kUserdefaultsEnableSound"
    
    
    var kUserdefaultsCuddlyModeEnabled = "kUserdefaultsCuddlyModeEnabled"
    
    var kUserdefaultsPomodoroDurationMinutes = "kUserdefaultsPomodoroDurationMinutes"
    var kUserdefaultsBreakDurationMinutes = "kUserdefaultsBreakDurationMinutes"
    
    var kUserdefaultsHideAllWindowInScreenShots = "kUserdefaultsHideAllWindowInScreenShots"
    var kUserdefaultsPomodoroModeEnabled = "kUserdefaultsPomodoroModeEnabled"
    
    
    var kUserdefaultsHardcorePomodoroEnabled = "kUserdefaultsHardcorePomodoroEnabled"
    var kUserdefaultsHardcorePomodoroFocusedName = "kUserdefaultsHardcorePomodoroFocusedName"
    var kUserdefaultsHardcorePomodoroFocusedCount = "kUserdefaultsHardcorePomodoroFocusedCount"
    var kUserdefaultsHardcorePomodoroSkipMicroBreaks = "kUserdefaultsHardcorePomodoroSkipMicroBreaks"
    
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
        kUserdefaultsAppPassword = kUserdefaultsAppPassword + (appdelegate?.user?.userId ?? "")
        
        kUserdefaultsPasswordRequireInChangeSettings = kUserdefaultsPasswordRequireInChangeSettings + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInSkipMorning = kUserdefaultsPasswordRequireInSkipMorning + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInSkipEvening = kUserdefaultsPasswordRequireInSkipEvening + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInAbortShutoff = kUserdefaultsPasswordRequireInAbortShutoff + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInStopPomodoro = kUserdefaultsPasswordRequireInStopPomodoro + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPasswordRequireInQuitApp = kUserdefaultsPasswordRequireInQuitApp + (appdelegate?.user?.userId ?? "")

        kUserdefaultsArrBlockedUrls = kUserdefaultsArrBlockedUrls + (appdelegate?.user?.userId ?? "")
        kUserdefaultsOfficeModeEnabled = kUserdefaultsOfficeModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsReducedMotion = kUserdefaultsReducedMotion + (appdelegate?.user?.userId ?? "")
        kUserdefaultsCuddlyModeEnabled = kUserdefaultsCuddlyModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPromptToRememberHabit = kUserdefaultsPromptToRememberHabit + (appdelegate?.user?.userId ?? "")
        kUserdefaultsEasySkipEnabled = kUserdefaultsEasySkipEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsEnableSound = kUserdefaultsEnableSound + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPomodoroDurationMinutes = kUserdefaultsPomodoroDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsBreakDurationMinutes = kUserdefaultsBreakDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHideAllWindowInScreenShots = kUserdefaultsHideAllWindowInScreenShots + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPomodoroModeEnabled = kUserdefaultsPomodoroModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroEnabled = kUserdefaultsHardcorePomodoroEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedName = kUserdefaultsHardcorePomodoroFocusedName + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedCount = kUserdefaultsHardcorePomodoroFocusedCount + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroSkipMicroBreaks = kUserdefaultsHardcorePomodoroSkipMicroBreaks + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroArrDays = kUserdefaultsHardcorePomodoroArrDays + (appdelegate?.user?.userId ?? "")
    }
    //https://api.focusbear.io/api/static/index.html#/
    func getUserLocalDeviceSettings(completionHandler: @escaping() -> ()){
        
        addLog(text: "get User Local Device Settings")
        
        //  ---------------------------SETTINGS Sound--------------------------//Do not sync it
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsEnableSound) as? Bool{
            if isEnabled{
                isSoundEnabled = true
            }else{
                isSoundEnabled = false
            }
        }else{
            UserDefaults.standard.set(true, forKey: kUserdefaultsEnableSound)
            isSoundEnabled = true
        }
        
        
        
        var isSettingsBlank = true // agar blank ho to upload bhi kro
        allApiObject.getUserLocalDeviceSettings(completionHandler: { [self]json in
            if json != nil{
                if let settings = json?.value(forKey: "MacOS") as? NSDictionary {
                    print(settings)
                    if settings.allKeys.count == 0{
                        isSettingsBlank = true
                    }else{
                        isSettingsBlank = false
                    }
                    let kIsReducedMotionEnabled = "kIsReducedMotion"
                    let kIsMeetingDetectionEnabled = "kIsMeetingDetectionEnabled"
                    let kIsPasswordRequireInChangeSettings = "kIsPasswordRequireInChangeSettings"
                    let kIsPasswordRequireInSkipMorning = "kIsPasswordRequireInSkipMorning"
                    let kIsPasswordRequireInSkipEvening = "kIsPasswordRequireInSkipEvening"
                    let kIsPasswordRequireInAbortShutoff = "kIsPasswordRequireInAbortShutoff"
                    let kIsPasswordRequireInStopPomodoro = "kIsPasswordRequireInStopPomodoro"
                    let kIsPasswordRequireInQuitApp = "kIsPasswordRequireInQuitApp"
                    
                    
                    
                    
                    
                    let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
                    let kIsEasySkipEnabled = "kIsEasySkipEnabled"
                    let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
                    //                    let kSelectedLanguage = "kSelectedLanguage"
                    let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
                    let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
                    let kBreakDurationMinutes = "kBreakDurationMinutes"
                    let kPomodoroModeEnabled = "kPomodoroModeEnabled"
                    let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
                    let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
                    let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
                    let kHardcorePomodoroSkipMicroBreaks = "kHardcorePomodoroSkipMicroBreaks"
                    let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"
                    
                    let kAppPassword = "kAppPassword"
                    let kArrBlockedUrls = "kArrBlockedUrls"
                    
                    let kCuddlyModeEnabled = "kCuddlyModeEnabled"
                    
                    if let val = settings.value(forKey: kIsReducedMotionEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsReducedMotion)
                    }
                    
                    if let val = settings.value(forKey: kIsMeetingDetectionEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsMeetingDetectionEnabled)
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
                    if let val = settings.value(forKey: kIsPasswordRequireInAbortShutoff) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInAbortShutoff)
                    }
                    
                    if let val = settings.value(forKey: kIsPasswordRequireInStopPomodoro) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInStopPomodoro)
                    }
                    
                    if let val = settings.value(forKey: kIsPasswordRequireInQuitApp) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPasswordRequireInQuitApp)
                    }
                    
                    
                    
                    
                    if let val = settings.value(forKey: kIsPromptToRememberHabit) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPromptToRememberHabit)
                    }
                    
                    if let val = settings.value(forKey: kIsEasySkipEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsEasySkipEnabled)
                    }
                    
                    if let val = settings.value(forKey: kIsOfficeModeEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsOfficeModeEnabled)
                    }

                    
                    if let val = settings.value(forKey: kHideAllWindowInScreenShots) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsHideAllWindowInScreenShots)
                    }
                    
                    if let val = settings.value(forKey: kPomodoroDurationMinutes) as? Int{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPomodoroDurationMinutes)
                    }
                    
                    if let val = settings.value(forKey: kBreakDurationMinutes) as? Int{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsBreakDurationMinutes)
                    }
                    
                    if let val = settings.value(forKey: kPomodoroModeEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPomodoroModeEnabled)
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
                    
                    if let val = settings.value(forKey: kHardcorePomodoroSkipMicroBreaks) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroSkipMicroBreaks)
                    }
                    
                    if let val = settings.value(forKey: kHardcorePomodoroArrDays) as? [String]{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroArrDays)
                    }
                    
                    if let val = settings.value(forKey: kArrBlockedUrls) as? [String]{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsArrBlockedUrls)
                    }
                    
                    if let val = settings.value(forKey: kAppPassword) as? String{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsAppPassword)
                    }
                    if let val = settings.value(forKey: kCuddlyModeEnabled) as? String{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsCuddlyModeEnabled)
                    }
                    
                }
                
            }
            
            //  ---------------------------OFFICE MODE--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsOfficeModeEnabled) as? Bool{
                if isEnabled{
                    isOfficeModeEnabled = true
                    DispatchQueue.main.async {
                        appdelegate?.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Office-Small"))
                    }
                }else{
                    isOfficeModeEnabled = false
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
            
            
            //  ---------------------------SETTINGS Password Require--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInChangeSettings) as? Bool{
                if isEnabled{
                    isPasswordRequireInChangeSettings = true
                }else{
                    isPasswordRequireInChangeSettings = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInChangeSettings)
                isPasswordRequireInChangeSettings = true
            }
            

            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInSkipMorning) as? Bool{
                if isEnabled{
                    isPasswordRequireInSkipMorning = true
                }else{
                    isPasswordRequireInSkipMorning = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInSkipMorning)
                isPasswordRequireInSkipMorning = true
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInSkipEvening) as? Bool{
                if isEnabled{
                    isPasswordRequireInSkipEvening = true
                }else{
                    isPasswordRequireInSkipEvening = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInSkipEvening)
                isPasswordRequireInSkipEvening = true
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInAbortShutoff) as? Bool{
                if isEnabled{
                    isPasswordRequireInAbortShutoff = true
                }else{
                    isPasswordRequireInAbortShutoff = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInAbortShutoff)
                isPasswordRequireInAbortShutoff = true
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInStopPomodoro) as? Bool{
                if isEnabled{
                    isPasswordRequireInStopPomodoro = true
                }else{
                    isPasswordRequireInStopPomodoro = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInStopPomodoro)
                isPasswordRequireInStopPomodoro = true
            }
            
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsPasswordRequireInQuitApp) as? Bool{
                if isEnabled{
                    isPasswordRequireInQuitApp = true
                }else{
                    isPasswordRequireInQuitApp = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPasswordRequireInQuitApp)
                isPasswordRequireInQuitApp = true
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
                UserDefaults.standard.set(true, forKey: kUserdefaultsEasySkipEnabled)
                isEasySkipEnabled = true
//                if let val = UserDefaults.standard.object(forKey: kUserdefaultsHabitSkipEasinessFromOnboarding) as? Bool{
//                    UserDefaults.standard.removeObject(forKey: kUserdefaultsHabitSkipEasinessFromOnboarding)
//                    UserDefaults.standard.set(val, forKey: kUserdefaultsEasySkipEnabled)
//                    isEasySkipEnabled = val
//                }else{
//                    UserDefaults.standard.set(true, forKey: kUserdefaultsEasySkipEnabled)
//                    isEasySkipEnabled = true
//                }
            }
            
            
            //  ---------------------------SETTINGS Focus bear mode--------------------------
            if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsCuddlyModeEnabled) as? Bool{
                if isEnabled{
                    isCuddlyModeEnabled = true
                }else{
                    isCuddlyModeEnabled = false
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsCuddlyModeEnabled)
                isCuddlyModeEnabled = true
            }
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
            
            //  ---------------------------POMODORO MODE--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroModeEnabled)
            }
            
            
            //  ---------------------------AUTO HARDCORE POMODORO MODE settings--------------------------
            if UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) == nil{
                UserDefaults.standard.set(false, forKey: kUserdefaultsHardcorePomodoroEnabled)
            }
            
            if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrBlockedUrls) as? [String]{
                arrBlockedUrls = arr
            }
            
            if isSettingsBlank{
                if let blockedUrls = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
                    arrBlockedUrls.removeAll()
                    for i in 0..<blockedUrls.count{
                        if let isSelected = blockedUrls[i]["isSelected"] as? Bool {
                            if isSelected{
                                arrBlockedUrls.append(blockedUrls[i]["url"] as? String ?? "")
                            }
                        }
                    }
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsBlockedUrlsFromOnboarding)
                }else{
                    arrBlockedUrls = ["facebook.com", "twitter.com", "instagram.com", "tiktok.com", "bbc.com", "cnn.com"]
                }
                
                UserDefaults.standard.set(arrBlockedUrls, forKey: kUserdefaultsArrBlockedUrls)
                
                isSettingsChanged = true
                self.perform(#selector(putUserLocalDeviceSettings))
            }
            
            // }
            completionHandler()
            return
        }
        )
        
    }
    @objc func putUserLocalDeviceSettings(){
        addLog(text: "put User Local Device Settings")
        if isSettingsChanged{
            isSettingsChanged = false
        }else{
            return
        }
        UserDefaults.standard.set(kIsReducedMotion, forKey: kUserdefaultsReducedMotion)
        UserDefaults.standard.set(isMeetingDetectionEnabled, forKey: kUserdefaultsMeetingDetectionEnabled)
        UserDefaults.standard.set(isPromptToRememberHabit, forKey: kUserdefaultsPromptToRememberHabit)
        UserDefaults.standard.set(isEasySkipEnabled, forKey: kUserdefaultsEasySkipEnabled)
        UserDefaults.standard.set(isOfficeModeEnabled, forKey: kUserdefaultsOfficeModeEnabled)
        UserDefaults.standard.set(isCuddlyModeEnabled, forKey: kUserdefaultsCuddlyModeEnabled)
        UserDefaults.standard.set(isSoundEnabled, forKey: kUserdefaultsEnableSound)//do not sync it
        
        
        UserDefaults.standard.set(isPasswordRequireInChangeSettings, forKey: kUserdefaultsPasswordRequireInChangeSettings)
        UserDefaults.standard.set(isPasswordRequireInSkipMorning, forKey: kUserdefaultsPasswordRequireInSkipMorning)
        UserDefaults.standard.set(isPasswordRequireInSkipEvening, forKey: kUserdefaultsPasswordRequireInSkipEvening)
        UserDefaults.standard.set(isPasswordRequireInAbortShutoff, forKey: kUserdefaultsPasswordRequireInAbortShutoff)
        UserDefaults.standard.set(isPasswordRequireInStopPomodoro, forKey: kUserdefaultsPasswordRequireInStopPomodoro)
        UserDefaults.standard.set(isPasswordRequireInQuitApp, forKey: kUserdefaultsPasswordRequireInQuitApp)
        
        let kIsReducedMotionEnabled = "kIsReducedMotion"
        let kIsMeetingDetectionEnabled = "kIsMeetingDetectionEnabled"
        let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
        let kIsEasySkipEnabled = "kIsEasySkipEnabled"
        let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
        //        let kSelectedLanguage = "kSelectedLanguage"
        let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
        let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
        let kBreakDurationMinutes = "kBreakDurationMinutes"
        let kPomodoroModeEnabled = "kPomodoroModeEnabled"
        let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
        let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
        let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
        let kHardcorePomodoroSkipMicroBreaks = "kHardcorePomodoroSkipMicroBreaks"
        let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"
        
        
        let kIsPasswordRequireInChangeSettings = "kIsPasswordRequireInChangeSettings"
        let kIsPasswordRequireInSkipMorning = "kIsPasswordRequireInSkipMorning"
        let kIsPasswordRequireInSkipEvening = "kIsPasswordRequireInSkipEvening"
        let kIsPasswordRequireInAbortShutoff = "kIsPasswordRequireInAbortShutoff"
        let kIsPasswordRequireInStopPomodoro = "kIsPasswordRequireInStopPomodoro"
        let kIsPasswordRequireInQuitApp = "kIsPasswordRequireInQuitApp"
        
        let kAppPassword = "kAppPassword"
        let kArrBlockedUrls = "kArrBlockedUrls"
        let kCuddlyModeEnabled = "kCuddlyModeEnabled"
        
        var json: [String: Any] = [
            kIsReducedMotionEnabled:kIsReducedMotion,//userId.removingPercentEncoding ?? "",
            kIsMeetingDetectionEnabled:isMeetingDetectionEnabled,
            kIsPromptToRememberHabit:isPromptToRememberHabit,
            kIsEasySkipEnabled:isEasySkipEnabled,
            kIsOfficeModeEnabled:isOfficeModeEnabled,
            kHideAllWindowInScreenShots:UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool ?? false,
            kPomodoroDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int ?? 0,
            kBreakDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) as? Int ?? 0,
            kPomodoroModeEnabled:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool ?? false,
            kHardcorePomodoroEnabled:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) as? Bool ?? false,
            kHardcorePomodoroFocusedName:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedName) as? String ?? "",
            kHardcorePomodoroFocusedCount:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedCount) as? Int ?? 0,
            kHardcorePomodoroSkipMicroBreaks:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroSkipMicroBreaks) as? Bool ?? false,//
            kHardcorePomodoroArrDays:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroArrDays) as? [String] ?? [],
            kArrBlockedUrls:arrBlockedUrls,
            kCuddlyModeEnabled:isCuddlyModeEnabled,
            kIsPasswordRequireInChangeSettings:isPasswordRequireInChangeSettings,
            kIsPasswordRequireInSkipMorning:isPasswordRequireInSkipMorning,
            kIsPasswordRequireInSkipEvening:isPasswordRequireInSkipEvening,
            kIsPasswordRequireInAbortShutoff:isPasswordRequireInAbortShutoff,
            kIsPasswordRequireInStopPomodoro:isPasswordRequireInStopPomodoro,
            kIsPasswordRequireInQuitApp:isPasswordRequireInQuitApp
        ]
        
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
            json[kAppPassword] = UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) as? String ?? ""
        }
        
        
        let dic: [String: [String:Any]] = [
            "MacOS": json,
            "Windows": [:],
            "Android": [:],
            "iOS": [:]
        ]
        allApiObject.putUserLocalDeviceSettings(settings: dic, completionHandler: {dic  in
            DispatchQueue.main.async {
                
                
                if dic == nil{
                    
                }else{
                    
                    do {
                        let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                        
                    } catch let myJSONError {
                        print(myJSONError)
                    }
                    
                }
            }
        })
        
    }
}


