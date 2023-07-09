//
//  aiPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 22/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class aiPermissionVc: NSViewController {

    @IBOutlet weak var heightBoxBg: NSLayoutConstraint!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Do you want to use AI to decide if websites should be allowed?"
        lblSubTitle.stringValue = "We'll use Open AI to decide if the site is valid based on your current focus mode, intention, the URL, the website title and the first 100 characters of the content. This is anonymous - no identifying details are shared."
        btnOk.title = buttonOkText
        btnCancel.title = "No thanks"
        
        if let aiPermissionVcInfo = configjson.value(forKey: "aiPermissionVcInfo") as? NSDictionary{
            lblTitle.stringValue = aiPermissionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = aiPermissionVcInfo.value(forKey: "descriptionText") as? String ?? lblSubTitle.stringValue
            btnCancel.title = aiPermissionVcInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
        }
        btnCancel.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.selectedFontIndex == intelOneMonoFontIndex || SettingsManagerObject.selectedFontIndex == openDyslexicFontIndex{
            heightBoxBg.constant = 660
        }else{
            heightBoxBg.constant = 600
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        SettingsManagerObject.isAiCheckUrlEnabled = true
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        showAlert()
    }
    @IBAction func btnCancelClicked(_ sender: Any) {
        SettingsManagerObject.isAiCheckUrlEnabled = false
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        showAlert()
    }
    
    func showAlert(){
        let alert = NSAlert()
        alert.setSharingType()
        
        alert.messageText = "Alright. You can change this setting later under Preferences - Settings - AI"
        if let aiPermissionVcInfo = configjson.value(forKey: "aiPermissionVcInfo") as? NSDictionary{
            alert.messageText = aiPermissionVcInfo.value(forKey: "titleAlertText") as? String ?? alert.messageText
        }
        alert.addButton(withTitle: buttonOkText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
            self.view.window?.contentViewController = getFocusTipsVcObjObj()
        })
    }
}
