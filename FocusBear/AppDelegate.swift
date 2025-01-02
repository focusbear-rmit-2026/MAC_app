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
import CoreMedia

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, SUUpdaterDelegate, NSPopoverDelegate {
    let validation = urlValidation()
    
    let sharedDefaults = UserDefaults(suiteName: "TCUD568B3U.group.com.focusbear.fbmac")
    @IBOutlet weak var menuItemUninstall: NSMenuItem!
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var statusbutton:NSStatusBarButton?
    var updater: SUUpdater?
    let client = TrueTimeClient.sharedInstance
    let popover = NSPopover()
    var terminateFromSelf = false
    var hotKeyClearUserdefaults: HotKey? {
        didSet {
            guard let hotKey = hotKeyClearUserdefaults else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
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
                self?.macWakeupResumeFocusModeIfRunning()
            }
        }
    }
    
    
    
    
    var timerCheckReactivateTime:Timer?
    var timerCheckClearPasswordTime:Timer?
    var timerBackgroundThread:Timer?
    
    var timerExtraNagsAfterInactivity:Timer?
    
//    var timerExtraNagsAfterTrialExpired:Timer?
    
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
                    if focusAlignmentScoreCsvURL != nil{
                        do{
                            try FileManager.default.removeItem(at: focusAlignmentScoreCsvURL!)
                        }catch{
                            
                        }
                    }
                    
                    
                    if arrNonTimerBasedHabitsDurationsPlistFileUrl != nil{
                        do{
                            try FileManager.default.removeItem(at: arrNonTimerBasedHabitsDurationsPlistFileUrl!)
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
                if focusAlignmentScoreCsvURL != nil{
                    do{
                        try FileManager.default.removeItem(at: focusAlignmentScoreCsvURL!)
                    }catch{
                        
                    }
                }
                
                if arrNonTimerBasedHabitsDurationsPlistFileUrl != nil{
                    do{
                        try FileManager.default.removeItem(at: arrNonTimerBasedHabitsDurationsPlistFileUrl!)
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
    var user: AuthUser?
    let credentialsManager = CredentialsManager(authentication: Auth0.authentication())

    func logout() {
        addLog(text: "logout")
        self.user = nil
        let _ = self.credentialsManager.clear()
        self.credential = nil
        UserDefaults.standard.removeObject(forKey: kUserdefaultsIsUserLoggedIn)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastHabitShowDate)
        shell(launchPath: "/bin/launchctl", arguments: ["unload","-w","\("/Users/")\(NSUserName())\("/Library/LaunchAgents/\(mainAppBundelId).plist")"])
        UserDefaults.standard.removeObject(forKey: kUserdefaultsLastBreaksStartTime)
        UserDefaults.standard.removeObject(forKey: kUserdefaultsArrayBreaksDurations)
        quitAndRestartApp()
    }
    let alertAppAutoRestart = NSAlert()
    var lastOpenUrlString = ""
    
    open func application(_ application: NSApplication, open urls: [URL]) {
        addLog(text: "func:- open urls")
        if let url = urls.first{
            let urlString = url.absoluteString
            lastOpenUrlString = urlString
            addLog(text: "func:- open url \(urlString)")
            if isSettingsLoddedInAppdelegate{
                filterUrl(url: lastOpenUrlString)
            }
        }
        
        if updater != nil{// it means application is already started
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
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        //doing this because if app is started after quit by user then  helper app will know that main app is restarted
        sharedDefaults?.removeObject(forKey: kUserdefaultsDontShowNudgeView)
        sharedDefaults?.removeObject(forKey: kUserdefaultsAppQuitForUser)
        sharedDefaults?.removeObject(forKey: kUserdefaultsStartHabitNagCount)
        sharedDefaults?.removeObject(forKey: kUserdefaultsLastNagShowDate)
        sharedDefaults?.removeObject(forKey: kUserdefaultsOnboardingIncompleted)
        sharedDefaults?.synchronize()
        //--------------------------------------------------------//
        
        checkAndGetGlobalUUID()
        
        if let fontPath = Bundle.main.path(forResource: "OpenDyslexic3-Regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }
        
        if let fontPath = Bundle.main.path(forResource: "intelone-mono-font-family-regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }
        
        if let fontPath = Bundle.main.path(forResource: "Poppins-Regular", ofType: "ttf") {
            let fontPathUrl = URL(fileURLWithPath: fontPath)
            var errorRef: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(fontPathUrl as CFURL, .process, &errorRef)
            print(errorRef)
        }
        
        let fontFamilies = NSFontManager.shared.availableFontFamilies.sorted()
        for family in fontFamilies {
            print(family)
            let familyFonts = NSFontManager.shared.availableMembers(ofFontFamily: family)
            if let fonts = familyFonts {
                for font in fonts {
                    print("\t\(font)")
                }
            }
        }
        
        
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
        arrNonTimerBasedHabitsDurationsPlistFileUrl = applicationSupportURL!.appendingPathComponent("nonTimerBasedHabitsDurations.plist")
        focusAlignmentScoreCsvURL = applicationSupportURL!.appendingPathComponent("focusAlignmentScore.csv")
        offlineActivitiesCsvURL = applicationSupportURL!.appendingPathComponent("offlineActivities.csv")
        trackFilesFolderURL = applicationSupportURL!.appendingPathComponent("Tracks")
//        habitInfoFileURL = applicationSupportURL!.appendingPathComponent("Habit_Info.txt")
        settingForScreeenTimeFileURL = applicationSupportURL!.appendingPathComponent("fbtt.plist")
        CreateDirectoryIfNotExist(path: trackFilesFolderURL!.path)
      
//        let outString = ""
//        do {
//            try outString.write(to: habitInfoFileURL!, atomically: true, encoding: .utf8)
//        } catch {
//            print(error)
//        }
        if FileManager.default.fileExists(atPath: "/Users/\(NSUserName())/Desktop/is_fb_test_user.txt"){
            isTestUser = true
        }
        
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
        
        // ----------------SET APP INSTALL DATE---------------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) == nil{
            UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
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
            
            boxForStatusBar = customStatusBarBox(frame: self.statusbutton!.frame)
            boxForStatusBar.boxType = .custom
            boxForStatusBar.borderWidth = 0
            boxForStatusBar.cornerRadius = statusBarBoxHeightWidth/2
            boxForStatusBar.fillColor = NSColor.clear
            statusbutton?.addSubview(boxForStatusBar)
//            statusbutton?.addConstraints(subView: boxForStatusBar)
            
            
            
            boxForStatusBar.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: statusBarBoxHeightWidth)
            let heightConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: statusBarBoxHeightWidth)
            let centerYConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .centerY, relatedBy: .equal, toItem: statusbutton!, attribute: .centerY, multiplier: 1, constant: 0)
            let centerXConstraint = NSLayoutConstraint(item: boxForStatusBar!, attribute: .centerX, relatedBy: .equal, toItem: statusbutton!, attribute: .centerX, multiplier: 1, constant: 0)
            
            statusbutton!.addConstraints([widthConstraint, heightConstraint, centerYConstraint, centerXConstraint])
            
            boxForStatusBarForTooltip = customStatusBarBoxForTooltip(frame: self.statusbutton!.frame)
            boxForStatusBarForTooltip.boxType = .custom
            boxForStatusBarForTooltip.borderWidth = 0
            boxForStatusBarForTooltip.cornerRadius = statusBarBoxHeightWidth/2
            boxForStatusBarForTooltip.fillColor = NSColor.clear
            statusbutton?.addSubview(boxForStatusBarForTooltip)
            
            
            
            boxForStatusBarForTooltip.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: statusBarBoxHeightWidth)
            let heightConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: statusBarBoxHeightWidth)
            let centerYConstraintForTooltip = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .centerY, relatedBy: .equal, toItem: statusbutton!, attribute: .centerY, multiplier: 1, constant: 0)
            let leadingConstraint = NSLayoutConstraint(item: boxForStatusBarForTooltip!, attribute: .leading, relatedBy: .equal, toItem: statusbutton!, attribute: .leading, multiplier: 1, constant: leadingStatusBarBox)
            
            statusbutton!.addConstraints([widthConstraintForTooltip, heightConstraintForTooltip, centerYConstraintForTooltip, leadingConstraint])
            
            
            
            
            let customBox = NSBox()
            customBox.boxType = .custom
            customBox.borderWidth = 0
            customBox.fillColor = NSColor.clear
            statusbutton?.addSubview(customBox)
            statusbutton?.addConstraints(subView: customBox)
            
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
                self.sharedDefaults?.setValue(languageCode, forKeyPath: kUserdefaultsSharedSelectedLanguage)
                self.sharedDefaults?.synchronize()
            } else {
                UserDefaults.standard.set(languageCode, forKey: kUserdefaultsSelectedLanguage)
                self.sharedDefaults?.setValue(languageCode, forKeyPath: kUserdefaultsSharedSelectedLanguage)
                self.sharedDefaults?.synchronize()
            }
        }
        
        
        writeSettingForScreeenTime(habitInfo: "")
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
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)//this is correct, needs to block uls even if user is not logged in
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
                createLaunchAgentForHelperApp()// for nudge work
                
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
                            showWelcomeWindow()
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
    
    func showAskOccupation(){
        currentState = ._ASK_APP_WORK_
        mainWindowControllerObj?.showWindow(self)
        showBlankWindowInSecondaryMonitor()
        mainViewControllerObj!.showAskOccupationVc()
    }
    func showOnbardingHabit(){
        addLog(text: "func:- showOnbardingHabit")
        
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
            self.user = AuthUser(from: self.credential!.accessToken)
        }
    }
    
    
    func loadCredentialsAndDeviceId(){
        addLog(text: "load Credentials And DeviceId")
        
        
        credentialsManager.credentials { [self] credentialsInfo in
            
            setCredentialAndUserInfo(credentialsInfo: credentialsInfo, isAppLaunching: true)
            
            if self.credential == nil{ //  it means failed to get cradential and popup offline or error msg is visible
                return;
            }
            if self.credential != nil{
                print(self.credential!.accessToken)
                sharedDefaults?.setValue(self.user?.userId ?? "", forKeyPath: kUserdefaultsSharedUserId)
                sharedDefaults?.setValue(self.credential!.accessToken, forKeyPath: kUserdefaultsSharedAccessToken)
                sharedDefaults?.setValue(appVersion, forKeyPath: kUserdefaultsSharedAppVersion)

               
                
                sharedDefaults?.synchronize()
                DispatchQueue.main.async {
                    kUserdefaultsVideoShown = kUserdefaultsVideoShown + (self.user?.userId ?? "")
                    if UserDefaults.standard.object(forKey: kUserdefaultsVideoShown) == nil{
            //            Use Focus Mode templates for onboarding#489
                        var shouldShowOnboardingAfterLogin = true
                        allApiObject.getUserLocalDeviceSettings(completionHandler: { json in
                            if json != nil{
                                if let settings = json?.value(forKey: "MacOS") as? NSDictionary {//
                                    print(settings)
                                    if settings.allKeys.count == 0{
                                        shouldShowOnboardingAfterLogin = true
                                    }else{
                                        shouldShowOnboardingAfterLogin = false
                                    }
                                    
                                }
                            }
                            DispatchQueue.main.async {
                                if shouldShowOnboardingAfterLogin{
                                    
                                    allApiObject.postTermsService(consentType: "terms_of_service")
                                    allApiObject.postTermsService(consentType: "privacy_policy")
                                    allApiObject.postCourse()
                                    allApiObject.autoEenrolledCourse()
                                    
                                    self.showAskOccupation()
                                    
                                }else{
                                    UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
                                    self.getUserSubscriptionInfo()
                                }
                            }
                        }
                        )
                        
                    }else{
                        self.getUserSubscriptionInfo()
                    }
                    
                    
                    
                    
                    
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
    
    
    func getUserSubscriptionInfo(){
        if UserDefaults.standard.object(forKey: kUserDefaultsFirstAppFullLoadDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserDefaultsFirstAppFullLoadDate)
        }
        allApiObject.getUserSubscriptionInfo(completionHandler: {dic,statusCode  in
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
            var subscriptionStatus: [String : Any]?
            if let subscriptionStatusDic = dic as? [String:Any]{
                subscriptionStatus = subscriptionStatusDic
            }else if let subscriptionStatusDic = self.user?.subscriptionStatus{
                subscriptionStatus = subscriptionStatusDic
                if statusCode != nil{
                    if statusCode == 404{
                        DispatchQueue.main.async {
                            self.logout()
                        }
                        return;
                    }
                }
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
                if isPurchased == false && daysLeft == 0{
                    isExpired = true
                }
            }
            self.sharedDefaults?.setValue(isPurchased, forKeyPath: kUserdefaultsSharedIsPurchased)
            self.sharedDefaults?.synchronize()
            
            
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
                kUserdefaultsTagsColumnAddedInStatsCsv = kUserdefaultsTagsColumnAddedInStatsCsv + (self.user?.userId ?? "")
                kUserdefaultsEditBlockedUrlsOnce = kUserdefaultsEditBlockedUrlsOnce + (self.user?.userId ?? "")
                kUserdefaultsLastFocusSavedIntention = kUserdefaultsLastFocusSavedIntention + (self.user?.userId ?? "")
                
                kUserdefaultsAllFocusModesTags = kUserdefaultsAllFocusModesTags + (self.user?.userId ?? "")
                kUserdefaultsFocusModeNotes = kUserdefaultsFocusModeNotes + (self.user?.userId ?? "")
                kUserdefaultsFocusTipsShown = kUserdefaultsFocusTipsShown + (self.user?.userId ?? "")
                kUserdefaultsImpactMeasurementShown = kUserdefaultsImpactMeasurementShown + (self.user?.userId ?? "")
                kUserdefaultsSurveyShown = kUserdefaultsSurveyShown + (self.user?.userId ?? "")
                kUserdefaultsTotalTimeSpentOnDistractingSites = kUserdefaultsTotalTimeSpentOnDistractingSites + (self.user?.userId ?? "")
                kUserdefaultsTotalDistractingSitesBlocked = kUserdefaultsTotalDistractingSitesBlocked + (self.user?.userId ?? "")
                kUserdefaultsSimplePomodoroAiBlockingSelected = kUserdefaultsSimplePomodoroAiBlockingSelected + (self.user?.userId ?? "")
                kUserdefaultsDisableBreaksForToday = kUserdefaultsDisableBreaksForToday + (self.user?.userId ?? "")
                kUserdefaultsLastFocusModeStrictness = kUserdefaultsLastFocusModeStrictness + (self.user?.userId ?? "")
                kUserdefaultsDontShowConfirmGeekModeAlert = kUserdefaultsDontShowConfirmGeekModeAlert + (self.user?.userId ?? "")
                kUserDefaultsOpenTodoPlayerFirstTime = kUserDefaultsOpenTodoPlayerFirstTime + (self.user?.userId ?? "")
                kUserDefaultsHideAppModeOption = kUserDefaultsHideAppModeOption + (self.user?.userId ?? "")
                kUserdefaultsMicroBreaksDoneCount = kUserdefaultsMicroBreaksDoneCount + (self.user?.userId ?? "")
                
                kUserdefaultsBeginMorningHabitClickedDate = kUserdefaultsBeginMorningHabitClickedDate + (self.user?.userId ?? "")
                kUserdefaultsBeginEveningHabitClickedDate = kUserdefaultsBeginEveningHabitClickedDate + (self.user?.userId ?? "")
                
                kUserDefaultsCustomGoals = kUserDefaultsCustomGoals + (self.user?.userId ?? "")
                kUserDefaultsBlockPageTourShowed = kUserDefaultsBlockPageTourShowed + (self.user?.userId ?? "")
                kUserDefaultsHowHeardAboutApp = kUserDefaultsHowHeardAboutApp + (self.user?.userId ?? "")
                kUserDefaultsLastQuitReason = kUserDefaultsLastQuitReason + (self.user?.userId ?? "")
                kUserDefaultsSelectedOccupationForPosthog = kUserDefaultsSelectedOccupationForPosthog + (self.user?.userId ?? "")
                kUserDefaultsCareFactorHabitsForPosthog = kUserDefaultsCareFactorHabitsForPosthog + (self.user?.userId ?? "")
                
                kUserdefaultsManageTaskFirstTime = kUserdefaultsManageTaskFirstTime + (self.user?.userId ?? "")
                connectGlobalAndMacIDWithDistinctUserID()
                
                if let notes = UserDefaults.standard.object(forKey: "kUserdefaultsFocusModeNotes") as? String{// get notes from old key and remove it from old key
                    UserDefaults.standard.set(notes, forKey: kUserdefaultsFocusModeNotes)
                    UserDefaults.standard.removeObject(forKey: "kUserdefaultsFocusModeNotes")
                }
                
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
                    arrNonTimerBasedHabitsDurationsPlistFileUrl = self.currentUserURL!.appendingPathComponent("nonTimerBasedHabitsDurations.plist")
                    focusAlignmentScoreCsvURL = self.currentUserURL!.appendingPathComponent("focusAlignmentScore.csv")
                    offlineActivitiesCsvURL = self.currentUserURL!.appendingPathComponent("offlineActivities.csv")
                    newLocalSettingsFileURL = self.currentUserURL!.appendingPathComponent("localSettings.plist")
                }
                nonTimerBasedHabitsObject.readNonTimerBasedHabitsDurations()
                if let id  = UserDefaults.standard.object(forKey: kUserdefaultsDeviceId) as? String{
                    currentDeviceId = id
                    addLog(text: "load Credentials And DeviceId - got old id")
                    self.loadAppAndSettings()
                    self.sharedDefaults?.setValue(id, forKeyPath: kUserdefaultsSharedCurrentDeviceId)
                    self.sharedDefaults?.synchronize()
                    
                }else{
                    addLog(text: "load Credentials And DeviceId - getDeviceId")
                    allApiObject.getDeviceId(completionHandler: {id in
                        addLog(text: "load Credentials And DeviceId - got id")
                        if id != nil{
                            DispatchQueue.main.async {
                                UserDefaults.standard.set(id!, forKey: kUserdefaultsDeviceId)//e935f08a-5571-4cc3-b514-e0bea9739fd7
                                currentDeviceId = id!
                                self.loadAppAndSettings()
                                self.sharedDefaults?.setValue(id, forKeyPath: kUserdefaultsSharedCurrentDeviceId)
                                self.sharedDefaults?.synchronize()
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
                            }
                        }
                        
                    }
                    )
                    
                }
            }
            
            
        })
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
            UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
        }else if UserDefaults.standard.object(forKey: kUserdefaultsTagsColumnAddedInStatsCsv) == nil{
            
            addTagsEntryInStatsCsv()
            UserDefaults.standard.set(true, forKey: kUserdefaultsTagsColumnAddedInStatsCsv)
        }
        
        
        if !fileManager.fileExists(atPath: focusAlignmentScoreCsvURL.path){
            let csvString = "Timestamp,Url,TabTitle,FocusMode,Intention,AiReason,Probability,TotalScore\n"

            do {
                try csvString.write(to: focusAlignmentScoreCsvURL, atomically: true, encoding: .utf8)
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
        
        //  ------------------------------------------------------------------------------------
        
        SettingsManagerObject.getUserLocalDeviceSettings(completionHandler: {
            
            DispatchQueue.main.async {

                if !SettingsManagerObject.startPomodoroShortcutFlags.isEmpty || !SettingsManagerObject.startPomodoroShortcutChar.isEmpty{
                    char = ""
                    flags = NSEvent.modifierFlags
                    
                    char = SettingsManagerObject.startPomodoroShortcutChar
                    
                    let sflags = SettingsManagerObject.startPomodoroShortcutFlags
                    updateFlags(sflags: sflags)
                    
                    
                    if flags.isEmpty == false || char != "" {
                        self.registerPomodoroShortcut()
                    }
                }
                if SettingsManagerObject.shouldReloadAfterForceQuitEnabled{
                    createLaunchAgent()
                }else{
                    deleteLaunchAgent()
                }
                
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
                        self.sharedDefaults?.setValue(currentUserEmail, forKeyPath: kUserdefaultsSharedUserEmail)
                        self.sharedDefaults?.setValue(currentUserName, forKeyPath: kUserdefaultsSharedUserName)
                        self.sharedDefaults?.synchronize()
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
                                    }else if key == "tags"{
                                        if let arrTags = focusDic["tags"] as? [NSDictionary]{
                                            var arrtags = [String]()
                                            for tagInfo in arrTags{
                                                arrtags.append(tagInfo["text"] as? String ?? "")
                                            }
                                            newDic["tags"] = arrtags
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
                    var isRelaxFocusContain = false
                    
                    var isDeepWorkFocusContain = false
                    
                    
                    if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String:Any]]{
                        arrFocusType = arr
                        
                        for i in 0..<arrFocusType.count{
                            arrFocusType[i]["isOn"] = false
                            arrFocusType[i]["isPaused"] = false
                            if let isDefault = arrFocusType[i]["isDefault"] as? Bool{//this key will only be awailable in default focus type
                                if  isDefault{
                                    isDefaultContain = isDefault
                                    defaultContainLocation = i//break nahi krna yha loop ko (qki isOn false bi ho rha h har index mai)
                                }
                            }
                            if let isMeetings = arrFocusType[i]["isMeetings"] as? Bool{//this key will only be awailable in default focus type
                                if  isMeetings{
                                    isMeetingsContain = isMeetings
                                }
                            }
                            if let isLockedFocus = arrFocusType[i]["isLockedFocus"] as? Bool{//this key will only be awailable in default focus type
                                if  isLockedFocus{
                                    islockedFocusContain = isLockedFocus
                                }
                            }
                            if let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool{//this key will only be awailable in default focus type
                                if  isRelaxFocus{
                                    isRelaxFocusContain = isRelaxFocus
                                }
                            }
                            if let isDeepWorkFocus = arrFocusType[i]["isDeepWorkFocus"] as? Bool{//this key will only be awailable in default focus type
                                if  isDeepWorkFocus{
                                    isDeepWorkFocusContain = isDeepWorkFocus
                                }
                            }
                            
                        }
                        
                    }
                    // finish focus mode if already running
                    finishOldFocusModeIfRunning(startNewFocusId: nil, intention: "", start_time: nil, finish_time: nil)
                    //
                    
                    if !isDefaultContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Block super distracting sites/apps", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "blocked_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isDefault":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]//#453//tags
                        //, "isBlockedAllUrls":false , "isAllowedAllUrls":true
                        arrFocusType.insert(dic, at: 0)
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic)
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
                            var focusMode = arrFocusType[defaultContainLocation]
                            if focusMode["isAllowedAllApps"] as? Bool == true{
                                focusMode["isAllowedAllApps"] = false
                                focusMode["blocked_apps"] = []
                                focusMode["allowed_apps"] = []
                                focusMode["isAllowedListApproach"] = false
                                focusMode["allowed_urls"] = []
                                focusMode["blockUrlsArray"] = []
                                
                                allApiObject.editFocusMode(focusType: focusMode, completionHandler: {newDic in
                                    DispatchQueue.main.async {
                                        print("*************************api called*****************")
                                        
                                    }
                                })
                            }
                            arrFocusType.remove(at: defaultContainLocation)
                            arrFocusType.insert(focusMode, at: 0)
                            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        }
                        
                    }// if any new default focus mode created then count should be changed in kUserdefaultsFocusTipsShown
                    if !isMeetingsContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Meetings", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": ["/Applications/Microsoft Teams.app", "/Applications/Microsoft Teams classic.app", "/Applications/zoom.us.app", "/Applications/Jitsi.app", "/Applications/Safari.app", "/Applications/Google Chrome.app", "/Applications/Firefox.app", "/Applications/Slack.app", "/Applications/Sidekick.app", "/Applications/Brave Browser.app"], "allowed_urls": ["http://meet.google.com", "http://meet.zoho.com", "focusmate.com", "shimmer.care", "webex.com", "gotomeeting.com", "goto.com/meeting",  "skype.com", "adobeconnect", "join.me", "joinme.com", "slack.com", "whereby.com", "chime.aws", "aws.amazon.com/chime/", "dialpad.com"], "isOn": false, "isAllowedAllApps":false, "isMeetings":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]//#453 , "isBlockedAllUrls":false , "isAllowedAllUrls":false
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.insert(dic, at: arrFocusType.count - 1)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic)
                    }
                    if !islockedFocusContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Locked Focus on current activity", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":false, "isLockedFocus":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]//#453 , "isAllowedAllUrls":false , "isBlockedAllUrls":false
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.append(dic)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic)
                        
                    }
                    
                    if !isRelaxFocusContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Free time - block nothing", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": [], "isOn": false, "isAllowedAllApps":true, "isRelaxFocus":true, "isAllowedListApproach":false, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.insert(dic, at: arrFocusType.count - 1)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic)
                    }
                    
                    
                    if !isDeepWorkFocusContain{
                        let id = getUuid()
                        let dic:[String:Any] = ["id":id, "name":"Deep Work", "color": getColorString(color: NSColor(red: 163/255, green: 255/255, blue: 161/255, alpha: 1)), "allowed_apps": [], "allowed_urls": ["google.com"], "isOn": false, "isAllowedAllApps":true, "isDeepWorkFocus":true, "isAllowedListApproach":true, "blockUrlsArray": [], "tags":[], "focusAlignmentScoreThreshold": defaultFocusAlignmentScoreToShowDistractingPopUp]
                        
                        if arrFocusType.count == 0{
                            arrFocusType.append(dic)
                        }else{
                            arrFocusType.insert(dic, at: arrFocusType.count - 1)
                        }
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        allApiObject.addFocusMode(focusType: dic)
                    }
                    
                    
                    for i in 0..<arrFocusType.count{
                        if arrFocusType[i]["isAllowedListApproach"] == nil{
                            arrFocusType[i]["isAllowedListApproach"] = true
                        }
                    }
                    
                    // locked in current focus should not be visible in focus prefrences thats why removing it and adding it at the end so that we will not show last item in list//486 - Remove Locked Focus
                    for i in 0..<arrFocusType.count{
                        if let isLockedFocus = arrFocusType[i]["isLockedFocus"] as? Bool{
                            if  isLockedFocus{
                                if i != arrFocusType.count - 1{
                                    let focusMode = arrFocusType[i]
                                    arrFocusType.remove(at: i)
                                    arrFocusType.append(focusMode)
                                }
                                break;
                            }
                        }
                        
                    }
                    sortFocusModes()
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    
                    
                    arrFocusTypeForPomodoro.removeAll()
                    for i in 0..<arrFocusType.count{
                        if !(arrFocusType[i]["isMeetings"] as? Bool ?? false == true){
                            arrFocusTypeForPomodoro.append(arrFocusType[i])
                        }
                    }
                    if UserDefaults.standard.object(forKey: kUserdefaultsFocusTipsShown) == nil{
                        if arrFocusType.count > 5{
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
                    options.dsn = "https://e8a9bd9e29490581f37b86342913134f@sentry.focusbear.io/6"
                    options.debug = true // Enabled debug when first installing is always helpful
                }
                
                SentrySDK.configureScope { scope in
                    let user = User(userId: self.user?.userId ?? "")
                    scope.setUser(user)
                }

                self.updater?.delegate = self
                self.updater?.checkForUpdatesInBackground()
                
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidWakeNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.screensDidSleepNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.didWakeNotification, object: nil)
                
                NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(self.sleepEvent(_:)), name: NSWorkspace.willSleepNotification, object: nil)
                
                
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }
    func pauseHabitActivityIfRunning(){
        addLog(text: "func:- pauseHabitActivityIfRunning")
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                return;
            }
        }
        
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
                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
                arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
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
            }
        }
    }
    func pauseBreakActivityTimerIfRunning(){
        addLog(text: "pause Break Activity Timer Called")
        
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                return;
            }
        }
        if  currentState == ._ACTIVITY_ || currentState == ._BREATHING_ ||  currentState == ._ABORT_{// no need to check morning or evening habit beacuse now morning evening habits can show breaks
            addLog(text: "return - no need to pause:- \(currentState)")
            return
        }
        
        if mainViewControllerObj?.breakTimer != nil{
            mainViewControllerObj?.stopActivityTimer()
            isActivityTimerPaused = true
            addLog(text: "pause Break Activity Timer Done")
        }else{
            addLog(text: "Timer Already nil - return")
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
        
//        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
//            addLog(text: "sleepEvent:- subscription expired return")
//            return;
//        }
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
            
            if !isSystemSleep && !isScreenSaverStart{
                if isActivityTimerPaused{
                    resumeBreakActivityTimerIfNededed()
                }
                returnFromSystemSleepCheckAppStateAgain()
            }
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
                macWakeupResumeFocusModeIfRunning()
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
                macWakeupResumeFocusModeIfRunning()
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
        addLog(text: "func:- macSleepPauseFocusModeIfRunning")
        if timerForFocusMode != nil{
            isAutoFocusPaused = true
            if let fireDate =  startFocusModeTimeForPauseAndResume{
                let interval = focusModeSecondsToPerform
                let passedSeconds = Calendar.current.dateComponents([.second], from: fireDate, to: Date()).second ?? 0
                focusModeActualDurationPerformed += passedSeconds
                remainingFocusModeSecondsAfterPaused = interval - passedSeconds
                print("remaining seconds \(remainingFocusModeSecondsAfterPaused)")
            }
            closeTaskPlayerWindowIfVisible()
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
            setAppIconForFocusModeScore(probability: nil)
        }else{
            addLog(text: "return:- timerForFocusMode is nil (auto meetings focus mode started)")
        }
    }
    
    func macWakeupResumeFocusModeIfRunning(){// auto pause when mac goes in sleep mode
        isAutoFocusPaused = false
        print("focus resume")
        addLog(text: "resume Focus Mode If Running")
        endFocusModeTime = Calendar.current.date(byAdding: .second, value: remainingFocusModeSecondsAfterPaused, to: Date())
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                setStatusBarButtonColorForFocusMode(color: nil, colorString: dic["color"] as? String ?? "")
                setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                statusbutton?.imagePosition = .imageLeft
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
            setAppIconForFocusModeScore(probability: nil)
            timerForFocusModeEndNotification = nil
            self.timerCheckAllowedApps?.invalidate()
            arrFocusType[index]["isPaused"] = true
            arrFocusType[index]["isOn"] = false
            closeTaskPlayerWindowIfVisible()
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
        shouldReloadTaskPlayer = true
        setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[index]["color"] as? String ?? "")
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
            writeSettingForScreeenTime(habitInfo: "")
        }else{//daysLeft
            
            //new work 12/9/22
            if daysLeft <= 0{//if expired than menu is enabled
//                self.readSettingsJsonDictionary(json: nil)
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
                
                // change appMode to simple mode
                if SettingsManagerObject.isGeekModeEnabled{
                    SettingsManagerObject.isGeekModeEnabled = false
                    SettingsManagerObject.isCuddlyModeEnabled = true
                    SettingsManagerObject.isSettingsChanged = true
                    SettingsManagerObject.putUserLocalDeviceSettings()
                }
                //
                
//                showUpgradeNowWindow()
                showUpgradeToProNagWindow(titleText: "", reason: "app_started_in_expired_mode")
                if UserDefaults.standard.object(forKey: kUserdefaultsScreenTimeEnabled) as? Bool == true{
                    UserDefaults.standard.set(false, forKey: kUserdefaultsScreenTimeEnabled)
                }
                writeSettingForScreeenTime(habitInfo: "")
            }else{
                self.initialWork()
                writeSettingForScreeenTime(habitInfo: "")
            }
            //
            
        }
    }
   
    /*
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
    */
    
    
    func readSettingsJsonDictionary(json:NSDictionary?){
        addLog(text: "read Settings Json Dictionary")
        arrFilteredMorningHabits.removeAll()
        arrPreFilteredMorningHabits.removeAll()
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
                    var tutorial = habitDic["tutorial"] as? String ?? ""
                    if tutorial.isEmpty{
                        if let arrTutorials = habitDic["tutorials"] as? [NSDictionary]{
                            if let tutorialDic = arrTutorials.first{
                                tutorial = tutorialDic.value(forKey: "id") as? String ?? ""
                            }
                        }
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
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode, activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: false, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list, tutorial: tutorial)
                    
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
                    var tutorial = habitDic["tutorial"] as? String ?? ""
                    if tutorial.isEmpty{
                        if let arrTutorials = habitDic["tutorials"] as? [NSDictionary]{
                            if let tutorialDic = arrTutorials.first{
                                tutorial = tutorialDic.value(forKey: "id") as? String ?? ""
                            }
                        }
                    }
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
                    let show_saved_distracting_websites = habitDic["show_saved_distracting_websites"] as? Bool ?? false
                    
                    
                    var habit = habit(id:id,name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion, openSpecificApps: openSpecificApps, allowUrls: allowUrls, allowApps: allowApps, allowedFocusMode: allowedFocusMode,activity_sequence_id: activity_sequence_id, run_micro_breaks: run_micro_breaks, take_notes: take_notes, isPriorityHigh: isPriorityHigh, days_of_week: days_of_week, text_instructions: text_instructions, imgUrls: imgUrls, completion_requirements: completion_requirements, useTimer: useTimer, checkList:check_list, tutorial: tutorial)
                    
                    
                    if let cutoff_time = habitDic["cutoff_time_for_doing_activity"] as? String{
                        habit.cutOffTime = getTimeFromString(val: cutoff_time)
                    }
                    
                    
                    habit.showSavedDistractingWebsites = show_saved_distracting_websites
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
                startTimeString = val
                startTime = getTimeFromString(val: val)
            }
            if let val = jsonResult!.value(forKey: "shutdown_time") as? String {
                shutOffTimeString = val
                shutOffTime = getTimeFromString(val: val)
            }
            
            addLog(text: "startup_time is \(startTimeString)")
            addLog(text: "shutdown_time is \(shutOffTimeString)")
            if let val = jsonResult!.value(forKey: "cutoff_time_for_non_high_priority_activities") as? String {
                cutOffTimeString = val
                cutOffTime = getTimeFromString(val: val)
            }
            
            has_edited_settings =  jsonResult!.value(forKey: "has_edited_settings") as? Bool ?? false
            writeSettingForScreeenTime(habitInfo: "")
            
            if arrFilteredMorningHabits.count == 0 && arrFilteredEveningHabits.count == 0{
                sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsNoHabitFound)
                sharedDefaults?.synchronize()
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
//        var packId = ""
        
