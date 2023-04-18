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
    
    @IBOutlet weak var checkBoxRunShellAfterFocus: NSButton!
    @IBOutlet weak var checkBoxRunShellBeforeFocus: NSButton!
    
    @IBOutlet var textViewRunShelltBeforeFocus: NSTextView!
    @IBOutlet var textViewRunShelltAfterFocus: NSTextView!
    
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
    
    var isShellScriptBeforeFocusEdited = false
    var isShellScriptAfterFocusEdited = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        textViewRunShelltAfterFocus.delegate = self
        textViewRunShelltBeforeFocus.delegate = self
        
        checkBoxRunShellBeforeFocus.title = "Run shell script before starting focus mode."
        checkBoxRunShellAfterFocus.title = "Run shell script after finishing focus mode."
        
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
            
            checkBoxRunShellBeforeFocus.title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandBeforeText") as? String ?? checkBoxRunShellBeforeFocus.title
            checkBoxRunShellAfterFocus.title = focusPreferencesAdvancedInfo.value(forKey: "runShellCommandAfterText") as? String ?? checkBoxRunShellAfterFocus.title
    
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
        
        
        if #available(macOS 11.0, *) {
            btnAddUrl.image = NSImage(systemSymbolName: "plus.square.fill", accessibilityDescription: nil)
            btnRemoveUrl.image = NSImage(systemSymbolName: "minus.square.fill", accessibilityDescription: nil)
        }
        
        
