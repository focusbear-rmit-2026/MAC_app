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
import Auth0
import TrueTime

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SUUpdaterDelegate, NSPopoverDelegate {
    let validation = urlValidation()
//    var statusBarMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var statusbutton:NSStatusBarButton?
    var updater: SUUpdater?
    let client = TrueTimeClient.sharedInstance
    
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
        addLog(text: "resetAllData")
        let alert = NSAlert()
        alert.setSharingType()
        alert.messageText = "Are you sure you want to reset Focus Bear? All your settings will be deleted."
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        
        if let window = NSApp.keyWindow{
            alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    addLog(text: "reset All Data Done")
                    let domain = Bundle.main.bundleIdentifier!
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                    
                    self.user = nil
                    let _ = self.credentialsManager.clear()
                    self.credential = nil
                    if quantityCsvURL != nil{
                        do{
                            try FileManager.default.removeItem(at: quantityCsvURL!)
                        }catch{
                            
                        }
                    }
                    if offlineActivitiesCsvURL != nil{
                        do{
                            try FileManager.default.removeItem(at: offlineActivitiesCsvURL!)
                        }catch{
                            
                        }
                    }
                    
                    
                    self.quitAndRestartApp()
                }
            })
        }else{
            let result = alert.runModal()
            if result == .alertFirstButtonReturn{
                addLog(text: "reset All Data Done")
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                
                self.user = nil
                let _ = self.credentialsManager.clear()
                self.credential = nil
                if quantityCsvURL != nil{
                    do{
                        try FileManager.default.removeItem(at: quantityCsvURL!)
                    }catch{
                        
                    }
                }
                if offlineActivitiesCsvURL != nil{
                    do{
                        try FileManager.default.removeItem(at: offlineActivitiesCsvURL!)
                    }catch{
                        
                    }
                }
                self.quitAndRestartApp()
            }
        }
        
    }
    var applicationSupportURL: URL?
    var currentUserURL: URL?
    
    // auth
    var credential:Credentials?
    var user: User?
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
//    var sessionStart = false
//    func login(isLogin:Bool) {
//        addLog(text: "show Login window")
//        print("*****login call")
////        Auth0..webAuth().lev
//
//
//
////        showLoginHelpWindow()
//        sessionStart = true
//
//        var parameters = [String:String]()
//        if isLogin{
//            parameters = ["prompt": "login"]
//        }else{
//            parameters = ["screen_hint":"signup"]
//        }
//
//        Auth0
//            .webAuth()
//            .useEphemeralSession()
//            .parameters(parameters)// Ignore the cookie (if present) and show the login page
//            .scope("offline_access")
//            .audience("https://auth.focusbear.io/api/v2/")
//            .start { [self] result in
//                if !sessionStart{
//                    addLog(text: "session already closed")
//                    return;
//                }
//                sessionStart = false
//                DispatchQueue.main.async {
//                    if loginHelpWcObj != nil{
//                        if loginHelpWcObj?.window?.isVisible ?? false{
//                            loginHelpWcObj?.window?.close()
//                        }
//                    }
//                }
//                switch result {
//                case .success(let credentials):// baad mai check krna iske ander main thred hota h kya automatically hi
//                    addLog(text: "Login success")
//                    DispatchQueue.main.async {
//                        self.statusbutton?.action = nil
//                        self.user = User(from: credentials.accessToken)
//                        let _ = self.credentialsManager.store(credentials: credentials)
//                        self.loadCredentialsAndDeviceId()
//                        if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) == nil{
//                            showOnboardingCardWindow()
//                        }
//                    }
//                    //logout()
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                    print("Failed with: \(error)")
//                    DispatchQueue.main.async {
//                        showAskLoginWindow()
//                    }
//
////                    addLog(text: "login failed - app quit")
////                    DispatchQueue.main.async {
////                        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
////                        self.terminateFromSelf = true
////                        NSApp.terminate(self)
////                    }
//                }
//            }
//    }
    
    
    func logout() {
        addLog(text: "logout")
        self.user = nil
        let _ = self.credentialsManager.clear()
        self.credential = nil
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        quitAndRestartApp()
//        login()// agar loin ko call krna hi h to alag se code likho or app close krna jyada sahi rhega automatially lgin view aayga
//        Auth0.webAuth()
//            .useEphemeralSession()
//            .parameters(["prompt": "login"]) // Ignore the cookie (if present) and show the login page
//            .start { result in
//                switch result {
//                case .success:
//                    self.user = nil
//                    //            let _ = self.credentialsManager.clear()
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                }
//
//            }
//        return;
//        Auth0
//            .webAuth()
//            .clearSession { result in
//                switch result {
//                case .success:
//                    self.user = nil
//                    let _ = self.credentialsManager.clear()
//                case .failure(let error):
//                    print("Failed with: \(error)")
//                }
//            }
    }
    let alertAppAutoRestart = NSAlert()
    func applicationWillFinishLaunching(_ notification: Notification) {

//  ********************************* Todo Always Comment This *************************************//
//        let domain = Bundle.main.bundleIdentifier!
//        UserDefaults.standard.removePersistentDomain(forName: domain)
//        UserDefaults.standard.synchronize()//
//        exit(1)
//        return;
//  **********************************************************************************************//


        
//        if let path = Bundle.main.path(forResource: "fenwick", ofType: "ttf") {// remove
//            let url = URL(fileURLWithPath: path)
//            print(url)
//            var errorRef: Unmanaged<CFError>?
//            let val = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
//            print(errorRef)
//        }
        
//        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
//        for family in fontFamilies {
//            print(family)
//            let familyFonts = NSFontManager.shared.availableMembers(ofFontFamily: family)
//            if let fonts = familyFonts {
//                for font in fonts {
//                    print("\t\(font)")
        
//                }
//            }
//        }
        

        
        client.start()// for getting true time
        
        updater = SUUpdater(for: Bundle.main)
        
        // -----------------------------GENERATE LOG FILE----------------------------
        let bundel = Bundle.main.bundleIdentifier ?? ""
        let applicationSupportPath = "/Users/\(NSUserName())/Library/Application Support/\(bundel)"
        CreateDirectoryIfNotExist(path: applicationSupportPath)
        applicationSupportURL  = URL(fileURLWithPath: applicationSupportPath)
        DebugLogsFolderURL = applicationSupportURL!.appendingPathComponent("Logs")
        CreateDirectoryIfNotExist(path: DebugLogsFolderURL!.path)
        DebugLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Logs.txt")
        quantityCsvURL = applicationSupportURL!.appendingPathComponent("eystStats.csv")
        offlineActivitiesCsvURL = applicationSupportURL!.appendingPathComponent("offlineActivities.csv")
        
//        //
//
//        do {
//            let data = try Data(contentsOf: URL(fileURLWithPath: "/Users/prashant/Library/Application Support/com.App.Late-No-More/events.json"), options: .mappedIfSafe)
//            //  if data != nil{
//            do {
//                if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary{
//                    print(jsonResult)
//                }
//            }catch{
//                print(error)
//            }
//            //  }
//        } catch {
//            // handle error
//        }
        
        // ----------------SET APP INSTALL DATE---------------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }
        // ----------------Dock icon work---------------------------------
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
            if state{
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
            }else{
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }else{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        }
        
        
        // ------------------- SET FORCE FRASH START ----------------
        let char = "k"
        var flags = NSEvent.modifierFlags
        flags.insert(.control)
        flags.insert(.command)
        self.hotKeyClearUserdefaults = HotKey(keyCombo: KeyCombo(stkey: char, modifiers: flags))
        
        
        // ///////////////////SET TOP ICON////////////////////////
        if self.statusItem.button != nil {
            self.statusbutton = self.statusItem.button
            self.statusbutton?.image = NSImage(named: NSImage.Name("Bear-Small"))
            
            self.statusbutton?.font = NSFont.systemFont(ofSize: 10)
            //            self.statusbutton?.imagePosition = .imageAbove
            //            self.statusItem.title = "fff"
            //            self.statusItem.
        }
        
        DispatchQueue.global().async {//ye isiliye kiya qki first time mai list mai time lgta hai to starting mai hi kr diya
            avmonitor.isMicOn()//.start()
            avmonitor.isACameraOn()//.checkCamera()
        }
        
        
                
        
        // setting Toolbox
        
        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsDontShowToolBoxAutomatically)
        }
        
        //  ---------------------------SETTINGS Language--------------------------

        var languageCode = "en"
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            languageCode = language
        }else{
            let language = Locale.preferredLanguages[0] as String
            let range: NSRange = (language as NSString).range(of: "-")
            if range.location != NSNotFound {
                let newString = (language as NSString).substring(to: range.location)
                if newString == "es"{
                    languageCode = "es"
                }else{
                    languageCode = "en"
                }
                UserDefaults.standard.set(languageCode, forKey: kUserdefaultsSelectedLanguage)
                print("\(newString)")
            } else {
                UserDefaults.standard.set(languageCode, forKey: kUserdefaultsSelectedLanguage)
            }
        }
        var configFileName = ""
        if languageCode == "en"{
            configFileName = "config"
        }else{
            configFileName = "config-\(languageCode)"
        }
        currentLanguageCode = languageCode
        if let version = Bundle.main.releaseVersionNumber,let build = Bundle.main.buildVersionNumber{
            addLog(text: "running app version:" + " " + version + "." + build)
            appVersion = version + "." + build
        }
        
        let systemVersion = ProcessInfo().operatingSystemVersion
        addLog(text: "macOS Version \(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)")
        macOSVersion = "\(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
        //        https://focus-bear.github.io/assets/config/config.json
        checkLogFileRotation()
        allApiObject.getConfigFile(fileUrl:"https://focus-bear.github.io/assets/config/\(configFileName).json", completionHandler: {dic in
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
            DispatchQueue.main.async {
                
                if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) != nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsAppQuitProperly) == nil{
                        if UserDefaults.standard.object(forKey: kUserdefaultsDontTellAgain) == nil{
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            self.alertAppAutoRestart.setSharingType()
                            self.alertAppAutoRestart.messageText = "Focus Bear automatically restarts if it gets force quit/crashes to make sure you always have help combatting distractions. If you want to quit the app/take a break, use the Quit option from the Focus Bear menu bar."
                            self.alertAppAutoRestart.showsSuppressionButton = true
                            self.alertAppAutoRestart.suppressionButton?.title = "Got it - don't tell me again"
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                self.alertAppAutoRestart.messageText = common.value(forKey: "alertAppRestartText") as? String ?? self.alertAppAutoRestart.messageText
                                self.alertAppAutoRestart.suppressionButton?.title = common.value(forKey: "buttonDontTellAgainText") as? String ?? "Got it - don't tell me again"
                            }
                            self.alertAppAutoRestart.suppressionButton?.state = .off
                            self.alertAppAutoRestart.addButton(withTitle: buttonOkText)
                            self.alertAppAutoRestart.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))//.modalPanel
                            self.alertAppAutoRestart.runModal()
                            if self.alertAppAutoRestart.suppressionButton?.state == .on{
                                UserDefaults.standard.set(true, forKey: kUserdefaultsDontTellAgain)
                            }
                        }
                    }else{
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsAppQuitProperly)
                    }
                }
                // work for old useres beacuse we have changed the login routine now we will also write is Logged in in userdefaulsts so handle old users
                if UserDefaults.standard.object(forKey: "oldUserLoggedInCheck") == nil{
                    if  self.credentialsManager.canRenew(){
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsUserLoggedIn)
                    }
                    UserDefaults.standard.set(true, forKey: "oldUserLoggedInCheck")
                }
                

                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        showWelcomeOnboardingWindow()
                    }else{
                        showAskLoginWindow()
                    }
                    return;
                }else{
                    guard self.credentialsManager.canRenew() else {
                        // Present login screen
                        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                            showWelcomeOnboardingWindow()
                        }else{
                            showAskLoginWindow()
                        }
                        
                        return;
                    }
                }
                
                self.loadCredentialsAndDeviceId()
            }

        }
        )
    }
    func showAskAppWork(){
        mainWindowControllerObj?.showWindow(self)
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj!.showAskAppWorkVc()
    }
    func showOnbardingHabit(){
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
        
        if mainWindowControllerObj != nil{
            if !mainWindowControllerObj!.window!.isVisible{
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
            }
        }else{
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
        }
        mainViewControllerObj!.showFirstTimeVc()
        isFirstRun = true
        
        
        
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
//                        if app is installed on the same day than user will not get morning habit on the same day until he logout and login with diffrent or same account so we write morning routine done date in userdefaulsts here but will remove when logout    and with the difrent account user will get his lastmorningroutine show date from api and write date in userdefaults
    }
    
//    var morningCount = 0
//    var startAppCheckCount = 0
    func setCredentialAndUserInfo(credentialsInfo: CredentialsManagerResult<Credentials>, isAppLaunching:Bool){
        addLog(text: "set Credential And User Info")
        var newCredential:Credentials?
        do{
            newCredential = try credentialsInfo.get()
        }catch{
            addLog(text: "failed:- appdelegate!.credentialsManager.credentials \(error.localizedDescription)")
            print(error)
        }
        var needToRefreshUser = false

        
        if newCredential == nil{
            addLog(text: "failed:- newCredential nil")
            DispatchQueue.main.async {
                
                
                if Reachability.isConnectedToNetwork() == false{
                    addLog(text: "failed:- newCredential nil : reason no internet")
                    
                    showPopUpOfflineWindow()
                    
                    
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        self.abortAllProcess()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    
                    
                }else{
                    addLog(text: "failed:- newCredential nil : show alert and logout")
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        self.abortAllProcess()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                
                    alert.runModal()
                    self.logout()
                }
                
            }
            return;
        }
        
        if self.credential == nil{
            self.credential = newCredential
            addLog(text: "successfully fetch cedential from credentialsManager in app launch")
            needToRefreshUser = true
        }else{
            if self.credential?.accessToken != newCredential?.accessToken{
                addLog(text: "accessToken changed:- update cedential in credentialsManager")
                self.credential = newCredential
                let _ = credentialsManager.store(credentials: self.credential!)
                needToRefreshUser = true
            }
        }
        
        if needToRefreshUser{
            addLog(text: "successfully fetch cedential:- needToRefreshUser")
            print(self.credential!.accessToken)
            print(self.credential!.idToken)
            print(self.credential?.expiresIn)
            
            self.user = User(from: self.credential!.accessToken)
            isPurchased = false
            if let subscriptionStatus = self.user?.subscriptionStatus{
                var activeEntitlementStatus = ""
                if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
                    if let status = activeEntitlements.first{
                        activeEntitlementStatus = status
                        if status == "personal" || status == "team_member" || status ==  "team_owner" || status == "team_size_5"{
                            isPurchased = true
                        }else if status == "trial"{
                            isPurchased = false
                        }else{
                            isPurchased = false
                        }
                    }
                }
                let oldDaysLeft = daysLeft
                daysLeft = 0
                print(subscriptionStatus)
                if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
                    if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
                        if let days_left = trial["days_left"] as? Int{
                            print(days_left)
                            daysLeft = days_left
                        }
                    }
                }
                if !isAppLaunching{
                    if oldDaysLeft > 0{// subscription over need to restart
                        if isPurchased == false && daysLeft == 0{
                            addLog(text: "subscription over:- need to restart app")
                            DispatchQueue.main.async {
                                self.quitAndRestartApp()
                            }
                            
                        }
                    }
                }
            }
        }
    }
    
    
    func loadCredentialsAndDeviceId(){
        addLog(text: "load Credentials And DeviceId")
        credentialsManager.credentials { [self] credentialsInfo in

//            do{
//                self.credential = try credentialsInfo.get()
//            }catch{
//                addLog(text: "failed:- appdelegate!.credentialsManager.credentials \(error.localizedDescription)")
//                print(error)
//            }
            setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: true)
//            Auth0.webAuth()/
            if self.credential == nil{ //  it means failed to get cradential and popup offline or error msg is visible
                return;
            }
            if self.credential != nil{
                print(self.credential!.accessToken)
//                print(self.credential!.idToken)
//                print(self.credential?.expiresIn)
//
//                self.user = User(from: self.credential!.accessToken)
//                isPurchased = false
//                if let subscriptionStatus = self.user?.subscriptionStatus{
//                    var activeEntitlementStatus = ""
//                    if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
//                        if let status = activeEntitlements.first{
//                            activeEntitlementStatus = status
//                            if status == "personal" || status == "team_member" || status ==  "team_owner" || status == "team_size_5"{
//                                isPurchased = true
//                            }else if status == "trial"{
//                                isPurchased = false
//                            }else{
//                                isPurchased = false
//                            }
//                        }
//                    }
////                    if !isPurchased{
//                    if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
//                        if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
//                            if let days_left = trial["days_left"] as? Int{
//                                print(days_left)
//                                daysLeft = days_left
//                            }
//                        }
//                    }
////                    }
//                }

                DispatchQueue.main.async {
                    
                    // ----------------SET DeviceID---------------------------------
                    addLog(text: "User Id is :- \(self.user?.userId ?? "")")
                    kUserdefaultsDeviceId = kUserdefaultsDeviceId + (self.user?.userId ?? "")
                    kUserdefaultsIsAppEnabled = kUserdefaultsIsAppEnabled + (self.user?.userId ?? "")
                    kUserdefaults4HourReActivateTime = kUserdefaults4HourReActivateTime + (self.user?.userId ?? "")
                    kUserdefaultsShutdownAborted = kUserdefaultsShutdownAborted + (self.user?.userId ?? "")
                    kUserdefaultsEveningHabitsShowedTillDate = kUserdefaultsEveningHabitsShowedTillDate + (self.user?.userId ?? "")
                    kUserdefaultsFocusSummaryShowedTillDate = kUserdefaultsFocusSummaryShowedTillDate + (self.user?.userId ?? "")
                    kUserdefaultsArrFocusTypes = kUserdefaultsArrFocusTypes + (self.user?.userId ?? "")
                    kUserdefaults24HoursClearPasswordTime = kUserdefaults24HoursClearPasswordTime + (self.user?.userId ?? "")
                    
                    kUserdefaultsLastHabitsStartedDate = kUserdefaultsLastHabitsStartedDate + (self.user?.userId ?? "")
                    kUserdefaultsLastHabitRunningInfo = kUserdefaultsLastHabitRunningInfo + (self.user?.userId ?? "")
                    kUserdefaultsLastSequencePostponeInfo = kUserdefaultsLastSequencePostponeInfo + (self.user?.userId ?? "")
                    
                    SettingsManagerObject.resetAllKeys()
                    

                    
                    
                    self.currentUserURL = self.applicationSupportURL!.appendingPathComponent(self.user?.userId ?? "")
                    if self.currentUserURL != nil{
                        CreateDirectoryIfNotExist(path: self.currentUserURL!.path)
                        quantityCsvURL = self.currentUserURL!.appendingPathComponent("eystStats.csv")
                        offlineActivitiesCsvURL = self.currentUserURL!.appendingPathComponent("offlineActivities.csv")
                    }
                    
                    if let id  = UserDefaults.standard.object(forKey: kUserdefaultsDeviceId) as? String{
                        currentDeviceId = id
                        addLog(text: "load Credentials And DeviceId - got old id")
                        self.loadAppAndSettings()
            
                        
                    }else{
                        addLog(text: "load Credentials And DeviceId - getDeviceId")
                        allApiObject.getDeviceId(completionHandler: {id in
                            addLog(text: "load Credentials And DeviceId - got id")
                            if id != nil{
                                DispatchQueue.main.async {
                                    UserDefaults.standard.set(id!, forKey: kUserdefaultsDeviceId)//e935f08a-5571-4cc3-b514-e0bea9739fd7
                                    currentDeviceId = id!
                                    self.loadAppAndSettings()
                                }
                            }else{
                                DispatchQueue.main.async {
                                    //
                                    let alert = NSAlert()
                                    alert.setSharingType()
                                    alert.messageText = "Unable to connect to server. Please check your internet connection."
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        alert.messageText = common.value(forKey: "checkInternetText") as? String ?? alert.messageText
                                    }
                                    alert.addButton(withTitle: buttonOkText)
                                    alert.runModal()
                                    addLog(text: "load Credentials And DeviceId - id is nil - force Logout user and ask sign in")
                                    self.logout()
                                    
//                                    addLog(text: "load Credentials And DeviceId - id is nil - quit app")
//                                    shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
//                                    self.terminateFromSelf = true
//                                    NSApp.terminate(self)
                                }
                            }
                            
                        }
                        )
                        
                    }
                    
                    
                }
                
            }else{
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                
                    alert.runModal()
                    self.logout()
                }
            }
 
        }
    }
    
    
    
    func loadAppAndSettings(){
        addLog(text: "load App And Settings")
        
        //  ----------------------START APP AT LOGIN-----------------------

        createLaunchAgent()// keep alive // todo uncomment

        
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: quantityCsvURL.path){
            let csvString = "Log type,Timestamp,Activity,Duration in seconds,Quantity Question,Quantity Logged,Start Time,Work achieved,Distractions encountered,Abort reason,Feedback\n"//start time will only be use in focus block start k time per
            
            do {
                try csvString.write(to: quantityCsvURL, atomically: true, encoding: .utf8)
            } catch {
                print("error creating file")
            }
        }
        
        if !fileManager.fileExists(atPath: offlineActivitiesCsvURL.path){
            let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete\n"//start time will only be use in focus block start k time per
            
            do {
                try csvString.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
            } catch {
                print("error creating file")
            }
        }
        
