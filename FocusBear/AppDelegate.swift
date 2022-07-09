//
//  AppDelegate.swift
//  FocusBear
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//


import Cocoa
import Sentry
import Sparkle

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SUUpdaterDelegate {
    let validation = urlValidation()
    var statusBarMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var statusbutton:NSStatusBarButton?
    var updater: SUUpdater?
    
    var terminateFromSelf = false
    var hotKeyClearUserdefaults: HotKey? {
        didSet {
            guard let hotKey = hotKeyClearUserdefaults else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                print("Pressed at \(Date())")
                self!.resetAllData()
                
            }
        }
    }
    
    var hotKeyPauseFocusMode: HotKey? {
        didSet {
            guard let hotKey = hotKeyPauseFocusMode else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                print("Pressed at \(Date())")
                self?.pauseFocusModeIfRunning()
                
            }
        }
    }
    var hotKeyResumeFocusMode: HotKey? {
        didSet {
            guard let hotKey = hotKeyResumeFocusMode else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                print("Pressed at \(Date())")
                self?.resumeFocusModeIfRunning()
                
            }
        }
    }
    
    var timerCheckReactivateTime:Timer?
    var timerCheckClearPasswordTime:Timer?
    var timerBackgroundThread:Timer?
    
    
    func resetAllData(){
        let alert = NSAlert()
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                alert.window.sharingType = .none
            }
        }
        alert.messageText = "Are you sure you want to reset Focus Bear? All your settings will be deleted."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        if let window = NSApp.keyWindow{
            alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                    
                    self.quitAndRestartApp()
                }
            })
        }else{
            let result = alert.runModal()
            if result == .alertFirstButtonReturn{
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                self.quitAndRestartApp()
            }
        }
        
    }
    
    
    
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        //        let domain = Bundle.main.bundleIdentifier!//todo
        //        UserDefaults.standard.removePersistentDomain(forName: domain)
        //        UserDefaults.standard.synchronize()
        //        return;
        //        UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstHabitDay)
        //        UserDefaults.standard.removeObject(forKey: "trialExpired")
        //        return;
        
        updater = SUUpdater(for: Bundle.main)
        updater?.delegate = self
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
        //        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)
        
        
        var isDefaultContain = false
        var defaultContainLocation = -1
        var isMeetingsContain = false
        if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String:Any]]{
            arrFocusType = arr
            
            for i in 0..<arrFocusType.count{
                arrFocusType[i]["isOn"] = false
                if let state = arrFocusType[i]["isDefault"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        isDefaultContain = state
                        defaultContainLocation = i//break nahi krna yha loop ko (qki isOn false bi ho rha h har index mai)
                    }
                }
                if let state = arrFocusType[i]["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        isMeetingsContain = state
                    }
                }
            }
            
        }
        if !isDefaultContain{
            let dic:[String:Any] = ["name":"Complete anarchy! Block nothing 😬", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": [], "urlsArray": [], "isOn": false, "isAllowedAllApps":true, "isAllowedAllUrls":true, "isDefault":true]
            arrFocusType.append(dic)
        }else{//for old users change default focusmode name deom "Default" to "Complete anarchy! Block nothing 😬" and defalt focus mode will always be last in list so rearranging it
            if defaultContainLocation == arrFocusType.count - 1{
                if var dic = arrFocusType.last{
                    dic["name"] = "Complete anarchy! Block nothing 😬"
                    arrFocusType[arrFocusType.count - 1] = dic
                }
            }else{
                var dic = arrFocusType[defaultContainLocation]
                dic["name"] = "Complete anarchy! Block nothing 😬"
                arrFocusType.remove(at: defaultContainLocation)
                arrFocusType.append(dic)
                
            }
        }
        if !isMeetingsContain{
            let dic:[String:Any] = ["name":"Meetings", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": ["/Applications/Microsoft Teams.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app"], "urlsArray": ["http://meet.google.com"], "isOn": false, "isAllowedAllApps":false, "isAllowedAllUrls":false, "isMeetings":true]
            arrFocusType.insert(dic, at: arrFocusType.count - 1)
        }
        
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrBlockedUrls) as? [String]{
            arrBlockedUrls = arr
        }
        
        // ----------------SET APP INSTALL DATE---------------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }
        
        //  ---------------------------OFFICE MODE--------------------------
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsOfficeModeEnabled) as? Bool{
            if isEnabled{
                isOfficeModeEnabled = true
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
        //  ---------------------------SETTINGS Language--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) == nil{
            UserDefaults.standard.set("en", forKey: kUserdefaultsSelectedLanguage)
        }
        
        //  ---------------------------SETTINGS Pomodoro duration--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroDurationMinutes) == nil{
            UserDefaults.standard.set(25, forKey: kUserdefaultsPomodoroDurationMinutes)
        }
        
        //  ---------------------------SETTINGS Break duration--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationMinutes) == nil{
            UserDefaults.standard.set(5, forKey: kUserdefaultsBreakDurationMinutes)
        }
        
        
        
       // ---------------------------SETTINGS Hide All Window In Screenshots--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsHideAllWindowInScreenShots)
        }
        
        //  ---------------------------POMODORO MODE--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroModeEnabled)
        }
        
        
        //  ---------------------------AUTO HARDCORE POMODORO MODE settings--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsHardcorePomodoroEnabled)
        }
        
        //  ----------------------START APP AT LOGIN-----------------------
        LaunchOnStartup.setLaunchAtStartup(true)
        createLaunchAgent()// keep alive // todo uncomment
        
        
        // -----------------------------GENERATE LOG FILE----------------------------
        let bundel = Bundle.main.bundleIdentifier ?? ""
        let applicationSupportPath = "/Users/\(NSUserName())/Library/Application Support/\(bundel)"
        CreateDirectoryIfNotExist(path: applicationSupportPath)
        let applicationSupportURL  = URL(fileURLWithPath: applicationSupportPath)
        DebugLogsURL = applicationSupportURL.appendingPathComponent("Debug_Logs.txt")
        quantityCsvURL = applicationSupportURL.appendingPathComponent("eystStats.csv")
        
        //"Log type", "Timestamp", "Activity", "Duration in seconds", "Quantity Question", "Quantity Logged", "Work achieved", "Distractions encountered", "Abort reason"
        
        
        
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: quantityCsvURL.path){
            let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback\n"//start time will only be use in focus block start k time per
            
            do {
                try csvString.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
            } catch {
                print("error creating file")
            }
        }

        blockURL = applicationSupportURL.appendingPathComponent("eyst-focus.html")
        
        if fileManager.fileExists(atPath: blockURL!.path){
            do{
                try fileManager.removeItem(atPath: blockURL!.path)
            }catch{
                print(error)
            }
        }//
        
        if !fileManager.fileExists(atPath: blockURL!.path){
            if let path = Bundle.main.path(forResource: "block", ofType: "html") {
                let url = URL(fileURLWithPath: path)
                do{
                    try fileManager.copyItem(at: url, to: blockURL)
                }catch{
                    print(error)
                }
            }
        }
        
        
        let logoURL = applicationSupportURL.appendingPathComponent("logo.png")
        
        if fileManager.fileExists(atPath: logoURL.path){
            do{
                try fileManager.removeItem(atPath: logoURL.path)
            }catch{
                print(error)
            }
        }//
        
        if !fileManager.fileExists(atPath: logoURL.path){
            if let path = Bundle.main.path(forResource: "logo", ofType: "png") {
                let url = URL(fileURLWithPath: path)
                do{
                    try fileManager.copyItem(at: url, to: logoURL)
                }catch{
                    print(error)
                }
            }
        }
        
        
        blockWebUrlString = "https://focus-bear.github.io/assets/focus-blocked/"//blockURL!.absoluteString
        //        var urlString = originalString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        
        //  ------------------------------------------------------------------------------------
        
        if let date = UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) as? Date{
            if Date().compare(date) == .orderedAscending {
                //first date is smaller than second
                DispatchQueue.global().async {
                    self.timerCheckClearPasswordTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkTwentyFourHourActivateTime), userInfo: nil, repeats: true)
                    RunLoop.current.add(self.timerCheckClearPasswordTime!, forMode: RunLoop.Mode.common)
                    RunLoop.current.run()
                }
            }else{
                UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
                UserDefaults.standard.removeObject(forKey: kUserdefaultsAppPassword)
                addLog(text: "password is cleard after 24 hours")
            }
            
        }
        
        
        // ------------------- SET FORCE FRASH START ----------------
        let char = "k"
        var flags = NSEvent.modifierFlags
        flags.insert(.control)
        flags.insert(.command)
        self.hotKeyClearUserdefaults = HotKey(keyCombo: KeyCombo(stkey: char, modifiers: flags))
        
        
        
        
        //        self.hotKeyPauseFocusMode = HotKey(keyCombo: KeyCombo(stkey: "p", modifiers: flags))
        //
        //        self.hotKeyResumeFocusMode = HotKey(keyCombo: KeyCombo(stkey: "r", modifiers: flags))
        
        
        // ///////////////////SET TOP ICON////////////////////////
        if self.statusItem.button != nil {
            self.statusbutton = self.statusItem.button
            self.statusbutton?.image = NSImage(named: NSImage.Name("clock22"))//)//Name("pagesLatex_small"))clock22eystSmall
            
            self.statusbutton?.font = NSFont.systemFont(ofSize: 10)
            //            self.statusbutton?.imagePosition = .imageAbove
            //            self.statusItem.title = "fff"
            //            self.statusItem.
        }
        
        
        DispatchQueue.global().async {//ye isiliye kiya qki first time mai list mai time lgta hai to starting mai hi kr diya
            avmonitor.isMicOn()//.start()
            avmonitor.isACameraOn()//.checkCamera()
        }
        
        
        var languageCode = "en"
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            languageCode = language
        }
        var configFileName = ""
        if languageCode == "en"{
            configFileName = "config"
        }else{
            configFileName = "config-\(languageCode)"
        }
        //        https://focus-bear.github.io/assets/config/config.json
        getConfigFile(fileUrl:"https://focus-bear.github.io/assets/config/\(configFileName).json", completionHandler: {dic in
            print("response mila")
            if dic != nil{//todo != kro
                configjson = dic!
            }else{
                if let path = Bundle.main.path(forResource: configFileName, ofType: "json") {
                    let url = URL(fileURLWithPath: path)
                    do {
                        let data = try Data(contentsOf: url, options: .mappedIfSafe)
                        
                        do {
                            if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                configjson = dicResult
                                print(configjson)
                                
                            }
                            
                        }catch {
                            print(error)
                        }
                        
                    } catch {
                        // handle error
                    }
                    
                }
            }
            readConfigFile()
            
            
            isPurchased = false
            if let val = UserDefaults.standard.object(forKey: kIsPurchased) as? Bool{
                isPurchased = val
            }
            var key = ""
            if let sKey = UserDefaults.standard.object(forKey: kRegisteredLicenseKey) as? String{
                key = sKey
            }else{
                isPurchased = false
            }
            
            if isPurchased && !key.isEmpty{
                UserDefaults.standard.removeObject(forKey: "trialExpired")
                activateKey(license_key: key, completionHandler: { jsonResult in
                    if jsonResult != nil{
                        var success = false
                        var refunded = false
                        if let val = jsonResult!.value(forKey: "success") as? Bool{
                            success = val
                        }
                        if let purchaseDic = jsonResult!.value(forKey: "purchase") as? NSDictionary{
                            if let val = purchaseDic.value(forKey: "refunded") as? Bool{
                                refunded = val
                            }
                        }
                        if success && !refunded{
                            isPurchased = true
                            UserDefaults.standard.removeObject(forKey: "trialExpired")
                        }else{
                            isPurchased = false
                            UserDefaults.standard.removeObject(forKey: kIsPurchased)
                            UserDefaults.standard.removeObject(forKey: kRegisteredLicenseKey)
                        }
                        DispatchQueue.main.async {
                            self.checkActivationState()
                        }
                    }
                    
                })
            }else{
                DispatchQueue.main.async {
                    self.checkActivationState()
                }
            }
            
        }
        )
        
    }
    // Are you sure you want to change the language to "language name"?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        SentrySDK.start { options in
            options.dsn = "https://d897211d717a4c79b1e34666c61548cc@o1187124.ingest.sentry.io/6342590"
            options.debug = true // Enabled debug when first installing is always helpful
        }
        
        //                let error = NSError(domain: "YourErrorDomain", code: 0, userInfo: nil)
        //                let id = SentrySDK.capture(error: error)
        //                print(id)
        
        updater?.checkForUpdatesInBackground()
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepEvent(_:)), name: NSWorkspace.didWakeNotification, object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(sleepEvent(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        //
        //        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenSaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
        DistributedNotificationCenter.default().addObserver(self,selector: #selector(sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"),object: nil)
        DistributedNotificationCenter.default().addObserver(self,selector: #selector(sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstop"),object: nil)
        
    }
    
    @objc private func sleepEvent(_ aNotification: Notification) {
        print("******didwakeup psps*******")
        
        if !isFocusModeOn(){
            isSystemSleep = false
            isFocusPaused = false
            return;
        }
        
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
            isSystemSleep = true
            
            if !isFocusPaused{
                pauseFocusModeIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            isSystemSleep = false
            if isFocusPaused{
                resumeFocusModeIfRunning()
            }
            
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstart") {
            print("com.apple.screensaver.didstart")
            pauseFocusModeIfRunning()
            
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstop") {
            print("com.apple.screensaver.didstop")
            
            if isSystemSleep{
                return;
            }
            if isFocusPaused{
                resumeFocusModeIfRunning()
            }
        }else {
            print("Some other event other than the first two")
        }
        
    }
    
    
    var isSystemSleep = false
    var isFocusPaused = false
    var remainingFocusModeSecondsAfterPaused = 0
    func pauseFocusModeIfRunning(){
        isFocusPaused = true
        print("focus paused")
        
        
        if timerForFocusMode != nil{
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
    }
    
    func resumeFocusModeIfRunning(){
        isFocusPaused = false
        print("focus resume")
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        
        DispatchQueue.global().async {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.current.add(timerForFocusMode!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()// ase q ho rha h ki  is line k baad next line execute ni hoti labhi
        }
    }
    
    
    //4b3eb33632184640b82aa3e3f50fe11b2cdd8b0e82ce48a8bfd1cbe26edc32f5
    func updaterWillRelaunchApplication(_ updater: SUUpdater) {
        addLog(text: "updater Will Relaunch Application")
        terminateFromSelf = true
    }
    
    func checkActivationState(){
        //        DispatchQueue.main.async {
        if isPurchased == true{
            // initial work includes top menu, and habit activities process
            self.initialWork()
        }else{
            //isko to roj check krna pdega
            if UserDefaults.standard.object(forKey: "trialExpired") != nil{//ak bar remaining day 0 hone k bad ise set krdete h taki koi date change krke chala ni pay
                activationWindowControllerObj?.showSevenDayTrialVc()
                self.setTopMenu()//if trial expired than menu is enabled
            }else{
                //sirf first day or 7ve day k baad hi nag show hoga
                if UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) == nil{// iska mtlb aaj tk start free trial per click ni kiya
                    activationWindowControllerObj?.showSevenDayTrialVc()
                    self.statusbutton?.action = #selector(self.topIconClickd)
                }else if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
                    let secondsBetween = Date().timeIntervalSince(date)
                    let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
                    var daysremaining = daysFreeTrial-numberOfDays_afterinstall
                    if daysremaining < 0 {
                        daysremaining = 0
                    }
                    if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                        daysremaining = 0
                    }
                    if daysremaining == 0{//if expired than menu is enabled
                        UserDefaults.standard.set(true, forKey: "trialExpired")
                        self.setTopMenu()
                        activationWindowControllerObj?.showSevenDayTrialVc()
                        //                                self.statusbutton?.action = #selector(self.topIconClickd)
                    }else{
                        self.initialWork()
                    }
                }
            }
        }
    }
    
    @objc func topIconClickd(){
        activationWindowControllerObj?.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func readSettingsJsonDictionary(){
        arrAllMorningHabits.removeAll()
        arrAllEveningHabits.removeAll()
        arrAllbreakActivities.removeAll()
        var jsonResult = NSDictionary()
        if let stringDic = UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) as? String {
            //            jsonResult = dic
            if let data = stringDic.data(using: String.Encoding.utf8) {
                
                do {
                    jsonResult = try (JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary ?? [:])
                    
                } catch let error as NSError {
                    print(error)
                }
            }
            
        }else {
            if let path = Bundle.main.path(forResource: "settings", ofType: "json") {
                let url = URL(fileURLWithPath: path)
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    
                    do {
                        if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            jsonResult = dicResult
                        }
                        
                    }catch {
                        print(error)
                    }
                } catch {
                    // handle error
                }
            }
        }
        
        // -------------------READING SETTINGS JSON----------------------//
        if let morningHabits = jsonResult.value(forKey: "morningHabits") as? [NSDictionary] {
            print("morningHabits")
            print(morningHabits)
            for habitDic in morningHabits {
                let name = habitDic["name"] as? String ?? ""
                let durationSeconds = habitDic["durationSeconds"] as? Int ?? 0
                let videoUrl = habitDic["videoUrl"] as? [String] ?? []
                let logQuantity = habitDic["logQuantity"] as? Bool ?? false
                let logQuantityQuestion = habitDic["logQuantityQuestion"] as? String
                //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                let allowUrls = habitDic["allowedUrls"] as? [String] ?? []
                let allowApps = habitDic["allowedApps"] as? [String] ?? []
                let allowedFocusMode = habitDic["allowedFocusMode"] as? String ?? ""
                var openSpecificApps = false
                if allowApps.count != 0{
                    openSpecificApps = true
                }
                arrAllMorningHabits.append(habit(name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode))
            }
        }
        if let eveningHabits = jsonResult.value(forKey: "eveningHabits") as? [NSDictionary] {
            print("eveningHabits")
            print(eveningHabits)
            for habitDic in eveningHabits {
                let name = habitDic["name"] as? String ?? ""
                let durationSeconds = habitDic["durationSeconds"] as? Int ?? 0
                let videoUrl = habitDic["videoUrl"] as? [String] ?? []
                let logQuantity = habitDic["logQuantity"] as? Bool ?? false
                let logQuantityQuestion = habitDic["logQuantityQuestion"] as? String
                //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                let allowUrls = habitDic["allowedUrls"] as? [String] ?? []
                let allowApps = habitDic["allowedApps"] as? [String] ?? []
                let allowedFocusMode = habitDic["allowedFocusMode"] as? String ?? ""
                var openSpecificApps = false
                if allowApps.count != 0{
                    openSpecificApps = true
                }
                arrAllEveningHabits.append(habit(name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode))
            }
        }
        
        if let breakActivities = jsonResult.value(forKey: "breakActivities") as? [NSDictionary] {
            print("breakActivities")
            print(breakActivities)
            for activityDic in breakActivities {
                let name = activityDic["name"] as? String ?? ""
                let durationSeconds = activityDic["durationSeconds"] as? Int ?? 0
                let IncludeInEveryBreak = activityDic["includeInEveryBreak"] as? Bool ?? false
                let videoUrl = activityDic["videoUrl"] as? [String] ?? []
                let logQuantity = activityDic["logQuantity"] as? Bool ?? false
                //                let openSpecificApps = activityDic["openSpecificApps"] as? Bool ?? false
                let allowUrls = activityDic["allowedUrls"] as? [String] ?? []
                let allowApps = activityDic["allowedApps"] as? [String] ?? []
                let isOfficeFriendly = activityDic["isOfficeFriendly"] as? Bool ?? false
                let allowedFocusMode = activityDic["allowedFocusMode"] as? String ?? ""
                var openSpecificApps = false
                if allowApps.count != 0{
                    openSpecificApps = true
                }
                var isRandomChoice = false
                if let type = activityDic["type"] as? String{
                    if type == "random-choice"{
                        isRandomChoice = true
                    }
                }
                var arrChoices = [activityChoice]()
                if let choices = activityDic.value(forKey: "choices") as? [NSDictionary] {
                    for dic in choices{
                        let name = dic["name"] as? String ?? ""
                        let videoUrl = dic["videoUrl"] as? [String] ?? []
                        let logQuantityQuestion = dic["logQuantityQuestion"] as? String ?? ""
                        let logQuantity = dic["logQuantity"] as? Bool ?? false
                        let logQuantityType = dic["logQuantityType"] as? String ?? ""
                        let choice = activityChoice(name: name, urlsArray: videoUrl, logQuantityQuestion: logQuantityQuestion, logQuantity: logQuantity, logQuantityType: logQuantityType)
                        arrChoices.append(choice)
                    }
                }
                if arrChoices.count == 0{
                    isRandomChoice = false
                }
                let logQuantityQuestion = activityDic["logQuantityQuestion"] as? String
                let logQuantityType = activityDic["logQuantityType"] as? String ?? ""
                arrAllbreakActivities.append(breakActivity(name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, urlsArray: videoUrl, logQuantity:logQuantity, isRandomChoice: isRandomChoice, choices: arrChoices, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, isOfficeFriendly: isOfficeFriendly, allowedFocusMode: allowedFocusMode, logQuantityType: logQuantityType))
            }
        }
        if let breakMinutes = jsonResult.value(forKey: "breakAfterMinutes") as? Int {
            print("breakAfterMinutes")
            breakAfterMinutes = breakMinutes
            print(breakAfterMinutes)
        }
        
        //        if let val = jsonResult.value(forKey: "showEveryBreak") as? Bool {//ye kabhi kaam ni aayga qki vo bejega h ni fir bhi hata ni rhe h qki default false h to koi prob ni h
        //            showEveryBreak = val
        //        }else{
        //            showEveryBreak = false
        //        }
        
        if let val = jsonResult.value(forKey: "startTime") as? String {
            startTime = getTimeFromString(val: val)
        }
        if let val = jsonResult.value(forKey: "shutOffTime") as? String {
            shutOffTime = getTimeFromString(val: val)
        }
    }
    func initialWork(){
        isAppInitialLodded = true
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstHabitDay)
        }
        self.statusbutton?.action = nil
        
        // -------------------GETTING SETTINGS JSON----------------------//
        self.readSettingsJsonDictionary()
        // --------------------------------------------------------------- //
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
            isAppEnable = true
        }
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) as? Bool{
            isAppEnable = state
            if state{
                self.checkWindowState()
//                if UserDefaults.standard.object(forKey: kUserdefaultsShowPomodoroView) != nil{//it means app was aborted from morning habit and its time to show pomodoro mode view
//                    UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
//                    if let state = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool{
//                        if state{
//                            showMorningPomodoroModeView()
//                        }
//                    }
//                }
            }else{
                statusbutton?.wantsLayer = true
                statusbutton?.layer?.borderColor = NSColor.red.cgColor
                statusbutton?.layer?.borderWidth = 2
                statusbutton?.layer?.backgroundColor = NSColor.clear.cgColor
                statusbutton?.title = buttonStatusStateOffText
                self.statusbutton?.imagePosition = .imageLeft
//                if UserDefaults.standard.object(forKey: kUserdefaultsShowPomodoroView) != nil{//it means app was aborted from morning habit and its time to show pomodoro mode view
//                    UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
//                    if let state = UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) as? Bool{
//                        if state{
//                            showMorningPomodoroModeView()
//                        }
//                    }
//                }
                addLog(text: "App started in Deactivated state")
            }
        }
        if let date = UserDefaults.standard.object(forKey: kUserdefaults4HourReActivateTime) as? Date{
            if Date().compare(date) == .orderedAscending {
                //first date is smaller than second
                DispatchQueue.global().async {
                    self.timerCheckReactivateTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkFourHourActivateTime), userInfo: nil, repeats: true)
                    RunLoop.current.add(self.timerCheckReactivateTime!, forMode: RunLoop.Mode.common)
                    RunLoop.current.run()
                }
            }else{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                addLog(text: "App Reactivated after 4 hours")
                appdelegate?.quitAndRestartApp()
                return;
            }
            
        }
        
        
        
        // ---------------------------------SET TOP MENU-------------------------------- //
        setTopMenu()
        
        // ---------------------------------FORCE HIDE APP SETUP-------------------------------- //
        let eventMask = NSEvent.EventTypeMask(rawValue: NSEvent.EventTypeMask.keyDown.rawValue)
        
        NSEvent.addLocalMonitorForEvents(
            matching: eventMask,
            handler: { event in
                if event.type == .keyDown {
                    print("Local monitor keyDown")
                    print(event.keyCode)
                    if event.keyCode == 53 {
                        if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.modifierFlags.contains(.control) {
                            if (mainWindowControllerObj?.window!.isVisible)! {
                                self.abortAllProcess()
                                mainWindowControllerObj?.window?.setIsVisible(false)
                            }
                            hideBlankWindowInSecondaryMonitor()
                            print("command contain")
                        }
                    }else if event.keyCode == 36 || event.keyCode == 76{//todo if any change in activity or habits change here
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            if currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                                if currentAction == ._END_{
                                    if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                        if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                            if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                                logQuantityVcObj?.btnOkClicked(self)
                                            }
                                        }else{
                                            if thirdVcObj?.boxBg.isHidden == true{// it means remember next habit is added
                                                if rememberNextHabitVcObj != nil{
                                                    if thirdVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                                                        if rememberNextHabitVcObj?.btnStartNextHabit.isHidden == false{
                                                            rememberNextHabitVcObj?.btnStartNextHabitClicked(self)
                                                        }
                                                    }
                                                }
                                            }else{
                                                if thirdVcObj?.btnMain.isHidden == true{// check if preload focus mode work view visible then enter will bt Button Continue
                                                    if currentState == ._BREATHING_ && thirdVcObj?.customViewContainer.isHidden == false && thirdVcObj?.preloadFocusModesVcObj != nil{
                                                        if thirdVcObj?.customViewContainer.subviews.contains(thirdVcObj!.preloadFocusModesVcObj!.view) ?? false{
                                                            if thirdVcObj?.preloadFocusModesVcObj?.btnContinue.isEnabled == true{
                                                                thirdVcObj?.preloadFocusModesVcObj?.btnContinueClicked(self)
                                                            }
                                                        }
                                                    }
                                                }else{
                                                    thirdVcObj?.btnMainClicked(self)
                                                }
                                            }
                                        }
                                    }
                                    
                                }else if currentAction == ._START_ {
                                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._BREATHING_{
                                        if (mainViewControllerObj?.containerView.subviews.contains(firstViewControllerObj!.view))!{
                                            if !firstViewControllerObj!.isTimerGoingOn{
                                                firstViewControllerObj?.btnStartFirstHabitClicked(self)
                                            }   
                                        }
                                    }else if currentState == ._ACTIVITY_{
                                        if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                            if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                                if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                                    logQuantityVcObj?.btnOkClicked(self)
                                                }
                                            }else{
                                                thirdVcObj?.btnMainClicked(self)
                                            }
                                        }
                                    }
                                }
                            }else if currentState == ._SHUTOFFMAC_{//shutoffmac k casemai last evening over hone per log quantity vala nag shutoff k upar aayga
                                if arrAllEveningHabits.count != 0{
                                    if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                        if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                            logQuantityVcObj?.btnOkClicked(self)
                                        }
                                    }
                                }
                            }
                            //                            if mainViewControllerObj?.containerView.subviews.con
                        }
                    }
                    
                }
                return event
        }
        )
        // ------------------------------------------------------------------------------- //
    }
    
    func setTopMenu(){
        if self.statusItem.button != nil
        {
            statusbutton?.action = #selector(togglePopover(_:))
        }
    }
    @objc func togglePopover(_ sender: Any?) {
        
        if let event = NSApp.currentEvent{
            if event.type ==  NSEvent.EventType.leftMouseUp {
                if isDiscourageDefaultFocusVcVisible{
                    return
                }
                self.statusBarMenu = NSMenu(title: "Status Bar Menu")
                let nItem = NSMenuItem()
                nItem.view = menuViewControllerObj?.view
                nItem.view?.translatesAutoresizingMaskIntoConstraints = false
                menuViewControllerObj!.reloadData()
                self.statusBarMenu.addItem(nItem)
                statusBarMenu.delegate = self
                
                statusItem.menu = statusBarMenu // add menu to button...
                statusItem.button?.performClick(nil) // ...and click
                return;
            } else {
                
            }
        }
        
    }
    func menuWillOpen(_ menu: NSMenu) {
        //        menuViewControllerObj!.reloadData()
        //        self.perform(#selector(reloadMenu), with: nil, with: 1)
    }
    @objc func reloadMenu(){
        //        menuViewControllerObj!.reloadData()
    }
    @objc func menuDidClose(_ menu: NSMenu) {
        statusItem.menu = nil // remove menu so button works as before
    }
    @objc func menuItemEnterLicenseKey(){
        addLog(text: "Showing Activate now view")
        activationWindowControllerObj?.showActivateNowVc()
        activateNowvcObj?.btnback.isHidden = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    @objc func menuItemGetALicenseKey(sender:NSMenuItem){
        activationWindowControllerObj?.showActivateNowVc()
        activateNowvcObj?.btnback.isHidden = true
        purchaseNow_clicked()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    @objc func menuItem_Reactivate(){
        timerCheckReactivateTime?.invalidate()
        timerCheckReactivateTime = nil
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
        UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
        addLog(text: "App Reactivated by user from top menu")
        appdelegate?.quitAndRestartApp()
    }
    @objc func checkFourHourActivateTime(){
        backgroundThread()//7 may 2022 (if you abort Habits, it shouldn't skip the evening routine #56)
        DispatchQueue.main.async {
            if let date  = UserDefaults.standard.object(forKey: kUserdefaults4HourReActivateTime) as? Date{
                if Date().compare(date) == .orderedAscending {
                    //first date is smaller than second
                }else{
                    self.timerCheckReactivateTime?.invalidate()
                    self.timerCheckReactivateTime = nil
                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                    UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                    addLog(text: "App Reactivated after 4 hours")
                    appdelegate?.quitAndRestartApp()
                }
            }else{
                self.timerCheckReactivateTime?.invalidate()
                self.timerCheckReactivateTime = nil
            }
        }
    }
    @objc func checkTwentyFourHourActivateTime(){
        DispatchQueue.main.async {
            if let date  = UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) as? Date{
                if Date().compare(date) == .orderedAscending {
                    //first date is smaller than second
                }else{
                    self.timerCheckClearPasswordTime?.invalidate()
                    self.timerCheckClearPasswordTime = nil
                    UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsAppPassword)
                    addLog(text: "password is cleard after 24 hours")
                }
            }else{
                self.timerCheckClearPasswordTime?.invalidate()
                self.timerCheckClearPasswordTime = nil
            }
        }
    }
    @objc func menuItem_ChangeJson() {
        //        selectJsonWindowControllerObj!.showWindow(self)
        preferencesWindowControllerObj?.showWindow(self)
        if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
            tabview.selectedTabViewItemIndex = 2
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    func quitAndRestartApp(){
        let task = Process()
        var args: [AnyHashable] = []
        args.append("-c")
        args.append("sleep \(1); open \"\(Bundle.main.bundlePath)\"")
        task.launchPath = "/bin/sh"
        task.arguments = args as? [String]
        task.launch()
        
        terminateFromSelf = true
        NSApp.terminate(self)
    }
    
    @objc func showAutoPomodoroModeView(){
        
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        
        if !isAppEnable{
            addLog(text: "App is Disabled: Pomodoro Mode View cancelled")
            return
        }
        if isFocusModeOn(){
            addLog(text: "Focus Mode Is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        if avmonitor.isMicOn() || avmonitor.isACameraOn(){
            addLog(text: "Mic/Camera Is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            self.statusbutton?.title = buttonStatusStateCallText
            self.statusbutton?.imagePosition = .imageLeft
            self.statusbutton?.backgroundcolor = NSColor.systemBlue
            return
        }
        if isPreventUserIdleDisplaySleepOn(){
            addLog(text: "PreventUserIdleDisplaySleep is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        if focusModeStartWindowLodded{
            if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                addLog(text: "focusModeStartWindowLodded .Auto Pomodoro Mode View cancelled")
                setTimerForPomodoroMode(delay: 60*10)
                return
            }
        }
        
        if isShutOffTimeGoing(){
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        pomodoroWindowControllerObj?.contentViewController = pomodoroVcObj
        pomodoroWindowControllerObj?.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    @objc func showMorningPomodoroModeView(){
        
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        
        if isFocusModeOn(){
            addLog(text: "Focus Mode Is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        if avmonitor.isMicOn() || avmonitor.isACameraOn(){
            addLog(text: "Mic/Camera Is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            self.statusbutton?.title = buttonStatusStateCallText
            self.statusbutton?.imagePosition = .imageLeft
            self.statusbutton?.backgroundcolor = NSColor.systemBlue
            return
        }
        if isPreventUserIdleDisplaySleepOn(){
            addLog(text: "PreventUserIdleDisplaySleep is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        
        
        if isShutOffTimeGoing(){
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        if let isEnabled = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                //                get  what da is today and comapre from pomodoro settings
                let cday = getDayOfWeek(fromDate: Date()) ?? kSunday
                
                if let arrDays = UserDefaults.standard.object(forKey: kUserdefaultsHardcorePomodoroArrDays) as? [String]{
                    if arrDays.contains(cday){
                        pomodoroVcObj?.isShowingMorningHardcorePomodoro = true
                    }else{
                        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
                    }
                }else{
                    pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
                }
            }else{
                pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
            }
        }
        
        pomodoroWindowControllerObj?.contentViewController = pomodoroVcObj
        pomodoroWindowControllerObj?.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    @objc func menuShowPomodoroModeView(){
        addLog(text: "Initiating Pomodoro Mode View.")
        
        if isFocusModeOn(){
            addLog(text: "Focus Mode Is On.")
            return
        }
        if focusModeStartWindowLodded{
            if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                addLog(text: "focusModeStartWindowLodded .Pomodoro Mode View cancelled")
                return
            }
        }
        
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        pomodoroWindowControllerObj?.contentViewController = pomodoroVcObj
        pomodoroWindowControllerObj?.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
//    @objc func fakeshowAllHabits(){
//        DispatchQueue.main.async {
//            mainWindowControllerObj?.showWindow(self)
//            mainViewControllerObj!.showAllMorningHabits()
//            showBlankWindowInSecondaryMonitor()
//        }
//
//    }
    
    @objc func checkWindowState(){//there will be no habit display on first day
        //        *****************for testing only *********************
        
        //        isHabitAlreadyShowed = false
        //        startHabitsCall()
        //
        
        //        fakeshowAllHabits()
        //        DispatchQueue.global().async {
        //            self.perform(#selector(self.fakeshowAllHabits), with: nil, afterDelay: 5)
        //        }
        
        
        //        DispatchQueue.global().async {
        //         //   sleep(5)
        //            DispatchQueue.main.async {
        ////                let alert = NSAlert()
        ////                alert.alertStyle = .warning
        ////
        ////                alert.messageText = "dddd"
        ////                alert.runModal()
        //                self.showMeetingStarAlert()
        //            }
        //        }
        //        use this to show AllMorningHabits
        //                mainWindowControllerObj?.showWindow(self)
        //                mainViewControllerObj!.showAllMorningHabits()
        //                showBlankWindowInSecondaryMonitor()
        //  //////
        
        //first time view
        //                mainWindowControllerObj?.showWindow(self)
        //                mainViewControllerObj!.showFirstTimeVc()
        //                isFirstRun = true
        //                showBlankWindowInSecondaryMonitor()
        
        
        //
        //        use this to show All Activities
        //                mainWindowControllerObj?.showWindow(self)
        //                mainViewControllerObj?.startBreakActivities()
        //                showBlankWindowInSecondaryMonitor()
        //  //////////
        
        
        //        shutOffMac()
        //        setShutOffTimer()
        
        //        showPomodoroModeView()
        
        //                  Showing focus summary
        //        mainWindowControllerObj?.showWindow(self)
        //        mainViewControllerObj?.showFocusSummaryView()
        //        showBlankWindowInSecondaryMonitor()
        //  //////////
        
        //        showPomodoroModeView()
        //                shutoff window
        //                mainWindowControllerObj?.showWindow(self)
        //                mainViewControllerObj?.shutOffMac()
        
        //show evening habits
        //                mainWindowControllerObj?.showWindow(self)
        //                mainViewControllerObj?.showAllEveningHabits()
        //                showBlankWindowInSecondaryMonitor()
        
        // show top timer window
        //        showSmallTimerWindow(durationSeconds: 30, name: "yogaa")
        
        //        showMorningPomodoroModeView()
        //                        return; //todo®
        //        *******************************************************************
        
        
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj!.showFirstTimeVc()
            isFirstRun = true
            
            
            
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            // changed 13/5/2022 // jis din app install hui h us din morning habit i aaygi bhale hi kitni hi bar app quit krke chalu krle(iske liya afirst time habit k time hi morning routine ki show date likhva lenege fir us din date write ho chuki h to morning habit ni aaygi +)
            
            //  isHabitAlreadyShowed ko kuch ni krna h qki default hi true h ..
            
            
            
            
            
        }else{
            isFirstRun = false
            if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
                
                checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
            }else{
                isHabitAlreadyShowed = false
            }
            
            if startTime != nil && shutOffTime != nil{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                
                if isShutOffTimeGoing(){
                    if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                        if currentState != ._SHUTOFFMAC_{
                            self.shutOffMac()
                        }
                    }else{
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                            if Date().compare(date) == .orderedDescending {
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                            }
                        }
                    }
                }else{
                    if !isHabitAlreadyShowed{
                        
                        if Date().compare(startDate) == .orderedAscending {
                            print("First Date is smaller then second date. all ok ")
                        }else{
                            self.startHabitsCall()
                        }
                    }else{
                        mainWindowControllerObj?.loadWindow()
                        mainViewControllerObj?.setActivityTimer()
                    }
                }
            }
            setBackgroundThreadTimer()
        }
        
    }
    
    func checkLastHabitShowDate(lastHabitShowDate:Date){
        isHabitAlreadyShowed = true
        let year1 = Calendar.current.component(.year, from: lastHabitShowDate)
        let year2 = Calendar.current.component(.year, from: Date())
        
        
        
        if year2>year1{
            isHabitAlreadyShowed = false
        }else{
            if year1 == year2{
                let month1 = Calendar.current.component(.month, from: lastHabitShowDate)
                let month2 = Calendar.current.component(.month, from: Date())
                if month2>month1{
                    isHabitAlreadyShowed = false
                }else{
                    if month1 == month2{
                        let day1 = Calendar.current.component(.day, from: lastHabitShowDate)
                        let day2 = Calendar.current.component(.day, from: Date())
                        if day2>day1{
                            isHabitAlreadyShowed = false
                        }
                    }
                }
            }
        }
    }
    
    
    func setBackgroundThreadTimer(){
        DispatchQueue.global().async {
            self.timerBackgroundThread = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.backgroundThread), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timerBackgroundThread!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
    }
    var alertSuggestFocusMode:NSAlert?
    var isUserOnMeeting = false
    var isAutoMeetingsModeStarted = false
    var appUsedInAutoMeetingFocusMode = ""
    func checkIsMeetingsGoingOn(){
        
        if avmonitor.isMicOn() || avmonitor.isACameraOn(){
            if isFocusModeOn(){
                return;
            }
            addLog(text: "Mic/Camera Is On")
            self.statusbutton?.title = buttonStatusStateCallText
            self.statusbutton?.imagePosition = .imageLeft
            self.statusbutton?.backgroundcolor = NSColor.systemBlue
            
            if alertSuggestFocusMode != nil{
                if alertSuggestFocusMode!.window.isVisible{
                    return
                }
            }
            let runningApps = NSWorkspace.shared.runningApplications
            
            
            for i in 0..<arrFocusType.count{
                let focus = arrFocusType[i]
                if let state = focus["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        if let arr = focus["appsArray"] as? [String]{
                            for apppPath in arr{
                                for app in runningApps{
                                    if let appUrl = app.bundleURL{
                                        let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                                        let url = URL(fileURLWithPath: apppPath)
                                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                            
                                            if isUserOnMeeting{
                                                return
                                            }
                                            appUsedInAutoMeetingFocusMode = url.lastPathComponent
                                            isUserOnMeeting = true
                                            
                                            timerMeetingStartAlert?.invalidate()
                                            timerMeetingStartAlert = nil
                                            
                                            timerMeetingStartAlert = Timer.scheduledTimer(timeInterval: 120, target: self, selector: #selector(self.showMeetingStarAlert), userInfo: nil, repeats: false) //no need run loop// 
                                            return;
                                        }
                                    }
                                }
                            }
                        }
                        isUserOnMeeting = false
                        break;
                    }
                }
            }
            
        }else{
            if isAutoMeetingsModeStarted{//end meetings focus mode
                if isFocusModeOn(){
                    focusModeFinished(fromShutOff: false)
                }
            }
            if isUserOnMeeting{
                isUserOnMeeting = false
            }
            self.statusbutton?.title = ""
            self.statusbutton?.backgroundcolor = NSColor.clear
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil
            
            
            
            for dic in arrFocusType{
                if dic["isOn"] as? Bool == true{
                    appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: dic["color"] as? String ?? "")
                    appdelegate!.statusbutton?.title = buttonStatusStateFocusText
                    appdelegate!.statusbutton?.imagePosition = .imageLeft
                }
            }
        }
        
    }
    var timerMeetingStartAlert:Timer?
    @objc func showMeetingStarAlert(){
        timerMeetingStartAlert?.invalidate()
        timerMeetingStartAlert = nil
        
//        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._SHUTOFFMAC_ || currentState == .
        
        
        // Luisa App broken bug fix 28/6/22
        if mainWindowControllerObj?.window?.isVisible ?? false{
            addLog(text: "Meeting suggestion aborted due to activity.")
            return
        }
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_{
            addLog(text: "Meeting suggestion aborted due to activity.")
            return
        }
        
        //  ////////////
        
        for i in 0..<arrFocusType.count{
            let focus = arrFocusType[i]
            if let state = focus["isMeetings"] as? Bool{
                if  state{
                    
                    alertSuggestFocusMode = NSAlert()
                    if let state = UserDefaults.standard.object(forKey: kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                        if state{
                            alertSuggestFocusMode!.window.sharingType = .none
                        }
                    }
                    var title = "It looks like you're in a meeting. Will you need to use other apps during the meeting? If not, I can block everything else to help you concentrate."
                    var subTitle = "On selecting \"Block everything else\" the app will start \"Meetings\" focus mode."
                    var buttonBlockText = "Block everything else"
                    var buttonCancelText = "It's ok for me to use other apps during this meeting"
                    
                    if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                        if let suggestFocusInfo = focusInfo.value(forKey: "suggestFocusInfo") as? NSDictionary{
                            if let val = suggestFocusInfo.value(forKey: "title") as? String{
                                title = val
                            }
                            if let val = suggestFocusInfo.value(forKey: "subTitle") as? String{
                                subTitle = val
                            }
                            if let val = suggestFocusInfo.value(forKey: "buttonBlockText") as? String{
                                buttonBlockText = val
                            }
                            if let val = suggestFocusInfo.value(forKey: "buttonCancelText") as? String{
                                buttonCancelText = val
                            }
                        }
                    }
                    
                    alertSuggestFocusMode?.messageText = title
                    alertSuggestFocusMode?.informativeText = subTitle
                    alertSuggestFocusMode?.addButton(withTitle: buttonBlockText)
                    alertSuggestFocusMode?.addButton(withTitle: buttonCancelText)
                    
                    if let result = alertSuggestFocusMode?.runModal(){
                        if result == .alertFirstButtonReturn{
                            print("first")
                            
                            if getEndFocusModeWindowControllerObj().window!.isVisible{
                                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                                addEntryInCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "")
                                getEndFocusModeWindowControllerObj().window?.close()
                            }
                            let calendar = Calendar.current
                            endFocusModeTime = calendar.date(byAdding: .minute, value: 5, to: Date())
                            startFocusModeTime = Date()
                            arrFocusType[i]["isOn"] = true
                            runAppleScriptBeforeFocusBeginIfAvailable(index: i)
                            focusModeMinutesToPerform = 0
//                            if focusPreferencesVcObj != nil{
//                                if (preferencesWindowControllerObj?.window!.isVisible)!{
//                                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                                        if tabview.selectedTabViewItemIndex == 1{
//                                            focusPreferencesVcObj?.focusModeStarted()
//                                        }
//                                    }
//                                }
//                            }
                            appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[i]["color"] as? String ?? "")
                            appdelegate!.statusbutton?.title = buttonStatusStateFocusText
                            appdelegate!.statusbutton?.imagePosition = .imageLeft
                            if timerForFocusMode != nil{
                                timerForFocusMode?.invalidate()
                                timerForFocusMode = nil
                            }
                            isFocusTimeType = ._HOUR_
                            //                                                appdelegate?.setFocusModeTimer(hour: nil, minute: totoalMinutes)
                            isFocusModeStartedFromPomodoroMode = false
                            appdelegate!.focusModeStartted()
                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                            whatToAchieveInFocusBlock = ""
                            
                            if isPomodoroWindowLodded{
                                if pomodoroWindowControllerObj!.window!.isVisible{
                                    pomodoroWindowControllerObj?.window?.close()
                                }
                            }
                            if focusModeStartWindowLodded{
                                if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                                    startingFocusWindowControllerObj?.window?.close()
                                    return
                                }
                            }
                            alertSuggestFocusMode = nil
                            isAutoMeetingsModeStarted = true
                        }else{
                            print("second")
                            alertSuggestFocusMode = nil
                        }
                    }
                }
            }
        }
        
    }
    @objc func backgroundThread(){
        
//        print(NSApp.keyWindow)
        DispatchQueue.main.async {
            
            
            if isAppEnable{// agar app diable hai to sirf 1 case mai ye func call hoga jab app 4 hour deactivate h tb
                self.checkIsMeetingsGoingOn() //and app kon kon si check krni haiu
            }
            
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            let currentDate = Date()
            
            /// 5  may 2022 (5 minute warning before shutdown time "It's time to wrap up for the day. Your shutdown time is in 5 minutes.")#62
            let fiveMinutesBeforeShutOffTime = shutOffdate.addingTimeInterval(-5 * 60)
            let sixtyFiveSecondsBeforeShutOffTime = fiveMinutesBeforeShutOffTime.addingTimeInterval(-5)
            
            if currentDate.compare(fiveMinutesBeforeShutOffTime) == .orderedAscending  && currentDate.compare(sixtyFiveSecondsBeforeShutOffTime) == .orderedDescending{
                var shutdownNotificationTitle = "It's time to wrap up for the day. Your shutdown time is in 5 minutes."
                
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    shutdownNotificationTitle = common.value(forKey: "shutdownNotificationTitle") as? String ?? shutdownNotificationTitle
                }
                
                showNotificationWithMessage(msg: shutdownNotificationTitle)
                
            }
            //  ////////////////
            
            
            
            
            
            
            if isShutOffTimeGoing(){
                if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                    if currentState != ._SHUTOFFMAC_{
                        self.shutOffMac()
                    }
                }else{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                        if Date().compare(date) == .orderedDescending {
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                        }
                    }
                }
                
            }else{
                
                if isAppEnable{//7 may 2022 (if you abort Habits, it shouldn't skip the evening routine #56)//this func is callimng even if app is disable but morning habit will not execute if app is diable 
                    if !isHabitAlreadyShowed{
                        if Date().compare(startDate) == .orderedAscending {
                            print("First Date is smaller then second date. all ok ")
                            //first date is smaller than second
                        }else{
                            self.abortAllProcess()
                            self.startHabitsCall()
                            // return;
                        }
                    }else{
                        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
                            self.checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
                        }
                    }
                }
                
            }
            
            //}
        }
    }
    //    @objc func setShutOffTimer(){
    //        if shutOffTime != nil{
    //            let date = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    //            if Date().compare(date) == .orderedAscending {
    //                print("First Date is smaller then second date. all ok ")
    //                let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(shutOffMac), userInfo: nil, repeats: false)
    //                RunLoop.main.add(timer, forMode: .common)
    //            }
    //        }
    //    }
    @objc func shutOffMac(){
        isHabitAlreadyShowed = false
        addLog(text: "Initiating shut off process.")
        
        //        if avmonitor.isMicOn(){// 5 may 2022 (Mic/camera shouldn't prevent shutdown #62)
        //            addLog(text: "Mic is in use, Shut off Cancelled.")
        //            return;
        //        }
        //        if avmonitor.isACameraOn(){
        //            addLog(text: "Camera is in use, Shut off Cancelled.")
        //            return;
        //        }
        //
        //        if isPreventUserIdleDisplaySleepOn(){
        //            addLog(text: "PreventUserIdleDisplaySleep is On: Shut off Cancelled")
        //            return
        //        }
        
        if currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_SUMMARY_{////_FOCUS_COMPLETED_()
            if currentState == ._EVENING_HABIT_{
                addLog(text: "current state is :- evening habits")
            }
                //            else if currentState == ._FOCUS_COMPLETED_{
                //                addLog(text: "current state is :- focus completed view")
                //            }
            else if currentState == ._FOCUS_SUMMARY_{
                addLog(text: "current state is :- focus summary")
            }
            return;
        }
        
        //  ************* solving evening routine abort bug 2/3/22
        //agar svenening routine abort krte h to abort state ho jati h or abbort state yha cancel hkar vapas shut off show ho jata h . to use handle krenege
        // agar abort state h  or shutOff time nikl chuka hai or evening routing show h chuki h to abort state hi rhne denge  or return kr denege
        
        if currentState == ._ABORT_{
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                if Date().compare(date) == .orderedDescending {
                    
                }else{
                    //Evening habits already shown for today
                    return;
                }
            }
        }
        
        
        //  **************
        
        abortAllProcess()
        if isFocusModeOn(){
            focusModeFinished(fromShutOff: true)
//            if focusPreferencesVcObj != nil{
//                if (preferencesWindowControllerObj?.window!.isVisible)!{
//                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                        if tabview.selectedTabViewItemIndex == 1{
//                            focusPreferencesVcObj?.focusModeFinished()
//                        }
//                    }
//                }
//            }
            
        }
        //        var iseveningHabitAlreadyShowed = true
        //        if let eveningRoutineDate = getEveningRoutineDate(){
        //            iseveningHabitAlreadyShowed = true
        //            let year1 = Calendar.current.component(.year, from: eveningRoutineDate)
        //            let year2 = Calendar.current.component(.year, from: Date())
        //
        //
        //
        //            if year2>year1{
        //                iseveningHabitAlreadyShowed = false
        //            }else{
        //                if year1 == year2{
        //                    let month1 = Calendar.current.component(.month, from: eveningRoutineDate)
        //                    let month2 = Calendar.current.component(.month, from: Date())
        //                    if month2>month1{
        //                        iseveningHabitAlreadyShowed = false
        //                    }else{
        //                        if month1 == month2{
        //                            let day1 = Calendar.current.component(.day, from: eveningRoutineDate)
        //                            let day2 = Calendar.current.component(.day, from: Date())
        //                            if day2>day1{
        //                                iseveningHabitAlreadyShowed = false
        //                            }
        //                        }
        //                    }
        //                }
        //            }
        //        }else{
        //            iseveningHabitAlreadyShowed = false
        //        }
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date == nil{
            if !(mainWindowControllerObj?.window!.isVisible)! {
                mainWindowControllerObj?.showWindow(self)
            }
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj!.showFocusSummaryView()
            focusSummaryVcObj!.btnNeedMoreTime.isHidden = false// first time show hoga button lekin jesi hi "need 1 more minute" per click hoga buttton hide ho jayga fir next day hi show hoga 
            return;
        }else{
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date{
                if Date().compare(date) == .orderedDescending {
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsFocusSummaryShowedTillDate)
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                    }
                    showBlankWindowInSecondaryMonitor()
                    mainViewControllerObj!.showFocusSummaryView()
                    return;
                }else{
                    addLog(text: "Focus Summary already shown for today - skipping.")
                }
            }
        }
        
        if arrAllEveningHabits.count != 0{//} && !iseveningHabitAlreadyShowed {
            if UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date == nil{
                //            if currentState != ._SHUTOFFMAC_{
                if !(mainWindowControllerObj?.window!.isVisible)! {
                    mainWindowControllerObj?.showWindow(self)
                }
                showBlankWindowInSecondaryMonitor()
                mainViewControllerObj!.showAllEveningHabits()
                return;
                //}
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                    if Date().compare(date) == .orderedDescending {
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsEveningHabitsShowedTillDate)
                        if !(mainWindowControllerObj?.window!.isVisible)! {
                            mainWindowControllerObj?.showWindow(self)
                        }
                        showBlankWindowInSecondaryMonitor()
                        mainViewControllerObj!.showAllEveningHabits()
                        return;
                    }else{
                        addLog(text: "Evening habits already shown for today - skipping.")
                    }
                }
                
                
                
            }
        }
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        mainViewControllerObj!.shutOffMac()
        showBlankWindowInSecondaryMonitor()
    }
    
    func abortAllProcess(){
        addLog(text: "call abort all process.")
        if (mainWindowControllerObj?.window!.isVisible)! {
            if currentAction == ._INPROGRESS_{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
                            enableSystemSleep()
                            if timerViewcontrollerObj?.webView.isHidden == false{
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func startHabitsCall(){
        //        if currentState == ._SHUTOFFMAC_{
        //            return;
        //        }
        addLog(text: "Initiating morning habits.")
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
        checkTrialExpire()
        if avmonitor.isMicOn(){
            mainWindowControllerObj?.loadWindow()
            mainViewControllerObj?.setActivityTimer()
            addLog(text: "Mic is in use, Morning Habits cancelled.")
            self.statusbutton?.title = buttonStatusStateCallText
            self.statusbutton?.imagePosition = .imageLeft
            self.statusbutton?.backgroundcolor = NSColor.systemBlue
            return;
        }
        if avmonitor.isACameraOn(){
            mainWindowControllerObj?.loadWindow()
            mainViewControllerObj?.setActivityTimer()
            addLog(text: "Camera is is use, Morning Habits cancelled.")
            self.statusbutton?.title = buttonStatusStateCallText
            self.statusbutton?.imagePosition = .imageLeft
            self.statusbutton?.backgroundcolor = NSColor.systemBlue
            return;
        }
        
        if isPreventUserIdleDisplaySleepOn(){
            mainWindowControllerObj?.loadWindow()
            mainViewControllerObj?.setActivityTimer()
            addLog(text: "PreventUserIdleDisplaySleep is On: Morning Habits cancelled.")
            return
        }
        
        //        if let morningRoutineDate = getMorningRoutineDate(){
        //            checkLastHabitShowDate(lastHabitShowDate: morningRoutineDate)
        //        }
        if isHabitAlreadyShowed{
            return;
        }
        if arrAllMorningHabits.count != 0 {
            isHabitAlreadyShowed = true
            mainWindowControllerObj?.showWindow(self)
            mainViewControllerObj!.showAllMorningHabits()
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            
            //            writeMorningRoutineDate()
            showBlankWindowInSecondaryMonitor()
        }
    }
    
    func checkTrialExpire(){
        if isPurchased == true{
            return;
        }
        if let date = UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) as? Date{
            let secondsBetween = Date().timeIntervalSince(date)
            let numberOfDays_afterinstall = Int((secondsBetween) / 86400)
            var daysremaining = daysFreeTrial-numberOfDays_afterinstall
            if daysremaining < 0 {
                daysremaining = 0
            }
            if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                daysremaining = 0
            }
            if daysremaining == 0{//if expired than menu is enabled
                UserDefaults.standard.set(true, forKey: "trialExpired")
                quitAndRestartApp()
            }
        }
    }
    @objc func menuItem_Preferences() {
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            return;
        }
        preferencesWindowControllerObj?.showWindow(self)
        addLog(text: "Showing preferences")
        
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = 0
                tabview.view.addSubview(enterPasswordVcObj!.view)
                tabview.view.addConstraints(subView: enterPasswordVcObj!.view)
                addLog(text: "Showing enter password view")
            }
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    @objc func menuItem_ExportStatistics() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.prompt = "Export"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            openPanel.prompt = common.value(forKey: "buttonExportText") as? String ?? "Export"
        }
        
        let button: NSApplication.ModalResponse = openPanel.runModal()
        if button == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                let filemanager = FileManager.default
                let destUrl = url.appendingPathComponent(quantityCsvURL.lastPathComponent)
                if filemanager.fileExists(atPath: destUrl.path){
                    do{
                        try filemanager.removeItem(at: destUrl)
                    }catch{
                        print(error)
                    }
                }
                
                do{
                    try FileManager.default.copyItem(at: quantityCsvURL, to: destUrl)
                }catch{
                    print(error)
                }
            }
        }
    }
    
    @objc func menuItem_Quit() {
        addLog(text: "App quit clicked by user")
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        terminateFromSelf = true
        NSApp.terminate(self)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        addLog(text: "Application Will Terminate")
        print("applicationWillTerminate")
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        print("applicationShouldTerminate")
        if terminateFromSelf {
            terminateFromSelf = false
            return .terminateNow
        }else {
            return .terminateCancel
        }
    }
    
    func setFocusModeTimer(hour:Int?, minute:Int?){
        DispatchQueue.global().async {
            focusModeMinutesToPerform = minute ?? 0
            
            //hour ni aayga kabhi . minut hi beje hai
            
            if timerForFocusMode != nil{
                timerForFocusMode?.invalidate()
            }
            var time = 0
            if hour != nil{
                time = hour!*60*60
            }else if minute != nil{
                time = minute!*60
            }else{
                time = 60*60
            }
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = time
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(time), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.current.add(timerForFocusMode!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
    }
    
    func focusModeAborted(){
        addLog(text: "focus mode Aborted")
        endFocusModeTime = nil
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        focusModeActualDurationPerformed = Int(Date().timeIntervalSince(startFocusModeTime ?? Date()))
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                runAppleScriptAfterFocusEndIfAvailable(index: i)
                break;
            }
        }
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            self.statusbutton?.backgroundcolor = NSColor.clear
            self.statusbutton?.title = ""
        }
        
        isFocusTimeType = ._NONE_
        if self.timerAllowUrl != nil{
            self.timerAllowUrl!.invalidate()
            //self.timerAllowUrl = nil
            print("invalidtate")
        }
        timerCheckAllowedApps?.invalidate()
        
        
        isAutoMeetingsModeStarted = false
        appUsedInAutoMeetingFocusMode = ""
    }
    @objc func focusModeTimerFinished(){
//        DispatchQueue.main.async {
//            if focusPreferencesVcObj != nil{
//                if (preferencesWindowControllerObj?.window!.isVisible)!{
//                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//                        if tabview.selectedTabViewItemIndex == 1{
//                            focusPreferencesVcObj?.focusModeFinished()
//                        }
//                    }
//                }
//            }
//        }
        focusModeFinished(fromShutOff: false)
    }
    @objc func focusModeFinished(fromShutOff:Bool){
        
        
        
        addLog(text: "focus mode finished")
        endFocusModeTime = nil
        print("focus mode finished")
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        
        
        focusModeActualDurationPerformed = Int(Date().timeIntervalSince(startFocusModeTime ?? Date()))
        
        var currentFocusModeName = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
                runAppleScriptAfterFocusEndIfAvailable(index: i)
                break;
            }
        }
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            if isPomodoroWindowLodded{
                if pomodoroWindowControllerObj!.window!.isVisible{
                    pomodoroWindowControllerObj?.window?.close()
                }
            }
            
            self.statusbutton?.backgroundcolor = NSColor.clear
            self.statusbutton?.title = ""
        }
        
        isFocusTimeType = ._NONE_
        if self.timerAllowUrl != nil{
            self.timerAllowUrl!.invalidate()
            //self.timerAllowUrl = nil
            print("invalidtate")
        }
        timerCheckAllowedApps?.invalidate()
        
        //        DispatchQueue.main.async {
        if self.isAutoMeetingsModeStarted{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "Meeting using {\(self.appUsedInAutoMeetingFocusMode)}", distractionsEncountered: "", abortReason: "", feedback: "")
        }else{
            if fromShutOff{
                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
            }else{
                DispatchQueue.main.async {
                    self.showFocusCompletedView()
                    focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
            
            //            }
            
            
            self.isAutoMeetingsModeStarted = false
            self.appUsedInAutoMeetingFocusMode = ""
        }
        
    }
    func showFocusCompletedView(){
        getEndFocusModeWindowControllerObj().contentViewController = focusCompletedVcObj
        getEndFocusModeWindowControllerObj().window?.styleMask.remove(.closable)
        getEndFocusModeWindowControllerObj().showWindow(self)
    }
    @objc func focusModeStartted(){
        isAutoMeetingsModeStarted = false
        
        var stringTime = ""
        
        if let date = endFocusModeTime{
            stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
        }
        addLog(text: "focus mode Started until - \(stringTime)")
        fillAllowUrlArray()
        fillAllowAppArray()
        arrNotificationShownForApps.removeAll()
        frontApplicationChanged()//ak bar khud hi call krdenge qki phle se bhi active ho skti h
        
        DispatchQueue.global().async {
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkAllowedApp), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timerCheckAllowedApps!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
        //        if isPomodoroWindowLodded{
        //            if pomodoroWindowControllerObj!.window!.isVisible{
        //                pomodoroWindowControllerObj?.window?.close()
        //            }
        //        }
    }
    
    func fillAllowUrlArray(){
        isAllowedAllUrlsInFocus = false
        arrAllowedUrlsForFocus.removeAll()
        arrBlockedUrlsForFocus.removeAll()
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                if dic["isAllowedAllUrls"] as? Bool == true{
                    isAllowedAllUrlsInFocus = true
                }
                arrAllowedUrlsForFocus = dic["urlsArray"] as? [String] ?? []
                arrBlockedUrlsForFocus = dic["blockUrlsArray"] as? [String] ?? []
            }
        }
        //        arrAllowedUrlsForFocus.append("eyst-focus.html")
        //        arrAllowedUrlsForFocus.append("earnyourscreentime.com")
        //        arrAllowedUrlsForFocus.append("devtools://")
        //        arrAllowedUrlsForFocus.append("chrome-extension://")
    }
    //
    func fillAllowAppArray(){
        isAllowedAllAppsInFocus = false
        allowAppsPath.removeAll()
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                if dic["isAllowedAllApps"] as? Bool == true{
                    isAllowedAllAppsInFocus = true
                }
                allowAppsPath = dic["appsArray"] as? [String] ?? []
            }
        }
    }
    
    var timerAllowUrl:Timer?
    var timerCheckAllowedApps:Timer?
    var timerAllowUrlForActivity:Timer?
    var timerAllowAppForActivity:Timer?
    var timerBlockUrl:Timer?//block urls list
    
    @objc func frontApplicationChanged(){
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            print(runningApp.localizedName)//ScreenSaverEngine
        }
        timerBlockUrl?.invalidate()
        timerAllowUrlForActivity?.invalidate()
        if currentState == ._ACTIVITY_ && currentAction == ._INPROGRESS_ && currentActivityPlaying != nil{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                print(runningApp.localizedName)
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    DispatchQueue.global().sync {
                        if currentActivityPlaying != nil{
                            var isAppAllowed = false
                            
                            if nameLowercased == "finder" || nameLowercased == selfAppName.lowercased(){
                                isAppAllowed = true
                            }else{
                                for appName in currentActivityPlaying!.allowApps{
                                    if appName.lowercased() == nameLowercased{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                                if !isAppAllowed{
                                    for appName in activityAllowedFocusApps{
                                        if appName.lowercased() == nameLowercased{
                                            isAppAllowed = true
                                            break;
                                        }
                                    }
                                }
                            }
                            if !isAppAllowed{
                                runningApp.hide()
                                return
                            }
                            if nameLowercased == "safari" || nameLowercased == "google chrome"{
                                timerAllowUrlForActivity?.invalidate()
                                self.timerAllowUrlForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkInBackgroundForActivity), userInfo: nil, repeats: true)
                                RunLoop.main.add(self.timerAllowUrlForActivity!, forMode: RunLoop.Mode.common)
                            }
                        }
                    }
                }
            }
            
            
        }else if (currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_) && currentAction == ._INPROGRESS_ && currentHabitPlaying != nil{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                print(runningApp.localizedName)
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    DispatchQueue.global().sync {
                        if currentHabitPlaying != nil{
                            var isAppAllowed = false
                            
                            if nameLowercased == "finder" || nameLowercased == selfAppName.lowercased(){
                                isAppAllowed = true
                            }else{
                                for appName in currentHabitPlaying!.allowApps{
                                    if appName.lowercased() == nameLowercased{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                                if !isAppAllowed{
                                    for appName in activityAllowedFocusApps{
                                        if appName.lowercased() == nameLowercased{
                                            isAppAllowed = true
                                            break;
                                        }
                                    }
                                }
                                
                            }
                            
                            
                            if !isAppAllowed{
                                runningApp.hide()
                                return
                            }
                            if nameLowercased == "safari" || nameLowercased == "google chrome"{
                                timerAllowUrlForActivity?.invalidate()
                                self.timerAllowUrlForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkInBackgroundForActivity), userInfo: nil, repeats: true)
                                RunLoop.main.add(self.timerAllowUrlForActivity!, forMode: RunLoop.Mode.common)
                            }
                        }
                    }
                }
            }
        }else if isFocusModeOn(){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    var isAppAllowed = false
                    
                    if isAllowedAllAppsInFocus{
                        isAppAllowed = true
                    }else{
                        
                        if nameLowercased == "finder" || nameLowercased == selfAppName.lowercased(){
                            isAppAllowed = true
                        }else{
                            for path in self.allowAppsPath{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                        }
                    }
                    
                    if !isAppAllowed{
                        runningApp.hide()
                        showFocusAppBlockNotification(appName: name)
                        
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                            print("invalidtate")
                        }
                        return
                    }
                    DispatchQueue.global().sync {
                        if nameLowercased == "safari" || nameLowercased == "google chrome"{
                            print("validtate")
                            self.timerAllowUrl?.invalidate()
                            if self.timerAllowUrl != nil{
                                if self.timerAllowUrl!.isValid{
                                    print("************************************* timer is not invalid")
                                    addLog(text: "timerAllowUrl is not invalid")
                                    self.timerAllowUrl?.invalidate()
                                }
                            }
                            self.timerAllowUrl = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkInBackground), userInfo: nil, repeats: true)
                            RunLoop.main.add(self.timerAllowUrl!, forMode: RunLoop.Mode.common)
                            
                        }
                    }
                    //                    }
                }
            }
            
        }else{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                print(runningApp.localizedName)
                if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    DispatchQueue.global().sync {
                        
                        if nameLowercased == "safari" || nameLowercased == "google chrome"{
                            timerBlockUrl?.invalidate()
                            self.timerBlockUrl = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.blockUrlsInBackground), userInfo: nil, repeats: true)
                            RunLoop.main.add(self.timerBlockUrl!, forMode: RunLoop.Mode.common)
                        }
                        //                        }
                        
                    }
                }
            }
        }
    }
    func showFocusAppBlockNotification(appName:String){
        
        if arrNotificationShownForApps.contains(appName){
            return;
        }
        let arrAppsAvoidNotification = ["loginwindow", "screensaverengine"]//lowercased
        //        if appName.lowercased() == "loginwindow"{
        //            return;
        //        }
        if arrAppsAvoidNotification.contains(appName.lowercased()){
            return;
        }
        arrNotificationShownForApps.append(appName)
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
        
        msg = msg.replacingOccurrences(of: "<APP_NAME>", with: appName)
        msg = msg.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
        showNotificationWithMessage(msg: msg)
    }
    @objc func blockUrlsInBackground(){
        if isFocusModeOn(){
            timerBlockUrl?.invalidate()
            return
        }
        
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let name = runningApp.localizedName{
                var script: String = ""
                if name.lowercased() == "safari"{
                    if var url = self.getSafariActiveTabUrl(){
                        print(url)
                        if !url.contains("favorites:") && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
                            let domain = getDomainFromUrl(url: url)
                            
                            var bool = false
                            for turl in arrBlockedUrls{
                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                if bool{
                                    break;
                                }
                            }
                            if bool{
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                script =
                                """
                                tell application "Safari"
                                set the_wnd to front window
                                set active_tab to current tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                            }else{
                                return;
                            }
                        }else{
                            return;
                        }
                        
                    }else{
                        return;
                    }
                    
                }else if name.lowercased() == "google chrome"{
                    if var url = self.getGoogleChromeActiveTabUrl(){
                        print(url)
                        if !url.contains("chrome:") && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
                            let domain = getDomainFromUrl(url: url)
                            
                            var bool = false
                            for turl in arrBlockedUrls{
                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                if bool{
                                    break;
                                }
                            }
                            if bool{
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                script =
                                """
                                tell application "Google Chrome"
                                set the_wnd to front window
                                set active_tab to active tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                            }else{
                                return
                            }
                        }else{
                            return
                        }
                    }else{
                        return
                    }
                    
                    
                }else{
                    self.timerAllowUrl?.invalidate()
                }
                //--if URL of the_tab is equal to "https://www.apple.com/" then
                if script.isEmpty{
                    return
                }
                if let appleScript = NSAppleScript(source: script) {
                    
                    var errors : NSDictionary? = nil
                    appleScript.executeAndReturnError(&errors)
                    if errors != nil {
                        
                        //var test = errors?.count
                        print(errors)
                    }
                    //let descriptor = error.descriptorType
                }
            }
        }
    }
    
    @objc func checkAllowedApp(){
        if isAllowedAllAppsInFocus{
            return;
        }
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                print(name)
                var isAppAllowed = false
                if name == "finder" || name == selfAppName.lowercased(){
                    isAppAllowed = true
                }else{
                    for path in self.allowAppsPath{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                            isAppAllowed = true
                            break;
                        }
                    }
                }
                
                if !isAppAllowed{
                    runningApp.hide()
                    showFocusAppBlockNotification(appName:appUrl.deletingPathExtension().lastPathComponent)
                    
                    if self.timerAllowUrl != nil{
                        self.timerAllowUrl!.invalidate()
                        print("invalidtate22")
                    }
                    return
                }
                
            }
        }
    }
    
    func startTimerActivitiesAllowedApp(){
        DispatchQueue.global().async {
            self.timerAllowAppForActivity?.invalidate()
            self.timerAllowAppForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkActivityAllowedApp), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timerAllowAppForActivity!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
        
        if currentState == ._ACTIVITY_{
            
            for appName in activityAllowedFocusApps{
                NSWorkspace.shared.launchApplication(appName)
            }
            
            if let apps = currentActivityPlaying?.allowApps{
                for app in apps{
                    NSWorkspace.shared.launchApplication(app)
                }
                if apps.count != 0{
                    if let app = apps.first{
                        NSWorkspace.shared.launchApplication(app)// isliye kiya taki first app sabse upar aa jay
                    }
                }else{
                    if let app = activityAllowedFocusApps.first{
                        NSWorkspace.shared.launchApplication(app)
                    }
                }
            }
            if let urls = currentActivityPlaying?.allowUrls{
                if urls.count != 0{
                    if var url = urls.first{
                        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                            url = "http://"+url
                        }
                        NSWorkspace.shared.open(URL(string: url)!)
                    }
                }else{
                    if var url = activityAllowedFocusUrls.first{
                        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                            url = "http://"+url
                        }
                        NSWorkspace.shared.open(URL(string: url)!)
                    }
                }
            }
        }else if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_{
            for appName in activityAllowedFocusApps{
                NSWorkspace.shared.launchApplication(appName)
            }
            if let apps = currentHabitPlaying?.allowApps{
                for app in apps{
                    NSWorkspace.shared.launchApplication(app)
                }
                if apps.count != 0{
                    if let app = apps.first{
                        NSWorkspace.shared.launchApplication(app)
                    }
                }else{
                    if let app = activityAllowedFocusApps.first{
                        NSWorkspace.shared.launchApplication(app)
                    }
                }
            }
            
            
            
            if let urls = currentHabitPlaying?.allowUrls{
                if urls.count != 0{
                    if var url = urls.first{
                        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                            url = "http://"+url
                        }
                        NSWorkspace.shared.open(URL(string: url)!)
                    }
                }else{
                    if var url = activityAllowedFocusUrls.first{
                        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                            url = "http://"+url
                        }
                        NSWorkspace.shared.open(URL(string: url)!)
                    }
                }
            }
            
        }
    }
    
    @objc func checkActivityAllowedApp(){
        if currentState == ._ACTIVITY_ && currentAction == ._INPROGRESS_ && currentActivityPlaying != nil{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    print(name)
                    if currentActivityPlaying != nil{
                        var isAppAllowed = false
                        if name == "finder" || name == selfAppName.lowercased(){
                            isAppAllowed = true
                        }else{
                            for appName in currentActivityPlaying!.allowApps{
                                if appName.lowercased() == name{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                            
                            if !isAppAllowed{
                                for appName in activityAllowedFocusApps{
                                    if appName.lowercased() == name{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                            }
                            
                        }
                        
                        if !isAppAllowed{
                            runningApp.hide()
                            if self.timerAllowUrlForActivity != nil{
                                self.timerAllowUrlForActivity!.invalidate()
                            }
                            return
                        }
                    }else{
                        if self.timerAllowAppForActivity != nil{
                            self.timerAllowAppForActivity!.invalidate()
                        }
                    }
                }
            }
        }else if (currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_) && currentAction == ._INPROGRESS_ && currentHabitPlaying != nil{
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    print(name)
                    if currentHabitPlaying != nil{
                        var isAppAllowed = false
                        if name == "finder" || name == selfAppName.lowercased(){
                            isAppAllowed = true
                        }else{
                            for appName in currentHabitPlaying!.allowApps{
                                if appName.lowercased() == name{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                            if !isAppAllowed{
                                for appName in activityAllowedFocusApps{
                                    if appName.lowercased() == name{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                            }
                        }
                        
                        if !isAppAllowed{
                            runningApp.hide()
                            if self.timerAllowUrlForActivity != nil{
                                self.timerAllowUrlForActivity!.invalidate()
                            }
                            return
                        }
                    }else{
                        if self.timerAllowAppForActivity != nil{
                            self.timerAllowAppForActivity!.invalidate()
                        }
                    }
                }
            }
        }
            
        else{
            if self.timerAllowAppForActivity != nil{
                self.timerAllowAppForActivity!.invalidate()
            }
        }
    }
    var arrAllowedUrlsForFocus = [""]
    var arrBlockedUrlsForFocus = [""]
    var defaultAllowedUrl = ["eyst-focus.html",
                             "earnyourscreentime.com",
                             "devtools://",
                             "chrome-extension://",
                             "focusbear.io",
                             "view-source:",
                             "https://focus-bear.github.io"]
    
    var allowAppsPath = [""]
    var arrNotificationShownForApps = [""]
    @objc func checkInBackground(){
        DispatchQueue.main.async {
            if !isFocusModeOn(){
                if self.timerAllowUrl != nil{
                    self.timerAllowUrl!.invalidate()
                    // self.timerAllowUrl = nil
                    print("invalidtate")
                }
                return;
            }
            print("checkInBackground")
            if isAllowedAllUrlsInFocus{
                return;
            }
            var stringTime: String = ""
            if isFocusTimeType == ._HOUR_{
                if let date = endFocusModeTime{
                    stringTime = getStringFromDate(date: date, dateFormat: "YYYY-MM-dd")
                    stringTime = stringTime + "T" + getStringFromDate(date: date, dateFormat: "hh:mm:ss")
                }
            }else if isFocusTimeType == ._TILL_SHUTOFF_ || isFocusTimeType == ._NONE_{
                if let date = shutOffTime{
                    //let stringTime = getStringFromDate(date: date, dateFormat: "HH:mm a")
                    let hour = date.hour
                    let minute = date.minute
                    let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
                    stringTime = getStringFromDate(date: date, dateFormat: "YYYY-MM-dd")
                    stringTime = stringTime + "T" + getStringFromDate(date: date, dateFormat: "hh:mm:ss")
                }
            }
            
            var focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
            var focusMode = ""
            
            for dic in arrFocusType{
                if dic["isOn"] as? Bool == true{
                    focusMode = dic["name"] as? String ?? ""
                }
            }
            
            focusModeExpiryTimeString = focusModeExpiryTimeString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            focusMode = focusMode.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            
            
            
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let name = runningApp.localizedName{
                    var script: String = ""
                    if name.lowercased() == "safari"{
                        if var url = self.getSafariActiveTabUrl(){
                            print(url)
                            for turl in self.defaultAllowedUrl{
                                if url.contains(turl){
                                    return
                                }
                            }
                            
                            if !url.contains("favorites:"){
                                let domain = getDomainFromUrl(url: url)
                                var isBlocked = false
                                for turl in self.arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if isBlocked{
                                        break;
                                    }
                                }
                                
                                var isAllowed = false
                                if !isBlocked{
                                    for turl in self.arrAllowedUrlsForFocus{
                                        isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if isAllowed{
                                            break;
                                        }
                                    }
                                }
                                if !isAllowed{
                                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)"
                                    end tell
                                    """
                                }else{
                                    return
                                }
                            }else{
                                return;
                            }
                            
                        }else{
                            return;
                        }
                        
                    }else if name.lowercased() == "google chrome"{
                        if var url = self.getGoogleChromeActiveTabUrl(){
                            print(url)
                            for turl in self.defaultAllowedUrl{
                                if url.contains(turl){
                                    return
                                }
                            }
                            
                            if !url.contains("chrome:"){
                                let domain = getDomainFromUrl(url: url)
                                var isBlocked = false
                                for turl in self.arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if isBlocked{
                                        break;
                                    }
                                }
                                var isAllowed = false
                                if !isBlocked{
                                    for turl in self.arrAllowedUrlsForFocus{
                                        isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if isAllowed{
                                            break;
                                        }
                                    }
                                }
                                if !isAllowed{
                                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)"
                                    end tell
                                    """
                                }else{
                                    return;
                                }
                            }else{
                                return
                            }
                        }else{
                            return;
                        }
                        
                        
                    }else{
                        self.timerAllowUrl?.invalidate()
                    }
                    //--if URL of the_tab is equal to "https://www.apple.com/" then
                    if let appleScript = NSAppleScript(source: script) {
                        
                        var errors : NSDictionary? = nil
                        appleScript.executeAndReturnError(&errors)
                        if errors != nil {
                            
                            //var test = errors?.count
                            print(errors)
                        }
                        //let descriptor = error.descriptorType
                    }
                }
            }
            
            
            
        }
    }
    
    @objc func checkInBackgroundForActivity(){
        DispatchQueue.main.async {
            
            if currentActivityPlaying == nil && currentHabitPlaying == nil{
                self.timerAllowUrlForActivity?.invalidate()
                return;
            }
            
            
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let name = runningApp.localizedName{
                    var script: String = ""
                    if name.lowercased() == "safari"{
                        if var url = self.getSafariActiveTabUrl(){
                            print(url)
                            for turl in self.defaultAllowedUrl{
                                if url.contains(turl){
                                    return
                                }
                            }
                            
                            if !url.contains("favorites:"){
                                let domain = getDomainFromUrl(url: url)
                                
                                var bool = false
                                var blockType = ""
                                if currentState == ._ACTIVITY_{
                                    if currentActivityPlaying != nil{
                                        for turl in currentActivityPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    blockType = "break-activity"
                                }
                                if currentState == ._MORNING_HABIT_{
                                    if currentHabitPlaying != nil{
                                        for turl in currentHabitPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    blockType = "morning-habit"
                                }
                                
                                if currentState == ._EVENING_HABIT_{
                                    if currentHabitPlaying != nil{
                                        for turl in currentHabitPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    blockType = "evening-habit"
                                }
                                
                                if !bool{
                                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                }else{
                                    return
                                }
                            }else{
                                return;
                            }
                            
                        }else{
                            return;
                        }
                        
                    }else if name.lowercased() == "google chrome"{
                        if var url = self.getGoogleChromeActiveTabUrl(){
                            print(url)
                            for turl in self.defaultAllowedUrl{
                                if url.contains(turl){
                                    return
                                }
                            }
                            
                            if !url.contains("chrome:"){
                                let domain = getDomainFromUrl(url: url)
                                var bool = false
                                var blockType = ""
                                if currentState == ._ACTIVITY_{
                                    if currentActivityPlaying != nil{
                                        for turl in currentActivityPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    blockType = "break-activity"
                                }
                                if currentState == ._MORNING_HABIT_{
                                    if currentHabitPlaying != nil{
                                        for turl in currentHabitPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                        
                                    }
                                    blockType = "morning-habit"
                                }
                                
                                if currentState == ._EVENING_HABIT_{
                                    if currentHabitPlaying != nil{
                                        for turl in currentHabitPlaying!.allowUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                break;
                                            }
                                        }
                                        
                                        if !bool{
                                            for turl in activityAllowedFocusUrls{
                                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                                if bool{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    blockType = "evening-habit"
                                }
                                
                                if !bool{
                                    url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                }else{
                                    return;
                                }
                            }else{
                                return
                            }
                        }else{
                            return;
                        }
                        
                        
                    }else{
                        self.timerAllowUrl?.invalidate()
                    }
                    //--if URL of the_tab is equal to "https://www.apple.com/" then
                    if let appleScript = NSAppleScript(source: script) {
                        
                        var errors : NSDictionary? = nil
                        appleScript.executeAndReturnError(&errors)
                        if errors != nil {
                            
                            //var test = errors?.count
                            print(errors)
                        }
                        //let descriptor = error.descriptorType
                    }
                }
            }
            
            
            
        }
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
    
    func showExtraWindows(){
        
        //        NSApplication.shared.activate(ignoringOtherApps: true)
        let screenList = NSScreen.screens
        if screenList.count == 1{
            if arrWindows.count != 0{
                for i in 0..<arrWindows.count{
                    let window = arrWindows[i]
                    window.orderOut(nil)
                    arrWindows[i].windowController?.window=nil
                }
                arrWindows.removeAll()
            }
            return
        }
        if arrWindows.count == 0{
            
            for i in 0..<screenList.count {  // create the corresponding windows
                let screen = screenList[i]
                //                let  mainWindowControllerObj  = mainstoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("mainWindowController")) as! mainWindowController
                if screen != mainWindowControllerObj?.window?.screen{
                    let window = NSWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen)
                    window.contentViewController = mainStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("blankController")) as! blankController
                    arrWindows.append(resetWin(window))
                }
            }
            
        }
        //        else{
        //            if arrWindows.count == screenList.count - 1{
        //                for win in arrWindows{
        //                    win.orderBack(nil)
        //                }
        //            }else{
        //
        //                if (screenList.count - 1) > arrWindows.count{
        //                    for win in arrWindows{
        //                        win.orderBack(nil)
        //                    }
        //                }
        //
        //            }
        //
        //        }
        
        if arrWindows.count == 0{
            return;
        }
        if !(arrWindows.first?.isVisible)!{
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
        self.perform(#selector(setframe), with: nil, afterDelay: 0)
    }
    
    @objc func setframe(){
        //let screenList = NSScreen.screens
        for i in 0..<arrWindows.count {  // create the corresponding windows
            let window = arrWindows[i]
            window.setFrame(NSMakeRect(NSMinX(window.screen!.frame), NSMinY(window.screen!.frame), NSWidth(window.screen!.frame), NSHeight(window.screen!.frame)), display: true)
        }
    }
    
    @objc func screenChanged() {  // call back for when the user reconfigured the Screen
        
        if isMainWindowLodded{
            if (mainWindowControllerObj?.window!.isVisible)!{
                let screenList = NSScreen.screens
                for screen in screenList {  // create the corresponding windows
                    //                     resetWin(BGWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen))
                    mainWindowControllerObj!.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
                    break;
                }
                hideBlankWindowInSecondaryMonitor()
                showExtraWindows()
            }
        }
        //        let screens = NSScreen.screens
        //        if screens.count > transWindow.count {  // number of screens increase, so create some new windows
        //            for i in (transWindow.count)..<screens.count {
        //                transWindow.append(createWin(screens[i]))
        //            }
        //            spaceChange() // need to update the window if we added
        //        } else if screens.count < transWindow.count {  // ugh, they removed a screen. let's ignore that and just update
        //            spaceChange()
        //        } // otherwise they probably just adjusted the Arrangements which we can ignore
    }
    
    func setTimerForPomodoroMode(delay:TimeInterval){// take a five minut k break per call hoga agar pomodoro mode finish hua h to. normal focus mode finish per call ni hoga ..
        if isAppEnable{
            self.perform(#selector(showAutoPomodoroModeView), with: nil, afterDelay: delay)
        }
    }
    
}





/*
 tell application "Google Chrome"
 set window_list to every window
 repeat with the_wnd in window_list
 set tab_list to tabs in the_wnd
 repeat with the_tab in tab_list
 --set surl to URL of the_tab
 --display dialog surl
 if URL of the_tab is equal to "https://www.apple.com/" then
 set URL of the_tab to "https://www.google.com/"
 end if
 end repeat
 end repeat
 end tell
 */




//                        script =
//                        """
//                        set allowUrl to \(self.allowUrl)
//                        tell application "Google Chrome"
//                            set the_wnd to front window
//                                set active_tab to active tab in the_wnd
//                                if URL of active_tab contains "chrome:" then
//
//                                else
//                                    set tag to 0
//                                    repeat with the_url in allowUrl
//                                        if URL of active_tab contains the_url then
//                                            set tag to 1
//                                        end if
//                                    end repeat
//
//                                    if tag is equal to 0 then
//                                        set URL of active_tab to "\(blockWebUrlString)?old_url=" & URL of active_tab & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)"
//                                    end if
//                                end if
//                        end tell
//                        """


//                            script =
//                            """
//                            set allowUrl to \(self.allowUrl)
//                            tell application "Safari"
//                                set the_wnd to front window
//                                set active_tab to current tab in the_wnd
//                                if URL of active_tab contains "favorites:" then
//
//                                else
//                                    set tag to 0
//                                    repeat with the_url in allowUrl
//                                        if URL of active_tab contains the_url then
//                                            set tag to 1
//                                        end if
//                                    end repeat
//
//                                    if tag is equal to 0 then
//                                        set URL of active_tab to "\(blockWebUrlString)?old_url=" & URL of active_tab & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)"
//                                    end if
//                                end if
//                            end tell
//                            """





//todo
//menu dissappear when quit clicked
//


// notes
//quitting nag will always be smaller in size(not full screen)

// focus mode auto finish hota h to sirf finish ka log likhvate hai.   jabki agar focus mode abort hota h to abort ka log likhvate hai lekin ager focus abort mai reason( i achived what i want ) select kiya hai to 2 log likhavte hai abort ka or finish ka dono ka qki is case mai focus finished vali screen bhi aaaati h or vha se finish vala nag bhi likhvate hai 

// hardcore pomodo mode band krne k liye password
// focus mode abort krne se haedcore pomodoro abort ho jayga chahe koi bhe readon select kiya ho to

// how to stop haedcode pomodoro mode

//during five minutebreak of  start pomodoro mode  convert "start pomodoro mode" button to "stop hardcore pomodoro mode button" button(password mang kar stop)
//if during hardcore pomodoro mode :- on start pomodoro window user close window stop hard code pomodoro mode (password mang ker)
//if hardcore pomodoro mode is on and if focud mode is on then stop focus mode willl stop hardcore pomodoro mode () password mang kar

// hardcore pomodoro mode agar on hua to start hardcore mode ki window close ka button ni aayga / the only way to close window is main buttton(let's do it) abd window will auto close when window focus mode is over 

//todo

// 7 din bad aopp uninstall k bad   app vapas chalu krke register krke dekho 















