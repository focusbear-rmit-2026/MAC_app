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
        return true ;
    }
    if currentBrowser == ._SAFARI_{
//        if safariWindowsInfo.keys.count == 0{
//            safariWindowsInfo = browserStruct
//        }else{
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
//        }
    }else if currentBrowser == ._GOOGLE_CHROME_{
      ///  if googleChromeWindowsInfo.keys.count == 0{
           // googleChromeWindowsInfo = browserStruct
       // }else{
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
       // }
    }else if currentBrowser == ._OPERA_{
       // if operaWindowsInfo.keys.count == 0{
        //    operaWindowsInfo = browserStruct
       // }else{
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
       // }
    }else if currentBrowser == ._OPERA_GX_{
        //if operaGxWindowsInfo.keys.count == 0{
         //   operaGxWindowsInfo = browserStruct
        //}else{
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
       // }
    }else if currentBrowser == ._VIVALDI_{
//        if vivaldiWindowsInfo.keys.count == 0{
//            vivaldiWindowsInfo = browserStruct
//        }else{
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
       // }
    }else if currentBrowser == ._BRAVE_BROWSER_{
//        if braveBrowserWindowsInfo.keys.count == 0{
//            braveBrowserWindowsInfo = browserStruct
//        }else{
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
//        }
    }else if currentBrowser == ._SIDEKICK_{
//        if sidekickWindowsInfo.keys.count == 0{
//            sidekickWindowsInfo = browserStruct
//        }else{
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
//        }
    }else if currentBrowser == ._MICROSOFT_EDGE_{
//        if microsoftEdgeWindowsInfo.keys.count == 0{
//            microsoftEdgeWindowsInfo = browserStruct
//        }else{
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
//        }
    }else if currentBrowser == ._ARC_{
//        if arcBrowserTabsInfo.count == 0{
//            if let allTabs = browserStruct["window"]{
//                arcBrowserTabsInfo = allTabs
//            }
//        }else{
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
//        }
    }
    return true
}

func getBrowserAllWindowStructSafeInBackground(browser: BROWSER) -> [String : [String]]? {
    // Call directly on the caller's (background) thread — runAppleScriptSafely already runs the script
    // off the main thread. The old DispatchQueue.main bounce forced the blocking browser AppleScript
    // onto the main thread (UI freeze / AppHang / blank Day Plan).
    return getBrowserAllWindowStruct(browser: browser)
}