//        blockURL = self.applicationSupportURL!.appendingPathComponent("eyst-focus.html")
//
//        if fileManager.fileExists(atPath: blockURL!.path){
//            do{
//                try fileManager.removeItem(atPath: blockURL!.path)
//            }catch{
//                print(error)
//            }
//        }//
//
//        if !fileManager.fileExists(atPath: blockURL!.path){
//            if let path = Bundle.main.path(forResource: "block", ofType: "html") {
//                let url = URL(fileURLWithPath: path)
//                do{
//                    try fileManager.copyItem(at: url, to: blockURL)
//                }catch{
//                    print(error)
//                }
//            }
//        }
        
        
//        let logoURL = self.applicationSupportURL!.appendingPathComponent("logo.png")
//
//        if fileManager.fileExists(atPath: logoURL.path){
//            do{
//                try fileManager.removeItem(atPath: logoURL.path)
//            }catch{
//                print(error)
//            }
//        }//
//
//        if !fileManager.fileExists(atPath: logoURL.path){
//            if let path = Bundle.main.path(forResource: "logo", ofType: "png") {
//                let url = URL(fileURLWithPath: path)
//                do{
//                    try fileManager.copyItem(at: url, to: logoURL)
//                }catch{
//                    print(error)
//                }
//            }
//        }
        
        
        blockWebUrlString = "https://focus-bear.github.io/assets/focus-blocked/"//blockURL!.absoluteString
        //        var urlString = originalString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        
        //  ------------------------------------------------------------------------------------
        
        
        
        
        SettingsManagerObject.getUserLocalDeviceSettings(completionHandler: {
            
            DispatchQueue.main.async {
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
                //        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)
                
                //  --------------------Checking Password reset time -------------------------------------------------
                
                if let date = UserDefaults.standard.object(forKey: kUserdefaults24HoursClearPasswordTime) as? Date{
                    if Date().compare(date) == .orderedAscending {
                        //first date is smaller than second
                        DispatchQueue.global().sync {
                            self.timerCheckClearPasswordTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkTwentyFourHourActivateTime), userInfo: nil, repeats: true)
                            RunLoop.main.add((self.timerCheckClearPasswordTime!), forMode: RunLoop.Mode.common)
                        }
                    }else{
                        UserDefaults.standard.removeObject(forKey: kUserdefaults24HoursClearPasswordTime)
                        UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                        SettingsManagerObject.isSettingsChanged = true
                        SettingsManagerObject.putUserLocalDeviceSettings()
                        addLog(text: "password is cleared after 24 hours")
                    }
                    
                }
                //  ------------------------------------------------------------------------------------
                addLog(text: "get user Details Info")
                allApiObject.getuserDetailsInfo(completionHandler: {dic in
                    if dic != nil{
                        currentUserEmail = dic?.value(forKey: "email") as? String ?? ""
                        currentUserName = dic?.value(forKey: "name") as? String ?? ""
                        if let arrFocusModes = dic!.value(forKey: "focus_modes") as? [[String:Any]]{
                            var newArr = [[String:Any]]()
                            
                            for i in 0..<arrFocusModes.count{
                                var focusDic = arrFocusModes[i]
                                focusDic.removeValue(forKey: "created_at")
                                focusDic.removeValue(forKey: "updated_at")
                                focusDic.removeValue(forKey: "user_id")
                                focusDic.removeValue(forKey: "deleted_at")
                                var newDic = [String:Any]()
                                for key in focusDic.keys{
                                    if key == "metadata"{
                                        if let metaDataDic = focusDic["metadata"] as? [String:Any]{
                                            for key in metaDataDic.keys{
                                                newDic[key] = metaDataDic[key]
                                            }
                                        }
                                    }else{
                                        newDic[key] = focusDic[key]
                                    }
                                    
                                }
                                newArr.append(newDic)
                                
                            }
                            
                            
                            //                            for i in 0..<newArr.count{
                            ////                                if newArr["isDefault"] as? boo
                            //                            }
                            UserDefaults.standard.set(newArr, forKey: kUserdefaultsArrFocusTypes)
                        }
                    }
                    var isDefaultContain = false
                    var defaultContainLocation = -1
                    var isMeetingsContain = false
                    var islockedFocusContain = false
                    
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
                            if let state = arrFocusType[i]["isLockedFocus"] as? Bool{//this key will only be awailable in default focus type
                                if  state{
                                    islockedFocusContain = state
                                }
                            }
                            
                        }
                        
                    }
                    // finish focus mode if already running
                    finishOldFocusModeIfRunning(startNewFocusId: nil, intention: "", start_time: nil, finish_time: nil)
                    //
                    if !isDefaultContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Complete anarchy! Block nothing 😬", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":true, "isDefault":true, "isAllowedListApproach":false, "blockUrlsArray": []]//#453//
                        //, "isBlockedAllUrls":false , "isAllowedAllUrls":true
                        arrFocusType.append(dic)
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in
                            //                if newDic != nil{
                            //                    dic["id"] = newDic!.value(forKey: "id") as? String ?? ""//["id"] as? String ?? ""
                            //
                            //                }
                            
                        })
                        
                        
                    }
                    else{//defalt focus mode will always be last in list so rearranging it
                        if defaultContainLocation == arrFocusType.count - 1{

                        }else{
                            let dic = arrFocusType[defaultContainLocation]
                            arrFocusType.remove(at: defaultContainLocation)
                            arrFocusType.append(dic)
                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        }
                        
                    }
                    if !isMeetingsContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Meetings", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Teams.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app", "/Applications/Sidekick.app", "/Applications/Brave Browser.app"], "allowed_urls": ["http://meet.google.com"], "isOn": false, "isAllowedAllApps":false, "isMeetings":true, "isAllowedListApproach":true, "blockUrlsArray": []]//#453 , "isBlockedAllUrls":false , "isAllowedAllUrls":false
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.insert(dic, at: arrFocusType.count - 1)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in

                            
                        })
                        
                    }
                    if !islockedFocusContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Locked Focus on current activity", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isLockedFocus":true, "isAllowedListApproach":true, "blockUrlsArray": []]//#453 , "isAllowedAllUrls":false , "isBlockedAllUrls":false
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.insert(dic, at: arrFocusType.count - 1)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in

                            
                        })
                        
                    }
                    
                    
                    if let dic = UserDefaults.standard.object(forKey: kUserdefaultsFocusAddedFromFirstHabit) as? [String : Any]{
                        var jobAllreadyAdded = false // if allready added then we will not add again same jobtype
                        if let jobType = dic["jobType"] as? String{
                            for focus in arrFocusType{
                                if focus["jobType"] as? String == jobType{
                                    jobAllreadyAdded = true
                                    break;
                                }
                            }
                            
                        }
                        if !jobAllreadyAdded{
                            
                            
                            if arrFocusType.count == 0{
                                arrFocusType.append(dic)
                            }else{
                                arrFocusType.insert(dic, at: 0)
                            }
                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                            allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in
                                
                            })
                        }
                        
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsFocusAddedFromFirstHabit)
                    }
              
                    

                    for i in 0..<arrFocusType.count{
                        if arrFocusType[i]["isAllowedListApproach"] == nil{
                            arrFocusType[i]["isAllowedListApproach"] = true
                        }
                    }
                    
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    
                    
                    arrFocusTypeForPomodoro.removeAll()
                    for i in 0..<arrFocusType.count{
                        if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true) && !(arrFocusType[i]["isLockedFocus"] as? Bool ?? false == true){
                            arrFocusTypeForPomodoro.append(arrFocusType[i])
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.checkActivationState()
                    }
                })

                

                //        self.hotKeyPauseFocusMode = HotKey(keyCombo: KeyCombo(stkey: "p", modifiers: flags))
                //
                //        self.hotKeyResumeFocusMode = HotKey(keyCombo: KeyCombo(stkey: "r", modifiers: flags))

                

                

                
//                DispatchQueue.main.async { [self] in
                    SentrySDK.start { options in
                        options.dsn = "https://d897211d717a4c79b1e34666c61548cc@o1187124.ingest.sentry.io/6342590"
                        options.debug = true // Enabled debug when first installing is always helpful
                    }
                    
                    //                let error = NSError(domain: "YourErrorDomain", code: 0, userInfo: nil)
                    //                let id = SentrySDK.capture(error: error)
                    //                print(id)
                    
                    
                self.updater?.delegate = self
                self.updater?.checkForUpdatesInBackground()
                  
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidWakeNotification, object: nil)
                    
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidSleepNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.didWakeNotification, object: nil)
                    
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.willSleepNotification, object: nil)
                    //
                    //        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screenSaverDidStart), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"), object: nil)
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstart"),object: nil)
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screensaver.didstop"),object: nil)
                
                
                
//                }
                
                //                }
                //                )
            }
            
        }
        )
        
        
        
    }
    // Are you sure you want to change the language to "language name"?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        
    }
    func pauseHabitActivityIfRunning(){
        addLog(text: "func:- pauseHabitActivityIfRunning")
        print("pause Habit Activity If Running Called")
        if  currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if currentAction == ._INPROGRESS_ && timerViewcontrollerObj?.timer != nil{
                isLastActivityStoppedInRunningState = true
                lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                timerViewcontrollerObj?.timer?.invalidate()
                timerViewcontrollerObj?.timer  = nil
                if timerViewcontrollerObj?.webView.isHidden == false{
                    timerViewcontrollerObj?.loadBlankUrl()
                }
                
                arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                isAnyAllowedFocusModeActivityRunning = false
                
                closePupUpBlockIfVisible()
                
                currentHabitPlaying = nil
                self.timerAllowUrlForActivity?.invalidate()
                self.timerAllowAppForActivity?.invalidate()
                currentActivityPlaying = nil
                
                if smallCountDownWcObj != nil{
                    if smallCountDownWcObj!.window?.isVisible ?? false{
                        getsmallCountDownVcObject().closeTimerBox()
                    }
                }
                enableSystemSleep()// dont change current state
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
                print("pause Habit Activity If Running Called:- Success")
            }
        }
    }
    func pauseBreakActivityTimerIfRunning(){
        addLog(text: "pause Break Activity Timer Called")
        print("pause Break Activity Timer Called")
        if  currentState == ._ACTIVITY_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{// no need to check morning or evening habit beacuse noe morning evening habits can show breaks
            addLog(text: "return - no need to pause:- \(currentState)")
            print("return - no need to pause:- \(currentState)")
            return
        }
        //        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
        //            checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
        //        }else{
        //            isHabitAlreadyShowed = false
        //        }
        //        if isHabitAlreadyShowed && !isShutOffTimeGoing(){
        if mainViewControllerObj?.breakTimer != nil{
            mainViewControllerObj?.breakTimer?.invalidate()
            mainViewControllerObj?.breakTimer = nil
            isActivityTimerPaused = true
            addLog(text: "pause Break Activity Timer Done")
            print("pause Break Activity Timer Done")
        }else{
            addLog(text: "Timer Already nil - return")
            print("Timer Already nil - return")
        }
        //        }
        //        else{
        //            addLog(text: "return - not activity time")
        //            print("return - not activity time")
        //            return;
        //        }
    }
    func resumeBreakActivityTimerIfNededed(){
        addLog(text: "resume Break Activity Timer Called")
        
        if isActivityTimerPaused{
            isActivityTimerPaused = false
        }else{
            addLog(text: "return - activity was not paused")
            return;
        }
        
        if  currentState == ._ACTIVITY_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{
            addLog(text: "return - no need to resume:- \(currentState)")
            return
        }
//        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
//            checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
//        }else{
//            isHabitAlreadyShowed = false
//        }
//        if isHabitAlreadyShowed && !isShutOffTimeGoing(){
        if mainViewControllerObj?.breakTimer == nil{
            mainViewControllerObj?.setActivityTimer()
        }
//        }else{
//            addLog(text: "return - not activity time")
//            return;
//        }
    }
    @objc private func sleepEvent(_ aNotification: Notification) {
        print("******didwakeup psps*******")
        addLog(text: "sleepEvent")
      
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            addLog(text: "sleepEvent:- subscription expired return")
            return;
        }
        if aNotification.name == NSWorkspace.screensDidSleepNotification {
            print("screensDidSleepNotification")
            addLog(text: "screensDidSleepNotification")

        }else if aNotification.name == NSWorkspace.screensDidWakeNotification {
            print("screensDidWakeNotification")
            addLog(text: "screensDidWakeNotification")

        }else if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
            addLog(text: "Going to sleep")
            isSystemSleep = true
            pauseBreakActivityTimerIfRunning()
            pauseHabitActivityIfRunning()
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            addLog(text: "Woke up")
            isSystemSleep = false
            if isActivityTimerPaused{
                resumeBreakActivityTimerIfNededed()
            }
            returnFromSystemSleepCheckAppStateAgain()
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstart") {//agar screensaver anable h to system slleep se pahle scrrensaver aayga or system sleep hote i jayga
            print("com.apple.screensaver.didstart")
            addLog(text: "com.apple.screensaver.didstart")
            pauseBreakActivityTimerIfRunning()
            pauseHabitActivityIfRunning()
            isScreenSaverStart = true
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstop") {
            print("com.apple.screensaver.didstop")
            addLog(text: "com.apple.screensaver.didstop")
            isScreenSaverStart = false
            if !isSystemSleep{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
        }else {
            print("Some other event other than the first four")
        }
        
        
        
        
        if !isFocusModeOn(){
            isFocusPaused = false
            return;
        }
        
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")

            if !isFocusPaused{
                pauseFocusModeIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")

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
            print("Some other event other than the first four")
        }
        
    }
    
    var isActivityTimerPaused = false
    var isSystemSleep = false
    var isScreenSaverStart = false
    var isFocusPaused = false
    var remainingFocusModeSecondsAfterPaused = 0
    func pauseFocusModeIfRunning(){
        isFocusPaused = true
        print("focus paused")
        addLog(text: "pause Focus Mode If Running")
        
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
        addLog(text: "resume Focus Mode If Running")
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        
        DispatchQueue.global().sync {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
           // RunLoop.current.add(timerForFocusMode!, forMode: RunLoop.Mode.common)
           // RunLoop.current.run()// ase q ho rha h ki  is line k baad next line execute ni hoti labhi
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
        }
    }
    
    
    //4b3eb33632184640b82aa3e3f50fe11b2cdd8b0e82ce48a8bfd1cbe26edc32f5
    // if application is going to relaunch by updater we unload launchagent to make sure applicate will not autostart before install finish /// bug solved 15/7/22
    func updaterWillRelaunchApplication(_ updater: SUUpdater) {
        addLog(text: "updater Will Relaunch Application")
        print("updater Will Relaunch Application")
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        terminateFromSelf = true
    }
