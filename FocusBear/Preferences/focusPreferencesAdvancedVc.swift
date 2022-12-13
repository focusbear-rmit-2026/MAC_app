//
//  focusPreferencesAdvancedVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 01/06/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa
import TrueTime


class focusPreferencesAdvancedVc: NSViewController {
    
    @IBOutlet weak var checkBoxAutoDoNotDisturb: NSButton!
    @IBOutlet weak var lineHorizontal: NSBox!
    @IBOutlet weak var boxTableView: NSBox!
    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lblInstruction: NSTextField!
    @IBOutlet weak var btnAddUrl: NSButton!
    @IBOutlet weak var btnRemoveUrl: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var tblView: NSTableView!
    @IBOutlet weak var lblUrlCurrentApplescriptAfter: NSTextField!
    @IBOutlet weak var lblUrlCurrentApplescriptBefore: NSTextField!
    @IBOutlet weak var lblTitleCurrentApplescriptAfter: NSTextField!
    @IBOutlet weak var lblTitleCurrentApplescriptBefore: NSTextField!
    @IBOutlet weak var checkBoxRunScriptAfterFocus: NSButton!
    @IBOutlet weak var checkBoxRunScriptBeforeFocus: NSButton!
    @IBOutlet weak var btnSelectAppleScriptBeforeFocus: NSButton!
    @IBOutlet weak var btnSelectAppleScriptAfterFocus: NSButton!
    @IBOutlet weak var btnOk: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        checkBoxAutoDoNotDisturb.title = "Turn on Do Not Disturb automatically when starting a focus mode."
        lblInstruction.stringValue = "The URLs here will be blocked during this focus mode. Useful if you want to allow some websites but block others. For example, you could have *.google.com as an allowed URL but block games.google.com"
        var runScriptBeforeText = "Run apple script before starting focus mode."
        var runScriptAfterText = "Run apple script after starting focus mode."
        var titleCurrentAppleScript = "Current Apple script:"
        var buttonSelectScriptText = "Select Apple script"
        var titleBlockedUrls = "Blocked URLs"
        
        var toolTipAdd = "Add"
        var toolTipRemove = "Remove"
        
        
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            runScriptBeforeText = focusPreferencesAdvancedInfo.value(forKey: "runScriptBeforeText") as? String ?? runScriptBeforeText
            runScriptAfterText = focusPreferencesAdvancedInfo.value(forKey: "runScriptAfterText") as? String ?? runScriptAfterText
            titleCurrentAppleScript = focusPreferencesAdvancedInfo.value(forKey: "titleCurrentAppleScript") as? String ?? titleCurrentAppleScript
            buttonSelectScriptText = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectScriptText") as? String ?? buttonSelectScriptText
            titleBlockedUrls = focusPreferencesAdvancedInfo.value(forKey: "titleBlockedUrls") as? String ?? titleBlockedUrls

            toolTipAdd = focusPreferencesAdvancedInfo.value(forKey: "toolTipAdd") as? String ?? toolTipAdd
            toolTipRemove = focusPreferencesAdvancedInfo.value(forKey: "toolTipRemove") as? String ?? toolTipRemove
            lblInstruction.stringValue = focusPreferencesAdvancedInfo.value(forKey: "instructionText") as? String ?? lblInstruction.stringValue
            
