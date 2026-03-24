//
//  showHideWindows.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

//func showStartingFocusMode(focusModeIndex: Int, focusType: String){
//    addLog(text: "Showing Starting Focus Mode view")
//    startingFocusWindowControllerObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
//    startingFocusWindowControllerObj?.contentViewController = startingFocusModeVcObj
//    startingFocusWindowControllerObj?.showWindow(nil)
//    startingFocusModeVcObj?.ResetData(focusModeIndex: focusModeIndex, focusType: focusType)
//    NSApplication.shared.activate(ignoringOtherApps: true)
//}
func showAbortingFocusModeVc(forPause:Bool){// abortview for pause only in strict mode
    addLog(text: "Showing Abort focus mode view")
    if currentFocusModeStrictness == ._STRICT_{
//        startingFocusWindowControllerObj?.contentViewController = abortingFocusModeVcObj
//        startingFocusWindowControllerObj?.showWindow(nil)
        
        mainWindowControllerObj?.showWindow(nil)
        leftMenuVcObj!.showFocusAbortedView()
        abortingFocusModeVcObj?.ResetData(forPause: forPause)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }else{
        isHardCorePomodoroModeOn = false
        appdelegate?.tryFocusModeFinished(isSilent: false, isShutOffTime: false, isMorningRoutineTime: false, allowExtend:false, isCustomRoutineTime:false)
    }
}

//***********SHOW completion Requirements View***************//
func showcompletionRequirementsWindow(title: String){
    addLog(text:"showcompletionRequirementsWindow")
    getCompletionRequirementsWindowObject().contentViewController = getCompletionRequirementsVcObject()
    getCompletionRequirementsWindowObject().window?.center()
    getCompletionRequirementsWindowObject().window?.title = appName
    getCompletionRequirementsWindowObject().window?.center()
    getCompletionRequirementsWindowObject().showWindow(nil)
    getCompletionRequirementsVcObject().resetView(title:title)
    
}

//***********SHOW PopUp CheckList Window***************//
func showPopUpCheckListWindow(title: String, list: [String]){
    if list.isEmpty{
        return;
    }
    addLog(text:"showPopUpCheckListWindow")
    getPopUpCheckListWindowObject().contentViewController = getPopUpCheckListVcObject()
    getPopUpCheckListWindowObject().window?.center()
    getPopUpCheckListWindowObject().window?.title = appName
    getPopUpCheckListWindowObject().window?.center()
    getPopUpCheckListWindowObject().showWindow(nil)
    getPopUpCheckListVcObject().resetView(title:title, list: list)
}


//***********SHOW Toolbox window***************//
//func showToolboxWindow(){//// not in use now  removed on 1/9/25  on version 2.27.408
//    addLog(text:"show Toolbox Window")
//    getToolBoxWindowObject().contentViewController = getToolBoxVcObject()
//    getToolBoxWindowObject().window?.backgroundColor = NSColor.clear
//    getToolBoxWindowObject().window?.title = "Focus Bear - Toolbox"
//    if let toolBoxVcInfo = configjson.value(forKey: "toolBoxVcInfo") as? NSDictionary{
//        getToolBoxWindowObject().window?.title = toolBoxVcInfo.value(forKey: "windowTitleText") as? String ?? "Focus Bear - Toolbox"
//    }
//    getToolBoxWindowObject().showWindow(nil)
//    toolBoxVcObj?.resetView()
//}

//***********SHOW ToDoList window***************//
func showToDoListWindow(){
    addLog(text:"show To Do List Window")
    if !(mainWindowControllerObj?.window?.isVisible ?? false){
        mainWindowControllerObj?.showWindow(nil)
    }
    leftMenuVcObj?.showTaskPlayer()
    allApiObject.capturePosthog(event: "todo-list-popup-shown", metadata: [:])
}


//***********SHOW Create Task window***************//
func showCreateTaskWindow(dueDate:Date){
    addLog(text:"show Create Task Window")
    allApiObject.capturePosthog(event: "create-task-window-shown", metadata: [:])
    getCreateTaskWcObject().contentViewController = getCreateTaskVcObject()
    getCreateTaskWcObject().window?.title = "Focus Bear - Create New Task"
    if let createTaskVcInfo = configjson.value(forKey: "createTaskVcInfo") as? NSDictionary{
        getCreateTaskWcObject().window?.title = createTaskVcInfo.value(forKey: "title") as? String ?? "Focus Bear - Create New Task"
    }
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    let windowFrame = getCreateTaskWcObject().window?.frame ?? NSRect(x: 0, y: 0, width: 450, height: 542)
    let screenFrameCenterPoint = NSPoint(x: screenFrame.maxX / 2, y: screenFrame.maxY / 2)
    let windowOrigin = NSPoint(x: (screenFrameCenterPoint.x - (windowFrame.width / 2)), y: (screenFrameCenterPoint.y - (windowFrame.height / 2)))
    
    createTaskWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.minX + windowOrigin.x, y: screenFrame.minY + windowOrigin.y))
    getCreateTaskWcObject().showWindow(nil)
    getCreateTaskVcObject().resetData(dueDate: dueDate)
}



//***********SHOW RelaxMode window***************//
func showRelaxModeWindow(durationSeconds: Int, currentTimerValue:Int){
    allApiObject.capturePosthog(event: "relax-mode-window-shown", metadata: [:])
    addLog(text:"show RelaxMode Window")
    getRelaxModeWindowObject().contentViewController = getRelaxModeVcObject()
    getRelaxModeWindowObject().window?.title = appName
    getRelaxModeWindowObject().window?.center()
    getRelaxModeWindowObject().showWindow(nil)
    relaxModeVcObj?.startTimerHabit(durationSeconds: durationSeconds, currentTimerValue: currentTimerValue)
}

//***********Show Saved Sites For Later Window For Breaks***************//
func showSavedSitesForLaterWindowForBreaks(){
    addLog(text:"show Saved Sites For Later during breaks in pomodoro")
    getSavedSitesForLaterWindowObject().contentViewController = getSavedSitesForLaterVcObject()
    getSavedSitesForLaterWindowObject().window?.title = appName
    getSavedSitesForLaterWindowObject().window?.center()
    getSavedSitesForLaterWindowObject().showWindow(nil)
    savedSitesForLaterVcObj?.reloadData()
}

//***********show Confirm Run Script Window***************//
func showConfirmRunScriptWindow(focusMode:String, scriptPath:String?, shellCommand:String?){
    addLog(text:"show Saved Sites For Later during breaks in pomodoro")
    getConfirmRunScriptWindowObject().contentViewController = getConfirmRunScriptVcObject()
    getConfirmRunScriptWindowObject().window?.title = appName
    getConfirmRunScriptWindowObject().window?.center()
    getConfirmRunScriptWindowObject().showWindow(nil)
    getConfirmRunScriptVcObject().reloadData(focusMode:focusMode, scriptPath: scriptPath, shellCommand: shellCommand)
}




//***********SHOW ask appwork window***************//
func showAskAppWorkWindow(){
    addLog(text:"show ask app work Window")
    getAskAppWorkWindowObject().contentViewController = getAskAppWorkVcObject()
    getAskAppWorkWindowObject().window?.backgroundColor = NSColor.clear
    getAskAppWorkWindowObject().window?.title = appName
    getAskAppWorkWindowObject().showWindow(nil)
}

//***********SHOW BRAIN DUMP WINDOW***************//