//    func updaterDidNotFindUpdate(_ updater: SUUpdater) {
//        print("did not find update")
//    }
//    func updater(_ updater: SUUpdater, didFinishLoading appcast: SUAppcast) {
//        print("didFinishLoading")
//    }
    func checkActivationState(){
        //        DispatchQueue.main.async {
        addLog(text: "checkActivationState")
        if isPurchased == true{
            // initial work includes top menu, and habit activities process
            self.initialWork()
        }else{//daysLeft
            
            //new work 12/9/22
            if daysLeft <= 0{//if expired than menu is enabled
                self.statusbutton?.wantsLayer = true
                self.statusbutton?.layer?.borderColor = NSColor.red.cgColor
                self.statusbutton?.layer?.borderWidth = 2
                self.statusbutton?.layer?.backgroundColor = NSColor.clear.cgColor
                var expiredBarText = "Expired"
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    expiredBarText = common.value(forKey: "expiredBarText") as? String ?? expiredBarText
                }
                self.statusbutton?.title = expiredBarText
                self.statusbutton?.imagePosition = .imageLeft
                addLog(text: "App started in Expired state")
                self.setTopMenu()
                showUpgradeNowWindow()
            }else{
                self.initialWork()
            }
            //
            
        }
    }
    
    
    


    func readSettingsJsonDictionary(json:NSDictionary?){
        addLog(text: "read Settings Json Dictionary")
        arrAllMorningHabits.removeAll()
        arrAllEveningHabits.removeAll()
        arrAllbreakActivities.removeAll()
        var jsonResult:NSDictionary?
        jsonResult = json
        if jsonResult == nil{
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
                if let path = Bundle.main.path(forResource: "settings", ofType: "json") {//ise na upload krenge na local per save krenege bcos ye us state mai aai hai jab upar se setting utar ni pai na hi koi  settings userdefaults mai nahi mili
                    let url = URL(fileURLWithPath: path)
                    do {
                        let data = try Data(contentsOf: url, options: .mappedIfSafe)
                        
                        do {
                            if let dicResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                                jsonResult = dicResult
                                
                                
                                if let str = String(data: data, encoding: String.Encoding.utf8){
                                    UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                                }
                                
                                
                            }
                            
                        }catch {
                            print(error)
                        }
                    } catch {
                        // handle error
                    }
                    
                    
                }
            }
        }
        
        

        
        // -------------------READING SETTINGS JSON----------------------//
        if jsonResult != nil{
            if let morningHabits = jsonResult!.value(forKey: "morning_activities") as? [NSDictionary] {
                print("morningHabits")
                print(morningHabits)
                for habitDic in morningHabits {
                    let id = habitDic["id"] as? String ?? ""
                    let name = habitDic["name"] as? String ?? ""
                    let durationSeconds = habitDic["duration_seconds"] as? Int ?? 0 
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    let logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    arrAllMorningHabits.append(habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode, activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks))
                }
            }

            
            
            if let eveningHabits = jsonResult!.value(forKey: "evening_activities") as? [NSDictionary] {
                print("eveningHabits")
                print(eveningHabits)
                for habitDic in eveningHabits {
                    let id = habitDic["id"] as? String ?? ""
                    let name = habitDic["name"] as? String ?? ""
                    let durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    let logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    arrAllEveningHabits.append(habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode,activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks))
                }
            }
            
            
            if let breakActivities = jsonResult!.value(forKey: "break_activities") as? [NSDictionary] {
                print("breakActivities")
                print(breakActivities)
                for activityDic in breakActivities {
                    let id = activityDic["id"] as? String ?? ""
                    let name = activityDic["name"] as? String ?? ""
                    let durationSeconds = activityDic["duration_seconds"] as? Int ?? 0
                    let IncludeInEveryBreak = activityDic["include_in_every_break"] as? Bool ?? false
                    let videoUrl = activityDic["video_urls"] as? [String] ?? []
                    let logQuantity = activityDic["log_quantity"] as? Bool ?? false
                    //                let openSpecificApps = activityDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = activityDic["allowed_urls"] as? [String] ?? []
                    let allowApps = activityDic["allowed_apps"] as? [String] ?? []
                    let isOfficeFriendly = activityDic["is_office_friendly"] as? Bool ?? false
                    let allowedFocusMode = activityDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = activityDic["activity_sequence_id"] as? String ?? ""
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    var isRandomChoice = false
                    if let type = activityDic["choice_type"] as? String{
                        if type == "random"{
                            isRandomChoice = true
                        }
                    }//"SUM" "AVG"// comapre
                    var arrChoices = [activityChoice]()
                    if let choices = activityDic.value(forKey: "choices") as? [NSDictionary] {
                        for dic in choices{
                            let id = dic["id"] as? String ?? ""
                            let name = dic["name"] as? String ?? ""
                            let videoUrl = dic["video_urls"] as? [String] ?? []
                            let logQuantityQuestion = dic["log_quantity_question"] as? String ?? ""
                            let logQuantity = dic["log_quantity"] as? Bool ?? false
                            let logQuantityType = dic["log_summary_type"] as? String ?? ""
                            let choice = activityChoice(name: name, urlsArray: videoUrl, logQuantityQuestion: logQuantityQuestion, logQuantity: logQuantity, logQuantityType: logQuantityType, id: id)
                            arrChoices.append(choice)
                        }
                    }
                    if arrChoices.count == 0{
                        isRandomChoice = false
                    }
                    let logQuantityQuestion = activityDic["log_quantity_question"] as? String
                    let logQuantityType = activityDic["log_summary_type"] as? String ?? ""
                    arrAllbreakActivities.append(breakActivity(id: id, name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, urlsArray: videoUrl, logQuantity:logQuantity, isRandomChoice: isRandomChoice, choices: arrChoices, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, isOfficeFriendly: isOfficeFriendly, allowedFocusMode: allowedFocusMode, logQuantityType: logQuantityType, activity_sequence_id: activity_sequence_id))
                }
            }
            

            
            if let breakMinutes = jsonResult!.value(forKey: "break_after_minutes") as? Int {
                print("breakAfterMinutes")
                breakAfterMinutes = breakMinutes
                print(breakAfterMinutes)
            }
            
            //        if let val = jsonResult.value(forKey: "showEveryBreak") as? Bool {//ye kabhi kaam ni aayga qki vo bejega h ni fir bhi hata ni rhe h qki default false h to koi prob ni h
            //            showEveryBreak = val
            //        }else{
            //            showEveryBreak = false
            //        }
            
            if let val = jsonResult!.value(forKey: "startup_time") as? String {
                startTime = getTimeFromString(val: val)
            }
            if let val = jsonResult!.value(forKey: "shutdown_time") as? String {
                shutOffTime = getTimeFromString(val: val)
            }
        }
        
    }
    var isSettingsLoddedInAppdelegate = false
    func initialWork(){
        addLog(text: "initialWork")
        isAppInitialLodded = true
//        if UserDefaults.standard.object(forKey: kUserdefaultsFirstHabitDay) == nil{
//            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstHabitDay)
//        }
        self.statusbutton?.action = nil
        
        // -------------------GETTING SETTINGS JSON----------------------//
        var isFirstTime = false
        if UserDefaults.standard.object(forKey: kUserdefaultsSelectedJson) == nil{
            isFirstTime = true
        }
        var isHabitsDisabled = false
        if isFirstTime{
            if let val = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabled) as? Bool{
                isHabitsDisabled = val
            }
        }

        allApiObject.getSettings(isFirstTime: isFirstTime, isHabitsDisabled:isHabitsDisabled, completionHandler: {settings in
            
            if settings != nil{
                print(settings!)
                //                appdelegate.b
                
                do {
                    let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                    if let str = String(data: data, encoding: String.Encoding.utf8){
                        UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
            self.readSettingsJsonDictionary(json: settings)
          
            DispatchQueue.main.async {
                if popUpOfflineWcObj != nil{
                    if popUpOfflineWcObj?.window?.isVisible ?? false{
                        addLog(text: "func:- initialWork   popUpOfflineWcObj window visible return")
                        return;
                    }
                }
                addLog(text: "func:- initialWork   isSettingsLoddedInAppdelegate done")
                
                self.isSettingsLoddedInAppdelegate = true
                //
                if UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) == nil{
                    UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                    isAppEnable = true
                }
                if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) as? Bool{
                    isAppEnable = state
                    if state{
                        self.checkWindowState()
                    }else{
                        self.statusbutton?.wantsLayer = true
                        self.statusbutton?.layer?.borderColor = NSColor.red.cgColor
                        self.statusbutton?.layer?.borderWidth = 2
                        self.statusbutton?.layer?.backgroundColor = NSColor.clear.cgColor
                        self.statusbutton?.title = buttonStatusStateOffText
                        self.statusbutton?.imagePosition = .imageLeft
                        addLog(text: "App started in Deactivated state")
                    }
                }
                if let date = UserDefaults.standard.object(forKey: kUserdefaults4HourReActivateTime) as? Date{
                    if Date().compare(date) == .orderedAscending {
                        //first date is smaller than second
                        DispatchQueue.global().sync {//async {
                            self.timerCheckReactivateTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkFourHourActivateTime), userInfo: nil, repeats: true)
//                            RunLoop.current.add(self.timerCheckReactivateTime!, forMode: RunLoop.Mode.common)
//                            RunLoop.current.run()
                            RunLoop.main.add((self.timerCheckReactivateTime!), forMode: RunLoop.Mode.common)
                        }
                    }else{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                        UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                        addLog(text: "App Reactivated after 4 hours")
                        self.quitAndRestartApp()
                        return;
                    }
                    
                }
                
                
                
                // ---------------------------------SET TOP MENU-------------------------------- //
                self.setTopMenu()
                
                // ---------------------------------FORCE HIDE APP AND ENTER BUTTON WORK SETUP-------------------------------- //
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
                                        if askPostponeVcObj != nil{
                                            if (mainViewControllerObj?.view.subviews.contains((getAskPostponeVcObject().view)))!{
                                                return event
                                            }
                                        }
                                        if skipHabitVcObj != nil{
                                            if (mainViewControllerObj?.view.subviews.contains((skipHabitVcObj!.view)))!{
                                                return event
                                            }
                                        }
                                        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                                            if enterPasswordVcObj != nil{
                                                if mainViewControllerObj!.view.subviews.contains(enterPasswordVcObj!.view){
                                                    return event
                                                }
                                            }
                                        }
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
//                                                        if thirdVcObj?.btnMain.isHidden == true{// check if preload focus mode work view visible then enter will bt Button Continue
//                                                            if currentState == ._BREATHING_ && thirdVcObj?.customViewContainer.isHidden == false && thirdVcObj?.preloadFocusModesVcObj != nil{
//                                                                if thirdVcObj?.customViewContainer.subviews.contains(thirdVcObj!.preloadFocusModesVcObj!.view) ?? false{
//                                                                    if thirdVcObj?.preloadFocusModesVcObj?.btnContinue.isEnabled == true{
//                                                                        thirdVcObj?.preloadFocusModesVcObj?.btnContinueClicked(self)
//                                                                    }
//                                                                }
//                                                            }
//                                                        }else{
                                                            thirdVcObj?.btnMainClicked(self)
//                                                        }
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
                                        }else if currentAction == ._VISUALIZE_{
                                            if !getvisualizeInstructionsObject().isTimerGoingOn{
                                                getvisualizeInstructionsObject().btnMainClicked(self)
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
            }
            
            
            // }
        }
        )
        // --------------------------------------------------------------- //
        
        
        
        // ------------------------------------------------------------------------------- //
    }
    
    func setTopMenu(){
        addLog(text: "setTopMenu")
//        if self.statusItem.button != nil
//        {
//            statusbutton?.action = #selector(togglePopover(_:))
//        }
        if let button = statusItem.button
        {
            button.action = #selector(togglePopover(_:))
            popover.contentViewController = menuViewControllerObj
//            popover.animates = false
            popover.behavior = .transient
            
        }
    }
    let popover = NSPopover()
    @objc func togglePopover(_ sender: Any?) {
        let runningApp = NSWorkspace.shared.frontmostApplication
        if runningApp?.bundleIdentifier != Bundle.main.bundleIdentifier{
            lastFrontMostApplication = runningApp
        }
        
        addLog(text: "Top bar focus bear button clicked")
        if popover.isShown
        {
            closePopover(sender: sender)
        } else
        {
            showPopover(sender: sender)
        }
//        if let event = NSApp.currentEvent{
//            if event.type ==  NSEvent.EventType.leftMouseUp {
//                if isDiscourageDefaultFocusVcVisible{
//                    return
//                }
//                self.statusBarMenu = NSMenu(title: "Status Bar Menu")
//                let nItem = NSMenuItem()
//                nItem.view = menuViewControllerObj?.view
//                nItem.view?.translatesAutoresizingMaskIntoConstraints = false
//                menuViewControllerObj!.reloadData()
//                self.statusBarMenu.addItem(nItem)
//                statusBarMenu.delegate = self
//
//                statusItem.menu = statusBarMenu // add menu to button...
//                if isFocusModeOn(){
//                    showBrainDumpWindow()
//                }
//                statusItem.button?.performClick(nil) // ...and click
//                return;
//            } else {
//
//            }
//        }
        
    }
    func showPopover(sender: Any?) {
        if let button = statusItem.button
        {
            if isDiscourageDefaultFocusVcVisible{
                return
            }
//            if isFocusModeOn(){
//                showBrainDumpWindow()
//            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
            
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }
    
//    func menuWillOpen(_ menu: NSMenu) {
//        //        menuViewControllerObj!.reloadData()
//        //        self.perform(#selector(reloadMenu), with: nil, with: 1)
//    }
//    @objc func reloadMenu(){
//        //        menuViewControllerObj!.reloadData()
//    }
//    @objc func menuDidClose(_ menu: NSMenu) {
//        statusItem.menu = nil // remove menu so button works as before// remove status menu aand statusitem.menu fromcode
//    }
    @objc func menuItemEnterLicenseKey(){
        addLog(text: "Showing Activate now view")
        activationWindowControllerObj?.showActivateNowVc()
        activateNowvcObj?.btnback.isHidden = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
//    @objc func menuItemGetALicenseKey(sender:NSMenuItem){
//        addLog(text: "menuItemGetALicenseKey")
//        activationWindowControllerObj?.showActivateNowVc()
//        activateNowvcObj?.btnback.isHidden = true
//        purchaseNow_clicked()
//        NSApplication.shared.activate(ignoringOtherApps: true)
//    }
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
                    UserDefaults.standard.removeObject(forKey: SettingsManagerObject.kUserdefaultsAppPassword)
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    addLog(text: "password is cleard after 24 hours")
                }
            }else{
                self.timerCheckClearPasswordTime?.invalidate()
                self.timerCheckClearPasswordTime = nil
            }
        }
    }
    
    func quitAndRestartApp(){
        addLog(text: "quitAndRestartApp")
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
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_{
            addLog(text: "Activity is running: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        
        if !isHardCorePomodoroModeOn{// if hardcore pomodoro is started than it will complete first
//            if avmonitor.isMicOn() || avmonitor.isACameraOn(){
//                addLog(text: "Mic/Camera Is On: Pomodoro Mode View cancelled")
//                setTimerForPomodoroMode(delay: 60*10)
//                return
//            }
//            if isPreventUserIdleDisplaySleepOn(){
//                addLog(text: "PreventUserIdleDisplaySleep is On: Pomodoro Mode View cancelled")
//                setTimerForPomodoroMode(delay: 60*10)
//                return
//            }
            if isUserOnMeeting{
                addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
                setTimerForPomodoroMode(delay: 60*10)
                return
            }
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
        pomodoroVcObj?.isShowingPomodoroManually = false
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    @objc func showMorningPomodoroModeView(){
        
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        
        if isFocusModeOn(){
            addLog(text: "Focus Mode Is On: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
//        if avmonitor.isMicOn() || avmonitor.isACameraOn(){
//            addLog(text: "Mic/Camera Is On: Pomodoro Mode View cancelled")
//            setTimerForPomodoroMode(delay: 60*10)
//            return
//        }
//        if isPreventUserIdleDisplaySleepOn(){
//            addLog(text: "PreventUserIdleDisplaySleep is On: Pomodoro Mode View cancelled")
//            setTimerForPomodoroMode(delay: 60*10)
//            return
//        }
        
        if isUserOnMeeting{
            addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        
        if isShutOffTimeGoing(){
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                //                get  what da is today and comapre from pomodoro settings
                let cday = SettingsManagerObject.getDayOfWeek(fromDate: Date()) ?? SettingsManagerObject.kSunday
                
                if let arrDays = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroArrDays) as? [String]{
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
        pomodoroVcObj?.isShowingPomodoroManually = false
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
                addLog(text: "focusModeStartWindowLodded. Pomodoro Mode View cancelled")
                return
            }
        }
        if self.timerPomodoroMode != nil{
            self.timerPomodoroMode?.invalidate()
            self.timerPomodoroMode = nil
        }
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                    getsmallCountDownVcObject().closeTimerBox()
                }
            }
        }
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        pomodoroWindowControllerObj?.contentViewController = pomodoroVcObj
        pomodoroWindowControllerObj?.showWindow(self)
        pomodoroVcObj?.isShowingPomodoroManually = true
        NSApplication.shared.activate(ignoringOtherApps: true)
    }


    
    @objc func checkWindowState(){//there will be no habit display on first day
        
//        *****************for testing only *********************
//
//
//                                use this to show AllMorningHabits
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj!.showAllMorningHabits()
//                                showBlankWindowInSecondaryMonitor()
//
//
//
//
//                                first time view
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj!.showFirstTimeVc()
//                                isFirstRun = true
//                                showBlankWindowInSecondaryMonitor()
//
//
//
//                                use this to show All Activities
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.executeBreakActivities()
//                                showBlankWindowInSecondaryMonitor()
//                                //////////
//
//
//                                Showing focus summary
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.showFocusSummaryView()
//                                showBlankWindowInSecondaryMonitor()
//                                //////////
//
//                                shutoff window
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.shutOffMac()
//
//                                show evening habits
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj?.showAllEveningHabits()
//                                showBlankWindowInSecondaryMonitor()
//                                self.perform(#selector(showMorningHabitAfterTimer), with: nil, afterDelay: 80)
//
//                                show top timer window
//                                showSmallTimerWindow(durationSeconds: 30, name: "yogaa")
//
//
//                                showMorningPomodoroModeView()
//
//                                show brain dump window
//                                showBrainDumpWindow()
//                                showAskLoginWindow()//
//
//
//                                use this to show abort done view
//                                mainWindowControllerObj?.showWindow(self)
//                                mainViewControllerObj!.showAbortConfirmationView()
//                                showBlankWindowInSecondaryMonitor()
//                                showUpgradeNowWindow()
//                                showWelcomeOnboardingWindow()
//                                showOnboardingVideoWindow()
//                                showOnboardingCardWindow(isLogin: true)
//                                showBreakWarningWindow()
//                                showPopupBlockConfirmWindow()
//                                showEasyPostponeWindow()
//                                showMorningPomodoroModeView()
//                                showPreloadFocusModesWindow()
//                                preloadFocusModesWindowControllerObj!.contentViewController = getHowHeardVcObj()
//                                showUpgradeNowWindow()
//                                showPopUpOfflineWindow()
//                                return;
//        todo®
//        *******************************************************************
        
        

        
        
//        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsFirstRun) == nil{// will never be true beacuse we have done this in the starting of will launch application function
//            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsFirstRun)
//            SettingsManagerObject.isSettingsChanged = true
//            SettingsManagerObject.putUserLocalDeviceSettings()
//            mainWindowControllerObj?.showWindow(self)
//            showBlankWindowInSecondaryMonitor()
//            mainViewControllerObj!.showFirstTimeVc()
//            isFirstRun = true
//
//
//
//            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
//            // changed 13/5/2022 // jis din app install hui h us din morning habit i aaygi bhale hi kitni hi bar app quit krke chalu krle(iske liya afirst time habit k time hi morning routine ki show date likhva lenege fir us din date write ho chuki h to morning habit ni aaygi +)
//
//            //  isHabitAlreadyShowed ko kuch ni krna h qki default hi true h ..
//
//
//
//
//
//        }else{
            isFirstRun = false
            if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
                
                checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
            }else{
                isHabitAlreadyShowed = false
            }
         
            if startTime != nil && shutOffTime != nil{
//                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!

                if isShutOffTimeGoing(){
                    if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                        if currentState != ._SHUTOFFMAC_{
                            self.shutOffMac()
                        }
                    }else{
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                            mainWindowControllerObj?.loadWindow()
                            if Date().compare(date) == .orderedDescending {
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                            }
                        }
                    }
                }else{
                    if !isHabitAlreadyShowed{
                        //   21/8/22
//                        if Date().compare(startDate) == .orderedAscending {//yha ni krenege qki andar se timer k hisab se kaam hoga q ki api se bhi check hota hai
//                            print("First Date is smaller then second date. all ok ")
//                        }else{
//                            self.startHabitsCall()
//                        }
                    }else{
                        mainWindowControllerObj?.loadWindow()
                        mainViewControllerObj?.setActivityTimer()
                    }
                }
            }
            setBackgroundThreadTimer()
       // }
        
    }
    
    
    func checkLastHabitShowDate(lastHabitShowDate:Date){
        isHabitAlreadyShowed = true
        let currentDate = Date()
        let year1 = Calendar.current.component(.year, from: lastHabitShowDate)
        let year2 = Calendar.current.component(.year, from: currentDate)
        
        
        
        if year2>year1{
            isHabitAlreadyShowed = false
        }else{
            if year1 == year2{
                let month1 = Calendar.current.component(.month, from: lastHabitShowDate)
                let month2 = Calendar.current.component(.month, from: currentDate)
                if month2>month1{
                    isHabitAlreadyShowed = false
                }else{
                    if month1 == month2{
                        let day1 = Calendar.current.component(.day, from: lastHabitShowDate)
                        let day2 = Calendar.current.component(.day, from: currentDate)
                        if day2>day1{
                            isHabitAlreadyShowed = false
                        }
                    }
                }
            }
        }
    }
    
    
    func setBackgroundThreadTimer(){
        addLog(text: "setBackgroundThreadTimer")
        DispatchQueue.global().sync {//async {
            self.timerBackgroundThread = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.backgroundThread), userInfo: nil, repeats: true)