//        if isFirstTime{
//            if let val = UserDefaults.standard.object(forKey: kUserdefaultsPackIdSelected) as? String{
//                packId = val
//            }
//        }// 
        
        allApiObject.getSettings(isFirstTime: isFirstTime, packId:"", completionHandler: {val in
            let settings = val?.mutableCopy() as? NSMutableDictionary

            if settings != nil{
                if isFirstTime{
                    
                    let breakDuration = UserDefaults.standard.object(forKey: kUserdefaultsBreakDurationValue) as? Int ?? defaultBreakDurationValue
                    
                    var startDate = UserDefaults.standard.object(forKey: kUserdefaultsStartupTimeFromOnboarding) as? String ?? defaultStartTime
                    var shutOffDate = UserDefaults.standard.object(forKey: kUserdefaultsShutOffTimeFromOnboarding) as? String ?? defaultShutDownTime
                    var sleepTime = UserDefaults.standard.object(forKey: kUserdefaultsSleepTimeFromOnboarding) as? String ?? defaultSleepTime
                    
//                    if packId.isEmpty{// work for focus only
//                        startDate = "00:00"
//                        shutOffDate = "23:59"
//                        sleepTime = "23:59"
//                    }
                    if let isHabitsDisabled = UserDefaults.standard.object(forKey: kUserdefaultsIsHabitsDisabledFromOnboarding) as? Bool{
                        if isHabitsDisabled{
                            startDate = "00:00"
                            shutOffDate = "23:59"
                            sleepTime = "23:59"
                        }
                    }
                    
                    settings!["startup_time"] = startDate
                    settings!["shutdown_time"] = shutOffDate
                    settings!["break_after_minutes"] = breakDuration
                    settings!["sleep_time"] = sleepTime
                    
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsBreakDurationValue)
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsStartupTimeFromOnboarding)
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsShutOffTimeFromOnboarding)
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsSleepTimeFromOnboarding)
                    
                    allApiObject.isSettingsValid(settings: settings!, isOnboarding:true, completionHandler: {dic,statusCode  in
                        DispatchQueue.main.async {
                            
                            
                            if dic == nil{
                                self.readSettingsAndLoadApp(settings: settings)
                            }else{
                                if statusCode == 200{
                                    let settings = dic?.mutableCopy() as? NSMutableDictionary
                                    self.readSettingsAndLoadApp(settings: settings)
                                    do {
                                        let jsonResultData =  try JSONSerialization.data(withJSONObject: dic!, options: JSONSerialization.WritingOptions.prettyPrinted)
                                        if let backToString = String(data: jsonResultData, encoding: String.Encoding.utf8){
                                            UserDefaults.standard.set(backToString, forKey: kUserdefaultsSelectedJson)
                                            //appdelegate?.readSettingsJsonDictionary(json: nil)//will not do this here
                                        }
                                    } catch let myJSONError {
                                        print(myJSONError)
                                    }
                                }else{
                                    
                                }
                            }
                        }
                    })
                    
                    
                    
                    do {
                        let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                        if let str = String(data: data, encoding: String.Encoding.utf8){
                            UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                        }
                    } catch let error as NSError {
                        print(error)
                    }
                }else{
                    do {
                        let data = try (JSONSerialization.data(withJSONObject: settings!, options: .prettyPrinted))
                        if let str = String(data: data, encoding: String.Encoding.utf8){
                            UserDefaults.standard.set(str, forKey: kUserdefaultsSelectedJson)
                        }
                    } catch let error as NSError {
                        print(error)
                    }
                    self.readSettingsAndLoadApp(settings: settings)
                }
                
                
            }else{
                self.readSettingsAndLoadApp(settings: settings)
            }
            

        }
        )
    }
    
    func readSettingsAndLoadApp(settings: NSMutableDictionary?){
        self.readSettingsJsonDictionary(json: settings)
        
        arrAllFocusModeTags = UserDefaults.standard.object(forKey: kUserdefaultsAllFocusModesTags) as? [[String : String]] ?? []
        allApiObject.getFocusModeTags(completionHandler: {arrJson in
            
        })
        
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
            SettingsManagerObject.readLocalSettings()
            if UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) == nil{
                UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
                isAppEnable = true
                SettingsManagerObject.writeLocalSettings()
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
                    SettingsManagerObject.enableAppWriteSettings()
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
                        if mainWindowControllerObj == nil{
                            return event;
                        }else if event.window != mainWindowControllerObj?.window{
                            return event;
                        }
                        
                        if event.keyCode == 53 {
                            if event.modifierFlags.contains(.command) && event.modifierFlags.contains(.shift) && event.modifierFlags.contains(.control) {
                                addLog(text: "[user-action]ShortCut Clicked Hide main window")
                                if (mainWindowControllerObj?.window!.isVisible)! {
                                    self.abortAllProcess()
                                    mainWindowControllerObj?.window?.close()
                                }
                                hideBlankWindowInSecondaryMonitor()
                            }
                        }else if event.keyCode == 48{// tab
                            if mainWindowControllerObj?.window?.isVisible ?? false{
                                if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                    if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                        if currentState == ._ACTIVITY_ || currentState == ._BREATHING_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_{
                                            if logQuantityVcObj!.tabClickedSelectNextTextField(){
                                                return nil
                                            }
                                        }
                                    }
                                }
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
                                            if focusCompletedForActivityVcObj != nil{
                                                if (mainViewControllerObj?.view.subviews.contains((focusCompletedForActivityVcObj!.view)))!{
                                                    return event
                                                }
                                            }
                                            if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                                logQuantityVcObj?.btnOkClicked(self)
                                                return nil
                                            }else{
                                                if thirdVcObj?.boxBg.isHidden == true{// it means remember next habit is added
                                                    if rememberNextHabitVcObj != nil{
                                                        if thirdVcObj?.view.subviews.contains(rememberNextHabitVcObj!.view) ?? false{
                                                            if rememberNextHabitVcObj?.btnStartNextHabit.isHidden == false{
                                                                rememberNextHabitVcObj?.btnStartNextHabitClicked(self)
                                                                return nil
                                                            }
                                                        }
                                                    }
                                                }else{
                                                    thirdVcObj?.btnMainClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                        
                                    }else if currentAction == ._INPROGRESS_{
                                        if timerViewcontrollerObj != nil{
                                            if (mainViewControllerObj?.containerView.subviews.contains(timerViewcontrollerObj!.view))!{
                                                if timerViewcontrollerObj?.boxTimer.isHidden == true{
                                                    timerViewcontrollerObj?.btnIAmDoneClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                        
                                    }else if currentAction == ._START_ {
                                        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._BREATHING_{
                                            if (mainViewControllerObj?.containerView.subviews.contains(firstViewControllerObj!.view))!{
                                                if !firstViewControllerObj!.isTimerGoingOn{
                                                    if firstViewControllerObj!.btnStartFirstHabit.isEnabled{
                                                        firstViewControllerObj?.btnStartFirstHabitClicked(self)
                                                        return nil
                                                    }
                                                }
                                            }
                                        }else if currentState == ._ACTIVITY_{
                                            if (mainViewControllerObj?.containerView.subviews.contains(firstViewControllerObj!.view))!{
                                                if !firstViewControllerObj!.isTimerGoingOn{
                                                    if firstViewControllerObj!.btnStartFirstHabit.isEnabled{
                                                        firstViewControllerObj?.btnStartFirstHabitClicked(self)
                                                        return nil
                                                    }
                                                }
                                            }else if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                                if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                                    logQuantityVcObj?.btnOkClicked(self)
                                                    return nil
                                                }else{
                                                    thirdVcObj?.btnMainClicked(self)
                                                    return nil
                                                }
                                            }
                                        }
                                    }else if currentAction == ._BRAIN_DUMP_ && breaksBrainDumpVcObj != nil && currentState == ._ACTIVITY_{
                                        if (mainViewControllerObj?.containerView.subviews.contains(breaksBrainDumpVcObj!.view))!{
                                            if breaksBrainDumpVcObj!.btnMain.isEnabled{
                                                breaksBrainDumpVcObj?.btnMainClicked(self)
                                                return nil
                                            }
                                        }
                                    }else if currentAction == ._VISUALIZE_{
                                        if !getvisualizeInstructionsObject().isTimerGoingOn{
                                            getvisualizeInstructionsObject().btnMainClicked(self)
                                            return nil
                                        }
                                    }
                                }else if currentState == ._SHUTOFFMAC_{//shutoffmac k casemai last evening over hone per log quantity vala nag shutoff k upar aayga
                                    if arrFilteredEveningHabits.count != 0{
                                        if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                            logQuantityVcObj?.btnOkClicked(self)
                                            return nil
                                        }
                                    }
                                }
                            }
                        }
                        
                    }
                    return event
                }
            )
        }
    }
    
    func setTopMenu(){
        addLog(text: "setTopMenu")
        if let button = statusItem.button
        {
            button.action = #selector(togglePopover(_:))
            popover.contentViewController = menuViewControllerObj
            popover.animates = false
            popover.behavior = .transient
            addLog(text: "setTopMenu end")
            
        }
    }
    
    @objc func togglePopover(_ sender: Any?) {
        addLog(text: "togglePopover start")
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if runningApp.bundleIdentifier != Bundle.main.bundleIdentifier{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    if !arrExcludeAppsInBreaksBrainDumpLastActivateApp.contains(nameLowercased){
                        lastFrontMostApplication = runningApp
                    }
                }
            }
        }
        
        addLog(text: "[user-action] Top bar focus bear button clicked")
        if popover.isShown
        {
            closePopover(sender: sender)
        } else
        {
            addLog(text: "popover is not visible")
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
                    }else if currentRelaxHabitPlaying != nil{
                        if relaxModeWcObj != nil{
                            relaxModeWcObj!.showWindow(nil)
                        }
                    }
                }
            }
            showPopover(sender: sender)
            
            if (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_) && !(mainWindowControllerObj?.window?.isVisible ?? false){
                addLog(text: "try to show samll window")
                if currentHabitPlaying != nil || currentActivityPlaying != nil{// it means background activity
                    if smallCountDownWcObj != nil{
                        addLog(text: "small window is not nil")
                        if smallCountDownWcObj?.window?.alphaValue == 0{
                            if popUpBlockConfirmWcObj != nil{
                                if !(popUpBlockConfirmWcObj?.window?.isVisible ?? false){//Countdown timer pops up after allowing app/website #455
                                    smallCountDownWcObj?.window?.alphaValue = 1
                                    addLog(text: "try to show samll window done")
                                }
                            }else{
                                smallCountDownWcObj?.window?.alphaValue = 1
                                addLog(text: "try to show samll window done")
                            }
                        }
                    }
                }
            }
            addLog(text: "togglePopover end")
        }  
    }
    func showPopover(sender: Any?) {
        addLog(text: "showPopover")
        if let button = statusItem.button{
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApplication.shared.activate(ignoringOtherApps: true)
            addLog(text: "showPopover End")
        }
    }
    
    func closePopover(sender: Any?) {
        addLog(text: "closePopover")
        popover.performClose(sender)
    }
    
    @objc func menuItem_Reactivate(){
        timerCheckReactivateTime?.invalidate()
        timerCheckReactivateTime = nil
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
        SettingsManagerObject.enableAppWriteSettings()
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
                    SettingsManagerObject.enableAppWriteSettings()
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
            addLog(text: "[user-action] button Do It Clicked")
            menuItem_Reactivate()
        }else if result == .alertSecondButtonReturn{
            addLog(text: "[user-action] button No thanks Clicked")
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
        isFocusBreakOn = false
        if savedSitesForLaterWcObj != nil{
            if savedSitesForLaterWcObj!.window?.isVisible ?? false{
                savedSitesForLaterWcObj!.close()
            }
        }
        if endingFocusWindowControllerObj != nil{
            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
                addLog(text: "Focus mode completed Window is visible:- return")
                return;
            }
        }
        
        if !isAppEnable{
            addLog(text: "App is Disabled: Pomodoro Mode View cancelled")
            return
        }
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
            return
        }
        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_ || currentState == ._FOCUS_SUMMARY_{
            addLog(text: "Activity is running: Pomodoro Mode View cancelled")
            return;
        }
        
        if !isHardCorePomodoroModeOn{// if hardcore pomodoro is started than it will complete first
            if isUserOnMeeting{
                addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
                return
            }
        }
        if focusModeStartWindowLodded{
            if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                addLog(text: "focusModeStartWindowLodded .Auto Pomodoro Mode View cancelled")
                return
            }
        }
        
        if currentState == ._SHUTOFFMAC_{
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        getPomodoroWindowControllerObj().contentViewController = pomodoroVcObj
        getPomodoroWindowControllerObj().showWindow(self)
        pomodoroVcObj?.isShowingPomodoroManually = false
        pomodoroVcObj?.isShowingMorningPomodoro = false
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    @objc func showMorningPomodoroModeView(){
        addLog(text: "Initiating Auto Pomodoro Mode View.")
        if !SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Simple Mode is enabled:- return.")
            return;
        }
        if endingFocusWindowControllerObj != nil{
            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
                addLog(text: "Focus mode completed Window is visible:- return")
                return;
            }
        }
        
        if isFocusModeOnOrPaused(){
            addLog(text: "Focus Mode Is On/Paused: Pomodoro Mode View cancelled")
            return
        }
        
        if isUserOnMeeting{
            addLog(text: "isUserOnMeeting True: Pomodoro Mode View cancelled.")
            return
        }
        
        if isShutOffTimeGoing(){
            addLog(text: "This is Shut Off time. Auto Pomodoro Mode View cancelled")
            return;//if not working hours then return
        }
        
        if let isEnabled = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHardcorePomodoroEnabled) as? Bool{
            if isEnabled{
                //                get  what day is today and comapre from pomodoro settings
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
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        getPomodoroWindowControllerObj().contentViewController = pomodoroVcObj
        getPomodoroWindowControllerObj().showWindow(self)
        pomodoroVcObj?.isShowingPomodoroManually = false
        pomodoroVcObj?.isShowingMorningPomodoro = true
        NSApplication.shared.activate(ignoringOtherApps: true)
        
    }
    
    @objc func menuShowPomodoroModeView(){
        addLog(text: "Initiating Pomodoro Mode View.")
        if !SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Simple Mode is enabled:- return.")
            return;
        }
        if endingFocusWindowControllerObj != nil{
            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
                addLog(text: "Focus mode completed Window is visible:- return")
                return;
            }
        }
        
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
            isFocusBreakOn = false
        }
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                    getsmallCountDownVcObject().closeTimerBox()
                }
            }
        }
        pomodoroVcObj?.isShowingMorningHardcorePomodoro = false
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        getPomodoroWindowControllerObj().contentViewController = pomodoroVcObj
        getPomodoroWindowControllerObj().showWindow(self)
        pomodoroVcObj?.isShowingPomodoroManually = true
        pomodoroVcObj?.isShowingMorningPomodoro = false
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    
    @objc func menuShowSimplePomodoroModeView(){
        addLog(text: "Initiating Simple Pomodoro Mode View.")
        if SettingsManagerObject.isGeekModeEnabled{
            addLog(text: "Geek Mode is enabled:- return.")
            return;
        }
        if endingFocusWindowControllerObj != nil{
            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
                addLog(text: "Focus mode completed Window is visible:- return")
                return;
            }
        }
        
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
            isFocusBreakOn = false
        }
        if smallCountDownWcObj != nil{// allowing postpone from timer window issue #213  date- 5/9/22
            if smallCountDownWcObj?.window != nil{
                if getSmallCountDownWindowObject().window!.isVisible && getsmallCountDownVcObject().isFocusBreak{
                    getsmallCountDownVcObject().closeTimerBox()
                }
            }
        }
        allApiObject.capturePosthog(event: "start-focus-session-popup-opened", metadata: [:])
        getPomodoroWindowControllerObj().contentViewController = getSimplePomodoroVcObj()
        getPomodoroWindowControllerObj().showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc func checkWindowState(){
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if !(menuViewControllerObj?.isViewLoaded ?? false){
                    menuViewControllerObj?.loadView()
                }
            }
        }
        isFirstRun = false
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                statusItem.button?.window?.sharingType = .none
            }else{
                statusItem.button?.window?.sharingType = .readOnly
            }
        }
        
        getAllLongTermGoals()
        getTotalFocuedTime()
        if !lastOpenUrlString.isEmpty{
            filterUrl(url: lastOpenUrlString)
        }

        
        if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
            checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
        }else{
            isHabitAlreadyShowed = false
        }
        
        if startTime != nil && shutOffTime != nil{
            
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
        
        setBackgroundThreadTimer()
        pusherEventsObject.startEventNotifications()
    }
    
    
    func checkLastHabitShowDate(lastHabitShowDate:Date){
        isHabitAlreadyShowed = true
        var currentDate = Date()
        // currentDate is 1 am and startdate is 10 am
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: currentDate)!
        if currentDate.compare(startDate) == .orderedAscending {//currentDate < startDate
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
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
        if !SettingsManagerObject.isMeetingDetectionEnabled{
            addLog(text: "func checkIsMeetingsGoingOn:- Meeting Detection Disabled: return")
            if isFocusModeRunning{
                self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateFocusText)
            }
            return;
        }
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
                                            
                                            if nameLowercased == "microsoft teams" || nameLowercased == "microsoft teams classic" || nameLowercased == "zoom.us"{
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
                                                            isAllowed = self.validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl)
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
                                                self.setStatusBarButtonColorForFocusMode(color: NSColor.systemBlue, colorString: nil)
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
                    focusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false)
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

            if isFocusModeOn() {
                self.setStatusBarButtonColorForFocusMode(color: nil, colorString: currentRunningFocusType["color"] as? String ?? "")
                setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                statusbutton?.imagePosition = .imageLeft
            }else if isAnyAllowedFocusModeActivityRunning && (currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_){
                self.setStatusBarButtonColorForFocusMode(color: nil, colorString: currentRunningFocusType["color"] as? String ?? "")
                setStatusBarButtonTitleForFocusMode(title: whatToAchieveInFocusBlock)
                statusbutton?.imagePosition = .imageLeft
            }else{
                self.statusbutton?.title = ""
                self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
            }
            
            timerMeetingStartAlert?.invalidate()
            timerMeetingStartAlert = nil
            
            
        }
    }
    
    func setStatusBarButtonColorForFocusMode(color:NSColor?, colorString:String?){
        if SettingsManagerObject.isOfficeModeEnabled{
            statusbutton?.backgroundcolor = NSColor.clear
            return;
        }
        
        if color != nil{
            statusbutton?.backgroundcolor = color
        }else if colorString != nil{
            statusbutton?.backgroundcolor = HexToColor(hexString: colorString!)
        }else{
            statusbutton?.backgroundcolor = NSColor.clear
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
        
        if isFocusModeRunning{
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

                if taskPlayerWcObj?.window?.isVisible ?? false{
                    finalTitle = "\(hour):\(minute)"
                }else{
                    finalTitle = "\(hour):\(minute)" + " - " + finalTitle//count down in minutes not in seconds
                }
                
            }else{
                if taskPlayerWcObj?.window?.isVisible ?? false{
                    statusbutton?.title = ""
                    return;
                }
            }
        }
        
        if SettingsManagerObject.isOfficeModeEnabled{
            statusbutton?.title = finalTitle
            return;
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
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Start Focus clicked")
                        self.meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Cancel clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        //                print("third")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
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
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Gotit clicked")
                        self.alertSuggestFocusMode = nil
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
                        self.alertSuggestFocusMode = nil
                        self.perform(#selector(self.showAlertFalseMicDetection), with: nil, afterDelay: 1)
                    }
                }else{
                    if result == .alertFirstButtonReturn{
                        //                print("first")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Start Focus clicked")
                        meetingAlertStartFocusClicked()
                    }else if result == .alertSecondButtonReturn{
                        //                print("second")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button Cancel clicked")
                        alertSuggestFocusMode = nil
                    }else if result == .alertThirdButtonReturn{
                        //                print("third")
                        addLog(text: "[user-action] func Meeting Suggestion alert:- button False Detection clicked")
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
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Disable detection clicked")
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
                        self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                        self.statusbutton?.title = ""
                    }
                }else{
                    //                print("second")
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Cancel clicked")
                    self.alertSuggestFocusMode = nil
                }
            })
            
        }else{
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let result = alertSuggestFocusMode?.runModal(){
                if result == .alertFirstButtonReturn{
                    //                print("first")
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Disable detection clicked")
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
                        self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString: nil)
                        self.statusbutton?.title = ""
                    }
                    
                }else{
                    //                print("second")
                    addLog(text: "[user-action] func showAlertFalseMicDetection:- Button Cancel clicked")
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
                        addEntryInStatsCsv(logType: "focus block", activity: focusCompletedVcObj!.currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "\(focusModeMinutesToPerform) of \(focusCompletedVcObj!.currentFocusModeName)", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
                        getEndFocusModeWindowControllerObj().window?.close()
                    }
                    let calendar = Calendar.current
                    endFocusModeTime = calendar.date(byAdding: .minute, value: 5, to: Date())
                    startFocusModeTime = Date()
                    currentFocusModeStrictness = ._NORMAL_
                    arrFocusType[i]["isOn"] = true
                    shouldReloadTaskPlayer = true
                    if let isAutoDoNotDisturbEnabled = arrFocusType[i]["isAutoDoNotDisturbEnabled"] as? Bool{
                        if isAutoDoNotDisturbEnabled{
                            if isAccessibilityEnabled(isPrompt: true){
                                enableDND()
                            }
                        }
                    }
                    workBeforeFocusBegin(index: i)
                    focusModeMinutesToPerform = 0
                    
                    self.setStatusBarButtonColorForFocusMode(color: nil, colorString: arrFocusType[i]["color"] as? String ?? "")
                    statusbutton?.title = buttonStatusStateFocusText
                    statusbutton?.imagePosition = .imageLeft
                    if timerForFocusMode != nil{
                        timerForFocusMode?.invalidate()
                        timerForFocusMode = nil
                        setAppIconForFocusModeScore(probability: nil)
                        timerForFocusModeEndNotification?.invalidate()
                        timerForFocusModeEndNotification = nil
                    }
                    isFocusTimeType = ._HOUR_
                    startFocusModeTimeForPauseAndResume = Date()
                    focusModeSecondsToPerform = 300
                    isFocusModeStartedFromPomodoroMode = false
                    whatToAchieveInFocusBlock = ""
                    setIntentionInBrainDumpWindow()
                    focusModeStartted(isStartedByPusher: false)
                    allApiObject.capturePosthog(event: "start-meetings-focus-mode", metadata: [:])
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    isMeetingsFocusStartedAutomatically = true
                    isFocusModeStartedAutomatically = false
                    closePomodoroWindowIOfVisible()
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
        if popupAppointmentTimeWcObj != nil{
            if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                addLog(text: "Appointment popup is visible :- return.")
                return;
            }
        }
        
        if currentState == ._ACTIVITY_ || currentState == ._POSTPON_EVENING_HABIT_ || currentState == ._POSTPON_FOCUS_SUMMARY_ || currentState == ._POSTPON_MORNING_HABIT_ || !isAppEnable || currentState == ._ABORT_ || currentState == ._SPECIAL_ACTIVITY_{
            addLog(text: "func:- returnFromSystemSleepCheckAppStateAgai   return:- currentState is activity/postpone/abort/specialActivity")
            
            
            if currentState == ._ACTIVITY_{// if user was doing break before system sleep and after sysytem wakes up if idle time is more then 5 minutes then stop activity and set timer again
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
                        mainViewControllerObj?.setActivityTimer()
                    }
                }
            }
            return
        }
        macGoesInSleepTime = nil
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
        if mainViewControllerObj != nil{//Log quantity box, Notes box, Focus mode end box will hold the activity screen there 26/6/23
            if !mainViewControllerObj!.checkIsAnyUserInputSubViewAdded(){
                
                
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_{
                    self.abortAllProcess()
                    currentState = ._NOTHING_
                    backgroundThread()
                    if self.isUserOnMeeting && currentState == ._NOTHING_{
                        addLog(text: "isUserOnMeeting True and currentState is None: Hide Main Window.")
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                        }
                    }
                }else{
                    self.abortAllProcess()
                    currentState = ._NOTHING_
                    if mainWindowControllerObj?.window?.isVisible ?? false{
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                    }
                    backgroundThread()
                }
            }
        }
    }
    
    
    
    var isProcessingHabitRoutine = false
    var isProcesssingOfflineData = false
    
    func processOfflineData(){
        if !self.isProcesssingOfflineData{
            DispatchQueue.global().async {
                if Reachability.isConnectedToNetwork() == true{
                    self.isProcesssingOfflineData = true
                    var arr = readDataFromCSV(url: offlineActivitiesCsvURL!)
                    if arr.last?.count == 1{
                        arr.removeLast()
                    }
                    if arr.count > 1{
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
                                if dic["start_time"] as? String == ""{
                                    continue;
                                }
                                if j == newArr.count - 1{
                                    if isLastLoop{
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
                                                    
                                                    
                                                    allApiObject.activityCompletedApi(activity_id: activity_id, activity_sequence_id: activity_sequence_id, start_time:start_time, quantity_logged:quantity_logged, duration_logged:duration_logged, choice_id: choice_id, is_skipped: is_skipped, notes: note_logged, should_not_update_current_activity: false, log_quantity_answers: [], completionHandler: {dic  in
                                                        
                                                        DispatchQueue.main.async {
                                                            
                                                        }
                                                        print(dic)
                                                    })
                                                }
                                            }
                                        }
                                    }
                                }
                                
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
                                arrDic.append(dic)
                            }
                        }
                        
                        if arrDic.count == 0{
                            self.isProcesssingOfflineData = false
                            removeEntryInActivitiesCsv(count: maxCount)
                            return;
                        }
                        
                        allApiObject.syncOfflineDataApi(offineData: arrDic, completionHandler: { json in
                            if json != nil{
                                self.nRetry = 0
                                removeEntryInActivitiesCsv(count: maxCount)
                            }else{
                                let nBaseDelayMs = 10000
                                let nDelayMs = calculateBackoffWithJitter(baseDelayMs: nBaseDelayMs, retry: self.nRetry)
                                let secondsToSleep = UInt32(nDelayMs) / 1000
                                sleep(secondsToSleep)
                                self.nRetry += 1
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
    var nRetry = 0
    
    func filterUrl(url:String){
        addLog(text: "func:- filterUrl \(url)")
        if !isAppEnable{
            addLog(text: "func:- filterUrl- app is not enabled- return")
            return;
        }
        if !isPurchased && daysLeft <= 0{
            addLog(text: "func:- filterUrl- subscription expired return- return")
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
                    
                    if !isActivityFound{
                        let durationInSeconds = Int(activityDuration) ?? 0
                        if durationInSeconds >= 60 {
                            for i in 0..<arrFocusType.count{
                                var isFocusModeFound = false
                                let id = arrFocusType[i]["id"] as? String ?? ""
                                let name = arrFocusType[i]["name"] as? String ?? ""
                                if id == activityId{
                                    isFocusModeFound = true
                                }else if name.lowercased() == activityId.lowercased(){
                                    isFocusModeFound = true
                                }
                                if isFocusModeFound{
                                    if isHardCorePomodoroModeOn{
                                        return;
                                    }
                                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
                                        addLog(text: "Activity is running: Can not start a focus mode")
                                        let alert = NSAlert()
                                        alert.setSharingType()
                                        alert.messageText = "You can not start a focus mode while an activity is running."
                                        
                                        if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                            if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                                                alert.messageText = startingFocusModeInfo.value(forKey: "activityRunningCantStartFocusText") as? String ?? alert.messageText
                                            }
                                        }
                                        NSApplication.shared.activate(ignoringOtherApps: true)
                                        alert.runModal()
                                        return;
                                    }
                                    
                                    
                                    for j in 0..<arrFocusType.count{
                                        if arrFocusType[j]["isOn"] as? Bool == true || arrFocusType[j]["isPaused"] as? Bool == true{
                                            
                                            if i == j{
                                                return;
                                            }
                                            let alert = NSAlert()
                                            alert.setSharingType()
                                            alert.messageText = "A focus mode is already running. Please abort the running focus mode to start a new one."
                                            var buttonStopFocusText = "Stop current focus mode and start this one"
                                            
                                            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                                if let focusAlreadyRunningText = focusInfo.value(forKey: "focusAlreadyRunningText") as? String{
                                                    alert.messageText = focusAlreadyRunningText
                                                }
                                            }
                                            
                                            if let focusInfo = configjson.value(forKey: "focusInfo") as? NSDictionary{
                                                if let startingFocusModeInfo = focusInfo.value(forKey: "startingFocusModeInfo") as? NSDictionary{
                                                    buttonStopFocusText = startingFocusModeInfo.value(forKey: "buttonStopFocusText") as? String ?? buttonStopFocusText
                                                }
                                            }
                                            
                                            alert.addButton(withTitle: buttonOkText)
                                            alert.addButton(withTitle: buttonStopFocusText)
                                            NSApplication.shared.activate(ignoringOtherApps: true)
                                            let result = alert.runModal()
                                            if result == .alertSecondButtonReturn{
                                                addLog(text: "Stop current focus from alert and show start focus view")
                                                appdelegate?.focusModeFinished(isSilent: true, isShutOffTime: false, isMorningRoutineTime: false)
                                                showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                                                
                                                startingFocusModeVcObj?.textFieldHourValue.integerValue = 0
                                                startingFocusModeVcObj?.textFieldMinutesValue.integerValue = durationInSeconds/60
                                            }
                                            return;
                                        }
                                    }
                                    
                                    
                                    let isRelaxFocus = arrFocusType[i]["isRelaxFocus"] as? Bool ?? false
                                    
                                    
                                    if isRelaxFocus{
                                        if shouldAskPassword(){
                                            if SettingsManagerObject.isPasswordRequireInUseRelaxFocusMode{
                                                menuViewControllerObj?.showPasswordWindow()
                                                menuViewControllerObj?.isShowingPasswordForRelaxFocusMode = true
                                                customUrlHandleLastDurationForRelaxFocusMode = durationInSeconds
                                            }else{
                                                showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                                                startingFocusModeVcObj?.textFieldHourValue.integerValue = 0
                                                startingFocusModeVcObj?.textFieldMinutesValue.integerValue = durationInSeconds/60
                                            }
                                        }else{
                                            showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                                            startingFocusModeVcObj?.textFieldHourValue.integerValue = 0
                                            startingFocusModeVcObj?.textFieldMinutesValue.integerValue = durationInSeconds/60
                                        }
                                    }else{
                                        showStartingFocusMode(focusModeIndex: i, focusType: arrFocusType[i]["name"] as? String ?? "")
                                        startingFocusModeVcObj?.textFieldHourValue.integerValue = 0
                                        startingFocusModeVcObj?.textFieldMinutesValue.integerValue = durationInSeconds/60
                                    }
                                    
                                    return;
                                }
                            }
                        }
                    }
                    
                    
                    
                        let durationInSeconds = Int(activityDuration) ?? 0
                        if durationInSeconds > 0{
                            if !isMainWindowLoaded{
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
                                mainViewControllerObj?.postponeMorningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false, showAskIntention:false)
                            }else if currentState == ._EVENING_HABIT_{
                                mainViewControllerObj?.stopActivityTimer()
                                mainViewControllerObj?.postponeEveningHabitFor(minutes: 0, secondsToPostpone: durationInSeconds, showAskFocusModeView:false, showAskIntention:false)
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
                            
                            if !isActivityFound{
                                specialHabit = habit(id: "", name: activityId, durationSeconds: durationInSeconds, urlsArray: [], logQuantity: false, logQuantityQuestion: nil, openSpecificApps: false, allowUrls: [], allowApps: [], allowedFocusMode: "", activity_sequence_id: "", run_micro_breaks: false, take_notes: "", isPriorityHigh: false, days_of_week: [], text_instructions: "", imgUrls: [], completion_requirements: "", useTimer: true, checkList: [], tutorial: "")
                            }
                            
                            mainViewControllerObj?.startSpecialActivity(duration: durationInSeconds,habit:specialHabit, activity:specialActivity)
                        }
                    
                    
                    
                }
            }
        }
        else if urlString.contains("focusbear://event-about-to-start?"){
            urlString = urlString.replacingOccurrences(of: "focusbear://event-about-to-start?", with: "")
            if popupAppointmentTimeWcObj != nil{
                if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
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
                if eventEndTime != nil{
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
                        //Late No More disrupts saving achievements at end of activity with focus mode#919
                        if currentAction == ._END_ && thirdVcObj != nil{
                            if (mainViewControllerObj?.containerView.subviews.contains(thirdVcObj!.view))!{
                                if logQuantityVcObj != nil{// log quanity
                                    if (mainViewControllerObj?.view.subviews.contains((logQuantityVcObj!.view)))!{
                                        logQuantityVcObj?.btnOkClicked(self)
                                    }
                                }
                                
                                if takeActivityNotesVcObj != nil{// notes
                                    if (mainViewControllerObj?.view.subviews.contains((takeActivityNotesVcObj!.view)))!{
                                        takeActivityNotesVcObj?.btnOkClicked(self)
                                    }
                                }
                                
                                if focusCompletedForActivityVcObj != nil{// focus completed view
                                    if (mainViewControllerObj?.view.subviews.contains((focusCompletedForActivityVcObj!.view)))!{
                                        focusCompletedForActivityVcObj?.btnContinueClicked(self)
                                    }
                                }
                            }
                        }
                        //--------------------------------------------------------------------------------------//
                        
                        mainViewControllerObj?.stopActivityTimer()
                        mainWindowControllerObj?.window?.close()
                        hideBlankWindowInSecondaryMonitor()
                        
                        showPopupAppointmentWindow(title: eventTitle, endTime: eventEndTime!)
                        if easyPostponeWcObj != nil{
                            if easyPostponeWcObj?.window?.isVisible ?? false{
                                easyPostponeWcObj?.close()
                            }
                        }
                    }else{
                        if mainViewControllerObj?.breakTimer != nil{
                            mainViewControllerObj?.setActivityTimer()
                        }
                        
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
                            for turl in arrAllVideoKindUrls{
                                isAllowed = self.validation.isUrlValid(urlToCheck: activeTabUrl, allowUrl: turl)
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
        DispatchQueue.main.async {
            if isAppEnable{// agar app diable hai to sirf 1 case mai ye func call hoga jab app 4 hour deactivate h tb
                self.checkIsMeetingsGoingOn() //and app kon kon si check krni haiu
            }else{
                if isFocusModeRunning{
                    self.setStatusBarButtonTitleForFocusMode(title: buttonStatusStateFocusText)
                }
                return;
            }
            
            if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
                
            }else if isAppEnable && SettingsManagerObject.blockingSchedule == ._UNTIL_I_FINISH_WORK_{
                if !isFocusModeOn(){
                    if let runningApp = NSWorkspace.shared.frontmostApplication{
                        if let appUrl = runningApp.bundleURL{
                            let name = appUrl.deletingPathExtension().lastPathComponent
                            let nameLowercased = name.lowercased()
                            if nameLowercased != selfAppName.lowercased() && nameLowercased != focusBearTimeTrackerAppName{
                                var isAppAllowed = true
                                var isAppAllowedByUser = false
                                let arrBlockedApps = getBlockedAppsToBlock()
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                        isAppAllowed = false
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if !result{// it means allowed by user(intention set by user)
                                            isAppAllowedByUser = true
                                        }
                                        break;
                                    }
                                }
                                if !isAppAllowedByUser{
                                    if !isAppAllowed{
                                        self.timerBlockUrl?.invalidate()
                                    }else{
                                        if nameLowercased != selfAppName.lowercased(){
                                            self.closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            self.processOfflineData()
            
            if isExpired{
                if let lastSubscriptionCheckDate = UserDefaults.standard.object(forKey: kUserdefaultsUserSubscriptionCheckDate) as? Date{
                    let currentDate = Date()
                    let diffHours = Calendar.current.dateComponents([.hour], from: lastSubscriptionCheckDate, to: currentDate).hour ?? 0
                    if diffHours > 24{
                        UserDefaults.standard.set(Date(), forKey: kUserdefaultsUserSubscriptionCheckDate)
                        allApiObject.getUserSubscriptionInfo(completionHandler: {dic,statusCode  in
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
                                if isPurchased == false && daysLeft == 0{
                                    isExpired = true
                                }
                            }
                        })
                    }
                }
            }
            
            
            if popupAppointmentTimeWcObj != nil{
                if popupAppointmentTimeWcObj?.window?.isVisible ?? false{
                    return;
                }
            }
            
            if currentState == ._ABORT_{
                return;
            }
            if startTime == nil || shutOffTime == nil{
                return;
            }
            var startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
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
            ///
            
            
            if arrAllDaysEveningHabits.count != 0{
                let fiveMinutesBeforeShutOffTime = shutOffdate.addingTimeInterval(-5 * 60)
                let sixtyFiveSecondsBeforeShutOffTime = fiveMinutesBeforeShutOffTime.addingTimeInterval(-5)
                if currentDate.compare(fiveMinutesBeforeShutOffTime) == .orderedAscending  && currentDate.compare(sixtyFiveSecondsBeforeShutOffTime) == .orderedDescending{
                    var shouldShowEveningHabit = true
                    if !isAppEnable{
                        shouldShowEveningHabit = false
                        
                        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                shouldShowEveningHabit = true
                            }
                        }
                    }
                    if shouldShowEveningHabit{
                        var shutdownNotificationTitle = "It's time to wrap up for the day. Your shutdown time is in 5 minutes."
                        
                        if let common = configjson.value(forKey: "common") as? NSDictionary{
                            shutdownNotificationTitle = common.value(forKey: "shutdownNotificationTitle") as? String ?? shutdownNotificationTitle
                        }
                        showNotificationWithMessage(msg: shutdownNotificationTitle)
                    }
                }
            }
            //  ////////////////
            
            
            if !self.isSystemSleep && !self.isScreenSaverStart && currentState != ._ACTIVITY_{//same condition in pomodoro view
                unfocusedTime += 5
            }
            
            
            
            if isShutOffTimeGoing(){
                
                var shouldShowEveningHabit = true
                
                if !isAppEnable{
                    shouldShowEveningHabit = false
                    
                    if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                        if cutOffTime != nil{
                            let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                            let currentDate = Date()
                            if currentDate > cutOffDate{
                                if SettingsManagerObject.isPasswordRequireInSkipEveningAfterCutOff{
                                    shouldShowEveningHabit = true
                                }
                            }else{
                                if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                    shouldShowEveningHabit = true
                                }
                            }
                        }else{
                            if SettingsManagerObject.isPasswordRequireInSkipEvening{
                                shouldShowEveningHabit = true
                            }
                        }
                    }
                }
                
                if shouldShowEveningHabit{
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
                        }else if shutOffTimeVcObj != nil{
                            if shutOffTimeVcObj!.boxUpEarly.isHidden && shutOffTimeVcObj!.step == 0{
                                shutOffTimeVcObj?.checkUpEarlyTime()
                            }
                        }
                    }else{
                        if let date = UserDefaults.standard.object(forKey: kUserdefaultsShutdownAborted) as? Date{
                            if Date().compare(date) == .orderedDescending {
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
                            }
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
                                    showNaturalBreakDetectionWindow(duration:idleTimeValue)
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
                            if Date().compare(startDate) == .orderedAscending {// current date < start date(current date is 1 am and start date is 10 am )
                                startDate = Calendar.current.date(byAdding: .day, value: -1, to: startDate) ?? startDate
                            }
                            
                            // if alldays array is blank then we do not write date in userdefaults(and checkLastHabitShowDate func will not call so no need to write date  )
                            if arrAllDaysMorningHabits.count == 0 {//  state bhi change krenge na currentState = ._NOTHING_
                                //                print("arr AllMorningHabits count is 0:-  skip morning habit")
                                isHabitAlreadyShowed = true
                                unfocusedTime = 0
                                if !isMainWindowLoaded{
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
                                arrPreFilteredMorningHabits.removeAll()
                                let currentWeekDay = Date().dayOfWeek()
                                
                                for habit in arrAllDaysMorningHabits{
                                    if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                                        arrFilteredMorningHabits.append(habit)
                                    }else if habit.days_of_week.contains(where: {$0.compare("weekdays", options: .caseInsensitive) == .orderedSame}) {
                                        if !currentWeekDay.localizedCaseInsensitiveContains("sat") && !currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                    }else if habit.days_of_week.contains(where: {$0.compare("weekend", options: .caseInsensitive) == .orderedSame}) {
                                        if currentWeekDay.localizedCaseInsensitiveContains("sat") || currentWeekDay.localizedCaseInsensitiveContains("sat"){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                    }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                
                                if arrFilteredMorningHabits.count == 0 {
                                    //                print("arr arrFilteredMorningHabits count is 0:-  skip morning habit")
                                    isHabitAlreadyShowed = true
                                    unfocusedTime = 0
                                    if !isMainWindowLoaded{
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
                                if isFocusModeOnOrPaused(){
                                    addLog(text: "isFocusModeOnOrPaused True: focusModeFinished.")
                                    self.focusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: true)
                                    return;
                                }
                                
                                //--------------------------------------------------------------------//
                                //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
                                //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
                                isActivitiesReducedInExpiredApp = false
                                if isExpired{
                                    if arrFilteredMorningHabits.count > activitiesCountInExpireApp{
                                        isActivitiesReducedInExpiredApp = true
                                        let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                                        arrFilteredMorningHabits.removeAll()
                                        for i in 0..<activitiesCountInExpireApp{
                                            arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                                        }
                                    }
                                }
                                //----------------------------------------------------------------------//
                                self.isProcessingHabitRoutine = true//after this line this should be false
                                
                                
                                
                                addLog(text: "get Last Activity Info")
                                
                                if isMainWindowLoaded{// if main window is visible show loader
                                    if mainWindowControllerObj?.window?.isVisible ?? false{
                                        mainViewControllerObj?.showLoaderView()
                                    }
                                }
                                allApiObject.getLastActivityInfo(completionHandler: { json in
                                    DispatchQueue.main.async {
                                        if isMainWindowLoaded{// if main window is visible show loader
                                            if mainWindowControllerObj?.window?.isVisible ?? false{
                                                mainViewControllerObj?.removeSubViews()
                                            }
                                        }
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

                                                                    if activityStartDate.compare(startDate) == .orderedDescending{
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
                                                                        addLog(text: "morning habit already shown for today - reason (backend return last_completed_sequence_started_at after morning routine start time)")
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
                                                                    
                                                                    
                                                                    
                                                                    if activityAssignedDate.compare(startDate) == .orderedDescending{//if activityAssignedDate > startDate
                                                                        // morning activity start hui thi lekin puri nahi hui hai
                                                                        if habitSequenceID == sequenceId{
                                                                            //                print("current_activity_sequence is pending")
                                                                            addLog(text: "morning habit sequnce is pending. start from current pending habit")
                                                                            self.isProcessingHabitRoutine = false
                                                                            var skippedActivities = [String]()
                                                                            if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
                                                                                skippedActivities = activities
                                                                            }//current_sequence_completed_activities
                                                                            
                                                                            var completedActivities = [String]()
                                                                            if let activities = json?.value(forKey: "current_sequence_completed_activities") as? [String]{
                                                                                completedActivities = activities
                                                                            }
                                                                            self.startHabitsCall(activityId: activityId, skippedActivities:skippedActivities, completedActivities: completedActivities)
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
                                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                                                self.isProcessingHabitRoutine = false
                                                                            }
                                                                        })
                                                                    }
                                                                    
                                                                }
                                                            }else{
                                                                addLog(text: "start new morning routine sequence:- current sequence Id or current activity Id not found")
                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                                self.isProcessingHabitRoutine = false
                                                            }
                                                        }else{
                                                            addLog(text: "start new morning routine sequence:- current_activity not found as dictionary")// ktyaa krna chahiye yha
                                                            
                                                            var isForToday = false
                                                            if activityAssignedDate.compare(startDate) == .orderedDescending{
                                                                isForToday = true
                                                            }
                                                            if let sequenceId = currentActivitySequence.value(forKey: "id") as? String{
                                                                addLog(text: "pending routin is not for use clean all running sequence")
                                                                allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: isForToday, completionHandler: {json in
                                                                    
                                                                    
                                                                    DispatchQueue.main.async {
                                                                        addLog(text: "start new morning routine sequence")
                                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                                        self.isProcessingHabitRoutine = false
                                                                    }
                                                                })
                                                            }else{
                                                                addLog(text: "start new morning routine sequence")
                                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                                self.isProcessingHabitRoutine = false
                                                            }
                                                        }
                                                    }else{
                                                        addLog(text: "start new morning routine sequence:- current_activity_sequence not found as dictionary")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                        self.isProcessingHabitRoutine = false
                                                    }
                                                }else{
                                                    addLog(text: "start new morning routine sequence:- can't create Date object from current_activity_assigned_at")
                                                    self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                            }else{
                                                addLog(text: "start new morning routine sequence :- current_activity_assigned_at not found :- \(json!)")
                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                self.isProcessingHabitRoutine = false
                                            }
                                        }else{
                                            addLog(text: "func backgrounThread:- Last Activity Info is nil, search is there any habit done info found in local userdefauts")
                                            if let date = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitsStartedDate) as? Date{
                                                
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
                                                                    self.startHabitsCall(activityId: arrFilteredMorningHabits[i+1].id, skippedActivities:[], completedActivities: [])
                                                                }
                                                                
                                                                return;
                                                            }
                                                        }
                                                        
                                                        addLog(text: "start new morning routine sequence Last Habit id is not from morning habit")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                        self.isProcessingHabitRoutine = false
                                                        
                                                    }else{
                                                        addLog(text: "start new morning routine sequence:- Last Habit id is nil")
                                                        self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                        self.isProcessingHabitRoutine = false
                                                    }
                                                }else{
                                                    addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is not from current day")
                                                    self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                            }else
                                            {
                                                addLog(text: "start new morning routine sequence:- LastHabitsStartedDate is nil")
                                                self.startHabitsCall(activityId: nil, skippedActivities:[], completedActivities: [])
                                                self.isProcessingHabitRoutine = false
                                            }
                                            
                                        }
                                    }
                                }
                                )
                            }
                            
                            //***********************************************************//
                            
                            // return;
                            
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
            
        }
    }
    var timerHighPriorityHabitTime:Timer?
    
    func startTimerAlertHighPriorityHabit(durationSeconds:Int) {
        self.timerHighPriorityHabitTime = nil
        DispatchQueue.global().sync {
            self.timerHighPriorityHabitTime = Timer.scheduledTimer(timeInterval: TimeInterval(durationSeconds), target: self, selector: #selector(self.performTimerHighPriorityHabit), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerHighPriorityHabitTime!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerHighPriorityHabit() {
        self.timerHighPriorityHabitTime?.invalidate()
        self.timerHighPriorityHabitTime = nil
        NSApp.stopModal()
    }

    @objc func shutOffMac(){
        isHabitAlreadyShowed = false
        addLog(text: "Initiating shut off process.")
        
        //    (Mic/camera shouldn't prevent shutdown #62)
        if UserDefaults.standard.object(forKey: kUserdefaultsShutOffCancelledForEveningRoutine) == nil{
            if (currentState == ._EVENING_HABIT_ && currentAction == ._START_) || currentState == ._FOCUS_SUMMARY_{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                let hoursToAllowUserToDoHabitsBeforeMorningHabitTime = 4
                var fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
                let curreentDate = Date()
                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate) ?? startDate
                    fourHourBeforeStartTime = startDate.addingTimeInterval(TimeInterval((0-hoursToAllowUserToDoHabitsBeforeMorningHabitTime) * 60 * 60))
                }
                if curreentDate > fourHourBeforeStartTime{
                    if currentState == ._FOCUS_SUMMARY_{
                        addLog(text: "Focus summary aborted. reason:- four hours remaining in start morning routines.")
                        if curreentDate > shutOffdate{// iska matlab 20-24 k bich
                            let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
                        }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
                            UserDefaults.standard.set(startDate, forKey: kUserdefaultsFocusSummaryShowedTillDate)
                        }
                        currentState = ._NOTHING_
                        focusSummaryVcObj?.viewVisibleCount = 0
                    }

                    currentHabitIndex = -1
    //                if curreentDate > shutOffdate{// iska matlab 20-24 k bich
    //                    let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    //                    let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)
    //                    UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
    //                }else if curreentDate < startDate{ //  iska mtlb 1 se 10 k bich ka time
    //                    UserDefaults.standard.set(startDate, forKey: kUserdefaultsEveningHabitsShowedTillDate)
    //                }
                    addLog(text: "Evening routine aborted. reason:- four hours remaining in start morning routines and evening routine is not started yet.")
                    
                    
                    if !(mainWindowControllerObj?.window!.isVisible)! {
                        mainWindowControllerObj?.showWindow(self)
                        showBlankWindowInSecondaryMonitor()
                    }
                    mainViewControllerObj!.shutOffMac()
                    return;
                }
            }
        }
        
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
                            let alertHighPriorityHabitTime = NSAlert()
                            alertHighPriorityHabitTime.setSharingType()
                            var cutOffTimePassedText = "Running low on time - let's just focus on the high priority habits for the rest of the evening."
                            var cutOffTimePassedsubTitle = "Your high priority habits will start after 5 seconds."
                            if let common = configjson.value(forKey: "common") as? NSDictionary{
                                cutOffTimePassedText = common.value(forKey: "cutOffTimePassedText") as? String ?? cutOffTimePassedText
                                cutOffTimePassedsubTitle = common.value(forKey: "cutOffTimePassedsubTitle") as? String ?? cutOffTimePassedsubTitle
                            }
                            alertHighPriorityHabitTime.messageText = cutOffTimePassedText
                            alertHighPriorityHabitTime.informativeText = cutOffTimePassedsubTitle
                            alertHighPriorityHabitTime.addButton(withTitle: buttonOkText)
                            
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            self.startTimerAlertHighPriorityHabit(durationSeconds: 5)
                            alertHighPriorityHabitTime.runModal()
                            //                            currentState = ._NOTHING_
                            isHighPrioritySequenceGoing = true
                            mainWindowControllerObj?.showWindow(self)
                            showBlankWindowInSecondaryMonitor()
                            
                            mainViewControllerObj?.showThirdVc()
                            thirdVcObj?.eveningHabitSkipped()
                        }else{
                            if let cutOffTime = arrFilteredEveningHabits[currentHabitIndex].cutOffTime{
                                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                                let currentDate = Date()
                                if currentDate > cutOffDate{
                                    abortAllProcess()
                                    if mainWindowControllerObj?.window?.isVisible ?? false{
                                        mainWindowControllerObj?.window?.close()
                                        hideBlankWindowInSecondaryMonitor()
                                    }
                                    let alertHighPriorityHabitTime = NSAlert()
                                    alertHighPriorityHabitTime.setSharingType()
                                    var cutOffTimePassedForHabitText = "It's past the cutoff time you set for this habit. Taking you to your next habit."
                                    
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        cutOffTimePassedForHabitText = common.value(forKey: "cutOffTimePassedForHabitText") as? String ?? cutOffTimePassedForHabitText
                                    }
                                    alertHighPriorityHabitTime.messageText = cutOffTimePassedForHabitText
                                    alertHighPriorityHabitTime.addButton(withTitle: buttonOkText)
                                    
                                    NSApplication.shared.activate(ignoringOtherApps: true)
                                    self.startTimerAlertHighPriorityHabit(durationSeconds: 5)
                                    alertHighPriorityHabitTime.runModal()
                                    isHighPrioritySequenceGoing = true
                                    mainWindowControllerObj?.showWindow(self)
                                    showBlankWindowInSecondaryMonitor()
                                    
                                    mainViewControllerObj?.showThirdVc()
                                    thirdVcObj?.eveningHabitSkipped()
                                }
                            }
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
        
        abortAllProcess()
        if isFocusModeOnOrPaused(){
            focusModeFinished(isSilent: false, isShutOffTime: true, isMorningRoutineTime: false)
            return;
        }
        
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
    func showEveningHabit(activityId: String?, skippedActivities:[String], completedActivities:[String]){
        additionalHabitTotalCompletedSeconds = 0
        if activityId != nil{
            let arrTempFilteredEveningHabits = arrFilteredEveningHabits
            arrFilteredEveningHabits.removeAll()
            
            var isActivityFound = false
            for i in 0..<arrTempFilteredEveningHabits.count{
                
                if arrTempFilteredEveningHabits[i].id == activityId!{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                    isActivityFound = true
                }else if isActivityFound{
                    if !completedActivities.contains(arrTempFilteredEveningHabits[i].id){
                        arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                    }else{
                        if !skippedActivities.contains(arrTempFilteredEveningHabits[i].id){
                            if arrTempFilteredEveningHabits[i].useTimer{
                                additionalHabitTotalCompletedSeconds += arrTempFilteredEveningHabits[i].durationSeconds
                            }
                        }
                    }
                }else{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                }
                
            }
        }
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
            arrPreFilteredEveningHabits = arrFilteredEveningHabits
            
            //  //Let user temporarily customise routine before starting#938
            let currentDate = Date()
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                    if lastSavedSequenceId == arrPreFilteredEveningHabits[0].activity_sequence_id && date.compare(currentDate) == .orderedDescending{
                        
                        
                        if arrHabitIds.count != 0{
                            arrFilteredEveningHabits.removeAll()
                            
                            for habit in arrPreFilteredEveningHabits{
                                if arrHabitIds.contains(habit.id){
                                    arrFilteredEveningHabits.append(habit)
                                }
                            }
                            if arrFilteredEveningHabits.count == 0{
                                arrFilteredEveningHabits = arrPreFilteredEveningHabits
                            }
                        }else{
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                        }
                    }
                }
            }
            //
            
            mainViewControllerObj!.showAllEveningHabits()
        }else{
            
            arrPreFilteredEveningHabits = arrFilteredEveningHabits
            //  //Let user temporarily customise routine before starting#938
            let currentDate = Date()
            if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                    if lastSavedSequenceId == arrPreFilteredEveningHabits[0].activity_sequence_id && date.compare(currentDate) == .orderedDescending{
                        
                        if arrHabitIds.count != 0{
                            arrFilteredEveningHabits.removeAll()
                            
                            var isActivityFound = false
                            for habit in arrPreFilteredEveningHabits{
                                if habit.id == activityId!{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredEveningHabits.append(habit)
                                    }
                                    isActivityFound = true
                                }else if isActivityFound{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredEveningHabits.append(habit)
                                    }
                                }else{
                                    arrFilteredEveningHabits.append(habit)
                                }
                            }
                            
                            if arrFilteredEveningHabits.count == 0{
                                arrFilteredEveningHabits = arrPreFilteredEveningHabits
                            }
                        }else{
                            UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                        }
                    }
                }
            }
            //

            
            var isActivityFound = false
            for i in 0..<arrFilteredEveningHabits.count{
                if arrFilteredEveningHabits[i].id == activityId!{
                    isActivityFound = true
                    if i == 0{
                        mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false, skippedActivities:skippedActivities, completedActivities:completedActivities)
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
                            
                            mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: false, skippedActivities:skippedActivities, completedActivities:completedActivities)
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
                            mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: i, isLastActivitySkipped: isLastActivitySkipped, skippedActivities:skippedActivities, completedActivities:completedActivities)
                        }
                    }
                    break;
                }
            }
            if !isActivityFound{
                addLog(text: "func showEveningHabit:- current activity id from actiity props not found in habit list.")
                //******************************************************************//
                //Doing this because if current habit id is not in selected habits list then we will found next habit to do according to selected list and if we can't find any current habit then show all habits
                var lastActivityFoundIndex = -1
                var isLastActivitySkipped = false
                for i in 0..<arrFilteredEveningHabits.count{
                    if completedActivities.contains(arrFilteredEveningHabits[i].id){
                        lastActivityFoundIndex = i+1// start next habit
                        if skippedActivities.contains(arrFilteredEveningHabits[i].id){
                            isLastActivitySkipped = true
                        }else{
                            isLastActivitySkipped = false
                        }
                    }
                }
                if lastActivityFoundIndex == -1{
                    mainViewControllerObj!.showAllEveningHabits()
                }else{
                    mainViewControllerObj!.startDirectIncompleteEveningHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped, skippedActivities:skippedActivities, completedActivities:completedActivities)
                }
                
                
                
            }
        }
        
    }
    var isNoHighPriorityActivityAlertVisible = false
    func processEveningHabit(){
        if isNoHighPriorityActivityAlertVisible{
            return;
        }
        arrFilteredEveningHabits.removeAll()
        let currentWeekDay = Date().dayOfWeek()
        
        for habit in arrAllDaysEveningHabits{
            if let cutOffTime = habit.cutOffTime{
                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime.hour, minute: cutOffTime.minute, second: cutOffTime.second, of: Date())!
                let currentDate = Date()
                if currentDate > cutOffDate{
                    continue;
                }
            }
            if habit.days_of_week.contains(where: {$0.compare("all", options: .caseInsensitive) == .orderedSame}) {
                arrFilteredEveningHabits.append(habit)
            }else if habit.days_of_week.contains(where: {$0.compare("weekdays", options: .caseInsensitive) == .orderedSame}) {
                if !currentWeekDay.localizedCaseInsensitiveContains("sat") && !currentWeekDay.localizedCaseInsensitiveContains("sat"){
                    arrFilteredEveningHabits.append(habit)
                }
            }else if habit.days_of_week.contains(where: {$0.compare("weekend", options: .caseInsensitive) == .orderedSame}) {
                if currentWeekDay.localizedCaseInsensitiveContains("sat") || currentWeekDay.localizedCaseInsensitiveContains("sat"){
                    arrFilteredEveningHabits.append(habit)
                }
            }else if habit.days_of_week.contains(where: {$0.compare(currentWeekDay, options: .caseInsensitive) == .orderedSame}) {
                arrFilteredEveningHabits.append(habit)
            }
        }
        
        //--------------------------------------------------------------------//
        //After the 7 day free trial, let's allow users to downgrade to Free Basic.//Support freemium#1066
        //if ap is expired max 5 habits in the morning and evening routines (if the user has more than 5, only show the first 5)#1066
        isActivitiesReducedInExpiredApp = false
        if isExpired{
            if arrFilteredEveningHabits.count > activitiesCountInExpireApp{
                isActivitiesReducedInExpiredApp = true
                let arrTempFilteredEveningHabits = arrFilteredEveningHabits
                arrFilteredEveningHabits.removeAll()
                for i in 0..<activitiesCountInExpireApp{
                    arrFilteredEveningHabits.append(arrTempFilteredEveningHabits[i])
                }
            }
        }
        //----------------------------------------------------------------------//
        if arrFilteredEveningHabits.count != 0{
            if cutOffTime != nil{
                let cutOffDate = Calendar.current.date(bySettingHour: cutOffTime!.hour, minute: cutOffTime!.minute, second: cutOffTime!.second, of: Date())!
                let currentDate = Date()
                if currentDate > cutOffDate{

                    let tempHabits = arrFilteredEveningHabits
                    arrFilteredEveningHabits.removeAll()
                    for i in 0..<tempHabits.count{
                        if tempHabits[i].isPriorityHigh{
                            arrFilteredEveningHabits.append(tempHabits[i])
                        }
                    }

                    if arrFilteredEveningHabits.count == 0{
                        abortAllProcess()
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            mainWindowControllerObj?.window?.close()
                            hideBlankWindowInSecondaryMonitor()
                        }
                        isNoHighPriorityActivityAlertVisible = true
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
                        isNoHighPriorityActivityAlertVisible = false
                        

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

                }
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
            var shutoffDate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            if Date().compare(shutoffDate) == .orderedAscending{//<  check for after 12 am 
                shutoffDate = Calendar.current.date(byAdding: .day, value: -1, to: shutoffDate) ?? shutoffDate
            }
            addLog(text: "get Last Activity Info process Evening Habit")
            if isMainWindowLoaded{// if main window is visible show loader
                if mainWindowControllerObj?.window?.isVisible ?? false{
                    mainViewControllerObj?.showLoaderView()
                }
            }
            allApiObject.getLastActivityInfo(completionHandler: { json in
                DispatchQueue.main.async {
                    
                    if isMainWindowLoaded{// if main window is visible show loader
                        if mainWindowControllerObj?.window?.isVisible ?? false{
                            mainViewControllerObj?.removeSubViews()
                        }
                    }
                    if json != nil{
                        
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
                                                    // evening activity started but not completed
                                                    
                                                    if habitSequenceID == sequenceId{
                                                        //                print("current evening routine sequence is pending")
                                                        addLog(text: "current evening routine sequence is pending")
                                                        self.isProcessingHabitRoutine = false
                                                        var skippedActivities = [String]()
                                                        if let activities = json?.value(forKey: "current_sequence_skipped_activities") as? [String]{
                                                            skippedActivities = activities
                                                        }
                                                        var completedActivities = [String]()
                                                        if let activities = json?.value(forKey: "current_sequence_completed_activities") as? [String]{
                                                            completedActivities = activities
                                                        }
                                                        self.showEveningHabit(activityId: activityId, skippedActivities: skippedActivities, completedActivities: completedActivities)
                                                    }else{
                                                        
                                                        addLog(text: "pending routine is not evening routine - \(sequenceId)")
                                                        allApiObject.forceCompleteCurrentSequence(activity_sequence_id: sequenceId, isForToday: true, completionHandler: {json in
                                                            // and strt break activity
                                                            DispatchQueue.main.async {
                                                                addLog(text: "start new evening routine sequence")
                                                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
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
                                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                                            self.isProcessingHabitRoutine = false
                                                        }
                                                    })
                                                }
                                            }
                                            
                                        }else{
                                            addLog(text: "start new evening routine sequence:- current sequence Id or current activity Id not found")
                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
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
                                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                                    self.isProcessingHabitRoutine = false
                                                }
                                            })
                                            
                                        }else{
                                            addLog(text: "start new evening routine sequence")
                                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                            self.isProcessingHabitRoutine = false
                                        }
                                    }
                                }else{
                                    addLog(text: "start new evening routine sequense:- current_activity_sequence not found as dictionary")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                }
                            }else{
                                addLog(text: "start new evening routine sequence:- can't create Date object from current_activity_assigned_at")
                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                self.isProcessingHabitRoutine = false
                            }
                        }else{
                            addLog(text: "start new evening routine sequence :- current_activity_assigned_at not found :- \(json!)")
                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
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
                                            self.showEveningHabit(activityId: arrFilteredEveningHabits[i+1].id, skippedActivities:[], completedActivities: [])
                                            return;
                                        }
                                    }
                                    
                                    addLog(text: "start new evening routine sequence:- Last Habit id is not from evening habit")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                    
                                }else{
                                    addLog(text: "start new evening routine sequence:- Last Habit id is nil")
                                    self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                    self.isProcessingHabitRoutine = false
                                }
                            }else{
                                addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is not from current day")
                                self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
                                self.isProcessingHabitRoutine = false
                            }
                        }else{
                            addLog(text: "start new evening routine sequence:- LastHabitsStartedDate is nil")
                            self.showEveningHabit(activityId: nil, skippedActivities: [], completedActivities: [])
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
                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
                        arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
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
                        
                        if relaxModeWcObj != nil{
                            if relaxModeWcObj!.window?.isVisible ?? false{
                                getRelaxModeVcObject().closeTimerBox()
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
                                dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
                                arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
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
                                if relaxModeWcObj != nil{
                                    if relaxModeWcObj!.window?.isVisible ?? false{
                                        getRelaxModeVcObject().closeTimerBox()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //skipped activities will always there in completed activities
    @objc func startHabitsCall(activityId:String?, skippedActivities:[String], completedActivities:[String]){
        addLog(text: "Initiating morning habits.")
        additionalHabitTotalCompletedSeconds = 0
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
        checkTrialExpire()
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
                arrPreFilteredMorningHabits = arrFilteredMorningHabits
                //  //Let user temporarily customise routine before starting#938
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                
                if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                    if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                        if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && date.compare(startDate) == .orderedDescending{
                            if arrHabitIds.count != 0{
                                arrFilteredMorningHabits.removeAll()
                                
                                for habit in arrPreFilteredMorningHabits{
                                    if arrHabitIds.contains(habit.id){
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                if arrFilteredMorningHabits.count == 0{
                                    arrFilteredMorningHabits = arrPreFilteredMorningHabits
                                }
                            }else{
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                            }
                        }
                    }
                }
                //
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                mainViewControllerObj!.showAllMorningHabits()
            }else{
                let arrTempFilteredMorningHabits = arrFilteredMorningHabits
                arrFilteredMorningHabits.removeAll()
                
                var isActivityFound = false
                for i in 0..<arrTempFilteredMorningHabits.count{
                    
                    if arrTempFilteredMorningHabits[i].id == activityId!{
                        arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                        isActivityFound = true
                    }else if isActivityFound{
                        if !completedActivities.contains(arrTempFilteredMorningHabits[i].id){
                            arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                        }else{
                            if !skippedActivities.contains(arrTempFilteredMorningHabits[i].id){
                                if arrTempFilteredMorningHabits[i].useTimer{
                                    additionalHabitTotalCompletedSeconds += arrTempFilteredMorningHabits[i].durationSeconds
                                }
                            }
                        }
                    }else{
                        arrFilteredMorningHabits.append(arrTempFilteredMorningHabits[i])
                    }
                    
                }
                
                arrPreFilteredMorningHabits = arrFilteredMorningHabits
                //  //Let user temporarily customise routine before starting#938
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                if let infoDic = UserDefaults.standard.object(forKey: kUserdefaultsLastSequenceSelectHabitsInfo) as? [String:Any]{
                    if let lastSavedSequenceId =  infoDic["sequenceId"] as? String, let arrHabitIds =  infoDic["arrHabitIds"] as? [String], let date =  infoDic["date"] as? Date{
                        if lastSavedSequenceId == arrFilteredMorningHabits[0].activity_sequence_id && date.compare(startDate) == .orderedDescending{
                            if arrHabitIds.count != 0{
                                arrFilteredMorningHabits.removeAll()
                                var isActivityFound = false
                                for habit in arrPreFilteredMorningHabits{
                                    if habit.id == activityId!{
                                        if arrHabitIds.contains(habit.id){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                        isActivityFound = true
                                    }else if isActivityFound{
                                        if arrHabitIds.contains(habit.id){
                                            arrFilteredMorningHabits.append(habit)
                                        }
                                    }else{
                                        arrFilteredMorningHabits.append(habit)
                                    }
                                }
                                if arrFilteredMorningHabits.count == 0{
                                    arrFilteredMorningHabits = arrPreFilteredMorningHabits
                                }
                            }else{
                                UserDefaults.standard.removeObject(forKey: kUserdefaultsLastSequencePostponeInfo)
                            }
                        }
                    }
                }
                //
                
                
                
                mainWindowControllerObj?.showWindow(self)
                showBlankWindowInSecondaryMonitor()
                isActivityFound = false
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
                 
                    //******************************************************************//
                    //Doing this because if current habit id is not in selected habits list then we will found next habit to do according to selected list and if we can't find any current habit then show all habits
                    var lastActivityFoundIndex = -1
                    var isLastActivitySkipped = false
                    for i in 0..<arrFilteredMorningHabits.count{
                        if completedActivities.contains(arrFilteredMorningHabits[i].id){
                            lastActivityFoundIndex = i+1// start next habit
                            if skippedActivities.contains(arrFilteredMorningHabits[i].id){
                                isLastActivitySkipped = true
                            }else{
                                isLastActivitySkipped = false
                            }
                        }
                    }
                    if lastActivityFoundIndex == -1{
                        mainViewControllerObj!.showAllMorningHabits()
                    }else{
                        mainViewControllerObj!.startDirectIncompleteMorningHabitAtIndex(index: lastActivityFoundIndex, isLastActivitySkipped:isLastActivitySkipped)
                    }
                    
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
        if isExpired{
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
        
        if shouldAskPassword(){
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = 0
                
                if SettingsManagerObject.isPasswordRequireInChangeSettings{
                    tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                    tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                    getEnterPasswordVcObjForPreferences().parentVc = nil
                    enterPasswordVcObjForPreferences?.removeConstraints()
                    addLog(text: "Showing enter password view")
                }
            }
        }else{
            if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                tabview.selectedTabViewItemIndex = 0
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
    
    @objc func quitAppForUser(){
        sharedDefaults?.setValue(Date(), forKeyPath: kUserdefaultsAppQuitForUser)
        sharedDefaults?.synchronize()
        
        let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
        DistributedNotificationCenter.default().post(name: mainAppQuitByUser,object: mainAppBundelId)
        menuItem_Quit()
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
                
                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        sharedDefaults?.removeObject(forKey: kUserdefaultsSharedAccessToken)
                        sharedDefaults?.setValue(globalUUID, forKeyPath: kUserdefaultsSharedUserId)
                        sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsOnboardingIncompleted)
                        sharedDefaults?.setValue(Date(), forKeyPath: kUserdefaultsAppQuitForUser)
                        sharedDefaults?.synchronize()
                        
                        let mainAppQuitByUser = Notification.Name("MainAppQuitByUser")
                        DistributedNotificationCenter.default().post(name: mainAppQuitByUser,object: mainAppBundelId)
                    }
                }
                return .terminateNow// quit without login check here
            }
            if self.user == nil{
                return .terminateNow
            }
            addLog(text: "[user-action] menu item Quit clicked from dock or activity monitor")
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
        print("applicationShouldHandleReopen")
        return false
    }
    
    // did this because we user closes last window than app should  deactivate beacuse we need to show popover if user clicks on dock icon and if app is allready active we cant get actual state of dock icon click that's why we are doing this.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("applicationShouldTerminateAfterLastWindowClosed")
        addLog(text: "applicationShouldTerminateAfterLastWindowClosed")
        if popover.isShown{
            return false
        }
        for window in NSApp.windows{// sometimes nsalert visible but app
            if window.isModalPanel{
                return false
            }
        }
        if NSApp.isActive{
            addLog(text: "hide app")
            addLog(text: "hide app")
            NSApp.hide(self)
        }
        return false
    }
    // didnot do this work in applicationShouldHandleReopen because applicationShouldHandleReopen calls again and aain if reload after force quit setting is enabled
    func applicationDidBecomeActive(_ notification: Notification) {
        if blankLayerWcObj != nil{
            if blankLayerWcObj?.window != nil{
                if blankLayerWcObj!.window!.isVisible{
                    return;
                }
            }
        }
        var isAnyStanderdWindowVisible = false
        
        for win in NSApp.windows{
            if win.isVisible && win.hasTitleBar{
                isAnyStanderdWindowVisible = true
            }
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

        makeAllAlertWindowToTopLevelWindow()
        
        if endingFocusWindowControllerObj != nil{
            if (endingFocusWindowControllerObj?.window?.isVisible ?? false) && endingFocusWindowControllerObj?.contentViewController == focusCompletedVcObj{
                focusCompletedVcObj?.setTimerMoveWindowToCenter()
            }
        }
        
    }
    func makeAllAlertWindowToTopLevelWindow(){
        for window in NSApp.windows{
            if window.isModalPanel{
                window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
            }
        }
    }
    
    @objc func showAlertOnboardingVideo(){
        let alert = NSAlert()
        alert.setSharingType()
        var messageText = "You'll be able to use the Focus Bear menu as soon as you have finished watching the onboarding video."
        addLog(text: "show Alert Onboarding Video")
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            messageText = common.value(forKey: "alertOnboardingVideoText") as? String ?? messageText
        }
        alert.messageText = messageText
        alert.addButton(withTitle: buttonOkText)
        alert.runModal()
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
            addLog(text: "top Icon Clickd")
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
        if taskPlayerWcObj != nil{
            if taskPlayerWcObj?.window?.isVisible ?? false{
                taskPlayerVcObj?.getToDosFromPlayer()
                taskPlayerWcObj?.window?.close()
                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
            }
        }
        setAppIconForFocusModeScore(probability: nil)
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
        if focusEndWarningWcObj != nil{
            if focusEndWarningWcObj?.window?.isVisible ?? false{
                focusEndWarningWcObj?.window?.close()
            }
        }
        if savedSitesForLaterWcObj != nil{
            if savedSitesForLaterWcObj!.window?.isVisible ?? false{
                savedSitesForLaterWcObj!.close()
            }
        }
        if isFocusModeOn(){// is is paused then already calculated
            let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
            focusModeActualDurationPerformed += totalSeconds
        }
        focusModeFinishedCapturePosthog()
        var currentFocusModeId = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true || arrFocusType[i]["isPaused"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                arrFocusType[i]["isPaused"] = false
                currentFocusModeId = arrFocusType[i]["id"] as? String ?? ""
                if isDndEnabled{
                    disableDND()
                }
                workAfterFocusBegin(index: i)
                break;
            }
        }
        
        isFocusModeRunning = false
        
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.focusModeFinished()
                }
            }
        }
        allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), rating:nil, completionHandler: {newDic in
            DispatchQueue.main.async {
                
            }
        })
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
            //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString:nil)
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
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
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
        focusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false)
    }
    
    func focusModeFinishedCapturePosthog(){
        let focusDurationMinutes = focusModeActualDurationPerformed / 60
        if isMeetingsFocusStartedAutomatically{
            allApiObject.capturePosthog(event: "completed-meetings-focus-mode", metadata: [:])
        }else if isFocusModeStartedFromPomodoroMode{
            if isFocusModeStartedAutomatically{
                allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"automated_focus", "focusDurationMinutes":focusDurationMinutes])
            }else{
                allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"pomodoro", "focusDurationMinutes":focusDurationMinutes])
            }
        }else{
            allApiObject.capturePosthog(event: "completed-focus-session", metadata: ["focus-type":"manual_focus", "focusDurationMinutes":focusDurationMinutes])
        }
    }
    
    @objc func focusModeFinished(isSilent:Bool, isShutOffTime:Bool, isMorningRoutineTime:Bool){
        addLog(text: "focus mode finished")
        if taskPlayerWcObj != nil{
            if taskPlayerWcObj?.window?.isVisible ?? false{
                taskPlayerVcObj?.getToDosFromPlayer()
                taskPlayerWcObj?.window?.close()
                allApiObject.capturePosthog(event: "todo-player-popup-closed", metadata: [:])
            }
        }
        setAppIconForFocusModeScore(probability: nil)
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
        if focusEndWarningWcObj != nil{
            if focusEndWarningWcObj?.window?.isVisible ?? false{
                focusEndWarningWcObj?.window?.close()
            }
        }
        if savedSitesForLaterWcObj != nil{
            if savedSitesForLaterWcObj!.window?.isVisible ?? false{
                savedSitesForLaterWcObj!.close()
            }
        }
        if isFocusModeOn(){// is is paused then already calculated
            let totalSeconds = Int(Date().timeIntervalSince(startFocusModeTimeForPauseAndResume ?? Date()))
            focusModeActualDurationPerformed += totalSeconds
        }
        focusModeFinishedCapturePosthog()
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
                
                if isDndEnabled{
                    disableDND()
                }
                workAfterFocusBegin(index: i)
                break;
            }
        }
        
        isFocusModeRunning = false
        
        if timerForFocusMode != nil{
            timerForFocusMode?.invalidate()
        }
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
            
            self.setStatusBarButtonColorForFocusMode(color: NSColor.clear, colorString:nil)
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
            addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "Meeting using {\(self.appUsedInAutoMeetingFocusMode)}", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
            
            
            allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), rating:nil, completionHandler: {newDic in
                DispatchQueue.main.async {
                    
                }
            })
        }else{
            if isSilent{
                let timestamp = getStringFromDate(date: startFocusModeTime ?? Date(), dateFormat: "yyyy-MM-dd HH:mm:ss")
                addEntryInStatsCsv(logType: "focus block", activity: currentFocusModeName, durationInSeconds: "\(focusModeActualDurationPerformed)", quantityQuestion: "", quantityLogged: "", startTime: timestamp, workAchieved: "", distractionsEncountered: "", abortReason: "", feedback: "", tags:"")
                
                allApiObject.finishFocusMode(id: currentFocusModeId, achievements: "", distractions: "", finish_time: Date(), rating:nil, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
            }else if isShutOffTime{
                lastFocusModeTempInfo = nil
                
                DispatchQueue.main.async {
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
                    mainViewControllerObj!.showDayEndFocusCompletedView()
                    focusCompletedFullScreenVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: isShutOffTime)
                }
            }else if isMorningRoutineTime{
                lastFocusModeTempInfo = nil
                
                DispatchQueue.main.async {
                    if !(mainWindowControllerObj?.isWindowLoaded ?? false){
                        mainWindowControllerObj?.loadWindow()
                    }
                    mainViewControllerObj!.showMorningRoutineFocusCompletedView()
                    focusCompletedFullScreenVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: isShutOffTime)
                }
            }else{
                if arrAllowedAppsInCuddlyModeCurrentFocus.count != 0 || arrAllowedUrlsInCuddlyModeCurrentFocus.count != 0{
                    lastFocusModeTempInfo = lastFocusTempInfo(id: currentFocusModeId, arrAllowedAppsInCuddlyModeCurrentFocus: arrAllowedAppsInCuddlyModeCurrentFocus, arrAllowedUrlsInCuddlyModeCurrentFocus: arrAllowedUrlsInCuddlyModeCurrentFocus)
                }else{
                    lastFocusModeTempInfo = nil
                }
                
                DispatchQueue.main.async {
                    self.showFocusCompletedView()
                    focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName, currentFocusModeId: currentFocusModeId, finish_time: Date(), isShutOffTime: false)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    DispatchQueue.global().async {
                        DispatchQueue.main.async {
                            NSApplication.shared.activate(ignoringOtherApps: true)
                        }
                    }
                }
            }
        }
        self.isAutoMeetingsModeStarted = false
        self.appUsedInAutoMeetingFocusMode = ""
        
        
        arrBlockedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedAppsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedUrlsInCuddlyModeCurrentFocus.removeAll()
        arrBlockedUrlsInCuddlyModeCurrentFocus.removeAll()
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
        
        DispatchQueue.main.async {
            closePupUpBlockIfVisible()
        }
    }
    
    func showFocusCompletedView(){
        addLog(text: "show Focus Completed View")
        getEndFocusModeWindowControllerObj().contentViewController = focusCompletedVcObj
        getEndFocusModeWindowControllerObj().showWindow(self)
    }
    
    
    func setIntentionInBrainDumpWindow(){
        if brainDumpWcObj != nil{
            if brainDumpWcObj?.window != nil{
                brainDumpVcObj?.textViewIntention.isEditable = true
                if brainDumpWcObj!.window!.isVisible{
                    brainDumpVcObj?.textViewIntention.string = whatToAchieveInFocusBlock
                    if whatToAchieveInFocusBlock.isEmpty{
                        if !focusModeTaskString.isEmpty{
                            brainDumpVcObj?.textViewIntention.string = getFocusModeTaskString()
                            brainDumpVcObj?.textViewIntention.isEditable = false
                        }
                    }
                }
            }
        }
    }
    
    
    @objc func focusModeStartted(isStartedByPusher:Bool){
        addLog(text: "focus Mode Started called")
        isMeetingsFocusStartedAutomatically = false
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
        if !isStartedByPusher{
            if let startTime = startFocusModeTime, let endTime = endFocusModeTime{
                allApiObject.startFocusMode(id: getRunningFocusModeId(), intention: whatToAchieveInFocusBlock, start_time: startTime, finish_time: endTime, completionHandler: {newDic in
                    DispatchQueue.main.async {
                        
                    }
                })
            }
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
        
        
        
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                currentRunningFocusType = dic
                let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                addLog(text: "\(currentRunningFocusModeName) Started until - \(stringTime)")
            }
        }
        isFocusModeRunning = true
        if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
            if  isRelaxFocus{
                showSavedSitesForLaterWindowForBreaks()
            }
        }
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
            if shouldShowToolBoxWindow && SettingsManagerObject.isGeekModeEnabled{
                showToolboxWindow()
            }
        }
        arrFocusBlockNotificationShownForApps.removeAll()
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
        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus.removeAll()
        arrAllowedDomianInCuddlyModeCurrentFocus.removeAll()
        
        arrKeywordsToAllowInFocus.removeAll()
        arrAllowedTabTitlesInCuddlyModeCurrentFocus.removeAll()