            checkBoxAutoDoNotDisturb.title = focusPreferencesAdvancedInfo.value(forKey: "autoOnDoNotDisturbText") as? String ?? checkBoxAutoDoNotDisturb.title
        }
        
        checkBoxRunScriptBeforeFocus.title = runScriptBeforeText
        lblTitleCurrentApplescriptBefore.stringValue = titleCurrentAppleScript
        btnSelectAppleScriptBeforeFocus.title = buttonSelectScriptText
        
        checkBoxRunScriptAfterFocus.title = runScriptAfterText
        lblTitleCurrentApplescriptAfter.stringValue = titleCurrentAppleScript
        btnSelectAppleScriptAfterFocus.title = buttonSelectScriptText
        
        lblTitle.stringValue = titleBlockedUrls
        btnOk.title = buttonOkText
        tblView.doubleAction = #selector(tableRowBlockedUrlsDoubleClicked)
        
        
        
        btnAddUrl.toolTip = toolTipAdd
        btnRemoveUrl.toolTip = toolTipRemove
        
        
    }
    override func viewWillAppear() {
        
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                self.view.window?.sharingType = .none
            }else{
                self.view.window?.sharingType = .readOnly
            }
        }
        
        tblView.reloadData()
        
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if row != -1{
            if let val = arrFocusType[row]["isScriptBeforeFocusEnabled"] as? Bool{
                if val{
                    checkBoxRunScriptBeforeFocus.state = .on
                }else{
                    checkBoxRunScriptBeforeFocus.state = .off
                }
            }else{
                checkBoxRunScriptBeforeFocus.state = .off
            }
            
            if let val = arrFocusType[row]["isScriptAfterFocusEnabled"] as? Bool{
                if val{
                    checkBoxRunScriptAfterFocus.state = .on
                }else{
                    checkBoxRunScriptAfterFocus.state = .off
                }
            }else{
                checkBoxRunScriptAfterFocus.state = .off
            }
            
            if checkBoxRunScriptBeforeFocus.state == .on{
                btnSelectAppleScriptBeforeFocus.isEnabled = true
            }else{
                btnSelectAppleScriptBeforeFocus.isEnabled = false
            }
            if checkBoxRunScriptAfterFocus.state == .on{
                btnSelectAppleScriptAfterFocus.isEnabled = true
            }else{
                btnSelectAppleScriptAfterFocus.isEnabled = false
            }
            
            
            if let val = arrFocusType[row]["scriptPathBeforeFocus"] as? String{
                lblUrlCurrentApplescriptBefore.stringValue = val
            }else{
                lblUrlCurrentApplescriptBefore.stringValue = "Please select a apple script."
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    lblUrlCurrentApplescriptBefore.stringValue = focusPreferencesAdvancedInfo.value(forKey: "pleaseSelectScriptText") as? String ?? lblUrlCurrentApplescriptBefore.stringValue
                }
                    
            }
            
            if let val = arrFocusType[row]["scriptPathAfterFocus"] as? String{
                lblUrlCurrentApplescriptAfter.stringValue = val
            }else{
                lblUrlCurrentApplescriptAfter.stringValue = "Please select a apple script."
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    lblUrlCurrentApplescriptAfter.stringValue = focusPreferencesAdvancedInfo.value(forKey: "pleaseSelectScriptText") as? String ?? lblUrlCurrentApplescriptAfter.stringValue
                }
            }
          
            if bottomConstraint != nil{
                NSLayoutConstraint.deactivate([bottomConstraint!])
                bottomConstraint = nil
            }
            
            
            if let isAllowedListApproach = arrFocusType[row]["isAllowedListApproach"] as? Bool{
                if isAllowedListApproach{
                    bottomConstraint = NSLayoutConstraint(item: btnOk!, attribute: .top, relatedBy: .equal, toItem: boxTableView, attribute: .bottom, multiplier: 1, constant: 14)
                    NSLayoutConstraint.activate([bottomConstraint!])
                    lblTitle.isHidden = false
                    lineHorizontal.isHidden = false
                }else{
                    bottomConstraint = NSLayoutConstraint(item: btnOk!, attribute: .top, relatedBy: .equal, toItem: checkBoxAutoDoNotDisturb, attribute: .bottom, multiplier: 1, constant: 14)
                    NSLayoutConstraint.activate([bottomConstraint!])
                    lblTitle.isHidden = true
                    lineHorizontal.isHidden = true
                }
            }
           
            
            if let val = arrFocusType[row]["isAutoDoNotDisturbEnabled"] as? Bool{
                if val{
                    checkBoxAutoDoNotDisturb.state = .on
                }else{
                    checkBoxAutoDoNotDisturb.state = .off
                }
            }else{
                checkBoxAutoDoNotDisturb.state = .off
            }
            
        }
        