func showBrainDumpWindow(){
    addLog(text: "func:- showBrainDumpWindow")
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showBrainDump()
    
//    return;
//    if brainDumpWcObj == nil{
//        getBrainDumpWindowObject().contentViewController = getBrainDumpVcObject()
//        brainDumpWcObj?.window?.styleMask.insert(.resizable)
//        brainDumpWcObj?.window?.title = "Focus Bear - Brain dump"
//        if let brainDumpVcInfo = configjson.value(forKey: "brainDumpVcInfo") as? NSDictionary{
//            brainDumpWcObj?.window?.title = brainDumpVcInfo.value(forKey: "title") as? String ?? "Focus Bear - Brain dump"
//        }
////        brainDumpWcObj?.window?.standardWindowButton(.zoomButton)!.isHidden = true
//        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//        
//        brainDumpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (brainDumpVcObj?.view.frame.width)!, y: screenFrame.height - (brainDumpVcObj?.view.frame.height)! - 22 - 140)) //  22 status bar heigh // timer window height is 100 // 20 is title bar height  and 20 is extra space to add
//    }
//    
//    
//    brainDumpWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********SHOW BRAIN DUMP WINDOW***************//

func showBrowsersTabAuditView(){
    addLog(text: "func:- showBrowsersTabAuditView")
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showBrowsersTabAuditView()
}
//-------------------------------------------------//


func showPopupBlockConfirmWindow(blockedAppName:String, currentApp:NSRunningApplication?, url:String, script:String, isBlockApp:Bool, browser:BROWSER?, tabTitle:String?, fullUrl:String, aiBlockReason:String?, isTimeOut:Bool, isBlockByAi:Bool, scoreForThisSiteApp: Double?, payload: [String : Any]?, isBrowser:Bool, suggestedTask:String?, suggestedTaskId:String?){
    addLog(text: "func:- PopupBlockConfirmWindow")
    var currentPid: pid_t?
    if let runningApp = NSWorkspace.shared.frontmostApplication{
        let pid = runningApp.processIdentifier
        currentPid = pid
        
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        
        for info in windowInfoList! {
            let windowPID = info["kCGWindowOwnerPID"] as! UInt32
            if  windowPID == pid {
                if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                    let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                    if height > 250{
                        let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                        let x = windowFrame.value(forKey: "X") as? Int ?? 0
                        let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                        var frame = NSRect(x: x, y: y, width: width, height: height)
                        if browser != nil{
                            frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser!)
                        }
                        showBlurWindow(frame: frame, browser: browser)
                        break;
                    }
                    
                }
            }
        }
    }
    if popUpBlockConfirmWcObj == nil{
        getPopUpBlockConfirmWindowObject().contentViewController = getPopUpBlockConfirmVcObject()
        popUpBlockConfirmWcObj?.window?.styleMask.remove(.closable)
        popUpBlockConfirmWcObj?.window?.title = appName
        popUpBlockConfirmWcObj?.window?.backgroundColor = NSColor.clear
        popUpBlockConfirmWcObj?.window?.isMovable = false
    }
    
    if !(popUpBlockConfirmVcObj?.isViewLoaded ?? false){
        popUpBlockConfirmVcObj?.loadView()
    }
    let blurWindowFrame = blurWcObj?.window?.frame
    var midX = blurWindowFrame?.midX ?? 0
    var midY = blurWindowFrame?.midY ?? 0
    let width = popUpBlockConfirmVcObj?.view.frame.width ?? 500
    let height = popUpBlockConfirmVcObj?.view.frame.height ?? 500
    
    if !(blurWcObj?.window?.isVisible ?? false){
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        midX = screenFrame.width / 2
        midY = screenFrame.height / 2
    }
    
    popUpBlockConfirmVcObj?.resetView(blockedAppName: blockedAppName, currentApp:currentApp, url:url, script:script, isBlockApp:isBlockApp, browser:browser, currentPid: currentPid, tabTitle: tabTitle, fullUrl: fullUrl, aiBlockReason:aiBlockReason, isTimeOut:isTimeOut, isBlockByAi: isBlockByAi, scoreForThisSiteApp: scoreForThisSiteApp, payload: payload, isBrowser:isBrowser, suggestedTask: suggestedTask, suggestedTaskId: suggestedTaskId)
    popUpBlockConfirmWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
    
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            let width = popUpBlockConfirmVcObj?.view.frame.width ?? 500
            let height = popUpBlockConfirmVcObj?.view.frame.height ?? 500
            popUpBlockConfirmWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
        }
    }
    popUpBlockConfirmWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********Popup Set Intention Blocked urls Window***************//
func showSetIntentionBlockedUrlsWindow(script: String, url:String, browser:BROWSER?, allreadyCheckedIndex:Int, isAppBlocking:Bool, currentApp:NSRunningApplication?, blockedAppName:String, blockItem:String){
    addLog(text: "func:- showSetIntentionBlockedUrlsWindow :- currentApp: \(currentApp?.localizedName ?? ""), url: \(url)")
    print("showSetIntentionBlockedUrlsWindow*************")
    var currentPid: pid_t?
    if let runningApp = NSWorkspace.shared.frontmostApplication{

        let pid = runningApp.processIdentifier
        currentPid = pid
        
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.excludeDesktopElements, CGWindowListOption.optionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let windowInfoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        
        for info in windowInfoList! {
            let windowPID = info["kCGWindowOwnerPID"] as! UInt32
            if  windowPID == pid {

                if let windowFrame = info["kCGWindowBounds"] as? NSDictionary{
                    let height = windowFrame.value(forKey: "Height") as? Int ?? 0
                    if height > 250{
                        let width = windowFrame.value(forKey: "Width") as? Int ?? 0
                        let x = windowFrame.value(forKey: "X") as? Int ?? 0
                        let y = windowFrame.value(forKey: "Y") as? Int ?? 0
                        var frame = NSRect(x: x, y: y, width: width, height: height)
                        if browser != nil{
                            frame = getBlurFrameForBrowser(x: x, y: y, width: width, height: height, browser: browser!)
                        }
                        showBlurWindow(frame: frame, browser: browser)
                        break;
                    }
                    
                }
            }
        }
    }

    if setIntentionBlockedUrlsWcObj == nil{
        getSetIntentionBlockedUrlsWindowObject().contentViewController = getSetIntentionBlockedUrlsVcObject()
        setIntentionBlockedUrlsWcObj?.window?.styleMask.remove(.closable)
        setIntentionBlockedUrlsWcObj?.window?.title = appName
        setIntentionBlockedUrlsWcObj?.window?.backgroundColor = NSColor.clear
        
        setIntentionBlockedUrlsWcObj?.window?.isMovable = false
    }
    if !(setIntentionBlockedUrlsVcObj?.isViewLoaded ?? false){
        setIntentionBlockedUrlsVcObj?.loadView()
    }
    if !(setIntentionBlockedUrlsWcObj?.isWindowLoaded ?? false){
        setIntentionBlockedUrlsWcObj?.loadWindow()
    }
    
    let blurWindowFrame = blurWcObj?.window?.frame
    var midX = blurWindowFrame?.midX ?? 0
    var midY = blurWindowFrame?.midY ?? 0
    let width = setIntentionBlockedUrlsWcObj?.window?.frame.width ?? 500
    let height = setIntentionBlockedUrlsWcObj?.window?.frame.height ?? 500
    if !(blurWcObj?.window?.isVisible ?? false){
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        midX = screenFrame.width / 2
        midY = screenFrame.height / 2
    }
    
    setIntentionBlockedUrlsVcObj?.resetView(script: script, url: url, currentPid: currentPid, browser:browser, allreadyCheckedIndex:allreadyCheckedIndex, isAppBlocking:isAppBlocking, currentApp:currentApp, blockedAppName:blockedAppName, blockItem:blockItem)
    let x = (midX-(width/2))
    let y = (midY-(height/2))
    setIntentionBlockedUrlsWcObj?.window?.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    
    DispatchQueue.global().async {
        DispatchQueue.main.async {
            let width = setIntentionBlockedUrlsVcObj?.view.frame.width ?? 500
            let height = setIntentionBlockedUrlsVcObj?.view.frame.height ?? 500
            setIntentionBlockedUrlsWcObj?.window?.setFrame(NSRect(x: (midX-(width/2)), y: (midY-(height/2)), width: width, height: height), display: true)
        }
    }
    setIntentionBlockedUrlsWcObj!.showWindow(nil)
    
}
//-----------------------------------------------------//

//***********Popup Intention urls Window***************//

func showIntentionBlockedUrlsWindow(script: String, url:String, browser:BROWSER?, intention: String, currentPid: pid_t?, allowFor24Hours:Bool){
    print("showIntentionBlockedUrlsWindow***************")
    if intentionBlockedUrlsWcObj == nil{
        getIntentionBlockedUrlsWindowObject().contentViewController = getIntentionBlockedUrlsVcObject()
        intentionBlockedUrlsWcObj?.window?.title = appName
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        intentionBlockedUrlsWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (intentionBlockedUrlsVcObj?.view.frame.width)!, y: 0)) //  22 status bar heigh
    }
    var pid: pid_t?
    if currentPid == nil{
        if let runningApp = NSWorkspace.shared.frontmostApplication{
            pid = runningApp.processIdentifier
        }
    }else{
        pid = currentPid
    }
    intentionBlockedUrlsWcObj!.showWindow(nil)
    intentionBlockedUrlsVcObj?.resetView(script: script, url: url, browser: browser, intention: intention, currentPid: pid, allowFor24Hours: allowFor24Hours)
}
//-----------------------------------------------------//

//***********Popup Intention apps Window***************//

func showIntentionBlockedAppsWindow(currentApp:NSRunningApplication?, blockedAppName:String, intention:String){
    print("showIntentionBlockedAppsWindow***************")
    if intentionBlockedAppsWcObj == nil{
        getIntentionBlockedAppsWindowObject().contentViewController = getIntentionBlockedAppsVcObject()
        intentionBlockedAppsWcObj?.window?.title = appName
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        intentionBlockedAppsWcObj?.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (intentionBlockedAppsVcObj?.view.frame.width)!, y: 200))
    }
    intentionBlockedAppsWcObj!.showWindow(nil)
    intentionBlockedAppsVcObj?.resetView(currentApp:currentApp, blockedAppName:blockedAppName, intention:intention)
}
//-----------------------------------------------------//


//***********show Break Warning Window***************//