//        fireFoxNotificationShownForCurrentFocusMode = false
    }
    
    
    var timerAllowUrl:Timer?
    var timerCheckAllowedApps:Timer?
    var timerAllowUrlForActivity:Timer?
    var timerAllowAppForActivity:Timer?
    var timerBlockUrl:Timer?//block urls list
    var timerForCheckUrlFromAiTimeOut:Timer?
    
    @objc func frontApplicationChanged(){
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool != nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) != nil{
                if !isSettingsLoddedInAppdelegate{
                    return;
                }
            }
        }
        
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if !tryBlockingVcShownInOnboarding{
                    return;
                }
            }
        }
        
//  if app is in shutoff state user can't use any app
        if currentState == ._SHUTOFFMAC_{
            if mainWindowControllerObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if !focusDefaultAllowApps.contains(nameLowercased) && nameLowercased != selfAppName.lowercased(){
                            exitFullScreen(runningApp:runningApp)
                            runningApp.hide()
                        }
                    }
                }
                return;
            }
        }
                
        timerBlockUrl?.invalidate()
        timerAllowUrlForActivity?.invalidate()
        currentBrowserUrlForAi = ""
        self.timerForCheckUrlFromAiTimeOut?.invalidate()
        // // close set Intention Blocked Urls window if front application changed////
        if setIntentionBlockedUrlsWcObj != nil{
            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            let pid = runningApp.processIdentifier
                            if setIntentionBlockedUrlsVcObj?.currentPid != pid{
                                setIntentionBlockedUrlsVcObj?.closeWindow()
                            }
                        }
                    }
                }
            }
        }
        
        
        // // close  Intention Blocked Urls window if front application changed////
        if intentionBlockedUrlsWcObj != nil{
            if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            let pid = runningApp.processIdentifier
                            if intentionBlockedUrlsVcObj?.currentPid != pid{
                                intentionBlockedUrlsWcObj?.window?.close()
                            }
                        }else{//focus bear
                            intentionBlockedUrlsVcObj?.setTimerHideWindow()
                        }
                    }
                }
            }
        }
        
        // // close  Intention Blocked Urls window if front application changed////
        if intentionBlockedAppsWcObj != nil{
            if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
                if let runningApp = NSWorkspace.shared.frontmostApplication{
                    if let appUrl = runningApp.bundleURL{
                        let name = appUrl.deletingPathExtension().lastPathComponent
                        let nameLowercased = name.lowercased()
                        if nameLowercased != selfAppName.lowercased(){
                            if let bundleURL = runningApp.bundleURL{
                                if intentionBlockedAppsVcObj!.blockedAppName != bundleURL.deletingPathExtension().lastPathComponent{
                                    intentionBlockedAppsWcObj?.window?.close()
                                }
                            }
                        }
                    }
                }
            }
        }
        //  ////////////////////////////////////////////////////////////////////////////
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent
                let nameLowercased = name.lowercased()
                if runningApp.bundleIdentifier != Bundle.main.bundleIdentifier{
                    if !arrExcludeAppsInBreaksBrainDumpLastActivateApp.contains(nameLowercased){
                        lastFrontMostApplication = runningApp
                    }
                }
                if nameLowercased == "firefox" && UserDefaults.standard.object(forKey: kUserdefaultsFirefoxPermissionShown) == nil{
                    showFirefoxPermissionWindow(showingFromOnboarding: false)
                }
            }
        }
        
        if currentState == ._EVENING_HABIT_ && currentRelaxHabitPlaying != nil && currentAction == ._INPROGRESS_{
            if currentRelaxHabitPlaying!.showSavedDistractingWebsites{
                return;
            }
        }
        
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    let localizedNameLowercased = runningApp.localizedName?.lowercased()
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
                                    let allowAppLowercased = appName.lowercased()
                                    if allowAppLowercased == nameLowercased || allowAppLowercased == localizedNameLowercased{
                                        isAppAllowed = true
                                        break;
                                    }
                                }
                                
                            }
                            
                            if !isAppAllowed{
                                exitFullScreen(runningApp:runningApp)
                                runningApp.hide()
                                allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
                                return
                            }
                            
                        }else{
                            let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                            let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                            let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                            let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                            focusModeCloseCurrentUrlForAlignmentScore()
                            
                            var isAppBlocked = false
                            if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentAppForAlignmentScore()
                                return;
                            }
                            for path in blockAppsPath{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    isAppBlocked = true
                                    break;
                                }
                            }
                            var isAllowedAppIsDefault = false
                            var isAppAllowedByAllowedAppList = false
                            if isAllowedAllAppsInFocus{
                                isAppAllowed = true
                                if nameLowercased == selfAppName.lowercased(){
                                    isSelfApp = true
                                    isAllowedAppIsDefault = true
                                }
                            }else{
                                
                                if nameLowercased == selfAppName.lowercased(){
                                    isSelfApp = true
                                    isAppAllowed = true
                                    isAllowedAppIsDefault = true
                                }else if focusDefaultAllowApps.contains(nameLowercased){//if nameLowercased == "finder" || nameLowercased == "universalaccessauthwarn"{
                                    isAppAllowed = true
                                    isAllowedAppIsDefault = true
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
                                                isAppAllowedByAllowedAppList = true
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            if isCuddlyModeEnabled(){
                                if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                                    isAppAllowed = true
                                }
                            }
                            
                            if !isAppAllowed{
                                var isAppAllowedByUser = false
                                let arrBlockedApps = getBlockedAppsToBlock()
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                        isAppAllowed = false
                                        if popUpBlockConfirmWcObj != nil{
                                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                                    popUpBlockConfirmVcObj?.closeWindow()
                                                }
                                            }
                                        }
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if !result{// it means not allowed by user(intention is not set)
                                            isAppAllowedByUser = true
                                            isAppAllowed = true
                                        }
                                        if !isAppAllowedByUser{
                                            self.closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        setFocusBearIconToNormal()
                                        focusModeCloseCurrentAppForAlignmentScore()
                                        return;
                                    }
                                }
                            }else{
                                if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                    let arrBlockedApps = getBlockedAppsToBlock()
                                    for path in arrBlockedApps{
                                        let url = URL(fileURLWithPath: path)
                                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                            if popUpBlockConfirmWcObj != nil{
                                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                                        popUpBlockConfirmVcObj?.closeWindow()
                                                    }
                                                }
                                            }
                                            let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                            if result{// it means not allowed by user(intention is not set)
                                                self.closeIntentionBlockedAppsWinddowIfVisible()
                                            }
                                            setFocusBearIconToNormal()
                                            focusModeCloseCurrentAppForAlignmentScore()
                                            return;
                                        }
                                    }
                                }
                            }
                            if isAppBlocked{
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true)
                                if self.timerAllowUrlForActivity != nil{
                                    self.timerAllowUrlForActivity!.invalidate()
                                }
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentAppForAlignmentScore()
                                return;
                            }else if !isAppAllowed{
                                focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name)
                                focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 0.0, isAppAllowedByAllowedAppList:false, appName: name)
                                return;
                            }else{
                                if isSelfApp{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                    return;
                                }
                                if isAllowedAppIsDefault{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                }else{
                                    focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 1.0, isAppAllowedByAllowedAppList:isAppAllowedByAllowedAppList, appName: name)
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
        }else if isFocusModeOn(){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                    let name = appUrl.deletingPathExtension().lastPathComponent
                    let nameLowercased = name.lowercased()
                    var isAppAllowed = false
                    var isSelfApp = false
                    
                    let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                    let allowAppsPath = currentRunningFocusType["allowed_apps"] as? [String] ?? []
                    let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                    let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                    if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
                        if  isRelaxFocus{
                            return;
                        }
                    }
                    focusModeCloseCurrentUrlForAlignmentScore()
                    var isAppBlocked = false
                    
                    if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                        setFocusBearIconToNormal()
                        focusModeCloseCurrentAppForAlignmentScore()
                        return;
                    }
                    for path in blockAppsPath{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                            isAppBlocked = true
                            break;
                        }
                    }
                    var isAllowedAppIsDefault = false
                    var isAppAllowedByAllowedAppList = false
                    if isAllowedAllAppsInFocus{
                        isAppAllowed = true
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                            isAllowedAppIsDefault = true
                        }
                    }else{
                        if nameLowercased == selfAppName.lowercased(){
                            isSelfApp = true
                            isAppAllowed = true
                            isAllowedAppIsDefault = true
                        }else if focusDefaultAllowApps.contains(nameLowercased){//if nameLowercased == "finder" || nameLowercased == "universalaccessauthwarn"{
                            isAppAllowed = true
                            isAllowedAppIsDefault = true
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
                                        isAppAllowedByAllowedAppList = true
                                        break;
                                    }
                                }
                            }
                            
                        }
                    }
                    if isCuddlyModeEnabled(){
                        if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                            isAppAllowed = true
                        }
                    }
                    
                    if !isAppAllowed{
                        var isAppAllowedByUser = false
                        let arrBlockedApps = getBlockedAppsToBlock()
                        for path in arrBlockedApps{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                isAppAllowed = false
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                if !result{// it means allowed by user(intention set by user)
                                    isAppAllowedByUser = true
                                    isAppAllowed = true
                                }
                                if !isAppAllowedByUser{
                                    self.closeIntentionBlockedAppsWinddowIfVisible()
                                }
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentAppForAlignmentScore()
                                return;
                            }
                        }
                    }else{
                        if !SettingsManagerObject.immediatelyBlockDistractingApps{
                            let arrBlockedApps = getBlockedAppsToBlock()
                            for path in arrBlockedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                    let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                    if result{// it means allowed by user(intention set by user)
                                        self.closeIntentionBlockedAppsWinddowIfVisible()
                                    }
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentAppForAlignmentScore()
                                    return;
                                }
                            }
                        }
                    }
                    
                    if isAppBlocked{
                        if popUpBlockConfirmWcObj != nil{
                            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                if popUpBlockConfirmVcObj!.isAppBlocking{
                                    popUpBlockConfirmVcObj?.closeWindow()
                                }
                            }
                        }
                        focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true)
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                        }
                        setFocusBearIconToNormal()
                        focusModeCloseCurrentAppForAlignmentScore()
                        return;
                    }else if !isAppAllowed{
                        focusTryToBlockUnwantedApp(runningApp: runningApp, appName: name)
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                        }
                        focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 0.0, isAppAllowedByAllowedAppList:false, appName: name)
                        
                        return
                    }else{
                        if isSelfApp{
                            setFocusBearIconToNormal()
                            focusModeCloseCurrentAppForAlignmentScore()
                            return;
                        }
                        if isAllowedAppIsDefault{
                            setFocusBearIconToNormal()
                            focusModeCloseCurrentAppForAlignmentScore()
                        }else{
                            focusModeOpenCurrentAppForAlignmentScore(appNameLowercased: nameLowercased, focusModeName: currentRunningFocusModeName, probability: 1.0, isAppAllowedByAllowedAppList:isAppAllowedByAllowedAppList, appName: name)
                        }
                        
                        DispatchQueue.main.async {
                            closePupUpBlockIfVisible()
                        }
                    }