//        let task = Process()
//        var args: [AnyHashable] = []
//        args.append("-c")
//        args.append("sleep \(1); open \"/System/Applications/TextEdit.app\"")
//        task.launchPath = "/bin/sh"
//        task.arguments = args as? [String]
//        task.launch()
        
    }
    override func viewWillAppear() {
        
        isShellScriptBeforeFocusEdited = false
        isShellScriptAfterFocusEdited = false
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
            
            if let val = arrFocusType[row]["isShellCommandBeforeFocusEnabled"] as? Bool{
                if val{
                    checkBoxRunShellBeforeFocus.state = .on
                }else{
                    checkBoxRunShellBeforeFocus.state = .off
                }
            }else{
                checkBoxRunShellBeforeFocus.state = .off
            }
            
            if let val = arrFocusType[row]["isShellCommandAfterFocusEnabled"] as? Bool{
                if val{
                    checkBoxRunShellAfterFocus.state = .on
                }else{
                    checkBoxRunShellAfterFocus.state = .off
                }
            }else{
                checkBoxRunShellAfterFocus.state = .off
            }
            if let val = arrFocusType[row]["shellCommandBeforeFocusText"] as? String{
                textViewRunShelltBeforeFocus.string = val
            }else{
                textViewRunShelltBeforeFocus.string = ""
            }
            
            if let val = arrFocusType[row]["shellCommandAfterFocusText"] as? String{
                textViewRunShelltAfterFocus.string = val
            }else{
                textViewRunShelltAfterFocus.string = ""
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
            
            if checkBoxRunShellBeforeFocus.state == .on{
                textViewRunShelltBeforeFocus.isEditable = true
            }else{
                textViewRunShelltBeforeFocus.isEditable = false
            }
            if checkBoxRunShellAfterFocus.state == .on{
                textViewRunShelltAfterFocus.isEditable = true
            }else{
                textViewRunShelltAfterFocus.isEditable = false
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
                if arrFocusType[row]["isDefault"] as? Bool == true{
                    bottomConstraint = NSLayoutConstraint(item: btnOk!, attribute: .top, relatedBy: .equal, toItem: textViewRunShelltAfterFocus, attribute: .bottom, multiplier: 1, constant: 14)
                    NSLayoutConstraint.activate([bottomConstraint!])
                    lblTitle.isHidden = true
                    lineHorizontal.isHidden = true
                    lblInstruction.isHidden = true
                }else{
                    if isAllowedListApproach{
                        bottomConstraint = NSLayoutConstraint(item: btnOk!, attribute: .top, relatedBy: .equal, toItem: boxTableView, attribute: .bottom, multiplier: 1, constant: 14)
                        NSLayoutConstraint.activate([bottomConstraint!])
                        lblTitle.isHidden = false
                        lineHorizontal.isHidden = false
                        lblInstruction.isHidden = false
                    }else{
                        bottomConstraint = NSLayoutConstraint(item: btnOk!, attribute: .top, relatedBy: .equal, toItem: textViewRunShelltAfterFocus, attribute: .bottom, multiplier: 1, constant: 14)
                        NSLayoutConstraint.activate([bottomConstraint!])
                        lblTitle.isHidden = true
                        lineHorizontal.isHidden = true
                        lblInstruction.isHidden = true
                    }
                }
            }
           
            
        }
        
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
            allApiObject.capturePosthog(event: "settings-changed-enable-script-before-focus", metadata: [:])//#490
        }else{
            arrFocusType[row]["isScriptBeforeFocusEnabled"] = false
            btnSelectAppleScriptBeforeFocus.isEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-script-before-focus", metadata: [:])//#490
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
            allApiObject.capturePosthog(event: "settings-changed-enable-script-after-focus", metadata: [:])//#490
        }else{
            arrFocusType[row]["isScriptAfterFocusEnabled"] = false
            btnSelectAppleScriptAfterFocus.isEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-disable-script-after-focus", metadata: [:])//#490
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
    }
    
    @IBAction func checkBoxRunShellCommandBeforeFocusClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunShellBeforeFocus.state == .on{
            arrFocusType[row]["isShellCommandBeforeFocusEnabled"] = true
            textViewRunShelltBeforeFocus.isEditable = true
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-before-focus", metadata: [:])
            self.view.window?.makeFirstResponder(textViewRunShelltBeforeFocus)
        }else{
            arrFocusType[row]["isShellCommandBeforeFocusEnabled"] = false
            textViewRunShelltBeforeFocus.isEditable = false
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-before-focus", metadata: [:])
        }
        UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
        
        allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
            DispatchQueue.main.async {

            }
        })
        
    }
    
    @IBAction func checkBoxRunShellCommandAfterFocusClicked(_ sender: Any) {
        let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
        if checkBoxRunShellAfterFocus.state == .on{
            arrFocusType[row]["isShellCommandAfterFocusEnabled"] = true
            textViewRunShelltAfterFocus.isEditable = true
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-after-focus", metadata: [:])
            self.view.window?.makeFirstResponder(textViewRunShelltAfterFocus)
        }else{
            arrFocusType[row]["isShellCommandAfterFocusEnabled"] = false
            textViewRunShelltAfterFocus.isEditable = false
            allApiObject.capturePosthog(event: "settings-changed-enable-shell-command-after-focus", metadata: [:])
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
        allApiObject.capturePosthog(event: "remove-blocked-url-in-focus-mode", metadata: [:])//#490

        reSetCurrentFocusMode(focusType:arrFocusType[selectedFocusTypeRow])
        
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        
        if isShellScriptBeforeFocusEdited || isShellScriptAfterFocusEdited{
            let row = focusPreferencesVcObj?.tblViewFocusType.selectedRow ?? 0
            
            //"shellCommandAfterFocusText"] as? String{"shellCommandBeforeFocusText"
            
            
            if isShellScriptBeforeFocusEdited{
                arrFocusType[row]["shellCommandBeforeFocusText"] = textViewRunShelltBeforeFocus.string
                allApiObject.capturePosthog(event: "set-shell-command-before-starting-focus-mode", metadata: [:])
            }
            
            
            if isShellScriptAfterFocusEdited{
                arrFocusType[row]["shellCommandAfterFocusText"] = textViewRunShelltAfterFocus.string
                allApiObject.capturePosthog(event: "set-shell-command-after-completing-focus-mode", metadata: [:])
            }
            
            
            
            
            UserDefaults.standard.set(arrFocusType, forKey: kUserdefaultsArrFocusTypes)
            allApiObject.editFocusMode(focusType: arrFocusType[row], completionHandler: {newDic in
                DispatchQueue.main.async {
                    
                }
            })
            
        }
        
        
        
        
        self.dismiss(self)
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


extension focusPreferencesAdvancedVc:NSTextViewDelegate{
    func textDidBeginEditing(_ notification: Notification) {
        print("textDidBeginEditing")
        if let textView = notification.object as? NSTextView{
            if textView == textViewRunShelltBeforeFocus{
                isShellScriptBeforeFocusEdited = true
            }else if textView == textViewRunShelltAfterFocus{
                isShellScriptAfterFocusEdited = true
            }
        }
    }
}