//            RunLoop.current.add(self.timerBackgroundThread!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
            RunLoop.main.add((self.timerBackgroundThread!), forMode: RunLoop.Mode.common)
        }
    }
    
    var alertSuggestFocusMode:NSAlert?
    var isUserOnMeeting = false
  
    var isAutoMeetingsModeStarted = false
    var appUsedInAutoMeetingFocusMode = ""
    func checkIsMeetingsGoingOn(){
        let isMicOn = avmonitor.isMicOn()
        let isACameraOn = avmonitor.isACameraOn()
        let isPreventUserIdleDisplaySleepOn = isPreventUserIdleDisplaySleepOn()

        if isMicOn || isACameraOn || isPreventUserIdleDisplaySleepOn{
            if isMicOn{
                addLog(text: "func checkIsMeetingsGoingOn:- Mic is On")
            }
            if isACameraOn{
                addLog(text: "func checkIsMeetingsGoingOn:- Camera is On")
            }
            
            if isPreventUserIdleDisplaySleepOn{
                addLog(text: "func checkIsMeetingsGoingOn:- PreventUserIdleDisplaySleep is On")
            }
            
//            if SettingsManagerObject.isMeetingDetectionEnabled{
//                if isFocusModeOn(){
//                    self.statusbutton?.title = buttonStatusStateCallText + " / " + buttonStatusStateFocusText
//                }else{
//                    self.statusbutton?.title = buttonStatusStateCallText
//                    self.statusbutton?.imagePosition = .imageLeft
//                    self.statusbutton?.backgroundcolor = NSColor.systemBlue
//                }
//            }
//            if isFocusModeOn() || isHardCorePomodoroModeOn{
//                addLog(text: "func checkIsMeetingsGoingOn:- Focus mode or Super pomodoro Is On :- return")
//                return;
//            }

            
            
            

            
            if !SettingsManagerObject.isMeetingDetectionEnabled{
                addLog(text: "func checkIsMeetingsGoingOn:- Meeting Detection Disabled: return")
                return;
            }
            if alertSuggestFocusMode != nil{
                if alertSuggestFocusMode!.window.isVisible{
                    addLog(text: "func checkIsMeetingsGoingOn:- alertSuggestFocusMode is visible return")
                    return
                }
            }
            let runningApps = NSWorkspace.shared.runningApplications
            
            
            for i in 0..<arrFocusType.count{
                let focus = arrFocusType[i]
                if let state = focus["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        if let arr = focus["allowed_apps"] as? [String]{
                            for apppPath in arr{
                                for app in runningApps{
                                    if let appUrl = app.bundleURL{
                                        let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                                        let url = URL(fileURLWithPath: apppPath)
                                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                            
                                            if isUserOnMeeting{
                                                return
                                            }
                                            
                                            if nameLowercased == "microsoft teams" || nameLowercased == "zoom.us"{
                                                if !isPreventUserIdleDisplaySleepOn{
                                                    continue;
                                                }
                                            }
                                            
                                            
                                            if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                                                addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is a browser:- get current url")
                                                
                                                var isAllowed = false
                                                
                                                if let allTabUrls = getBrowserAllTabUrl(browser: browser){
                                                    for  activeTabUrl in allTabUrls{
                                                        
                                                        
                                                        
                                                        let domain = getDomainFromUrl(url: activeTabUrl)
                                                        if domain == "meet.google.com"{
                                                            let urlElements = activeTabUrl.components(separatedBy: "/")
                                                            if urlElements.last != "meet.google.com"{
                                                                isAllowed = true
                                                                break;
                                                            }
                                                        }
                                                        
                                                        let arrAllowedUrlsMeetingsFocus = focus["allowed_urls"] as? [String] ?? []
                                                        for turl in arrAllowedUrlsMeetingsFocus{
                                                            isAllowed = self.validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl, domain: domain)
                                                            if isAllowed{
                                                                break;
                                                            }
                                                        }
                                                        if isAllowed{
                                                            break;
                                                        }
                                                    }
                                                }
                                                
                                                if !isAllowed{
                                               
                                                    continue;
                                                }
 
                                            }
                                            
                                            addLog(text: "func checkIsMeetingsGoingOn:- Running meeting app is \(nameLowercased)")
                                            
                                            appUsedInAutoMeetingFocusMode = url.lastPathComponent
                                            isUserOnMeeting = true
                                            
                                            if isFocusModeOn(){
                                                self.statusbutton?.title = buttonStatusStateCallText + " / " + buttonStatusStateFocusText
                                            }else{
                                                self.statusbutton?.title = buttonStatusStateCallText
                                                self.statusbutton?.imagePosition = .imageLeft
                                                self.statusbutton?.backgroundcolor = NSColor.systemBlue
                                            }
                                            if  SettingsManagerObject.showMeetingDetectionAlert{
                                                timerMeetingStartAlert?.invalidate()
                                                timerMeetingStartAlert = nil
                                                
                                                timerMeetingStartAlert = Timer.scheduledTimer(timeInterval: 0, target: self, selector: #selector(self.showMeetingSuggestionAlert), userInfo: nil, repeats: false) //no need run loop////
                                            }else{
                                                addLog(text: "func checkIsMeetingsGoingOn:- showMeetingDetectionAlert setting is false:- return")
                                            }
                                            
                                            return;
                                        }
                                    }
                                }
                            }
                        }
                        if isUserOnMeeting{
                            isUserOnMeeting = false
                            if alertSuggestFocusMode != nil{
                                if alertSuggestFocusMode!.window.isVisible{
                                    NSApp.endSheet(alertSuggestFocusMode!.window)
                                    addLog(text: "close Meeting suggestion Alert")
                                }
                            }
                        }
                        break;
                    }
                }
            }
            
        }else{
            if isAutoMeetingsModeStarted{//end meetings focus mode
                if isFocusModeOn(){
                    focusModeFinished(isSilent: false)
                }
            }
            if isUserOnMeeting{
                isUserOnMeeting = false
                if alertSuggestFocusMode != nil{
                    if alertSuggestFocusMode!.window.isVisible{
                        NSApp.endSheet(alertSuggestFocusMode!.window)
                        addLog(text: "close Meeting suggestion Alert")
                    }
                }
            }
            
            
//            if isPreventUserIdleDisplaySleepOn(){
//                addLog(text: "func checkIsMeetingsGoingOn:- PreventUserIdleDisplaySleep is On")
//                if isFocusModeOn(){
//                    self.statusbutton?.title = buttonStatusStateCallText + " / " + buttonStatusStateFocusText
//                }else{
//                    self.statusbutton?.title = buttonStatusStateCallText
//                }
//
//                self.statusbutton?.imagePosition = .imageLeft
//                self.statusbutton?.backgroundcolor = NSColor.systemBlue

//            }else{
                self.statusbutton?.title = ""
                self.statusbutton?.backgroundcolor = NSColor.clear
                for dic in arrFocusType{
                    if dic["isOn"] as? Bool == true{
                        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: dic["color"] as? String ?? "")
                        setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                        appdelegate!.statusbutton?.imagePosition = .imageLeft
                    }
                }