//                    if nameLowercased == "firefox"{//
//                        if !fireFoxNotificationShownForCurrentFocusMode{
//                            var msg = "FYI we can't block distractions in Firefox yet but if you use Chrome or Safari, we'll be here to support you to stay on track"
//                            if let common = configjson.value(forKey: "common") as? NSDictionary{
//                                msg = common.value(forKey: "notificationFirefoxText") as? String ?? msg
//                            }
//                            showNotificationWithMessage(msg: msg)
//                            fireFoxNotificationShownForCurrentFocusMode = true
//                            return;
//                        }
//                    }
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
                }
            }
        }else{
            if isAppEnable{//Deactivate should stop always blocked URLs#663
                if isFocusBreakOn{
                    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                        if state{
                            return;
                        }
                    }
                }
                if currentState == ._ACTIVITY_{
                    if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
                        if state{
                            return;
                        }
                    }
                }
                if isUserOnMeeting && !SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled{
                    return;
                }
                
                if SettingsManagerObject.blockingSchedule == ._UNTIL_I_FINISH_WORK_{
                    if let runningApp = NSWorkspace.shared.frontmostApplication{
                        if let appUrl = runningApp.bundleURL{//let name = runningApp.localizedName{
                            let name = appUrl.deletingPathExtension().lastPathComponent
                            let nameLowercased = name.lowercased()
                            if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
                                return;
                            }
                            var isAppAllowed = true
                            var isAppAllowedByUser = false
                            let arrBlockedApps = getBlockedAppsToBlock()
                            for path in arrBlockedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == nameLowercased{
                                    isAppAllowed = false
                                    let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                    if !result{// it means allowed by user(intention set by user)
                                        isAppAllowedByUser = true
                                        isAppAllowed = true
                                    }
                                    print("\(nameLowercased) hide**************************")
                                    DispatchQueue.global().async {
                                        DispatchQueue.main.async {
                                            self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        }
                                    }
                                    break;
                                }
                            }

                            
                            if nameLowercased != selfAppName.lowercased(){
                                if isAppAllowed{
                                    if !isAppAllowedByUser{
                                        closeIntentionBlockedAppsWinddowIfVisible()
                                    }
                                    DispatchQueue.global().sync {
                                        if arrBrowsersLowerCasedNames.contains(nameLowercased){
                                            timerBlockUrl?.invalidate()
                                            self.timerBlockUrl = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.blockUrlsInBackground), userInfo: nil, repeats: true)
                                            RunLoop.main.add(self.timerBlockUrl!, forMode: RunLoop.Mode.common)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func checkIsCurrentTabAllowed(currentBrowser:BROWSER)->Bool{
        if !SettingsManagerObject.isTabLimiterEnabled{
            return true
        }
        if currentBrowser == ._FIREFOX_{
            return true
        }
        if let browserStruct = getBrowserAllWindowStruct(browser: currentBrowser){
            if currentBrowser == ._SAFARI_{
                if safariWindowsInfo.keys.count == 0{
                    safariWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = safariWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = safariWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        safariWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
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
            }else if currentBrowser == ._GOOGLE_CHROME_{
                if googleChromeWindowsInfo.keys.count == 0{
                    googleChromeWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = googleChromeWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = googleChromeWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        googleChromeWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
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
            }else if currentBrowser == ._OPERA_{
                if operaWindowsInfo.keys.count == 0{
                    operaWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = operaWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = operaWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        operaWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = operaWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            operaWindowsInfo[key] = browserTabsArr
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
                            operaWindowsInfo = browserStruct
                        }
                    }else{
                        operaWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._OPERA_GX_{
                if operaGxWindowsInfo.keys.count == 0{
                    operaGxWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = operaGxWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = operaGxWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        operaGxWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = operaGxWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            operaGxWindowsInfo[key] = browserTabsArr
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
                            operaGxWindowsInfo = browserStruct
                        }
                    }else{
                        operaGxWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._VIVALDI_{
                if vivaldiWindowsInfo.keys.count == 0{
                    vivaldiWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = vivaldiWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = vivaldiWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        vivaldiWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
                            let keys = browserStruct.keys
                            for key in keys{
                                if let browserTabsArr = browserStruct[key]{
                                    if let selfTabArr = vivaldiWindowsInfo[key]{
                                        if selfTabArr.count == browserTabsArr.count{
                                            vivaldiWindowsInfo[key] = browserTabsArr
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
                            vivaldiWindowsInfo = browserStruct
                        }
                    }else{
                        vivaldiWindowsInfo = browserStruct
                    }
                }
            }else if currentBrowser == ._BRAVE_BROWSER_{
                if braveBrowserWindowsInfo.keys.count == 0{
                    braveBrowserWindowsInfo = browserStruct
                }else{
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = braveBrowserWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = braveBrowserWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        braveBrowserWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
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
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = sidekickWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = sidekickWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        sidekickWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
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
                    var currentBrowserTabsArr = [String]()
                    var allSelfTabArr = [String]()
                    
                    var keys = browserStruct.keys
                    for key in keys{
                        if let tabsArr = browserStruct[key]{
                            currentBrowserTabsArr += tabsArr
                        }
                    }
                    keys = microsoftEdgeWindowsInfo.keys
                    for key in keys{
                        if let tabsArr = microsoftEdgeWindowsInfo[key]{
                            allSelfTabArr += tabsArr
                        }
                    }
                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        microsoftEdgeWindowsInfo = browserStruct
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
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
            }else if currentBrowser == ._ARC_{
                if arcBrowserTabsInfo.count == 0{
                    if let allTabs = browserStruct["window"]{
                        arcBrowserTabsInfo = allTabs
                    }
                }else{
                    let currentBrowserTabsArr = browserStruct["window"] ?? []
                    let allSelfTabArr = arcBrowserTabsInfo
                    

                    if allSelfTabArr.count == currentBrowserTabsArr.count{
                        arcBrowserTabsInfo = currentBrowserTabsArr
                    }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
                        if (getAllBrowsersTabCount() + 1) > SettingsManagerObject.maxTabLimitCount{
                            
                            for i in 0..<currentBrowserTabsArr.count{
                                if i < allSelfTabArr.count{
                                    if currentBrowserTabsArr[i] != allSelfTabArr[i]{
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
                            
                            
                        }else{
                            arcBrowserTabsInfo = currentBrowserTabsArr
                        }
                    }else{
                        arcBrowserTabsInfo = currentBrowserTabsArr
                    }
                }
            }
        }
        return true
    }
    
    var isCurrentUrlAllowedInCurrentFocsMode = false
    var isCurrentUrlNotAllowedInCurrentFocsMode = false
    
    @objc func blockUrlsInBackground(){
        if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
            if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                if UserDefaults.standard.object(forKey: kUserdefaultsControllingBrowserVcShown) == nil{
                    self.timerBlockUrl?.invalidate()
                    return;
                }
            }
        }
        let isCurrentUrlAllowedInFocsMode = self.isCurrentUrlAllowedInCurrentFocsMode
        if self.isCurrentUrlAllowedInCurrentFocsMode{
            self.isCurrentUrlAllowedInCurrentFocsMode = false
        }
        let isCurrentUrlNotAllowedInFocsMode = self.isCurrentUrlNotAllowedInCurrentFocsMode
        if self.isCurrentUrlNotAllowedInCurrentFocsMode{
            self.isCurrentUrlNotAllowedInCurrentFocsMode = false
        }
        
        
        currentBrowserUrlForAi = ""
        self.timerForCheckUrlFromAiTimeOut?.invalidate()
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    popUpBlockConfirmVcObj?.closeWindow()
                }
            }
        }
        
        if currentState == ._EVENING_HABIT_ && currentRelaxHabitPlaying != nil && currentAction == ._INPROGRESS_{
            if currentRelaxHabitPlaying!.showSavedDistractingWebsites{
                return;
            }
        }
        
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let name = runningApp.localizedName{
                var script: String = ""
                var tabUrl:String = ""
                var blockItem = ""
                var currentBrowser:BROWSER!
                let nameLowercased = name.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    currentBrowser = browser
                }else{
                    self.timerBlockUrl?.invalidate()
                    if setIntentionBlockedUrlsWcObj != nil{
                        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                            setIntentionBlockedUrlsVcObj?.closeWindow()
                            return;
                        }
                    }
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
                    
                    if currentBrowser == ._OPERA_GX_{
                        if url.contains("gxcorner.games"){ //  alllow gxcorner (default url)
                            self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                            self.closeIntentionBlockedUrlsWinddowIfVisible()
                            return;
                        }
                    }
                    
                    //Allow unblocking super distracting URL in cuddly bear mode #432
                    if url.localizedCaseInsensitiveContains("unblock_it=true"){
                        allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
                        //if change anything in always block site code then a change also done in checkinbackground function
                        var extractedUrl: String = ""
                        extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") ?? ""
                        if extractedUrl.isEmpty{
                            extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") ?? ""
                        }
                        
                        if !extractedUrl.isEmpty {
                            print("Extracted substring: \(extractedUrl)")
                            extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                            let extractedPath = getDomainFromUrl(url: extractedUrl)
                            
                            for i in 0..<arrAlwaysBlockedSitesData.count{
                                let dictionary = arrAlwaysBlockedSitesData[i]
                                if let blockUrl = dictionary["url"] as? String{
                                    if blockUrl.lowercased() == extractedPath.lowercased(){
                                        arrAlwaysBlockedSitesData.remove(at: i)
                                        break;
                                    }
                                }
                            }
                            allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                            setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                            
                            // doing this because if immidiatly block url setting is on then after unblock click we are not showing ask intention box again thats why after clicking unblock it is blocking again. to handle this problem if immidiatly block setting is on then allwing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
                            if SettingsManagerObject.immediatelyBlockDistractingSites{
                                let seconds =  24*60*60
                                let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                                arrAlwaysBlockedSitesData.append(["url": extractedPath, "isBlocked": false, "intention" : "", "closed":false, "endTime": endTime, "duration": seconds, "allowFor24Hours": true])
                            }
                        } else {
                            print("Substring not found.")
                        }
                    }
                    //  //////
                    
                    
                    if !url.contains(defaultPageOfBrowser) && !url.contains(blockWebUrlString){//agar block url mai file://* bhi hai to bar bar block hi gota rhega isiliye blockWebUrlString ka check lagaya
                        let domain = getDomainFromUrl(url: url)//getDomainFromUrl(url: url)
                        tabUrl = domain
                        if setIntentionBlockedUrlsWcObj != nil{
                            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                                    exitFullScreen(runningApp: runningApp)
                                    return;
                                }else{
                                    setIntentionBlockedUrlsVcObj?.closeWindow()
                                }
                            }
                        }
                        
                        let arrBlockedUrls = getBlockedUrlsToBlock()
                        var bool = false
                        for turl in arrBlockedUrls{
                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                            bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)//.isUrlValid(urlToCheck: url, allowUrl: turl)
                            if bool{
                                blockItem = turl
                                break;
                            }
                        }
                        if bool{
                            url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                            
                            switch currentBrowser{
                                
                            case ._SAFARI_:
                                script = getSafariBlockScript(url:url)
                                
                            case ._GOOGLE_CHROME_:
                                script = getGoogleChromeBlockScript(url:url)
                            
                            case ._OPERA_:
                                script = getOperaBlockScript(url:url)
                           
                            case ._OPERA_GX_:
                                script = getOperaGxBlockScript(url:url)
                                
                            case ._VIVALDI_:
                                script = getVivaldiBlockScript(url:url)
                                
                            case ._BRAVE_BROWSER_:
                                script = getBraveBrowserBlockScript(url:url)
                                
                            case ._SIDEKICK_:
                                script = getSidekickBlockScript(url:url)
                                
                            case ._MICROSOFT_EDGE_:
                                script = getMicrosoftEdgeBlockScript(url:url)
                                
                            case ._ARC_:
                                script = getArcBlockScript(url:url)
                                
                            case ._FIREFOX_:
                                script = getFirefoxBlockScript(url:url)
                            case .none:
                                
                                return
                            }
                            
                        }else{
                            if setIntentionBlockedUrlsWcObj != nil{
                                if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    setIntentionBlockedUrlsVcObj?.closeWindow()
                                    return;
                                }
                            }
                            closeIntentionBlockedUrlsWinddowIfVisible()
                            return;
                        }
                    }else{
                        if setIntentionBlockedUrlsWcObj != nil{
                            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                setIntentionBlockedUrlsVcObj?.closeWindow()
                                return;
                            }
                        }
                        closeIntentionBlockedUrlsWinddowIfVisible()
                        return;
                    }
                    
                }else{
                    if setIntentionBlockedUrlsWcObj != nil{
                        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                            setIntentionBlockedUrlsVcObj?.closeWindow()
                            return;
                        }
                    }
                    closeIntentionBlockedUrlsWinddowIfVisible()
                    return;
                }//
                
                var modeString = ""
                if SettingsManagerObject.isCuddlyModeEnabled{
                    modeString = "&block_mode=cuddly"
                }else{
                    modeString = "&block_mode=grizzly"
                }
                var isOnboardingString = ""
                
                let blockPageTourShowed = UserDefaults.standard.object(forKey: kUserDefaultsBlockPageTourShowed) as? Bool ?? false
                var shouldShowTour = !blockPageTourShowed
                

                if UserDefaults.standard.object(forKey: kUserdefaultsIsUserLoggedIn) as? Bool == nil{
                    if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
                        shouldShowTour = false
                    }
                }
                //
                if shouldShowTour{
                    isOnboardingString = "&show_tour=true"
                    UserDefaults.standard.set(true, forKey: kUserDefaultsBlockPageTourShowed)
                }
                
                
                if isCurrentUrlAllowedInFocsMode{
                    
                    var cuddly_bear_modeString = ""
                    var aiReasonToBlockString = ""
                    if isCuddlyModeEnabled(){
                        cuddly_bear_modeString = "&cuddly_bear_mode=true"
                        aiReasonToBlockString = "&reason=The website URL is not directly related to the focus mode and intention."
                    }
                    if isAnyAllowedFocusModeActivityRunning == true{
                        var blockType = ""
                        if currentState == ._ACTIVITY_{
                            blockType = "break-activity"
                        }else if currentState == ._MORNING_HABIT_{
                            blockType = "morning-habit"
                        }else if currentState == ._EVENING_HABIT_{
                            blockType = "evening-habit"
                        }else if currentState == ._SPECIAL_ACTIVITY_{
                            blockType = "special-activity"
                        }

                        script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)\(modeString)")
                    }else{
                        var focusMode = ""
                        let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
                        for dic in arrFocusType{
                            if dic["isOn"] as? Bool == true{
                                focusMode = dic["name"] as? String ?? ""
                                break;
                            }
                        }
                        var stringTime: String = ""
                        if let date = endFocusModeTime{
                            stringTime = getStringFromDateInUtc(date: date, dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                        }
                        let focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
                        script = script.replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                    }
                }else{
                    script = script.replacingOccurrences(of: "<PARAMS>", with: "&block_type=always-blocked\(modeString)\(isOnboardingString)")
                }
                if script.isEmpty{
                    return
                }
                if isCurrentUrlNotAllowedInFocsMode{
                    
                    var allowFor24Hours = false
                    
                     // doing this because url is not allowed in focus mode and blocked in always blocked urls then we immidiatly blocked it without chacking that immidiatly block setting is on or off thats why after clicking unblock it is blocking again. to handle this problem  allowing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
                    for i in 0..<arrAlwaysBlockedSitesData.count{
                        let dictionary = arrAlwaysBlockedSitesData[i]
                        if let blockUrl = dictionary["url"] as? String{
                            if blockUrl.lowercased() == tabUrl.lowercased(){
                                allowFor24Hours = dictionary["allowFor24Hours"] as? Bool ?? false
                                break;
                            }
                        }
                    }
                    
                    if !allowFor24Hours{
                        addLog(text:"blockAlwaysBlockedUrl (CurrentUrlNotAllowedInFocusMode):- \(tabUrl)")
                        executeScript(script: script)
                        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"super_distracting_url"])
                    }
                }else{
                    tryToBlockAlwaysBlockedUrl(script: script, url: tabUrl, browser: currentBrowser, runningApp: runningApp, blockItem: blockItem)
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
        let currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
        
        if let isRelaxFocus = currentRunningFocusType["isRelaxFocus"] as? Bool{
            if  isRelaxFocus{
                return;
            }
        }
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            if let appUrl = runningApp.bundleURL{
                let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                
                var isAppAllowed = false
                var isAppBlocked = false
                var isSelfApp = false
                if name == selfAppName.lowercased() || name == focusBearTimeTrackerAppName{
                    return;
                }
                let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                for path in blockAppsPath{
                    let url = URL(fileURLWithPath: path)
                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                        isAppBlocked = true
                        break;
                    }
                }
                
                if isAllowedAllAppsInFocus{
                    isAppAllowed = true
                    if name == selfAppName.lowercased(){
                        isSelfApp = true
                    }
                }else if name == selfAppName.lowercased(){
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
                
                
                if isCuddlyModeEnabled(){
                    if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                        isAppAllowed = true
                    }
                }
                
                if !isAppAllowed{
                    var isAppAllowedByUser = false
                    let arrBlockedApps = getBlockedAppsToBlock()
                    for path in arrBlockedApps{
                        let url = URL(fileURLWithPath: path)
                        if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                            isAppAllowed = false
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                            if !result{// it means not allowed by user(intention is not set)
                                isAppAllowedByUser = true
                                isAppAllowed = true
                            }
                            if !isAppAllowedByUser{
                                self.closeIntentionBlockedAppsWinddowIfVisible()
                            }
                            return;
                        }
                    }
                }else{
                    if !SettingsManagerObject.immediatelyBlockDistractingApps{
                        let arrBlockedApps = getBlockedAppsToBlock()
                        for path in arrBlockedApps{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                if popUpBlockConfirmWcObj != nil{
                                    if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                        if popUpBlockConfirmVcObj!.isAppBlocking{
                                            popUpBlockConfirmVcObj?.closeWindow()
                                        }
                                    }
                                }
                                let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                if result{// it means not allowed by user(intention is not set)
                                    self.closeIntentionBlockedAppsWinddowIfVisible()
                                }
                                return;
                            }
                        }
                    }
                }
                if isAppBlocked{
                    if popUpBlockConfirmWcObj != nil{
                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                popUpBlockConfirmVcObj?.closeWindow()
                            }
                        }
                    }
                    focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true)
                    if self.timerAllowUrl != nil{
                        self.timerAllowUrl!.invalidate()
                    }
                    return;
                }else if !isAppAllowed{
                    focusTryToBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent)
                    if self.timerAllowUrl != nil{
                        self.timerAllowUrl!.invalidate()
                    }
                    return;
                }else{
                    if isSelfApp{
                     //   setFocusBearIconToNormal()//
                      //  focusModeCloseCurrentAppForAlignmentScore()
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
        exitFullScreen(runningApp:runningApp)
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if popUpBlockConfirmVcObj!.isAppBlocking{
                    if popUpBlockConfirmVcObj?.currentApp == runningApp{
                        return;
                    }
                }
            }
        }
        if isCuddlyModeEnabled(){
            if arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true)
            }else{
                showPopupBlockConfirmWindow(blockedAppName: appName, currentApp: runningApp, url:"", script:"", isBlockApp:true, browser: nil, tabTitle: nil, fullUrl:"", aiUrlBlockReason: "", isTimeOut:false, isUrlBlockByAi: false)
            }
        }else{
            focusBlockUnwantedApp(runningApp: runningApp, appName: appName, showNotification: true)
        }
    }

    func focusBlockUnwantedApp(runningApp: NSRunningApplication, appName:String, showNotification:Bool){
        exitFullScreen(runningApp:runningApp)
        runningApp.hide()
        allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
        if showNotification{
            showFocusAppBlockNotification(appName:appName)
        }
        if isCuddlyModeEnabled(){
            if !arrBlockedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                arrBlockedAppsInCuddlyModeCurrentFocus.append(runningApp)
            }
        }
    }
    
    
    func focusTryToBlockUnwantedUrl(script: String, url:String, browser: BROWSER?, tabTitle:String?, fullUrl:String, runningApp:NSRunningApplication){
        print("focusTryToBlockUnwantedUrl")
        if popUpBlockConfirmWcObj != nil{
            if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                if !popUpBlockConfirmVcObj!.isAppBlocking{
                    if popUpBlockConfirmVcObj?.url == url{
                        exitFullScreen(runningApp:runningApp)
                        return;
                    }else{
                        popUpBlockConfirmVcObj?.closeWindow()
                    }
                }
            }
        }
        if isCuddlyModeEnabled(){
            if arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
                focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "blocked_once_in_this_session")
            }else{
                if SettingsManagerObject.isAiCheckUrlEnabled{
                    checkUrlFromAi(script: script, url: url, tabTitle: tabTitle, browser: browser, fullUrl: fullUrl)
                }else{
                    exitFullScreen(runningApp:runningApp)
                    showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiUrlBlockReason: "", isTimeOut:false, isUrlBlockByAi: false)
                    
                }
            }
        }else{
            
            
            if arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
                focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "blocked_once_in_this_session")
            }else{
                if SettingsManagerObject.isAiCheckUrlEnabled{
                    checkUrlFromAi(script: script, url: url, tabTitle: tabTitle, browser: browser, fullUrl: fullUrl)
                }else{
                    exitFullScreen(runningApp:runningApp)
                    focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: nil, browser: browser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                    
                }
            }
        }
        
    }
