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
    @IBOutlet weak var menuItemUninstall: NSMenuItem!
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
                //                print("Pressed at \(Date())")
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
                //                print("Pressed at \(Date())")
                self?.macSleepPauseFocusModeIfRunning()
                
            }
        }
    }
    var hotKeyResumeFocusMode: HotKey? {
        didSet {
            guard let hotKey = hotKeyResumeFocusMode else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                //                print("Pressed at \(Date())")
                self?.macSleepPauseFocusModeIfRunning()
                
            }
        }
    }
    
    
    
    
    var timerCheckReactivateTime:Timer?
    var timerCheckClearPasswordTime:Timer?
    var timerBackgroundThread:Timer?
    
    var timerExtraNagsAfterInactivity:Timer?
    
    var timerExtraNagsAfterTrialExpired:Timer?
    
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
            NSApplication.shared.activate(ignoringOtherApps: true)
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
    //
    ////        sessionStart = true
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
    ////                if !sessionStart{
    ////                    addLog(text: "session already closed")
    ////                    return;
    ////                }
    ////                sessionStart = false
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
    ////                            showOnboardingCardWindow()
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
    var lastOpenUrlString = ""
    
    open func application(_ application: NSApplication, open urls: [URL]) {
        //        print(urls)
        if let url = urls.first{
            let urlString = url.absoluteString
            lastOpenUrlString = urlString
            if isSettingsLoddedInAppdelegate{
                filterUrl(url: lastOpenUrlString)
            }
        }
    }
    
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        //  ********************************* Todo Always Comment This *************************************//
        //        let domain = Bundle.main.bundleIdentifier!
        //        UserDefaults.standard.removePersistentDomain(forName: domain)
        //        UserDefaults.standard.synchronize()//
        //        exit(1)
        //        return;
        //  **********************************************************************************************//
        
        
        
        //        if let path = Bundle.main.path(forResource: "intelone-mono-font-family-regular", ofType: "ttf") {//
        //            let url = URL(fileURLWithPath: path)
        //            print(url)
        //            var errorRef: Unmanaged<CFError>?
        //            let val = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &errorRef)
        //            print(errorRef)
        //        }
        //
        //        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
        //        for family in fontFamilies {
        //            print(family)
        //            let familyFonts = NSFontManager.shared.availableMembers(ofFontFamily: family)
        //            if let fonts = familyFonts {
        //                for font in fonts {
        //                    print("\t\(font)")
        //
        //                }
        //            }
        //        }
        
        
        menuItemUninstall.isHidden = true
        client.start()// for getting true time
        
        updater = SUUpdater(for: Bundle.main)
        updater?.automaticallyChecksForUpdates = true
        
        // -----------------------------GENERATE LOG FILE----------------------------
        let bundel = Bundle.main.bundleIdentifier ?? ""
        let applicationSupportPath = "/Users/\(NSUserName())/Library/Application Support/\(bundel)"
        CreateDirectoryIfNotExist(path: applicationSupportPath)
        applicationSupportURL  = URL(fileURLWithPath: applicationSupportPath)
        DebugLogsFolderURL = applicationSupportURL!.appendingPathComponent("Logs")
        CreateDirectoryIfNotExist(path: DebugLogsFolderURL!.path)
        DebugLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Logs.txt")
        DebugGraphLogsURL = DebugLogsFolderURL!.appendingPathComponent("Debug_Graphs_Logs.txt")
        quantityCsvURL = applicationSupportURL!.appendingPathComponent("eystStats.csv")
        offlineActivitiesCsvURL = applicationSupportURL!.appendingPathComponent("offlineActivities.csv")
        trackFilesFolderURL = applicationSupportURL!.appendingPathComponent("Tracks")
        CreateDirectoryIfNotExist(path: trackFilesFolderURL!.path)
        
        
        let filename = "focus-block.html"//also change in defaultAllowedUrl
        let fileUrl = applicationSupportURL!.appendingPathComponent(filename)
        
        let logoURL = self.applicationSupportURL!.appendingPathComponent("logo.svg")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: logoURL.path){
            if let path = Bundle.main.path(forResource: "logo", ofType: "svg") {
                let url = URL(fileURLWithPath: path)
                do{
                    try fileManager.copyItem(at: url, to: logoURL)
                }catch{
                    print(error)
                }
            }
        }
        
        allApiObject.downloadBlockPageAsync(url: URL(string: "https://focus-bear.github.io/assets/focus-blocked/index.html"), destinationUrl: fileUrl){ (success, error) in
            
            
            print(success)
            
        }
        blockWebUrlString = fileUrl.absoluteString//"https://focus-bear.github.io/assets/focus-blocked/"
        
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
        
        if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity)
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
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)//this is correct, needs to block uls ven if user is not logged in
                NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
                
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
                        showWelcomeWindow()
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
                    
                    allApiObject.isInternetOn(completionHandler: {isInternetOn in
                        DispatchQueue.main.async {
                            if !isInternetOn{
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
                                allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                                let alert = NSAlert()
                                alert.setSharingType()
                                var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                    someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                                }
                                alert.messageText = someProblemInCredentialText
                                alert.addButton(withTitle: buttonOkText)
                                NSApplication.shared.activate(ignoringOtherApps: true)
                                alert.runModal()
                                self.logout()
                            }
                        }
                        
                    })
                    
                    
                    
                }else{
                    addLog(text: "failed:- newCredential nil : show alert and logout")
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        self.abortAllProcess()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                    NSApplication.shared.activate(ignoringOtherApps: true)
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
            //                print(self.credential!.accessToken)
            //                print(self.credential!.idToken)
            //                print(self.credential?.expiresIn)
            
            self.user = User(from: self.credential!.accessToken)
            
            
            
            
            
            //            if let subscriptionStatus = self.user?.subscriptionStatus{
            //                var activeEntitlementStatus = ""
            //                if let activeEntitlements = subscriptionStatus["activeEntitlements"] as? [String]{
            //                    if let status = activeEntitlements.first{
            //                        activeEntitlementStatus = status
            //                        if status == "personal" || status == "team_member" || status ==  "team_owner" || status == "team_size_5"{
            //                            isPurchased = true
            //                        }else if status == "trial"{
            //                            isPurchased = false
            //                        }else{
            //                            isPurchased = false
            //                        }
            //                    }
            //                }
            //                let oldDaysLeft = daysLeft
            //                daysLeft = 0
            //                print(subscriptionStatus)
            //                if let expirations = subscriptionStatus["expirations"] as? [String:Any]{
            //                    if let trial = expirations[activeEntitlementStatus] as? [String:Any]{
            //                        if let days_left = trial["days_left"] as? Int{
            //                            print(days_left)
            //                            daysLeft = days_left
            //                        }
            //                    }
            //                }
            //                if !isAppLaunching{
            //                    if oldDaysLeft > 0{// subscription over need to restart
            //                        if isPurchased == false && daysLeft == 0{
            //                            addLog(text: "subscription over:- need to restart app")
            //                            DispatchQueue.main.async {
            //                                self.quitAndRestartApp()
            //                            }
            //
            //                        }
            //                    }
            //                }
            //            }
        }
    }
    
    
    func loadCredentialsAndDeviceId(){
        addLog(text: "load Credentials And DeviceId")
        
        if UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserDefaultsFirstAppFullLoadDate)
        }
        credentialsManager.credentials { [self] credentialsInfo in
            
            setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: true)
            
            if self.credential == nil{ //  it means failed to get cradential and popup offline or error msg is visible
                return;
            }
            if self.credential != nil{
                print(self.credential!.accessToken)
                
                
                DispatchQueue.main.async {
                    
                    allApiObject.getUserSubscriptionInfo(completionHandler: {dic in
                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
                        var subscriptionStatus: [String : Any]?
                        if let subscriptionStatusDic = dic as? [String:Any]{
                            subscriptionStatus = subscriptionStatusDic
                        }else if let subscriptionStatusDic = self.user?.subscriptionStatus{
                            subscriptionStatus = subscriptionStatusDic
                        }
                        
                        isPurchased = false
                        if let subscriptionStatus = subscriptionStatus{
                            
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
                            if oldDaysLeft > 0{// subscription over need to restart
                                if isPurchased == false && daysLeft == 0{
                                    addLog(text: "subscription over:- need to restart app")
                                    DispatchQueue.main.async {
                                        self.quitAndRestartApp()
                                    }
                                    
                                }
                            }
                            
                        }
                        
                        
                        
                        DispatchQueue.main.async {
                            // ----------------SET DeviceID---------------------------------
                            addLog(text: "User Id is :- \(self.user?.userId ?? "")")
                            kUserdefaultsDeviceId = kUserdefaultsDeviceId + (self.user?.userId ?? "")
                            kUserdefaultsIsAppEnabled = kUserdefaultsIsAppEnabled + (self.user?.userId ?? "")
                            kUserdefaultsLastAppAbortedDate = kUserdefaultsLastAppAbortedDate + (self.user?.userId ?? "")
                            kUserdefaultsLastFocusModeDoneDate = kUserdefaultsLastFocusModeDoneDate + (self.user?.userId ?? "")
                            kUserdefaultsLastInactivityNagShowDate = kUserdefaultsLastInactivityNagShowDate + (self.user?.userId ?? "")
                            kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate = kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate + (self.user?.userId ?? "")
                            kUserdefaultsLastHabitSavedNotes = kUserdefaultsLastHabitSavedNotes + (self.user?.userId ?? "")
                            kUserdefaultsLastActivitySavedNotes = kUserdefaultsLastActivitySavedNotes + (self.user?.userId ?? "")
                            kUserdefaults4HourReActivateTime = kUserdefaults4HourReActivateTime + (self.user?.userId ?? "")
                            kUserdefaultsShutdownAborted = kUserdefaultsShutdownAborted + (self.user?.userId ?? "")
                            kUserdefaultsEveningHabitsShowedTillDate = kUserdefaultsEveningHabitsShowedTillDate + (self.user?.userId ?? "")
                            kUserdefaultsFocusSummaryShowedTillDate = kUserdefaultsFocusSummaryShowedTillDate + (self.user?.userId ?? "")
                            kUserdefaultsArrFocusTypes = kUserdefaultsArrFocusTypes + (self.user?.userId ?? "")
                            kUserdefaults24HoursClearPasswordTime = kUserdefaults24HoursClearPasswordTime + (self.user?.userId ?? "")
                            
                            kUserdefaultsLastHabitsStartedDate = kUserdefaultsLastHabitsStartedDate + (self.user?.userId ?? "")
                            kUserdefaultsLastHabitRunningInfo = kUserdefaultsLastHabitRunningInfo + (self.user?.userId ?? "")
                            kUserdefaultsLastSequencePostponeInfo = kUserdefaultsLastSequencePostponeInfo + (self.user?.userId ?? "")
                            kUserdefaultsLastBreakActivityPostponeInfo = kUserdefaultsLastBreakActivityPostponeInfo + (self.user?.userId ?? "")
                            
                            kUserdefaultsNotesAddedInOfflineCsv = kUserdefaultsNotesAddedInOfflineCsv + (self.user?.userId ?? "")
                            
                            kUserdefaultsEditFocusModeOnce = kUserdefaultsEditFocusModeOnce + (self.user?.userId ?? "")
                            kUserdefaultsEditHabitsOnce = kUserdefaultsEditHabitsOnce + (self.user?.userId ?? "")
                            kUserdefaultsEditBlockedUrlsOnce = kUserdefaultsEditBlockedUrlsOnce + (self.user?.userId ?? "")
                            kUserdefaultsMorningRoutineDoneCount = kUserdefaultsMorningRoutineDoneCount + (self.user?.userId ?? "")
                            kUserdefaultsEveningRoutineDoneCount = kUserdefaultsEveningRoutineDoneCount + (self.user?.userId ?? "")
                            kUserdefaultsFocusModeDoneCount = kUserdefaultsFocusModeDoneCount + (self.user?.userId ?? "")
                            kUserdefaultsLastFocusSavedIntention = kUserdefaultsLastFocusSavedIntention + (self.user?.userId ?? "")
                            
                            
                            kUserdefaultsFocusModeNotes = kUserdefaultsFocusModeNotes + (self.user?.userId ?? "")
                            
                            if let notes = UserDefaults.standard.object(forKey: "kUserdefaultsFocusModeNotes") as? String{// get notes from old key and remove it from old key
                                UserDefaults.standard.set(notes, forKey: kUserdefaultsFocusModeNotes)
                                UserDefaults.standard.removeObject(forKey: "kUserdefaultsFocusModeNotes")
                            }
                            //                    var kUserdefaultsFocusModeNotes = "kUserdefaultsFocusModeNotes"
                            
                            SettingsManagerObject.resetAllKeys()
                            
                            allApiObject.getAllTracks(completionHandler: {arrJson in
                                print(arrJson)
                                
                                autoreleasepool{
                                    if arrJson != nil{
                                        for item in arrJson!{
                                            let artist = item.value(forKey: "artist") as? String ?? ""
                                            let description = item.value(forKey: "description") as? String ?? ""
                                            let download_url = item.value(forKey: "download_url") as? String ?? ""//URL(string:item.value(forKey: "download_url") as? String ?? "")
                                            let duration = Int(item.value(forKey: "duration") as? String ?? "") ?? 0
                                            let id = item.value(forKey: "id") as? String ?? ""
                                            let name = item.value(forKey: "name") as? String ?? ""
                                            let pathExtension = URL(string: download_url)?.pathExtension ?? ""
                                            let localUrl = trackFilesFolderURL!.appendingPathComponent(id + "." + pathExtension)
                                            
                                            let thumbnail_download_url = item.value(forKey: "thumbnail_download_url") as? String ?? ""
                                            let thumbnailExtension = URL(string: thumbnail_download_url)?.pathExtension ?? ""
                                            let thumbnailLocalUrl = trackFilesFolderURL!.appendingPathComponent(id + "." + thumbnailExtension)
                                            
                                            
                                            var isFileDownloading = false
                                            var isFileDownloded = true
                                            if !FileManager.default.fileExists(atPath: localUrl.path){
                                                isFileDownloded = false
                                                isFileDownloading = false
                                                
                                            }
                                            arrAllTracks.append(["artist":artist, "description":description, "download_url":download_url, "id":id, "name":name, "url":localUrl.path, "isFileDownloded":isFileDownloded, "isFileDownloading":isFileDownloading, "isPlaying":false, "thumbnailLocalUrl":thumbnailLocalUrl.path, "thumbnail_download_url":thumbnail_download_url, "duration":duration])
                                            
                                        }//
                                    }else{
                                        arrAllTracks = UserDefaults.standard.object(forKey: kUserdefaultsAllTracks) as? [[String : Any]] ?? []
                                        for i in 0..<arrAllTracks.count{
                                            arrAllTracks[i]["isPlaying"] = false
                                            arrAllTracks[i]["isPaused"] = false
                                        }
                                    }
                                    UserDefaults.standard.set(arrAllTracks, forKey: kUserdefaultsAllTracks)
                                    DispatchQueue.main.async {
                                        if allTracksVcObj != nil && allTracksWindowControllerObj != nil{
                                            if allTracksWindowControllerObj?.window?.isVisible ?? false{
                                                allTracksVcObj?.tblView.reloadData()
                                            }
                                        }
                                    }
                                }
                                checkAllTracksDownloadState()
                            })
                            
                            
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
                                            allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                                            let alert = NSAlert()
                                            alert.setSharingType()
                                            alert.messageText = "Unable to connect to server. Please check your internet connection."
                                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                                alert.messageText = common.value(forKey: "checkInternetText") as? String ?? alert.messageText
                                            }
                                            alert.addButton(withTitle: buttonOkText)
                                            NSApplication.shared.activate(ignoringOtherApps: true)
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
                        
                        
                    })
                    
                    
                    
                    
                    
                    
                    
                    
                    
                    
                }
                
            }else{
                DispatchQueue.main.async {
                    addLog(text: "credential nil:- ask login again")
                    allApiObject.capturePosthog(event: "automatic-logout", metadata: [:])
                    let alert = NSAlert()
                    alert.setSharingType()
                    var someProblemInCredentialText = "There was a problem connecting to the backend server. Please login again."//example. no internet and credentialsManager.credentials is failed
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        someProblemInCredentialText = common.value(forKey: "someProblemInCredentialText") as? String ?? someProblemInCredentialText
                    }
                    alert.messageText = someProblemInCredentialText
                    alert.addButton(withTitle: buttonOkText)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    alert.runModal()
                    self.logout()
                }
            }
            
        }
    }
    
    
    
    func loadAppAndSettings(){
        addLog(text: "load App And Settings")
        
        //  ----------------------START APP AT LOGIN-----------------------
        
        
        
        
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
            let csvString = "activity_id,duration_logged,device_id,activity_sequence_id,start_time,finish_time,skipped_did_complete,choice_id,quantity_logged,skipped_did_not_complete,note_logged\n"//start time will only be use in focus block start k time per
            
            do {
                try csvString.write(to: offlineActivitiesCsvURL, atomically: true, encoding: .utf8)
            } catch {
                print("error creating file")
            }
            UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
        }else if UserDefaults.standard.object(forKey: kUserdefaultsNotesAddedInOfflineCsv) == nil{
            
            addNotesEntryInOfflineCsv()
            UserDefaults.standard.set(true, forKey: kUserdefaultsNotesAddedInOfflineCsv)
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
        
        
        //        var urlString = originalString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        
        
        //  ------------------------------------------------------------------------------------
        
        
        
        
        SettingsManagerObject.getUserLocalDeviceSettings(completionHandler: {
            
            DispatchQueue.main.async {
                
                
                if SettingsManagerObject.shouldReloadAfterForceQuitEnabled{
                    createLaunchAgent()// keep alive // todo uncomment
                }else{
                    deleteLaunchAgent()
                }
                
                
                //                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
                //                NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
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
                            arrFocusType[i]["isPaused"] = false
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
                        let dic:[String:Any] = ["id":id, "name":"Block super distracting sites/apps", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "blocked_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isDefault":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[]]//#453//tags
                        //, "isBlockedAllUrls":false , "isAllowedAllUrls":true
                        arrFocusType.insert(dic, at: 0)
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in
                            
                        })
                        
                        
                    }
                    else{//defalt focus mode will always be last in list so rearranging it
                        if defaultContainLocation == 0{
                            if arrFocusType[defaultContainLocation]["isAllowedAllApps"] as? Bool == true{
                                arrFocusType[defaultContainLocation]["isAllowedAllApps"] = false
                                arrFocusType[defaultContainLocation]["blocked_apps"] = []
                                arrFocusType[defaultContainLocation]["allowed_apps"] = []
                                arrFocusType[defaultContainLocation]["isAllowedListApproach"] = false
                                arrFocusType[defaultContainLocation]["allowed_urls"] = []
                                arrFocusType[defaultContainLocation]["blockUrlsArray"] = []
                                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                                
                                allApiObject.editFocusMode(focusType: arrFocusType[defaultContainLocation], completionHandler: {newDic in
                                    DispatchQueue.main.async {
                                        print("*************************api called*****************")
                                        
                                    }
                                })
                            }
                            
                        }else{
                            var dic = arrFocusType[defaultContainLocation]
                            if dic["isAllowedAllApps"] as? Bool == true{
                                dic["isAllowedAllApps"] = false
                                dic["blocked_apps"] = []
                                dic["allowed_apps"] = []
                                dic["isAllowedListApproach"] = false
                                dic["allowed_urls"] = []
                                dic["blockUrlsArray"] = []
                                
                                allApiObject.editFocusMode(focusType: dic, completionHandler: {newDic in
                                    DispatchQueue.main.async {
                                        print("*************************api called*****************")
                                        
                                    }
                                })
                            }
                            arrFocusType.remove(at: defaultContainLocation)
                            arrFocusType.insert(dic, at: 0)
                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        }
                        
                    }// if any new default focus mode created then count should be changed in kUserdefaultsFocusTipsShown
                    if !isMeetingsContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Meetings", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Teams.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app", "/Applications/Sidekick.app", "/Applications/Brave Browser.app"], "allowed_urls": ["http://meet.google.com"], "isOn": false, "isAllowedAllApps":false, "isMeetings":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[]]//#453 , "isBlockedAllUrls":false , "isAllowedAllUrls":false
                        
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
                        let dic:[String:Any] = ["id":id, "name":"Locked Focus on current activity", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isLockedFocus":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[]]//#453 , "isAllowedAllUrls":false , "isBlockedAllUrls":false
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.append(dic)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in
                            
                            
                        })
                        
                    }
                    
                    
                    //                    if let dic = UserDefaults.standard.object(forKey: kUserdefaultsFocusAddedFromFirstHabit) as? [String : Any]{
                    //                        var jobAllreadyAdded = false // if allready added then we will not add again same jobtype
                    //                        if let jobType = dic["name"] as? String{
                    //                            for focus in arrFocusType{
                    //                                if focus["name"] as? String == jobType{
                    //                                    jobAllreadyAdded = true
                    //                                    break;
                    //                                }
                    //                            }
                    //
                    //                        }
                    //                        if !jobAllreadyAdded{
                    //
                    //
                    //                            if arrFocusType.count == 0{
                    //                                arrFocusType.append(dic)
                    //                            }else{
                    //                                arrFocusType.insert(dic, at: 0)
                    //                            }
                    //                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    //                            allApiObject.addFocusMode(focusType: dic, completionHandler: {newDic in
                    //
                    //                            })
                    //                        }
                    //
                    //                        UserDefaults.standard.removeObject(forKey: kUserdefaultsFocusAddedFromFirstHabit)
                    //                    }
                    
                    
                    
                    for i in 0..<arrFocusType.count{
                        if arrFocusType[i]["isAllowedListApproach"] == nil{
                            arrFocusType[i]["isAllowedListApproach"] = true
                        }
                    }
                    
                    // locked in current focus should not be visible in focus prefrences thats why removing it and adding it at the end so that we will not show last item in list//486 - Remove Locked Focus
                    for i in 0..<arrFocusType.count{
                        if let state = arrFocusType[i]["isLockedFocus"] as? Bool{
                            if  state{
                                if i != arrFocusType.count - 1{
                                    let focusMode = arrFocusType[i]
                                    arrFocusType.remove(at: i)
                                    arrFocusType.append(focusMode)
                                }
                                break;
                            }
                        }
                        
                    }
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    
                    
                    arrFocusTypeForPomodoro.removeAll()
                    for i in 0..<arrFocusType.count{
                        if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true) && !(arrFocusType[i]["isLockedFocus"] as? Bool ?? false == true){
                            arrFocusTypeForPomodoro.append(arrFocusType[i])
                        }
                    }
                    
                    if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
                        if arrFocusType.count > 3{
                            UserDefaults.standard.set(true, forKey: kUserdefaultsFocusTipsShown)
                        }else{
                            allApiObject.getFocusTemplateInfo(completionHandler: { json in
                                if json != nil{
                                    
                                }
                            }
                            )
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
                
                
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screenIsLocked"),object: nil)
                DistributedNotificationCenter.default().addObserver(self,selector: #selector(self.sleepEvent(_:)), name: NSNotification.Name(rawValue: "com.apple.screenIsUnlocked"),object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.macWillPowerOff(_:)), name: NSWorkspace.willPowerOffNotification, object: nil)
                
                
            }
            
        }
        )
        
        
        
    }
    
    @objc private func macWillPowerOff(_ aNotification: Notification) {
        //respond to the power-off notification
        addLog(text: "func:- macWillPowerOff")
        createLaunchAgent()
        terminateFromSelf = true
    }
    // Are you sure you want to change the language to "language name"?
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }
    func pauseHabitActivityIfRunning(){
        addLog(text: "func:- pauseHabitActivityIfRunning")
        //                print("pause Habit Activity If Running Called")
        macGoesInSleepTime = Date()
        if  currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
            if currentAction == ._INPROGRESS_ && timerViewcontrollerObj?.timer != nil{
                isLastActivityStoppedInRunningState = true
                lastActivityStoppedTimerCount = timerViewcontrollerObj?.currentTimer ?? 0
                timerViewcontrollerObj?.timer?.invalidate()
                timerViewcontrollerObj?.timer  = nil
                if timerViewcontrollerObj?.isVideoLodded ?? false{
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
                if toolBoxWcObj != nil{
                    if toolBoxWcObj!.window!.isVisible{
                        toolBoxWcObj?.window?.close()
                    }
                }
                if smallCountDownWcObj != nil{
                    if smallCountDownWcObj!.window?.isVisible ?? false{
                        getsmallCountDownVcObject().closeTimerBox()
                    }
                }
                enableSystemSleep()// dont change current state
                mainWindowControllerObj?.window?.close()
                hideBlankWindowInSecondaryMonitor()
                //                print("pause Habit Activity If Running Called:- Success")
            }
        }
    }
    func pauseBreakActivityTimerIfRunning(){
        addLog(text: "pause Break Activity Timer Called")
        //                print("pause Break Activity Timer Called")
        if  currentState == ._ACTIVITY_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{// no need to check morning or evening habit beacuse now morning evening habits can show breaks
            addLog(text: "return - no need to pause:- \(currentState)")
            //                print("return - no need to pause:- \(currentState)")
            return
        }
        
        if mainViewControllerObj?.breakTimer != nil{
            mainViewControllerObj?.breakTimer?.invalidate()
            mainViewControllerObj?.breakTimer = nil
            isActivityTimerPaused = true
            addLog(text: "pause Break Activity Timer Done")
            //                print("pause Break Activity Timer Done")
        }else{
            addLog(text: "Timer Already nil - return")
            //                print("Timer Already nil - return")
        }
        
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
        
        if mainViewControllerObj?.breakTimer == nil{
            mainViewControllerObj?.setActivityTimer()
        }
        //        }else{
        //            addLog(text: "return - not activity time")
        //            return;
        //        }
    }
    @objc private func sleepEvent(_ aNotification: Notification) {
        //                print("******didwakeup psps*******")
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
            if !isScreenLocked{
                pauseBreakActivityTimerIfRunning()
                pauseHabitActivityIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            addLog(text: "Woke up")
            isSystemSleep = false
            if !isScreenLocked{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()//always calll this function before returnFromSystemSleepCheckAppStateAgain func
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
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
            if !isSystemSleep && !isScreenLocked{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screenIsLocked") {
            print("com.apple.screenIsLocked")
            addLog(text: "com.apple.screenIsLocked")
            isScreenLocked = true
            if !isSystemSleep && !isScreenSaverStart{
                pauseBreakActivityTimerIfRunning()
                pauseHabitActivityIfRunning()
            }
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screenIsUnlocked") {
            print("com.apple.screenIsUnlocked")
            addLog(text: "com.apple.screenIsUnlocked")
            isScreenLocked = false
            if isActivityTimerPaused{
                resumeBreakActivityTimerIfNededed()
            }
            returnFromSystemSleepCheckAppStateAgain()
        }else {
            print("Some other event other than the first four")
        }
        
        
        
        
        if !isFocusModeOn(){
            isAutoFocusPaused = false
            return;
        }
        
        if aNotification.name == NSWorkspace.willSleepNotification {
            print("Going to sleep")
            
            if !isAutoFocusPaused{
                macSleepPauseFocusModeIfRunning()
            }
        }else if aNotification.name == NSWorkspace.didWakeNotification {
            print("Woke up")
            
            if isAutoFocusPaused{
                macSleepPauseFocusModeIfRunning()
            }
            
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstart") {
            print("com.apple.screensaver.didstart")
            
            macSleepPauseFocusModeIfRunning()
            
        }else if aNotification.name == NSNotification.Name(rawValue: "com.apple.screensaver.didstop") {
            print("com.apple.screensaver.didstop")
            
            if isSystemSleep{
                return;
            }
            if isAutoFocusPaused{
                macSleepPauseFocusModeIfRunning()
            }
        }else {
            print("Some other event other than the first four")
        }
        
    }
    
    var isActivityTimerPaused = false
    var isSystemSleep = false
    var isScreenSaverStart = false
    var isScreenLocked = false
    var isAutoFocusPaused = false// auto pause when mac goes in sleep mode
    var remainingFocusModeSecondsAfterPaused = 0
    func macSleepPauseFocusModeIfRunning(){// auto pause when mac goes in sleep mode
        isAutoFocusPaused = true
        //                print("focus paused")
        addLog(text: "pause Focus Mode If Running")
        
        if timerForFocusMode != nil{
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                focusModeActualDurationPerformed += passedSeconds
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
            self.timerCheckAllowedApps?.invalidate()
            if focusEndWarningWcObj != nil{
                if focusEndWarningWcObj?.window?.isVisible ?? false{
                    focusEndWarningWcObj?.window?.close()
                }
            }
        }
    }
    
    func macWakeupResumeFocusModeIfRunning(){// auto pause when mac goes in sleep mode
        isAutoFocusPaused = false
        print("focus resume")
        addLog(text: "resume Focus Mode If Running")
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: dic["color"] as? String ?? "")
                setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                appdelegate!.statusbutton?.imagePosition = .imageLeft
            }
        }
        DispatchQueue.global().sync {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > 120{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused - 120), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
        }
    }
    
    func extendFocusModeFor(minutes:Int){
        if minutes > 0{
            if isFocusModeOn(){
                if timerForFocusMode != nil{
                    if let fireDate =  startFocusModeTimeForPauseAndResume{
                        let interval = focusModeSecondsToPerform
                        let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                        focusModeActualDurationPerformed += passedSeconds
                        let remainingFocusModeSeconds = interval - passedSeconds
                        print("remaining seconds \(remainingFocusModeSeconds)")
                        
                        
                        timerForFocusMode?.invalidate()
                        timerForFocusMode = nil
                        timerForFocusModeEndNotification?.invalidate()
                        timerForFocusModeEndNotification = nil
                        
                        
                        startFocusModeTimeForPauseAndResume = Date()
                        focusModeSecondsToPerform = remainingFocusModeSeconds + (minutes * 60)//(minutes * 60)
                        endFocusModeTime = Calendar.current.date(byAdding: .second, value: focusModeSecondsToPerform, to: Date())
                        timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
                        RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
                        
                        if focusModeSecondsToPerform > 120{
                            timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - 120), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                            RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
                        }
                    }
                    
                    
                }
            }
        }
        
    }
    
    func pauseFocusMode(index:Int){
        if timerForFocusMode != nil{
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                focusModeActualDurationPerformed += passedSeconds
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
            self.timerCheckAllowedApps?.invalidate()
            arrFocusType[index]["isPaused"] = true
            arrFocusType[index]["isOn"] = false
            
            if focusEndWarningWcObj != nil{
                if focusEndWarningWcObj?.window?.isVisible ?? false{
                    focusEndWarningWcObj?.window?.close()
                }
            }
        }
    }
    func resumeFocusMode(index:Int){
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        arrFocusType[index]["isPaused"] = false
        arrFocusType[index]["isOn"] = true
        
        
        appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: arrFocusType[index]["color"] as? String ?? "")
        setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        appdelegate!.statusbutton?.imagePosition = .imageLeft
        DispatchQueue.global().sync {
            print("resume seconds \(self.remainingFocusModeSecondsAfterPaused)")
            print(getStringFromDate(date: endFocusModeTime!, dateFormat: "HH:mm:ss"))
            startFocusModeTimeForPauseAndResume = Date()
            focusModeSecondsToPerform = self.remainingFocusModeSecondsAfterPaused
            
            
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkFcousAllowedApp), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckAllowedApps!), forMode: RunLoop.Mode.common)
            
            timerForFocusMode = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused), target: self, selector: #selector(self.focusModeTimerFinished), userInfo: nil, repeats: false)
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            print("******************resume checkFcousAllowedApp*********************")
            
            
            
            if focusModeSecondsToPerform > 120{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(self.remainingFocusModeSecondsAfterPaused - 120), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
            DispatchQueue.main.async {
                if brainDumpWcObj != nil{
                    if brainDumpWcObj?.window != nil{
                        if brainDumpWcObj!.window!.isVisible{
                            brainDumpVcObj?.focusModeStarted()
                        }
                    }
                }
            }
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
                self.readSettingsJsonDictionary(json: nil)
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
                
                DispatchQueue.global().sync {//async {
                    self.timerExtraNagsAfterTrialExpired = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkExtraNagsAfterTrialExpired), userInfo: nil, repeats: true)
                    RunLoop.main.add((self.timerExtraNagsAfterTrialExpired!), forMode: RunLoop.Mode.common)
                }
            }else{
                self.initialWork()
            }
            //
            
        }
    }
    
    
    @objc func checkExtraNagsAfterTrialExpired(){
        if startTime == nil{
            startTime = Time(hour: 9, minute: 15, second: 0)
        }
        if shutOffTime == nil{
            shutOffTime = Time(hour: 20, minute: 15, second: 0)
        }
        
        if upgradeNowWcObj != nil{
            if upgradeNowWcObj?.window?.isVisible ?? false{
                return;
            }
        }
        
        if trialExpiredNagWcObj != nil{
            if trialExpiredNagWcObj?.window?.isVisible ?? false{
                return;
            }
        }
        if !isShutOffTimeGoing(){
            
            if UserDefaults.standard.object(forKey: kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate) as? Date == nil{
                showTrialExpiredWindow()
                return;
            }else{
                if let date = UserDefaults.standard.object(forKey: kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate) as? Date{
                    if Date().compare(date) == .orderedDescending {
                        showTrialExpiredWindow()
                        return;
                    }
                }
            }
            
        }
    }
    
    
    
    func readSettingsJsonDictionary(json:NSDictionary?){
        addLog(text: "read Settings Json Dictionary")
        arrFilteredMorningHabits.removeAll()
        arrFilteredEveningHabits.removeAll()
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
                    let id = habitDic["id"] as? String ?? ""//"image_urls","text_instructions" // completion_requirements
                    let name = habitDic["name"] as? String ?? ""
                    var durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    var logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    let take_notes = habitDic["take_notes"] as? String ?? ""
                    let days_of_week = habitDic["days_of_week"] as? [String] ?? []
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    let text_instructions = habitDic["text_instructions"] as? String ?? ""
                    let image_urls = habitDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    var useTimer = true
                    let completion_requirements = habitDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{//todo ase check krna gakat
                        useTimer = false
                        durationSeconds = 86400
                    }
                    var check_list = habitDic["check_list"] as? [String] ?? []
                    if let type = habitDic["choice_type"] as? String{//competency,  "random", check_list
                        if type != "check_list"{
                            check_list.removeAll()
                        }
                    }
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = habitDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode, activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: false, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list)
                    
                    habit.logQuantityQuestions = arrLogQuantityQuestions
                    arrFilteredMorningHabits.append(habit)
                }
            }
            
            arrAllDaysMorningHabits = arrFilteredMorningHabits
            
            
            if let eveningHabits = jsonResult!.value(forKey: "evening_activities") as? [NSDictionary] {
                print("eveningHabits")
                print(eveningHabits)
                for habitDic in eveningHabits {
                    let id = habitDic["id"] as? String ?? ""
                    let name = habitDic["name"] as? String ?? ""
                    var durationSeconds = habitDic["duration_seconds"] as? Int ?? 0
                    let videoUrl = habitDic["video_urls"] as? [String] ?? []
                    var logQuantity = habitDic["log_quantity"] as? Bool ?? false
                    let logQuantityQuestion = habitDic["log_quantity_question"] as? String
                    //                let openSpecificApps = habitDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = habitDic["allowed_urls"] as? [String] ?? []
                    let allowApps = habitDic["allowed_apps"] as? [String] ?? []
                    let allowedFocusMode = habitDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = habitDic["activity_sequence_id"] as? String ?? ""
                    let run_micro_breaks = habitDic["run_micro_breaks"] as? Bool ?? false
                    let take_notes = habitDic["take_notes"] as? String ?? ""
                    let days_of_week = habitDic["days_of_week"] as? [String] ?? []
                    let priority = habitDic["priority"] as? String ?? ""
                    var isPriorityHigh = false
                    if priority == "HIGH"{
                        isPriorityHigh = true
                    }
                    
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    
                    let text_instructions = habitDic["text_instructions"] as? String ?? ""
                    let image_urls = habitDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    var useTimer = true
                    let completion_requirements = habitDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{
                        useTimer = false
                        durationSeconds = 86400
                    }
                    let check_list = habitDic["check_list"] as? [String] ?? []
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = habitDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode,activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: isPriorityHigh, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list)
                    habit.logQuantityQuestions = arrLogQuantityQuestions
                    arrFilteredEveningHabits.append(habit)
                    
                }
            }
            
            arrAllDaysEveningHabits = arrFilteredEveningHabits
            
            if let breakActivities = jsonResult!.value(forKey: "break_activities") as? [NSDictionary] {
                print("breakActivities")
                print(breakActivities)
                for activityDic in breakActivities {
                    let id = activityDic["id"] as? String ?? ""
                    let name = activityDic["name"] as? String ?? ""
                    var durationSeconds = activityDic["duration_seconds"] as? Int ?? 0
                    let IncludeInEveryBreak = activityDic["include_in_every_break"] as? Bool ?? false
                    let videoUrl = activityDic["video_urls"] as? [String] ?? []
                    var logQuantity = activityDic["log_quantity"] as? Bool ?? false
                    //                let openSpecificApps = activityDic["openSpecificApps"] as? Bool ?? false
                    let allowUrls = activityDic["allowed_urls"] as? [String] ?? []
                    let allowApps = activityDic["allowed_apps"] as? [String] ?? []
                    let isOfficeFriendly = activityDic["is_office_friendly"] as? Bool ?? false
                    let allowedFocusMode = activityDic["allowed_focus_mode_id"] as? String ?? ""
                    let activity_sequence_id = activityDic["activity_sequence_id"] as? String ?? ""
                    let take_notes = activityDic["take_notes"] as? String ?? ""
                    
                    var openSpecificApps = false
                    if allowApps.count != 0{
                        openSpecificApps = true
                    }
                    //                    var isRandomChoice = false
                    var choiceType:CHOICETYPE = ._NONE_
                    if let type = activityDic["choice_type"] as? String{//competency,  "random", check_list
                        if type == "random"{
                            choiceType = ._RANDOM_
                        }else if type == "competency"{
                            choiceType = ._COMPETENCY_
                        }else if type == "check_list"{
                            choiceType = ._CHECKLIST_
                        }
                    }//"SUM" "AVG"// comapre
                    var arrChoices = [activityChoice]()
                    if let choices = activityDic.value(forKey: "choices") as? [NSDictionary] {
                        for dic in choices{
                            let id = dic["id"] as? String ?? ""
                            let name = dic["name"] as? String ?? ""
                            let videoUrl = dic["video_urls"] as? [String] ?? []
                            let logQuantityQuestion = dic["log_quantity_question"] as? String ?? ""
                            var logQuantity = dic["log_quantity"] as? Bool ?? false
                            let logQuantityType = dic["log_summary_type"] as? String ?? ""
                            var choice = activityChoice(name: name, urlsArray: videoUrl, logQuantityQuestion: logQuantityQuestion, logQuantity: logQuantity, logQuantityType: logQuantityType, id: id)
                            
                            var arrLogQuantityQuestions = [quantityQuestion]()
                            if let logQuantityQuestions = dic["log_quantity_questions"] as? [NSDictionary]{
                                for questionDic in logQuantityQuestions{
                                    let id = questionDic.value(forKey: "id") as? String ?? ""
                                    let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                                    let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                                    let question = questionDic["question"] as? String ?? ""
                                    let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                                    let min_value_description = questionDic["min_value_description"] as? String ?? ""
                                    let max_value_description = questionDic["max_value_description"] as? String ?? ""
                                    
                                    arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                                }
                            }
                            if arrLogQuantityQuestions.count == 0{
                                logQuantity = false
                            }
                            
                            choice.logQuantityQuestions = arrLogQuantityQuestions
                            arrChoices.append(choice)
                        }
                    }
                    var check_list = activityDic["check_list"] as? [String] ?? []
                    
                    if arrChoices.count == 0 && choiceType == ._RANDOM_{
                        choiceType = ._NONE_
                    }
                    if check_list.count == 0 && choiceType == ._CHECKLIST_{
                        choiceType = ._NONE_
                    }else if check_list.count != 0 && choiceType != ._CHECKLIST_{
                        check_list.removeAll()
                    }
                    
                    if arrChoices.count == 0 && choiceType == ._COMPETENCY_{
                        choiceType = ._NONE_
                    }
                    
                    let text_instructions = activityDic["text_instructions"] as? String ?? ""
                    let image_urls = activityDic["image_urls"] as? [[String:Any]] ?? []
                    var imgUrls = [String]()
                    for info in image_urls{
                        if let url = info["url"] as? String{
                            imgUrls.append(url)
                        }
                    }
                    
                    let logQuantityQuestion = activityDic["log_quantity_question"] as? String
                    let logQuantityType = activityDic["log_summary_type"] as? String ?? ""
                    
                    var useTimer = true
                    let completion_requirements = activityDic["completion_requirements"] as? String ?? ""
                    if !completion_requirements.isEmpty{
                        useTimer = false
                        durationSeconds = 86400
                    }
                    
                    var arrLogQuantityQuestions = [quantityQuestion]()
                    if let logQuantityQuestions = activityDic["log_quantity_questions"] as? [NSDictionary]{
                        for questionDic in logQuantityQuestions{
                            let id = questionDic.value(forKey: "id") as? String ?? ""
                            let minValue = questionDic.value(forKey: "min_value") as? Int ?? 0
                            let maxValue = questionDic.value(forKey: "max_value") as? Int ?? 0
                            let question = questionDic["question"] as? String ?? ""
                            let logQuantityType = questionDic["log_summary_type"] as? String ?? ""
                            
                            let min_value_description = questionDic["min_value_description"] as? String ?? ""
                            let max_value_description = questionDic["max_value_description"] as? String ?? ""
                            
                            arrLogQuantityQuestions.append(quantityQuestion(id: id, minValue: minValue, maxValue: maxValue, question: question, logQuantityType: logQuantityType, minValueDescription:min_value_description, maxValueDescription:max_value_description))
                        }
                    }
                    if arrLogQuantityQuestions.count == 0{
                        logQuantity = false
                    }
                    
                    var activity = breakActivity(id: id, name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, urlsArray: videoUrl, logQuantity:logQuantity, choiceType: choiceType, choices: arrChoices, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, isOfficeFriendly: isOfficeFriendly, allowedFocusMode: allowedFocusMode, logQuantityType: logQuantityType, activity_sequence_id: activity_sequence_id, take_notes: take_notes, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list)
                    activity.logQuantityQuestions = arrLogQuantityQuestions
                    arrAllbreakActivities.append(activity)
                }
            }
            
            
            
            if let breakMinutes = jsonResult!.value(forKey: "break_after_minutes") as? Int {
                //                print("breakAfterMinutes")
                breakAfterMinutes = breakMinutes
                print(breakAfterMinutes)
            }
            
            
            if let val = jsonResult!.value(forKey: "startup_time") as? String {
                startTime = getTimeFromString(val: val)
            }
            if let val = jsonResult!.value(forKey: "shutdown_time") as? String {
                shutOffTime = getTimeFromString(val: val)
            }
            
            if let val = jsonResult!.value(forKey: "cutoff_time_for_non_high_priority_activities") as? String {
                cutOffTime = getTimeFromString(val: val)
            }
            has_edited_settings =  jsonResult!.value(forKey: "has_edited_settings") as? Bool ?? false
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
        var packId = ""
        //  var isHabitsDisabled = false
        if isFirstTime{
            if let val = UserDefaults.standard.object(forKey: kUserdefaultsPackIdSelected) as? String{
                packId = val
            }
        }
        
        allApiObject.getSettings(isFirstTime: isFirstTime, packId:packId, completionHandler: {val in
            let settings = val?.mutableCopy() as? NSMutableDictionary
            
            
            if settings != nil{
                print(settings!)
                
                
                if isFirstTime{
                    
                    let breakDuration = UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationValue) as? Int ?? defaultBreakDurationValue
                    
                    
                    if let startDate = UserDefaults.standard.object(forKey: kUserdefaultsStartupTimeFromOnboarding) as? String, let shutOffDate = UserDefaults.standard.object(forKey: kUserdefaultsShutOffTimeFromOnboarding) as? String{
                        
                        settings!["startup_time"] = startDate
                        settings!["shutdown_time"] = shutOffDate
                        settings!["break_after_minutes"] = breakDuration
                        
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsBreakDurationValue)
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsStartupTimeFromOnboarding)
                        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffTimeFromOnboarding)
                        
                        allApiObject.isSettingsValid(settings: settings!, completionHandler: {dic,statusCode  in
                            DispatchQueue.main.async {
                                
                                
                                if dic == nil{
                                    
                                    
                                }else{
                                    
                                    if statusCode == 200{
                                        
                                        
                                        do {
                                            let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                            
                                            //                print(jsonResultData)
                                            
                                            if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                                UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                                //                                                appdelegate?.readSettingsJsonDictionary(json: nil)//will not do this here
                                            }
                                            
                                            
                                        } catch let myJSONError {
                                            print(myJSONError)
                                        }
                                        
                                    }else{
                                        
                                    }
                                }
                            }
                        })
                        
                    }
                }
                //                if let val = jsonResult!.value(forKey: "startup_time") as? String {
                //                    startTime = getTimeFromString(val: val)
                //                }
                //                if let val = jsonResult!.value(forKey: "shutdown_time") as? String {
                //                    shutOffTime = getTimeFromString(val: val)
                //                }
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
                            RunLoop.main.add((self.timerCheckReactivateTime!), forMode: RunLoop.Mode.common)
                        }
                    }else{
                        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                        UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
                        addLog(text: "App Reactivated after 4 hours")
                        self.quitAndRestartApp()
                        return;
                    }
                    
                }else if !isAppEnable && !isPurchased{
                    if UserDefaults.standard.object(forKey: kUserdefaultsLastAppAbortedDate) != nil{
                        DispatchQueue.global().sync {
                            self.timerExtraNagsAfterInactivity = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(self.checkExtraNagsAfterInactivity), userInfo: nil, repeats: true)
                            RunLoop.main.add((self.timerExtraNagsAfterInactivity!), forMode: RunLoop.Mode.common)
                        }
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
                            //                print("Local monitor keyDown")
                            //                print(event.keyCode)
                            if event.keyCode == 53 {
                                if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.modifierFlags.contains(.control) {
                                    if (mainWindowControllerObj?.window!.isVisible)! {
                                        self.abortAllProcess()
                                        mainWindowControllerObj?.window?.close()
                                    }
                                    hideBlankWindowInSecondaryMonitor()
                                    //                print("command contain")
                                }
                            }else if event.keyCode == 36 || event.keyCode == 76{//todo if any change in activity or habits change here
                                if mainWindowControllerObj?.window?.isVisible ?? false{
                                    if currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_{
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
                                                    //if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                                    logQuantityVcObj?.btnOkClicked(self)
                                                    // }
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
                                                        if firstViewControllerObj!.btnStartFirstHabit.isEnabled{
                                                            firstViewControllerObj?.btnStartFirstHabitClicked(self)
                                                        }
                                                    }
                                                }
                                            }else if currentState == ._ACTIVITY_{
                                                if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                                    if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                                        ///if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                                        logQuantityVcObj?.btnOkClicked(self)
                                                        //}
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
                                        if arrFilteredEveningHabits.count != 0{
                                            if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                                //if !(logQuantityVcObj?.textFieldCount.stringValue.isEmpty)!{
                                                logQuantityVcObj?.btnOkClicked(self)
                                                //}
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
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_{
                if currentAction == ._INPROGRESS_{
                    if currentHabitPlaying != nil{
                        if !currentHabitPlaying!.useTimer{
                            showcompletionRequirementsWindow(title: currentHabitPlaying!.completion_requirements)
                        }
                    }else if currentActivityPlaying != nil{
                        if !currentActivityPlaying!.useTimer{
                            showcompletionRequirementsWindow(title: currentActivityPlaying!.completion_requirements)
                        }
                    }
                }
            }
            showPopover(sender: sender)
            
            
        }
        
        
    }
    func showPopover(sender: Any?) {
        if let button = statusItem.button{
            if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
                if state{
                    statusItem.button?.window?.sharingType = .none
                }else{
                    statusItem.button?.window?.sharingType = .readOnly
                }
            }
            //
            
            if isDiscourageDefaultFocusVcVisible{
                return
            }
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
    
    @objc func checkExtraNagsAfterInactivity(){
        DispatchQueue.main.async {
            if shareFeedbackWindowControllerObj != nil{
                if shareFeedbackWindowControllerObj?.window?.isVisible ?? false{
                    return;
                }
            }
            if let date  = UserDefaults.standard.object(forKey: kUserdefaultsLastAppAbortedDate) as? Date{
                var shouldShowNag = false
                let currentDate = Date()
                if let lastFocusModeDoneDate = UserDefaults.standard.object(forKey: kUserdefaultsLastFocusModeDoneDate) as? Date{
                    let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                    
                    let diffHoursLastFocus = Calendar.current.dateComponents([.hour], from: lastFocusModeDoneDate, to: currentDate).hour ?? 0
                    if diffHours > 72  && diffHoursLastFocus > 72{
                        shouldShowNag = true
                    }
                    
                }else{
                    
                    let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                    if diffHours > 72 {
                        shouldShowNag = true
                    }
                    
                }
                
                if shouldShowNag{
                    if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastInactivityNagShowDate) as? Date{
                        let diffHours = Calendar.current.dateComponents([.hour], from: date, to: currentDate).hour ?? 0
                        if diffHours > 72 {
                            shouldShowNag = true
                        }else{
                            shouldShowNag = false
                        }
                    }else{
                        //show nag
                        shouldShowNag = true
                    }
                }
                
                
                if shouldShowNag{
                    self.showExtraNagsAfterInactivity()
                }
            }
        }
    }
    
    func showExtraNagsAfterInactivity(){
        addLog(text: "show Extra Nag After Inactivity")
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastInactivityNagShowDate)
        let alertExtraNagAfterInactivity = NSAlert()
        alertExtraNagAfterInactivity.messageText = "Still interested in improving your habits and productivity?"
        var buttonDoItText = "Yeah - let's do it"
        var buttonCancelText = "No thanks"
        
        
        if let inactivityNagInfo = configjson.value(forKey: "inactivityNagInfo") as? NSDictionary{
            alertExtraNagAfterInactivity.messageText = inactivityNagInfo.value(forKey: "title") as? String ?? alertExtraNagAfterInactivity.messageText
            buttonDoItText = inactivityNagInfo.value(forKey: "buttonDoItText") as? String ?? buttonDoItText
            buttonCancelText = inactivityNagInfo.value(forKey: "buttonCancelText") as? String ?? buttonCancelText
        }
        
        alertExtraNagAfterInactivity.setSharingType()
        
        
        alertExtraNagAfterInactivity.addButton(withTitle: buttonDoItText)
        alertExtraNagAfterInactivity.addButton(withTitle:  buttonCancelText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        let result = alertExtraNagAfterInactivity.runModal()
        if result == .alertFirstButtonReturn{
            addLog(text: "button Do It Clicked")
            menuItem_Reactivate()
        }else if result == .alertSecondButtonReturn{
            addLog(text: "button No thanks Clicked")
            showShareFeedbackWindow()
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
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
            setTimerForPomodoroMode(delay: 60*10)
            return
        }
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
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
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
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
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused.")
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
//                                showWelcomeOnboardingWindow()//
//                                showOnboardingVideoWindow()
//                                showOnboardingCardWindow(isLogin: true)
//                                showBreakWarningWindow()
//                                showEasyPostponeWindow()
//                                showMorningPomodoroModeView()
//                                showPreloadFocusModesWindow()
//                                preloadFocusModesWindowControllerObj!.contentViewController = getHowHeardVcObj()
//                                showUpgradeNowWindow()
//                                showPopUpOfflineWindow()
//                                showExtraNagsAfterInactivity()
//                                showTrialExpiredWindow()
//
//                                mainWindowControllerObj?.loadWindow()
//                                isHabitAlreadyShowed = true
//                                UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)//
//                                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)//
//                                UserDefaults.standard.set(Date().dayBefore, forKey: kUserdefaultsLastHabitShowDate)
//                                UserDefaults.standard.set(Date().dayBefore, forKey: kUserdefaultsEveningHabitsShowedTillDate)
//                                arrKeywordsToAllowInFocus = ["111", "222", "333"]//
//                                lastFocusModeTempInfo = lastFocusTempInfo(id: "currentFocusModeId", arrAllowedAppsInCuddlyModeCurrentFocus: [], arrAllowedUrlsInCuddlyModeCurrentFocus: ["google.com", "facebook.com"])
//                                showaddFocusTempUrlsOrAppsWindow()//
//
//                                showSmallTimerWindow(durationSeconds: 500, msg: "Focus mode ends in", isFocusBreak: true, currentTimerValue: 0)
//                                showFocusEndWarningWindow()
//
//                                getPreloadFocusModesWindowControllerObj()
//                                preloadFocusModesWindowControllerObj!.contentViewController = getFocusTipsVcObjObj()
//                                preloadFocusModesWindowControllerObj!.showWindow(self)
//
//                                showWelcomeWindow()
//                                showHowHeardWindow()
//                                showAskLoginWindow()
//                                showChooseFrictionLevelWindow()
//                                UserDefaults.standard.removeObject(forKey: kUserdefaultsEveningHabitsShowedTillDate)//
//                                UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
//                                mainWindowControllerObj?.loadWindow()//
//                                mainViewControllerObj?.timeToStartBreakActivities()
//                                return;//
//        todo®
//        *******************************************************************
        
        
        
        
        //      /// //  //  //
        
        
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
        
        
        if !lastOpenUrlString.isEmpty{
            filterUrl(url: lastOpenUrlString)
        }
        
        
        
        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
            
            checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
        }else{
            isHabitAlreadyShowed = false
        }
        
        if startTime != nil && shutOffTime != nil{
            //                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            
            if isShutOffTimeGoing() && shouldDoHabits(){
                if UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date == nil{
                    if currentState != ._SHUTOFFMAC_{
                        // self.shutOffMac()
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
        //        detector.startDetection()
        
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
                                                self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText + " / " + buttonStatusStateFocusText) //self.statusbutton?.title = buttonStatusStateCallText + " / " + buttonStatusStateFocusText
                                            }else{
                                                self.statusbutton?.backgroundcolor = NSColor.systemBlue
                                                //                                                self.statusbutton?.title = buttonStatusStateCallText
                                                self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateCallText)
                                                self.statusbutton?.imagePosition = .imageLeft
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
            
            
            self.statusbutton?.title = ""
            self.statusbutton?.backgroundcolor = NSColor.clear
            for dic in arrFocusType{
                if dic["isOn"] as? Bool == true{
                    appdelegate!.statusbutton?.backgroundcolor = HexToColor(hexString: dic["color"] as? String ?? "")
                    setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    appdelegate!.statusbutton?.imagePosition = .imageLeft
                }
            }
            
            
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil
            
            
        }
    }
    func setStatusBarButtonTitleForFocusMode(title:String){
        var finalTitle = ""
        if title.isEmpty{
            finalTitle = buttonStatusStateFocusText
        }else{
            let btnTitle = title.components(separatedBy: .newlines).joined()
            if btnTitle.count > 40 {
                finalTitle = String(btnTitle.prefix(40)) + "..."
            }else{
                finalTitle = btnTitle
            }
            
        }
        if isShowTimerInFocusEnabled{
            if let date = endFocusModeTime{
                let secondsBetween = date.timeIntervalSince(Date())
                
                let (h,m,s) = secondsToHoursMinutesSeconds(seconds: Int(secondsBetween))
                var hour = "\(h)"
                var minute = "\(m)"
                var second = "\(s)"
                
                if hour.count == 1 {
                    hour = "0\(h)"
                }
                
                if minute.count == 1 {
                    minute = "0\(m)"
                }
                if second.count == 1 {
                    second = "0\(s)"
                }
                
                finalTitle = "\(hour):\(minute)" + " - " + finalTitle//count down in minutes not in seconds
                
                //                if h == 0{
                //                    finalTitle = "\(minute):\(second)" + " - " + finalTitle
                //                }else{
                //                    finalTitle = "\(hour):\(minute):\(second)" + " - " + finalTitle
                //                }
            }
        }
        
        let bgColor = statusbutton?.backgroundcolor
        let r = (bgColor?.redComponent ?? 1) * 255
        let g = (bgColor?.greenComponent ?? 1) * 255
        let b = (bgColor?.blueComponent ?? 1) * 255
        
        let threshold:CGFloat = 105;
        let bgDelta = ((r * 0.299) + (g * 0.587) + (b * 0.114));
        var finalRgb = NSColor.black
        //  let Color = NSColor(re) (255 - bgDelta < threshold) ? [Color blackColor] : [Color whiteColor];
        if (255 - bgDelta < threshold){
            finalRgb = NSColor.black
        }else{
            finalRgb = NSColor.white
        }
        
        let myString = finalTitle
        let myAttribute = [ NSAttributedString.Key.foregroundColor: finalRgb ]
        let myAttrString = NSAttributedString(string: myString, attributes: myAttribute)
        statusbutton?.attributedTitle = myAttrString
        return;
        
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
        
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SHUTOFFMAC_ || currentState == ._SPECIAL_ACTIVITY_{
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
        let isFocusModeOn = isFocusModeOnOrPaused()
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
                        //                print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Start Focus clicked")
                        self.meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "func Meeting Suggestion alert:- button Cancel clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        //                print("third")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }
                
            })
            
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let result = alertSuggestFocusMode?.runModal(){
                
                if alertSuggestFocusMode?.suppressionButton?.state == .on{
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.showMeetingDetectionAlert = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                
                if isFocusModeOn{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "func Meeting Suggestion alert:- button Start Focus clicked")
                        meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "func Meeting Suggestion alert:- button Cancel clicked")
                        alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        //                print("third")
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
                    //                print("first")
                    addLog(text: "func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    self.alertSuggestFocusMode = nil
                    
                    if self.isUserOnMeeting{
                        self.isUserOnMeeting = false
                    }
                    if isFocusModeOn(){
                        self.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    }else{
                        self.statusbutton?.backgroundcolor = NSColor.clear
                        self.statusbutton?.title = ""
                    }
                }else{
                    //                print("second")
                    addLog(text: "func showAlertFalseMicDetection:- Button Cancel clicked")
                    self.alertSuggestFocusMode = nil
                }
            })
            
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let result = alertSuggestFocusMode?.runModal(){
                if result == .alertFirstButtonReturn{
                    //                print("first")
                    addLog(text: "func showAlertFalseMicDetection:- Button Disable detection clicked")
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.isMeetingDetectionEnabled = false
                    SettingsManagerObject.putUserLocalDeviceSettings()
                    alertSuggestFocusMode = nil
                    
                    if isUserOnMeeting{
                        isUserOnMeeting = false
                    }
                    
                    
                    if isFocusModeOn(){
                        setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                    }else{
                        self.statusbutton?.backgroundcolor = NSColor.clear
                        self.statusbutton?.title = ""
                    }
                    
                }else{
                    //                print("second")
                    addLog(text: "func showAlertFalseMicDetection:- Button Cancel clicked")
                    alertSuggestFocusMode = nil
                }
            }
        }
    }
    
    func meetingAlertStartFocusClicked(){
        //                print("first")
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
                        
                        timerForFocusModeEndNotification?.invalidate()
                        timerForFocusModeEndNotification = nil
                    }
                    isFocusTimeType = ._HOUR_
                    startFocusModeTimeForPauseAndResume = Date()
                    focusModeSecondsToPerform = 300
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
        
        
        if currentState == ._ACTIVITY_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_MORNING_HABIT_ || !isAppEnable || currentState == ._ABORT_ || currentState == ._SPECIAL_ACTIVITY_{
            addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- currentState is activity/postpone/abort/specialActivity")
            
            
            if currentState == ._ACTIVITY_{// if user was doing break before system sleep and after sysytem wakes up is idle time is more then 5 minutes then stop activity and set timer again
                if macGoesInSleepTime != nil{
                    let passedSeconds = Calendar.current.dateComponents([.second], from: macGoesInSleepTime!, to: Date()).second ?? 0
                    if passedSeconds > 300{
                        currentState = ._NOTHING_
                        if breakWarningWcObj != nil{
                            if breakWarningWcObj?.window?.isVisible ?? false{
                                breakWarningWcObj?.window?.close()
                            }
                        }
                        mainViewControllerObj?.stopActivityCountDownTimer()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        addLog(text: "Current State s activity: stop Break Activity Done")
                        if mainViewControllerObj?.breakTimer != nil{
                            mainViewControllerObj?.breakTimer?.invalidate()
                            mainViewControllerObj?.breakTimer = nil
                        }
                        mainViewControllerObj?.setActivityTimer()
                    }
                }
            }
            return
        }
        
        if isShutOffTimeGoing(){
            if arrFilteredEveningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrFilteredEveningHabits count is 0")
                return;
            }
        }else{
            if arrFilteredMorningHabits.count == 0 {
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- arrFilteredMorningHabits count is 0")
                return;
            }else if isHabitAlreadyShowed{
                addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- habit showed already")
                return;
            }
        }
        
        
        
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
                    //                print(arr)
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
                                            let note_logged = dic["note_logged"] as? String ?? ""
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
                                                    
                                                    
                                                    allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, is_skipped: is_skipped, notes: note_logged, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in//todo log quantity array
                                                        
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
                                
                                
                                //                print(dic)
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
    
    func filterUrl(url:String){
        if !isAppEnable{
            return;
        }
        if !isPurchased && daysLeft <= 0{
            return;
        }
        var urlString = url.removingPercentEncoding ?? url
        if urlString.contains("focusbear://start-activity?"){
            urlString = urlString.replacingOccurrences(of: "focusbear://start-activity?", with: "")
            
            // focusbear://start-activity?activity_id=1234s-sdf-&duration=600
            
            let activityInfo = urlString.components(separatedBy: "&")
            if activityInfo.count > 1{
                //let activityInfo = urlString.components(separatedBy: "=")
                
                let activityIdInfo  = activityInfo[0].components(separatedBy: "=")
                let activityDurationInfo  = activityInfo[1].components(separatedBy: "=")
                
                if activityIdInfo.count > 1 && activityDurationInfo.count > 1{
                    let activityId = activityIdInfo[1]
                    let activityDuration = activityDurationInfo[1]
                    //                print(activityId)
                    //                print(activityDuration)
                    
                    var isActivityFound = false
                    var specialHabit:habit?
                    var specialActivity:breakActivity?
                    
                    for habit in arrAllDaysMorningHabits{
                        if habit.id == activityId{
                            specialHabit = habit
                            isActivityFound = true
                            break;
                        }else if habit.name.lowercased() == activityId.lowercased(){
                            specialHabit = habit
                            isActivityFound = true
                            break;
                        }
                    }
                    
                    if !isActivityFound{
                        for habit in arrAllDaysEveningHabits{
                            if habit.id == activityId{
                                specialHabit = habit
                                isActivityFound = true
                                break;
                            }else if habit.name.lowercased() == activityId.lowercased(){
                                specialHabit = habit
                                isActivityFound = true
                                break;
                            }
                        }
                    }
                    
                    if !isActivityFound{
                        for activity in arrAllbreakActivities{
                            if activity.id == activityId{
                                specialActivity = activity
                                isActivityFound = true
                                break;
                            }else if activity.name.lowercased() == activityId.lowercased(){
                                specialActivity = activity
                                isActivityFound = true
                                break;
                            }
                        }
                    }
                    
                    if isActivityFound{
                        let durationInSeconds = Int(activityDuration) ?? 0
                        if durationInSeconds > 0{
                            
                            
                            if !isMainWindowLodded{
                                mainWindowControllerObj?.loadWindow()
                            }
                            
                            if currentAction == ._INPROGRESS_{
                                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                                    if timerViewcontrollerObj != nil {
                                        if timerViewcontrollerObj?.timer != nil {
                                            timerViewcontrollerObj?.timer?.invalidate()
                                            enableSystemSleep()
                                            if timerViewcontrollerObj?.isVideoLodded ?? false{
                                                if !(timerViewcontrollerObj?.isActivityPaused ?? false){
                                                    if #available(macOS 12.0, *) {
                                                        if timerViewcontrollerObj?.boxButtonTabViews.isHidden == false{
                                                            timerViewcontrollerObj?.btnTabVideoClicked(self)
                                                        }
                                                        timerViewcontrollerObj?.webView.setAllMediaPlaybackSuspended(true)
                                                    } else {
                                                        // Fallback on earlier versions
                                                        timerViewcontrollerObj?.loadBlankUrl()
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                                        if smallCountDownWcObj?.window != nil{
                                            if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                                if getsmallCountDownVcObject().timer != nil {
                                                    getsmallCountDownVcObject().timer?.invalidate()
                                                    getSmallCountDownWindowObject().window?.close()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            mainViewControllerObj?.refreshLastPostponeCount()
                            closePupUpBlockIfVisible()
                            if currentState == ._MORNING_HABIT_{
                                mainViewControllerObj?.stopActivityTimer()
                                mainViewControllerObj?.postponeMorningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false)
                            }else if currentState == ._EVENING_HABIT_{
                                mainViewControllerObj?.stopActivityTimer()
                                mainViewControllerObj?.postponeEveningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false)
                            }else if currentState == ._ACTIVITY_{
                                if breakWarningWcObj != nil{
                                    if breakWarningWcObj?.window?.isVisible ?? false{
                                        breakWarningVcObj?.timer?.invalidate()
                                        breakWarningWcObj?.window?.close()
                                    }
                                }
                                
                                mainWindowControllerObj?.window?.close()
                                hideBlankWindowInSecondaryMonitor()
                                mainViewControllerObj?.postponeBreakActivitiesFor(minutes: breakAfterMinutes, secondsToPostpone: nil)
                            }else{
                                mainWindowControllerObj?.window?.close()
                                hideBlankWindowInSecondaryMonitor()
                            }
                            
                            
                            mainViewControllerObj?.startSpecialActivity(duration: durationInSeconds,habit:specialHabit, activity:specialActivity)
                        }
                    }
                    
                    
                }
            }
        }
        else if urlString.contains("focusbear://event-about-to-start?"){
            urlString = urlString.replacingOccurrences(of: "focusbear://event-about-to-start?", with: "")
            
            let arrActivityInfo = urlString.components(separatedBy: "&")
            if arrActivityInfo.count > 1{
                var eventTitle = ""
                var eventStartTime:Date?// = Date()
                var eventEndTime:Date?
                
                for info in arrActivityInfo{
                    let eventInfo  = info.components(separatedBy: "=")
                    if eventInfo.count > 1{
                        if eventInfo[0] == "event_title"{
                            eventTitle = eventInfo[1]
                        }else if eventInfo[0] == "event_start_time"{
                            let stringDate = eventInfo[1]
                            eventStartTime = getDateFromStringInUtc(date: stringDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                        }else if eventInfo[0] == "event_end_time"{
                            let stringDate = eventInfo[1]
                            eventEndTime = getDateFromStringInUtc(date: stringDate, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                        }
                    }
                }
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
                    
                    lastCurrentState = currentState
                    lastCurrentAction = currentAction
                    mainViewControllerObj?.stopActivityCountDownTimer()
                    
                    if currentHabitPlaying != nil || currentActivityPlaying != nil{
                        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
                            if smallCountDownWcObj?.window != nil{
                                if getSmallCountDownWindowObject().window!.isVisible && !getsmallCountDownVcObject().isFocusBreak{
                                    getSmallCountDownWindowObject().window?.close()
                                }
                            }
                        }
                    }
                    
                    if currentState == ._MORNING_HABIT_{
                        mainViewControllerObj?.refreshLastPostponeCount()
                        
                        if currentHabitPlaying != nil{
                            closePupUpBlockIfVisible()
                        }
                        
                    }else if currentState == ._EVENING_HABIT_{
                        mainViewControllerObj?.refreshLastPostponeCount()
                        
                        if currentHabitPlaying != nil{
                            closePupUpBlockIfVisible()
                        }
                    }else if currentState == ._ACTIVITY_{
                        
                        
                        var lastSavedPostponeTime = Date()
                        activityPostponeCount = 0
                        var lastSavedPostponeCount = activityPostponeCount
                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                        
                        if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastBreakActivityPostponeInfo) as? [String:Any]{
                            
                            
                            if let postponeCount =  infoDic["postponeCount"] as? Int{
                                lastSavedPostponeCount = postponeCount
                            }
                            if let date =  infoDic["date"] as? Date{
                                lastSavedPostponeTime = date
                            }
                        }
                        
                        if lastSavedPostponeTime.compare(startDate) == .orderedDescending{
                            activityPostponeCount = lastSavedPostponeCount
                        }
                        
                        
                        
                        if currentActivityPlaying != nil{
                            closePupUpBlockIfVisible()
                        }
                        
                        
                        
                    }
                    mainViewControllerObj?.stopActivityTimer()
                    mainWindowControllerObj?.window?.close()
                    hideBlankWindowInSecondaryMonitor()
                    
                    var duration = 300
                    if eventStartTime != nil && eventEndTime != nil{
                        duration = Calendar.current.dateComponents([.second], from: eventStartTime!, to: eventEndTime!).second ?? 0
                    }
                    if duration < 5{
                        duration = 5
                    }
                    showPopupAppointmentWindow(title: eventTitle, duration: duration)
                }else{
                    if mainViewControllerObj?.breakTimer != nil{
                        mainViewControllerObj?.breakTimer?.invalidate()
                        mainViewControllerObj?.breakTimer = nil
                        mainViewControllerObj?.setActivityTimer()
                    }
                    
                }
                
                
            }
            
            
        }
    }
    var arrAllVideoKindUrls:[String] = ["https://vimeo.com/",
                                        "https://www.dailymotion.com/",
                                        "https://www.twitch.tv/",
                                        "http://www.veoh.com/",
                                        "http://www.metacafe.com/",
                                        "https://www.liveleak.com/",
                                        "https://www.viddler.com/",
                                        "https://9gag.com/tv",
                                        "https://9gag.com",
                                        "https://www.tiktok.com/",
                                        "https://www.bilibili.com/",
                                        "youtube.com"]
    func checkIsAnyVideoWebsiteIsRunning()->Bool{
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps{
            if let appUrl = app.bundleURL{
                let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    var isAllowed = false
                    if let allTabUrls = getBrowserAllTabUrl(browser: browser){
                        for  activeTabUrl in allTabUrls{
                            let domain = getDomainFromUrl(url: activeTabUrl)
                            
                            for turl in arrAllVideoKindUrls{
                                isAllowed = self.validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl, domain: domain)
                                if isAllowed{
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
            
            
            if let lastSubscriptionCheckDate = UserDefaults.standard.object(forKey: kUserdefaultsUserSubscriptionCheckDate) as? Date{
                let currentDate = Date()
                let diffHours = Calendar.current.dateComponents([.hour], from: lastSubscriptionCheckDate, to: currentDate).hour ?? 0
                if diffHours > 24{
                    UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
                    allApiObject.getUserSubscriptionInfo(completionHandler: {dic in
                        if let subscriptionStatus = dic{
                            isPurchased = false
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
                            if oldDaysLeft > 0{// subscription over need to restart
                                if isPurchased == false && daysLeft == 0{
                                    addLog(text: "subscription over:- need to restart app")
                                    DispatchQueue.main.async {
                                        self.quitAndRestartApp()
                                    }
                                    
                                }
                            }
                            
                        }
                    })
                }
            }
            
            
            
            if currentState == ._ABORT_{
                return;
            }
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            let currentDate = Date()
            
            //save progress during an activity (morning and evening) Progress lost when I restarted my computer during an activity#444
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_) && currentAction == ._INPROGRESS_ && timerViewcontrollerObj != nil{
                if timerViewcontrollerObj?.timer?.isValid ?? false{
                    
                    var postPoneTime = currentDate
                    
                    if currentState == ._EVENING_HABIT_{
                        if currentDate > shutOffdate{// iska matlab 20-24 k bich
                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!
                            postPoneTime = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? postPoneTime
                            
                        }
                    }
                    
                    let infoDic:[String:Any] = ["id":lastActivityRunningId, "duration":timerViewcontrollerObj?.currentTimer ?? 0, "date":postPoneTime]
                    UserDefaults.standard.set(infoDic, forKey: kUserdefaultsLastHabitRunningInfo)
                    //                print(infoDic)
                }
                
            }
            //  ////////////////////////////////////////////////////////////////
            
            
            if !shouldDoHabits(){
                return;
            }
            
            if currentState == ._SPECIAL_ACTIVITY_{
                return;
            }
            
            
            /// 5  may 2022 (5 minute warning before shutdown time "It's time to wrap up for the day. Your shutdown time is in 5 minutes.")#62
            if arrAllDaysEveningHabits.count != 0 {
                
                let fiveMinutesBeforeShutOffTime = shutOffdate.addingTimeInterval(-5 * 60)
                let sixtyFiveSecondsBeforeShutOffTime = fiveMinutesBeforeShutOffTime.addingTimeInterval(-5)
                if currentDate.compare(fiveMinutesBeforeShutOffTime) == .orderedAscending  && currentDate.compare(sixtyFiveSecondsBeforeShutOffTime) == .orderedDescending{
                    var shutdownNotificationTitle = "It's time to wrap up for the day. Your shutdown time is in 5 minutes."
                    
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        shutdownNotificationTitle = common.value(forKey: "shutdownNotificationTitle") as? String ?? shutdownNotificationTitle
                    }
                    
                    showNotificationWithMessage(msg: shutdownNotificationTitle)
                    
                }
            }
            //  ////////////////
            
            
            if !self.isSystemSleep && !self.isScreenSaverStart && currentState != ._ACTIVITY_{//same condition in pomodoro view
                unfocusedTime += 5
            }
            
            
            
            if isShutOffTimeGoing(){
                
                if arrAllDaysEveningHabits.count == 0 {// if count is 0 then we will not do anything
                    return;
                }
                
                if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromEveningHabit{// new work  24/12/22
                    return;
                }
                
                if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeEveningHabit{
                    return;
                }
                isBreakActivityExecuteFromMorningHabit = false
                isBreakActivityExecuteFromPostponeMorningHabit = false
                
                if currentState == ._POSTPON_MORNING_HABIT_{//if user postpone again and again
                    currentState = ._NOTHING_
                }
                if currentState == ._POSTPON_FOCUS_SUMMARY_{
                    addLog(text: "Focus Summary is Postponed. Focus Summary Time checking Cancelled.")
                    return;
                }
                
                if currentState == ._POSTPON_EVENING_HABIT_{
                    addLog(text: "Evening Routine is Postponed. Evening Habits Time checking Cancelled.")
                    if cutOffTime != nil{//Postpone should be abandoned at the start of cutoff_for_high_priority_activities/evening_routine#513
                        if !isHighPrioritySequenceGoing{
                            if eveningRoutineLastPostponeTime != nil{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                                
                                let currentDate = Date()
                                if eveningRoutineLastPostponeTime! < cutOffDate && currentDate > cutOffDate{
                                    addLog(text: "Postpone abandoned at the start of cutoff_for_high_priority_activities")
                                    currentState = ._NOTHING_
                                    if mainViewControllerObj != nil{
                                        if mainViewControllerObj?.postponeTimer != nil{
                                            mainViewControllerObj?.postponeTimer?.invalidate()
                                            mainViewControllerObj?.postponeTimer = nil
                                            if mainViewControllerObj?.postponeNotificationTimer != nil{
                                                mainViewControllerObj?.postponeNotificationTimer?.invalidate()
                                                mainViewControllerObj?.postponeNotificationTimer = nil
                                            }
                                            
                                            if smallCountDownWcObj != nil{
                                                if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                                                    smallCountDownVcObj?.closeTimerBox()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
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
                    
                    
                    //Natural break detection not working if the user closes their laptop lid #319
                    var lastEvent:CFTimeInterval = 0
                    lastEvent = CGEventSource.secondsSinceLastEventType(CGEventSourceStateID.hidSystemState, eventType: CGEventType(rawValue: ~0)!)
                    
                    let idleTimeValue = Int(lastEvent)
                    //                print(idleTimeValue)
                    //                    print(self.checkIsAnyVideoWebsiteIsRunning())
                    if currentState != ._MORNING_HABIT_ && currentState != ._ACTIVITY_ && (isHabitAlreadyShowed || currentState == ._POSTPON_MORNING_HABIT_) && arrAllbreakActivities.count != 0 && !self.isUserOnMeeting{
                        if idleTimeValue > 600{// 600 kro
                            if !self.isScreenLocked && !self.isSystemSleep && !self.isScreenSaverStart{
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
                                    if self.checkIsAnyVideoWebsiteIsRunning(){
                                        shouldShowAlert = false
                                    }
                                }
                                if shouldShowAlert{
                                    showNaturalBreakDetectionWindow()
                                }
                            }
                        }
                    }else{
                        if naturalBreaksDetectionWcObj != nil{
                            if naturalBreaksDetectionWcObj?.window?.isVisible ?? false{
                                naturalBreaksDetectionWcObj?.window?.close()
                            }
                        }
                    }
                    //
                    
                    if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromMorningHabit{// new work  24/12/22
                        return;
                    }
                    if currentState == ._ACTIVITY_ && isBreakActivityExecuteFromPostponeMorningHabit{ //  new work - micro break start after postponing morning habit
                        return;
                    }
                    isBreakActivityExecuteFromEveningHabit = false
                    isBreakActivityExecuteFromPostponeEveningHabit = false
                    
                    if currentState != ._MORNING_HABIT_{
                        if currentState == ._POSTPON_EVENING_HABIT_{//if user postpone again and again
                            currentState = ._NOTHING_
                        }
                        
                        if !isHabitAlreadyShowed{
                            if Date().compare(startDate) == .orderedAscending {
                                //                print("First Date is smaller then second date. all ok ")
                                //first date is smaller than second
                            }else{
                                
                                // if alldays array is blank then we do not write date in userdefaults(and checkLastHabitShowDate func will not call so no need to write date  )
                                if arrAllDaysMorningHabits.count == 0 {//  state bhi change krenge na currentState = ._NOTHING_
                                    //                print("arr AllMorningHabits count is 0:-  skip morning habit")
                                    isHabitAlreadyShowed = true
                                    unfocusedTime = 0
                                    if !isMainWindowLodded{
                                        mainWindowControllerObj?.loadWindow()
                                    }else if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                        self.abortAllProcess()
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                        currentState = ._NOTHING_
                                    }
                                    mainViewControllerObj?.setActivityTimer()
                                    return;
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
                                    
                                    if self.isUserOnMeeting{
                                        addLog(text: "isUserOnMeeting True: Morning Habits Time checking Cancelled.")
                                        return
                                    }
                                    arrFilteredMorningHabits.removeAll()
                                    
                                    let currentWeekDay = Date().dayOfWeek()
                                    
                                    for habit in arrAllDaysMorningHabits{
                                        if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                                            arrFilteredMorningHabits.append(habit)
                                        }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                    }
                                    
                                    if arrFilteredMorningHabits.count == 0 {
                                        //                print("arr arrFilteredMorningHabits count is 0:-  skip morning habit")
                                        isHabitAlreadyShowed = true
                                        unfocusedTime = 0
                                        if !isMainWindowLodded{
                                            mainWindowControllerObj?.loadWindow()
                                        }else if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                            self.abortAllProcess()
                                            mainWindowControllerObj?.window?.close()
                                            hideBlankWindowInSecondaryMonitor()
                                            currentState = ._NOTHING_
                                        }
                                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                        mainViewControllerObj?.setActivityTimer()
                                        return;
                                    }
                                    
                                    self.isProcessingHabitRoutine = true//after this line this should be false
                                    
                                    
                                    
                                    addLog(text: "get Last Activity Info")
                                    allApiObject.getLastActivityInfo(completionHandler: { json in
                                        DispatchQueue.main.async {
                                            if json != nil{
                                                //                print(json)
                                                // check is there any change in settings
                                                if let lastSettingsModifiedDateString = json?.value(forKey: "last_time_user_settings_modified") as? String{
                                                    if let lastSettingsModifiedDate = getDateFromStringInUtc(date: lastSettingsModifiedDateString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                                        if applastSettingsGetTime != nil{
                                                            if lastSettingsModifiedDate.compare(applastSettingsGetTime!) == .orderedDescending{//if lastSettingsModifiedDate > applastSettingsGetTime
                                                                addLog(text: "Settings Changed")
                                                                self.abortAllProcess()
                                                                mainWindowControllerObj?.window?.close()
                                                                hideBlankWindowInSecondaryMonitor()
                                                                currentState = ._NOTHING_
                                                                let alert = NSAlert()
                                                                alert.setSharingType()
                                                                var settingsChangedText = "It looks like your settings have been updated. App will restart to take effect."//
                                                                if let common = configjson.value(forKey: "common") as? NSDictionary{
                                                                    settingsChangedText = common.value(forKey: "settingsChangedText") as? String ?? settingsChangedText
                                                                }
                                                                alert.messageText = settingsChangedText
                                                                alert.addButton(withTitle: buttonOkText)
                                                                NSApplication.shared.activate(ignoringOtherApps: true)
                                                                alert.runModal()
                                                                
                                                                self.quitAndRestartApp()
                                                                return;
                                                            }
                                                        }
                                                        
                                                    }
                                                }
                                                // additional check that if user change pc and there is not locally save that morning routine is done today than  check is there morning routine done by user or not
                                                if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                                                    if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                                        if let sequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
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
                                                                            currentState = ._NOTHING_
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
                                                                    
                                                                    
                                                                    
                                                                    if let habitSequenceID = arrFilteredMorningHabits.first?.activity_sequence_id{
                                                                        
                                                                        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                                                                        
                                                                        if activityAssignedDate.compare(startDate) == .orderedDescending{//if activityAssignedDate > startDate
                                                                            // morning activity start hui thi lekin puri nahi hui hai
                                                                            if habitSequenceID == sequenceId{
                                                                                //                print("current_activity_sequence is pending")
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
                                                                                currentState = ._NOTHING_
                                                                                mainWindowControllerObj?.loadWindow()
                                                                                mainViewControllerObj?.setActivityTimer()
                                                                                
                                                                                allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                                                                                    
                                                                                    
                                                                                    DispatchQueue.main.async {
                                                                                        
                                                                                    }
                                                                                })
                                                                                
                                                                            }
                                                                        }
                                                                        else{
                                                                            //                print("pending routin is not from current day clean all running sequence")
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
                                                                addLog(text: "start new morning routine sequence:- current_activity not found as dictionary")// ktyaa krna chahiye yha
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
                                                            for i in 0..<arrFilteredMorningHabits.count{
                                                                if arrFilteredMorningHabits[i].id == lastActivityId{
                                                                    if i == arrFilteredMorningHabits.count - 1{// this case will never happened because we will write morning habit done (kUserdefaultsLastHabitShowDate) locally if all activities done in morning habit
                                                                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                                                                        
                                                                        isHabitAlreadyShowed = true
                                                                        self.isProcessingHabitRoutine = false
                                                                        if mainWindowControllerObj?.window?.isVisible ?? false{//if shutoff or focus summary is showing then
                                                                            self.abortAllProcess()
                                                                            mainWindowControllerObj?.window?.close()
                                                                            hideBlankWindowInSecondaryMonitor()
                                                                        }
                                                                        currentState = ._NOTHING_
                                                                        mainWindowControllerObj?.loadWindow()
                                                                        mainViewControllerObj?.setActivityTimer()
                                                                    }else{
                                                                        addLog(text: "start new morning routine sequence:- Last Habit id is from morning habit, show morning Habit from last habit id found in userdefaults")
                                                                        self.isProcessingHabitRoutine = false
                                                                        self.startHabitsCall(activityId: arrFilteredMorningHabits[i+1].id, skippedActivities:[])
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
                            if arrAllDaysMorningHabits.count != 0 {
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
        
        if currentState == ._EVENING_HABIT_{
            if cutOffTime != nil{
                
                if currentAction == ._INPROGRESS_{
                    let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                    let currentDate = Date()
                    if currentDate > cutOffDate{
                        if !arrFilteredEveningHabits[currentHabitIndex].isPriorityHigh{
                            abortAllProcess()
                            if mainWindowControllerObj?.window?.isVisible ?? false{
                                mainWindowControllerObj?.window?.close()
                                hideBlankWindowInSecondaryMonitor()
                            }
                            let alert = NSAlert()
                            alert.setSharingType()
                            var cutOffTimePassedText = "Running low on time - let's just focus on the high priority habits for the rest of the evening."
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                cutOffTimePassedText = common.value(forKey: "cutOffTimePassedText") as? String ?? cutOffTimePassedText
                            }
                            alert.messageText = cutOffTimePassedText
                            alert.addButton(withTitle: buttonOkText)
                            
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            alert.runModal()
                            //                            currentState = ._NOTHING_
                            isHighPrioritySequenceGoing = true
                            mainWindowControllerObj?.showWindow(self)
                            showBlankWindowInSecondaryMonitor()
                            
                            mainViewControllerObj?.showThirdVc()
                            thirdVcObj?.eveningHabitSkipped()
                        }
                    }
                }
            }
            if currentState == ._EVENING_HABIT_{
                return;
            }
        }else if currentState == ._FOCUS_SUMMARY_{
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
        if isFocusModeOnOrPaused(){
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
        
        if arrAllDaysEveningHabits.count != 0{//} && !iseveningHabitAlreadyShowed {
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
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj!.shutOffMac()
    }
    func showEveningHabit(activityId: String?, skippedActivities:[String]){
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        showBlankWindowInSecondaryMonitor()
        
        isHighPrioritySequenceGoing = false
        if cutOffTime != nil{
            let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
            let currentDate = Date()
            
            if currentDate > cutOffDate{
                
                var isAnyHighPriorityActivityFound = false
                for i in 0..<arrFilteredEveningHabits.count{
                    if arrFilteredEveningHabits[i].isPriorityHigh{
                        isAnyHighPriorityActivityFound = true
                        
                        break;
                        
                    }
                }
                if !isAnyHighPriorityActivityFound{
                    abortAllProcess()
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }

                    let alert = NSAlert()
                    alert.setSharingType()
                    var noHighPriorityActivityText = "No activities with high Priority found"
                    
                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                        noHighPriorityActivityText = common.value(forKey: "noHighPriorityActivityText") as? String ?? noHighPriorityActivityText
                    }
                    
                    alert.messageText = noHighPriorityActivityText
                    alert.addButton(withTitle: buttonOkText)
                    
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    alert.runModal()
                    
                    
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
                    
                    
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                    }
                    showBlankWindowInSecondaryMonitor()
                    mainViewControllerObj!.shutOffMac()
                    return;
                }
                
                
                
                isHighPrioritySequenceGoing = true
            }
        }
        
        
        if activityId == nil{
            mainViewControllerObj!.showAllEveningHabits()
        }else{
            var isActivityFound = false
            for i in 0..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].id == activityId!{
                    isActivityFound = true
                    if i == 0{
                        mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false)
                    }else{
                        if skippedActivities.count == 0{
                            habitTotalCompletedSeconds = 0
                            for j in 0..<i{
                                if arrFilteredEveningHabits[j].useTimer{
                                    if isHighPrioritySequenceGoing{
                                        if arrFilteredEveningHabits[j].isPriorityHigh{
                                            habitTotalCompletedSeconds += arrFilteredEveningHabits[j].durationSeconds!
                                        }
                                    }else{
                                        habitTotalCompletedSeconds += arrFilteredEveningHabits[j].durationSeconds!
                                    }
                                }
                            }
                            if i-1 >= 0{
                                UserDefaults.standard.set(arrFilteredEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                            }
                            
                            mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false)
                        }else{
                            var isLastActivitySkipped = false
                            if let lastActivityId = arrFilteredEveningHabits[i-1].id{
                                
                                if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                    isLastActivitySkipped = true
                                }
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    let habit = arrFilteredEveningHabits[j]
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                        //skiped
                                    }else{
                                        if habit.useTimer{
                                            if isHighPrioritySequenceGoing{
                                                if habit.isPriorityHigh{
                                                    habitTotalCompletedSeconds += habit.durationSeconds!
                                                }
                                            }else{
                                                habitTotalCompletedSeconds += habit.durationSeconds!
                                            }
                                            //completed
                                        }
                                    }
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrFilteredEveningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
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
        
        arrFilteredEveningHabits.removeAll()
        
        let currentWeekDay = Date().dayOfWeek()
        
        for habit in arrAllDaysEveningHabits{
            if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                arrFilteredEveningHabits.append(habit)
            }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                arrFilteredEveningHabits.append(habit)
            }
        }
        
        if arrFilteredEveningHabits.count == 0{
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
            addLog(text: "evening habit already Done for today")
            return;
        }
        
        isHighPrioritySequenceGoing = false
        if !self.isProcessingHabitRoutine{
            self.isProcessingHabitRoutine = true
            let shutoffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            addLog(text: "get Last Activity Info process Evening Habit")
            allApiObject.getLastActivityInfo(completionHandler: { json in
                DispatchQueue.main.async {
                    if json != nil{
                        //                print(json)
                        
                        // check is there any change in settings
                        if let lastSettingsModifiedDateString = json?.value(forKey: "last_time_user_settings_modified") as? String{
                            if let lastSettingsModifiedDate = getDateFromStringInUtc(date: lastSettingsModifiedDateString, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'") {
                                if applastSettingsGetTime != nil{
                                    if lastSettingsModifiedDate.compare(applastSettingsGetTime!) == .orderedDescending{//if lastSettingsModifiedDate > applastSettingsGetTime
                                        addLog(text: "Settings Changed")
                                        self.abortAllProcess()
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                        currentState = ._NOTHING_
                                        let alert = NSAlert()
                                        alert.setSharingType()
                                        var settingsChangedText = "It looks like your settings have been updated. App will restart to take effect."//
                                        if let common = configjson.value(forKey: "common") as? NSDictionary{
                                            settingsChangedText = common.value(forKey: "settingsChangedText") as? String ?? settingsChangedText
                                        }
                                        alert.messageText = settingsChangedText
                                        alert.addButton(withTitle: buttonOkText)
                                        NSApplication.shared.activate(ignoringOtherApps: true)
                                        alert.runModal()
            
                                        self.quitAndRestartApp()
                                        print("settings changed")
                                        return;
                                    }
                                }
                                
                            }
                        }
                        
                        // additional check that if user change pc and there is not locally save that evening routine is done today than  check is there morning routine done by user or not
                        if let lastCompletedSequence = json?.value(forKey: "last_completed_sequence") as? NSDictionary{
                            if let lastCompletedSequenceId = lastCompletedSequence.value(forKey: "id") as? String{
                                if let sequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
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
                                            if let habitSequenceID = arrFilteredEveningHabits.first?.activity_sequence_id{
                                                
                                                
                                                if activityAssignedDate.compare(shutoffDate) == .orderedDescending && habitSequenceID == sequenceId{//if activityAssignedDate > shutoffDate
                                                    // evening activity start hui thi lekin puri nahi hui hai
                                                    
                                                    if habitSequenceID == sequenceId{
                                                        //                print("current evening routine sequence is pending")
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
                                                    //                print("processEveningHabit - pending  routine is not from current day clean all running sequence or pending sequence is not evening routine - \(sequenceId)")
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
                                    for i in 0..<arrFilteredEveningHabits.count{
                                        if arrFilteredEveningHabits[i].id == lastActivityId{
                                            addLog(text: "start new evening routine sequence:- Last Habit id is from evening habit, show eveningHabit from last habit id found in userdefaults")
                                            self.isProcessingHabitRoutine = false
                                            self.showEveningHabit(activityId: arrFilteredEveningHabits[i+1].id, skippedActivities:[])
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
            if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._SPECIAL_ACTIVITY_{
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        enableSystemSleep()
                        if timerViewcontrollerObj?.isVideoLodded ?? false{
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
                        
                        if toolBoxWcObj != nil{
                            if toolBoxWcObj!.window!.isVisible{
                                toolBoxWcObj?.window?.close()
                            }
                        }
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
                                if timerViewcontrollerObj?.isVideoLodded ?? false{
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
                                if toolBoxWcObj != nil{
                                    if toolBoxWcObj!.window!.isVisible{
                                        toolBoxWcObj?.window?.close()
                                    }
                                }
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
        if arrFilteredMorningHabits.count != 0 {
            
            checkSystemTimeAndShowWindow()
            
            self.abortAllProcess()
            if activityId == nil{
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                mainViewControllerObj!.showAllMorningHabits()
            }else{
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                var isActivityFound = false
                for i in 0..<arrFilteredMorningHabits.count{
                    if arrFilteredMorningHabits[i].id == activityId!{
                        isActivityFound = true
                        if i == 0{
                            mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                        }else {
                            if skippedActivities.count == 0{
                                habitTotalCompletedSeconds = 0
                                for j in 0..<i{
                                    if arrFilteredMorningHabits[j].useTimer{
                                        habitTotalCompletedSeconds += arrFilteredMorningHabits[j].durationSeconds!
                                    }
                                }
                                if i-1 >= 0{
                                    UserDefaults.standard.set(arrFilteredMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
                                }
                                
                                
                                mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: i, isLastActivitySkipped:false)
                            }else{
                                var isLastActivitySkipped = false
                                if let lastActivityId = arrFilteredMorningHabits[i-1].id{
                                    if skippedActivities.contains(where: { $0.caseInsensitiveCompare(lastActivityId.lowercased()) == .orderedSame }) {
                                        isLastActivitySkipped = true
                                    }
                                    habitTotalCompletedSeconds = 0
                                    for j in 0..<i{
                                        let habit = arrFilteredMorningHabits[j]
                                        if skippedActivities.contains(where: { $0.caseInsensitiveCompare(habit.id.lowercased()) == .orderedSame }) {
                                            //skiped
                                        }else{
                                            if habit.useTimer{
                                                habitTotalCompletedSeconds += habit.durationSeconds!
                                            }
                                            //completed
                                        }
                                        
                                    }
                                    if i-1 >= 0{
                                        UserDefaults.standard.set(arrFilteredMorningHabits[i-1].id, forKey: kUserdefaultsLastHabitID)
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
                
            }
        }
    }
    
    func checkSystemTimeAndShowWindow(){
        addLog(text: "func checkSystemTimeAndShowWindow")
        if let now = client.referenceTime?.now(){
            //                print(now)
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
                    tabview.selectedTabViewItemIndex = 3//account
                }else{
                    tabview.selectedTabViewItemIndex = 0
                }
                
                if SettingsManagerObject.isPasswordRequireInChangeSettings{
                    tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                    tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                    getEnterPasswordVcObjForPreferences().parentVc = nil
                    addLog(text: "Showing enter password view")
                }
            }
        }else{
            if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    tabview.selectedTabViewItemIndex = 3
                }
            }else{
                if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                    tabview.selectedTabViewItemIndex = 0
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
            
            if mainWindowControllerObj?.window?.isVisible ?? false{
                mainViewControllerObj?.btnAbortClicked(self)
            }else{
                showQuitWindow()
            }
            
            return .terminateCancel
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        //        if appdelegate!.statusbutton?.action == #selector(appdelegate!.topIconClickd){
        //            topIconClickd()
        //        }
        print("applicationShouldHandleReopen")
        return true
    }
    
    // did this beacuse we user closes last window than app should  deactivate beacuse we need to show popover if user clicks on dock icon and if app is allready active we cant get actual state of dock icon click that's why we are doing this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed")
        addLog(text: "applicationShouldTerminateAfterLastWindowClosed")
        if popover.isShown{
            return false
        }
        if NSApp.isActive{
            addLog(text: "hide app")
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
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_) && !(mainWindowControllerObj?.window?.isVisible ?? false){
                if currentHabitPlaying != nil || currentActivityPlaying != nil{// it means background activity
                    if smallCountDownWcObj != nil{
                        if smallCountDownWcObj?.window?.alphaValue == 0{
                            if popUpBlockConfirmWcObj != nil{
                                if !(popUpBlockConfirmWcObj?.window?.isVisible ?? false){//Countdown timer pops up after allowing app/website #455
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
        addLog(text: "applicationDidBecomeActive")
        print("applicationDidBecomeActive")
    }
    func applicationDidResignActive(_ notification: Notification) {
        print("applicationDidResignActive")
        addLog(text: "applicationDidResignActive")
        //        if self.alertAppAutoRestart.window.isVisible{
        //            self.alertAppAutoRestart.window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
        //        }
        for window in NSApp.windows{
            if window.isModalPanel{
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
            }
        }
    }
    
    @objc func topIconClickd(){
        addLog(text: "top Icon Clickd")
        if self.user == nil{
            addLog(text: "self.user = nil")
            if  UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if mainWindowControllerObj != nil {
                    if mainWindowControllerObj!.window?.isVisible ?? false{
                        return;
                    }
                }
                if welcomeOnboardingWcObj != nil{
                    welcomeOnboardingWcObj!.showWindow(nil)
                    if appdelegate!.onboardingTimer != nil{
                        appdelegate!.onboardingTimer?.invalidate()
                        appdelegate!.onboardingTimer = nil
                    }
                }
                
                
                return
            }else{
                if mainWindowControllerObj != nil {
                    if mainWindowControllerObj!.window?.isVisible ?? false{
                        return;
                    }
                }
                if welcomeOnboardingWcObj != nil{
                    welcomeOnboardingWcObj!.showWindow(nil)
                    if appdelegate!.onboardingTimer != nil{
                        appdelegate!.onboardingTimer?.invalidate()
                        appdelegate!.onboardingTimer = nil
                    }
                }
            }
        }else{
            ///addLog(text: "show activation Window")
            // activationWindowControllerObj?.showWindow(self)
            // NSApplication.shared.activate(ignoringOtherApps: true)
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
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
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
            RunLoop.main.add((timerForFocusMode!), forMode: RunLoop.Mode.common)
            
            if focusModeSecondsToPerform > 120{
                timerForFocusModeEndNotification = Timer.scheduledTimer(timeInterval: TimeInterval(focusModeSecondsToPerform - 120), target: self, selector: #selector(self.showFocusModeFinishNotification), userInfo: nil, repeats: false)
                RunLoop.main.add((timerForFocusModeEndNotification!), forMode: RunLoop.Mode.common)
            }
            
        }
    }
    
    func focusModeAborted(){
        addLog(text: "focus mode Aborted")
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0
        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        if isFocusModeOn(){// is is paused then already calculated
            let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
            focusModeActualDurationPerformed += totalSeconds
        }
        
        var currentFocusModeId = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                arrFocusType[i]["isPaused"] = false
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
            //                print("invalidtate")
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
    
    @objc func showFocusModeFinishNotification(){
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        if isFocusModeOn(){
            //            var msg = "Focus mode ends in"
            //            if let common = configjson.value(forKey: "common") as? NSDictionary{
            //                msg = common.value(forKey: "focusEndsText") as? String ?? msg
            //            }
            //
            //            showSmallTimerWindow(durationSeconds: 120, msg: msg, isFocusBreak: true, currentTimerValue: 0)
            if breakWarningWcObj != nil{
                if breakWarningWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            
            if smallCountDownWcObj != nil{
                if smallCountDownWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            
            
            showFocusEndWarningWindow()
            
        }
    }
    
    
    @objc func focusModeTimerFinished(){
        focusModeFinished(isSilent: false)
    }
    
    @objc func focusModeFinished(isSilent:Bool){
        addLog(text: "focus mode finished")
        
        isSkipBreakActivityDuringFocus = false
        lastFocusModeTempInfo = nil
        unfocusedTime = 0
        
        playFocusPomodorBreakEndsSound()
        endFocusModeTime = nil
        //                print("focus mode finished")
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            timerForFocusMode = nil
        }
        if timerForFocusModeEndNotification != nil{
            timerForFocusModeEndNotification?.invalidate()
            timerForFocusModeEndNotification = nil
        }
        if isFocusModeOn(){// is is paused then already calculated
            let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
            focusModeActualDurationPerformed += totalSeconds
        }
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
            if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                arrFocusType[i]["isPaused"] = false
                currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
                currentFocusModeId = arrFocusType[i]["id"] as? String ?? ""
                workAfterFocusBegin(index: i)
                break;
            }
        }
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
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
            //                print("invalidtate")
        }
        timerCheckAllowedApps?.invalidate()
        DispatchQueue.main.async {
            
            arrKeywordsToAllowInFocus.removeAll()
            
            if !self.isAutoMeetingsModeStarted && !isSilent{
                allApiObject.getKeyWords(completionHandler: {dic  in
                    
                    arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
                })
            }else{
                arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
            }
            
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
                if arrAllowedAppsInCuddlyModeCurrentFocus.count != 0 || arrAllowedUrlsInCuddlyModeCurrentFocus.count != 0{
                    lastFocusModeTempInfo = lastFocusTempInfo(id: currentFocusModeId, arrAllowedAppsInCuddlyModeCurrentFocus: arrAllowedAppsInCuddlyModeCurrentFocus, arrAllowedUrlsInCuddlyModeCurrentFocus: arrAllowedUrlsInCuddlyModeCurrentFocus)
                }else{
                    lastFocusModeTempInfo = nil
                }
                
                DispatchQueue.main.async {
                    self.showFocusCompletedView()
                    focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date())
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.global().async {
                        DispatchQueue.main.async {
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
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
        var focusModeDoneCount = UserDefaults.standard.object(forKey: kUserdefaultsFocusModeDoneCount) as? Int ?? 0
        focusModeDoneCount += 1
        UserDefaults.standard.set(focusModeDoneCount, forKey: kUserdefaultsFocusModeDoneCount)
        
        focusModeActualDurationPerformed = 0
        unfocusedTime = 0
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastFocusModeDoneDate)
        playFocusModeStartedSound()
        if getSmallCountDownWindowObject().window?.isVisible ?? false{
            getsmallCountDownVcObject().closeTimerBox()
        }
        
        if addFocusTempUrlsOrAppsWcObj != nil{
            if addFocusTempUrlsOrAppsWcObj?.window?.isVisible ?? false{
                addFocusTempUrlsOrAppsWcObj?.window?.close()
            }
        }
        lastFocusModeTempInfo = nil
        
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
        
        arrKeywordsToAllowInFocus.removeAll()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()
        
        
        fireFoxNotificationShownForCurrentFocusMode = false
    }
    
    
    var timerAllowUrl:Timer?
    var timerCheckAllowedApps:Timer?
    var timerAllowUrlForActivity:Timer?
    var timerAllowAppForActivity:Timer?
    var timerBlockUrl:Timer?//block urls list
    
    @objc func frontApplicationChanged(){
        //        if let runningApp = NSWorkspace.shared.frontmostApplication{
        //            print(runningApp.localizedName)//ScreenSaverEngine
        //        }
        timerBlockUrl?.invalidate()
        timerAllowUrlForActivity?.invalidate()
        
        
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
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
                                    if currentRunningFocusType["isDefault"] as? Bool == true {
                                        isAppAllowed = true
                                        let blocked_apps = currentRunningFocusType["blocked_apps"] as? [String] ?? []
                                        for path in blocked_apps{
                                            let url = URL(fileURLWithPath: path)
                                            if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                                isAppAllowed = false
                                                break;
                                            }
                                        }
                                        
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
                            if currentRunningFocusType["isDefault"] as? Bool == true {
                                isAppAllowed = true
                                let blocked_apps = currentRunningFocusType["blocked_apps"] as? [String] ?? []
                                for path in blocked_apps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                        isAppAllowed = false
                                        break;
                                    }
                                }
                                
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
                            //                print("invalidtate")
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
                            //                print("validtate")
                            self.timerAllowUrl?.invalidate()
                            if self.timerAllowUrl != nil{
                                if self.timerAllowUrl!.isValid{
                                    //                print("************************************* timer is not invalid")
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
            if isAppEnable{//Deactivate should stop always blocked URLs#663
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    //                print(runningApp.localizedName)
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
    }
    
    func showFocusAppBlockNotification(appName:String){
        addLog(text: "show Focus App Block Notification called")
        if arrNotificationShownForApps.contains(appName){
            addLog(text: "func showFocusAppBlockNotification:- Notification already shown:- return")
            return;
        }
        let arrAppsAvoidNotification = ["loginwindow", "screensaverengine"]//lowercased
        
        if arrAppsAvoidNotification.contains(appName.lowercased()){
            addLog(text: "func showFocusAppBlockNotification:- AppsAvoidNotification contain app:- return")
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
        addLog(text: "func showFocusAppBlockNotification:- show notification for app:- \(appName)")
        msg = msg.replacingOccurrences(of: "<APP_NAME>", with: appName)
        msg = msg.replacingOccurrences(of: "<FOCUS_NAME>", with: focusMode)
        showNotificationWithMessage(msg: msg)
    }
    func checkIsCurrentTabAllowed(currentBrowser:BROWSER)->Bool{
        if !SettingsManagerObject.isTabLimiterEnabled{
            return true
        }
        
        if let browserStruct = getBrowserAllWindowStruct(browser: currentBrowser){
            if currentBrowser == ._SAFARI_{
                if safariWindowsInfo.keys.count == 0{
                    safariWindowsInfo = browserStruct
                }else{
                    var allBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            allBrowserTabsArr += tabsArr
                        }
                    }
                    keys = safariWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = safariWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == allBrowserTabsArr.count{
                        safariWindowsInfo = browserStruct
                    }else if allBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if allBrowserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = safariWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            safariWindowsInfo[key] = browserTabsArr
                                        }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                            
                                            for i in 0..<browserTabsArr.count{
                                                if i < selfTabArr.count{
                                                    if browserTabsArr[i] != selfTabArr[i]{
                                                        closeTabAt(index: i, browser: currentBrowser)
                                                        break;
                                                    }
                                                }else{
                                                    closeTabAt(index: i, browser: currentBrowser)
                                                    break;
                                                }
                                            }
                                            showAlertMaxTabLimitWindow()
                                            return false
                                            
                                        }
                                    }else{//new window created
                                        closeTabAt(index: 0, browser: currentBrowser)
                                        showAlertMaxTabLimitWindow()
                                        return false
                                    }
                                }
                            }
                            
                            
                        }else{
                            safariWindowsInfo = browserStruct
                        }
                    }else{
                        safariWindowsInfo = browserStruct
                    }
                }
                //                if safariWindowsInfo.keys.count != browserStruct.keys.count{ // it means window count is not same
                //                    safariWindowsInfo = browserStruct
                //                }else if browserStruct.keys.count != 0{
                //                    let keys = browserStruct.keys
                //                    for key in keys{
                //                        if let browserTabsArr = browserStruct[key]{
                //                            if let selfTabArr = safariWindowsInfo[key]{
                //                                if selfTabArr.count == browserTabsArr.count{
                //                                    safariWindowsInfo[key] = browserTabsArr
                //                                }else if browserTabsArr.count > selfTabArr.count{// new tab created
                //                                    if browserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                //                                        for i in 0..<browserTabsArr.count{
                //                                            if i < selfTabArr.count{
                //                                                if browserTabsArr[i] != selfTabArr[i]{
                //                                                    closeTabAt(index: i, browser: currentBrowser)
                //                                                    break;
                //                                                }
                //                                            }else{
                //                                                closeTabAt(index: i, browser: currentBrowser)
                //                                                break;
                //                                            }
                //                                        }
                //                                        showAlertMaxTabLimitWindow()
                //                                        return false
                //                                    }else{
                //                                        safariWindowsInfo[key] = browserTabsArr
                //                                    }
                //                                }
                //                            }
                //                        }
                //                    }
                //                }
            }else if currentBrowser == ._GOOGLE_CHROME_{
                if googleChromeWindowsInfo.keys.count == 0{
                    googleChromeWindowsInfo = browserStruct
                }else{
                    var allBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            allBrowserTabsArr += tabsArr
                        }
                    }
                    keys = googleChromeWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = googleChromeWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == allBrowserTabsArr.count{
                        googleChromeWindowsInfo = browserStruct
                    }else if allBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if allBrowserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = googleChromeWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            googleChromeWindowsInfo[key] = browserTabsArr
                                        }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                            
                                            for i in 0..<browserTabsArr.count{
                                                if i < selfTabArr.count{
                                                    if browserTabsArr[i] != selfTabArr[i]{
                                                        closeTabAt(index: i, browser: currentBrowser)
                                                        break;
                                                    }
                                                }else{
                                                    closeTabAt(index: i, browser: currentBrowser)
                                                    break;
                                                }
                                            }
                                            showAlertMaxTabLimitWindow()
                                            return false
                                            
                                        }
                                    }else{//new window created
                                        closeTabAt(index: 0, browser: currentBrowser)
                                        showAlertMaxTabLimitWindow()
                                        return false
                                    }
                                }
                            }
                            
                            
                        }else{
                            googleChromeWindowsInfo = browserStruct
                        }
                    }else{
                        googleChromeWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._BRAVE_BROWSER_{
                if braveBrowserWindowsInfo.keys.count == 0{
                    braveBrowserWindowsInfo = browserStruct
                }else{
                    var allBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            allBrowserTabsArr += tabsArr
                        }
                    }
                    keys = braveBrowserWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = braveBrowserWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == allBrowserTabsArr.count{
                        braveBrowserWindowsInfo = browserStruct
                    }else if allBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if allBrowserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = braveBrowserWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            braveBrowserWindowsInfo[key] = browserTabsArr
                                        }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                            
                                            for i in 0..<browserTabsArr.count{
                                                if i < selfTabArr.count{
                                                    if browserTabsArr[i] != selfTabArr[i]{
                                                        closeTabAt(index: i, browser: currentBrowser)
                                                        break;
                                                    }
                                                }else{
                                                    closeTabAt(index: i, browser: currentBrowser)
                                                    break;
                                                }
                                            }
                                            showAlertMaxTabLimitWindow()
                                            return false
                                            
                                        }
                                    }else{//new window created
                                        closeTabAt(index: 0, browser: currentBrowser)
                                        showAlertMaxTabLimitWindow()
                                        return false
                                    }
                                }
                            }
                            
                            
                        }else{
                            braveBrowserWindowsInfo = browserStruct
                        }
                    }else{
                        braveBrowserWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._SIDEKICK_{
                if sidekickWindowsInfo.keys.count == 0{
                    sidekickWindowsInfo = browserStruct
                }else{
                    var allBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            allBrowserTabsArr += tabsArr
                        }
                    }
                    keys = sidekickWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = sidekickWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == allBrowserTabsArr.count{
                        sidekickWindowsInfo = browserStruct
                    }else if allBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if allBrowserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = sidekickWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            sidekickWindowsInfo[key] = browserTabsArr
                                        }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                            
                                            for i in 0..<browserTabsArr.count{
                                                if i < selfTabArr.count{
                                                    if browserTabsArr[i] != selfTabArr[i]{
                                                        closeTabAt(index: i, browser: currentBrowser)
                                                        break;
                                                    }
                                                }else{
                                                    closeTabAt(index: i, browser: currentBrowser)
                                                    break;
                                                }
                                            }
                                            showAlertMaxTabLimitWindow()
                                            return false
                                            
                                        }
                                    }else{//new window created
                                        closeTabAt(index: 0, browser: currentBrowser)
                                        showAlertMaxTabLimitWindow()
                                        return false
                                    }
                                }
                            }
                            
                            
                        }else{
                            sidekickWindowsInfo = browserStruct
                        }
                    }else{
                        sidekickWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._MICROSOFT_EDGE_{
                if microsoftEdgeWindowsInfo.keys.count == 0{
                    microsoftEdgeWindowsInfo = browserStruct
                }else{
                    var allBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            allBrowserTabsArr += tabsArr
                        }
                    }
                    keys = microsoftEdgeWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = microsoftEdgeWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == allBrowserTabsArr.count{
                        microsoftEdgeWindowsInfo = browserStruct
                    }else if allBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if allBrowserTabsArr.count > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = microsoftEdgeWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            microsoftEdgeWindowsInfo[key] = browserTabsArr
                                        }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                            
                                            for i in 0..<browserTabsArr.count{
                                                if i < selfTabArr.count{
                                                    if browserTabsArr[i] != selfTabArr[i]{
                                                        closeTabAt(index: i, browser: currentBrowser)
                                                        break;
                                                    }
                                                }else{
                                                    closeTabAt(index: i, browser: currentBrowser)
                                                    break;
                                                }
                                            }
                                            showAlertMaxTabLimitWindow()
                                            return false
                                            
                                        }
                                    }else{//new window created
                                        closeTabAt(index: 0, browser: currentBrowser)
                                        showAlertMaxTabLimitWindow()
                                        return false
                                    }
                                }
                            }
                            
                            
                        }else{
                            microsoftEdgeWindowsInfo = browserStruct
                        }
                    }else{
                        microsoftEdgeWindowsInfo = browserStruct
                    }
                }
            }
        }
        //        return true;
        //        if let count = getBrowserAllTabsCount(browser: currentBrowser){
        //            if currentBrowser == ._SAFARI_{
        //                if safariAllTabCount == -1{
        //                    safariAllTabCount = count
        //                }else if count > safariAllTabCount{
        //                    if count > SettingsManagerObject.maxTabLimitCount{
        //                        closeSafariLastTab()
        //                        showAlertMaxTabLimitWindow()
        //                        return false
        //                    }else{
        //                        safariAllTabCount = count
        //                    }
        //                }else{
        //                    safariAllTabCount = count
        //                }
        //
        //            }else if currentBrowser == ._GOOGLE_CHROME_{
        //                if googleChromeAllTabCount == -1{
        //                    googleChromeAllTabCount = count
        //                }else if count > googleChromeAllTabCount{
        //                    if count > SettingsManagerObject.maxTabLimitCount{
        //                        closeOtherBrowsersLastTab(browser: currentBrowser)
        //                        showAlertMaxTabLimitWindow()
        //                        return false
        //                    }else{
        //                        googleChromeAllTabCount = count
        //                    }
        //                }else{
        //                    googleChromeAllTabCount = count
        //                }
        //            }else if currentBrowser == ._BRAVE_BROWSER_{
        //                if braveBrowserAllTabCount == -1{
        //                    braveBrowserAllTabCount = count
        //                }else if count > braveBrowserAllTabCount{
        //                    if count > SettingsManagerObject.maxTabLimitCount{
        //                        closeOtherBrowsersLastTab(browser: currentBrowser)
        //                        showAlertMaxTabLimitWindow()
        //                        return false
        //                    }else{
        //                        braveBrowserAllTabCount = count
        //                    }
        //                }
        //            }else if currentBrowser == ._SIDEKICK_{
        //                if sidekickAllTabCount == -1{
        //                    sidekickAllTabCount = count
        //                }else if count > sidekickAllTabCount{
        //                    if count > SettingsManagerObject.maxTabLimitCount{
        //                        closeOtherBrowsersLastTab(browser: currentBrowser)
        //                        showAlertMaxTabLimitWindow()
        //                        return false
        //                    }else{
        //                        sidekickAllTabCount = count
        //                    }
        //                }else{
        //                    sidekickAllTabCount = count
        //                }
        //            }else if currentBrowser == ._MICROSOFT_EDGE_{
        //                if microsoftEdgeAllTabCount == -1{
        //                    microsoftEdgeAllTabCount = count
        //                }else if count > microsoftEdgeAllTabCount{
        //                    if count > SettingsManagerObject.maxTabLimitCount{
        //                        closeOtherBrowsersLastTab(browser: currentBrowser)
        //                        showAlertMaxTabLimitWindow()
        //                        return false
        //                    }else{
        //                        microsoftEdgeAllTabCount = count
        //                    }
        //                }else{
        //                    microsoftEdgeAllTabCount = count
        //                }
        //            }
        //        }
        return true
    }
    
    @objc func blockUrlsInBackground(){
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if UserDefaults.standard.object(forKey: kUserdefaultsControllingBrowserVcShown) == nil{
                    return;
                }
            }
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
                }else if currentBrowser == ._MICROSOFT_EDGE_{
                    defaultPageOfBrowser = "edge://newtab"
                }else{
                    defaultPageOfBrowser = "chrome:"
                }
                
                if !checkIsCurrentTabAllowed(currentBrowser: currentBrowser){
                    return;
                }
                if var url = getActiveTabUrlOf(browser: currentBrowser){
                    //                print(url)
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
                                
                            case ._MICROSOFT_EDGE_:
                                script =
                                """
                                tell application "Microsoft Edge"
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
        //        print("******************checkFcousAllowedApp*********************")
        if isShowTimerInFocusEnabled{
            self.setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
        }
        let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
        if isAllowedAllAppsInFocus{
            return;
        }
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                //                print(name)
                var isAppAllowed = false
                var isSelfApp = false
                if name == selfAppName.lowercased(){
                    isSelfApp = true
                    isAppAllowed = true
                }else if focusDefaultAllowApps.contains(name){//if name == "finder" || name == "universalaccessauthwarn"{
                    isAppAllowed = true
                }else{
                    
                    if currentRunningFocusType["isDefault"] as? Bool == true {
                        isAppAllowed = true
                        let blocked_apps = currentRunningFocusType["blocked_apps"] as? [String] ?? []
                        for path in blocked_apps{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                isAppAllowed = false
                                break;
                            }
                        }
                        
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
                        //                print("invalidtate22")
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
                showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil, tabTitle: nil)
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
    
    
    func focusTryToBlockUnwantedUrl(script: String, url:String, browser: BROWSER?, tabTitle:String?){
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
                focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil)
            }else{
                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle)
            }
        }else{
            focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil)
        }
        
    }
    
    func focusBlockUnwantedUrl(script: String, url:String, lastBlockReasonFromAi:String?){
        var newScript = script
        
        if lastBlockReasonFromAi != nil{
            newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "&reason=\(lastBlockReasonFromAi!)")
        }else{
            newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "")
        }
        
        
        if let appleScript = NSAppleScript(source: newScript) {
            
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
                addLog(text:"set activity timer from morning/evening activity allowed app")
                if !(mainViewControllerObj?.isBreakActivityPostponeInsideAllowedHabit ?? false){
                    mainViewControllerObj?.setActivityTimer()
                }else{
                    addLog(text:"set activity timer from morning/evening activity allowed app:- break activity postpone, do not reset activity timer")
                }
            }
            
            
            if isAnyAllowedFocusModeActivityRunning{
                
                if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomatically) as? Bool == false{
                    var shouldShowToolBoxWindow = false
                    
                    let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    
                    if !isAllowedAllAppsInFocus && allowAppsPath.count != 0{
                        shouldShowToolBoxWindow = true
                    }
                    let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
                    let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
                    
                    if arrAllowedUrlsForFocus.count != 0 && isAllowedListApproachInFocus{//!isAllowedAllUrlsInFocus &&#453
                        shouldShowToolBoxWindow = true
                    }
                    if shouldShowToolBoxWindow{
                        showToolboxWindow()
                    }
                }
            }else{//
                if UserDefaults.standard.object(forKey: kUserdefaultsDontShowToolBoxAutomaticallyForActivity) as? Bool == false{
                    var shouldShowToolBoxWindow = false
                    let allowAppsPath = currentHabitPlaying?.allowApps ?? []
                    
                    if allowAppsPath.count != 0{
                        shouldShowToolBoxWindow = true
                    }
                    
                    let arrAllowedUrlsForFocus = currentHabitPlaying?.allowUrls ?? []
                    
                    if arrAllowedUrlsForFocus.count != 0{
                        shouldShowToolBoxWindow = true
                    }
                    if shouldShowToolBoxWindow{
                        showToolboxWindow()
                    }
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
            var isSpecialHabitGoing = false
            var isSpecialActivityGoing = false
            
            if currentState == ._SPECIAL_ACTIVITY_{
                if timerViewcontrollerObj?.lastCurrentSpecialHabit != nil{
                    isSpecialHabitGoing = true
                }else{
                    isSpecialActivityGoing = true
                }
            }
            
            if currentState == ._ACTIVITY_ || isSpecialActivityGoing{
                showPopUpCheckListWindow(title: currentActivityPlaying?.name ?? "", list: currentActivityPlaying?.checkList ?? [])
                if let apps = currentActivityPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
                        
                        
                    }
                }else{
                    
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
                        
                    }
                }
            }else if currentState == ._EVENING_HABIT_ || currentState == ._MORNING_HABIT_ || isSpecialHabitGoing{
                showPopUpCheckListWindow(title: currentHabitPlaying?.name ?? "", list: currentHabitPlaying?.checkList ?? [])
                if let apps = currentHabitPlaying?.allowApps{
                    if apps.count != 0{
                        if let app = apps.first{
                            NSWorkspace.shared.launchApplication(app)
                        }
                    }else{
                        
                    }
                }else{
                    
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
                        
                    }
                }
                
            }
        }
        
    }
    
    @objc func checkActivityAllowedApp(){
        addLog(text:"check Activity Allowed App")
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    //                print(name)
                    
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
                            if currentRunningFocusType["isDefault"] as? Bool == true {
                                isAppAllowed = true
                                let blocked_apps = currentRunningFocusType["blocked_apps"] as? [String] ?? []
                                for path in blocked_apps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                        isAppAllowed = false
                                        break;
                                    }
                                }
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
        
        
        else{
            if self.timerAllowAppForActivity != nil{
                self.timerAllowAppForActivity!.invalidate()
            }
        }
    }
    //    var arrAllowedUrlsForFocus = [""]
    //    var arrBlockedUrlsForFocus = [""]
    var defaultAllowedUrl = ["focus-block.html",
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
                    //                print("invalidtate")
                }
                return;
            }
            //                print("checkInBackground")
            
            
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
                    var needToBlockImmediately = false
                    
                    var currentBrowser:BROWSER!
                    let nameLowercased = name.lowercased()
                    var tabTitle: String?
                    
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
                    }else if currentBrowser == ._MICROSOFT_EDGE_{
                        defaultPageOfBrowser = "edge://newtab"
                    }else{
                        defaultPageOfBrowser = "chrome:"
                    }
                    if !self.checkIsCurrentTabAllowed(currentBrowser: currentBrowser){
                        return;
                    }
                    
                    if var url = getActiveTabUrlOf(browser: currentBrowser){
                        //                print(url)
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
                                    
                                    if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                                        if !arrAllowedTabTitlesInCuddlyModeCurrentFocus.contains(title){
                                            arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
                                        }
                                    }
                                    
                                    
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                                
                                if url.contains("focus_bear_temporarily_allow=true"){
                                    arrAllowedUrlsInCuddlyModeCurrentFocus.append(domain)
                                    for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                        if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(domain){
                                            arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                            break;
                                        }
                                    }
                                    
                                    return;
                                }
                            }
                            if isAllowedListApproachInFocus{
                                for turl in arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if isBlocked{
                                        needToBlockImmediately = true
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
                                            tabTitle = title
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
                                        needToBlockImmediately = true
                                        break;
                                    }
                                }
                                //                                }
                            }
                            
                            if !isAllowed{
                                if isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                    var bool = false
                                    for turl in SettingsManagerObject.arrBlockedUrls{
                                        bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if bool{
                                            self.blockUrlsInBackground()
                                            return;
                                        }
                                    }
                                }
                                //  //
                                
                                tabUrl = domain
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                var cuddly_bear_modeString = ""
                                var aiReasonToBlockString = ""
                                if SettingsManagerObject.isCuddlyModeEnabled{
                                    cuddly_bear_modeString = "&cuddly_bear_mode=true"
                                    aiReasonToBlockString = "<AIREASON>"
                                }
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._GOOGLE_CHROME_:
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._BRAVE_BROWSER_:
                                    script =
                                    """
                                    tell application "Brave Browser"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._SIDEKICK_:
                                    script =
                                    """
                                    tell application "Sidekick"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._MICROSOFT_EDGE_:
                                    script =
                                    """
                                    tell application "Microsoft Edge"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case .none:
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                                
                            }else{
                                if !isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                    var bool = false
                                    for turl in SettingsManagerObject.arrBlockedUrls{
                                        bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                        if bool{
                                            self.blockUrlsInBackground()
                                        }
                                    }
                                }
                                //  //
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
                    if needToBlockImmediately{
                        self.focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil)
                    }else{
                        self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle)
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
                    var tabUrl = ""
                    var needToBlockImmediately = false
                    var currentBrowser:BROWSER!
                    let nameLowercased = name.lowercased()
                    var tabTitle:String?
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        currentBrowser = browser
                    }else{
                        self.timerAllowUrl?.invalidate()
                        return;
                    }
                    var defaultPageOfBrowser = ""
                    if currentBrowser == ._SAFARI_{
                        defaultPageOfBrowser = "favorites:"
                    }else if currentBrowser == ._MICROSOFT_EDGE_{
                        defaultPageOfBrowser = "edge://newtab"
                    }else{
                        defaultPageOfBrowser = "chrome:"
                    }
                    if !self.checkIsCurrentTabAllowed(currentBrowser: currentBrowser){
                        return;
                    }
                    
                    if var url = getActiveTabUrlOf(browser: currentBrowser){
                        //                print(url)
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
                            
                            
                            if SettingsManagerObject.isCuddlyModeEnabled && isAnyAllowedFocusModeActivityRunning{// no need additional check
                                if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(domain){
                                    self.closePopupBlockWindowIfRunningForUrl()
                                    return;
                                }
                            }
                            
                            if url.contains("focus_bear_temporarily_allow=true"){
                                arrAllowedUrlsInCuddlyModeCurrentFocus.append(domain)
                                for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                    if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(domain){
                                        arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                        break;
                                    }
                                }
                                
                                return;
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
                            }else if currentState == ._SPECIAL_ACTIVITY_{
                                if currentHabitPlaying != nil{
                                    activityAllowUrls = currentHabitPlaying!.allowUrls
                                }
                                blockType = "special-activity"
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
                                            needToBlockImmediately = true
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
                                                tabTitle = title
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
                                            needToBlockImmediately = true
                                            break;
                                        }
                                    }
                                    //                                    }
                                }
                                if !isAllowed{
                                    if isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                        var bool = false
                                        for turl in SettingsManagerObject.arrBlockedUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                self.blockUrlsInBackground()
                                                return;
                                            }
                                        }
                                    }
                                }else{
                                    if !isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                        var bool = false
                                        for turl in SettingsManagerObject.arrBlockedUrls{
                                            bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                            if bool{
                                                self.blockUrlsInBackground()
                                            }
                                        }
                                    }
                                    //                                    return// no need to return here
                                }
                            }
                            
                            
                            if !isAllowed{
                                
                                tabUrl = domain
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                var cuddly_bear_modeString = ""
                                var aiReasonToBlockString = ""
                                if SettingsManagerObject.isCuddlyModeEnabled && isAnyAllowedFocusModeActivityRunning{
                                    cuddly_bear_modeString = "&cuddly_bear_mode=true"
                                    aiReasonToBlockString = "<AIREASON>"
                                }
                                
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script =
                                    """
                                    tell application "Safari"
                                    set the_wnd to front window
                                    set active_tab to current tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._GOOGLE_CHROME_:
                                    script =
                                    """
                                    tell application "Google Chrome"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._BRAVE_BROWSER_:
                                    script =
                                    """
                                    tell application "Brave Browser"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._SIDEKICK_:
                                    script =
                                    """
                                    tell application "Sidekick"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
                                    end tell
                                    """
                                    
                                case ._MICROSOFT_EDGE_:
                                    script =
                                    """
                                    tell application "Microsoft Edge"
                                    set the_wnd to front window
                                    set active_tab to active tab in the_wnd
                                    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)"
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
                        if needToBlockImmediately{
                            self.focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil)
                        }else{
                            self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle)
                        }
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
        if !checkIsFullScreenEnabled(){
            return;
        }
        if isMainWindowLodded{
            if (mainWindowControllerObj?.window!.isVisible)!{
                let screenList = NSScreen.screens
                for screen in screenList {  // create the corresponding windows
                    //                     resetWin(BGWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen))
                    mainWindowControllerObj!.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
                    break;
                }
                for i in 0..<arrWindows.count{
                    let window = arrWindows[i]
                    window.orderOut(nil)
                    arrWindows[i].windowController?.window=nil
                }
                arrWindows.removeAll()
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
    @IBAction func menuItemUninstallClicked(_ sender: Any) {
        if askLogInWcObj?.window != nil{
            if askLogInWcObj?.window?.isVisible ?? false{
                addLog(text: "menu Item Uninstall Clicked")//
                if uninstallingConfirmVcObj == nil{
                    uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
                }
                askLogInWcObj?.contentViewController?.presentAsSheet(uninstallingConfirmVcObj!)
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


//11/1/22
// blank scrren in second monitor bug solved
// onboarding url add screen



// focus music screen done
// evening habit time save correction done
// break activity 0 case handled 
// -+ icon done

//

// easy postpone cancel vala kaam 
// internet vala kaam done
// crazy blocking bug





// reallow url
// meeting detectionnew settings
// focus music k time per badi window aay to focus music roko
// onboarding add remove button sahi kro 
// api se check krna hi h na ki seeting blank h to block url vali scre aaygi
// width same onboarding card ki


// let no more


//meeting detection ka alert ni aayga jab tk user khjud set na kro default falase for popoup
// complete anarcy vale mai focus mode mai agar allow aal url selected hai to always blocked url vala kaam hoga or  complete anarcy ka special popupa lert focus mode or pomodoro se pahle nahi aayga


// Tell user what break activities are coming up#479 done

//  auto resume focus  music
//  reallow url in activity with focus mode
// focus time ramianing
// setup
// xut off date work



// delete all preferences window from main storyboard


//    /.. default focus mode activities mai select hoga kya  ok done work 



//tooltip lagali

// ui set krli

//delete duplicate ka action reset ho gya


// nai key jo aai h agar focus duplicate ho to vo key hatani h toi ask sir ki default focus ki duplicate kre user to keise mangae hoga // hatao duplicate icon bhi

// remove delete button from default focus types

//tab reset to pahle  hi ho gye the lekin tab k check jha jha lage hue h use review krne hai done
// account tab uninstall tab jo ander vale tabview mai aa gye h sirf vo hi select kr skta h user if account is expired  done

// default focus mode mai advance per click krne per blocked urls ki list  na aay


// focus mode mode start hote hi break activity ka timer reset ho jay //


//todo always check releas notes in updae build xml
// skip break vali setting focus mai //
// break warning aate hifocus mode end waring hat jaygi
//or jab bhi focus mode end warning dikhaynge check krneg break warning visible hogi to nahi dikhaynhge
//ys badi screen lagi hui ho to bhi ni dikhaynge
//small window dikh rahi h to focus end waring ni dikhaynge or jese hi small window aaaygi focus end warning hat jaygi
// editable mode when new created, do not need any default value , remove - button, add ka button chota




// onboarding event tracking 
// brain dump mai text na ho to auto window ni show hogi 




// other ko others
//  startup or shutoff time naya vala save kro
// Explain why: “Create an account to sync your habit + block settings across all your devices.”


// onboarding progress

//meeting focus mode keisehatega
// special character add kiye ha password rules amai
//  open tool box ka menu enable
//allApiObject.capturePosthog(event: "visualize-morning-routine", metadata: ["routine-type":"morning_routine"])
/*
 welcome aboard shown/
 set onboarding blocked urls
 privacy and security shown
 permissions to block distraction shown
 distraction shield activated shown
 button blocked clicked
 button didnt blocked clicked
 // browsers screen
 button still not working clicked
 button correct browser clicked
 
 button onboarding Habit Start View shown
 lets do it clciked
 no thanks clicked
 */
//*






//todo always add new search items in earch
//todo always seet new height if new item added in preferences
// config file update
// browser vala kro


// lateno more pkg

//done
//morning grapg mai question
// log quantity changes -  min max value, current value change

// checklist empty showing bug
//ai not thanks white color gackground
// add focus mode 250 character limit crash solved

// solve kro api call kro  getfocus mode template ki api  call ni ho rhi thi solved
// added tab limiter in search
//ak bhi question na ho to
// browsers all window tab work done


// revice quntity check
// "Max tab count (10) exceeded." text
// log quantity constraints

// subscription url done
// blur bug done

//help k tab ko bda kro     done
// blur window big bug ?  solved need to check by user

// after activity done close checklist box




//count down timers in quittingConfirmVc
// allow breaks in call with setting 


// 29/5/23
// break actiivty while postponinng evening habir
// log quanity cursor bug
// evening routine done text



// uninstall if not logged in
// do not do any this if app is diabled and some one fire app from let no more
// log file delete na ho to
//
//sare info icon k hover per hi ttoltip dikh jay
// segment control  hand cursor

//tab vala kaam
// background clor vala kaam
// sab per tool tip set ki








//done 15/6/23
// minuts vala kaam
// preferences window resize done

//gray text ko black kiys
//Deactivate should stop always blocked URLs#663
//you need to pass additional key-value pair for stats page
//{access_token:<token>, type:<platform>}  where platform can be either win or mac//
// kala color text


//16/6/23
// webview msg vala kaam done 


// deactivate mai postpone mai password
// new font add vala kaam 



//20/6/23
//password vala kaam
//pomodoro mode vala kaam
//popup block confirm vala bug thi solver 
// focus mode finish screen whem allow focus mode activity finished

