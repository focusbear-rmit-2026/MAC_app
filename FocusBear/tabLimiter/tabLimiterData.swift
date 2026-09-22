//
//  File.swift
//  FocusBear
//
//  Created by Manish Jain on 25/11/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

var safariWindowsInfo = [String:[String]]()
var googleChromeWindowsInfo = [String:[String]]()
var operaWindowsInfo = [String:[String]]()
var vivaldiWindowsInfo = [String:[String]]()
var braveBrowserWindowsInfo = [String:[String]]()
var sidekickWindowsInfo = [String:[String]]()
var microsoftEdgeWindowsInfo = [String:[String]]()
var arcBrowserTabsInfo = [String]()
var operaGxWindowsInfo = [String:[String]]()
var cometWindowsInfo = [String:[String]]()

enum BrowserTabLimitDecision: Equatable {
    case allow, warnExisting, rejectNew

    static func evaluate(previous: Int, current: Int, otherBrowsers: Int, limit: Int) -> Self {
        guard current + max(0, otherBrowsers) > max(1, limit) else { return .allow }
        // A first snapshot cannot identify a newly opened tab: warn without deleting existing work.
        return previous > 0 && current > previous ? .rejectNew : .warnExisting
    }
}

private func cachedTabWindows(_ browser: BROWSER) -> [String: [String]] {
    switch browser {
    case ._SAFARI_: return safariWindowsInfo
    case ._GOOGLE_CHROME_: return googleChromeWindowsInfo
    case ._OPERA_: return operaWindowsInfo
    case ._VIVALDI_: return vivaldiWindowsInfo
    case ._BRAVE_BROWSER_: return braveBrowserWindowsInfo
    case ._SIDEKICK_: return sidekickWindowsInfo
    case ._MICROSOFT_EDGE_: return microsoftEdgeWindowsInfo
    case ._ARC_: return ["window": arcBrowserTabsInfo]
    case ._OPERA_GX_: return operaGxWindowsInfo
    case ._COMET_: return cometWindowsInfo
    default: return [:]
    }
}

private var lastTabLimitSnapshot: [BROWSER: String] = [:]

func checkIsCurrentTabAllowed(currentBrowser:BROWSER)->Bool{
    if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
        return true
    }
    if !SettingsManagerObject.isTabLimiterEnabled{
        return true
    }
    if currentBrowser == ._FIREFOX_ || currentBrowser == ._SIGMA_OS_{
        return true
    }
    
    guard let browserStruct = getBrowserAllWindowStructSafeInBackground(browser: currentBrowser) else {
        if lastTabLimitSnapshot[currentBrowser] != "unavailable" {
            addLog(text: "tab limiter: browser=\(currentBrowser) snapshot unavailable")
            lastTabLimitSnapshot[currentBrowser] = "unavailable"
        }
        return true
    }
    let previousCount = cachedTabWindows(currentBrowser).values.reduce(0) { $0 + $1.count }
    let currentCount = browserStruct.values.reduce(0) { $0 + $1.count }
    let otherCount = max(0, getAllBrowsersTabCount() - previousCount)
    let decision = BrowserTabLimitDecision.evaluate(previous: previousCount, current: currentCount,
        otherBrowsers: otherCount, limit: SettingsManagerObject.maxTabLimitCount)
    let snapshot = "current=\(currentCount) other=\(otherCount) limit=\(SettingsManagerObject.maxTabLimitCount) decision=\(decision)"
    if lastTabLimitSnapshot[currentBrowser] != snapshot {
        addLog(text: "tab limiter: browser=\(currentBrowser) \(snapshot)")
        lastTabLimitSnapshot[currentBrowser] = snapshot
        if decision == .warnExisting { showAlertMaxTabLimitWindow() }
    }
    if currentBrowser == ._SAFARI_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._GOOGLE_CHROME_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._OPERA_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._OPERA_GX_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._VIVALDI_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._BRAVE_BROWSER_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._SIDEKICK_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._MICROSOFT_EDGE_{
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
            if decision == .rejectNew{
                
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
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
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
    }else if currentBrowser == ._ARC_{
        let currentBrowserTabsArr = browserStruct["window"] ?? []
        let allSelfTabArr = arcBrowserTabsInfo
        
        
        if allSelfTabArr.count == currentBrowserTabsArr.count{
            arcBrowserTabsInfo = currentBrowserTabsArr
        }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
            if decision == .rejectNew{
                
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
    }else if currentBrowser == ._COMET_{
        // Comet is Chromium-based, so it exposes the same windows/tabs AppleScript model as
        // Chrome/Brave/Edge — mirror that branch exactly, keyed on cometWindowsInfo.
        var currentBrowserTabsArr = [String]()
        var allSelfTabArr = [String]()
        
        var keys = browserStruct.keys
        for key in keys{
            if let tabsArr = browserStruct[key]{
                currentBrowserTabsArr += tabsArr
            }
        }
        keys = cometWindowsInfo.keys
        for key in keys{
            if let tabsArr = cometWindowsInfo[key]{
                allSelfTabArr += tabsArr
            }
        }
        if allSelfTabArr.count == currentBrowserTabsArr.count{
            cometWindowsInfo = browserStruct
        }else if currentBrowserTabsArr.count > allSelfTabArr.count{// new tab created
            if decision == .rejectNew{
                
                let keys = browserStruct.keys
                for key in keys{
                    if let browserTabsArr = browserStruct[key]{
                        if let selfTabArr = cometWindowsInfo[key]{
                            if selfTabArr.count == browserTabsArr.count{
                                cometWindowsInfo[key] = browserTabsArr
                            }else if browserTabsArr.count > selfTabArr.count{// new tab created
                                
                                for i in 0..<browserTabsArr.count{
                                    if i < selfTabArr.count{
                                        if browserTabsArr[i] != selfTabArr[i]{
                                            closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                            break;
                                        }
                                    }else{
                                        closeTabAt(index: i, browser: currentBrowser, windowID: key)
                                        break;
                                    }
                                }
                                showAlertMaxTabLimitWindow()
                                return false
                                
                            }
                        }else{//new window created
                            closeTabAt(index: 0, browser: currentBrowser, windowID: key)
                            showAlertMaxTabLimitWindow()
                            return false
                        }
                    }
                }
                
                
            }else{
                cometWindowsInfo = browserStruct
            }
        }else{
            cometWindowsInfo = browserStruct
        }
    }
    return true
}

func getBrowserAllWindowStructSafeInBackground(browser: BROWSER) -> [String : [String]]? {
    // Call directly on the caller's (background) thread — runAppleScriptSafely already runs the script
    // off the main thread. The old DispatchQueue.main bounce forced the blocking browser AppleScript
    // onto the main thread (UI freeze / AppHang / blank Day Plan).
    return getBrowserAllWindowStruct(browser: browser)
}
