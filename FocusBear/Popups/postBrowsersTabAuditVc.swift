//
//  postTabAuditVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/09/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class postBrowsersTabAuditVc: NSViewController {

    @IBOutlet weak var btnSave: Button!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var stepperTabLimit: NSStepper!
    @IBOutlet weak var textFieldTabLimit: NSTextField!
    @IBOutlet weak var lblMaxTabLimit: NSTextField!
    @IBOutlet weak var lblSetTabLimit: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Your tabs have been saved to the CSV file. You can safely close them now, since you have a reference stored."
        lblSetTabLimit.stringValue = "Set a tab limit so you don't get overwhelmed with tabs again"
        lblMaxTabLimit.stringValue = "Max tab limit:"
        btnCancel.title = buttonCancelText
        btnSave.title = "Save"
        textFieldTabLimit.delegate = self
        btnCancel.buttonColor = NSColor.white.cgColor
        
        
        if let postBrowsersTabAuditVcInfo = configjson.value(forKey: "postBrowsersTabAuditVcInfo") as? NSDictionary{
            lblTitle.stringValue = postBrowsersTabAuditVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSetTabLimit.stringValue = postBrowsersTabAuditVcInfo.value(forKey: "titleSetTabLimit") as? String ?? lblSetTabLimit.stringValue
            lblMaxTabLimit.stringValue = postBrowsersTabAuditVcInfo.value(forKey: "titleTabLimitCount") as? String ?? lblMaxTabLimit.stringValue
            btnSave.title = postBrowsersTabAuditVcInfo.value(forKey: "buttonSave") as? String ?? btnSave.title
        }
    }
    
    override func viewWillAppear() {
        stepperTabLimit.maxValue = 999
        stepperTabLimit.minValue = 1
        textFieldTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
        stepperTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
        isViewVisible = true
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
    }
    
    
    @IBAction func stepperTabLimitClicked(_ sender: Any) {
        textFieldTabLimit.integerValue = stepperTabLimit.integerValue
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func btnSaveClicked(_ sender: Any) {
        self.dismiss(self)
        
        if textFieldTabLimit.stringValue.isEmpty{
            textFieldTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
            return;
        }
        if textFieldTabLimit.integerValue < 1{
            textFieldTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
            return;
        }
        let count = textFieldTabLimit.integerValue
        if SettingsManagerObject.maxTabLimitCount == count{
            return;
        }
        
        stepperTabLimit.integerValue = textFieldTabLimit.integerValue
        SettingsManagerObject.maxTabLimitCount = stepperTabLimit.integerValue
        SettingsManagerObject.isTabLimiterEnabled = true
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.putUserLocalDeviceSettings()
        allApiObject.capturePosthog(event: "settings-changed-tab-limiter-count", metadata: ["count":SettingsManagerObject.maxTabLimitCount])//
    }
}


extension postBrowsersTabAuditVc: NSTextFieldDelegate{
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textfield = obj.object as? NSTextField{
            if textfield == textFieldTabLimit{
                if textFieldTabLimit.stringValue.isEmpty{
                    textFieldTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
                    return;
                }
                if textFieldTabLimit.integerValue < 1{
                    textFieldTabLimit.integerValue = SettingsManagerObject.maxTabLimitCount
                    return;
                }
                let count = textfield.integerValue
                if SettingsManagerObject.maxTabLimitCount == count{
                    return;
                }
                
                stepperTabLimit.integerValue = textFieldTabLimit.integerValue
            }
        }
    }
}