func showBreakWarningWindow(){
    if checkIsFullScreenEnabled(){
        getTransparentWindowObject().showWindow(nil)
    }
    addLog(text:"showBreakWarningWindow")
    allApiObject.capturePosthog(event: "break-warning-shown", metadata: [:])
    getBreakWarningWindowObject().contentViewController = getBreakWarningVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getBreakWarningWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (breakWarningVcObj?.view.frame.width)!, y: screenFrame.height - (breakWarningVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    
    breakWarningWcObj?.window?.title = appName
    breakWarningWcObj!.showWindow(nil)
    breakWarningVcObj!.resetView()
}
//-------------------------------------------------//

//***********show Deactivate Breaks Window***************//

func showDeactivateBreaksWindow(){
    addLog(text:"showDeactivateBreaksWindow")
    allApiObject.capturePosthog(event: "deactivate-breaks-window-shown", metadata: [:])
    getDeactivateBreaksWindowObject().contentViewController = getDeactivateBreaksVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getDeactivateBreaksWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (deactivateBreaksVcObj?.view.frame.width)!, y: screenFrame.height - (deactivateBreaksVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    deactivateBreaksWcObj?.window?.styleMask.remove(.closable)
    deactivateBreaksWcObj?.window?.title = appName
    deactivateBreaksWcObj!.showWindow(nil)
}
//-------------------------------------------------//




//***********show alertReasonAutoAllowSite Window***************//

//func showAutoUrlAllowWindow(title: String, subTitle: String, buttonCancelText: String, checkBoxText: String, payload: [String : Any], response: NSDictionary){
//    addLog(text:"showAutoUrlAllowWindow")
//    getAlertReasonAutoAllowWindowObject().contentViewController = getAlertReasonAutoAllowSiteVcObject()
//
//    //    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//    getAlertReasonAutoAllowWindowObject().window?.titlebarAppearsTransparent = true
//    getAlertReasonAutoAllowWindowObject().window?.styleMask.remove(.closable)
//    getAlertReasonAutoAllowWindowObject().window?.styleMask.insert(.fullSizeContentView)
//    getAlertReasonAutoAllowWindowObject().window?.center()
//    getAlertReasonAutoAllowWindowObject().window?.title = ""//no title
//    getAlertReasonAutoAllowWindowObject().showWindow(nil)
//    getAlertReasonAutoAllowSiteVcObject().resetView(title: title, subTitle: subTitle, buttonCancelText: buttonCancelText, checkBoxText: checkBoxText, payload: payload, response: response)
//    //    NSApplication.shared.activate(ignoringOtherApps: true)
//}
//-------------------------------------------------//


//***********show alertReasonAutoAllowSite Window***************//

func showNaturalBreakDetectionWindow(duration:Int){
    print("showNaturalBreakDetectionWindow")
    if naturalBreaksDetectionVcObj != nil{
        if naturalBreaksDetectionVcObj?.isViewVisible ?? false{
            return;
        }
    }
    addLog(text:"showNaturalBreakDetectionWindow")
    allApiObject.capturePosthog(event: "natural-break-detection-window-shown", metadata: [:])
    
    naturalBreaksDetectionVcObj = nil// always catch a fresh object
    if mainWindowControllerObj?.window?.isVisible ?? false{
        addLog(text:"Natural Break view presenting by sheet")
        mainViewControllerObj?.presentAsSheet(getNaturalBreaksDetectionVcObject())
        getNaturalBreaksDetectionVcObject().resetView(duration:duration)
    }else{
        addLog(text:"Natural Break view presenting as window")
        getNaturalBreaksDetectionWindowObject().contentViewController = getNaturalBreaksDetectionVcObject()
        getNaturalBreaksDetectionWindowObject().window?.styleMask.remove(.closable)
        getNaturalBreaksDetectionWindowObject().window?.center()
        getNaturalBreaksDetectionWindowObject().window?.title = appName
        getNaturalBreaksDetectionWindowObject().showWindow(nil)
        getNaturalBreaksDetectionVcObject().resetView(duration:duration)
    }
}

func closeNaturalBreakDetectionWindowIfVisible(){// added on 9/9/25 in 2.27.413
    addLog(text: "closeNaturalBreakDetectionWindowIfVisible")
    if naturalBreaksDetectionVcObj != nil{
        if naturalBreaksDetectionVcObj?.isViewVisible ?? false{
            if naturalBreaksDetectionVcObj != nil{
                if naturalBreaksDetectionVcObj?.presentingViewController == mainViewControllerObj{
                    naturalBreaksDetectionVcObj?.closeForecefully()
                }
            }
        }
    }
}

//-------------------------------------------------//

//***********show Popup Appointment Time Window***************//

func showPopupAppointmentWindow(title:String, endTime:Date){
    addLog(text:"showPopupAppointmentWindow")
    getPopupAppointmentTimeWindowObject().contentViewController = getPopupAppointmentTimeVcObject()
    getPopupAppointmentTimeWindowObject().window?.styleMask.remove(.closable)
    getPopupAppointmentTimeWindowObject().window?.center()
    getPopupAppointmentTimeWindowObject().window?.title = appName
    getPopupAppointmentTimeWindowObject().showWindow(nil)
    getPopupAppointmentTimeVcObject().resetView(title:title, endTime:endTime)
}
//-------------------------------------------------//


//***********show Alert Max Tab Limit Window***************//

func showAlertMaxTabLimitWindow(){
    addLog(text:"showAlertMaxTabLimitWindow")
    DispatchQueue.main.async {
        getAlertMaxTabLimitWindowObject().contentViewController = getAlertMaxTabLimitVcObject()
        getAlertMaxTabLimitWindowObject().window?.styleMask.remove(.closable)
        getAlertMaxTabLimitWindowObject().window?.center()
        getAlertMaxTabLimitWindowObject().window?.title = appName
        getAlertMaxTabLimitWindowObject().showWindow(nil)
    }
}
//-------------------------------------------------//

//***********show Blur Window***************//

func showBlurWindow(frame:NSRect, browser:BROWSER?){
    addLog(text:"show Blur Window")
    if blurWcObj == nil{
        getBlurWindowObject().contentViewController = getBlockBlurVcObject()
        getBlurWindowObject().window?.styleMask = .borderless
        
        blurWcObj?.window?.backgroundColor = NSColor.clear
        blurWcObj?.window?.isOpaque = false
        blurWcObj?.window?.alphaValue = 0.98
    }
    guard let screen = NSScreen.main else{
        return;
    }
    let screenFrame = screen.frame
    let firstScreenFrame = NSScreen.screens.first?.frame ?? screenFrame
    let finalFrame: NSRect = NSRect(x: frame.minX, y: (firstScreenFrame.height - (frame.minY + frame.height)), width: frame.width, height: frame.height)

    getBlurWindowObject().window?.setFrame(finalFrame, display: true)
    
    if !(blurWcObj?.window?.isVisible ?? false){
        blurWcObj!.showWindow(nil)
    }
    if browser != nil{
        if browser == ._ARC_{
            blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        }else{
            blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        }
        
    }else{
        blockBlurVcObj?.visualEffectView.layer?.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    
}
//-------------------------------------------------//

//***********show Break Warning Window***************//

func showAllTracksWindow(){
    addLog(text:"showAllTracksWindow")
    
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showAllTracks()
    return;
}
//-------------------------------------------------//



//***********show share Feedback Window***************//

func showShareFeedbackWindow(){
    addLog(text:"showShareFeedbackWindow")
    getShareFeedbackWindowControllerObj().contentViewController = getShareFeedbackVcObj()
    
    shareFeedbackWindowControllerObj?.window?.center()
    shareFeedbackWindowControllerObj?.window?.styleMask.remove(.closable)
    shareFeedbackWindowControllerObj?.window?.title = appName
    shareFeedbackWindowControllerObj?.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//



//trialExpiredNag


//***********showTrialExpiredWindow***************//

func showTrialExpiredWindow(){
    addLog(text:"showTrialExpiredWindow")
    getTrialExpiredWindowControllerObj().contentViewController = getTrialExpiredNagVcObj()
    
    trialExpiredNagWcObj?.window?.center()
    trialExpiredNagWcObj?.window?.title = appName
    trialExpiredNagWcObj?.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    let shutOffdate = Calendar.current.date(bySettingHour: shutOffTime!.hour, minute: shutOffTime!.minute, second: shutOffTime!.second, of: Date())!
    UserDefaults.standard.set(shutOffdate, forKey: kUserdefaultsExtraNagsAfterTrialExpiredShowedTillDate)
}
//-------------------------------------------------//


//***********showaddFocusTempUrlsOrAppsWindow***************//

func showaddFocusTempUrlsOrAppsWindow(){
    addLog(text:"func:- showaddFocusTempUrlsOrAppsWindow")
    if !SettingsManagerObject.isGeekModeEnabled{
        addLog(text:"Simple mode is enabled:- return")
        return;
    }
    // dont show for Default focus mode / v 2.28.449 
    if let currentFocusModeId = lastFocusModeTempInfo?.id{
        for i in 0..<arrFocusType.count{
            if arrFocusType[i]["id"] as? String  == currentFocusModeId{
                if let isDefault = arrFocusType[i]["isDefault"] as? Bool{
                    if  isDefault{
                        addLog(text:"Default focus mode:- return")
                        return;
                    }
                }
                break;
            }
        }
    }
    
    getAddFocusTempUrlsOrAppsWcObj().contentViewController = getAddFocusTempUrlsOrAppsVcObj()
    
    getAddFocusTempUrlsOrAppsWcObj().window?.center()
    
    
    var titleWindowText = "Teach Focus Bear how you focus"
    if let addFocusTempUrlsOrAppsVcInfo = configjson.value(forKey: "addFocusTempUrlsOrAppsVcInfo") as? NSDictionary{
        titleWindowText = addFocusTempUrlsOrAppsVcInfo.value(forKey: "titleWindowText") as? String ?? titleWindowText
    }
    getAddFocusTempUrlsOrAppsWcObj().window?.title = titleWindowText
    
    getAddFocusTempUrlsOrAppsWcObj().showWindow(nil)
    addFocusTempUrlsOrAppsVcObj?.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********showSurveyWindow***************//
func showSurveyWindow(){
    addLog(text:"showSurveyWindow")
    getSurveyWcObject().contentViewController = getSurveyVcObject()
    getSurveyWcObject().window?.center()
    getSurveyWcObject().window?.title = appName
    getSurveyWcObject().showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    allApiObject.capturePosthog(event: "survey-window-shown", metadata: [:])
}
//-------------------------------------------------//


//***********showTimeTrackerWindow***************//
func showTimeTrackerWindow(showingAutomatically:Bool){
    addLog(text:"showTimeTrackerWindow")
    getTimeTrackerWcObject().contentViewController = getTimeTrackerVcObject()
    getTimeTrackerWcObject().window?.center()
    getTimeTrackerWcObject().window?.title = appName
    getTimeTrackerWcObject().window?.styleMask.remove(.closable)
    getTimeTrackerWcObject().showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    timeTrackerVcObj!.showingAutomatically = showingAutomatically
    allApiObject.capturePosthog(event: "show-timetracker-window", metadata: [:])
}
//-------------------------------------------------//

var shouldReloadTaskPlayer = true
//***********showTaskPlayerWindow***************//
func showTaskPlayerWindow(totalDuration:Int, intention:String, automatically:Bool){
    addLog(text:"func call:- showTaskPlayerWindow")
    if !getHabitsVcObject().isViewLoaded{
        getHabitsVcObject().loadView()
    }
    
    if !(mainViewControllerObj?.isViewLoaded ?? false){
        mainViewControllerObj?.loadView()
    }
    if !(mainWindowControllerObj?.window?.isVisible ?? false){
        mainWindowControllerObj?.showWindow(nil)
    }
    leftMenuVcObj?.showTaskPlayer()
    allApiObject.capturePosthog(event: "todo-player-popup-shown", metadata: [:])
    
}
//-------------------------------------------------//



//***********showCustomAlert***************//
func showCustomAlert(title:String, body:String?, buttonOkText:String, buttonCancelText:String?, checkBoxText:String?, autoClose:Bool, buttonLinkUrl:String?, buttonLinkText:String?, completionHandler: @escaping (Bool) -> Void){
    if customAlertWcObj == nil{
        getCustomAlertWindowObject().contentViewController = getCustomAlertVcObject()
    }
    getCustomAlertWindowObject().window?.center()
    getCustomAlertWindowObject().window?.styleMask.remove(.closable)
    getCustomAlertWindowObject().window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    getCustomAlertWindowObject().showWindow(nil)
    customAlertVcObj?.resetData(title: title, body: body, buttonOkText: buttonOkText, buttonCancelText: buttonCancelText, checkBoxText: checkBoxText, autoClose:autoClose, buttonLinkUrl: buttonLinkUrl, buttonLinkText:buttonLinkText, completionHandler: {isOkClicked in
        completionHandler(isOkClicked)
    })
}
//-------------------------------------------------//

//***********unverifiedEmailVc***************//
func showUnverifiedEmailWindow(){
    addLog(text:"showUnverifiedEmailWindow")
    if unverifiedEmailWcObj == nil{
        getUnverifiedEmailWindowObject().contentViewController = getUnverifiedEmailVcObject()
    }
    getUnverifiedEmailWindowObject().window?.center()
    getUnverifiedEmailWindowObject().window?.styleMask.remove(.closable)
    getUnverifiedEmailWindowObject().window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.numberOfWindowLevelKeys)))
    getUnverifiedEmailWindowObject().showWindow(nil)
    getUnverifiedEmailVcObject().isAWindow = true
}
//-------------------------------------------------//




//***********showLateNoMoreWindow***************//
func showLateNoMoreWindow(){
    if FileManager.default.fileExists(atPath: "/Applications/Late No More.app"){
        return;
    }
    addLog(text:"showLateNoMoreWindow")
    getLateNoMorePopUpWcObject().contentViewController = getLateNoMorePopUpVcObject()
    getLateNoMorePopUpWcObject().window?.center()
    getLateNoMorePopUpWcObject().window?.title = appName
    getLateNoMorePopUpWcObject().window?.styleMask.remove(.closable)
    getLateNoMorePopUpWcObject().showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
    allApiObject.capturePosthog(event: "show-latenomore-window", metadata: [:])
}
//-------------------------------------------------//


//***********show Break Warning Window***************//

func showPreloadFocusModesWindow(){
    addLog(text:"showPreloadFocusModesWindow")
    getPreloadFocusModesWindowControllerObj().contentViewController = getPreloadFocusModesVcObj()
    
    preloadFocusModesWindowControllerObj!.window?.center()
    
    preloadFocusModesWindowControllerObj!.window?.styleMask.remove(.closable)
    preloadFocusModesWindowControllerObj?.window?.title = appName
    preloadFocusModesWindowControllerObj!.showWindow(nil)
    //    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


//***********show Easy Postpone Window***************//

func showEasyPostponeWindow(){
    addLog(text:"showEasyPostponeWindow")
    allApiObject.capturePosthog(event: "easy-postpone-window-shown", metadata: [:])
    
    easyPostponeVcObj = nil// always get a fresh object
    if mainWindowControllerObj?.window?.isVisible ?? false{
        mainViewControllerObj?.presentAsSheet(getEasyPostponeVcObject())
    }else{
        getEasyPostponeWindowObject().contentViewController = getEasyPostponeVcObject()
        
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        easyPostponeWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (easyPostponeVcObj?.view.frame.width)!, y: screenFrame.height - (easyPostponeVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
        
        easyPostponeWcObj!.window?.styleMask.remove(.closable)
        easyPostponeWcObj?.window?.title = appName
        easyPostponeWcObj!.showWindow(nil)
    }
    easyPostponeVcObj?.isForExtendPostponeDuringCustomRoutine = false
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//


func closeEasyPostponeWindowIfVisible(){
    if easyPostponeVcObj != nil{
        if easyPostponeVcObj?.isViewVisible ?? false{
            easyPostponeVcObj?.closeView()
        }
    }
}


//***********show Super Gentle Quit Window***************//

func showSuperGentleQuitWindow(){
    addLog(text:"showSuperGentleQuitWindow")
    allApiObject.capturePosthog(event: "super-gentle-quit-window-shown", metadata: [:])
    getSuperGentleQuitWindowObject().contentViewController = getSuperGentleQuitVcObject()
    
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    superGentleQuitWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (superGentleQuitVcObj?.view.frame.width)!, y: screenFrame.height - (superGentleQuitVcObj?.view.frame.height)! - 22)) //  22 status bar heigh

    superGentleQuitWcObj?.window?.title = appName
    superGentleQuitWcObj!.showWindow(nil)
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//




//***********show PopUp Offline Window***************//

func showPopUpOfflineWindow(){
    addLog(text:"showPopUpOfflineWindow")
    getPopUpOfflineWindowObject().contentViewController = getPopUpOfflineVcObject()
    
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    popUpOfflineWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (popUpOfflineVcObj?.view.frame.width)!, y: screenFrame.height - (popUpOfflineVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
    popUpOfflineWcObj?.window?.title = appName
    popUpOfflineWcObj!.showWindow(nil)
    //    breakWarningVcObj!.resetView()
    NSApplication.shared.activate(ignoringOtherApps: true)
}
//-------------------------------------------------//

//***********SHOW Ask Login Window ***************//

func showAskLoginWindow(){
    addLog(text:"showAskLoginWindow")
    getAskLogInWindowObject().contentViewController = getAskLogInVcObject()
    if !(getAskLogInWindowObject().window?.isVisible ?? false){
        getAskLogInWindowObject().window?.center()
    }
    askLogInWcObj?.window?.title = appName
    appdelegate!.statusbutton?.action = nil
    askLogInWcObj!.showWindow(nil)
//    askLogInWcObj?.window?.center()
//  for  blocking at onboarding time if user set blocked urls and then open app after once quit
    if let blockedUrls = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
        SettingsManagerObject.arrBlockedUrls.removeAll()
        for i in 0..<blockedUrls.count{
            if let isSelected = blockedUrls[i]["isSelected"] as? Bool {
                if isSelected{
                    SettingsManagerObject.arrBlockedUrls.append(blockedUrls[i]["url"] as? String ?? "")
                }
            }
        }
    }
}
//-------------------------------------------------//



//***********SHOW Custom Login Window ***************//

func showCustomLoginWindow(isLogin:Bool){
    addLog(text:"showCustomLoginWindow")
    if customLoginVcObj == nil{
        getCustomLoginVcObject().loadView()
    }
    customLoginVcObj?.isLogin = isLogin
    getAskLogInWindowObject().contentViewController = getCustomLoginVcObject()
    appdelegate!.statusbutton?.action = nil
    askLogInWcObj!.showWindow(nil)
}
//-------------------------------------------------//

//***********SHOW Custom Login Window ***************//

//func showLoginHelpWindow(){
//    addLog(text:"showLoginHelpWindow")
//    getLoginHelpWindowObject().contentViewController = getLoginHelpVcObject()
//    loginHelpWcObj!.showWindow(nil)
//
//    loginHelpWcObj!.window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//
//    loginHelpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (loginHelpVcObj!.view.frame.width), y: screenFrame.height - (loginHelpVcObj!.view.frame.height) - 22)) //  22 status bar heigh
//    loginHelpWcObj!.window?.isMovableByWindowBackground = true
//
//}
//-------------------------------------------------//

//***********SHOW Onboarding Card Window ***************//

//func showOnboardingCardWindow(isLogin:Bool){
//    addLog(text:"showOnboardingCardWindow")
//    getOnboardingCardsWindowObject().contentViewController = getOnboardingCardsVcObject()
//    getOnboardingCardsWindowObject().window?.center()
//    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
//    onboardingCardsVcObj?.isLogin = isLogin
//    onboardingCardsWcObj!.showWindow(nil)
//    onboardingCardsWcObj?.window?.center()
//    //    loginHelpWcObj!.window?.styleMask = .borderless
//    //    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//    //
//    //    loginHelpWcObj!.window?.setFrameOrigin(NSPoint(x: screenFrame.width - (loginHelpVcObj!.view.frame.width), y: screenFrame.height - (loginHelpVcObj!.view.frame.height) - 22)) //  22 status bar heigh
//    //    loginHelpWcObj!.window?.isMovableByWindowBackground = true
//
//}



//func showHowHeardWindow(){
//    addLog(text:"showHowHeardWindow")
//    allApiObject.capturePosthog(event: "show_how_heard_about_focus_bear_screen", metadata: [:])
//    getOnboardingCardsWindowObject().contentViewController = getHowHeardVcObj()
//    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
//    onboardingCardsWcObj!.showWindow(nil)
//}
func showAskProcrastinatingWindow(){
    addLog(text:"showProcrastinatingWindow")
    allApiObject.capturePosthog(event: "show_procrastinating_screen", metadata: [:])
//    getOnboardingCardsWindowObject().contentViewController = getAskProcrastinatingVcObj()
//    onboardingCardsWcObj!.showWindow(nil)
//    onboardingCardsWcObj?.window?.center()
//
    // changed from v 2.28.446
    mainWindowControllerObj?.showWindow(nil)
    leftMenuVcObj?.showProcrastinatingView()
}

func showConfirmBlockingScheduleWindow(){
    addLog(text:"showConfirmBlockingScheduleWindow")
    allApiObject.capturePosthog(event: "show_confirm_blocking_schedule_screen", metadata: [:])
    mainWindowControllerObj?.showWindow(nil)
    mainViewControllerObj?.showConfirmBlockingScheduleView()
}

func showFirefoxPermissionWindow(showingFromOnboarding:Bool, currentBrowser:BROWSER){
    addLog(text:"showFirefoxPermissionWindow")
    getFirefoxPermissionsWindowObject().contentViewController = getFirefoxPermissionsVcObject()
    firefoxPermissionsWcObj!.window?.styleMask.remove(.closable)
    firefoxPermissionsWcObj!.showWindow(nil)
    firefoxPermissionsWcObj?.window?.center()
    firefoxPermissionsVcObj?.showingFromOnboarding = showingFromOnboarding
    firefoxPermissionsVcObj?.currentBrowser = currentBrowser
    firefoxPermissionsVcObj?.resetView()
    if currentBrowser == ._FIREFOX_{
        UserDefaults.standard.set(true, forKey: kUserdefaultsFirefoxPermissionShown)
    }else if currentBrowser == ._SIGMA_OS_{
        UserDefaults.standard.set(true, forKey: kUserdefaultsSigmaOSPermissionShown)
    }
}

func showFirefoxPermissionVideoWindow(){
    addLog(text:"FirefoxPermissionVideoWindow")
    getFirefoxPermissionVideoWindowObject().contentViewController = getFirefoxPermissionVideoVcObject()
    firefoxPermissionVideoWcObj?.window?.styleMask.insert(.resizable)
    firefoxPermissionVideoWcObj!.showWindow(nil)
}


//func showChooseFrictionLevelWindow(){
//    addLog(text:"showChooseFrictionLevelWindow")
//    getOnboardingCardsWindowObject().contentViewController = getChooseFrictionLevelVcObj()
//    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
//    onboardingCardsWcObj!.showWindow(nil)
//    onboardingCardsWcObj?.window?.center()
//}

//func showInstallHabitPackWindow(){
//    addLog(text:"showInstallHabitPackWindow")
//    getOnboardingCardsWindowObject().contentViewController = getInstallHabitPacksVcObj()
//    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
//    onboardingCardsWcObj!.window?.styleMask.insert(.resizable)
//    onboardingCardsWcObj!.showWindow(nil)
//    onboardingCardsWcObj?.window?.center()
//}


func showMenuTourWindow(){
    addLog(text:"showMenuTourWindow")
    allApiObject.capturePosthog(event: "show_menu_tour", metadata: [:])
    if menuTourWcObj == nil{
        getMenuTourWcObject().contentViewController = getMenuTourVcObject()
    }
    getMenuTourWcObject().showWindow(nil)
    
    
    let screenList = NSScreen.screens
    for screen in screenList {
        menuTourWcObj?.window?.setFrame(NSMakeRect(0, 0, NSWidth(screen.frame), NSHeight(screen.frame)), display: true)
        break;
    }
}



//func showOnboardingSetPasswordWindow(){
//    addLog(text:"showOnboardingSetPasswordWindow")
//    getOnboardingCardsWindowObject().contentViewController = getOnboardingSetPasswordVcObj()
//    onboardingCardsWcObj!.showWindow(nil)
//}

//-------------------------------------------------//

//***********SHOW SetFocus Mode Window ***************//
func showSetFocusWindow(){
    addLog(text:"showSetFocusWindow")
    getOnboardingCardsWindowObject().contentViewController = getPreloadFocusModesVcObj()
    getOnboardingCardsWindowObject().window?.center()
    //    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
    onboardingCardsWcObj!.showWindow(nil)
    onboardingCardsWcObj?.window?.center()
}


//***********Show Distraction Types Window***************//
func showDistractionTypesWindow(showingFromPomodoro:Bool, showingFromBlockingSchedule:Bool = false){
    addLog(text:"showSetFocusWindow")
    isExplainingPermissionsWindowShowingFromPomodoro = showingFromPomodoro
    isExplainingPermissionsWindowShowingFromBlockingSchedule = showingFromBlockingSchedule
    getPermissionBlockDistractionWindowObject().contentViewController = getOnboardingDistractionTypesVcObject()
    getPermissionBlockDistractionWindowObject().window?.center()
    //    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
    getPermissionBlockDistractionWindowObject().showWindow(nil)
    getPermissionBlockDistractionWindowObject().window?.center()
    UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser) // line added on 23/7/25 version 1.26.393
}


//***********Show Explaining Permissions Window***************//
func showExplainingPermissionsWindow(showingFromPomodoro:Bool, showingFromBlockingSchedule:Bool = false){
    addLog(text:"showSetFocusWindow")
    isExplainingPermissionsWindowShowingFromPomodoro = showingFromPomodoro
    isExplainingPermissionsWindowShowingFromBlockingSchedule = showingFromBlockingSchedule
    getPermissionBlockDistractionWindowObject().contentViewController = getExplainingPermissionsVcObject()
    getPermissionBlockDistractionWindowObject().window?.center()
    //    onboardingCardsWcObj!.window?.styleMask.remove(.closable)
    getPermissionBlockDistractionWindowObject().showWindow(nil)
    getPermissionBlockDistractionWindowObject().window?.center()
}

//***********SHOW Upgrade Now Window ***************//
func showUpgradeNowWindow(){
    addLog(text:"showUpgradeNowWindow")
    allApiObject.capturePosthog(event: "upgrade-nag-shown", metadata: [:])
    if upgradeNowVcObj != nil{
        if upgradeNowVcObj?.isViewVisible ?? false{
            upgradeNowVcObj?.closeView()
        }
    }
    upgradeNowVcObj = nil// always catch a fresh object
    if mainWindowControllerObj?.window?.isVisible ?? false{
        mainViewControllerObj?.presentAsSheet(getUpgradeNowVcObject())
    }else{
        getUpgradeNowWindowObject().contentViewController = getUpgradeNowVcObject()
        upgradeNowWcObj?.window?.title = appName
        upgradeNowWcObj!.showWindow(nil)
    }
}
//-------------------------------------------------//


//***********SHOW Upgrade To Pro Window ***************//
func showUpgradeToProNagWindow(titleText:String, reason:String){
    allApiObject.capturePosthog(event: "upgrade-pro-nag-shown", metadata: ["reason":reason])
    addLog(text:"showUpgradeToProNagWindow")
    if upgradeToProNagWcObj == nil{
        getupgradeToProNagWindowObject().contentViewController = getUpgradeToProNagVcObject()
        upgradeToProNagWcObj?.window?.title = appName
        upgradeToProNagWcObj?.window?.styleMask.insert(.fullSizeContentView)
        upgradeToProNagWcObj?.window?.titlebarAppearsTransparent = true
        upgradeToProNagWcObj?.window?.title = ""
    }
    upgradeToProNagWcObj!.window?.center()
    upgradeToProNagWcObj!.showWindow(nil)
    upgradeToProNagVcObj?.resetData(titleText: titleText)
}
//-------------------------------------------------//

//***********SHOW WelcomeOnbarding window ***************//
func showWelcomeOnboardingWindow(){
    addLog(text:"showWelcomeWindow")
    appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
    if welcomeOnboardingWcObj == nil{
        getWelcomeOnboardingWindowObject().contentViewController = getWelcomeOnboardingVcObject()
        welcomeOnboardingWcObj?.window?.title = appName
    }
    welcomeOnboardingWcObj!.showWindow(nil)
    if appdelegate!.onboardingTimer != nil{
        appdelegate!.onboardingTimer?.invalidate()
        appdelegate!.onboardingTimer = nil
    }
}

//-------------------------------------------------//

//***********SHOW Welcome window ***************//


func showWelcomeWindow(){
    addLog(text:"showWelcomeOnboardingWindow")
    appdelegate!.statusbutton?.action = #selector(appdelegate!.topIconClickd)
    //if welcomeOnboardingWcObj == nil{
    getWelcomeOnboardingWindowObject().contentViewController = getWelcomeVcObject()
    welcomeOnboardingWcObj?.window?.title = appName
    // }
    welcomeOnboardingWcObj!.showWindow(nil)
    welcomeOnboardingWcObj?.window?.center()
}
//-------------------------------------------------//


//***********SHOW Onbarding video window ***************//

var onboardingVideoStartTime:Date?
/*// not in use
func showOnboardingVideoWindow(){
    addLog(text:"showOnboardingVideoWindow")
    appdelegate!.checkSystemTimeAndShowWindow()
    onboardingCardsWcObj?.contentViewController = getAskOnboardingVideoVcObject()
    
    UserDefaults.standard.set(true, forKey: kUserdefaultsVideoShown)
    
}
 */
//-------------------------------------------------//

func showQuitWindow(){
    addLog(text: "[user-action] - func showQuitWindow")
    
    showQuittingConfirmView()
    quittingWcObj?.showWindow(appdelegate!)
    quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))//modalPanelWindow
    NSApplication.shared.activate(ignoringOtherApps: true)
    
//    if isAppEnable{
//        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
//            showSuperGentleQuitWindow()
//        }else{
//            addLog(text: "Showing ask quit window")
//            allApiObject.capturePosthog(event: "show-initial-quit-screen", metadata: [:])
//            getQuittingWindowObject().contentViewController = getAskQuitVcObject()
//            quittingWcObj?.showWindow(appdelegate!)
//            quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))//modalPanelWindow
//            NSApplication.shared.activate(ignoringOtherApps: true)
//        }
//    }else{
//        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
//            if !SettingsManagerObject.isMenuPopoverEnabled{
//                if menuWcObj?.window?.isVisible ?? false{
//                    menuWcObj?.window?.close()
//                }
//            }
//            addLog(text: "showQuitWindow:- strictness level is super gentle")
//            allApiObject.capturePosthog(event: "app-quit", metadata: ["quitReason":"super gentle quit", "usageStartDate":getFirstRunDateString(), "daysSinceUserInstalledFocusBear": getDaysSinceAppInstalled(), "feedback": ""])
//            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
//                UserDefaults.standard.set("super gentle quit", forKey: kUserDefaultsLastQuitReason)
//                appdelegate?.quitAppForUser()
//            }
//        }else{
//            showQuittingConfirmView()
//            quittingWcObj?.showWindow(appdelegate!)
//            quittingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))//modalPanelWindow
//            NSApplication.shared.activate(ignoringOtherApps: true)
//        }
//    }
}

func showQuittingConfirmView(){
    let currentDate = Date()
    let firstRunDate = UserDefaults.standard.object(forKey: kUserdefaultsFirstRunDate) as? Date ?? currentDate
    let diffDays = Calendar.current.dateComponents([.day], from: firstRunDate, to: currentDate).day ?? 0
    
    if diffDays > 2{
        addLog(text: "[user-action] - Show QuittingConfirmVc")
        allApiObject.capturePosthog(event: "show-quit-confirm-screen", metadata: [:])
        getQuittingWindowObject().contentViewController = getQuittingConfirmVcObject()
        getQuittingConfirmVcObject().resetData()
    }else{
        addLog(text: "[user-action] - Show InitialQuitFeedbackVc")
        allApiObject.capturePosthog(event: "show-quit-within-48-hrs-feedback-screen", metadata: [:])
        getQuittingWindowObject().contentViewController = getInitialQuitFeedbackVcObject()
        getInitialQuitFeedbackVcObject().resetData()
    }
}


var popoverInformation:NSPopover?// = NSPopover()
func showInformationPopover(sender:NSView, preferredEdge: NSRectEdge,mainTitle: String, title: String, description: String) {
    if popoverInformation == nil{
        popoverInformation = NSPopover()
        popoverInformation!.behavior = .transient
        popoverInformation!.animates = false
        //        popoverTooltip!.delegate = appdelegate
    }
    if popoverInformation!.isShown{
        popoverInformation?.close()
    }
    let vc = getInformationPopoverVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    vc.showCurrentMessage(mainTitle: mainTitle, title: title, description: description)
    popoverInformation!.contentViewController = vc
    popoverInformation!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
}



//func showNotificationVideoCall(){
//    var notificationVideoCallText = "Looks like you're in a video call. I won't interrupt you with micro-breaks during the meeting to avoid embarrassing screensharing moments. Enjoy the meeting!"
//    if let common = configjson.value(forKey: "common") as? NSDictionary{
//        notificationVideoCallText = common.value(forKey: "notificationVideoCallText") as? String ?? notificationVideoCallText
//    }
//    showCustomNotificationWindow(msg: notificationVideoCallText)
//}


//  /////////////////////////////////////////////////////////////////////////

var popoverFocusHelp:NSPopover?//
var popoverTooltip:NSPopover?// = NSPopover()
func showTooltip(sender:NSView, msg:String, preferredEdge: NSRectEdge, maxWidthVal:CGFloat, autoCloseOnMouseExit:Bool = false) {
    if popoverTooltip == nil{
        popoverTooltip = NSPopover()
        popoverTooltip!.animates = false
    }
    
//    if autoCloseOnMouseExit{// it means showing as tooltip on mouse hover and it will close on mouse exit so no transient behavior needed (transient behavior close tooltip when click again on anywhere . but with transient behavior additional nsbox was needed to click on button with same click)
//        popoverTooltip!.behavior = .applicationDefined
//    }else{
//        popoverTooltip!.behavior = .transient
//    }
    popoverTooltip!.behavior = .transient
    if popoverTooltip!.isShown{
        popoverTooltip?.close()
    }
    let vc = getCustomTooltipVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    if vc.maxWidthVal != maxWidthVal{
        vc.maxWidthVal = maxWidthVal
        vc.resetView()
    }
    
    popoverTooltip!.contentViewController = vc
    popoverTooltip!.contentSize = vc.view.frame.size
    
    popoverTooltip!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
    //    appdelegate!.popover.behavior = .applicationDefined
    vc.lblTitle.stringValue = msg
}

func showTooltipWithOsTahoe(sender:NSView, msg:String, preferredEdge: NSRectEdge, maxWidthVal:CGFloat, autoCloseOnMouseExit:Bool = false) {
    if popoverTooltip == nil{
        popoverTooltip = NSPopover()
        popoverTooltip!.animates = false
    }
    popoverTooltip!.behavior = .applicationDefined
    if popoverTooltip!.isShown{
        popoverTooltip?.close()
    }
    let vc = getCustomTooltipVcObject()
    if !vc.isViewLoaded{
        vc.loadView()
    }
    if vc.maxWidthVal != maxWidthVal{
        vc.maxWidthVal = maxWidthVal
        vc.resetView()
    }
    
    popoverTooltip!.contentViewController = vc
    popoverTooltip!.contentSize = vc.view.frame.size
    
    popoverTooltip!.show(relativeTo: sender.bounds, of: sender, preferredEdge: preferredEdge)
    //    appdelegate!.popover.behavior = .applicationDefined
    vc.lblTitle.stringValue = msg
}



func closePopoverTooltipIfVisible(){
    if popoverTooltip != nil{
        if popoverTooltip!.isShown{
            popoverTooltip?.close()
        }
    }
}


func closePomodoroWindowIOfVisible(){
    if pomodoroWindowControllerObj != nil{
        if pomodoroWindowControllerObj!.window!.isVisible{
            pomodoroWindowControllerObj?.window?.close()
            allApiObject.capturePosthog(event: "start-focus-session-popup-closed", metadata: [:])
        }
    }
}

func closePupUpBlockIfVisible(){
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            popUpBlockConfirmVcObj?.closeWindow()
        }else if popUpBlockConfirmVcObj != nil{
            popUpBlockConfirmVcObj?.currentApp = nil
        }
    }
}

