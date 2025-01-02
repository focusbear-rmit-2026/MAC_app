//
//  focusBearModeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class focusBearModeVc: NSViewController {

    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var lblDescriptionGrizzlyBear: NSTextField!
    @IBOutlet weak var radioBtnGrizzlyBear: NSButton!
    @IBOutlet weak var lblDescriptionCuddlyBear: NSTextField!
    @IBOutlet weak var radioBtnCuddlyBear: NSButton!
    @IBOutlet weak var lblTitleAppMode: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Focus Mode"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "focusModeSettingTitle") as? String ?? lblTitle.stringValue
        }
        lblTitleAppMode.stringValue = "Focus bear mode:"
        radioBtnCuddlyBear.title = "Cuddly Bear mode"
        lblDescriptionCuddlyBear.stringValue = "Cuddly Bear mode: kind and gentle - gives you the benefit of the doubt when you open a non-allowed URL. Lets you temporarily allow blocked URLs during a focus mode."
        
        radioBtnGrizzlyBear.title = "Grizzly Bear mode"
        lblDescriptionGrizzlyBear.stringValue = "Grizzly Bear mode: super strict - immediately block URLs that aren't allowed and don't let yourself allow them until the focus mode is over."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblTitleAppMode.stringValue = preferencesInfo.value(forKey: "titleAppMode") as? String ?? lblTitleAppMode.stringValue
            radioBtnCuddlyBear.title = preferencesInfo.value(forKey: "checkBoxCuddlyBearText") as? String ?? radioBtnCuddlyBear.title
            lblDescriptionCuddlyBear.stringValue = preferencesInfo.value(forKey: "descriptionCuddlyBearText") as? String ?? lblDescriptionCuddlyBear.stringValue
            radioBtnGrizzlyBear.title = preferencesInfo.value(forKey: "checkBoxGrizzlyBearText") as? String ?? radioBtnGrizzlyBear.title
            lblDescriptionGrizzlyBear.stringValue = preferencesInfo.value(forKey: "descriptionGrizzlyBearText") as? String ?? lblDescriptionGrizzlyBear.stringValue
        }
        
        arrForSearchFromSettings.append(["title": lblTitleAppMode.stringValue, "tabId": idFocusBearMode, "object": bgBox as Any])
        arrForSearchFromSettings.append(["title": radioBtnCuddlyBear.title, "tabId": idFocusBearMode, "object": bgBox as Any])
        arrForSearchFromSettings.append(["title": radioBtnGrizzlyBear.title, "tabId": idFocusBearMode, "object": bgBox as Any])
        
        
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.isCuddlyModeEnabled{
            radioBtnCuddlyBear.state = .on
            radioBtnGrizzlyBear.state = .off
        }else{
            radioBtnCuddlyBear.state = .off
            radioBtnGrizzlyBear.state = .on
        }
    }

    @IBAction func radioBtnCuddlyBearClicked(_ sender: Any) {
        if SettingsManagerObject.isCuddlyModeEnabled == true{
            return;
        }
        SettingsManagerObject.isSettingsChanged = true
        radioBtnGrizzlyBear.state = .off
        SettingsManagerObject.isCuddlyModeEnabled = true
        allApiObject.capturePosthog(event: "settings-changed-focus-bear-mode-cuddly", metadata: [:])//#490
    }
    
    @IBAction func radioBtnGrizzlyBearClicked(_ sender: Any) {
        if SettingsManagerObject.isCuddlyModeEnabled == false{
            return;
        }
        SettingsManagerObject.isSettingsChanged = true
        radioBtnCuddlyBear.state = .off
        SettingsManagerObject.isCuddlyModeEnabled = false
        allApiObject.capturePosthog(event: "settings-changed-focus-bear-mode-grizzly", metadata: [:])//#490
        
        let alert = NSAlert()
        alert.setSharingType()
        var warningText = "Warning: Grizzly Bear mode is not recommended until you have fully fleshed out your focus modes. We recommend starting with cuddly bear mode and switching to Grizzly Bear mode after a few weeks"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            warningText = preferencesInfo.value(forKey: "warningGrizzlyBearText") as? String ?? warningText
        }
        
        alert.messageText = warningText
        alert.addButton(withTitle: buttonOkText)
        
        if self.view.window != nil{
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    
                }
            })
        }
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
}
