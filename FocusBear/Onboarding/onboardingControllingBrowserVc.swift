//
//  onboardingControllingBrowserVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingControllingBrowserVc: NSViewController {

    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var checkPermissionTimer:Timer?
    var arrBrowsers = [[String:Any]]()
    
    var buttonRequestPermissionText = "Request Permission"
    var enabledText = "✅  Enabled!"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.//
        
        lblTitle.stringValue = "Controlling Your Browser"//"Controlando tu navegador"
        lblDescription.stringValue = "Alright, now you need to give Focus Bear permission to block distraction. Open your browser and you'll see a popup seeking permission. Click OK in the popup that shows."//
        btnContinue.title = "Permission Granted"
        btnContinue.isEnabled = false
        
        
//        var safariText = "Enable to capture website URLs in Safari to block or allow URLs[NEEDSTRANSLATION]"
//        var googleChromeText = "Enable to capture website URLs in Google Chrome to block or allow URLs[NEEDSTRANSLATION]"
//        var sidekickText = "Enable to capture website URLs in Sidekick to block or allow URLs[NEEDSTRANSLATION]"
//        var braveBrowserText = "Enable to capture website URLs in Brave Browser to block or allow URLs[NEEDSTRANSLATION]"
//        var microsoftEdgeText = "Enable to capture website URLs in Microsoft Edge to block or allow URLs[NEEDSTRANSLATION]"
        
        
        if let dic = configjson.value(forKey: "onboardingControllingBrowserVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "descriptionText") as? String ?? lblDescription.stringValue
            btnContinue.title = dic.value(forKey: "buttonPermissionGrantedText") as? String ?? btnContinue.title
            
//            safariText = dic.value(forKey: "safariText") as? String ?? safariText
//            googleChromeText = dic.value(forKey: "googleChromeText") as? String ?? googleChromeText
//            sidekickText = dic.value(forKey: "sidekickText") as? String ?? sidekickText
//            braveBrowserText = dic.value(forKey: "braveBrowserText") as? String ?? braveBrowserText
//            microsoftEdgeText = dic.value(forKey: "microsoftEdgeText") as? String ?? microsoftEdgeText
            
            buttonRequestPermissionText = dic.value(forKey: "buttonRequestPermissionText") as? String ?? buttonRequestPermissionText
            enabledText = dic.value(forKey: "enabledText") as? String ?? enabledText
        }
        
        
        
        let filemanager = FileManager.default
        
        if filemanager.fileExists(atPath: "/Applications/Safari.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
            arrBrowsers.append(["name": "Safari", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SAFARI_])
        }

        if filemanager.fileExists(atPath: "/Applications/Google Chrome.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Google Chrome.app")
            arrBrowsers.append(["name": "Google Chrome", "image": fileIcon, "isEnabled": false, "browser":BROWSER._GOOGLE_CHROME_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Sidekick.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Sidekick.app")
            arrBrowsers.append(["name": "Sidekick", "image": fileIcon, "isEnabled": false, "browser":BROWSER._SIDEKICK_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Brave Browser.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Brave Browser.app")
            arrBrowsers.append(["name": "Brave Browser", "image": fileIcon, "isEnabled": false, "browser":BROWSER._BRAVE_BROWSER_])
        }
        
        if filemanager.fileExists(atPath: "/Applications/Microsoft Edge.app"){
            let fileIcon = NSWorkspace.shared.icon(forFile: "/Applications/Microsoft Edge.app")
            arrBrowsers.append(["name": "Microsoft Edge", "image": fileIcon, "isEnabled": false, "browser":BROWSER._MICROSOFT_EDGE_])
        }

        checkPermission()
        
        allApiObject.capturePosthog(event: "permission-to-block-distractions-shown", metadata: [:])
    }
    
    override func viewWillAppear() {
        DispatchQueue.global().sync {
            if self.checkPermissionTimer != nil{
                self.checkPermissionTimer?.invalidate()
                self.checkPermissionTimer = nil
            }
            self.checkPermissionTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(self.checkPermission), userInfo: nil, repeats: true)

            RunLoop.main.add((checkPermissionTimer!), forMode: RunLoop.Mode.common)
        }
    }
    
    override func viewWillDisappear() {
        checkPermissionTimer?.invalidate()
    }
    
    @objc func checkPermission(){
        let runningApps = NSWorkspace.shared.runningApplications
        for runningApp in runningApps{
            if let name = runningApp.localizedName{
                let nameLowercased = name.lowercased()
                if let browser = getCurrentBrowserFrom(browserName: nameLowercased){
                    for i in 0..<arrBrowsers.count{
                        if arrBrowsers[i]["browser"] as? BROWSER == browser{
                            let state = arrBrowsers[i]["isEnabled"] as? Bool ?? false
                            if !state{
                                if getActiveTabUrlOf(browser: browser) != nil{
                                    DispatchQueue.main.async {
                                        self.btnContinue.isEnabled = true
                                        self.arrBrowsers[i]["isEnabled"] = true
                                        self.tblView.reloadData()
                                    }
                                    
                                }
                            }
                            
                            break;
                        }
                    }
                    
                    
                }
            }
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        self.view.window?.contentViewController = getTryBlockUrlVcObject()
    }
}

extension onboardingControllingBrowserVc:NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return arrBrowsers.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellBrowsers"), owner: nil) as? tblCellBrowsers {
            
            cell.lblTitle.stringValue = arrBrowsers[row]["name"] as? String ?? ""
//            cell.lblDescription.stringValue = arrBrowsers[row]["description"] as? String ?? ""
            cell.imgView.image = arrBrowsers[row]["image"] as? NSImage
            
            let state = arrBrowsers[row]["isEnabled"] as? Bool ?? false
            if state{
                cell.lblState.isHidden = false
                cell.btnRequest.isHidden = true
            }else{
                cell.lblState.isHidden = true
                cell.btnRequest.isHidden = false
            }
            
            cell.btnRequest.title = buttonRequestPermissionText
            cell.lblState.stringValue = enabledText
            
            cell.btnRequest.target = self
            cell.btnRequest.tag = row
            cell.btnRequest.action = #selector(btnRequestClicked(sender:))
            
            return cell
        }
        
        return NSTableCellView()
    }
    
    @objc func btnRequestClicked(sender:NSButton){
        if let browser = arrBrowsers[sender.tag]["browser"] as? BROWSER{
            if getActiveTabUrlOf(browser: browser) != nil{
                DispatchQueue.main.async {
                    self.btnContinue.isEnabled = true
                    self.arrBrowsers[sender.tag]["isEnabled"] = true
                    self.tblView.reloadData()
                }
            }
        }
        
    }
}