func closePopupBlockWindowIfRunningForUrl(){
    currentBrowserUrlForAi = ""
//    appdelegate?.timerForCheckUrlFromAiTimeOut?.invalidate()
    if popUpBlockConfirmWcObj != nil{
        if popUpBlockConfirmWcObj!.window?.isVisible ?? false{
            if !popUpBlockConfirmVcObj!.isAppBlocking{
                popUpBlockConfirmVcObj?.closeWindow()
            }
        }
    }
}


func showNudgeFocusAlignmentScoreWindow(score:Double){
    if !SettingsManagerObject.isFocusVisualIndicatorEnabled{
        if nudgeFocusAlignmentScoreDippingWcObject != nil{
            if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
                nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
            }
            nudgeFocusAlignmentScoreDippingWcObject?.window?.close()
        }
        return;
    }
    
    if nudgeFocusAlignmentScoreDippingVcObj == nil{
        getNudgeFocusAlignmentScoreDippingVcObject().loadView()
    }
    
    //  dont showe popup if active app is focus bear for time tracker
//    if let runningApp = NSWorkspace.shared.frontmostApplication{
//        if let appUrl = runningApp.bundleURL{
//            let name = appUrl.deletingPathExtension().lastPathComponent
//            let nameLowercased = name.lowercased()
//            if nameLowercased == selfAppName.lowercased() || nameLowercased == focusBearTimeTrackerAppName{
//                
//                if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
//                    getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: score, isNudgeVisible: true)
//                    lastFocusAlignmentShownScore = score
//                    return;
//                }
//                
//                return;
//            }
//        }
//    }
    //.
    
    ///If the big floating bear is open, I don’t think we need the little one as well.
    
    getNudgeFocusAlignmentScoreDippingVcObject().isFloatingTopBarRemovedByNudge = false
    if floatingTopBarWcObj != nil{
        if getFloatingTopBarWObject().window?.isVisible ?? false{
            if !getFloatingTopBarVObject().boxMain.isHidden{
                getFloatingTopBarVObject().boxMain.isHidden = true
                getFloatingTopBarVObject().boxMoreItems.isHidden = true
                getNudgeFocusAlignmentScoreDippingVcObject().isFloatingTopBarRemovedByNudge = true
            }
        }
    }
    
    
    if nudgeFocusAlignmentScoreDippingWcObject == nil{
        nudgeFocusAlignmentScoreDippingWcObject = nudgeFocusAlignmentScoreDippingWc()
    }else{
        if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){// if window is not visible but isNudgeVisible is true then make isNudgeVisible false
            if !(nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false){
                nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible = false
            }
        }
    }
    
    if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
        getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: score, isNudgeVisible: true)
        lastFocusAlignmentShownScore = score
        return;
    }
    
    
    
    if !(nudgeFocusAlignmentScoreDippingWcObject?.window?.isVisible ?? false){
        nudgeFocusAlignmentScoreDippingWcObject?.showWindow(nil)
    }
    
    let screenFrame = NSScreen.main?.frame ?? NSRect.zero
    let viewFrame = getNudgeFocusAlignmentScoreDippingVcObject().view.frame
    
    let xPoint = screenFrame.width - (viewFrame.width + 50)
