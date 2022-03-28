//
//  AppDelegate.swift
//  EarnYourScreentime
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
                
                let domain = Bundle.main.bundleIdentifier!
                UserDefaults.standard.removePersistentDomain(forName: domain)
                UserDefaults.standard.synchronize()
                
                self!.quitAndRestartApp()
            }
        }
    }
    var timerCheckReactivateTime:Timer?
    var timerCheckClearPasswordTime:Timer?
    var timerBackgroundThread:Timer?
    func applicationWillFinishLaunching(_ notification: Notification) {

        //        let domain = Bundle.main.bundleIdentifier!//todo
        //        UserDefaults.standard.removePersistentDomain(forName: domain)
        //        UserDefaults.standard.synchronize()
        //        return;

        updater = SUUpdater(for: Bundle.main)
        updater?.delegate = self
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(frontApplicationChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
//        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didActivateApplicationNotification, object: nil)


        var isDefaultContain = false
        if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrFocusTypes) as? [[String:Any]]{
            arrFocusType = arr

            for i in 0..<arrFocusType.count{
                arrFocusType[i]["isOn"] = false
                if let state = arrFocusType[i]["isDefault"] as? Bool{//this key will only be awailable in default focus type
                    if  state{
                        isDefaultContain = state
                    }
                }
            }

        }
        if !isDefaultContain{
            let dic:[String:Any] = ["name":"Default", "color": getColorString(color: NSColor(red: 208/255, green: 150/255, blue: 60/255, alpha: 1)), "appsArray": [], "urlsArray": [], "isOn": false, "isAllowedAllApps":true, "isAllowedAllUrls":true, "isDefault":true]
            arrFocusType.insert(dic, at: 0)
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)

        if let arr = UserDefaults.standard.object(forKey: kUserdefaultsArrBlockedUrls) as? [String]{
            arrBlockedUrls = arr
        }
        
        // ----------------SET APP INSTALL DATE---------------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }

        //  ---------------------------POMODORO MODE--------------------------
        if UserDefaults.standard.object(forKey: kUserdefaultsPomodoroModeEnabled) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsPomodoroModeEnabled)
        }

        //  ----------------------START APP AT LOGIN-----------------------
        LaunchOnStartup.setLaunchAtStartup(true)



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

        if !fileManager.fileExists(atPath: blockURL!.path){
            if let path = Bundle.main.path(forResource: "block", ofType: "html") {
                let url = URL(fileURLWithPath: path)
                do{
                    try fileManager.moveItem(at: url, to: blockURL!)
                }catch{
                    print(error)
                }
            }
        }
        blockWebUrlString = blockURL!.absoluteString
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




        // ///////////////////SET TOP ICON////////////////////////
        if self.statusItem.button != nil {
            self.statusbutton = self.statusItem.button
            self.statusbutton?.image = NSImage(named: NSImage.Name("clock22"))//)//Name("pagesLatex_small"))
        }

        DispatchQueue.global().async {
            avmonitor.isMicOn()//.start()
            avmonitor.isACameraOn()//.checkCamera()
        }





        getConfigFile(completionHandler: {dic in
            print("response mila")
            if dic != nil{ 
                configjson = dic!
            }else{
                if let path = Bundle.main.path(forResource: "config", ofType: "json") {
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
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        SentrySDK.start { options in
            options.dsn = "https://d364747efa3a4925a0679266c4ecbd24@o1162655.ingest.sentry.io/6250138"
            options.debug = true // Enabled debug when first installing is always helpful
        }
        
//        let error = NSError(domain: "YourErrorDomain", code: 0, userInfo: nil)
//        let id = SentrySDK.capture(error: error)
//        print(id)
       // var id:Int?
       // print(id!)
        updater?.checkForUpdatesInBackground()
    }
    
    func updaterWillRelaunchApplication(_ updater: SUUpdater) {
        addLog(text: "updater Will Relaunch Application")
        terminateFromSelf = true
    }
    //    @objc func checkState(){
    //        if avmonitor.currentState == NSControl.StateValue.on{
    //            print("microphone is on")
    //        }else{
    //            print("microphone is off")
    //        }
    //    }
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
                    var daysremaining = 7-numberOfDays_afterinstall
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
        
        //        }
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
                arrAllMorningHabits.append(habit(name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion))
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
                arrAllEveningHabits.append(habit(name: name, durationSeconds: durationSeconds, urlsArray: videoUrl, logQuantity: logQuantity, logQuantityQuestion: logQuantityQuestion))
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
                        let logQuantityQuestion = dic["logQuantityQuestion"] as? String
                        let choice = activityChoice(name: name, urlsArray: videoUrl, logQuantityQuestion: logQuantityQuestion)
                        arrChoices.append(choice)
                    }
                }
                if arrChoices.count == 0{
                    isRandomChoice = false
                }
                let logQuantityQuestion = activityDic["logQuantityQuestion"] as? String
                arrAllbreakActivities.append(breakActivity(name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, urlsArray: videoUrl, logQuantity:logQuantity, isRandomChoice: isRandomChoice, choices: arrChoices, logQuantityQuestion: logQuantityQuestion))
            }
        }
        if let breakMinutes = jsonResult.value(forKey: "breakAfterMinutes") as? Int {
            print("breakAfterMinutes")
            breakAfterMinutes = breakMinutes
            print(breakAfterMinutes)
        }
        
        if let val = jsonResult.value(forKey: "showEveryBreak") as? Bool {
            showEveryBreak = val
        }else{
            showEveryBreak = false
        }
        
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
                if UserDefaults.standard.object(forKey: kUserdefaultsShowPomodoroView) != nil{//it means app was avorted from morning habit and its time to show pomodoro mode view
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
                    showPomodoroModeView()
                }
            }else{
                if UserDefaults.standard.object(forKey: kUserdefaultsShowPomodoroView) != nil{//it means app was avorted from morning habit and its time to show pomodoro mode view
                    UserDefaults.standard.removeObject(forKey: kUserdefaultsShowPomodoroView)
                    showPomodoroModeView()
                }
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
                                            thirdVcObj?.btnMainClicked(self)
                                        }
                                    }
                                    
                                }else if currentAction == ._START_ {
                                    if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._BREATHING_{
                                        if (mainViewControllerObj?.containerView.subviews.contains(firstViewControllerObj!.view))!{
                                                firstViewControllerObj?.btnStartFirstHabitClicked(self)
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
    
    @objc func showPomodoroModeView(){//todo try common window here
        if isFocusModeOn(){
            return
        }
        if focusModeStartWindowLodded{
            if startingFocusWindowControllerObj?.window?.isVisible ?? false{
                return
            }
        }
        let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
        let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
        
        let currentDate = Date()
        if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
            return;//if not working hours then return
        }
        pomodoroWindowControllerObj?.contentViewController = pomodoroVcObj
        pomodoroWindowControllerObj?.showWindow(self)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
//    func showPomodoroModeFocusCompletedView(){
//        pomodoroWindowControllerObj?.contentViewController = focusCompletedVcObj
//        pomodoroWindowControllerObj?.showWindow(self)
//    }
    @objc func checkWindowState(){//there will be no habit display on first day
//        isHabitAlreadyShowed = false
//        startHabitsCall()
//
//        mainWindowControllerObj?.showWindow(self)
//        mainViewControllerObj!.showAllMorningHabits()
//
//        mainWindowControllerObj?.showWindow(self)
//        mainViewControllerObj!.showFirstTimeVc()
//        isFirstRun = true
//        mainWindowControllerObj?.showWindow(self)
//        mainViewControllerObj?.startBreakActivities()
//        mainViewControllerObj?.startBreakActivities()
//        showBlankWindowInSecondaryMonitor()
//        shutOffMac()
//        setShutOffTimer()
//
//        if arrAllEveningHabits.count != 0 {
//            mainWindowControllerObj?.showWindow(self)
//            mainViewControllerObj!.showAllEveningHabits()
//        }
//        showPomodoroModeView()
//        mainWindowControllerObj?.showWindow(self)
//        mainViewControllerObj?.showFocusSummaryView()
//        showPomodoroModeView()
//        mainViewControllerObj?.shutOffMac()
//        return; //todo®
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
            mainWindowControllerObj?.showWindow(self)
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj!.showFirstTimeVc()
            isFirstRun = true
            //  isHabitAlreadyShowed ko kuch ni krna h qki default hi true h .. or kis sessioon mai app install hui h us session mai habit show ni hogi  isiliye true hi rakhna h shut offf hote hi false ho jaygi
        }else{
            isFirstRun = false
            if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
//                isHabitAlreadyShowed = true
//                let year1 = Calendar.current.component(.year, from: lastHabitShowDate)
//                let year2 = Calendar.current.component(.year, from: Date())
//
//
//
//                if year2>year1{
//                    isHabitAlreadyShowed = false
//                }else{
//                    if year1 == year2{
//                        let month1 = Calendar.current.component(.month, from: lastHabitShowDate)
//                        let month2 = Calendar.current.component(.month, from: Date())
//                        if month2>month1{
//                            isHabitAlreadyShowed = false
//                        }else{
//                            if month1 == month2{
//                                let day1 = Calendar.current.component(.day, from: lastHabitShowDate)
//                                let day2 = Calendar.current.component(.day, from: Date())
//                                if day2>day1{
//                                    isHabitAlreadyShowed = false
//                                }
//                            }
//                        }
//                    }
//                }
                checkLastHabitShowDate(lastHabitShowDate: lastHabitShowDate)
            }else{
                isHabitAlreadyShowed = false
            }
            
            if startTime != nil && shutOffTime != nil{
                let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
                let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
                
                let currentDate = Date()
                if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
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
    @objc func backgroundThread(){
        DispatchQueue.main.async {
            if startTime == nil || shutOffTime == nil{
                return;
            }
            let startDate = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
            let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
            
            
            let currentDate = Date()
            if currentDate.compare(startDate) == .orderedAscending  || currentDate.compare(shutOffdate) == .orderedDescending{
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
                        //first date is smaller than second
                        // self.shutOffMac()
                    }else{
                        self.startHabitsCall()
                        // return;
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
        
        if avmonitor.isMicOn(){
            addLog(text: "Mic is in use, Shut off Cancelled.")
            return;
        }
        if avmonitor.isACameraOn(){
            addLog(text: "Camera is in use, Shut off Cancelled.")
            return;
        }
        
        if currentState == ._EVENING_HABIT_ || currentState == ._FOCUS_COMPLETED_ || currentState == ._FOCUS_SUMMARY_{
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
            if focusPreferencesVcObj != nil{
                if (preferencesWindowControllerObj?.window!.isVisible)!{
                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                        if tabview.selectedTabViewItemIndex == 1{
                            focusPreferencesVcObj?.focusModeFinished()
                        }
                    }
                }
            }
            return;
        }
        var iseveningHabitAlreadyShowed = true
        if let eveningRoutineDate = getEveningRoutineDate(){
            iseveningHabitAlreadyShowed = true
            let year1 = Calendar.current.component(.year, from: eveningRoutineDate)
            let year2 = Calendar.current.component(.year, from: Date())
            
            
            
            if year2>year1{
                iseveningHabitAlreadyShowed = false
            }else{
                if year1 == year2{
                    let month1 = Calendar.current.component(.month, from: eveningRoutineDate)
                    let month2 = Calendar.current.component(.month, from: Date())
                    if month2>month1{
                        iseveningHabitAlreadyShowed = false
                    }else{
                        if month1 == month2{
                            let day1 = Calendar.current.component(.day, from: eveningRoutineDate)
                            let day2 = Calendar.current.component(.day, from: Date())
                            if day2>day1{
                                iseveningHabitAlreadyShowed = false
                            }
                        }
                    }
                }
            }
        }else{
            iseveningHabitAlreadyShowed = false
        }
        
        
        if UserDefaults.standard.object(forKey: kUserdefaultsFocusSummaryShowedTillDate) as? Date == nil{
            if !(mainWindowControllerObj?.window!.isVisible)! {
                mainWindowControllerObj?.showWindow(self)
            }
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj!.showFocusSummaryView()
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
        
        if arrAllEveningHabits.count != 0 && !iseveningHabitAlreadyShowed {
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
        if (mainWindowControllerObj?.window!.isVisible)! {
            if currentAction == ._INPROGRESS_{
                if currentState == ._MORNING_HABIT_ || currentState == ._EVENING_HABIT_ || currentState == ._ACTIVITY_ || currentState == ._BREATHING_{
                    if timerViewcontrollerObj != nil {
                        if timerViewcontrollerObj?.timer != nil {
                            timerViewcontrollerObj?.timer?.invalidate()
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
            return;
        }
        if avmonitor.isACameraOn(){
            mainWindowControllerObj?.loadWindow()
            mainViewControllerObj?.setActivityTimer()
            addLog(text: "Camera is is use, Morning Habits cancelled.")
            return;
        }
        
        //read file
//        if let path = UserDefaults.standard.object(forKey: kUserdefaultsSelectedFolder) as? String{
//             let url = URL(fileURLWithPath: path)
//            do {
//                let stringDate = try String(contentsOf: url.appendingPathComponent("timestamp.txt"), encoding: .utf8)
//                if let date = getDateFromString(date: stringDate, dateFormat: "yyyy-MM-dd HH:mm:ss"){
//                    checkLastHabitShowDate(lastHabitShowDate: date)
//                }
//            }catch{
//                print(error)
//            }
//        }
        if let morningRoutineDate = getMorningRoutineDate(){
            checkLastHabitShowDate(lastHabitShowDate: morningRoutineDate)
        }
        if isHabitAlreadyShowed{
            return;
        }
        if arrAllMorningHabits.count != 0 {
            isHabitAlreadyShowed = true
            mainWindowControllerObj?.showWindow(self)
            mainViewControllerObj!.showAllMorningHabits()
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
            
            writeMorningRoutineDate()
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
            var daysremaining = 7-numberOfDays_afterinstall
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
        terminateFromSelf = true
        NSApp.terminate(self)
    }
    
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        addLog(text: "Application Will Terminate")
    }
 
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if terminateFromSelf {
            terminateFromSelf = false
            return .terminateNow
        }else {
            return .terminateCancel
        }
    }
    
    func setFocusModeTimer(hour:Int?, minute:Int?){
        DispatchQueue.global().async {
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
        for i in 0..<arrFocusType.count{
            arrFocusType[i]["isOn"] = false
        }
        if timerForFocusMode != nil{
                    timerForFocusMode?.invalidate()
        //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            self.statusbutton?.backgroundcolor = NSColor.clear
        }
        
        isFocusTimeType = ._NONE_
        if self.timerAllowUrl != nil{
            self.timerAllowUrl!.invalidate()
            //self.timerAllowUrl = nil
            print("invalidtate")
        }
        timerCheckAllowedApps?.invalidate()
    }
    @objc func focusModeTimerFinished(){
        DispatchQueue.main.async {
            if focusPreferencesVcObj != nil{
                if (preferencesWindowControllerObj?.window!.isVisible)!{
                    if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
                        if tabview.selectedTabViewItemIndex == 1{
                            focusPreferencesVcObj?.focusModeFinished()
                        }
                    }
                }
            }
        }
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
        var currentFocusModeName = ""
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["isOn"] as? Bool == true{
                arrFocusType[i]["isOn"] = false
                currentFocusModeName = arrFocusType[i]["name"] as? String ?? ""
            }
        }
        if timerForFocusMode != nil{
                    timerForFocusMode?.invalidate()
        //            timerForFocusMode = nil
        }
        DispatchQueue.main.async {
            self.statusbutton?.backgroundcolor = NSColor.clear
        }
        
        isFocusTimeType = ._NONE_
        if self.timerAllowUrl != nil{
            self.timerAllowUrl!.invalidate()
            //self.timerAllowUrl = nil
            print("invalidtate")
        }
        timerCheckAllowedApps?.invalidate()
        
        DispatchQueue.main.async {
            if !(mainWindowControllerObj?.window!.isVisible)!{
                mainWindowControllerObj?.showWindow(self)
            }
            showBlankWindowInSecondaryMonitor()
            mainViewControllerObj!.showFocusCompletedView()
            print("fromShutOff")
            print(fromShutOff)
            focusCompletedVcObj?.resetData(focusModeName: currentFocusModeName, fromShutOff: fromShutOff)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        
    }
    
    @objc func focusModeStartted(){
        var stringTime = ""
        
        if let date = endFocusModeTime{
            stringTime = getStringFromDate(date: date, dateFormat: "hh:mm a")
        }
        addLog(text: "focus mode Started until - \(stringTime)")
        fillAllowUrlArray()
        fillAllowAppArray()
        frontApplicationChanged()//ak bar khud hi call krdenge qki phle se bhi active ho skti h
        
        DispatchQueue.global().async {
            self.timerCheckAllowedApps?.invalidate()
            self.timerCheckAllowedApps = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.checkAllowedApp), userInfo: nil, repeats: true)
            RunLoop.current.add(self.timerCheckAllowedApps!, forMode: RunLoop.Mode.common)
            RunLoop.current.run()
        }
        if isPomodoroWindowLodded{
            if pomodoroWindowControllerObj!.window!.isVisible{
                pomodoroWindowControllerObj?.window?.close()
            }
        }
    }
    func fillAllowUrlArray(){
        isAllowedAllUrlsInFocus = false
        allowUrl.removeAll()
        for dic in arrFocusType{
            if dic["isOn"] as? Bool == true{
                if dic["isAllowedAllUrls"] as? Bool == true{
                    isAllowedAllUrlsInFocus = true
                }
                allowUrl = dic["urlsArray"] as? [String] ?? []
            }
        }
//        allowUrl.append("eyst-focus.html")
//        allowUrl.append("earnyourscreentime.com")
//        allowUrl.append("devtools://")
//        allowUrl.append("chrome-extension://")
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
    
    var timerBlockUrl:Timer?//block urls list
    @objc func frontApplicationChanged(){
        timerBlockUrl?.invalidate()
        if isFocusModeOn(){
            if let runningApp = NSWorkspace.shared.frontmostApplication{
                print(runningApp.localizedName)
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
                        //                            self.perform(#selector(self.checkAllowedApp), with: nil, afterDelay: 1)
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                            //                    self.timerAllowUrl = nil
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
                    }
                }
            }
        }
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
                        //                    self.perform(#selector(checkAllowedApp), with: nil, afterDelay: 1)
                        if self.timerAllowUrl != nil{
                            self.timerAllowUrl!.invalidate()
                            //                    self.timerAllowUrl = nil
                            print("invalidtate22")
                        }
                        return
                    }
                    
//                }
            }
        }
    }
 
    var allowUrl = [""]
    var defaultAllowedUrl = ["eyst-focus.html",
                             "earnyourscreentime.com",
                             "devtools://",
                             "chrome-extension://"]
    
    var allowAppsPath = [""]
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
                                
                                var bool = false
                                for turl in self.allowUrl{
                                    bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if bool{
                                        break;
                                    }
                                }
                                if !bool{
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
                                var bool = false
                                for turl in self.allowUrl{
                                    bool = self.validation.isUrlValid(urlToCheck: url, allowUrl: turl, domain: domain)
                                    if bool{
                                        break;
                                    }
                                }
                                if !bool{
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
            let screenList = NSScreen.screens
            for screen in screenList {  // create the corresponding windows
                //                     resetWin(BGWindow(contentRect: NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), styleMask: .borderless, backing: .buffered, defer: true, screen: screen))
                mainWindowControllerObj!.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
                break;
            }
            hideBlankWindowInSecondaryMonitor()
            showExtraWindows()
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
    
    func setTimerForPomodoroMode(){// take a five minut k break per call hoga agar pomodoro mode finish hua h to. normal focus mode finish per call ni hoga ..
        self.perform(#selector(showPomodoroModeView), with: nil, afterDelay: 60*5)
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