//            }
            
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil

            
        }
    }
    func setStatusBarButtonTitleForFocusMode(title:String){
        if title.isEmpty{
            appdelegate!.statusbutton?.title = buttonStatusStateFocusText
        }else{
            let btnTitle = title.components(separatedBy: .newlines).joined()
            if btnTitle.count > 40 {
                appdelegate!.statusbutton?.title = String(btnTitle.prefix(40)) + "..."
            }else{
                appdelegate!.statusbutton?.title = btnTitle
            }
            
        }
    }
    var timerMeetingStartAlert:Timer?
    @objc func showMeetingSuggestionAlert(){
        timerMeetingStartAlert?.invalidate()
        timerMeetingStartAlert = nil
        addLog(text: "showMeetingSuggestionAlert")
        //        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._SHUTOFFMAC_ || currentState == .
        
        // Luisa App broken bug fix 28/6/22
        if mainWindowControllerObj?.window?.isVisible ?? false{
            addLog(text: "Meeting suggestion aborted due to activity.")
            return
        }
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SHUTOFFMAC_{
            addLog(text: "Meeting suggestion aborted due to activity.")
            return
        }
        
        //  ////////////
        
        
        
        alertSuggestFocusMode = NSAlert()
        alertSuggestFocusMode!.setSharingType()
        var notificationVideoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            notificationVideoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? notificationVideoCallText
        }
        
        var title = "It looks like you're in a meeting. Will you need to use other apps during the meeting? If not, I can block everything else to help you concentrate."
        var subTitle = "On selecting \"Block everything else\" the app will start \"Meetings\" focus mode."
        var buttonBlockText = "Block everything else"
        var buttonCancelText = "It's ok for me to use other apps during this meeting"
        var buttonFalseDetectionText = "False positive: I'm not in a meeting"
        var buttonGotItText = "Got it"
        var buttonCheckBoxText = "Don't show this again when I join meetings"
        
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
                if let val = suggestFocusInfo.value(forKey: "buttonFalseDetectionText") as? String{
                    buttonFalseDetectionText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonGotItText") as? String{
                    buttonGotItText = val
                }
                if let val = suggestFocusInfo.value(forKey: "buttonCheckBoxText") as? String{
                    buttonCheckBoxText = val
                }
            }
        }
        let isFocusModeOn = isFocusModeOn()
        alertSuggestFocusMode?.messageText = notificationVideoCallText
        
        if isFocusModeOn{
            alertSuggestFocusMode?.addButton(withTitle: buttonGotItText)
        }else{
            alertSuggestFocusMode?.informativeText = title + "\n\n" + subTitle
            alertSuggestFocusMode?.addButton(withTitle: buttonBlockText)
            alertSuggestFocusMode?.addButton(withTitle: buttonCancelText)
        }
        
        
        alertSuggestFocusMode?.addButton(withTitle: buttonFalseDetectionText)
        alertSuggestFocusMode?.showsSuppressionButton = true
        alertSuggestFocusMode?.suppressionButton?.title = buttonCheckBoxText
        alertSuggestFocusMode?.suppressionButton?.state = .off
        
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let window = NSApp.keyWindow{
            alertSuggestFocusMode?.beginSheetModal(for: window, completionHandler: { (result) in
                
                if self.alertSuggestFocusMode?.suppressionButton?.state == .on{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showMeetingDetectionAlert = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                
                if isFocusModeOn{
                    if result == .alertFirstButtonReturn{
                        print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        print("second")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Start Focus clicked")
                        self.meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        print("second")
                        addLog(text: "func Meeting Suggestion alert:- button Cancel clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        print("third")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }
                
            })
        
        }else{
            if let result = alertSuggestFocusMode?.runModal(){
                
                if alertSuggestFocusMode?.suppressionButton?.state == .on{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showMeetingDetectionAlert = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                
                if isFocusModeOn{
                    if result == .alertFirstButtonReturn{
                        print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        print("second")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Start Focus clicked")
                        meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        print("second")
                        addLog(text: "func Meeting Suggestion alert:- button Cancel clicked")
                        alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        print("third")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        alertSuggestFocusMode = nil
                        self.perform(#selector(showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }
            }
        }
        
    }
    
    @objc func showAlertFalseMicDetection(){
        addLog(text: "func showAlertFalseMicDetection")
        alertSuggestFocusMode = NSAlert()
        alertSuggestFocusMode!.messageText = "Sorry about that. Are you sure you're not using an app that is using your microphone? If we keep getting it wrong, click button below to disable meeting detection."
        var buttonDisableText = "Disable meeting detection"
        
        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
            if let suggestFocusInfo = focusInfo.value(forKey: "suggestFocusInfo") as? NSDictionary{
                alertSuggestFocusMode!.messageText = suggestFocusInfo.value(forKey: "titleFalseDetection") as? String ?? alertSuggestFocusMode!.messageText
                buttonDisableText = suggestFocusInfo.value(forKey: "buttonDisableText") as? String ?? buttonDisableText
            }
        }
        
        alertSuggestFocusMode!.addButton(withTitle: buttonDisableText)
        alertSuggestFocusMode!.addButton(withTitle: buttonCancelText)
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        if let window = NSApp.keyWindow{
            alertSuggestFocusMode?.beginSheetModal(for: window, completionHandler: { (result) in
                if result == .alertFirstButtonReturn{
                    print("first")
                    addLog(text: "func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    self.alertSuggestFocusMode = nil
                    
                    if self.isUserOnMeeting{
                        self.isUserOnMeeting = false
                    }
                    self.statusbutton?.title = ""
                    self.statusbutton?.backgroundcolor = NSColor.clear
                }else{
                    print("second")
                    addLog(text: "func showAlertFalseMicDetection:- Button Cancel clicked")
                    self.alertSuggestFocusMode = nil
                }
            })
        
        }else{
            if let result = alertSuggestFocusMode?.runModal(){
                if result == .alertFirstButtonReturn{
                    print("first")
                    addLog(text: "func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    alertSuggestFocusMode = nil
                    
                    if isUserOnMeeting{
                        isUserOnMeeting = false
                    }
                    self.statusbutton?.title = ""
                    self.statusbutton?.backgroundcolor = NSColor.clear
                }else{
                    print("second")
                    addLog(text: "func showAlertFalseMicDetection:- Button Cancel clicked")
                    alertSuggestFocusMode = nil
                }
            }
        }
    }
    
    func meetingAlertStartFocusClicked(){
        print("first")
        addLog(text: "meeting Alert Start Focus Clicked")
        for i in 0..<arrFocusType.count{
            let focus = arrFocusType[i]
            if let state = focus["isMeetings"] as? Bool{
                if  state{
                    if getEndFocusModeWindowControllerObj().window!.isVisible{
                        let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                        addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "")
                        getEndFocusModeWindowControllerObj().window?.close()
                    }
                    let calendar = Calendar.current
                    endFocusModeTime = calendar.date(byAdding: .minute, value: 5, to: Date())
                    startFocusModeTime = Date()
                    arrFocusType[i]["isOn"] = true
                    workBeforeFocusBegin(index: i)
                    focusModeMinutesToPerform = 0
                    
                    appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[i]["color"] as? String ?? "")
                    appdelegate!.statusbutton?.title = buttonStatusStateFocusText
                    appdelegate!.statusbutton?.imagePosition = .imageLeft
                    if timerForFocusMode != nil{
                        timerForFocusMode?.invalidate()
                        timerForFocusMode = nil
                    }
                    isFocusTimeType = ._HOUR_
                    
                    isFocusModeStartedFromPomodoroMode = false
                    whatToAchieveInFocusBlock = ""
                    setIntensionInBrainDumpWindow()
                    appdelegate!.focusModeStartted()
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    
                    
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
                }
            }
        }
    }
    
 
    
    func returnFromSystemSleepCheckAppStateAgain(){
        addLog(text: "func:- returnFromSystemSleepCheckAppStateAgain")
        
        if pomodoroWindowControllerObj != nil{
            if pomodoroWindowControllerObj?.window?.isVisible ?? false{
                if pomodoroVcObj?.timer != nil {
                    if pomodoroVcObj!.timer!.isValid{
                        pomodoroVcObj?.currentTimer = unfocusedTime
                    }
                }
            }
        }
        
        
        if currentState == ._ACTIVITY_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_MORNING_HABIT_ || !isAppEnable || currentState == ._ABORT_{
            addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- currentState is activity/postpone/abort")
            return
        }
        
        if isShutOffTimeGoing(){
            if arrAllEveningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrAllEveningHabits count is 0")
                return;
            }
        }else{
            if arrAllMorningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrAllMorningHabits count is 0")
                return;
            }else if isHabitAlreadyShowed{
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- habit showed already")
                return;
            }
        }
        
//        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
//            if Reachability.isConnectedToNetwork() == false {
//                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- no internet connection")
//                return
//            }
////            if currentAction == ._VISUALIZE_ && (mainWindowControllerObj?.window?.isVisible ?? false){
////                return
////            }
//        }
        
        if popUpOfflineWcObj != nil{
            if popUpOfflineWcObj?.window?.isVisible ?? false{
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- popUpOffline window visible")
                return;
            }
        }
        self.abortAllProcess()//
        currentState = ._NOTHING_
        if mainWindowControllerObj?.window?.isVisible ?? false{
            mainWindowControllerObj?.window?.close()
            hideBlankWindowInSecondaryMonitor()
        }
        backgroundThread()
    }
    
    
    
    var isProcessingHabitRoutine = false
    var isProcesssingOfflineData = false
    
    func processOfflineData(){

        if !self.isProcesssingOfflineData{
            DispatchQueue.global().async {
                if Reachability.isConnectedToNetwork() == true{
                    self.isProcesssingOfflineData = true
                    var arr = readDataFromCSV(url: offlineActivitiesCsvURL!)
                    print(arr)
                    if arr.last?.count == 1{
                        arr.removeLast()
                    }
                    if arr.count > 1{
                        
                        // take first 5 entry
                        var arrDic = [[String : Any]]()
                        let headers  = arr.first!
                        arr.removeFirst()
                        let newArr = arr
                        var maxCount = 50
                        var isLastLoop = false
                        if newArr.count > maxCount{
                            //let firstBatch = newArr
                            
                            
                        }else{
                            maxCount = newArr.count
                            isLastLoop = true
                            
                        }
                        
                        for j in 0..<maxCount{
                            let subarray = newArr[j]
                            if subarray.count != headers.count{// column numbers are fixed so verifying content while reading
                                
                            }else{
                                var dic = [String:Any]()
                                for i in 0..<subarray.count{
                                    
                                    dic[headers[i]] = subarray[i]
                                }
                                dic["duration_logged"] = Int(dic["duration_logged"] as? String ?? "") ?? 0
                                
                                let quantity_logged_string = dic["quantity_logged"] as? String ?? ""
                                if quantity_logged_string.isEmpty{
                                    dic.removeValue(forKey: "quantity_logged")
                                }else{
                                    dic["quantity_logged"] = Double(quantity_logged_string) ?? 0
                                }
                                
                                
                                
                                
                                if j == newArr.count - 1{
                                    if isLastLoop{
                                        //                                        if let lastActivity = newArr.last{
                                        //                                            if let activity = lastActivity["skipped_did_not_complete"]{
                                        //
                                        //                                            }
                                        //                                        }
                                        if let val = dic["skipped_did_not_complete"] as? String{
                                            let activity_sequence_id = dic["activity_sequence_id"] as? String ?? ""
                                            let start_time_String = dic["start_time"] as? String ?? ""
                                          
                                            let morningStartDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                            let start_time = getDateFromStringInUtc(date: start_time_String, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") ?? Date()
                                            if start_time.compare(morningStartDate) == .orderedDescending{
                                                var choice_id:String?
                                                if let id = dic["choice_id"] as? String{
                                                    if !id.isEmpty{
                                                        choice_id = id
                                                    }
                                                }
                                                
                                                var quantity_logged:Double?
                                                
                                                if let val = dic["quantity_logged"] as? Double{
                                                    quantity_logged = val
                                                }
                                                
                                                
                                                let duration_logged = dic["duration_logged"] as? Int ?? 0
                                                let activity_id = dic["activity_id"] as? String ?? ""
                                                
                                                
                                                if val == "true"{
                                                    allApiObject.activitySkippedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, completionHandler: {dic in

                                                    })
                                                }else{
                                                    var is_skipped = false
                                                    if let skipped_did_complete = dic["skipped_did_complete"] as? String{
                                                        if skipped_did_complete == "true"{
                                                            is_skipped = true
                                                        }
                                                    }
                                                    
                                                    
                                                    allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, is_skipped: is_skipped, completionHandler: {dic  in

                                                        DispatchQueue.main.async {

                                                        }
                                                        print(dic)
                                                    })
                                                }
                                            }
                                            
                                            
                                            
                                        }
                                    }
                                }
                                
//                                    "metadata": {
//                                                    "skipped_did_complete": true
//                                                }
                                var metadataDic = [String : Any]()
                                if let val = dic["skipped_did_not_complete"] as? String{
                                    dic.removeValue(forKey: "skipped_did_not_complete")
                                    var skipped_did_not_complete = false
                                    if val == "true"{
                                        skipped_did_not_complete = true
                                    }else{
                                        skipped_did_not_complete = false
                                    }
                                    metadataDic["skipped_did_not_complete"] = skipped_did_not_complete
                                }
                                
                                if let val = dic["skipped_did_complete"] as? String{
                                    dic.removeValue(forKey: "skipped_did_complete")
                                    var skipped_did_complete = false
                                    if val == "true"{
                                        skipped_did_complete = true
                                    }else{
                                        skipped_did_complete = false
                                    }
                                    metadataDic["skipped_did_complete"] = skipped_did_complete
                                }
                                
                                dic["metadata"] = metadataDic
                                
                                
                                print(dic)
                                arrDic.append(dic)
                            }
                        }
                        
                        if arrDic.count == 0{
                            self.isProcesssingOfflineData = false
                            return;
                        }
                        
                        allApiObject.syncOfflineDataApi(offineData: arrDic, completionHandler: { json in
                         //   print(json)
                            if json != nil{
                                removeEntryInActivitiesCsv(count: maxCount)
                            }
                            self.isProcesssingOfflineData = false
                        }
                        )
                        
                    }else{
                        self.isProcesssingOfflineData = false
                    }
                }
            }
            
        }
    }
    @objc func backgroundThread(){
//        if isProcessingHabitRoutine{
//            return
//        }
//        print(NSApp.keyWindow)
        DispatchQueue.main.async {

            if isAppEnable{// agar app diable hai to sirf 1 case mai ye func call hoga jab app 4 hour deactivate h tb
                self.checkIsMeetingsGoingOn() //and app kon kon si check krni haiu
            }
            

            self.processOfflineData()
            
            
            //save progress during an activity (morning and evening) Progress lost when I restarted my computer during an activity#444
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && timerViewcontrollerObj != nil{
                if timerViewcontrollerObj?.timer?.isValid ?? false{
                    let infoDic:[String:Any] = ["id":lastActivityRunningId, "duration":timerViewcontrollerObj?.currentTimer ?? 0, "date":Date()]
                    UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastHabitRunningInfo)
                    print(infoDic)//todo evening habit k case mai til evening date vala time save kro verna bigad jayga just like kUserdefaultsFocusSummaryShowedTillDate
                }

            }
            //  ////////////////////////////////////////////////////////////////
            
            if currentState == ._ABORT_{
                return;
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
            
            
            if !self.isSystemSleep && !self.isScreenSaverStart && currentState != ._ACTIVITY_{//same condition in pomodoro view
                unfocusedTime += 5
            }
            
            if isShutOffTimeGoing(){
                
                if arrAllEveningHabits.count == 0 {
                    return;
                }
                if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromEveningHabit{// new work  24/12/22
                    return;
                }
                isBreakActivityExecuteFromMorningHabit = false
                
                
                if currentState == ._POSTPON_MORNING_HABIT_{//if user postpone again and again
                    currentState = ._NOTHING_
                }
                if currentState == ._POSTPON_FOCUS_SUMMARY_{
                    addLog(text: "Focus Summary is Postponed. Focus Summary Time checking Cancelled.")
                    return;
                }
                
                if currentState == ._POSTPON_EVENING_HABIT_{
                    addLog(text: "Evening Routine is Postponed. Evening Habits Time checking Cancelled.")
                    return;
                }
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
                    
                    if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromMorningHabit{// new work  24/12/22
                        return;
                    }
                    isBreakActivityExecuteFromEveningHabit = false
                    
                    if currentState != ._MORNING_HABIT_{
                        if currentState == ._POSTPON_EVENING_HABIT_{//if user postpone again and again
                            currentState = ._NOTHING_
                        }

                        if !isHabitAlreadyShowed{
                            if Date().compare(startDate) == .orderedAscending {
                                print("First Date is smaller then second date. all ok ")
                                //first date is smaller than second
                            }else{
                                
                              
                                if arrAllMorningHabits.count == 0 {
                                    print("arr AllMorningHabits count is 0:-  skip morning habit")
                                    isHabitAlreadyShowed = true
                                    unfocusedTime = 0
                                    if !isMainWindowLodded{
                                        mainWindowControllerObj?.loadWindow()
                                    }else if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                        self.abortAllProcess()
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                    }
                                    mainViewControllerObj?.setActivityTimer()
                                }
                                
                                
                                
                                // ye check krenge start habit k time ki pahle se koi sequence calu hai kya nahi h to morning habit start krdenge
                                // ya agar pahle se sequence chalu hai or uski date kal ki hai to bhi use force complete kr denge
                                // or agar pahele se koi sequence chalu h to agar vo morning habit ka nahi h to use force complete kr denge
                                
                                // or agar vo mrning habit sequence pahle se chalu hai to use get krenege or vahi se coontinue krenge
                                
                                //********************** new work*************************//
                            
                                if !self.isProcessingHabitRoutine{
                                    
                                    
                                    
                                    
                                    if currentState == ._POSTPON_MORNING_HABIT_{
                                        addLog(text: "Morning Routine is Postponed. Morning Habits Time checking Cancelled.")
                                        return;
                                    }
//                                    if avmonitor.isMicOn(){
//                                        addLog(text: "Mic is in use, Morning Habits Time checking Cancelled.")
//                                        return;
//                                    }
//                                    if avmonitor.isACameraOn(){
//                                        addLog(text: "Camera is is use, Morning Habits Time checking Cancelled.")
//                                        return;
//                                    }
//
//                                    if isPreventUserIdleDisplaySleepOn(){
//                                        addLog(text: "PreventUserIdleDisplaySleep is On: Morning Habits Time checking Cancelled.")
//                                        return
//                                    }
                                    if self.isUserOnMeeting{
                                        addLog(text: "isUserOnMeeting True: Morning Habits Time checking Cancelled.")
                                        return
                                    }
                                    
                                    self.isProcessingHabitRoutine = true
                                    addLog(text: "get Last Activity Info")
                                    allApiObject.getLastActivityInfo(completionHandler: { json in
                                        DispatchQueue.main.async {
                                            if json != nil{
                                                print(json)
                                                
                                                // additional check that if user change pc and there is not locally save that morning routine is done today than  check is there morning routine done by user or not
                                                if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                                                    if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                                        if let sequenceID = arrAllMorningHabits.first?.activity_sequence_id{
                                                            if lastCompletedSequenceId == sequenceID{
                                                                if let lastCompletedSequenceStartedAt = json?.value(forKey: "last_completed_sequence_started_at") as? String{
                                                                    if let activityStartDate = getDateFromStringInUtc(date: lastCompletedSequenceStartedAt, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {

                                                                        if activityStartDate.compare(startDate) == .orderedDescending{//if activityAssignedDate > startDate
                                                                            // aaj hi hui hai

                                                                            UserDefaults.standard.set(activityStartDate, forKey: kUserdefaultsLastHabitShowDate)
                                                                            isHabitAlreadyShowed = true
                                                                            self.isProcessingHabitRoutine = false
                                                                            if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                                self.abortAllProcess()
                                                                                mainWindowControllerObj?.window?.close()
                                                                                hideBlankWindowInSecondaryMonitor()
                                                                            }
                                                                            mainWindowControllerObj?.loadWindow()
                                                                            mainViewControllerObj?.setActivityTimer()
                                                                            addLog(text: "morning habit already shown for today -  return")
                                                                            return
                                                                        }

                                                                    }
                                                                }


                                                            }
                                                        }
                                                    }
                                                }
                                                //
                                                if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
                                                    if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                        if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
                                                            
                                                            if let currentActivity = json?.value(forKey: "current_activity") as? NSDictionary{
                                                                if let sequenceId = currentActivitySequence.value(forKey: "id") as? String, let activityId = currentActivity.value(forKey: "id") as? String{
                                                                    
                                                                    
                                                                    
                                                                    if let habitSequenceID = arrAllMorningHabits.first?.activity_sequence_id{
                                                                        
                                                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                                        
                                                                        if activityAssignedDate.compare(startDate) == .orderedDescending{//if activityAssignedDate > startDate
                                                                            // morning activity start hui thi lekin puri nahi hui hai
                                                                            if habitSequenceID == sequenceId{
                                                                                print("current_activity_sequence is pending")
                                                                                addLog(text: "morning habit sequnce is pending. start from current pending habit")
                                                                                self.isProcessingHabitRoutine = false
                                                                                var skippedActivities = [String]()
                                                                                if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
                                                                                    skippedActivities = activities
                                                                                }
                                                                                self.startHabitsCall(activityId: activityId, skippedActivities:skippedActivities)
                                                                            }else{//it means current activity is not morning habit and morning habit done for today
                                                                                addLog(text: "current activity is not morning habit and it means morning habit done for today")
                                                                                UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                                                                
                                                                                isHabitAlreadyShowed = true
                                                                                self.isProcessingHabitRoutine = false
                                                                                if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                                    self.abortAllProcess()
                                                                                    mainWindowControllerObj?.window?.close()
                                                                                    hideBlankWindowInSecondaryMonitor()
                                                                                }
                                                                                mainWindowControllerObj?.loadWindow()
                                                                                mainViewControllerObj?.setActivityTimer()
                                                                                
                                                                                allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                                                                                    
                                                                                    
                                                                                    DispatchQueue.main.async {
             
                                                                                    }
                                                                                })
                                                                                
                                                                            }
                                                                        }
                                                                        else{
                                                                            print("pending routin is not from current day clean all running sequence")
                                                                            addLog(text: "pending routin is not from current day clean all running sequence")
                                                                            allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: false, completionHandler: {json in
                                                                                
                                                                                
                                                                                DispatchQueue.main.async {
                                                                                    addLog(text: "start new morning routine sequence")
                                                                                    self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                                                    self.isProcessingHabitRoutine = false
                                                                                }
                                                                            })
                                                                        }
                                                                        
                                                                    }
                                                                }else{
                                                                    addLog(text: "start new morning routine sequence:- current sequence Id or current activity Id not found")
                                                                    self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                                    self.isProcessingHabitRoutine = false
                                                                }
                                                            }else{
                                                                addLog(text: "start new morning routine sequence:- current_activity not found as dictionary")//todo ktyaa krna chahiye yha
                                                                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                                var isForToday = false
                                                                if activityAssignedDate.compare(startDate) == .orderedDescending{
                                                                    isForToday = true
                                                                }
                                                                if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
                                                                    addLog(text: "pending routin is not for use clean all running sequence")
                                                                    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
                                                                        
                                                                        
                                                                        DispatchQueue.main.async {
                                                                            addLog(text: "start new morning routine sequence")
                                                                            self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                                            self.isProcessingHabitRoutine = false
                                                                        }
                                                                    })
                                                                }else{
                                                                    addLog(text: "start new morning routine sequence")
                                                                    self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                                    self.isProcessingHabitRoutine = false
                                                                }
                                                            }
                                                        }else{
                                                            addLog(text: "start new morning routine sequence:- current_activity_sequence not found as dictionary")
                                                            self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                            self.isProcessingHabitRoutine = false
                                                        }
                                                    }else{
                                                        addLog(text: "start new morning routine sequence:- can't create Date object from current_activity_assigned_at")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                        self.isProcessingHabitRoutine = false
                                                    }
                                                }else{
                                                    addLog(text: "start new morning routine sequence :- current_activity_assigned_at not found")
                                                    self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                                //                                        }
                                            }else{
                                                addLog(text: "func backgrounThread:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                                                if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitsStartedDate) as? Date{
                                                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                    addLog(text: "start new morning routine sequence:- LastHabitsStartedDate found")
                                                    if date.compare(startDate) == .orderedDescending{//if
                                                        if let lastActivityId = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitID) as? String{
                                                            for i in 0..<arrAllMorningHabits.count{
                                                                if arrAllMorningHabits[i].id == lastActivityId{
                                                                    if i == arrAllMorningHabits.count - 1{// this case will never happened because we will write morning habit done (kUserdefaultsLastHabitShowDate) locally if all activities done in morning habit
                                                                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                                                        
                                                                        isHabitAlreadyShowed = true
                                                                        self.isProcessingHabitRoutine = false
                                                                        if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                            self.abortAllProcess()
                                                                            mainWindowControllerObj?.window?.close()
                                                                            hideBlankWindowInSecondaryMonitor()
                                                                        }
                                                                        mainWindowControllerObj?.loadWindow()
                                                                        mainViewControllerObj?.setActivityTimer()
                                                                    }else{
                                                                        addLog(text: "start new morning routine sequence:- Last Habit id is from morning habit, show morning Habit from last habit id found in userdefaults")
                                                                        self.isProcessingHabitRoutine = false
                                                                        self.startHabitsCall(activityId: arrAllMorningHabits[i+1].id, skippedActivities:[])
                                                                    }
                                                                    
                                                                    return;
                                                                }
                                                            }
                                                            
                                                            addLog(text: "start new morning routine sequence Last Habit id is not from morning habit")
                                                            self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                            self.isProcessingHabitRoutine = false
                                                            
                                                        }else{
                                                            addLog(text: "start new morning routine sequence:- Last Habit id is nil")
                                                            self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                            self.isProcessingHabitRoutine = false
                                                        }
                                                    }else{
                                                        addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is not from current day")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                        self.isProcessingHabitRoutine = false
                                                    }
                                                }else
                                                {
                                                    addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is nil")
                                                    self.startHabitsCall(activityId: nil, skippedActivities:[])
                                                    self.isProcessingHabitRoutine = false
                                                }

                                            }
                                        }
                                    }
                                    )
                                }
                                
                                
                                
                                
                                //***********************************************************//
                                
                                // return;
                            }
                        }else{
                            if arrAllMorningHabits.count != 0 {
                                if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
                                    self.checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
                                }
                            }
                        }
                    }
                }
                
            }
            
            //}
        }
    }

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
//            if currentState == ._EVENING_HABIT_{
//                addLog(text: "current state is :- evening habits")
//            }
//                //            else if currentState == ._FOCUS_COMPLETED_{
//                //                addLog(text: "current state is :- focus completed view")
//                //            }
//            else if currentState == ._FOCUS_SUMMARY_{
//                addLog(text: "current state is :- focus summary")
//            }
            return;
        }
        
        
        
        //  ************* solving evening routine abort bug 2/3/22
        //agar svenening routine abort krte h to abort state ho jati h or abbort state yha cancel hkar vapas shut off show ho jata h . to use handle krenege
        // agar abort state h  or shutOff time nikl chuka hai or evening routing show h chuki h to abort state hi rhne denge  or return kr denege
        