//    if let savedXPoint = UserDefaults.standard.object(forKey: kUserDefaultsLastNudgeScoreWindowXPoisition) as? CGFloat{
//        xPoint = savedXPoint
//    }
    if !isNudgeDraggedInCurrentFocusSession{
        let frame = NSRect(x: xPoint, y: 0 - viewFrame.height, width: viewFrame.width, height: viewFrame.height)
        nudgeFocusAlignmentScoreDippingWcObject?.window?.setFrameOrigin(frame.origin)
    }
    
    nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible = false
    
    if !(nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
        nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
    }
    getNudgeFocusAlignmentScoreDippingVcObject().reloadData(score: score, isNudgeVisible: false)
    lastFocusAlignmentShownScore = score
    getNudgeFocusAlignmentScoreDippingVcObject().setTimerStopAniumation()
}

//func hideNudgeFocusAlignmentScoreWindow(){
//    if nudgeFocusAlignmentScoreDippingWcObject != nil{
//        if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
//            nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
//            nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible = false
//        }
//    }
//}

func closeNudgeFocusAlignmentScoreWindow(){
    if nudgeFocusAlignmentScoreDippingWcObject != nil{
        if (nudgeFocusAlignmentScoreDippingWcObject?.isNudgeVisible ??  false){
            nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
            
            ///If the big floating bear is open, I don’t think we need the little one as well.
            if floatingTopBarWcObj != nil && !isFocusBearMenuVisible(){
                if getFloatingTopBarWObject().window?.isVisible ?? false{
                    getFloatingTopBarVObject().boxMain.isHidden = false
                    getFloatingTopBarVObject().boxMoreItems.isHidden = false
                }
            }
        }
        nudgeFocusAlignmentScoreDippingWcObject?.window?.close()
    }
}



