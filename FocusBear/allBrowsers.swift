//
//  allBrowsers.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Foundation

/// Run an AppleScript source and return its result descriptor, ALWAYS on the main thread.
/// NSAppleScript is not thread-safe; executing it on a background queue (e.g. the URL/tab timer)
/// intermittently segfaults inside Apple's AppleScript compiler — that was the browser-tab-count crash.
/// Routes through `runAppleScriptSafely`, the single serialised AppleScript entry point, so browser
/// scripts never execute concurrently with other NSAppleScript on a different thread. NSAppleScript
/// is not thread-safe: running browser scripts on the main thread (as this used to) while other
/// scripts ran on the AppleScript serial queue segfaulted inside Apple's AppleScript compiler
/// (EXC_BAD_ACCESS during compile). The `with timeout` guard (#1950) prevents hangs but not that
/// crash — serialising every NSAppleScript execution onto one queue does.
func runBrowserAppleScript(_ source: String, timeoutSeconds: Int = 5) -> NSAppleEventDescriptor? {
    var errors: NSDictionary?
    let desc = runAppleScriptSafely(source, timeoutSeconds: timeoutSeconds, errors: &errors)
    if errors != nil { print(errors as Any) }
    return desc
}

//*****************all browsers Active Tab Url and Titlle*********************//

enum BROWSER:Int{
    case _GOOGLE_CHROME_ = 152, _SAFARI_, _BRAVE_BROWSER_, _SIDEKICK_, _MICROSOFT_EDGE_, _ARC_, _FIREFOX_, _OPERA_, _VIVALDI_, _OPERA_GX_, _SIGMA_OS_// start state sirf first activity ki start mi hi hoti h fir  second activity ki start mai "end state hoti hai "
}
var sigmaOsBrowserName = "SigmaOS" // SigmaOS_latest
var arrBrowsersLowerCasedNames = ["safari", "google chrome", "sidekick", "brave browser", "microsoft edge", "arc", "firefox", "opera", "vivaldi", "opera gx", "sigmaos", "sigmaos_latest"]//if any change in this array, should also change in browsers list in onboardingcontrollingbrowservc