//        btnOk
        
        
        //
    }
    var bottomConstraint: NSLayoutConstraint?
    @objc func tableRowBlockedUrlsDoubleClicked(){
        let selectedTow = tblView.selectedRow
        if selectedTow == -1{
            return;
        }
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
        addWebUrlVcObj!.isAdding = false
        self.presentAsSheet(addWebUrlVcObj!)
    }
    @IBAction func checkBoxRunScriptBeforeFocusClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunScriptBeforeFocus.state == .on{
            arrFocusType[row]["isScriptBeforeFocusEnabled"] = true
            btnSelectAppleScriptBeforeFocus.isEnabled = true
        }else{
            arrFocusType[row]["isScriptBeforeFocusEnabled"] = false
            btnSelectAppleScriptBeforeFocus.isEnabled = false
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
    }
    
    @IBAction func checkBoxRunScriptAfterFocusClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunScriptAfterFocus.state == .on{
            arrFocusType[row]["isScriptAfterFocusEnabled"] = true
            btnSelectAppleScriptAfterFocus.isEnabled = true
        }else{
            arrFocusType[row]["isScriptAfterFocusEnabled"] = false
            btnSelectAppleScriptAfterFocus.isEnabled = false
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
    }
    @IBAction func btnSelectAppleScriptBeforeClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.message = "Please select a script file"
        dialog.prompt = "Select"
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            dialog.message = focusPreferencesAdvancedInfo.value(forKey: "selectScriptFileText") as? String ?? dialog.message
            dialog.prompt = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectText") as? String ?? dialog.prompt
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                dialog.sharingType = .none
            }
        }
        dialog.allowedFileTypes = ["scpt"]
        dialog.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if modalResponse.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = dialog.url {
                    arrFocusType[row]["scriptPathBeforeFocus"] = url.path
                    self.lblUrlCurrentApplescriptBefore.stringValue = url.path
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                        DispatchQueue.main.async {

                        }
                    })
                    allApiObject.capturePosthog(event: "set-apple-script-before-starting-focus-mode", metadata: [:])
                }
            }
        })
    }
    
    @IBAction func btnSelectAppleScriptAfterClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        let dialog = NSOpenPanel()
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.message = "Please select a script file"
        dialog.prompt = "Select"
        if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
            dialog.message = focusPreferencesAdvancedInfo.value(forKey: "selectScriptFileText") as? String ?? dialog.message
            dialog.prompt = focusPreferencesAdvancedInfo.value(forKey: "buttonSelectText") as? String ?? dialog.prompt
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                dialog.sharingType = .none
            }
        }
        dialog.allowedFileTypes = ["scpt"]
        dialog.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if modalResponse.rawValue == NSApplication.ModalResponse.OK.rawValue {
                if let url = dialog.url {
                    arrFocusType[row]["scriptPathAfterFocus"] = url.path
                    self.lblUrlCurrentApplescriptAfter.stringValue = url.path
                    UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                    allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                        DispatchQueue.main.async {

                        }
                    })
                    allApiObject.capturePosthog(event: "set-apple-script-after-completing-focus-mode", metadata: [:])
                }
            }
        })
    }

    @IBAction func btnAddUrlClicked(_ sender: Any) {
        addWebUrlVcObj!.currenUrlAddingtState = ._FOCUS_BLOCK_URL
        addWebUrlVcObj!.isAdding = true
        self.presentAsSheet(addWebUrlVcObj!)
    }
    
    @IBAction func btnRemoveUrlClicked(_ sender: Any) {
        let selectedFocusTypeRow = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if selectedFocusTypeRow == -1{
            return
        }
        
        let selectedUrlsRow = tblView.selectedRow
        if selectedUrlsRow == -1{
            return
        }
        
        if arrFocusType.count > selectedFocusTypeRow{

            if var arr = arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] as? [String]{
                if arr.count > selectedUrlsRow{
                    arr.remove(at: selectedUrlsRow)
                }
                arrFocusType[selectedFocusTypeRow]["blockUrlsArray"] = arr
            }
            self.tblView.reloadData()
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: arrFocusType[selectedFocusTypeRow], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
        if arrFocusType[selectedFocusTypeRow]["isOn"] as? Bool == true{
            appdelegate!.fillAllowUrlArray()
        }
        
        
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        self.dismiss(self)
    }
    @IBAction func checkBoxAutoDoNotDisturbClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxAutoDoNotDisturb.state == .on{
            
            if !isAccessibilityEnabled(isPrompt: false){
                let alert = NSAlert()
                alert.setSharingType()
                alert.messageText = "To turn on Do Not Disturb when starting a Focus Mode, Focus Bear needs Accessibility permissions. Would you like to give the permissions now?"
                if let focusPreferencesAdvancedInfo = configjson.value(forKey: "focusPreferencesAdvancedInfo") as? NSDictionary{
                    alert.messageText = focusPreferencesAdvancedInfo.value(forKey: "needDndPermissionText") as? String ?? alert.messageText
                }
                alert.addButton(withTitle: buttonOkText)
                alert.addButton(withTitle: buttonCancelText)
                alert.beginSheetModal(for: self.view.window!, completionHandler: { response in
                    if response == .alertFirstButtonReturn{
                        _ = isAccessibilityEnabled(isPrompt: true)
                        arrFocusType[row]["isAutoDoNotDisturbEnabled"] = true
                        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                        
                        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                            DispatchQueue.main.async {

                            }
                        })
                        preferencesWindowControllerObj!.window!.setFrameOrigin(NSPoint(x: 0, y: 0))
                    }else{
                        self.checkBoxAutoDoNotDisturb.state = .off
                    }
                })
                
            }else{
                arrFocusType[row]["isAutoDoNotDisturbEnabled"] = true
                UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
                
                allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                    DispatchQueue.main.async {

                    }
                })
            }
            
        }else{
            arrFocusType[row]["isAutoDoNotDisturbEnabled"] = false
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            
            allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                DispatchQueue.main.async {

                }
            })
        }
        
    }
    
}
extension focusPreferencesAdvancedVc: NSTableViewDelegate, NSTableViewDataSource{
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        if arrFocusType.count == 0{
            return 0
        }else {
            let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
            if row != -1{
                if let arr = arrFocusType[row]["blockUrlsArray"] as? [String]{
                    btnRemoveUrl.isEnabled = false
                    return arr.count
                }
            }
            
        }
        return 0
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "tblCellFocusPreferences"), owner: nil) as? tblCellFocusPreferences {
            
            
            if let arr = arrFocusType[focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0]["blockUrlsArray"] as? [String]{
                //                        let url = URL(fileURLWithPath: arr[row])
                if row < arr.count{
                    cell.lblTitle.stringValue = arr[row]
                    cell.imgView.image = NSImage(named: NSImage.networkName)
                }else{
                    cell.lblTitle.stringValue = ""
                    cell.imgView.image = nil
                }
            }
            
            return cell
        }
        
        return NSTableCellView()
    }
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {

//    }
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard let tblview = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tblview.selectedRow
    
        if tblview == tblView{
            if selectedRow == -1{
                btnRemoveUrl.isEnabled = false
            }else{
                btnRemoveUrl.isEnabled = true
            }
        }
    }
    

}