func showReportBadAIResponseWindow(url:String?, app:String?, payload:[String:Any]?){
    getReportBadAIResponseWindowObject().contentViewController = getReportBadAIResponseVcObject()
    getReportBadAIResponseWindowObject().window?.center()
    getReportBadAIResponseWindowObject().showWindow(nil)
    getReportBadAIResponseVcObject().resetData(url: url, app: app, payload: payload)
}



//***********show Custom Routine Time Window***************//

func showCustomRoutineTimeWindow(index:Int){
    addLog(text:"showCustomRoutineTimeWindow")
    allApiObject.capturePosthog(event: "custom-routine-time-window-shown", metadata: [:])
    getCustomRoutineTimeWindowObject().contentViewController = getCustomRoutineTimeVcObject()
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    getCustomRoutineTimeWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (customRoutineTimeVcObj?.view.frame.width)!, y: screenFrame.height - (customRoutineTimeVcObj?.view.frame.height)! - 22)) //  22 is status bar heigh
    
    customRoutineTimeWcObj?.window?.title = appName
    customRoutineTimeWcObj!.showWindow(nil)
    customRoutineTimeVcObj!.resetView(index: index)
}
//------------------hideCustomRoutineTimeWindow-------------------------------//


func hideCustomRoutineTimeWindowIfVisible(){
    if customRoutineTimeWcObj != nil{
        if customRoutineTimeWcObj?.window?.isVisible ?? false{
            customRoutineTimeWcObj?.window?.close()
        }
    }
}