func getBrowserAllTabUrl(browser:BROWSER)->[String]?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    var browserName = ""
    
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._FIREFOX_{
        if let url = getFirefoxActiveTabUrl(){
            return [url]
        }
    }else if browser == ._SIGMA_OS_{
        if let url = getSigmaOSBrowserActiveTabUrl(){
            return [url]
        }
    }
    
    var script: String = ""
    
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set end of arrayTabs to URL of theTab
        end repeat
        return arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set the_wnd to front window
        set allTabs to tabs in the_wnd
        set arrayTabs to {}
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set end of arrayTabs to taburl
        end repeat
        return the arrayTabs
        end tell
        """
    }
    
    
    if let desc = runBrowserAppleScript(script) {
        return desc.toStringArray()
    }
    return nil
}


func getBrowserAllTabUrlAndTitle(browser:BROWSER)->[(title: String, url: String)]?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    var browserName = ""
    
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }else if browser == ._FIREFOX_{
        if let url = getFirefoxActiveTabUrl(), let title = getFirefoxActiveTabTitle(){
            return [(title, url)]
        }
    }else if browser == ._SIGMA_OS_{
        if let url = getSigmaOSBrowserActiveTabUrl(), let title = getSigmaOSBrowserActiveTabTitle(){
            return [(title, url)]
        }
    }
    

    
    
    var script: String = ""
    
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set tabTitle to title of theTab
        set tabURL to URL of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        return arrayTabs
        end tell
        """
    }else if browser == ._SAFARI_{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayTabs to {}
        repeat with the_wnd in allWinds
        set allTabs to tabs in the_wnd
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set tabTitle to name of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        end repeat
        return the arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayTabs to {}
        repeat with the_wnd in allWinds
        set allTabs to tabs of the_wnd
        repeat with theTab in allTabs
        set tabTitle to title of theTab
        set tabURL to URL of theTab
        set end of arrayTabs to {tabTitle, tabURL}
        end repeat
        end repeat
        return arrayTabs
        end tell
        """
    }
    

    
    
    if let desc = runBrowserAppleScript(script) {
        return desc.toTwoColumnStringArray()
    }
    return nil
}



func getActiveTabUrlForBlocking(browser:BROWSER)->String?{
    addLog(text:"func call:- getActiveTabUrl")
    
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        addLog(text:"Browsers Permissions is not Set By User return;")
        return nil
    }
    var url:String?
    if browser == ._SAFARI_{
        url = getSafariActiveTabUrl()
    }else if browser == ._GOOGLE_CHROME_{
        url = getGoogleChromeActiveTabUrl()
    }else if browser == ._OPERA_{
        url = getOperaActiveTabUrl()
    }else if browser == ._OPERA_GX_{
        url = getOperaGxActiveTabUrl()
    }else if browser == ._VIVALDI_{
        url = getVivaldiActiveTabUrl()
    }else if browser == ._BRAVE_BROWSER_{
        url = getBraveBrowserActiveTabUrl()
    }else if browser == ._SIDEKICK_{
        url = getSidekickBrowserActiveTabUrl()
    }else if browser == ._MICROSOFT_EDGE_{
        url = getMicrosoftEdgeActiveTabUrl()
    }else if browser == ._ARC_{
        url = getArcBrowserActiveTabUrl()
    }else if browser == ._FIREFOX_{
        url = getFirefoxActiveTabUrl()
    }else if browser == ._SIGMA_OS_{
        url = getSigmaOSBrowserActiveTabUrl()
    }

    // check which browser is allowed in automation
    if url != nil{
        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
            for i in 0..<arrBrowsersInfo.count{
                let info = arrBrowsersInfo[i]
                let browserRawValue = info["browser"] as? Int ?? 0
                if browser.rawValue == browserRawValue{
                    arrBrowsersInfo[i]["isEnabled"] = true
                    break;
                }
            }
            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
        }
    }else if browser == ._FIREFOX_{// may be extension not installed. for old users because from now firefox blocking is based on extension v 2.27.435
        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
            for i in 0..<arrBrowsersInfo.count{
                let info = arrBrowsersInfo[i]
                let browserRawValue = info["browser"] as? Int ?? 0
                if browser.rawValue == browserRawValue{
                    arrBrowsersInfo[i]["isEnabled"] = false
                    break;
                }
            }
            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
        }
    }
    if let url = url{
        if url.isEmpty{
            addLog(text:"url is empty return;")
            return nil;  //is blank then return nil so we will not read this // 26/4/25
        }
    }
    return url
}


func getActiveTabUrlOf(browser:BROWSER)->String?{
    addLog(text:"func call:- getActiveTabUrl")
    
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        addLog(text:"Browsers Permissions is not Set By User return;")
        return nil
    }
    var url:String?
    if browser == ._SAFARI_{
        url = getSafariActiveTabUrl()
    }else if browser == ._GOOGLE_CHROME_{
        url = getGoogleChromeActiveTabUrl()
    }else if browser == ._OPERA_{
        url = getOperaActiveTabUrl()
    }else if browser == ._OPERA_GX_{
        url = getOperaGxActiveTabUrl()
    }else if browser == ._VIVALDI_{
        url = getVivaldiActiveTabUrl()
    }else if browser == ._BRAVE_BROWSER_{
        url = getBraveBrowserActiveTabUrl()
    }else if browser == ._SIDEKICK_{
        url = getSidekickBrowserActiveTabUrl()
    }else if browser == ._MICROSOFT_EDGE_{
        url = getMicrosoftEdgeActiveTabUrl()
    }else if browser == ._ARC_{
        url = getArcBrowserActiveTabUrl()
    }else if browser == ._FIREFOX_{
        url = getFirefoxActiveTabUrl()
    }else if browser == ._SIGMA_OS_{
        url = getSigmaOSBrowserActiveTabUrl()
    }

    //--------------------------------------------//
    // check which browser is allowed in automation
    if url != nil{
        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
            for i in 0..<arrBrowsersInfo.count{
                let info = arrBrowsersInfo[i]
                let browserRawValue = info["browser"] as? Int ?? 0
                if browser.rawValue == browserRawValue{
                    arrBrowsersInfo[i]["isEnabled"] = true
                    break;
                }
            }
            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
        }
    }
    if let url = url{
        if url.isEmpty{
            addLog(text:"url is empty return;")
            return nil;  //is blank then return nil so we will not read this // 26/4/25
        }
    }
    return url
}

func getActiveTabTitleOf(browser:BROWSER)->String?{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return nil
    }
    if browser == ._SAFARI_{
        return getSafariActiveTabTitle()
    }else if browser == ._GOOGLE_CHROME_{
        return getGoogleChromeActiveTabTitle()
    }else if browser == ._OPERA_{
        return getOperaActiveTabTitle()
    }else if browser == ._OPERA_GX_{
        return getOperaGxActiveTabTitle()
    }else if browser == ._VIVALDI_{
        return getVivaldiActiveTabTitle()
    }else if browser == ._BRAVE_BROWSER_{
        return getBraveBrowserActiveTabTitle()
    }else if browser == ._SIDEKICK_{
        return getSidekickBrowserActiveTabTitle()
    }else if browser == ._MICROSOFT_EDGE_{
        return getMicrosoftEdgeActiveTabTitle()
    }else if browser == ._ARC_{
        return getArcBrowserActiveTabTitle()
    }else if browser == ._FIREFOX_{
        return getFirefoxActiveTabTitle()
    }else if browser == ._SIGMA_OS_{
        return getSigmaOSBrowserActiveTabTitle()
    }
    return nil
}






func getAllBrowsersTabCount()->Int{
    var totalTabsCount = 0
    let runningApps = NSWorkspace.shared.runningApplications
    var isSafariRunning = false
    var isChromeRunning = false
    var isBraveRunning = false
    var isEdgeRunning = false
    var isSideKickRunning = false
    var isArcRunning = false
    var isOperaRunning = false
    var isVivaldiRunning = false
    var isOperaGxRunning = false
    
    for app in runningApps{
        if let appUrl = app.bundleURL{
            let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
            if nameLowercased == "safari"{
                let keys = safariWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = safariWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isSafariRunning = true
            }else if nameLowercased == "google chrome"{
                let keys = googleChromeWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = googleChromeWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isChromeRunning = true
            }else if nameLowercased == "opera"{
                let keys = operaWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = operaWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isOperaRunning = true
            }else if nameLowercased == "opera gx"{
                let keys = operaGxWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = operaGxWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isOperaGxRunning = true
            }else if nameLowercased == "vivaldi"{
                let keys = vivaldiWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = vivaldiWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isVivaldiRunning = true
            }else if nameLowercased == "brave browser"{
                let keys = braveBrowserWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = braveBrowserWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isBraveRunning = true
            }else if nameLowercased == "sidekick"{
                let keys = sidekickWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = sidekickWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isSideKickRunning = true
            }else if nameLowercased == "microsoft edge"{
                let keys = microsoftEdgeWindowsInfo.keys
                for key in keys{
                    if let browserTabsArr = microsoftEdgeWindowsInfo[key]{
                        totalTabsCount += browserTabsArr.count
                    }
                }
                isEdgeRunning = true
            }else if nameLowercased == "arc"{
                totalTabsCount += arcBrowserTabsInfo.count
                isArcRunning = true
            }
        }
    }
    if !isSafariRunning{
        safariWindowsInfo.removeAll()
    }
    
    if !isChromeRunning{
        googleChromeWindowsInfo.removeAll()
    }
    if !isOperaRunning{
        operaWindowsInfo.removeAll()
    }
    
    if !isOperaGxRunning{
        operaGxWindowsInfo.removeAll()
    }
    
    if !isVivaldiRunning{
        vivaldiWindowsInfo.removeAll()
    }
    if !isBraveRunning{
        braveBrowserWindowsInfo.removeAll()
    }
    if !isEdgeRunning{
        microsoftEdgeWindowsInfo.removeAll()
    }
    if !isSideKickRunning{
        sidekickWindowsInfo.removeAll()
    }
    if !isArcRunning{
        arcBrowserTabsInfo.removeAll()
    }
    return totalTabsCount
}


func getBrowserAllWindowStruct(browser:BROWSER)->[String:[String]]?{
    var browserName = ""
    
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }
    
    var script: String = ""
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        set arrayTabs to {}
        repeat with theTab in tabs of front window
        set end of arrayTabs to URL of theTab
        end repeat
        return arrayTabs
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set allWinds to windows
        set arrayWinds to {}
            
        repeat with the_wnd in allWinds
        set arrayTabs to {}
        set allTabs to tabs in the_wnd
        repeat with theTab in allTabs
        set taburl to URL of theTab
        set end of arrayTabs to taburl
        end repeat
        set idWind to id of the_wnd
        set arr to {idWind, arrayTabs}
        set end of arrayWinds to arr
        end repeat
        return the arrayWinds
        end tell
        """
        
    }
    
    
    if let desc = runBrowserAppleScript(script) {
        if browser == ._ARC_{
            return ["window": desc.toStringArray()]
        }
        return desc.toAnyArray()
    }
    return nil
}