//        if currentState == ._ABORT_{ths will never execute beacuse allreday has checked  about abort state in background thread
//            if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
//                if Date().compare(date) == .orderedDescending {
//
//                }else{
//                    //Evening habits already shown for today
//                    return;
//                }
//            }
//        }
        
        
        //  **************
        
        abortAllProcess()
        if isFocusModeOn(){
            focusModeFinished(isSilent: true)
            return;
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
            if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                mainWindowControllerObj?.loadWindow()
            }
            mainViewControllerObj!.showFocusSummaryView()
            return;
        }else{
            if let date = UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date{
                if Date().compare(date) == .orderedDescending {
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsFocusSummaryShowedTillDate)
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
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
                processEveningHabit()
                return;
                //}
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsEveningHabitsShowedTillDate) as? Date{
                    if Date().compare(date) == .orderedDescending {
//                        UserDefaults.standard.removeObject(forKey: kUserdefaultsEveningHabitsShowedTillDate)
                        processEveningHabit()
                        return;
                    }else{
                        addLog(text: "Evening habits already shown for today - skipping.")
                    }
                }
                
                
                
            }
        }else{
            print("arr AllEveningHabits count is 0:-  skip Evening habit")
        }

        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        mainViewControllerObj!.shutOffMac()
        showBlankWindowInSecondaryMonitor()
    }
    func showEveningHabit(activityId: String?, skippedActivities:[String]){
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        
        if activityId == nil{
            mainViewControllerObj!.showAllEveningHabits()
        }else{
            var isActivityFound = false
            for i in 0..<arrAllEveningHabits.count{
                if arrAllEveningHabits[i].id == activityId!{
                    isActivityFound = true
                    if i == 0{
                        mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false)
                    }else{
                        if skippedActivities.count == 0{
                            habitTotalCompletedSeconds = 0
                            for j in 0..<i{
                                habitTotalCompletedSeconds += arrAllEveningHabits[j].durationSeconds!
                            }
                            if i-1 >= 0{
                                UserDefaults.standard.set(arrAllEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                            }
                            
                            mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false)
                        }else{
                            var isLastActivitySkipped = false
                            if let lastActivityId = arrAllEveningHabits[i-1].id{
    
                                if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                    isLastActivitySkipped = true
                                }
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    let habit = arrAllEveningHabits[j]
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                        //skiped
                                    }else{
                                        habitTotalCompletedSeconds += habit.durationSeconds!
                                        //completed
                                    }
                                    
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrAllEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                }
                            }
                            mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: isLastActivitySkipped)
                        }
                    }
                    break;
                }
            }
            if !isActivityFound{
                addLog(text: "func showEveningHabit:- current activity id from actiity props not found in habit list.")
                quitAndRestartApp()
            }
        }
        
    }

    func processEveningHabit(){
        if !self.isProcessingHabitRoutine{
            self.isProcessingHabitRoutine = true
            let shutoffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            addLog(text: "get Last Activity Info process Evening Habit")
            allApiObject.getLastActivityInfo(completionHandler: { json in
                DispatchQueue.main.async {
                    if json != nil{
                        print(json)
                        // additional check that if user change pc and there is not locally save that evening routine is done today than  check is there morning routine done by user or not
                        if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                            if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                if let sequenceID = arrAllEveningHabits.first?.activity_sequence_id{
                                    if lastCompletedSequenceId == sequenceID{
                                        if let lastCompletedSequenceStartedAt = json?.value(forKey: "last_completed_sequence_started_at") as? String{
                                            if let activityStartDate = getDateFromStringInUtc(date: lastCompletedSequenceStartedAt, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                             
                                                if activityStartDate.compare(shutoffDate) == .orderedDescending{//if activityAssignedDate > shutoffDate
                                                    // aaj hi hui hai/
          
                                                    if startTime == nil || shutOffTime == nil{
                                                        return;
                                                    }
                                                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                                                    
                                                    let curreentDate = Date()
                                                    if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                                                        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                                                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                                    }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                                                        UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
                                                    }
                                                    isHabitAlreadyShowed = false
                                                    self.isProcessingHabitRoutine = false
                                                    addLog(text: "evening habit already Done for today")
                                                    return
                                                }
                                                
                                            }
                                        }
                                        
                                        
                                    }
                                }
                            }
                        }
                        //
                        if let current_activity_assigned_at = json?.value(forKey: "current_activity_assigned_at") as? String{
                            if let activityAssignedDate = getDateFromStringInUtc(date: current_activity_assigned_at, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                if let currentActivitySequence = json?.value(forKey: "current_activity_sequence") as? NSDictionary{
                                    
                                    if let currentActivity = json?.value(forKey: "current_activity") as? NSDictionary{
                                        if let sequenceId = currentActivitySequence.value(forKey: "id") as? String, let activityId = currentActivity.value(forKey: "id") as? String{
                                            
                                            
                                            
                                            addLog(text: "processEveningHabit - pending sequence id - \(sequenceId)")
                                            if let habitSequenceID = arrAllEveningHabits.first?.activity_sequence_id{
                                                
                                                
                                                if activityAssignedDate.compare(shutoffDate) == .orderedDescending && habitSequenceID == sequenceId{//if activityAssignedDate > shutoffDate
                                                    // evening activity start hui thi lekin puri nahi hui hai
                                                    
                                                    if habitSequenceID == sequenceId{
                                                        print("current evening routine sequence is pending")
                                                        addLog(text: "current evening routine sequence is pending")
                                                        self.isProcessingHabitRoutine = false
                                                        var skippedActivities = [String]()
                                                        if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
                                                            skippedActivities = activities
                                                        }
                                                        self.showEveningHabit(activityId: activityId, skippedActivities: skippedActivities)
                                                    }else{
                                                      
                                                        addLog(text: "pending routine is not evening routine - \(sequenceId)")
                                                        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                                                            // and strt break activity
                                                            DispatchQueue.main.async {
                                                                addLog(text: "start new evening routine sequence")
                                                                self.showEveningHabit(activityId: nil, skippedActivities: [])
                                                                self.isProcessingHabitRoutine = false
                                                            }
                                                        })
                                                    }
                                                    
                                                }else{
                                                    print("processEveningHabit - pending  routine is not from current day clean all running sequence or pending sequence is not evening routine - \(sequenceId)")
                                                    addLog(text: "processEveningHabit - pending  routine is not from current day clean all running sequence or pending sequence is not evening routine - \(sequenceId)")
                                                    
                                                    var isForToday = false
                                                    if activityAssignedDate.compare(shutoffDate) == .orderedDescending{
                                                        isForToday = true
                                                    }
                                                    
                                                    allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
                                                        // and strt break activity
                                                        DispatchQueue.main.async {
                                                            addLog(text: "start new evening routine sequence")
                                                            self.showEveningHabit(activityId: nil, skippedActivities: [])
                                                            self.isProcessingHabitRoutine = false
                                                        }
                                                    })
                                                }
                                            }
                                            
                                        }else{
                                            addLog(text: "start new evening routine sequence:- current sequence Id or current activity Id not found")
                                            self.showEveningHabit(activityId: nil, skippedActivities: [])
                                            self.isProcessingHabitRoutine = false
                                        }
                                    }else{
                                        addLog(text: "start new evening routine sequense:- current_activity not found as dictionary")
                                        
                                        if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
                                            addLog(text: "pending routin is not for use clean all running sequence")
                                            
                                            var isForToday = false
                                            if activityAssignedDate.compare(shutoffDate) == .orderedDescending{
                                                isForToday = true
                                            }
                                            
                                            
                                            allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
                                                // and strt break activity
                                                DispatchQueue.main.async {
                                                    addLog(text: "start new evening routine sequence")
                                                    self.showEveningHabit(activityId: nil, skippedActivities: [])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                            })
                                            
                                        }else{
                                            addLog(text: "start new evening routine sequence")
                                            self.showEveningHabit(activityId: nil, skippedActivities: [])
                                            self.isProcessingHabitRoutine = false
                                        }
                                    }
                                }else{
                                    addLog(text: "start new evening routine sequense:- current_activity_sequence not found as dictionary")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                }
                            }else{
                                addLog(text: "start new evening routine sequence:- can't create Date object from current_activity_assigned_at")
                                self.showEveningHabit(activityId: nil, skippedActivities: [])
                                self.isProcessingHabitRoutine = false
                            }
                        }else{
                            addLog(text: "start new evening routine sequence :- current_activity_assigned_at not found")
                            self.showEveningHabit(activityId: nil, skippedActivities: [])
                            self.isProcessingHabitRoutine = false
                        }
                        //                                        }
                    }else{
                        addLog(text: "func processEveningHabit:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitsStartedDate) as? Date{
                            
                            addLog(text: "start new evening routine sequence:-LastHabitsStartedDate found")
                            if date.compare(shutoffDate) == .orderedDescending{//if
                                if let lastActivityId = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitID) as? String{
                                    for i in 0..<arrAllEveningHabits.count{
                                        if arrAllEveningHabits[i].id == lastActivityId{
                                            addLog(text: "start new evening routine sequence:- Last Habit id is from evening habit, show eveningHabit from last habit id found in userdefaults")
                                            self.isProcessingHabitRoutine = false
                                            self.showEveningHabit(activityId: arrAllEveningHabits[i+1].id, skippedActivities:[])
                                            return;
                                        }
                                    }
                                    
                                    addLog(text: "start new evening routine sequence:- Last Habit id is not from evening habit")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                    
                                }else{
                                    addLog(text: "start new evening routine sequence:- Last Habit id is nil")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                }
                            }else{
                                addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is not from current day")
                                self.showEveningHabit(activityId: nil, skippedActivities: [])
                                self.isProcessingHabitRoutine = false
                            }
                        }else{
                            addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is nil")
                            self.showEveningHabit(activityId: nil, skippedActivities: [])
                            self.isProcessingHabitRoutine = false
                        }
                        
                    }
                }
            }
            )
        }
    }// easy postpone ka dibba pda ho to use marna hai 
    
    func abortAllProcess(){// do not change current state and current action inside this function
        addLog(text: "call abort all process.")
        //        if (mainWindowControllerObj?.window!.isVisible)! {// jaruri ni h ki window dikh hi rhi ho
        if currentAction == ._INPROGRESS_{
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        enableSystemSleep()
                        if timerViewcontrollerObj?.webView.isHidden == false{
                            timerViewcontrollerObj?.loadBlankUrl()
                        }
                        
                        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                        isAnyAllowedFocusModeActivityRunning = false
                        closePupUpBlockIfVisible()
                        
                        currentHabitPlaying = nil
                        timerAllowUrlForActivity?.invalidate()
                        timerAllowAppForActivity?.invalidate()
                        currentActivityPlaying = nil
                        
                        
                        if smallCountDownWcObj != nil{
                            if smallCountDownWcObj!.window?.isVisible ?? false{
                                getsmallCountDownVcObject().closeTimerBox()
                            }
                        }
                    }
                    DispatchQueue.global().async {// did this beacuse some times action is in progress but timer is not initialized and it takes 1 second to initialize
                        DispatchQueue.main.async {
                            if timerViewcontrollerObj?.timer != nil {
                                timerViewcontrollerObj?.timer?.invalidate()
                                enableSystemSleep()
                                if timerViewcontrollerObj?.webView.isHidden == false{
                                    timerViewcontrollerObj?.loadBlankUrl()
                                }
                                
                                arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
                                arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
                                arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
                                arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
                                isAnyAllowedFocusModeActivityRunning = false
                                currentHabitPlaying = nil
                                self.timerAllowUrlForActivity?.invalidate()
                                self.timerAllowAppForActivity?.invalidate()
                                currentActivityPlaying = nil
                                closePupUpBlockIfVisible()
                                
                                if smallCountDownWcObj != nil{
                                    if smallCountDownWcObj!.window?.isVisible ?? false{
                                        getsmallCountDownVcObject().closeTimerBox()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func startHabitsCall(activityId:String?, skippedActivities:[String]){
        //        if currentState == ._SHUTOFFMAC_{
        //            return;
        //        }
        addLog(text: "Initiating morning habits.")
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
        checkTrialExpire()
//        if avmonitor.isMicOn(){
//            addLog(text: "Mic is in use, Morning Habits skipped for some time.")
//            return;
//        }
//
//        if avmonitor.isACameraOn(){
//            addLog(text: "Camera is is use, Morning Habits skipped for some time.")
//            return;
//        }
//
//        if isPreventUserIdleDisplaySleepOn(){
//            addLog(text: "PreventUserIdleDisplaySleep is On: Morning Habits skipped for some time.")
//            return
//        }
        if isUserOnMeeting{
            addLog(text: "isUserOnMeeting True: Morning Habits skipped for some time.")
            return
        }
        if isHabitAlreadyShowed{
            return;
        }
        if arrAllMorningHabits.count != 0 {
            
            checkSystemTimeAndShowWindow()
            
            self.abortAllProcess()
            if activityId == nil{
                mainWindowControllerObj?.showWindow(self)
                mainViewControllerObj!.showAllMorningHabits()
                showBlankWindowInSecondaryMonitor()
            }else{
                mainWindowControllerObj?.showWindow(self)
                var isActivityFound = false
                for i in 0..<arrAllMorningHabits.count{
                    if arrAllMorningHabits[i].id == activityId!{
                        isActivityFound = true
                        if i == 0{
                            mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                        }else {
                            if skippedActivities.count == 0{
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    habitTotalCompletedSeconds += arrAllMorningHabits[j].durationSeconds!
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrAllMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                }
                                
                                
                                mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                            }else{
                                var isLastActivitySkipped = false
                                if let lastActivityId = arrAllMorningHabits[i-1].id{
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                        isLastActivitySkipped = true
                                    }
                                    habitTotalCompletedSeconds = 0
                                    for j in 0..<i{
                                        let habit = arrAllMorningHabits[j]
                                        if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                            //skiped
                                        }else{
                                            habitTotalCompletedSeconds += habit.durationSeconds!
                                            //completed
                                        }
                                        
                                    }
                                    if i-1 >= 0{
                                        UserDefaults.standard.set(arrAllMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                    }
                                    
                                }
                                
                                
                                mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:isLastActivitySkipped)
                                
                            }
                                
                        }
                        break;
                    }
                }
                if !isActivityFound{
                    addLog(text: "func startHabitsCall:- current activity id from actiity props not found in habit list.")
                    quitAndRestartApp()
                }
                showBlankWindowInSecondaryMonitor()
            }
        }
    }
    
    func checkSystemTimeAndShowWindow(){
        addLog(text: "func checkSystemTimeAndShowWindow")
        if let now = client.referenceTime?.now(){
            print(now)
            let currentDate = Date()
            let diffHours = Calendar.current.dateComponents([.hour], from: now, to: currentDate).hour ?? 0
            if diffHours > 24 || diffHours < -24{
                let nowString = getStringFromDate(date: now, dateFormat: "yyyy-MM-dd HH:mm:ss")
                let currentDateString = getStringFromDate(date: currentDate, dateFormat: "yyyy-MM-dd HH:mm:ss")
                
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                }
                var timeIncorrectText = "Your system time seems to be incorrect - it's saying the current time is <SYSTEM_TIME> but the actual time is <TRUE_TIME>. Focus Bear won't work properly if you don't have your system time configured correctly. Once you have adjusted the time settings, click \"I am ready to start my habits\" button below."
                if let common = configjson.value(forKey: "common") as? NSDictionary{
                    timeIncorrectText = common.value(forKey: "timeIncorrectText") as? String ?? timeIncorrectText
                }
                
                timeIncorrectText = timeIncorrectText.replacingOccurrences(of: "<SYSTEM_TIME>", with: currentDateString)
                timeIncorrectText = timeIncorrectText.replacingOccurrences(of: "<TRUE_TIME>", with: nowString)
                addLog(text: "checkSystemTimeAndShowWindow:- time is not correct:- show window")
                getIncorrectTimeVcObject().loadView()
                getIncorrectTimeVcObject().lblTitle.stringValue = timeIncorrectText
                NSApplication.shared.activate(ignoringOtherApps: true)
                NSApplication.shared.runModal(for: getIncorrectTimeWindowObject().window!)

            }
        }
    }
    func checkTrialExpire(){
        if isPurchased == true{
            return;
        }
        addLog(text: "checkTrialExpire")

        if isPurchased == false && daysLeft <= 0{//
            quitAndRestartApp()
        }
    }
    @objc func menuItem_Preferences() {
    
        if preferencesWindowControllerObj?.window?.isVisible ?? false{
            return;
        }
        allApiObject.capturePosthog(event: "open-preferences", metadata: [:])
        if preferencesWindowControllerObj?.window?.isMiniaturized ?? false{
            preferencesWindowControllerObj?.showWindow(self)
            addLog(text: "Showing preferences:- was minimize")
            return;
        }
        preferencesWindowControllerObj?.showWindow(self)
        addLog(text: "Showing preferences")

        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                    tabview.selectedTabViewItemIndex = 5
                }else{
                    tabview.selectedTabViewItemIndex = 0
                }
                
                if SettingsManagerObject.isPasswordRequireInChangeSettings{
                    tabview.view.addSubview(enterPasswordVcObj!.view)
                    tabview.view.addConstraints(subView: enterPasswordVcObj!.view)
                    enterPasswordVcObj?.parentVc = nil
                    addLog(text: "Showing enter password view")
                }
            }
        }else{
            if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    tabview.selectedTabViewItemIndex = 5
                }
            }
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
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
        UserDefaults.standard.set(true, forKey: kUserdefaultsAppQuitProperly)
        print("applicationWillTerminate")
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        addLog(text: "application Should Terminate")
        print("applicationShouldTerminate")
        if terminateFromSelf {
            terminateFromSelf = false
            return .terminateNow
        }else {
            if appdelegate!.statusbutton?.action == #selector(appdelegate!.topIconClickd){
                return .terminateNow
            }
            if self.user == nil{
                return .terminateNow
            }
            addLog(text: "menu item Quit clicked from dock or activity monitor")
            if isPurchased == false && daysLeft <= 0{//if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
                return .terminateNow
            }
            if quittingWcObj != nil{
                if quittingWcObj?.window?.isVisible ?? false{
                    addLog(text: "Quit window already visible")
                    return .terminateCancel
                }
            }
            showQuitWindow()
            
            return .terminateCancel
        }
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
//        if appdelegate!.statusbutton?.action == #selector(appdelegate!.topIconClickd){
//            topIconClickd()
//        }
        print("applicationShouldHandleReopen")
//        print(sender)
//        let args = ProcessInfo.processInfo.arguments
//        print("arguments:-\n")
//        print(args)
//        statusbutton?.performClick(self)
        return true
    }
    
    // did this beacuse we user closes last window than app should  deactivate beacuse we need to show popover if user clicks on dock icon and if app is allready active we cant get actual state of dock icon click that's why we are doing this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed")
        print(NSApp.isActive)
        if popover.isShown{
            return false
        }
        if NSApp.isActive{
            NSApp.hide(self)
        }
        return false
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {

//        print(notification.userInfo)
//        print(notification.object)
//        print(notification)
//        print(popover.isShown)
//        print(NSApp.windows)
        var isAnyStanderdWindowVisible = false
        
        for win in NSApp.windows{
//            print(win.isVisible)
//
//            print("title " + win.title)
//            print(win.isMainWindow)
//            print(win.isKeyWindow)
//            print(win.level)
//            print(win.styleMask.contains(.closable))
//            print(win.hasTitleBar)
            if win.isVisible && win.hasTitleBar{
                isAnyStanderdWindowVisible = true
            }
//            print("***********")
        }
        if smallCountDownWcObj != nil{
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible{
                    isAnyStanderdWindowVisible = true
                }
            }
        }
        if !popover.isShown{// window is visible but alpha is 0
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_) && !(mainWindowControllerObj?.window?.isVisible ?? false){
                if currentHabitPlaying != nil || currentActivityPlaying != nil{// it means background activity
                    if smallCountDownWcObj != nil{
                        if smallCountDownWcObj?.window?.alphaValue == 0{
                            if popUpBlockConfirmWcObj != nil{
                                if !(popUpBlockConfirmWcObj?.window?.isVisible ?? false){
                                    smallCountDownWcObj?.window?.alphaValue = 1
                                }
                            }else{
                                smallCountDownWcObj?.window?.alphaValue = 1
                            }
                            
                        }else{
                            isAnyStanderdWindowVisible = true
                        }
                    }
                }
            }
        }
        
        if !popover.isShown && !isAnyStanderdWindowVisible{
            statusbutton?.performClick(self)
        }
        print("applicationDidBecomeActive")
    }
    func applicationDidResignActive(_ notification: Notification) {
        print("applicationDidResignActive")
        if self.alertAppAutoRestart.window.isVisible{
            self.alertAppAutoRestart.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        }
    }
    
    @objc func topIconClickd(){
        addLog(text: "top Icon Clickd")
        if self.user == nil{
            addLog(text: "self.user = nil")
            if  UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                showWelcomeOnboardingWindow()
                return
            }
//            if !sessionStart{
////                login(isLogin: true)
//            }else{
//                if let browser = defaultBrowser{
//                    NSWorkspace.shared.launchApplication(browser)
//                }
//            }
        }else{
            addLog(text: "show activation Window")
            activationWindowControllerObj?.showWindow(self)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
    }
    func setFocusModeTimer(hour:Int?, minute:Int?){
        addLog(text: "setFocusModeTimer")
        DispatchQueue.global().sync {
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
//            RunLoop.current.add(timerForFocusMode!, forMode: RunLoop.Mode.common)
//            RunLoop.current.run()
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
        }
    }
    
    func focusModeAborted(){
        addLog(text: "focus mode Aborted")
        unfocusedTime = 0
        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        focusModeActualDurationPerformed = Int(Date().timeIntervalSince(startFocusModeTime ?? Date()))
        var currentFocusModeId = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                currentFocusModeId = arrFocusType[i]["id"] as? String ?? ""
                workAfterFocusBegin(index: i)
                break;
            }
        }
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.focusModeFinished()
                }
            }
        }
        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        
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
        DispatchQueue.main.async {
            if toolBoxWcObj != nil{
                if toolBoxWcObj!.window!.isVisible{
                    toolBoxWcObj?.window?.close()
                }
            }
        }
        
        isAutoMeetingsModeStarted = false
        appUsedInAutoMeetingFocusMode = ""
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
        }
        
    }
    @objc func focusModeTimerFinished(){
        focusModeFinished(isSilent: false)
    }
    @objc func focusModeFinished(isSilent:Bool){
        unfocusedTime = 0
        addLog(text: "focus mode finished")
        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil
        print("focus mode finished")
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        
        
        focusModeActualDurationPerformed = Int(Date().timeIntervalSince(startFocusModeTime ?? Date()))
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.focusModeFinished()
                }
            }
        }
        
        var currentFocusModeName = ""
        var currentFocusModeId = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
                currentFocusModeId = arrFocusType[i]["id"] as? String ?? ""
                workAfterFocusBegin(index: i)
                break;
            }
        }
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
            
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
        DispatchQueue.main.async {
            if toolBoxWcObj != nil{
                if toolBoxWcObj!.window!.isVisible{
                    toolBoxWcObj?.window?.close()
                }
            }
        }
        
        if self.isAutoMeetingsModeStarted{
            let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
            addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "Meeting using {\(self.appUsedInAutoMeetingFocusMode)}", distractionsEncountered: "", abortReason: "", feedback: "")
            
            
            allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), completionHandler: {newDic in
                DispatchQueue.main.async {
                    
                }
            })
        }else{
            if isSilent{
                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "")
                
                allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
            }else{
                DispatchQueue.main.async {
                    self.showFocusCompletedView()
                    focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date())
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
            
            //            }
 
        }
        self.isAutoMeetingsModeStarted = false
        self.appUsedInAutoMeetingFocusMode = ""
        
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
        }
    }
    
    func showFocusCompletedView(){
        addLog(text: "show Focus Completed View")
        getEndFocusModeWindowControllerObj().contentViewController = focusCompletedVcObj
//        getEndFocusModeWindowControllerObj().window?.styleMask.remove(.closable)
        getEndFocusModeWindowControllerObj().showWindow(self)
    }
    
    func setIntensionInBrainDumpWindow(){
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.textViewIntention.string = whatToAchieveInFocusBlock
                }
            }
        }
    }
    @objc func focusModeStartted(){
        addLog(text: "focus Mode Started called")
        unfocusedTime = 0
        playFocusModeStartedSound()
        if getSmallCountDownWindowObject().window?.isVisible ?? false{
            getsmallCountDownVcObject().closeTimerBox()
        }
        isAutoMeetingsModeStarted = false
        if let startTime = startFocusModeTime, let endTime = endFocusModeTime{
            allApiObject.startFocusMode(id: getRunningFocusModeId(), intention: whatToAchieveInFocusBlock, start_time: startTime, finish_time: endTime, completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        var stringTime = ""

        if let date = endFocusModeTime{
            stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
        }
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.focusModeStarted()
                }
            }
        }

        addLog(text: "focus mode Started until - \(stringTime)")