//




func showNudgeStartAnotherFocusSessionWindow(){
    addLog(text:"showNudgeStartAnotherFocusSessionWindow")
    if nudgeStartAnotherFocusSessionWcObj == nil{
        getNudgeStartAnotherFocusSessionVcObject().loadView()
        nudgeStartAnotherFocusSessionWcObj = getNudgeStartAnotherFocusSessionWcObject()
        nudgeStartAnotherFocusSessionWcObj?.contentViewController = getNudgeStartAnotherFocusSessionVcObject()
        
        
        nudgeStartAnotherFocusSessionWcObj?.window?.level = .statusBar
        nudgeStartAnotherFocusSessionWcObj?.window?.isMovableByWindowBackground = true
        nudgeStartAnotherFocusSessionWcObj?.window?.isOpaque = false
        nudgeStartAnotherFocusSessionWcObj?.window?.hasShadow = false
        nudgeStartAnotherFocusSessionWcObj?.window?.backgroundColor = NSColor.clear
        nudgeStartAnotherFocusSessionWcObj?.window?.styleMask = .borderless
        
        nudgeStartAnotherFocusSessionWcObj?.window?.collectionBehavior = .stationary // prevent from expose desktop under mission control
    }

    nudgeStartAnotherFocusSessionWcObj?.showWindow(nil)
    
    let screenFrame = NSScreen.main?.visibleFrame ?? NSRect.zero
    let viewFrame = getNudgeStartAnotherFocusSessionVcObject().view.frame
    
    let xPoint = screenFrame.width - (viewFrame.width + 50)

    let frame = NSRect(x: xPoint, y: screenFrame.minY, width: viewFrame.width, height: viewFrame.height)
    nudgeStartAnotherFocusSessionWcObj?.window?.setFrameOrigin(frame.origin)
}

func hideNudgeStartAnotherFocusSessionWindow(){
    if nudgeStartAnotherFocusSessionWcObj != nil{
        if nudgeStartAnotherFocusSessionWcObj?.window?.isVisible ?? false{
            addLog(text:"hideNudgeStartAnotherFocusSessionWindow")
            nudgeStartAnotherFocusSessionWcObj?.window?.close()
        }
    }
}


func showSplashWindow(){
    getSplashWindowObject().contentViewController = getSplashVcObject()
    getSplashWindowObject().showWindow(nil)
}

func closeSplashWindow(){
    if splashWcObj != nil{
        if splashWcObj?.window?.isVisible ?? false{
            getSplashWindowObject().window?.close()
        }
    }
}


var arrWindows = [NSWindow]()
func showBlankWindowInSecondaryMonitor(){
    addLog(text: "func:- showBlankWindowInSecondaryMonitor")
    
    // Luisa App broken bug fix 28/6/22
    let windows = NSApp.windows
    for win in windows{
        print(win)
        if win.isModalPanel{
            NSApp.stopModal()
            break;
        }
    }
    //  /////////////////////////////////
    if !checkIsFullScreenEnabled(){//Blank Window In Secondary Monitor is not required if full screen is not enabled
        return;
    }
    appdelegate?.showExtraWindows()
}



func hideBlankWindowInSecondaryMonitor(){
    addLog(text: "func:- hideBlankWindowInSecondaryMonitor")
    for i in 0..<arrWindows.count{
        let window = arrWindows[i]
        window.orderOut(nil)
        arrWindows[i].windowController?.window=nil
    }
    arrWindows.removeAll()
}