func closeTabAt(index:Int, browser:BROWSER){
    let tab = index + 1// browser first tab index is 1 not 0

    var browserName = ""
    if browser == ._SAFARI_{
        browserName = "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        browserName = "Google Chrome"
    }else if browser == ._OPERA_{
        browserName = "Opera"
    }else if browser == ._OPERA_GX_{
        browserName = "Opera GX"
    }else if browser == ._VIVALDI_{
        browserName = "Vivaldi"
    }else if browser == ._BRAVE_BROWSER_{
        browserName = "Brave Browser"
    }else if browser == ._SIDEKICK_{
        browserName = "Sidekick"
    }else if browser == ._MICROSOFT_EDGE_{
        browserName = "Microsoft Edge"
    }else if browser == ._ARC_{
        browserName = "Arc"
    }
    
    var script: String = ""
    
    if browser == ._ARC_{
        script =
        """
        tell application "Arc"
        close item \(tab) of tabs in front window
        end tell
        """
    }else{
        script =
        """
        tell application "\(browserName)"
        set the_wnd to front window
        set allTabs to tabs in the_wnd
        set active_tab to item \(tab) of allTabs
        active_tab close
        end tell
        """
    }
    executeScript(script: script)
}


func getCurrentBrowserFrom(browserName:String)->BROWSER?{
    if browserName == "safari"{
        return ._SAFARI_
    }else if browserName == "google chrome"{
        return ._GOOGLE_CHROME_
    }else if browserName == "opera"{
        return ._OPERA_
    }else if browserName == "opera gx"{
        return ._OPERA_GX_
    }else if browserName == "vivaldi"{
        return ._VIVALDI_
    }else if browserName == "sidekick" {
        return ._SIDEKICK_
    }else if browserName == "brave browser"{
        return ._BRAVE_BROWSER_
    }else if browserName == "microsoft edge"{
        return ._MICROSOFT_EDGE_
    }else if browserName == "arc"{
        return ._ARC_
    }else if browserName == "firefox"{
        return ._FIREFOX_
    }else if browserName == "sigmaos"{
        return ._SIGMA_OS_
    }else if browserName == "sigmaos_latest"{
        return ._SIGMA_OS_
    }else{
        return nil
    }
}