//        fillAllowUrlArray()
//        fillAllowAppArray()

        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                currentRunningFocusType = dic
            }
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) as? Bool == false{
            var shouldShowToolBoxWindow = false

            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
            
            if !isAllowedAllAppsInFocus && allowAppsPath.count != 0{
                shouldShowToolBoxWindow = true
            }
//            let isAllowedAllUrlsInFocus = currentRunningFocusType["isAllowedAllUrls"] as? Bool ?? false#453
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            
            if arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{//!isAllowedAllUrlsInFocus &&#453
                shouldShowToolBoxWindow = true
            }
            if shouldShowToolBoxWindow{
                showToolboxWindow()
            }
        }
        arrNotificationShownForApps.removeAll()
        frontApplicationChanged()//ak bar khud hi call krdenge qki phle se bhi active ho skti h

        DispatchQueue.global().sync {
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
        }
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()

        fireFoxNotificationShownForCurrentFocusMode = false
    }
//    var currentRunningFocusModeName = ""
//    func fillAllowUrlArray(){
//        addLog(text: "fill focus Allow Urls Array")
//        isAllowedAllUrlsInFocus = false
//        isBlockedAllUrlsInFocus = false
//        isAllowedListApproachInFocus = true
//        arrAllowedUrlsForFocus.removeAll()
//        arrBlockedUrlsForFocus.removeAll()
//        for dic in arrFocusType{
//            if dic["isOn"] as? Bool == true{
//                currentRunningFocusModeName = dic["name"] as? String ?? ""
//                if dic["isAllowedAllUrls"] as? Bool == true{
//                    isAllowedAllUrlsInFocus = true
//                }
//                if dic["isBlockedAllUrls"] as? Bool == true{
//                    isBlockedAllUrlsInFocus = true
//                }
//                if dic["isAllowedListApproach"] as? Bool == true{
//                    isAllowedListApproachInFocus = true
//                }else{
//                    isAllowedListApproachInFocus = false
//                }
//
//
//                arrAllowedUrlsForFocus = dic["allowed_urls"] as? [String] ?? []
//                arrBlockedUrlsForFocus = dic["blockUrlsArray"] as? [String] ?? []
//            }
//        }
//    }
    //
//    func fillAllowAppArray(){
//        addLog(text: "fill focus Allow App Array")
//        isAllowedAllAppsInFocus = false
//        allowAppsPath.removeAll()
//        for dic in arrFocusType{
//            if dic["isOn"] as? Bool == true{
//                if dic["isAllowedAllApps"] as? Bool == true{
//                    isAllowedAllAppsInFocus = true
//                }
//                allowAppsPath = dic["allowed_apps"] as? [String] ?? []
//            }
//        }
//    }
    
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
        
        
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    var isAppAllowed = false
                    var isSelfApp = false
                    DispatchQueue.global().sync {
                      
                          

                            if !isAnyAllowedFocusModeActivityRunning{
                                if focusDefaultAllowApps.contains(nameLowercased) || nameLowercased == selfAppName.lowercased(){
                                    isAppAllowed = true
                                }else{
                                    var allowApps = [String]()
                                    
                                    if currentHabitPlaying != nil{
                                        allowApps = currentHabitPlaying!.allowApps
                                    }else if currentActivityPlaying != nil{
                                        allowApps = currentActivityPlaying!.allowApps
                                    }
                                    
                                    for appName in allowApps{
                                        if appName.lowercased() == nameLowercased{
                                            isAppAllowed = true
                                            break;
                                        }
                                    }

                                }
                                
                                if !isAppAllowed{
                                    runningApp.hide()
                                    allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
                                    return
                                }
                                
                            }else{
                                let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                                let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                                
                                
                                if isAllowedAllAppsInFocus{
                                    isAppAllowed = true
                                    if nameLowercased == selfAppName.lowercased(){
                                        isSelfApp = true
                                    }
                                }else{
                                    
                                    if nameLowercased == selfAppName.lowercased(){
                                        isSelfApp = true
                                        isAppAllowed = true
                                    }else if focusDefaultAllowApps.contains(nameLowercased){//if nameLowercased == "finder" || nameLowercased == "universalaccessauthwarn"{
                                        isAppAllowed = true
                                    }else{
                                        for path in allowAppsPath{
                                            let url = URL(fileURLWithPath: path)
                                            if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                                isAppAllowed = true
                                                break;
                                            }
                                        }
                                    }
                                }
                                if SettingsManagerObject.isCuddlyModeEnabled{
                                    if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                                        isAppAllowed = true
                                    }
                                }
                                if !isAppAllowed{
                                    focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name)
                                    return
                                }else{
                                    if isSelfApp{
                                        return;
                                    }
                                    DispatchQueue.main.async {
                                        closePupUpBlockIfVisible()
                                    }
                                }
                                
                                
                            }
                            

                            
                            if arrBrowsersLowerCasedNames.contains(nameLowercased){
                                timerAllowUrlForActivity?.invalidate()
                                self.timerAllowUrlForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkInBackgroundForActivity), userInfo: nil, repeats: true)
                                RunLoop.main.add(self.timerAllowUrlForActivity!, forMode: RunLoop.Mode.common)
                            }
                        
                    }
                }
            }
        }
//        else if (currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_) && currentAction == ._INPROGRESS_ && currentHabitPlaying != nil{
//            if let runningApp = NSWorkspace.shared.frontmostApplication{
//                print(runningApp.localizedName)
//                if let appUrl = runningApp.bundleURL{
//                    let name = appUrl.deletingPathExtension().lastPathComponent
//                    let nameLowercased = name.lowercased()
//                    DispatchQueue.global().sync {
//                        if currentHabitPlaying != nil{
//                            var isAppAllowed = false
//
//                            if nameLowercased == "finder" || nameLowercased == selfAppName.lowercased(){
//                                isAppAllowed = true
//                            }else{
//                                for appName in currentHabitPlaying!.allowApps{
//                                    if appName.lowercased() == nameLowercased{
//                                        isAppAllowed = true
//                                        break;
//                                    }
//                                }
//
//                                if !isAppAllowed{
////                                    for appName in activityAllowedFocusApps{
////                                        if appName.lowercased() == nameLowercased{
////                                            isAppAllowed = true
////                                            break;
////                                        }
////                                    }
//
//                                    if activityAllowedFocusMode != nil{//
//                                        for path in activityAllowedFocusMode!.allowAppsPath{
//                                            let url = URL(fileURLWithPath: path)
//                                            if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
//                                                isAppAllowed = true
//                                                break;
//                                            }
//                                        }
//                                    }
//
//                                }
//
//                            }
//
//
//                            if !isAppAllowed{
//                                runningApp.hide()
//                                allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
//                                return
//                            }
//                            if arrBrowsersLowerCasedNames.contains(nameLowercased){
//                                timerAllowUrlForActivity?.invalidate()
//                                self.timerAllowUrlForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkInBackgroundForActivity), userInfo: nil, repeats: true)
//                                RunLoop.main.add(self.timerAllowUrlForActivity!, forMode: RunLoop.Mode.common)
//                            }//x
//                        }
//                    }
//                }
//            }
//        }
        else if isFocusModeOn(){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    var isAppAllowed = false
                    var isSelfApp = false
                    
                    let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    
                    if isAllowedAllAppsInFocus{
                        isAppAllowed = true
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                        }
                    }else{
                        
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                            isAppAllowed = true
                        }else if focusDefaultAllowApps.contains(nameLowercased){//if nameLowercased == "finder" || nameLowercased == "universalaccessauthwarn"{
                            isAppAllowed = true
                        }else{
                            for path in allowAppsPath{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                        }
                    }
                    if SettingsManagerObject.isCuddlyModeEnabled{
                        if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                            isAppAllowed = true
                        }
                    }
                    if !isAppAllowed{
                        focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name)
                        
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                            print("invalidtate")
                        }
                        return
                    }else{
                        if isSelfApp{
                            return;
                        }
                        DispatchQueue.main.async {
                            closePupUpBlockIfVisible()
                        }
                    }
                    if nameLowercased == "firefox"{
                        if !fireFoxNotificationShownForCurrentFocusMode{
                            var msg = "FYI we can't block distractions in Firefox yet but if you use Chrome or Safari, we'll be here to support you to stay on track"
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                msg = common.value(forKey: "notificationFirefoxText") as? String ?? msg
                            }
                            showNotificationWithMessage(msg: msg)
                            fireFoxNotificationShownForCurrentFocusMode = true
                            return;
                        }
                    }
                    DispatchQueue.global().sync {
                        if arrBrowsersLowerCasedNames.contains(nameLowercased){
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
                        
                        if arrBrowsersLowerCasedNames.contains(nameLowercased){
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
        addLog(text: "show Focus App Block Notification called")
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
                
                var currentBrowser:BROWSER!
                let nameLowercased = name.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    currentBrowser = browser
                }else{
                    self.timerBlockUrl?.invalidate()
                    return;
                }
                var defaultPageOfBrowser = ""
                if currentBrowser == ._SAFARI_{
                    defaultPageOfBrowser = "favorites:"
                }else{
                    defaultPageOfBrowser = "chrome:"
                }
                
                
                
                if var url = getActiveTabUrlOf(browser: currentBrowser){
                    print(url)
                    if !url.contains(defaultPageOfBrowser) && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
                        let domain = getDomainFromUrl(url: url)
                        
                        var bool = false
                        for turl in SettingsManagerObject.arrBlockedUrls{
                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                            if bool{
                                break;
                            }
                        }
                        if bool{
                            url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                            
                            switch currentBrowser{
                                
                            case ._SAFARI_:
                                script =
                                """
                                tell application "Safari"
                                set the_wnd to front window
                                set active_tab to current tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                                
                            case ._GOOGLE_CHROME_:
                                script =
                                """
                                tell application "Google Chrome"
                                set the_wnd to front window
                                set active_tab to active tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                                
                            case ._BRAVE_BROWSER_:
                                script =
                                """
                                tell application "Brave Browser"
                                set the_wnd to front window
                                set active_tab to active tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                                
                            case ._SIDEKICK_:
                                script =
                                """
                                tell application "Sidekick"
                                set the_wnd to front window
                                set active_tab to active tab in the_wnd
                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
                                end tell
                                """
                            case .none:
                               
                                return
                            }
                            
                        }else{
                            return;
                        }
                    }else{
                        return;
                    }
                    
                }else{
                    return;
                }
                
//
//                if name.lowercased() == "safari"{
//                    if var url = getSafariActiveTabUrl(){
//                        print(url)
//                        if !url.contains("favorites:") && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
//                            let domain = getDomainFromUrl(url: url)
//
//                            var bool = false
//                            for turl in SettingsManagerObject.arrBlockedUrls{
//                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
//                                if bool{
//                                    break;
//                                }
//                            }
//                            if bool{
//                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
//                                script =
//                                """
//                                tell application "Safari"
//                                set the_wnd to front window
//                                set active_tab to current tab in the_wnd
//                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
//                                end tell
//                                """
//                            }else{
//                                return;
//                            }
//                        }else{
//                            return;
//                        }
//
//                    }else{
//                        return;
//                    }
//
//                }else if name.lowercased() == "google chrome"{
//                    if var url = getGoogleChromeActiveTabUrl(){
//                        print(url)
//                        if !url.contains("chrome:") && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
//                            let domain = getDomainFromUrl(url: url)
//
//                            var bool = false
//                            for turl in SettingsManagerObject.arrBlockedUrls{
//                                bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
//                                if bool{
//                                    break;
//                                }
//                            }
//                            if bool{
//                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
//                                script =
//                                """
//                                tell application "Google Chrome"
//                                set the_wnd to front window
//                                set active_tab to active tab in the_wnd
//                                set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=always-blocked"
//                                end tell
//                                """
//                            }else{
//                                return
//                            }
//                        }else{
//                            return
//                        }
//                    }else{
//                        return
//                    }
//
//
//                }else{
//                    self.timerAllowUrl?.invalidate()
//                }
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
                    allApiObject.capturePosthog(event: "block-distracting-url", metadata: [:])
                    //let descriptor = error.descriptorType
                }
            }
        }
    }
    
    @objc func checkFcousAllowedApp(){
        let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
        if isAllowedAllAppsInFocus{
            return;
        }
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                print(name)
                var isAppAllowed = false
                var isSelfApp = false
                if name == selfAppName.lowercased(){
                    isSelfApp = true
                    isAppAllowed = true
                }else if focusDefaultAllowApps.contains(name){//if name == "finder" || name == "universalaccessauthwarn"{
                    isAppAllowed = true
                }else{
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    for path in allowAppsPath{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                            isAppAllowed = true
                            break;
                        }
                    }
                }
                
                
                if SettingsManagerObject.isCuddlyModeEnabled{
                    if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                        isAppAllowed = true
                    }
                }
                if !isAppAllowed{
                    
                    focusTryToBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent)
                    
                    if self.timerAllowUrl != nil{
                        self.timerAllowUrl!.invalidate()
                        print("invalidtate22")
                    }
                    return
                }else{
                    if isSelfApp{
                        return;
                    }
                    DispatchQueue.main.async {
                        if popUpBlockConfirmWcObj != nil{
                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                        }
                    }
                }
                
            }
        }
    }
    
    
    
    
    func focusTryToBlockUnwantedApp(runningApp: NSRunningApplication, appName:String){
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if popUpBlockConfirmVcObj!.isAppBlocking{
                    if popUpBlockConfirmVcObj?.currentApp == runningApp{
                        return;
                    }
                }
            }
        }
        if SettingsManagerObject.isCuddlyModeEnabled{
            if arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true)
            }else{
                showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true)
            }
        }else{
            focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true)
        }
    }
    
    
    
    func focusBlockUnwantedApp(runningApp: NSRunningApplication, appName:String, showNotification:Bool){
        runningApp.hide()
        allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
        if showNotification{
            showFocusAppBlockNotification(appName:appName)
        }
        if SettingsManagerObject.isCuddlyModeEnabled{
            if !arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                arrBlockedAppsInCuddlyModeCurrentFocus.append(runningApp)
            }
        }
    }
    
    
    func focusTryToBlockUnwantedUrl(script: String, url:String){
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    if popUpBlockConfirmVcObj?.url == url{
                        return;
                    }
                }
            }
        }
        
        if SettingsManagerObject.isCuddlyModeEnabled{
            if arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
                focusBlockUnwantedUrl(script: script, url: url)
            }else{
                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false)
            }
        }else{
            focusBlockUnwantedUrl(script: script, url: url)
        }
        
    }
    
    func focusBlockUnwantedUrl(script: String, url:String){
        if let appleScript = NSAppleScript(source: script) {
            
            var errors : NSDictionary? = nil
            appleScript.executeAndReturnError(&errors)
            if errors != nil {
                
                //var test = errors?.count
                print(errors)
            }
            allApiObject.capturePosthog(event: "block-distracting-url", metadata: [:])
        }
        
        if SettingsManagerObject.isCuddlyModeEnabled{
            if !arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
                arrBlockedUrlsInCuddlyModeCurrentFocus.append(url)
            }
        }
    }
    
    func startTimerActivitiesAllowedApp(shouldLaunchAppAndUrl:Bool){
        addLog(text:"start Timer Activities AllowedApp")
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if currentHabitPlaying?.run_micro_breaks ?? false{
                addLog(text:"set activity timer from morning activity allowed app")
                if !(mainViewControllerObj?.isBreakActivityPostponeInsideAllowedHabit ?? false){
                    mainViewControllerObj?.setActivityTimer()
                }else{
                    addLog(text:"set activity timer from morning activity allowed app:- break activity postpone, do not reset activity timer")
                }
            }
        }
        DispatchQueue.global().sync {
            self.timerAllowAppForActivity?.invalidate()
            self.timerAllowAppForActivity = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkActivityAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerAllowAppForActivity!), forMode: RunLoop.Mode.common)
            
        }
        setDocBarTo(isHide: true)
        if shouldLaunchAppAndUrl{
            if currentState == ._ACTIVITY_{
                if let apps = currentActivityPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
//                        if let app = activityAllowedFocusApps.first{
//                            NSWorkspace.shared.launchApplication(app)
//                        }
                        
//                        if activityAllowedFocusMode != nil{//
//                            for path in activityAllowedFocusMode!.allowAppsPath{
//                                let url = URL(fileURLWithPath: path)
//                                let app = url.deletingPathExtension().lastPathComponent
//                                NSWorkspace.shared.launchApplication(app)
//                            }
//                        }
                        
                    }
                }else{
//                    if let app = activityAllowedFocusApps.first{
//                        NSWorkspace.shared.launchApplication(app)
//                    }
//                    if activityAllowedFocusMode != nil{
//                        for path in activityAllowedFocusMode!.allowAppsPath{
//                            let url = URL(fileURLWithPath: path)
//                            let app = url.deletingPathExtension().lastPathComponent
//                            NSWorkspace.shared.launchApplication(app)
//                        }
//                    }
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
//                        if activityAllowedFocusMode != nil{
//                            if var url = activityAllowedFocusMode!.activityAllowedFocusUrls.first{
//                                if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
//                                    url = "http://"+url
//                                }
//                                NSWorkspace.shared.open(URL(string: url)!)
//                            }
//                        }
                    }
                }
            }else if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_{
                if let apps = currentHabitPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
//                        if let app = activityAllowedFocusApps.first{
//                            NSWorkspace.shared.launchApplication(app)
//                        }
//                        if activityAllowedFocusMode != nil{
//                            for path in activityAllowedFocusMode!.allowAppsPath{
//                                let url = URL(fileURLWithPath: path)
//                                let app = url.deletingPathExtension().lastPathComponent
//                                NSWorkspace.shared.launchApplication(app)
//                            }
//                        }
                    }
                }else{
//                    if let app = activityAllowedFocusApps.first{
//                        NSWorkspace.shared.launchApplication(app)
//                    }
//                    if activityAllowedFocusMode != nil{
//                        for path in activityAllowedFocusMode!.allowAppsPath{
//                            let url = URL(fileURLWithPath: path)
//                            let app = url.deletingPathExtension().lastPathComponent
//                            NSWorkspace.shared.launchApplication(app)
//                        }
//                    }
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
//                        if activityAllowedFocusMode != nil{
//                            if var url = activityAllowedFocusMode!.activityAllowedFocusUrls.first{
//                                if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
//                                    url = "http://"+url
//                                }
//                                NSWorkspace.shared.open(URL(string: url)!)
//                            }
//                        }
                    }
                }
                
            }
        }
        
    }
    
    @objc func checkActivityAllowedApp(){
        addLog(text:"check Activity Allowed App")
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    print(name)

                        var isAppAllowed = false
                            if isAnyAllowedFocusModeActivityRunning{
                                let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                                if isAllowedAllAppsInFocus{
                                    return;
                                }
                                var isSelfApp = false
                                if name == selfAppName.lowercased(){
                                    isSelfApp = true
                                    isAppAllowed = true
                                }else if focusDefaultAllowApps.contains(name){//if name == "finder" || name == "universalaccessauthwarn"{
                                    isAppAllowed = true
                                }else{
                                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                                    for path in allowAppsPath{
                                        let url = URL(fileURLWithPath: path)
                                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                            isAppAllowed = true
                                            break;
                                        }
                                    }
                                }
                                
                                if SettingsManagerObject.isCuddlyModeEnabled{
                                    if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                                        isAppAllowed = true
                                    }
                                }
                                
                                
                                if !isAppAllowed{
                                    
                                    focusTryToBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent)
                                    
                                    if self.timerAllowUrlForActivity != nil{
                                        self.timerAllowUrlForActivity!.invalidate()
                                    }
                                    return
                                }else{
                                    if isSelfApp{
                                        return;
                                    }
                                    DispatchQueue.main.async {
                                        if popUpBlockConfirmWcObj != nil{
                                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                                    popUpBlockConfirmVcObj?.closeWindow()
                                                }
                                            }
                                        }
                                    }
                                }
                            }else{
                                
                                 if focusDefaultAllowApps.contains(name) || name == selfAppName.lowercased(){
                                     isAppAllowed = true
                                 }else{
                                     var allowApps = [String]()
                                     
                                     if currentHabitPlaying != nil{
                                         allowApps = currentHabitPlaying!.allowApps
                                     }else if currentActivityPlaying != nil{
                                         allowApps = currentActivityPlaying!.allowApps
                                     }
                                     
                                     for appName in allowApps{
                                         if appName.lowercased() == name{
                                             isAppAllowed = true
                                             break;
                                         }
                                     }
                                 }
                                
                                
                                
                                if !isAppAllowed{
                                    runningApp.hide()
                                    allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
                                    if self.timerAllowUrlForActivity != nil{
                                        self.timerAllowUrlForActivity!.invalidate()
                                    }
                                    return
                                }
                                
                            }

                }
            }
        }
