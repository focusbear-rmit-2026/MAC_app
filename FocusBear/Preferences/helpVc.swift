//
//  helpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class helpVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnExportLogs: underLineButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Focus Bear is still a new app and you might encounter issues (or have great ideas on how to make it better). We'd really appreciate your feedback. You can email us at team@focusbear.io. Screenshots are really helpful to let us understand the problem. Also if you had a problem, please export your logs (use the link below) and attach it to the email."
        btnExportLogs.title = "Click here to export logs to share with Support Team."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            btnExportLogs.title = preferencesInfo.value(forKey: "buttonExportLogsText") as? String ?? btnExportLogs.title
            lblTitle.stringValue = preferencesInfo.value(forKey: "helpText") as? String ?? lblTitle.stringValue
        }
    }
    @IBAction func btnExportLogsClicked(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.treatsFilePackagesAsDirectories = false
        openPanel.prompt = "Export Logs"
        openPanel.message = "Export logs to share with Focus Bear Support Team"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            openPanel.prompt = preferencesInfo.value(forKey: "buttonPanelExportLogsText") as? String ?? openPanel.prompt
            openPanel.message = preferencesInfo.value(forKey: "panelExportLogsText") as? String ?? openPanel.message
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                openPanel.sharingType = .none
            }
        }
    
        
        openPanel.beginSheetModal(for: self.view.window!) { response in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                return
            }
            if let url = openPanel.url {
                let filemanager = FileManager.default
                let destUrl = url.appendingPathComponent("FocusBearLogs.zip")
                if filemanager.fileExists(atPath: destUrl.path){
                    do{
                        try filemanager.removeItem(at: destUrl)
                    }catch{
                        print(error)
                    }
                }
                //FocusBearLogs.zip

     
                do{
                    _ = try DebugLogsFolderURL!.zip(dest: destUrl)
                }catch{
                    
                }
                
                
                var successText = "Your logs are available to share in the FocusBearLogs.zip file in the <URL> directory"
                if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                    successText = preferencesInfo.value(forKey: "exportSuccessText") as? String ?? successText
                }
                
                successText = successText.replacingOccurrences(of: "<URL>", with: url.path)
                
                self.showAlert(msg: successText, completionHandler: {_ in
                    NSWorkspace.shared.activateFileViewerSelecting([destUrl])
                })
                
                allApiObject.capturePosthog(event: "export-logs", metadata: [:])
                
            }
        }
    }
    func showAlert(msg:String, completionHandler: @escaping(_ result: Bool) -> ()) {
        let alertWarning = NSAlert()
        alertWarning.setSharingType()
        alertWarning.messageText = msg
        alertWarning.addButton(withTitle: buttonOkText)
        alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in

            completionHandler(true)
            return
        })
    }
    
}