func getCurrentBrowserNameFrom(browser:BROWSER)->String?{
    if browser == ._SAFARI_{
        return "Safari"
    }else if browser == ._GOOGLE_CHROME_{
        return "Google Chrome"
    }else if browser == ._OPERA_{
        return "Opera"
    }else if browser == ._OPERA_GX_{
        return "Opera GX"
    }else if browser == ._VIVALDI_{
        return "Vivaldi"
    }else if browser == ._SIDEKICK_ {
        return "Sidekick"
    }else if browser == ._BRAVE_BROWSER_{
        return "Brave Browser"
    }else if browser == ._MICROSOFT_EDGE_{
        return "Microsoft Edge"
    }else if browser == ._ARC_{
        return "Arc"
    }else if browser == ._FIREFOX_{
        return "Firefox"
    }else if browser == ._SIGMA_OS_{
        return sigmaOsBrowserName
    }else{
        return nil
    }
}

func setUrlToBrowser(browser:BROWSER, url:String){
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return;
    }
    var script = ""
    var browserName = ""
    
    switch browser {
    case ._GOOGLE_CHROME_:
        browserName = "Google Chrome"
    case ._OPERA_:
        browserName = "Opera"
    case ._OPERA_GX_:
        browserName = "Opera GX"
    case ._VIVALDI_:
        browserName = "Vivaldi"
    case ._SAFARI_:
        browserName = "Safari"
    case ._BRAVE_BROWSER_:
        browserName = "Brave Browser"
    case ._SIDEKICK_:
        browserName = "Sidekick"
    case ._MICROSOFT_EDGE_:
        browserName = "Microsoft Edge"
    case ._ARC_:
        browserName = "Arc"
    case ._FIREFOX_:
        browserName = "Firefox"
    case ._SIGMA_OS_:
        browserName = sigmaOsBrowserName
    }
    
    
    if browser == ._SAFARI_{
        script = """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set URL of active_tab to "\(url)"
    end tell
    """
    }else if browser == ._ARC_{
        script = """
                tell application \(browserName)
                set URL of active tab in front window to "\(url)"
                end tell
                """
    }else if browser == ._FIREFOX_{
        
        firefoxServer.sendUnBlockNow(url: url)
        return;//
        
//        if isVersionLower(currentVersion: fireFoxLatestVersion, referenceVersion: "133.0.3"){
//            script = """
//                    tell application "System Events" to set value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(url)"
//                    tell application "Firefox"
//                    activate
//                    end tell
//                    tell application "System Events" to key code 36
//                    """
//        }else{
//            script = """
//                    tell application "System Events" to set value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(url)"
//                    tell application "Firefox"
//                    activate
//                    end tell
//                    tell application "System Events" to key code 36
//                    """
//        }
        
    }else if browser == ._SIGMA_OS_{
        script = """
                tell application "\(sigmaOsBrowserName)" to activate
                 delay 0.2
                 tell application "System Events"
                     key code 53 -- press Escape to dismiss any popover
                     keystroke "l" using {command down} -- focus the address bar
                     delay 0.2
                     tell application process "SigmaOS"
                         -- Focus the URL text field
                         set urlField to text field 1 of group 1 of window 1
                         tell urlField
                             -- perform action "AXPress"
                             set value to "\(url)"
                         end tell
                         
                         -- Simulate pressing Return to load the URL
                         keystroke return
                     end tell
                 end tell
                """
    }else{
        script = """
    tell application "\(browserName)"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(url)"
    end tell
    """
    }
    executeScript(script: script)
}

