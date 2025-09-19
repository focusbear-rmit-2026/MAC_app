//
//  alertMaxTabLimitVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class alertMaxTabLimitVc: NSViewController {

    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Max tab count (\(SettingsManagerObject.maxTabLimitCount)) exceeded."
        btnOk.title = buttonOkText
    }
    override func viewWillAppear() {
        resetView()
    }
    func resetView(){
        var title = "Max tab count (<COUNT>) exceeded."
        if let alertMaxTabLimitVcInfo = configjson.value(forKey: "alertMaxTabLimitVcInfo") as? NSDictionary{
            title = alertMaxTabLimitVcInfo.value(forKey: "title") as? String ?? title
        }
        title = title.replacingOccurrences(of: "<COUNT>", with: "\(SettingsManagerObject.maxTabLimitCount)")
        
        var totalTabsCount = 0
        
        var titleTabsCount = "Number of open tabs:"
        if let alertMaxTabLimitVcInfo = configjson.value(forKey: "alertMaxTabLimitVcInfo") as? NSDictionary{
            titleTabsCount = alertMaxTabLimitVcInfo.value(forKey: "titleTabsCount") as? String ?? titleTabsCount
        }
        
        
        title += "\n\n\(titleTabsCount)\n"
//        
//        var keys = safariWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = safariWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nSafari - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = googleChromeWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = googleChromeWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nGoogle Chrome - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = operaWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = operaWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nOpera - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = operaGxWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = operaGxWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nOpera GX - \(totalTabsCount)"
//        }
//        
//        
//        totalTabsCount = 0
//        keys = vivaldiWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = vivaldiWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nVivaldi - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = braveBrowserWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = braveBrowserWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nBrave Browser - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = sidekickWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = sidekickWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nSidekick - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        keys = microsoftEdgeWindowsInfo.keys
//        for key in keys{
//            if let browserTabsArr = microsoftEdgeWindowsInfo[key]{
//                totalTabsCount += browserTabsArr.count
//            }
//        }
//        if totalTabsCount != 0{
//            title += "\nMicrosoft Edge - \(totalTabsCount)"
//        }
//        
//        totalTabsCount = 0
//        totalTabsCount = arcBrowserTabsInfo.count
//        if totalTabsCount != 0{
//            title += "\nArc - \(totalTabsCount)"
//        }
//        
        let (allBrowsersTabCount, numberOfOpenTabsPerBrowserInString) = getNumberOfOpenTabsPerBrowserInString()
        
        lblTitle.stringValue = title + numberOfOpenTabsPerBrowserInString
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()
    }
}
