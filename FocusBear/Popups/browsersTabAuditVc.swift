//
//  tabAuditVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class browsersTabAuditVc: NSViewController {

    @IBOutlet weak var lblTitleTabCount: NSTextField!
    @IBOutlet weak var boxTabCount: NSBox!
    @IBOutlet weak var lblCsvFilePath: NSTextField!
    @IBOutlet weak var lblTabCountPerBrowser: NSTextField!
    @IBOutlet weak var btnLastSavedAuditReport: Button!
    @IBOutlet weak var lblLastAuditDate: NSTextField!
    @IBOutlet weak var btnExtractTabURLs: Button!
    @IBOutlet weak var lblSubtile: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Tab Audit"
        lblSubtile.stringValue = "Focus Bear can extract all the open browser tabs you have and put them in a CSV so you can decide if you need them."
        btnExtractTabURLs.title = "Extract tab URLs to CSV"
        btnLastSavedAuditReport.title = "Open saved Tab Audit report"
        lblLastAuditDate.stringValue = "Your last audit was done on: 18 Sep 2025 05:09PM"
        lblTitleTabCount.stringValue = "Number of open tabs:"
        btnLastSavedAuditReport.buttonColor = NSColor.white.cgColor
        self.lblTabCountPerBrowser.stringValue = ""// need to do this
        
        
        
        if let browsersTabAuditVcInfo = configjson.value(forKey: "browsersTabAuditVcInfo") as? NSDictionary{
            lblTitle.stringValue = browsersTabAuditVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubtile.stringValue = browsersTabAuditVcInfo.value(forKey: "subTitle") as? String ?? lblSubtile.stringValue
            lblTitleTabCount.stringValue = browsersTabAuditVcInfo.value(forKey: "titleTabsCount") as? String ?? lblTitleTabCount.stringValue
            btnExtractTabURLs.title = browsersTabAuditVcInfo.value(forKey: "buttonExtractURLs") as? String ?? btnExtractTabURLs.title
            btnLastSavedAuditReport.title = browsersTabAuditVcInfo.value(forKey: "buttonOpenSavedReport") as? String ?? btnLastSavedAuditReport.title
        }
    }
    
    override func viewWillAppear() {
        reloadData()
    }
    
    override func viewWillDisappear() {
        if postBrowsersTabAuditVcObj != nil{
            if postBrowsersTabAuditVcObj?.isViewVisible ?? false{
                postBrowsersTabAuditVcObj?.dismiss(postBrowsersTabAuditVcObj)
            }
        }
    }
    
    func reloadData(){
        if let date = UserDefaults.standard.object(forKey: kUserdefaultsBrowsersTabAuditReportSaveDate) as? Date{
            if FileManager.default.fileExists(atPath: browsersTabAuditCsvURL.path){
                lblLastAuditDate.isHidden = false
                btnLastSavedAuditReport.isHidden = false
                lblCsvFilePath.isHidden = false
                let formatter = DateFormatter()
                formatter.dateFormat = "dd MMM yyyy hh:mma"
                formatter.amSymbol = "AM"
                formatter.pmSymbol = "PM"

                let formattedDate = formatter.string(from: date)
                var lastReportDateText = "Your last audit was done on: <DATE>"
                if let browsersTabAuditVcInfo = configjson.value(forKey: "browsersTabAuditVcInfo") as? NSDictionary{
                    lastReportDateText = browsersTabAuditVcInfo.value(forKey: "lastReportDateText") as? String ?? lastReportDateText
                }
                lblLastAuditDate.stringValue = lastReportDateText.replacingOccurrences(of: "<DATE>", with: formattedDate)
                lblCsvFilePath.stringValue = browsersTabAuditCsvURL.path
            }else{
                lblLastAuditDate.isHidden = true
                btnLastSavedAuditReport.isHidden = true
                lblCsvFilePath.isHidden = true
            }
        }else{
            lblLastAuditDate.isHidden = true
            btnLastSavedAuditReport.isHidden = true
            lblCsvFilePath.isHidden = true
        }
        
        DispatchQueue.global().async {
            var totalTabsCount = 0
            var allBrowsersTabCount = 0
            var title = ""
            let runningApps = NSWorkspace.shared.runningApplications
            var allBrowsersTabUrls = [(title: String, url: String)]()
            for app in runningApps{
                if let appUrl = app.bundleURL{
                    let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                    
                    if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                        if let allTabUrls = getBrowserAllTabUrlAndTitle(browser: browser){
                            allBrowsersTabUrls += allTabUrls
                            print(allTabUrls)
                            totalTabsCount = allTabUrls.count
                            allBrowsersTabCount += allTabUrls.count
                            switch browser{
                                
                            case ._GOOGLE_CHROME_:
                                title += "Google Chrome - \(totalTabsCount)\n"
                            case ._SAFARI_:
                                title += "Safari - \(totalTabsCount)\n"
                            case ._BRAVE_BROWSER_:
                                title += "Brave Browser - \(totalTabsCount)\n"
                            case ._SIDEKICK_:
                                title += "Sidekick - \(totalTabsCount)\n"
                            case ._MICROSOFT_EDGE_:
                                title += "Microsoft Edge - \(totalTabsCount)\n"
                            case ._ARC_:
                                title += "Arc - \(totalTabsCount)\n"
                            case ._FIREFOX_:
                                title += "Firefox - \(totalTabsCount)\n"
                            case ._OPERA_:
                                title += "Opera - \(totalTabsCount)\n"
                            case ._VIVALDI_:
                                title += "Vivaldi - \(totalTabsCount)\n"
                            case ._OPERA_GX_:
                                title += "Opera GX - \(totalTabsCount)\n"
                            case ._SIGMA_OS_:
                                title += "SigmaOS - \(totalTabsCount)\n"
                            }
                            
                        }
                    }
                }
            }

            DispatchQueue.main.async {
                if allBrowsersTabCount == 0{
                    self.boxTabCount.isHidden = true
                }else{
                    self.boxTabCount.isHidden = false
                    self.lblTabCountPerBrowser.stringValue = title
                }
            }
        }
    }

    @IBAction func btnExtractTabURLsClicked(_ sender: Any) {
        let runningApps = NSWorkspace.shared.runningApplications
        var allBrowsersTabUrls = [(title: String, url: String)]()
        for app in runningApps{
            if let appUrl = app.bundleURL{
                let nameLowercased = appUrl.deletingPathExtension().lastPathComponent.lowercased()
                
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    if let allTabUrls = getBrowserAllTabUrlAndTitle(browser: browser){
                        allBrowsersTabUrls += allTabUrls
                        print(allTabUrls)
                        
                    }
                }
            }
        }
        print(allBrowsersTabUrls)
        UserDefaults.standard.set(Date(), forKey: kUserdefaultsBrowsersTabAuditReportSaveDate)
        saveBrowsersTabAuditCsv(arrTabs: allBrowsersTabUrls)
        openCsvFile(at: browsersTabAuditCsvURL.path)
        reloadData()
        self.presentAsSheet(getPostBrowsersTabAuditVcObject())
    }
    
    @IBAction func btnLastSavedAuditReportClicked(_ sender: Any) {
        openCsvFile(at: browsersTabAuditCsvURL.path)
    }
    
    func openCsvFile(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(fileURL)
    }
}
