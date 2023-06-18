//
//  customAlertVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class alertReasonAutoAllowSiteVc: NSViewController {

    @IBOutlet weak var btnCheckBox: NSButton!
    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var payload: [String : Any]?
    var response: NSDictionary?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnOk.title = buttonOkText
        btnCancel.buttonColor = NSColor.white.cgColor
    }
    func resetView(title: String, subTitle: String, buttonCancelText: String, checkBoxText: String, payload: [String : Any], response: NSDictionary){
        
        self.payload = payload
        self.response = response
        lblTitle.stringValue = title
        lblSubTitle.stringValue = subTitle
        btnCancel.title = buttonCancelText
        btnCheckBox.title = checkBoxText
        btnCheckBox.state = .off
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
        if btnCheckBox.state == .on{
            SettingsManagerObject.isAiAllowUrlShowAlertEnabled = false
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
        }
        popUpBlockConfirmVcObj?.timerHideAlert?.invalidate()
        popUpBlockConfirmVcObj?.timerHideAlert = nil
    }
    @IBAction func btnOkClicked(_ sender: Any) {
        self.view.window?.close()
        if payload != nil && response != nil{
            allApiObject.capturePosthog(event: "bad-decision-ai-allowed-url", metadata: ["payload":payload!, "response":response!])
        }
        
        if btnCheckBox.state == .on{
            SettingsManagerObject.isAiAllowUrlShowAlertEnabled = false
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.putUserLocalDeviceSettings()
        }
        popUpBlockConfirmVcObj?.timerHideAlert?.invalidate()
        popUpBlockConfirmVcObj?.timerHideAlert = nil
    }
}