//--------------------------------------------//

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
    
    return executeScriptAndReturnString(script: script)
}

func getSafariActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set tabtitle to name of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
/*
 
 tell application "System Events" to set isFocused to focused of UI element 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 if isFocused = false then
     tell application "System Events" to set urlValue to value of UI element 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 end if
 */

/*
 
 tell application "System Events" to set isFocused to focused of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 if isFocused = false then
     
     tell application "System Events" to set urlValue to value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
 end if
 
 */
var fireFoxLatestVersion = ""
func getFireFoxVersion()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Firefox"
    set firefoxVersion to (get version)
    end tell
    """
    return executeScriptAndReturnString(script: script)
}

func isVersionLower(currentVersion: String, referenceVersion: String) -> Bool {
    return currentVersion.compare(referenceVersion, options: .numeric) == .orderedAscending
}

func getFirefoxActiveTabUrl()->String?{
    return firefoxServer.currentTabUrl
    
//    var script: String = ""
//    if let currentVersion = getFireFoxVersion(){
//        fireFoxLatestVersion = currentVersion
//        print("version of firefox is:-")
//        print(currentVersion)
//        
//        if isVersionLower(currentVersion: currentVersion, referenceVersion: "133.0.3"){
//            script =
//            """
//            tell application "System Events" to set isFocused to focused of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            if isFocused = false then
//                        
//            tell application "System Events" to set urlValue to value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            end if
//            """
//        }else{
//            script =
//            """
//            tell application "System Events" to set urlValue to value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//            """
//        }
//    }else{
//        script =
//        """
//        tell application "System Events" to set urlValue to value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox"
//        """
//    }
//    
//    if let appleScript = NSAppleScript(source: script) {
//        var errors : NSDictionary? = nil
//        let desc = appleScript.executeAndReturnError(&errors)
//        if errors != nil {
//            print(errors!)
//            if let errorCode = errors?.value(forKey: "NSAppleScriptErrorNumber") as? Int{
//                if let browser = getCurrentBrowserFrom(browserName: "firefox"){
//                    if errorCode == -1743{
//                        if var arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
//                            for i in 0..<arrBrowsersInfo.count{
//                                let info = arrBrowsersInfo[i]
//                                let browserRawValue = info["browser"] as? Int ?? 0
//                                if browser.rawValue == browserRawValue{
//                                    arrBrowsersInfo[i]["isEnabled"] = false
//                                    break;
//                                }
//                            }
//                            UserDefaults.standard.set(arrBrowsersInfo, forKey: kUserdefaultsAllBrowsersPermissionInfo)
//                        }
//                    }else if desc.stringValue == nil{
//                        return ""
//                    }
//                }
//            }
//        }
//        return desc.stringValue?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//    }
//    return nil
}