func resetWin(_ win: NSWindow) -> NSWindow {
    win.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces          // we want these windows to follow Spaces around
    //use .desktopWindow for window below icons   //hack? this makes mission control and expose ignore these windows
    //        if toggleButtonHideDesktopIcons.isOn{
    //            win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.backstopMenu)))
    //        }else{
    win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
    //        }
    // rest is to make the windows dumb
    win.canHide = false
    win.isExcludedFromWindowsMenu = true
    win.hidesOnDeactivate = false
    win.discardCursorRects()
    win.discardEvents(matching: NSEvent.EventTypeMask.any, before: nil)
    //win.ignoresMouseEvents = true
    win.orderBack(nil)
    win.isRestorable = false
    win.animationBehavior = .none
    win.backgroundColor = NSColor.clear
    return win
}



func isFocusCompletedViewVisibled()->Bool{
    if mainWindowControllerObj?.window?.isVisible ?? false{
        if (leftMenuVcObj?.boxFocusSession.isSelected ?? false) && focusCompletedVcObj != nil{
            if focusCompletedVcObj!.isViewLoaded{
                if mainViewControllerObj!.containerView.subviews.contains(focusCompletedVcObj!.view){
                    return true
                }
            }
        }
    }
    return false
}


func showFloatingTopBarWindow(windowTopMidPoint:NSPoint){
    if floatingTopBarWcObj == nil{
        getFloatingTopBarWObject().contentViewController = getFloatingTopBarVObject()
        getFloatingTopBarWObject().window?.level = .statusBar
        getFloatingTopBarWObject().window?.isMovable = true
        getFloatingTopBarWObject().window?.isMovableByWindowBackground = true
        getFloatingTopBarWObject().window?.isOpaque = false
        getFloatingTopBarWObject().window?.hasShadow = false
        getFloatingTopBarWObject().window?.backgroundColor = NSColor.clear
        getFloatingTopBarWObject().window?.styleMask = .borderless
    }
    getFloatingTopBarWObject().showWindow(nil)
    let boxMainMaxY = floatingTopBarVcObj?.boxMain.frame.maxY ?? 134
    
    var origin = NSPoint(x: windowTopMidPoint.x - (getFloatingTopBarVObject().view.frame.width / 2), y: windowTopMidPoint.y - boxMainMaxY)// 34. box height
    if SettingsManagerObject.isMenuPopoverEnabled{
        origin = NSPoint(x: windowTopMidPoint.x - (getFloatingTopBarVObject().view.frame.width / 2), y: windowTopMidPoint.y - boxMainMaxY - 10)// 10 is arrow height
    }
    getFloatingTopBarWObject().window?.setFrameOrigin(origin)
    getFloatingTopBarVObject().boxMain.isHidden = false
    getFloatingTopBarVObject().boxMoreItems.isHidden = false
}


func closeMenuWindowIsVisible(){
    if !SettingsManagerObject.isMenuPopoverEnabled{
        if menuWcObj != nil{
            if menuWcObj?.window?.isVisible ?? false{
                menuWcObj?.window?.close()
            }
        }
    }
}

func closeMainMenuIfVisible(){
    if SettingsManagerObject.isMenuPopoverEnabled{
        if appdelegate?.popover.isShown ?? false{
            appdelegate?.popover.close()
        }
    }else{
        if getMenuWindowObject().window?.isVisible ?? false{
            getMenuWindowObject().window?.close()
        }
    }
}

//***********SHOW Small Timer WINDOW***************//

func showSmallTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool, currentTimerValue:Int){
    addLog(text:"show Top Small Timer Window for:- \(durationSeconds) seconds")
    closeMainMenuIfVisible()
    floatingTopBarVcObj?.showTimerWindow(durationSeconds: durationSeconds, msg: msg, isFocusBreak: isFocusBreak, currentTimerValue: currentTimerValue)
    
    if floatingTopBarVcObj != nil {
        floatingTopBarVcObj?.boxMain.isHidden = false
        floatingTopBarVcObj?.boxMoreItems.isHidden = false
    }
    
//    getSmallCountDownWindowObject().contentViewController = getsmallCountDownVcObject()
//    smallCountDownVcObj?.isFocusBreak = isFocusBreak
//    getSmallCountDownWindowObject().window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//    
//    getSmallCountDownWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (smallCountDownVcObj?.view.frame.width)!, y: screenFrame.height - (smallCountDownVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
//    getSmallCountDownWindowObject().window?.isMovableByWindowBackground = true
//    
//    getSmallCountDownWindowObject().showWindow(nil)
//    
//    smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, msg: msg, currentTimerValue:currentTimerValue)
}

func showCustomBlockingScheduleStartPopUp(scheduleName: String, scheduleTime: String){
    addLog(text:"show Custom Blocking Schedule Start PopUp for:- \(scheduleTime)")
    closeMainMenuIfVisible()
    floatingTopBarVcObj?.lblScheduleName.stringValue = scheduleName
    floatingTopBarVcObj?.lblScheduleTime.stringValue = scheduleTime
    floatingTopBarVcObj?.boxCustomBlockingSchedule.isHidden = false
}

func showSmallTimerView(){
//    getsmallCountDownVcObject().view.isHidden = false
    floatingTopBarVcObj?.boxTimer.isHidden = false
    floatingTopBarVcObj?.timerBoxShown()
}

//***********SHOW Focus End Warning***************//

func showFocusEndWarningWindow(){
    addLog(text:"showFocusEndWarningWindow")
    getFocusEndWarningWindowObject().contentViewController = getFocusEndWarningVcObject()
    //    getFocusEndWarningWindowObject().window?.styleMask = .borderless
    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
    //    getFocusEndWarningWindowObject().window?.styleMask.remove(.closable)
    getFocusEndWarningWindowObject().window?.title = appName
    getFocusEndWarningWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (getFocusEndWarningVcObject().view.frame.width), y: screenFrame.height - (getFocusEndWarningVcObject().view.frame.height) - 22)) //  22 status bar heigh
    //    getFocusEndWarningWindowObject().window?.isMovableByWindowBackground = true
    getFocusEndWarningWindowObject().showWindow(nil)
}

//***********SHOW Custom Notification WINDOW***************//
//func showCustomNotificationWindow(msg: String){
//    addLog(text:"show Custom Notification Window")
//    getCustomNotificationWindowObject().contentViewController = getCustomNotificationVcObject()ye view  subview bhi ban rha h to dekh k use kro agar uncomment kro to
//    getCustomNotificationWindowObject().window?.styleMask = .borderless
//    let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
//    getCustomNotificationWindowObject().window?.backgroundColor = NSColor.clear
//    getCustomNotificationWindowObject().window?.setFrameOrigin(NSPoint(x: screenFrame.width - (customNotificationVcObj?.view.frame.width)!, y: screenFrame.height - (customNotificationVcObj?.view.frame.height)! - 22)) //  22 status bar heigh
//
//    getCustomNotificationWindowObject().showWindow(nil)
//    customNotificationVcObj?.resetView(msg: msg)
//}

//***********SHOW Custom Notification View***************//
func showCustomNotificationView(msg: String){
    if mainWindowControllerObj?.window?.isVisible ?? false{
        addLog(text:"show Custom Notification View")
        let _ = getCustomNotificationVcObject()
        getHabitsVcObject().view.addSubview(customNotificationVcObj!.view)
        getHabitsVcObject().view.addTopRightConstraints(subView: customNotificationVcObj!.view)
        customNotificationVcObj!.resetView(msg: msg)
    }
    
}


func isSmallCountDownTimerViewVisible()->Bool{
    if smallCountDownVcObj != nil{
        return !(floatingTopBarVcObj?.boxTimer.isHidden ?? false)
    }
    return false
}

func closeSmallCountDownTimerBoxIfVisible(){
    if isSmallCountDownTimerViewVisible(){
        smallCountDownVcObj?.closeTimerBox()
    }
}

func closeSmallCountDownTimerBoxIfVisibleForFocusBreak(){
    if isSmallCountDownTimerViewVisible(){
        if (smallCountDownVcObj?.isFocusBreak ?? false){
            smallCountDownVcObj?.closeTimerBox()
        }
    }
}


func closeSmallCountDownTimerBoxIfVisibleForWithoutFocusBreak(){
    if isSmallCountDownTimerViewVisible(){
        if !(smallCountDownVcObj?.isFocusBreak ?? false){
            smallCountDownVcObj?.closeTimerBox()
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


func closeAlwaysBlockPopupsIfNotForeCurrentDomain(domain:String, runningApp:NSRunningApplication){
    if intentionBlockedUrlsWcObj != nil{
        if intentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            if intentionBlockedUrlsVcObj?.tabUrl != domain{
                intentionBlockedUrlsWcObj?.window?.close()
            }
        }
    }
    if setIntentionBlockedUrlsWcObj != nil{
        if setIntentionBlockedUrlsWcObj?.window?.isVisible ?? false{
            if setIntentionBlockedUrlsVcObj?.tabUrl == domain{
                exitFullScreen(runningApp: runningApp)
            }else{
                setIntentionBlockedUrlsVcObj?.closeWindow()
            }
        }
    }
}

func closeIntentionBlockedAppsWinddowIfVisible(){
    if intentionBlockedAppsWcObj != nil{
        if intentionBlockedAppsWcObj?.window?.isVisible ?? false{
            intentionBlockedAppsWcObj?.window?.close()
        }
    }
}
