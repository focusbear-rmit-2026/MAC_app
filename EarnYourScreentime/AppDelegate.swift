//
//  AppDelegate.swift
//  EarnYourScreentime
//
//  Created by Prashant Sawnani on 01/01/22.
//  .
//


import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusBarMenu: NSMenu!
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var statusbutton:NSStatusBarButton?
    
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
    var timerBackgroundThread:Timer?
    func applicationWillFinishLaunching(_ notification: Notification) {
        
        //        let domain = Bundle.main.bundleIdentifier!//todo
        //        UserDefaults.standard.removePersistentDomain(forName: domain)
        //        UserDefaults.standard.synchronize()
        //        return;
        
        avmonitor.start()
      //  Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkState), userInfo: nil, repeats: true)
        //print(isCameraOn())
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
        readConfigFile()
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) == nil{
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsFirstRunDate)
        }
        
        let char = "k"
        var flags = NSEvent.modifierFlags
        flags.insert(.control)
        flags.insert(.command)
        hotKeyClearUserdefaults = HotKey(keyCombo: KeyCombo(stkey: char, modifiers: flags))
        
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
                            print(jsonResult)
                            
                        }
                        
                    }catch {
                        print(error)
                    }
                    
                } catch {
                    // handle error
                }
                
            }
        }
        if let morningHabits = jsonResult.value(forKey: "morningHabits") as? [NSDictionary] {
            print("morningHabits")
            print(morningHabits)
            for habitDic in morningHabits {
                let name = habitDic["name"] as? String ?? ""
                let durationSeconds = habitDic["durationSeconds"] as? Int ?? 0
                let videoUrl = habitDic["videoUrl"] as? String
                arrAllHabits.append(morningHabit(name: name, durationSeconds: durationSeconds, url: videoUrl))
            }
        }
        
        if let breakActivities = jsonResult.value(forKey: "breakActivities") as? [NSDictionary] {
            print("breakActivities")
            print(breakActivities)
            for activityDic in breakActivities {
                let name = activityDic["name"] as? String ?? ""
                let durationSeconds = activityDic["durationSeconds"] as? Int ?? 0
                let IncludeInEveryBreak = activityDic["includeInEveryBreak"] as? Bool ?? false
                let videoUrl = activityDic["videoUrl"] as? String
                arrAllbreakActivities.append(breakActivity(name: name, durationSeconds: durationSeconds, IncludeInEveryBreak: IncludeInEveryBreak, url: videoUrl))
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
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
            isAppEnable = true
        }
        if let state = UserDefaults.standard.object(forKey: kUserdefaultsIsAppEnabled) as? Bool{
            isAppEnable = state
            if state{
                checkWindowState()
            }else{
                
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
                appdelegate?.quitAndRestartApp()
                return;
            }
            
        }
        
        LaunchOnStartup.setLaunchAtStartup(true)
        
        if statusItem.button != nil
        {
            statusbutton = statusItem.button
            
            statusbutton?.image = NSImage(named: NSImage.Name("clock22"))//)//Name("pagesLatex_small"))
            statusBarMenu = NSMenu(title: "Status Bar Menu")
            if !isAppEnable{
                statusBarMenu.addItem(withTitle: "Reactivate",action: #selector(menuItem_Reactivate(sender:)),keyEquivalent: "")
            }
            statusBarMenu.addItem(withTitle: "Settings",action: #selector(menuItem_ChangeJson(sender:)),keyEquivalent: "")
            statusBarMenu.addItem(withTitle: "Quit",action: #selector(menuItem_Quit(sender:)),keyEquivalent: "")
            statusItem.menu = statusBarMenu
        }
        
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
                            print("command contain")
                        }
                    }
                    
                }
                return event
        }
            
        )
    }