func getFirefoxActiveTabTitle()->String?{//
    return firefoxServer.currentTabTitle
    
//    var script: String = ""
//    
//    script =
//    """
//    tell application "Firefox"
//    set the_title to name of windows's item 1
//    end tell
//    """
//    
//    return executeScriptAndReturnString(script: script)
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
    
    return executeScriptAndReturnString(script: script)
}

func getGoogleChromeActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaGxActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getOperaGxActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getVivaldiActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getVivaldiActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getBraveBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getBraveBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}


func getSidekickBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}
func getSidekickBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getMicrosoftEdgeActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set taburl to URL of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getMicrosoftEdgeActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set tabtitle to title of active_tab
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}



func getArcBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Arc"
    get URL of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getArcBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "Arc"
    get title of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getSigmaOSBrowserActiveTabUrl()->String?{
    var script: String = ""
    
    script =
    """
    tell application "\(sigmaOsBrowserName)"
    get URL of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}

func getSigmaOSBrowserActiveTabTitle()->String?{
    var script: String = ""
    
    script =
    """
    tell application "\(sigmaOsBrowserName)"
    get name of active tab of front window
    end tell
    """
    
    return executeScriptAndReturnString(script: script)
}



func getFirefoxBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    
    return """
    old_url=\(url)&\(params)&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())&version=\(appVersion)\(newPageParam)"
    """
    
   // return; //
//    if isVersionLower(currentVersion: fireFoxLatestVersion, referenceVersion: "133.0.3"){
//        return """
//        tell application "System Events" to set value of UI element 1 of combo box 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
//        tell application "Firefox"
//        activate
//        end tell
//        tell application "System Events" to key code 36
//        """
//    }else{
//        return """
//        tell application "System Events" to set value of text field 1 of combo box 1 of group 1 of toolbar "Navigation" of first group of front window of application process "Firefox" to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
//        tell application "Firefox"
//        activate
//        end tell
//        tell application "System Events" to key code 36
//        """
//    }
}

func getSigmaOsBrowserBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    
    
    return """
                 tell application "\(sigmaOsBrowserName)" to activate
                 delay 0.2
                 tell application "System Events"
                     key code 53 -- press Escape to dismiss any popover
                     keystroke "l" using {command down} -- focus the address bar
                     delay 0.2
                     tell application process "SigmaOS"
                         -- Focus the URL text field
                         set urlField to text field 1 of group 1 of window 1
                         tell urlField
                             -- perform action "AXPress"
                             set value to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
                         end tell
                         
                         -- Simulate pressing Return to load the URL
                         keystroke return
                     end tell
                 end tell
                """
}

func getSafariBlockScript(url:String)->String{//"&confirm_ai_distracting_url=true"
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Safari"
    set the_wnd to front window
    set active_tab to current tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getGoogleChromeBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Google Chrome"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getOperaBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Opera"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getOperaGxBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Opera GX"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getVivaldiBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Vivaldi"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getBraveBrowserBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Brave Browser"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getSidekickBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Sidekick"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getMicrosoftEdgeBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Microsoft Edge"
    set the_wnd to front window
    set active_tab to active tab in the_wnd
    set URL of active_tab to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

func getArcBlockScript(url:String)->String{
    let params = "<PARAMS>"
    let newPageParam = "<NEWPAGE>"
    return """
    tell application "Arc"
    set URL of active tab in front window to "\(blockWebUrlString)?old_url=" & "\(url)" & "\(params)" & "&encouraging_info=\(getGoalsAndFocusdJsonForBlockedScript())" & "&version=\(appVersion)" & "\(newPageParam)"
    end tell
    """
}

//*******************************************************//





func isBrowserRunning(browserName: String) -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    let lowercaseBrowserName = browserName.lowercased()

    return runningApps.contains { app in
        if let appName = app.localizedName?.lowercased() {
            return appName == lowercaseBrowserName
        }
        return false
    }
}



func getNumberOfOpenTabsPerBrowserInString()->(Int,String){
    var totalTabsCount = 0
    var allBrowsersTabCount = 0
    var title = ""
    
    var keys = safariWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = safariWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nSafari - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = googleChromeWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = googleChromeWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nGoogle Chrome - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = operaWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = operaWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nOpera - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = operaGxWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = operaGxWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nOpera GX - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    
    totalTabsCount = 0
    keys = vivaldiWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = vivaldiWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nVivaldi - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = braveBrowserWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = braveBrowserWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nBrave Browser - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = sidekickWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = sidekickWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nSidekick - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    keys = microsoftEdgeWindowsInfo.keys
    for key in keys{
        if let browserTabsArr = microsoftEdgeWindowsInfo[key]{
            totalTabsCount += browserTabsArr.count
        }
    }
    if totalTabsCount != 0{
        title += "\nMicrosoft Edge - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    
    totalTabsCount = 0
    totalTabsCount = arcBrowserTabsInfo.count
    if totalTabsCount != 0{
        title += "\nArc - \(totalTabsCount)"
        allBrowsersTabCount += totalTabsCount
    }
    return (allBrowsersTabCount, title)
}

let firefoxServer = firefoxHttpServer()// for firefox