//    func setTimerHideAiSafeSiteAlertFewSeconds(){
//        DispatchQueue.global().sync {
//            self.timerHideAiSafeSiteAlert = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.hideAiSafeSiteAlert), userInfo: nil, repeats: false)
//            RunLoop.main.add((self.timerHideAiSafeSiteAlert!), forMode: RunLoop.Mode.common)
//        }
//    }
//    @objc func hideAiSafeSiteAlert(){
//        if alertReasonAutoAllowWcObj != nil{
//            if alertReasonAutoAllowWcObj?.window != nil{
//                //self.view.window?.endSheet(self.alertTimer!.window)
//                alertReasonAutoAllowWcObj?.window?.close()
//            }
//        }
//        if timerHideAiSafeSiteAlert != nil{
//            timerHideAiSafeSiteAlert?.invalidate()
//            timerHideAiSafeSiteAlert = nil
//        }
//    }
//    var timerHideAiSafeSiteAlert:Timer?
    var currentBrowserUrlForAi = ""
    var currentBrowserUrlForTimeoutTimer = ""
    var lastBrowserUrlForTimeoutTimer = ""
    var currentBrowserFullUrlForTimeoutTimer = ""
    var currentBrwoserScriptForTimeoutTimer = ""
    var currentBrwoserTabTitleForTimeoutTimer = ""
    var currentBrwoserForTimeoutTimer:BROWSER?
    
    var isGettingResponseFromAi = false
    
    func checkUrlFromAi(script: String, url:String, tabTitle:String?, browser:BROWSER?, fullUrl:String){
        if currentBrowserUrlForAi == url{
            print("******************")
            print("url is same return now")
            print("******************")
            print("\(isGettingResponseFromAi)***********5555")
            if isCuddlyModeEnabled(){
                if !isGettingResponseFromAi, let info = dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url]{
                    let reason = info["reason"] as? String ?? ""
                    boxForStatusBarForTooltip?.customToolTip = reason
                    let probability = info["probability"] as? Double ?? 0.0
                    calculateFocusAlignmentScore()
                    print("-----------------------")
                    print(currentFocusAlignmentScore)
                    print(probability)
                    print("-----------------------")
                    if probability < 0.8{
                        if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                            //Unsafe url
                            showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiUrlBlockReason: reason, isTimeOut:false, isUrlBlockByAi: true)
                        }
                    }
                }
            }
            return;
        }
        currentBrowserUrlForAi = url
        var currentRunningFocusModeName = ""
        if isAnyAllowedFocusModeActivityRunning{
            if currentHabitPlaying != nil{
                currentRunningFocusModeName = currentHabitPlaying?.name ?? ""
            }else if currentActivityPlaying != nil{
                currentRunningFocusModeName = currentActivityPlaying?.name ?? ""
            }
        }else{
            currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
        }
        var tab_title = ""
        if tabTitle == nil{
            if browser != nil{
                if let title = getActiveTabTitleOf(browser: browser!){
                    tab_title = title
                }
            }
        }else{
            tab_title = tabTitle!
        }
        isGettingResponseFromAi = true
        self.timerForCheckUrlFromAiTimeOut?.invalidate()
        DispatchQueue.global().sync {
            self.timerForCheckUrlFromAiTimeOut = Timer.scheduledTimer(timeInterval: 7, target: self, selector: #selector(self.checkUrlFromAiTimeOut), userInfo: nil, repeats: false)
            RunLoop.main.add((self.timerForCheckUrlFromAiTimeOut!), forMode: RunLoop.Mode.common)
            currentBrowserUrlForTimeoutTimer = currentBrowserUrlForAi

            currentBrowserFullUrlForTimeoutTimer = fullUrl
            currentBrwoserScriptForTimeoutTimer = script
            currentBrwoserTabTitleForTimeoutTimer = tabTitle ?? ""
            currentBrwoserForTimeoutTimer = browser
        }
        if isCuddlyModeEnabled(){
            statusbutton?.image = NSImage(named: NSImage.Name("thinking_icon"))
        }
        allApiObject.chatGPTIsURLSafe(url: url, tab_title: tab_title, focus_mode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, completionHandler: {dic, checkedUrl, payload  in
            self.timerForCheckUrlFromAiTimeOut?.invalidate()
            if dic != nil{
                if self.currentBrowserUrlForAi == checkedUrl{
                    DispatchQueue.main.async{
                        let reason = dic?.value(forKey: "reason") as? String ?? ""
                        print("*****************************Reason")
                        print(reason)
                        print("*****************************")
                        setFocusBearIconToNormal()
                        if let dProbability = dic?.value(forKey: "allowed_probability") as? Double{
                            
                            if isCuddlyModeEnabled(){
                                if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] == nil{
                                    addEntryInfocusAlignmentScoreCsv(url: url, tabTitle: tab_title, focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: reason, allowedProbability: "\(dProbability)", totalScore: "")
                                    dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[url] = ["probability":dProbability, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason":reason]
                                    boxForStatusBarForTooltip?.customToolTip = reason
                                }
                                calculateFocusAlignmentScore()
                                print("*****************************currentFocusAlignmentScore")
                                print(currentFocusAlignmentScore)
                                print("*****************************dProbability")
                                print(dProbability)
                                print("*****************************")
                                if(dProbability >= 0.80){
                                    // Safe URL
                                    addLog(text: "url is safe according to chat gpt")
                                    allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                    
                                    arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                                    arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                    
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if !popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                }else if currentFocusAlignmentScore < minFocusAlignmentScoreToShowDistractingPopUp{
                                    //Unsafe url
                                    
                                    var popUpWindowVisible = false
                                    
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if !popUpBlockConfirmVcObj!.isAppBlocking{
                                                if popUpBlockConfirmVcObj?.url == self.currentBrowserUrlForAi{
                                                    
                                                    var urlNotVerifiedText = "The status of this url could not be verified."
                                                    if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                                                        urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "urlNotVerifiedText") as? String ?? urlNotVerifiedText
                                                    }
                                                    popUpWindowVisible = true
                                                    popUpBlockConfirmVcObj?.lblAi.stringValue = urlNotVerifiedText
                                                    return;
                                                }
                                            }
                                        }
                                    }
                                    if !popUpWindowVisible{
                                        if self.lastBrowserUrlForTimeoutTimer != self.currentBrowserUrlForAi{
                                            showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiUrlBlockReason: reason, isTimeOut:false, isUrlBlockByAi: true)
                                        }
                                    }
                                }
                            }else{
                                if(dProbability >= 0.80){
                                    // Safe URL
                                    addLog(text: "url is safe according to chat gpt")
                                    allApiObject.capturePosthog(event: "block-popup-allow-automatically", metadata: [:])
                                    
                                    arrAllowedUrlsInCuddlyModeCurrentFocus.append(url)
                                    arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(tab_title)
                                    
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if !popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                }else{
                                    if self.lastBrowserUrlForTimeoutTimer != self.currentBrowserUrlForAi{
                                        self.focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: reason, browser: browser, isUrlBlockByAi: true, blockReason:"")
                                    }
                                }
                            }
                            
                        }
                        self.isGettingResponseFromAi = false
                        
                    }
                }else{
                    self.isGettingResponseFromAi = false
                }
            }else{
                DispatchQueue.main.async{
                    self.isGettingResponseFromAi = false
                    if self.currentBrowserUrlForAi == checkedUrl{
                        
                        if isCuddlyModeEnabled(){
                            setFocusBearIconToNormal()
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if !popUpBlockConfirmVcObj!.isAppBlocking{
                                        if popUpBlockConfirmVcObj?.url == self.currentBrowserUrlForAi{
                                            
                                            var urlNotVerifiedText = "The status of this url could not be verified."
                                            if let popUpBlockConfirmVcInfo = configjson.value(forKey: "popUpBlockConfirmVcInfo") as? NSDictionary{
                                                urlNotVerifiedText = popUpBlockConfirmVcInfo.value(forKey: "urlNotVerifiedText") as? String ?? urlNotVerifiedText
                                            }
                                            
                                            popUpBlockConfirmVcObj?.lblAi.stringValue = urlNotVerifiedText
                                            return;
                                        }
                                    }
                                }
                            }
                            if self.lastBrowserUrlForTimeoutTimer != self.currentBrowserUrlForAi{
                                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:url, script:script, isBlockApp:false, browser: browser,tabTitle: tabTitle, fullUrl:fullUrl, aiUrlBlockReason: "", isTimeOut:false, isUrlBlockByAi: true)
                            }
                        }else{
                            if self.lastBrowserUrlForTimeoutTimer != self.currentBrowserUrlForAi{
                                self.focusBlockUnwantedUrl(script: script, url: url, lastBlockReasonFromAi: "", browser: browser, isUrlBlockByAi: true, blockReason:"")
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    @objc func checkUrlFromAiTimeOut(){
        self.timerForCheckUrlFromAiTimeOut?.invalidate()
        if currentBrowserUrlForTimeoutTimer == currentBrowserUrlForAi{
            lastBrowserUrlForTimeoutTimer = currentBrowserUrlForTimeoutTimer
            
            if isCuddlyModeEnabled(){
                showPopupBlockConfirmWindow(blockedAppName: "", currentApp: nil, url:currentBrowserUrlForTimeoutTimer, script:currentBrwoserScriptForTimeoutTimer, isBlockApp:false, browser: currentBrwoserForTimeoutTimer,tabTitle: currentBrwoserTabTitleForTimeoutTimer, fullUrl:currentBrowserFullUrlForTimeoutTimer, aiUrlBlockReason: "", isTimeOut:true, isUrlBlockByAi: true)
            }else{
                self.focusBlockUnwantedUrl(script: currentBrwoserScriptForTimeoutTimer, url: currentBrowserUrlForTimeoutTimer, lastBlockReasonFromAi: "", browser: currentBrwoserForTimeoutTimer, isUrlBlockByAi: true, blockReason:"")
            }
        }
    }
    
    func focusBlockUnwantedUrl(script: String, url:String, lastBlockReasonFromAi:String?, browser: BROWSER?, isUrlBlockByAi:Bool, blockReason:String){
        addLog(text:"focusBlockUnwantedUrl:- \(url)")
        var newScript = script
        currentBrowserUrlForAi = ""
        self.timerForCheckUrlFromAiTimeOut?.invalidate()
        if lastBlockReasonFromAi != nil{
            newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "&reason=\(lastBlockReasonFromAi!)")
        }else{
            newScript = newScript.replacingOccurrences(of: "<AIREASON>", with: "")
        }
        if browser == ._ARC_{
            NSWorkspace.shared.launchApplication("Arc")
        }

        executeScript(script: newScript)
        var blockMode = ""
        if currentFocusModeStrictness == ._SUPER_STRICT_{
            blockMode = "super_strict"
        }else if currentFocusModeStrictness == ._STRICT_{
            blockMode = "strict"
        }else if currentFocusModeStrictness == ._NORMAL_{
            blockMode = "normal"
        }
        
        if isUrlBlockByAi{
            allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"ai_blocking", "block-mode": blockMode])
        }else{
            allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":blockReason, "block-mode": blockMode])
        }
        if !arrBlockedUrlsInCuddlyModeCurrentFocus.contains(url){
            arrBlockedUrlsInCuddlyModeCurrentFocus.append(url)
        }
    }
    
    func closeIntentionBlockedAppsWinddowIfVisible(){
        if intentionBlockedAppsWcObj != nil{
            if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
                intentionBlockedAppsWcObj?.window?.close()
            }
        }
    }
    
    func closeIntentionBlockedUrlsWinddowIfVisible(){
        if intentionBlockedUrlsWcObj != nil{
            if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                intentionBlockedUrlsWcObj?.window?.close()
            }
        }
    }
    func closeSetIntentionBlockedUrlsWinddowIfVisible(){
        if setIntentionBlockedUrlsWcObj != nil{
            if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                setIntentionBlockedUrlsVcObj?.closeWindow()
            }
        }
    }
    
    
    func tryToBlockAlwaysBlockedUrl(script: String, url:String, browser: BROWSER?, runningApp:NSRunningApplication, blockItem:String){
        print("tryToBlockAlwaysBlockedUrl")
        if SettingsManagerObject.immediatelyBlockDistractingSites{
            closeIntentionBlockedUrlsWinddowIfVisible()
            var allowFor24Hours = false
            
            // doing this because if immidiatly block url setting is on then after unblock click we are not showing ask intention box again thats why after clicking unblock it is blocking again. to handle this problem if immidiatly block setting is on then allwing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        allowFor24Hours = dictionary["allowFor24Hours"] as? Bool ?? false
                        break;
                    }
                }
            }
            
            if !allowFor24Hours{
                blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
            }
        }else{
            var isBlocked = true
            var isUrlAllreadyChecked = false
            var intention = ""
            var isClosed = false
            var alllowUrlEndTime:Date?
            var urlAllreadyCheckedIndex = -1
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        isBlocked = dictionary["isBlocked"] as? Bool ?? false
                        intention = dictionary["intention"] as? String ?? ""
                        isClosed = dictionary["closed"] as? Bool ?? false
                        alllowUrlEndTime = dictionary["endTime"] as? Date
                        isUrlAllreadyChecked = true
                        urlAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            
            if isUrlAllreadyChecked{
                if isBlocked{
                    closeIntentionBlockedUrlsWinddowIfVisible()
                    blockAlwaysBlockedUrl(script: script, browser: browser, url: url)
                }else {
                    var shouldSetIntentionAgain = false
                    if alllowUrlEndTime != nil{
                        if Date().compare(alllowUrlEndTime!) == .orderedDescending{ //>
                            shouldSetIntentionAgain = true
                        }
                    }
                    if shouldSetIntentionAgain{
                        if urlAllreadyCheckedIndex != -1{
                            arrAlwaysBlockedSitesData[urlAllreadyCheckedIndex]["intention"] = ""
                            arrAlwaysBlockedSitesData[urlAllreadyCheckedIndex]["closed"] = false
                        }
                        closeIntentionBlockedUrlsWinddowIfVisible()
                        exitFullScreen(runningApp: runningApp)
                        showSetIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, allreadyCheckedIndex:urlAllreadyCheckedIndex, isAppBlocking:false, currentApp:nil, blockedAppName:"", blockItem: blockItem)
                    }else{
                        if !isClosed{
                            if intentionBlockedUrlsWcObj != nil{
                                if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    if intentionBlockedUrlsVcObj?.tabUrl == url && intentionBlockedUrlsVcObj?.browser == browser{
                                        intentionBlockedUrlsVcObj?.timer?.invalidate()
                                        intentionBlockedUrlsVcObj?.timer = nil
                                        return;
                                    }else{
                                        intentionBlockedUrlsVcObj?.saveLastVisibleTimeForCurrentUrl()
                                    }
                                }
                            }
                            
                            showIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, intention: intention, currentPid: nil)
                        }else{
                            closeIntentionBlockedUrlsWinddowIfVisible()
                        }
                    }
                    
                }
            }else{
                closeIntentionBlockedUrlsWinddowIfVisible()
                exitFullScreen(runningApp: runningApp)
                showSetIntentionBlockedUrlsWindow(script: script, url: url, browser: browser, allreadyCheckedIndex:urlAllreadyCheckedIndex, isAppBlocking:false, currentApp:nil, blockedAppName:"", blockItem: blockItem)
            }
        }
    }
    
    func tryToBlockAlwaysBlockedApp(runningApp: NSRunningApplication, appName:String)->Bool{
        exitFullScreen(runningApp:runningApp)
        if SettingsManagerObject.immediatelyBlockDistractingApps{
            closeIntentionBlockedAppsWinddowIfVisible()
            blockAlwaysBlockedApp(runningApp: runningApp, appName:appName)
            return true
        }else{
            if setIntentionBlockedUrlsWcObj != nil{
                if setIntentionBlockedUrlsWcObj!.window?.isVisible ?? false{
                    if setIntentionBlockedUrlsVcObj!.isAppBlocking{
                        if setIntentionBlockedUrlsVcObj?.currentApp == runningApp{
                            return true
                        }
                    }
                }
            }
            
            var isBlocked = true
            var isAppAllreadyChecked = false
            var intention = ""
            var isClosed = false
            var alllowAppEndTime:Date?
            var appAllreadyCheckedIndex = -1
            for i in 0..<arrAlwaysBlockedAppsData.count{
                let dictionary = arrAlwaysBlockedAppsData[i]
                if let blockApp = dictionary["app"] as? String{
                    if blockApp.lowercased() == appName.lowercased(){
                        isBlocked = dictionary["isBlocked"] as? Bool ?? false
                        intention = dictionary["intention"] as? String ?? ""
                        isClosed = dictionary["closed"] as? Bool ?? false
                        alllowAppEndTime = dictionary["endTime"] as? Date
                        isAppAllreadyChecked = true
                        appAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            
            
            
            if isAppAllreadyChecked{
                if isBlocked{
                    closeIntentionBlockedAppsWinddowIfVisible()
                    blockAlwaysBlockedApp(runningApp: runningApp, appName: appName)
                }else{
                    var shouldSetIntentionAgain = false
                    if alllowAppEndTime != nil{
                        if Date().compare(alllowAppEndTime!) == .orderedDescending{ //>
                            shouldSetIntentionAgain = true
                        }
                    }
                    if shouldSetIntentionAgain{
                        if appAllreadyCheckedIndex != -1{
                            arrAlwaysBlockedAppsData[appAllreadyCheckedIndex]["intention"] = ""
                            arrAlwaysBlockedAppsData[appAllreadyCheckedIndex]["closed"] = false
                        }
                        closeIntentionBlockedAppsWinddowIfVisible()
                        showSetIntentionBlockedUrlsWindow(script: "", url: "", browser: nil, allreadyCheckedIndex:appAllreadyCheckedIndex, isAppBlocking:true, currentApp:runningApp, blockedAppName:appName, blockItem:"")
                        
                        return true
                    }else{
                        if !isClosed{
                            if intentionBlockedAppsWcObj != nil{
                                if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
                                    if intentionBlockedAppsVcObj?.currentApp == runningApp{
                                        return false
                                    }else{
                                        intentionBlockedAppsVcObj?.saveLastVisibleTimeForCurrentApp()
                                    }
                                }
                            }
                            
                            showIntentionBlockedAppsWindow(currentApp: runningApp, blockedAppName: appName, intention: intention)
                        }else{
                            closeIntentionBlockedAppsWinddowIfVisible()
                        }
                        return false
                    }
                }
            }else{
                closeIntentionBlockedAppsWinddowIfVisible()
                showSetIntentionBlockedUrlsWindow(script: "", url: "", browser: nil, allreadyCheckedIndex:-1, isAppBlocking:true, currentApp:runningApp, blockedAppName:appName, blockItem:"")
                return true
            }
            
            return true
        }
    }
    
    func blockAlwaysBlockedApp(runningApp: NSRunningApplication, appName:String){
        exitFullScreen(runningApp:runningApp)
        runningApp.hide()
        allApiObject.capturePosthog(event: "block-distracting-app", metadata: [:])
        
        if !SettingsManagerObject.immediatelyBlockDistractingApps{
            var isAppAllreadyChecked = false
            var isAppAllreadyCheckedIndex = 0
            for i in 0..<arrAlwaysBlockedAppsData.count{
                let dictionary = arrAlwaysBlockedAppsData[i]
                if let blockApp = dictionary["app"] as? String{
                    if blockApp.lowercased() == appName.lowercased(){
                        isAppAllreadyChecked = true
                        isAppAllreadyCheckedIndex = i
                        break;
                    }
                }
            }
            if isAppAllreadyChecked == false{
                arrAlwaysBlockedAppsData.append(["app": appName, "isBlocked": true, "intention" : "", "closed":false])
            }else{
                arrAlwaysBlockedAppsData[isAppAllreadyCheckedIndex] = ["app": appName, "isBlocked": true, "intention" : "", "closed":false]
            }
        }
    }
    func blockAlwaysBlockedUrl(script: String, browser: BROWSER?, url:String){
        addLog(text:"blockAlwaysBlockedUrl:- \(url)")
        if browser == ._ARC_{
            NSWorkspace.shared.launchApplication("Arc")
        }
        
        executeScript(script: script)
        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"super_distracting_url"])
        
        var totalBlockedSites = 0
        if let blockInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalDistractingSitesBlocked) as? [String:Any]{
            if let date = blockInfo["date"] as? Date, let count = blockInfo["count"] as? Int{
                if Calendar.current.isDateInToday(date){
                    totalBlockedSites = count
                }
            }
        }
        totalBlockedSites += 1
        UserDefaults.standard.set(["date": Date(), "count": totalBlockedSites], forKey: kUserdefaultsTotalDistractingSitesBlocked)
        

        if !SettingsManagerObject.immediatelyBlockDistractingSites{
            var isUrlAllreadyChecked = false
            var isUrlAllreadyCheckedIndex = 0
            for i in 0..<arrAlwaysBlockedSitesData.count{
                let dictionary = arrAlwaysBlockedSitesData[i]
                if let blockUrl = dictionary["url"] as? String{
                    if blockUrl.lowercased() == url.lowercased(){
                        isUrlAllreadyChecked = true
                        isUrlAllreadyCheckedIndex = i
                        break;
                    }
                }
                
            }
            if isUrlAllreadyChecked == false{
                arrAlwaysBlockedSitesData.append(["url": url, "isBlocked": true, "intention" : "", "closed":false])
            }else{
                //
                if let endTime = arrAlwaysBlockedSitesData[isUrlAllreadyCheckedIndex]["endTime"] as? Date{
                    let diffSeconds = Calendar.current.dateComponents([.second], from: Date(), to: endTime).second ?? 0
                    if diffSeconds != 0{
                        
                        var totalDurationaSaved = 0
                        if let timeSpentInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalTimeSpentOnDistractingSites) as? [String:Any]{
                            if let date = timeSpentInfo["date"] as? Date, let duration = timeSpentInfo["duration"] as? Int{
                                if Calendar.current.isDateInToday(date){
                                    totalDurationaSaved = duration
                                }
                            }
                        }
                        if totalDurationaSaved > 0{
                            totalDurationaSaved -= diffSeconds// remove remaining seconds if user clicks" block url i am done"
                            UserDefaults.standard.set(["date": Date(), "duration": totalDurationaSaved], forKey: kUserdefaultsTotalTimeSpentOnDistractingSites)
                        }
                        
                    }
                }
                //
                arrAlwaysBlockedSitesData[isUrlAllreadyCheckedIndex] = ["url": url, "isBlocked": true, "intention" : "", "closed":false]
            }
        }
    }
    

    func saveIntentionForBlockedUrl(url: String, script: String, browser: BROWSER?, intention:String, seconds:Int, currentPid: pid_t?){
        let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
        
        var isUrlAllreadyChecked = false
        var isUrlAllreadyCheckedIndex = 0
        for i in 0..<arrAlwaysBlockedSitesData.count{
            let dictionary = arrAlwaysBlockedSitesData[i]
            if let blockUrl = dictionary["url"] as? String{
                if blockUrl.lowercased() == url.lowercased(){
                    isUrlAllreadyChecked = true
                    isUrlAllreadyCheckedIndex = i
                    break;
                }
            }
            
        }
        if isUrlAllreadyChecked{
            arrAlwaysBlockedSitesData[isUrlAllreadyCheckedIndex] = ["url": url, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds]
        }else{
            arrAlwaysBlockedSitesData.append(["url": url, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds])
        }

        lastFrontMostApplication?.activate()
        
        var totalDurationaSaved = 0
        if let timeSpentInfo = UserDefaults.standard.object(forKey: kUserdefaultsTotalTimeSpentOnDistractingSites) as? [String:Any]{
            if let date = timeSpentInfo["date"] as? Date, let duration = timeSpentInfo["duration"] as? Int{
                if Calendar.current.isDateInToday(date){
                    totalDurationaSaved = duration
                }
            }
        }
        totalDurationaSaved += seconds
        UserDefaults.standard.set(["date": Date(), "duration": totalDurationaSaved], forKey: kUserdefaultsTotalTimeSpentOnDistractingSites)
        
    }

    func saveIntentionForBlockedApp(intention:String, seconds:Int, runningApp: NSRunningApplication, appName:String){
        let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
        
        var isUrlAllreadyChecked = false
        var isUrlAllreadyCheckedIndex = 0
        for i in 0..<arrAlwaysBlockedAppsData.count{
            let dictionary = arrAlwaysBlockedAppsData[i]
            if let app = dictionary["app"] as? String{
                if app.lowercased() == appName.lowercased(){
                    isUrlAllreadyChecked = true
                    isUrlAllreadyCheckedIndex = i
                    break;
                }
            }
            
        }
        
        if isUrlAllreadyChecked{
            arrAlwaysBlockedAppsData[isUrlAllreadyCheckedIndex] = ["app": appName, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds]
        }else{
            arrAlwaysBlockedAppsData.append(["app": appName, "isBlocked": false, "intention" : intention, "closed":false, "endTime": endTime, "duration": seconds])
        }
        showIntentionBlockedAppsWindow(currentApp: runningApp, blockedAppName: appName, intention: intention)
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
                if let focusAlignmentScore = currentRunningFocusType["focusAlignmentScoreThreshold"] as? Int{
                    minFocusAlignmentScoreToShowDistractingPopUp = Double(focusAlignmentScore)
                }else{
                    minFocusAlignmentScoreToShowDistractingPopUp = Double(defaultFocusAlignmentScoreToShowDistractingPopUp)
                }
                
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
        if (currentState == ._ACTIVITY_ || currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._SPECIAL_ACTIVITY_) && currentAction == ._INPROGRESS_ && (currentActivityPlaying != nil || currentHabitPlaying != nil){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let appUrl = runningApp.bundleURL{
                    let name = appUrl.deletingPathExtension().lastPathComponent.lowercased()//runningApp.localizedName?.lowercased(){
                    let localizedNameLowercased = runningApp.localizedName?.lowercased()
                    
                    if name == selfAppName.lowercased() || name == focusBearTimeTrackerAppName{
                        return;
                    }
                    
                    var isAppAllowed = false
                    if isAnyAllowedFocusModeActivityRunning{
                        let isAllowedAllAppsInFocus = currentRunningFocusType["isAllowedAllApps"] as? Bool ?? false
                        if isAllowedAllAppsInFocus{
                            
                            if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                let arrBlockedApps = getBlockedAppsToBlock()
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if result{// it means not allowed by user(intention is not set)
                                            self.closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        return;
                                    }
                                }
                            }
                            return;
                        }
                        var isSelfApp = false
                        var isAppBlocked = false
                        
                        let blockAppsPath = currentRunningFocusType["blockAppsArray"] as? [String] ?? []
                        for path in blockAppsPath{
                            let url = URL(fileURLWithPath: path)
                            if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                isAppBlocked = true
                                break;
                            }
                        }
                        
                        
                        if isAllowedAllAppsInFocus{
                            isAppAllowed = true
                            if name == selfAppName.lowercased(){
                                isSelfApp = true
                            }
                        }else if name == selfAppName.lowercased(){
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
                        
                        if isCuddlyModeEnabled(){
                            if arrAllowedAppsInCuddlyModeCurrentFocus.contains(runningApp){
                                isAppAllowed = true
                            }
                        }
                        if !isAppAllowed{
                            var isAppAllowedByUser = false
                            let arrBlockedApps = getBlockedAppsToBlock()
                            for path in arrBlockedApps{
                                let url = URL(fileURLWithPath: path)
                                if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                    isAppAllowed = false
                                    if popUpBlockConfirmWcObj != nil{
                                        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                            if popUpBlockConfirmVcObj!.isAppBlocking{
                                                popUpBlockConfirmVcObj?.closeWindow()
                                            }
                                        }
                                    }
                                    let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                    if !result{// it means not allowed by user(intention is not set)
                                        isAppAllowedByUser = true
                                        isAppAllowed = true
                                    }
                                    if !isAppAllowedByUser{
                                        self.closeIntentionBlockedAppsWinddowIfVisible()
                                    }
                                    
                                    return;
                                }
                            }
                        }else{
                            if !SettingsManagerObject.immediatelyBlockDistractingApps{
                                let arrBlockedApps = getBlockedAppsToBlock()
                                for path in arrBlockedApps{
                                    let url = URL(fileURLWithPath: path)
                                    if url.deletingPathExtension().lastPathComponent.lowercased() == name{
                                        let result = self.tryToBlockAlwaysBlockedApp(runningApp: runningApp, appName: name)
                                        if result{// it means not allowed by user(intention is not set)
                                            self.closeIntentionBlockedAppsWinddowIfVisible()
                                        }
                                        return;
                                    }
                                }
                            }
                        }
                        
                        if isAppBlocked{
                            if popUpBlockConfirmWcObj != nil{
                                if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
                                    if popUpBlockConfirmVcObj!.isAppBlocking{
                                        popUpBlockConfirmVcObj?.closeWindow()
                                    }
                                }
                            }
                            focusBlockUnwantedApp(runningApp: runningApp, appName: appUrl.deletingPathExtension().lastPathComponent, showNotification: true)
                            if self.timerAllowUrlForActivity != nil{
                                self.timerAllowUrlForActivity!.invalidate()
                            }
                            return;
                        }else if !isAppAllowed{
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
                                let allowAppLowercased = appName.lowercased()
                                if allowAppLowercased == name || allowAppLowercased == localizedNameLowercased{
                                    isAppAllowed = true
                                    break;
                                }
                            }
                        }
                        
                        
                        
                        if !isAppAllowed{
                            exitFullScreen(runningApp:runningApp)
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

    
    var defaultAllowedUrl = ["focus-block.html",
                             "earnyourscreentime.com",
                             "devtools://",
                             "chrome-extension://",
                             "focusbear.io",
                             "view-source:",
                             "about:blank",
                             "https://focus-bear.github.io"]

    @objc func checkInBackground(){
        DispatchQueue.main.async {
            
            if !isFocusModeOn(){
                if self.timerAllowUrl != nil{
                    self.timerAllowUrl!.invalidate()
                }
                return;
            }
            let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
            let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
            let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
            
            
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
            var currentRunningFocusModeName = ""
            var focusModeExpiryTimeString = "&focus_mode_end_time=\(stringTime)"
            var focusMode = ""
            let intention = whatToAchieveInFocusBlock.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
            for dic in arrFocusType{
                if dic["isOn"] as? Bool == true{
                    focusMode = dic["name"] as? String ?? ""
                    currentRunningFocusModeName = focusMode
                    if let isRelaxFocus = dic["isRelaxFocus"] as? Bool{
                        if  isRelaxFocus{
                            return;
                        }
                    }
                    break;
                }
            }
            
            focusModeExpiryTimeString = focusModeExpiryTimeString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            focusMode = focusMode.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
                 
            
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                if let name = runningApp.localizedName{
                    var script: String = ""
                    var tabUrl = ""
                    var fullUrl = ""
                    var needToBlockImmediately = false
                    var currentBrowser:BROWSER!
                    let nameLowercased = name.lowercased()
                    var tabTitle: String?
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        currentBrowser = browser
                    }else{
                        if nameLowercased != selfAppName.lowercased(){
                            closePopupBlockWindowIfRunningForUrl()
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
                        
                        if currentBrowser == ._OPERA_GX_{
                            if url.contains("gxcorner.games"){ //  alllow gxcorner (default url)
                                self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                                self.closeIntentionBlockedUrlsWinddowIfVisible()
                                closePopupBlockWindowIfRunningForUrl()
                                if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled{
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentUrlForAlignmentScore()
                                }
                                return;
                            }
                        }
                        if !url.lowercased().contains("http://") && !url.lowercased().contains("https://"){
                            url = "https://"+url
                        }
                        // 
                        if url.localizedCaseInsensitiveContains("unblock_it=true"){
                            //                            old_url=
                            //                            &focus_mode_end_time
                            allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
                            if isCuddlyModeEnabled(){
                                if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") {
                                    print("Extracted substring: \(extractedUrl)")
                                    extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                                    let extractedPath = getPathFromUrl(url: extractedUrl)//getDomainFromUrl(url: url)
                                    
                                    var isAlwaysBlockedUrl = false
                                    for i in 0..<arrAlwaysBlockedSitesData.count{
                                        let dictionary = arrAlwaysBlockedSitesData[i]
                                        if let blockUrl = dictionary["url"] as? String{
                                            if blockUrl.lowercased() == extractedPath.lowercased(){
                                                arrAlwaysBlockedSitesData.remove(at: i)
                                                isAlwaysBlockedUrl = true
                                                break;
                                            }
                                        }
                                    }
                                    if !isAlwaysBlockedUrl{
                                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(extractedPath)
                                        for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                            if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(extractedPath){
                                                arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                                break;
                                            }
                                        }
                                    }
                                    allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                    setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                                    let domain = getDomainFromUrl(url: extractedUrl).lowercased()
                                    var buttonAllowDomainText = "Do you want to allow all URLs from <DOMAIN> for this focus session?"
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        buttonAllowDomainText = common.value(forKey: "allowAllUrlsFromDomainText") as? String ?? buttonAllowDomainText
                                    }
                                    buttonAllowDomainText = buttonAllowDomainText.replacingOccurrences(of: "<DOMAIN>", with: domain)
                                    
                                    
                                    showCustomAlert(title: buttonAllowDomainText, body: nil, buttonOkText: buttonYesText, buttonCancelText: buttonNoText, checkBoxText: nil, autoClose: true, completionHandler: {isOkClicked in
                                        print(isOkClicked)
                                        if isOkClicked{
                                            arrAllowedDomianInCuddlyModeCurrentFocus.append(domain)
                                        }
                                    })
                                    
                                    return;
                                } else {
                                    print("Substring not found.")
                                    // work for always block site// if change anything in always block site code then a change also done in blockUrlsInBackground function
                                    var extractedUrl: String = ""
                                    extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") ?? ""
                                    if extractedUrl.isEmpty{
                                        extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") ?? ""
                                    }
                                    
                                    if !extractedUrl.isEmpty {
                                        print("Extracted substring: \(extractedUrl)")
                                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                                        let extractedPath = getDomainFromUrl(url: extractedUrl)
                                        
                                        for i in 0..<arrAlwaysBlockedSitesData.count{
                                            let dictionary = arrAlwaysBlockedSitesData[i]
                                            if let blockUrl = dictionary["url"] as? String{
                                                if blockUrl.lowercased() == extractedPath.lowercased(){
                                                    arrAlwaysBlockedSitesData.remove(at: i)
                                                    break;
                                                }
                                            }
                                        }
                                        allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                                        
                                        // doing this because url is not allowed in focus mode and blocked in always blocked urls then we immidiatly blocked it without chacking that immidiatly block setting is on or off thats why after clicking unblock it is blocking again. to handle this problem  allowing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
//                                        if SettingsManagerObject.immediatelyBlockDistractingSites{ // do not need to check this
                                            let seconds =  24*60*60
                                            let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                                            arrAlwaysBlockedSitesData.append(["url": extractedPath, "isBlocked": false, "intention" : "", "closed":false, "endTime": endTime, "duration": seconds, "allowFor24Hours": true])
//                                        }
                                        return;
                                    } else {
                                        print("Substring not found.")
                                    }
                                    //
                                }
                            }
                        }
                        //  //////
                        for turl in self.defaultAllowedUrl{
                            if url.contains(turl){
                                self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                                self.closeIntentionBlockedUrlsWinddowIfVisible()
                                closePopupBlockWindowIfRunningForUrl()
                                if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentUrlForAlignmentScore()
                                }
                                return;
                            }
                        }
                        if url == "https://"{
                            self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                            self.closeIntentionBlockedUrlsWinddowIfVisible()
                            closePopupBlockWindowIfRunningForUrl()
                            if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled{
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentUrlForAlignmentScore()
                            }
                            return;
                        }
                        if !url.contains(defaultPageOfBrowser){
                            let path = getPathFromUrl(url: url)//getDomainFromUrl(url: url)
                            focusModeOpenCurrentUrlForAlignmentScore(domain: path)
                            
                            if intentionBlockedUrlsWcObj != nil{
                                if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    let domain = getDomainFromUrl(url: url)
                                    if intentionBlockedUrlsVcObj?.tabUrl != domain{
                                        intentionBlockedUrlsWcObj?.window?.close()
                                    }
                                }
                            }
                            if setIntentionBlockedUrlsWcObj != nil{
                                if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    let domain = getDomainFromUrl(url: url)
                                    if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                                        exitFullScreen(runningApp: runningApp)
                                    }else{
                                        setIntentionBlockedUrlsVcObj?.closeWindow()
                                    }
                                }
                            }
                            var isBlocked = false
                            var isAllowed = false
                            if isCuddlyModeEnabled(){
                                if arrAllowedDomianInCuddlyModeCurrentFocus.count != 0{
                                    let domain = getDomainFromUrl(url: url)
                                    if arrAllowedDomianInCuddlyModeCurrentFocus.contains(domain){
                                        closePopupBlockWindowIfRunningForUrl()
                                        return;
                                    }
                                }
                            }
                            if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(path){
                                if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                                    if !arrAllowedTabTitlesInCuddlyModeCurrentFocus.contains(title){
                                        arrAllowedTabTitlesInCuddlyModeCurrentFocus.append(title)
                                    }
                                }
                                closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                            if isCuddlyModeEnabled(){
                                if url.contains("focus_bear_temporarily_allow=true"){
                                    var isAlwaysBlockedUrl = false
                                    for i in 0..<arrAlwaysBlockedSitesData.count{
                                        let dictionary = arrAlwaysBlockedSitesData[i]
                                        if let blockUrl = dictionary["url"] as? String{
                                            if blockUrl.lowercased() == path.lowercased(){
                                                arrAlwaysBlockedSitesData.remove(at: i)
                                                isAlwaysBlockedUrl = true
                                                break;
                                            }
                                        }
                                    }
                                    if isAlwaysBlockedUrl{
                                        if url.contains("?focus_bear_temporarily_allow=true"){
                                            setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "?focus_bear_temporarily_allow=true", with: ""))
                                        }else if url.contains("&focus_bear_temporarily_allow=true"){
                                            setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "&focus_bear_temporarily_allow=true", with: ""))
                                        }
                                        
                                    }else{
                                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(path)
                                        for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                            if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(path){
                                                arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                                break;
                                            }
                                        }
                                    }
                                    return;
                                }
                            }
                            if isAllowedListApproachInFocus{
                                for turl in arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                                    if isBlocked{
                                        needToBlockImmediately = true
                                        break;
                                    }
                                }
                                
                                if !isBlocked{
                                    for turl in arrAllowedUrlsForFocus{
                                        isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
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
                                isAllowed = true
                                for turl in arrBlockedUrlsForFocus{
                                    isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                                    if isBlocked{
                                        isAllowed = false
                                        needToBlockImmediately = true
                                        break;
                                    }
                                }
                            }

                            if !isAllowed{
                                if isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                    var bool = false
                                    let arrBlockedUrls = getBlockedUrlsToBlock()
                                    for turl in arrBlockedUrls{
                                        //Change all suggested blocked apps in onboarding to start with https:// #1233
                                        bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                        if bool{
                                            self.isCurrentUrlNotAllowedInCurrentFocsMode = true
                                            self.blockUrlsInBackground()
                                            return;
                                        }
                                    }
                                }

                                tabUrl = path
                                fullUrl = url
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                var cuddly_bear_modeString = ""
                                var aiReasonToBlockString = ""
                                if isCuddlyModeEnabled(){
                                    cuddly_bear_modeString = "&cuddly_bear_mode=true"// this will show "oops i actually need this- unblock it" url button
                                    aiReasonToBlockString = "<AIREASON>"
                                }

                                
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script = getSafariBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                            
                                case ._GOOGLE_CHROME_:
                                    script = getGoogleChromeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._OPERA_:
                                    script = getOperaBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._OPERA_GX_:
                                    script = getOperaGxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._VIVALDI_:
                                    script = getVivaldiBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._BRAVE_BROWSER_:
                                    script = getBraveBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._SIDEKICK_:
                                    script = getSidekickBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._MICROSOFT_EDGE_:
                                    script = getMicrosoftEdgeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                case ._ARC_:
                                    script = getArcBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                case ._FIREFOX_:
                                    script = getFirefoxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "\(focusModeExpiryTimeString)&focus_mode=\(focusMode)&focus_mode_intention=\(intention)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                case .none:
                                    closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                                
                            }else{
                                self.currentBrowserUrlForAi = ""
                                self.timerForCheckUrlFromAiTimeOut?.invalidate()
                                if !isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                    var bool = false
                                    let arrBlockedUrls = getBlockedUrlsToBlock()
                                    for turl in arrBlockedUrls{
                                        //Change all suggested blocked apps in onboarding to start with https:// #1233
                                        bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                        if bool{
                                            self.blockUrlsInBackground()
                                        }
                                    }
                                }else{//super distracting site is allowed in a Focus Mode and focus mode is running - result = should show intention popup. 756
                                    if !SettingsManagerObject.immediatelyBlockDistractingSites{
                                        var bool = false
                                        let arrBlockedUrls = getBlockedUrlsToBlock()
                                        for turl in arrBlockedUrls{
                                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                                            bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                            if bool{
                                                self.isCurrentUrlAllowedInCurrentFocsMode = true
                                                self.blockUrlsInBackground()
                                            }
                                        }
                                    }
                                }
                                closePopupBlockWindowIfRunningForUrl()
                                if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && !isBlockSuperDistractingFocusModeOn(){
                                    if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] == nil{
                                        addEntryInfocusAlignmentScoreCsv(url: path, tabTitle: tabTitle ?? "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "1.0", totalScore: "")
                                        var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                                        reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] = ["probability":1.0, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason": reason]
                                        boxForStatusBarForTooltip?.customToolTip = reason
                                    }else{
                                        var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                                        reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["probability"] = 1.0
                                        dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["reason"] = reason
                                    }
                                    calculateFocusAlignmentScore()
                                }
                                return
                            }
                        }else{
                            self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                            self.closeIntentionBlockedUrlsWinddowIfVisible()
                            closePopupBlockWindowIfRunningForUrl()
                            if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled{
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentUrlForAlignmentScore()
                            }
                            return;
                        }
                        
                    }else{
                        self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                        self.closeIntentionBlockedUrlsWinddowIfVisible()
                        closePopupBlockWindowIfRunningForUrl()
                        return;
                    }

                    if needToBlockImmediately{
                        self.focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil, browser: currentBrowser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                    }else{
                        self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle, fullUrl: fullUrl, runningApp:runningApp)
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
                    var fullUrl = ""
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
                        
                        if currentBrowser == ._OPERA_GX_{
                            if url.contains("gxcorner.games"){ //  alllow gxcorner (default url)
                                self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                                self.closeIntentionBlockedUrlsWinddowIfVisible()
                                closePopupBlockWindowIfRunningForUrl()
                                
                                if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && isAnyAllowedFocusModeActivityRunning && !isBlockSuperDistractingFocusModeOn(){
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentUrlForAlignmentScore()
                                }
                                return;
                            }
                        }
                        if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                            if url.localizedCaseInsensitiveContains("unblock_it=true"){
                                allApiObject.capturePosthog(event: "unblock-it-for-me-found", metadata: [:])
                                
                                if var extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") {
                                    print("Extracted substring: \(extractedUrl)")
                                    extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                                    let extractedPath = getPathFromUrl(url: extractedUrl)//getDomainFromUrl(url: url)
                                    
                                    var isAlwaysBlockedUrl = false
                                    for i in 0..<arrAlwaysBlockedSitesData.count{
                                        let dictionary = arrAlwaysBlockedSitesData[i]
                                        if let blockUrl = dictionary["url"] as? String{
                                            if blockUrl.lowercased() == extractedPath.lowercased(){
                                                arrAlwaysBlockedSitesData.remove(at: i)
                                                isAlwaysBlockedUrl = true
                                                break;
                                            }
                                        }
                                    }
                                    if !isAlwaysBlockedUrl{
                                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(extractedPath)
                                        for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                            if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(extractedPath){
                                                arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                                break;
                                            }
                                        }
                                    }
                                    allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                    setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                                    let domain = getDomainFromUrl(url: extractedUrl).lowercased()
                                    var buttonAllowDomainText = "Do you want to allow all URLs from <DOMAIN> for this focus session?"
                                    if let common = configjson.value(forKey: "common") as? NSDictionary{
                                        buttonAllowDomainText = common.value(forKey: "allowAllUrlsFromDomainText") as? String ?? buttonAllowDomainText
                                    }
                                    buttonAllowDomainText = buttonAllowDomainText.replacingOccurrences(of: "<DOMAIN>", with: domain)
                                    
                                    
                                    showCustomAlert(title: buttonAllowDomainText, body: nil, buttonOkText: buttonYesText, buttonCancelText: buttonNoText, checkBoxText: nil, autoClose: true, completionHandler: {isOkClicked in
                                        print(isOkClicked)
                                        if isOkClicked{
                                            arrAllowedDomianInCuddlyModeCurrentFocus.append(domain)
                                        }
                                    })
                                    
                                    return;
                                } else {
                                    print("Substring not found.")
                                    // work for always block site// if change anything in always block site code then a change also done in blockUrlsInBackground function
                                    var extractedUrl: String = ""
                                    extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&block_type") ?? ""
                                    if extractedUrl.isEmpty{
                                        extractedUrl = extractSubstring(from: url, start: "old_url=", end: "&focus_mode_end_time") ?? ""
                                    }
                                    
                                    if !extractedUrl.isEmpty {
                                        print("Extracted substring: \(extractedUrl)")
                                        extractedUrl = extractedUrl.removingPercentEncoding ?? extractedUrl
                                        let extractedPath = getDomainFromUrl(url: extractedUrl)
                                        
                                        for i in 0..<arrAlwaysBlockedSitesData.count{
                                            let dictionary = arrAlwaysBlockedSitesData[i]
                                            if let blockUrl = dictionary["url"] as? String{
                                                if blockUrl.lowercased() == extractedPath.lowercased(){
                                                    arrAlwaysBlockedSitesData.remove(at: i)
                                                    break;
                                                }
                                            }
                                        }
                                        allApiObject.capturePosthog(event: "unblock-it-for-me-worked", metadata: [:])
                                        setUrlToBrowser(browser: currentBrowser, url: extractedUrl)
                                        
                                        // doing this because url is not allowed in focus mode and blocked in always blocked urls then we immidiatly blocked it without chacking that immidiatly block setting is on or off thats why after clicking unblock it is blocking again. to handle this problem  allowing url for 24 hours. and using arrAlwaysBlockedSitesData to handle this
//                                        if SettingsManagerObject.immediatelyBlockDistractingSites{ // do not need to check this
                                            let seconds =  24*60*60
                                            let endTime = Calendar.current.date(byAdding: .second, value: seconds, to: Date()) ?? Date()
                                            arrAlwaysBlockedSitesData.append(["url": extractedPath, "isBlocked": false, "intention" : "", "closed":false, "endTime": endTime, "duration": seconds, "allowFor24Hours": true])
//                                        }
                                        return;
                                    } else {
                                        print("Substring not found.")
                                    }
                                    //
                                }
                            }
                        }
                        for turl in self.defaultAllowedUrl{
                            if url.contains(turl){
                                self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                                self.closeIntentionBlockedUrlsWinddowIfVisible()
                                closePopupBlockWindowIfRunningForUrl()
                                if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && isAnyAllowedFocusModeActivityRunning && !isBlockSuperDistractingFocusModeOn(){
                                    setFocusBearIconToNormal()
                                    focusModeCloseCurrentUrlForAlignmentScore()
                                }
                                return
                            }
                        }
                        if url == "https://"{
                            self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                            self.closeIntentionBlockedUrlsWinddowIfVisible()
                            closePopupBlockWindowIfRunningForUrl()
                            if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && isAnyAllowedFocusModeActivityRunning && !isBlockSuperDistractingFocusModeOn(){
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentUrlForAlignmentScore()
                            }
                            return;
                        }
                        var activityAllowUrls = [String]()
                        
                        
                        if !url.contains(defaultPageOfBrowser){
                            let path = getPathFromUrl(url: url)//getDomainFromUrl(url: url)
                            if isAnyAllowedFocusModeActivityRunning{
                                focusModeOpenCurrentUrlForAlignmentScore(domain: path)
                            }
                            if intentionBlockedUrlsWcObj != nil{
                                if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    let domain = getDomainFromUrl(url: url)
                                    if intentionBlockedUrlsVcObj?.tabUrl != domain{
                                        intentionBlockedUrlsWcObj?.window?.close()
                                    }
                                }
                            }
                            if setIntentionBlockedUrlsWcObj != nil{
                                if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
                                    let domain = getDomainFromUrl(url: url)
                                    if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                                        exitFullScreen(runningApp: runningApp)
                                    }else{
                                        setIntentionBlockedUrlsVcObj?.closeWindow()
                                    }
                                }
                            }
                            var isBlocked = false
                            var isAllowed = false
                            
                            
                            if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                                
                                if arrAllowedDomianInCuddlyModeCurrentFocus.count != 0{
                                    let domain = getDomainFromUrl(url: url)
                                    if arrAllowedDomianInCuddlyModeCurrentFocus.contains(domain){
                                        closePopupBlockWindowIfRunningForUrl()
                                        return;
                                    }
                                }
                            }
                            if arrAllowedUrlsInCuddlyModeCurrentFocus.contains(path){
                                closePopupBlockWindowIfRunningForUrl()
                                return;
                            }
                                
                            if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{// no need additional check
                                if url.contains("focus_bear_temporarily_allow=true"){
                                    var isAlwaysBlockedUrl = false
                                    for i in 0..<arrAlwaysBlockedSitesData.count{
                                        let dictionary = arrAlwaysBlockedSitesData[i]
                                        if let blockUrl = dictionary["url"] as? String{
                                            if blockUrl.lowercased() == path.lowercased(){
                                                arrAlwaysBlockedSitesData.remove(at: i)
                                                isAlwaysBlockedUrl = true
                                                break;
                                            }
                                        }
                                    }
                                    
                                    if isAlwaysBlockedUrl{
                                        if url.contains("?focus_bear_temporarily_allow=true"){
                                            setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "?focus_bear_temporarily_allow=true", with: ""))
                                        }else if url.contains("&focus_bear_temporarily_allow=true"){
                                            setUrlToBrowser(browser: currentBrowser, url: url.replacingOccurrences(of: "&focus_bear_temporarily_allow=true", with: ""))
                                        }
                                        
                                    }else{
                                        arrAllowedUrlsInCuddlyModeCurrentFocus.append(path)
                                        for i in 0..<arrBlockedUrlsInCuddlyModeCurrentFocus.count{
                                            if arrBlockedUrlsInCuddlyModeCurrentFocus[i].contains(path){
                                                arrBlockedUrlsInCuddlyModeCurrentFocus.remove(at: i)
                                                break;
                                            }
                                        }
                                    }
                                    return;
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
                            }else if currentState == ._SPECIAL_ACTIVITY_{
                                if currentHabitPlaying != nil{
                                    activityAllowUrls = currentHabitPlaying!.allowUrls
                                }
                                blockType = "special-activity"
                            }
                            
                            
                            
                            if isAnyAllowedFocusModeActivityRunning == false{
                                for turl in activityAllowUrls{
                                    isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                                    if isAllowed{
                                        break;
                                    }
                                }
                                
                                if !isAllowed{
                                    if let title = getActiveTabTitleOf(browser: currentBrowser)?.lowercased(){
                                        tabTitle = title
                                        for turl in activityAllowUrls{
                                            var starUrl: String = ""
                                            starUrl = "*" + turl.lowercased() + "*"
                                            isAllowed = wildcard(title, pattern: starUrl)
                                            if isAllowed{
                                                break;
                                            }
                                        }
                                    }
                                }
                            }else if isAnyAllowedFocusModeActivityRunning{

                                let isAllowedListApproachInFocus = currentRunningFocusType["isAllowedListApproach"] as? Bool ?? false
                                let arrAllowedUrlsForFocus = currentRunningFocusType["allowed_urls"] as? [String] ?? []
                                let arrBlockedUrlsForFocus = currentRunningFocusType["blockUrlsArray"] as? [String] ?? []
                                var currentRunningFocusModeName = currentRunningFocusType["name"] as? String ?? ""
                                if isAllowedListApproachInFocus{
                                    for turl in arrBlockedUrlsForFocus{
                                        isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
                                        if isBlocked{
                                            needToBlockImmediately = true
                                            break;
                                        }
                                    }
                                    
                                    
                                    if !isBlocked{
                                        for turl in arrAllowedUrlsForFocus{
                                            isAllowed = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
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
                                        isBlocked = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl)
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
                                        let arrBlockedUrls = getBlockedUrlsToBlock()
                                        for turl in arrBlockedUrls{
                                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                                            bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                            if bool{
                                                self.isCurrentUrlNotAllowedInCurrentFocsMode = true
                                                self.blockUrlsInBackground()
                                                return;
                                            }
                                        }
                                    }
                                }else{
                                    self.currentBrowserUrlForAi = ""
                                    self.timerForCheckUrlFromAiTimeOut?.invalidate()
                                    if !isAllowedListApproachInFocus{//Always blocked URLs should be blocked immediately even in cuddly bear mode#476
                                        var bool = false
                                        let arrBlockedUrls = getBlockedUrlsToBlock()
                                        for turl in arrBlockedUrls{
                                            //Change all suggested blocked apps in onboarding to start with https:// #1233
                                            bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                            if bool{
                                                self.blockUrlsInBackground()
                                            }
                                        }
                                    }else{//super distracting site is allowed in a Focus Mode and focus mode is running - result = should show intention popup. 756
                                        if !SettingsManagerObject.immediatelyBlockDistractingSites{
                                            var bool = false
                                            let arrBlockedUrls = getBlockedUrlsToBlock()
                                            for turl in arrBlockedUrls{
                                                //Change all suggested blocked apps in onboarding to start with https:// #1233
                                                bool = self.validation.isUrlAlwaysBlocked(urlToCheck: url, blockedUrl: turl)
                                                if bool{
                                                    self.isCurrentUrlAllowedInCurrentFocsMode = true
                                                    self.blockUrlsInBackground()
                                                }
                                            }
                                        }
                                    }
                                    if !isBlockSuperDistractingFocusModeOn(){
                                        if dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] == nil{
                                            addEntryInfocusAlignmentScoreCsv(url: path, tabTitle: tabTitle ?? "", focusMode: currentRunningFocusModeName, intention: whatToAchieveInFocusBlock, aiReason: "", allowedProbability: "1.0", totalScore: "")
                                            var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                                            reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path] = ["probability":1.0, "isVisibleUrl":true, "totalSeconds":0, "startedTime":Date(), "reason": reason]
                                            boxForStatusBarForTooltip?.customToolTip = reason
                                        }else{
                                            var reason = appAllowedInFocusModeText.replacingOccurrences(of: "<APP>", with: path)
                                            reason = reason.replacingOccurrences(of: "<FOCUSMODE>", with: currentRunningFocusModeName)
                                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["probability"] = 1.0
                                            dictionaryScoreAiCheckUrlsInCuddlyModeCurrentFocus[path]!["reason"] = reason
                                        }
                                        
                                        calculateFocusAlignmentScore()
                                    }
                                    //                                    return// no need to return here
                                }
                            }
                            
                            
                            if !isAllowed{
                                
                                tabUrl = path
                                fullUrl = url
                                url = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? url
                                
                                var cuddly_bear_modeString = ""
                                var aiReasonToBlockString = ""
                                if isCuddlyModeEnabled() && isAnyAllowedFocusModeActivityRunning{
                                    cuddly_bear_modeString = "&cuddly_bear_mode=true"
                                    aiReasonToBlockString = "<AIREASON>"
                                }
                                
                                switch currentBrowser{
                                    
                                case ._SAFARI_:
                                    script = getSafariBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._GOOGLE_CHROME_:
                                    script = getGoogleChromeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                  
                                case ._OPERA_:
                                    script = getOperaBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._OPERA_GX_:
                                    script = getOperaGxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._VIVALDI_:
                                    script = getVivaldiBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._BRAVE_BROWSER_:
                                    script = getBraveBrowserBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._SIDEKICK_:
                                    script = getSidekickBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case ._MICROSOFT_EDGE_:
                                    script = getMicrosoftEdgeBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                  
                                case ._ARC_:
                                    script = getArcBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                case ._FIREFOX_:
                                    script = getFirefoxBlockScript(url: url).replacingOccurrences(of: "<PARAMS>", with: "&block_type=\(blockType)\(cuddly_bear_modeString)\(aiReasonToBlockString)")
                                    
                                case .none:
                                    closePopupBlockWindowIfRunningForUrl()
                                    return
                                }
                                
                            }else{
                                closePopupBlockWindowIfRunningForUrl()
                                return
                            }
                        }else{
                            self.closeSetIntentionBlockedUrlsWinddowIfVisible()
                            self.closeIntentionBlockedUrlsWinddowIfVisible()
                            closePopupBlockWindowIfRunningForUrl()
                            
                            if isCuddlyModeEnabled() && SettingsManagerObject.isAiCheckUrlEnabled && isAnyAllowedFocusModeActivityRunning && !isBlockSuperDistractingFocusModeOn(){
                                setFocusBearIconToNormal()
                                focusModeCloseCurrentUrlForAlignmentScore()
                            }
                            return;
                        }
                        
                    }else{
                        closePopupBlockWindowIfRunningForUrl()
                        return;
                    }
                    
                    if isAnyAllowedFocusModeActivityRunning{
                        if needToBlockImmediately{
                            self.focusBlockUnwantedUrl(script: script, url: tabUrl, lastBlockReasonFromAi: nil, browser: currentBrowser, isUrlBlockByAi: false, blockReason: "block_in_focus_mode")
                        }else{
                            self.focusTryToBlockUnwantedUrl(script: script, url: tabUrl, browser: currentBrowser, tabTitle: tabTitle, fullUrl: fullUrl, runningApp:runningApp)
                        }
                    }else{
                        self.currentBrowserUrlForAi = ""
                        self.timerForCheckUrlFromAiTimeOut?.invalidate()
                        addLog(text:"blockActivityBlockedUrl:- \(tabUrl)")
                        executeScript(script: script)
                        allApiObject.capturePosthog(event: "block-distracting-url", metadata: ["block-reason":"block_in_habit"])
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
                    arrWindows[i].windowController?.window = nil
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
        if isMainWindowLoaded{
            if (mainWindowControllerObj?.window!.isVisible)!{
                let screenList = NSScreen.screens
                for screen in screenList {  // create the corresponding windows
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
                let oldDaysLeft = daysLeft
                daysLeft = 0
                isPurchased = false
                switch(result) {
                case .success(let credentials):
                    
                    let _ = self.credentialsManager.store(credentials: credentials)
                    // If you have Refresh Token Rotation enabled, you get a new Refresh Token
                    // Otherwise you only get a new Access Token
                    
                    self.credential = credentials
                    self.user = AuthUser(from: self.credential!.accessToken)
                    
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
                    if isPurchased == false && daysLeft == 0{
                        isExpired = true
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
                addLog(text: "[user-action] menu Item Uninstall Clicked")
                if uninstallingConfirmVcObj == nil{
                    uninstallingConfirmVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("uninstallingConfirmVc")) as? uninstallingConfirmVc
                }
                askLogInWcObj?.contentViewController?.presentAsSheet(uninstallingConfirmVcObj!)
            }
        }
        
    }
    
    var hotKeyStartPomodoro: HotKey? {
        didSet {
            guard let hotKey = hotKeyStartPomodoro else {
                return
            }
            hotKey.keyDownHandler = { [weak self] in
                print("Pressed at \(Date())")
                addLog(text: "Shortcut start Pomodoro Pressed")
                let isFocusModeOnOrPaused = isFocusModeOnOrPaused()
                
                if isFocusModeOnOrPaused{
                    addLog(text: "FocusMode is On Or Paused:- return")
                    return;
                }else{
                    if isHardCorePomodoroModeOn{
                        addLog(text: "HardCore Pomodoro Mode is On:- return")
                        return;
                    }else{
                        if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._SPECIAL_ACTIVITY_{
                            
                            addLog(text: "Activity is running:- return")
                            return;
                        }
                    }
                }
                self?.menuShowPomodoroModeView()
            }
        }
    }
    
    func registerPomodoroShortcut() {
        hotKeyStartPomodoro = HotKey(keyCombo: KeyCombo(stkey: char, modifiers: flags))
    }
    
    func unregisterPomodoroShortcut() {
        hotKeyStartPomodoro = nil
    }
}


//  always block url ka kaam hua
// flickering sahi krdi aaj
//
// custom routine ban jay


// version 321
// bug solved
// open task player option in menu added for in allowed focus mode habit
// task player bug solved
// the blocking schedule preference seems to reset to "Only when I ask you to". I've changed it to All the time at least 3 times and it keeps going back    :- solved 
//  intention bug solved


// documetn bnao. // todo
//message not user friendlu // todo  /// onboarding browsers k liye


// bug :- brekas in postpone focus summary // done
//
//user-settings-updated done alert