//    @objc func checkState(){
//        if avmonitor.currentState == NSControl.StateValue.on{
//            print("microphone is on")
//        }else{
//            print("microphone is off")
//        }
//    }
    @objc func menuItem_Reactivate(sender:NSMenuItem){
        timerCheckReactivateTime?.invalidate()
        timerCheckReactivateTime = nil
        UserDefaults.standard.set(true, forKey: kUserdefaultsIsAppEnabled)
        UserDefaults.standard.removeObject(forKey: kUserdefaults4HourReActivateTime)
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
                    appdelegate?.quitAndRestartApp()
                }
            }else{
                self.timerCheckReactivateTime?.invalidate()
                self.timerCheckReactivateTime = nil
            }
        }
    }
    @objc func menuItem_ChangeJson(sender:NSMenuItem) {
        selectJsonWindowControllerObj!.showWindow(self)
        selectJsonVcObj?.setData()
        NSApplication.shared.activate(ignoringOtherApps: true)
        return;
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["json"]
        // openPanel.beginSheetModal(for: self.view.window!) { response in
        //            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
        //                return
        //            }
        let button: NSApplication.ModalResponse = openPanel.runModal()
        if button == NSApplication.ModalResponse.OK {
            if let url = openPanel.url {
                do {
                    let data = try Data(contentsOf: url, options: .mappedIfSafe)
                    
                    
                    do {
                        if let jsonResult: NSDictionary = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary {
                            UserDefaults.standard.set(jsonResult, forKey: kUserdefaultsSelectedJson)
                            quitAndRestartApp()
                            
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
    @objc func checkWindowState(){//there will be no habit display on first day
//                startHabitsCall()
        
//        mainWindowControllerObj?.showWindow(self)
//        mainViewControllerObj!.showFirstTimeVc()
//        isFirstRun = true
//                mainWindowControllerObj?.showWindow(self)
//                mainViewControllerObj?.startBreakActivities()
//                shutOffMac()
        //        setShutOffTimer()
        //
//                return; //todo®
        if UserDefaults.standard.object(forKey: kUserdefaultsFirstRun) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
            mainWindowControllerObj?.showWindow(self)
            mainViewControllerObj!.showFirstTimeVc()
            isFirstRun = true
            //            setShutOffTimer()
        }else{
            isFirstRun = false
            if let lastHabitShowDate = UserDefaults.standard.object(forKey: kUserdefaultsLastHabitShowDate) as? Date{
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
                // if let distance = lastHabitShowDate.fullDistance(from: Date(), resultIn: .day){
//                if isHabitAlreadyShowed{//it means no habit shown at current date
//                    mainWindowControllerObj?.loadWindow()
//                    mainViewControllerObj?.setActivityTimer()
//                    //setShutOffTimer()
//                    //  return
//                }else{
//
//                }
                // }
            }
            //            setShutOffTimer()
            
//            if shutOffTime != nil{
//                let date = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
//                if Date().compare(date) == .orderedAscending {
//                    print("First Date is smaller then second date. all ok ")
//
//                }else{
//                    shutOffMac()
//                }
//            }
//
//            if startTime != nil && !isHabitAlreadyShowed{
//                let date = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: Date())!
//                if Date().compare(date) == .orderedAscending {
//                    print("First Date is smaller then second date. all ok ")
//                    //                    let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(startHabitsCall), userInfo: nil, repeats: false)
//                    //                    RunLoop.main.add(timer, forMode: .common)
//                    shutOffMac()
//                }else{
//                    //                                start habit
//                    startHabitsCall()
//                }
//            }
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
                            //first date is smaller than second
                            // self.shutOffMac()
                        }else{
                            self.startHabitsCall()
                           // return;
                        }
                    }else{
                        mainWindowControllerObj?.loadWindow()
                        mainViewControllerObj?.setActivityTimer()
                    }
                }
            }
            
            //   if isHabitAlreadyShowed{
            
            // }
            
        }
        setBackgroundThreadTimer()
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
//            if !isHabitAlreadyShowed && currentState == ._SHUTOFFMAC_ && !isFirstRun{
//
//                if Date().compare(startDate) == .orderedAscending {
//                    print("First Date is smaller then second date. all ok ")
//                    //first date is smaller than second
//                    // self.shutOffMac()
//                }else{
//                    self.startHabitsCall()
//                    return;
//                }
//            }
            // if currentState != ._SHUTOFFMAC_{
            
            
//            if Date().compare(shutOffdate) == .orderedAscending {
//                print("First Date is smaller then second date. all ok ")
//
//            }else{
//                self.shutOffMac()
//            }
            
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
        
        if avmonitor.currentState == NSControl.StateValue.on{
            return;
        }
        //        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        //        let date = Calendar.current.date(bySettingHour: startTime!.hour, minute: startTime!.minute, second: startTime!.second, of: tomorrowDate)!
        //        if Date().compare(date) == .orderedAscending {
        //            print("First Date is smaller then second date. all ok ")
        //            let timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(startHabitsCall), userInfo: nil, repeats: false)
        //            RunLoop.main.add(timer, forMode: .common)
        //        }
        //        print("runCode")
        //
        abortAllProcess()
        if !(mainWindowControllerObj?.window!.isVisible)! {
            mainWindowControllerObj?.showWindow(self)
        }
        mainViewControllerObj!.shutOffMac()
        isHabitAlreadyShowed = false
    }
    
    func abortAllProcess(){
        if (mainWindowControllerObj?.window!.isVisible)! {
            if isHabitGoing {
                isHabitGoing = false
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        if currentAction == ._INPROGRESS_{
                            if timerViewcontrollerObj?.webView.isHidden == false{
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
            }
            else if isBreakActivitiesGoing {
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        if currentAction == ._INPROGRESS_{
                            if timerViewcontrollerObj?.webView.isHidden == false{
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
                isBreakActivitiesGoing = false
            }else if isBreathingGoing {
                if timerViewcontrollerObj != nil {
                    if timerViewcontrollerObj?.timer != nil {
                        timerViewcontrollerObj?.timer?.invalidate()
                        if currentAction == ._INPROGRESS_{
                            if timerViewcontrollerObj?.webView.isHidden == false{
                                timerViewcontrollerObj?.loadBlankUrl()
                            }
                        }
                    }
                }
                isBreathingGoing = false
            }
        }
    }
    @objc func setStartTimer(){
        
    }
    
    @objc func startHabitsCall(){
        //        if currentState == ._SHUTOFFMAC_{
        //            return;
        //        }
        UserDefaults.standard.removeObject(forKey: kUserdefaultsShutdownAborted)
        
        if avmonitor.currentState == NSControl.StateValue.on{
            mainWindowControllerObj?.loadWindow()
            mainViewControllerObj?.setActivityTimer()
            return;
        }
        if arrAllHabits.count != 0 {
            isHabitAlreadyShowed = true
            mainWindowControllerObj?.showWindow(self)
            mainViewControllerObj!.showAllHabits()
            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
        }
    }
    @objc func menuItem_Quit(sender:NSMenuItem) {
        terminateFromSelf = true
        NSApp.terminate(self)
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if terminateFromSelf {
            terminateFromSelf = false
            return .terminateNow
        }else {
            return .terminateCancel
        }
    }
}



