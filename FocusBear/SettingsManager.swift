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
    // **blocked urls**
    var arrBlockedUrls = [String]()
    var isOfficeModeEnabled = false
    var kIsReducedMotion = false
    var isPromptToRememberHabit = true
    
    var kUserdefaultsAppPassword = "kUserdefaultsAppPassword"
    var kUserdefaultsArrBlockedUrls = "kUserdefaultsArrBlockedUrls"
    var kUserdefaultsOfficeModeEnabled = "kUserdefaultsOfficeModeEnabled"
    var kUserdefaultsReducedMotion = "kUserdefaultsReducedMotion"
    var kUserdefaultsPromptToRememberHabit = "kUserdefaultsPromptToRememberHabit"
    var kUserdefaultsEnableSound = "kUserdefaultsEnableSound"
    var kUserdefaultsPomodoroDurationMinutes = "kUserdefaultsPomodoroDurationMinutes"
    var kUserdefaultsBreakDurationMinutes = "kUserdefaultsBreakDurationMinutes"

    var kUserdefaultsHideAllWindowInScreenShots = "kUserdefaultsHideAllWindowInScreenShots"
    var kUserdefaultsPomodoroModeEnabled = "kUserdefaultsPomodoroModeEnabled"
    
    
    var kUserdefaultsHardcorePomodoroEnabled = "kUserdefaultsHardcorePomodoroEnabled"
    var kUserdefaultsHardcorePomodoroFocusedName = "kUserdefaultsHardcorePomodoroFocusedName"
    var kUserdefaultsHardcorePomodoroFocusedCount = "kUserdefaultsHardcorePomodoroFocusedCount"
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
        kUserdefaultsArrBlockedUrls = kUserdefaultsArrBlockedUrls + (appdelegate?.user?.userId ?? "")
        kUserdefaultsOfficeModeEnabled = kUserdefaultsOfficeModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsReducedMotion = kUserdefaultsReducedMotion + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPromptToRememberHabit = kUserdefaultsPromptToRememberHabit + (appdelegate?.user?.userId ?? "")
        kUserdefaultsEnableSound = kUserdefaultsEnableSound + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPomodoroDurationMinutes = kUserdefaultsPomodoroDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsBreakDurationMinutes = kUserdefaultsBreakDurationMinutes + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHideAllWindowInScreenShots = kUserdefaultsHideAllWindowInScreenShots + (appdelegate?.user?.userId ?? "")
        kUserdefaultsPomodoroModeEnabled = kUserdefaultsPomodoroModeEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroEnabled = kUserdefaultsHardcorePomodoroEnabled + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedName = kUserdefaultsHardcorePomodoroFocusedName + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroFocusedCount = kUserdefaultsHardcorePomodoroFocusedCount + (appdelegate?.user?.userId ?? "")
        kUserdefaultsHardcorePomodoroArrDays = kUserdefaultsHardcorePomodoroArrDays + (appdelegate?.user?.userId ?? "")
    }
    //https://api.focusbear.io/api/static/index.html#/
    func getUserLocalDeviceSettings(completionHandler: @escaping() -> ()){
        
        addLog(text: "get User Local Device Settings")
        
        //  ---------------------------SETTINGS Sount--------------------------//Do not sync it
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
                    let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
                    let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
//                    let kSelectedLanguage = "kSelectedLanguage"
                    let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
                    let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
                    let kBreakDurationMinutes = "kBreakDurationMinutes"
                    let kPomodoroModeEnabled = "kPomodoroModeEnabled"
                    let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
                    let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
                    let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
                    let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"
                    
                    let kAppPassword = "kAppPassword"
                    let kArrBlockedUrls = "kArrBlockedUrls"
                    
                    if let val = settings.value(forKey: kIsReducedMotionEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsReducedMotion)
                    }
                    
                    if let val = settings.value(forKey: kIsPromptToRememberHabit) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsPromptToRememberHabit)
                    }
                    
                    if let val = settings.value(forKey: kIsOfficeModeEnabled) as? Bool{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsOfficeModeEnabled)
                    }
                    
                    
//                    if let val = settings.value(forKey: kSelectedLanguage) as? String{
//                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsSelectedLanguage)
//                    }
                    
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
                    
                    if let val = settings.value(forKey: kHardcorePomodoroArrDays) as? [String]{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsHardcorePomodoroArrDays)
                    }
                    
                    if let val = settings.value(forKey: kArrBlockedUrls) as? [String]{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsArrBlockedUrls)
                    }
                    
                    if let val = settings.value(forKey: kAppPassword) as? String{
                        UserDefaults.standard.set(val, forKey: self.kUserdefaultsAppPassword)
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
                    UserDefaults.standard.set(false, forKey: kUserdefaultsOfficeModeEnabled)
                    isOfficeModeEnabled = false
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
        UserDefaults.standard.set(isPromptToRememberHabit, forKey: kUserdefaultsPromptToRememberHabit)
        UserDefaults.standard.set(isOfficeModeEnabled, forKey: kUserdefaultsOfficeModeEnabled)
        
        UserDefaults.standard.set(isSoundEnabled, forKey: kUserdefaultsEnableSound)//do not sync it 
        
        let kIsReducedMotionEnabled = "kIsReducedMotion"
        let kIsPromptToRememberHabit = "kIsPromptToRememberHabit"
        let kIsOfficeModeEnabled = "kIsOfficeModeEnabled"
//        let kSelectedLanguage = "kSelectedLanguage"
        let kHideAllWindowInScreenShots = "kHideAllWindowInScreenShots"
        let kPomodoroDurationMinutes = "kPomodoroDurationMinutes"
        let kBreakDurationMinutes = "kBreakDurationMinutes"
        let kPomodoroModeEnabled = "kPomodoroModeEnabled"
        let kHardcorePomodoroEnabled = "kHardcorePomodoroEnabled"
        let kHardcorePomodoroFocusedName = "kHardcorePomodoroFocusedName"
        let kHardcorePomodoroFocusedCount = "kHardcorePomodoroFocusedCount"
        let kHardcorePomodoroArrDays = "kHardcorePomodoroArrDays"

        let kAppPassword = "kAppPassword"
        let kArrBlockedUrls = "kArrBlockedUrls"
      
        
        var json: [String: Any] = [
            kIsReducedMotionEnabled:kIsReducedMotion,//userId.removingPercentEncoding ?? "",
            kIsPromptToRememberHabit:isPromptToRememberHabit,
            kIsOfficeModeEnabled:isOfficeModeEnabled,
//            kSelectedLanguage:UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String ?? "",
            kHideAllWindowInScreenShots:UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool ?? false,
            kPomodoroDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) as? Int ?? 0,
            kBreakDurationMinutes:UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) as? Int ?? 0,
            kPomodoroModeEnabled:UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool ?? false,
            kHardcorePomodoroEnabled:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) as? Bool ?? false,
            kHardcorePomodoroFocusedName:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedName) as? String ?? "",
            kHardcorePomodoroFocusedCount:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroFocusedCount) as? Int ?? 0,
            kHardcorePomodoroArrDays:UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroArrDays) as? [String] ?? [],
            kArrBlockedUrls:arrBlockedUrls,
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