//        else if (currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_) && currentAction == ._INPROGRESS_ && currentHabitPlaying != nil{
//            if let runningApp = NSWorkspace.shared.frontmostApplication{
//                if let appUrl = runningApp.bundleURL{
//                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
//                    print(name)
//                    if currentHabitPlaying != nil{
//                        var isAppAllowed = false
//                        if name == "finder" || name == selfAppName.lowercased(){
//                            isAppAllowed = true
//                        }else{
//                            for appName in currentHabitPlaying!.allowApps{
//                                if appName.lowercased() == name{
//                                    isAppAllowed = true
//                                    break;
//                                }
//                            }
//                            if !isAppAllowed{
////                                for appName in activityAllowedFocusApps{
////                                    if appName.lowercased() == name{
////                                        isAppAllowed = true
////                                        break;
////                                    }
////                                }
//                                if activityAllowedFocusMode != nil{
//                                    for path in activityAllowedFocusMode!.allowAppsPath{
//                                        let url = URL(fileURLWithPath: path)
//                                        let app = url.deletingPathExtension().lastPathComponent
//                                        if app.lowercased() == name{
//                                            isAppAllowed = true
//                                            break;
//                                        }
//                                    }
//                                }
//                            }
//
//                        }
//
//                        if !isAppAllowed{
//                            runningApp.hide()
//                            allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
//                            if self.timerAllowUrlForActivity != nil{
//                                self.timerAllowUrlForActivity!.invalidate()
//                            }
//                            return
//                        }
//                    }else{
//                        if self.timerAllowAppForActivity != nil{
//                            self.timerAllowAppForActivity!.invalidate()
//                        }
//                    }
//                }
//            }
//        }
            
        else{
            if self.timerAllowAppForActivity != nil{
                self.timerAllowAppForActivity!.invalidate()
            }
        }
    }
//    var arrAllowedUrlsForFocus = [""]
//    var arrBlockedUrlsForFocus = [""]
    var defaultAllowedUrl = ["eyst-focus.html",
                             "earnyourscreentime.com",
                             "devtools://",
                             "chrome-extension://",
                             "focusbear.io",
                             "view-source:",
                             "about:blank",
                             "https://focus-bear.github.io"]
    
//    var allowAppsPath = [""]
    var arrNotificationShownForApps = [""]
    func closePopupBlockWindowIfRunningForUrl(){
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
    }
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
            
            



//            let isAllowedAllUrlsInFocus = currentRunningFocusType["isAllowedAllUrls"] as? Bool ?? false#453
//            let isBlockedAllUrlsInFocus = currentRunningFocusType["isBlockedAllUrls"] as? Bool ?? false#453
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                
            
            
            
            
//            if isAllowedAllUrlsInFocus && isAllowedListApproachInFocus{#453
//                return;
//            }
            
            var stringTime: String = ""
            if isFocusTimeType == ._HOUR_{
                if let date = endFocusModeTime{
                    stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                }
            }else if isFocusTimeType == ._TILL_SHUTOFF_ || isFocusTimeType == ._NONE_{
                if let date = shutOffTime{
                    //let stringTime = getStringFromDate(date: date, dateFormat: "HH:mm a")
                    let hour = date.hour
                    let minute = date.minute
                    let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
                    stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                }
            }
            
            var focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
            var focusMode = ""
            let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
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
                    var tabUrl = ""
                    
                    var currentBrowser:BROWSER!
                    let nameLowercased = name.lowercased()
                            
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        currentBrowser = browser
                    }else{
                        if nameLowercased != selfAppName.lowercased(){
                            self.closePopupBlockWindowIfRunningForUrl()
                        }
                        
                        self.timerAllowUrl?.invalidate()
                        return;
                    }
                    var defaultPageOfBrowser = ""
                    if currentBrowser == ._SAFARI_{
                        defaultPageOfBrowser = "favorites:"
                    }else{
                        defaultPageOfBrowser = "chrome:"
                    }
                    if var url = getActiveTabUrlOf(browser: currentBrowser){
                        print(url)
                        for turl in self.defaultAllowedUrl{
                            if url.contains(turl){
                                self.closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                        }
                        
                        if !url.contains(defaultPageOfBrowser){
                            let domain = getDomainFromUrl(url: url)
                            var isBlocked = false
                            var isAllowed = false
                            if SettingsManagerObject.isCuddlyModeEnabled{
                                if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(domain){
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                            }
                            if isAllowedListApproachInFocus{
                                for turl in arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if isBlocked{
                                        break;
                                    }
                                }
                                
                                
                                if !isBlocked{
                                    for turl in arrAllowedUrlsForFocus{
                                        isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if isAllowed{
                                            break;
                                        }
                                    }
                                    if !isAllowed{
                                        if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                                            for turl in arrAllowedUrlsForFocus{
                                                var starUrl: String = ""
                                                starUrl = "*" + turl.lowercased() + "*"
                                                isAllowed = wildcard(title, pattern: starUrl)
                                                if isAllowed{
                                                    break;
                                                }
                                            }
                                        }
                                    }
                                }
                            }else{
//                                if !isBlockedAllUrlsInFocus{#453
                                    isAllowed = true
                                    for turl in arrBlockedUrlsForFocus{
                                        isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if isBlocked{
                                            isAllowed = false
                                            break;
                                        }
                                    }
//                                }
                            }
                            
                            if !isAllowed{
                                tabUrl = domain
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)"
                                    end tell
                                    """
                                    
                                case ._GOOGLE_CHROME_:
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)"
                                    end tell
                                    """
                                    
                                case ._BRAVE_BROWSER_:
                                    script =
                                    """
                                    tell application "Brave Browser"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)"
                                    end tell
                                    """
                                    
                                case ._SIDEKICK_:
                                    script =
                                    """
                                    tell application "Sidekick"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)"
                                    end tell
                                    """
                                case .none:
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
 
                            }else{
                                self.closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                        }else{
                            self.closePopupBlockWindowIfRunningForUrl()
                            return;
                        }
                        
                    }else{
                        self.closePopupBlockWindowIfRunningForUrl()
                        return;
                    }
                    self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl)
                    

                    
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
//            if isAnyAllowedFocusModeActivityRunning{
//                let isAllowedAllUrlsInFocus = currentRunningFocusType["isAllowedAllUrls"] as? Bool ?? false#453
//                let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
//                if isAllowedAllUrlsInFocus && isAllowedListApproachInFocus{
//                    return;
//                }
//            }
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let name = runningApp.localizedName{
                    var script: String = ""
                    var tabUrl = ""
                    var currentBrowser:BROWSER!
                    let nameLowercased = name.lowercased()
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        currentBrowser = browser
                    }else{
                        self.timerAllowUrl?.invalidate()
                        return;
                    }
                    var defaultPageOfBrowser = ""
                    if currentBrowser == ._SAFARI_{
                        defaultPageOfBrowser = "favorites:"
                    }else{
                        defaultPageOfBrowser = "chrome:"
                    }
                    
                    
                    if var url = getActiveTabUrlOf(browser: currentBrowser){
                        print(url)
                        for turl in self.defaultAllowedUrl{
                            if url.contains(turl){
                                self.closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                        }
                        var activityAllowUrls = [String]()
                        
                        
                        if !url.contains(defaultPageOfBrowser){
                            let domain = getDomainFromUrl(url: url)
                            
                            var isBlocked = false
                            var isAllowed = false
                            
                            if SettingsManagerObject.isCuddlyModeEnabled{// no need additional check
                                if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(domain){
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                            }
                            
                            var blockType = ""
                            if currentState == ._ACTIVITY_{
                                if currentActivityPlaying != nil{
                                    activityAllowUrls = currentActivityPlaying!.allowUrls
                                }
                                blockType = "break-activity"
                            }else if currentState == ._MORNING_HABIT_{
                                if currentHabitPlaying != nil{
                                    activityAllowUrls = currentHabitPlaying!.allowUrls
                                }
                                blockType = "morning-habit"
                            }else if currentState == ._EVENING_HABIT_{
                                if currentHabitPlaying != nil{
                                    activityAllowUrls = currentHabitPlaying!.allowUrls
                                }
                                blockType = "evening-habit"
                            }
                            
                            
                            
                            if isAnyAllowedFocusModeActivityRunning == false{
                                for turl in activityAllowUrls{
                                    isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if isAllowed{
                                        break;
                                    }
                                }
                            }else if isAnyAllowedFocusModeActivityRunning{
                                
                                
//                                let isAllowedAllUrlsInFocus = currentRunningFocusType["isAllowedAllUrls"] as? Bool ?? false#453
//                                let isBlockedAllUrlsInFocus = currentRunningFocusType["isBlockedAllUrls"] as? Bool ?? false#453
                                let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
                                let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
                                let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                                
                                
                                
//                                if isAllowedAllUrlsInFocus && isAllowedListApproachInFocus{#453
//                                    return;
//                                }
                                
                                
                                if isAllowedListApproachInFocus{
                                    for turl in arrBlockedUrlsForFocus{
                                        isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if isBlocked{
                                            break;
                                        }
                                    }
                                    
                                    
                                    if !isBlocked{
                                        for turl in arrAllowedUrlsForFocus{
                                            isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if isAllowed{
                                                break;
                                            }
                                        }
                                        if !isAllowed{
                                            if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                                                for turl in arrAllowedUrlsForFocus{
                                                    var starUrl: String = ""
                                                    starUrl = "*" + turl.lowercased() + "*"
                                                    isAllowed = wildcard(title, pattern: starUrl)
                                                    if isAllowed{
                                                        break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }else{
//                                    if !isBlockedAllUrlsInFocus{#453
                                        isAllowed = true
                                        for turl in arrBlockedUrlsForFocus{
                                            isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if isBlocked{
                                                isAllowed = false
                                                break;
                                            }
                                        }
//                                    }
                                }
                            }
                            
                            
                            if !isAllowed{
                                tabUrl = domain
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                    
                                case ._GOOGLE_CHROME_:
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                    
                                case ._BRAVE_BROWSER_:
                                    script =
                                    """
                                    tell application "Brave Browser"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                    
                                case ._SIDEKICK_:
                                    script =
                                    """
                                    tell application "Sidekick"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)"
                                    end tell
                                    """
                                case .none:
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                                
                            }else{
                                self.closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                        }else{
                            self.closePopupBlockWindowIfRunningForUrl()
                            return;
                        }
                        
                    }else{
                        self.closePopupBlockWindowIfRunningForUrl()
                        return;
                    }
                    
                    
                    
                    
                    if isAnyAllowedFocusModeActivityRunning{
                        self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl)
                    }else{
                        if let appleScript = NSAppleScript(source: script) {
                            
                            var errors : NSDictionary? = nil
                            appleScript.executeAndReturnError(&errors)
                            if errors != nil {
                                
                                //var test = errors?.count
                                print(errors)
                            }
                            allApiObject.capturePosthog(event: "block-distracting-url", metadata: [:])
                            //let descriptor = error.descriptorType
                        }
                    }
                    
                }
            }
            
            
            
        }
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
                    
                    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                        if state{
                            window.sharingType = .none
                        }
                    }
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
    
    
    var timerPomodoroMode: Timer?
    func setTimerForPomodoroMode(delay:TimeInterval){// take a five minut k break per call hoga agar pomodoro mode finish hua h to. normal focus mode finish per call ni hoga ..
        if isAppEnable{
            DispatchQueue.global().sync{//async {
                if self.timerPomodoroMode != nil{
                    self.timerPomodoroMode?.invalidate()
                    self.timerPomodoroMode = nil
                }
                self.timerPomodoroMode = Timer.scheduledTimer(timeInterval: delay, target: self, selector: #selector(self.showAutoPomodoroModeView), userInfo: nil, repeats: false)
                RunLoop.main.add((timerPomodoroMode!), forMode: RunLoop.Mode.common)
            }
            
        }
    }
    
    var onboardingTimer: Timer?
    func postponeOnboardingHabitFor(minutes:Int){
        addLog(text: "postpone Onboarding habits, Timer reset Done:- \(minutes) minutes")
        currentState = ._POSTPON_ONBOARDING_HABIT_
        
        DispatchQueue.global().sync{//async {
            if self.onboardingTimer != nil{
                self.onboardingTimer?.invalidate()
                self.onboardingTimer = nil
            }
            self.onboardingTimer = Timer.scheduledTimer(timeInterval: TimeInterval(minutes*60), target: self, selector: #selector(self.resumeOnboardingProcess), userInfo: nil, repeats: false)
            RunLoop.main.add((onboardingTimer!), forMode: RunLoop.Mode.common)
        }
        
    }
    @objc func resumeOnboardingProcess(){
        addLog(text: "resume Onboarding Process.")
        currentState = ._NOTHING_
        showWelcomeOnboardingWindow()
    }
    
    func renewToken(window:NSWindow,completionHandler: @escaping() -> ()) {
        addLog(text: "renewToken")
        Auth0
            .authentication()
            .renew(withRefreshToken: credential!.refreshToken ?? "")
            .start { result in
                let oldPurchasedState = isPurchased
                let oldDaysLeft = daysLeft
                daysLeft = 0
                isPurchased = false
                switch(result) {
                case .success(let credentials):
                    
                    let _ = self.credentialsManager.store(credentials: credentials)
                    // If you have Refresh Token Rotation enabled, you get a new Refresh Token
                    // Otherwise you only get a new Access Token
                    
                    self.credential = credentials
                    
                    print(self.credential!.accessToken)
                    print(self.credential!.idToken)

                    self.user = User(from: self.credential!.accessToken)

                    print(self.user?.subscriptionStatus)
                    
                    
                    if let subscriptionStatus = self.user?.subscriptionStatus{
                        addLog(text: "subscriptionStatus is:- \(subscriptionStatus)")
                        var activeEntitlementStatus = ""
                        if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
                            if let status = activeEntitlements.first{
                                activeEntitlementStatus = status
                                if status == "personal" || status == "team_member" || status ==  "team_owner" || status == "team_size_5"{
                                    isPurchased = true
                                }else if status == "trial"{
                                    isPurchased = false
                                }else{
                                    isPurchased = false
                                }
                            }
                        }
    //                    if !isPurchased{
                        if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
                            if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
                                if let days_left = trial["days_left"] as? Int{
                                    print(days_left)
                                    daysLeft = days_left
                                }
                            }
                        }
                    }else{
                        addLog(text: "subscriptionStatus is:- nil")
                    }
                    if oldDaysLeft > 0{// subscription over need to restart
                        if isPurchased == false && daysLeft == 0{
                            addLog(text: "Subscription over")
                            DispatchQueue.main.async {
                                self.quitAndRestartApp()
                            }
                            
                        }
                    }else{
                        if daysLeft > 0 {
                            addLog(text: "Purchases found")
                            DispatchQueue.main.async {
                                self.quitAndRestartApp()
                            }
                        }else{
                            // No purchases found.
                            DispatchQueue.main.async {
                                let alert = NSAlert()
                                alert.setSharingType()
                                var noPurchasesFoundText = "No purchases found."
                                addLog(text: "No purchases found.")
                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                    noPurchasesFoundText = common.value(forKey: "noPurchasesFoundText") as? String ?? noPurchasesFoundText
                                }
                                alert.messageText = noPurchasesFoundText
                                alert.addButton(withTitle: buttonOkText)
                                
                                
                                alert.beginSheetModal(for: window, completionHandler: { (modalResponse) in
                                    if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){

                                    }
                                })
                            }
                            
                        }
                    }
                    
                    completionHandler()
                    return
                case .failure(let error):
    //                            keychain.clearAll()
                    // Handle error
                    completionHandler()
                    return
                }
        }
    }
//    func popoverDidClose(_ notification: Notification) {
//        if let cPopover = notification.object as? NSPopover{
//            if popoverTooltip != nil{
//                if popoverTooltip == cPopover{
//                 //   popover.behavior = .transient
//                    DispatchQueue.global().async {
//                        usleep(50000)
//                        DispatchQueue.main.async {
//                            self.popover.behavior = .transient
//                        }
//                    }
//                }
//            }
//        }
//    }
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

//popUpMenuWindow level ko modalPanelWindow  kiya h qki popUpMenuWindow nspopover  se bhi upar aa rha h







 



// 4 hour app deactivate k case mai evening habit or shutoff or focus summary aata h
//lekin agar kisi se focus summary ya evening habit ko 4 hour app deactivate kiyta h to sirf shutoff ayga, focus summary 4 hour deactivate se evening routine bhi skip hogi



// note break activity postpone krke sleep mac akrte h to mac jagne k baad break activity   normal timer lgega
// net band krke habit kar payga user lekin net aate hi net se get krenge  or current activity or net ki same hai to progress local vali  hi use krenge

// ab se break warning mai bhji app state activity hogi




//onboarding flow
// welcomw onboardingview(user can postpone boboarding from here)
// full screen:-   what your goals screen(morning habit or break only)
//                 always block site settings
//                 start 30 seconds mindful breathing
//                 breathing finished set up a account for you   (unlock machine)
// login sinup views
//onboarding cards view
// pre focus mode creation with apps and urls
// load complete app and show focus tips
// show onboarding video after focus tips
//

//9/1/23
//* vala kaam done

// signup mai eys kk cion k click per text select ho rha h done


//we can also show a warning "All websites will be blocked - add safe sites that you want to allow"

//and "All websites will be allowed - add unsafe sites that you want to block"

//"

//cant reproduce evening habit bug 

// break activity shut off k bich mai aa rha tha done


// ask password again done


// start session
// Time spend unfocused 00:00:00





//10/1/22
// old 2 bugs
// new screen with text
// onboarding windows in cener
// add time in start focus view
// resume habits button


