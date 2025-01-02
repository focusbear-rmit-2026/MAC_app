//
//  AISettingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 22/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class AISettingVc: NSViewController {// this is not in use

    @IBOutlet weak var checkBoxMorningMotivation: NSButton!
    @IBOutlet weak var lblCheckBoxMorningMotivation: NSTextField!
    @IBOutlet weak var lblDescriptionMorningMotivation: NSTextField!
    @IBOutlet weak var lblTitleMorningMotivation: NSTextField!
    
    
    @IBOutlet weak var checkBoxWhichWebsiteAllow: NSButton!
    @IBOutlet weak var lblCheckBoxWhichWebsiteAllow: NSTextField!
    @IBOutlet weak var lblTitleWhichWebsiteAllow: NSTextField!
    @IBOutlet weak var lblDescriptionWhichWebsiteAllow: NSTextField!
    
    
    @IBOutlet weak var checkBoxShowAllowAlert: NSButton!
    @IBOutlet weak var lblCheckBoxShowAllowAlert: NSTextField!
    @IBOutlet weak var lblTitleShowAllowAlert: NSTextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitleMorningMotivation.stringValue = "Personalised motivational message:"
        lblCheckBoxMorningMotivation.stringValue = "Use AI to generate a personalised motivational message each morning"
        lblDescriptionMorningMotivation.stringValue = "Your routine streak and your morning routine activities will be sent to Open AI. No other details will be shared but if you have anything in the habit titles that would identify you, we recommend not to have any personally identifiable information in habit titles."
        
        lblTitleWhichWebsiteAllow.stringValue = "Allow websites:"
        lblCheckBoxWhichWebsiteAllow.stringValue = "Use AI to decide if websites should be allowed"
        lblDescriptionWhichWebsiteAllow.stringValue = "We'll use Open AI to decide if the site is valid based on your current focus mode, intention, the URL, the website title and the first 100 characters of the content. This is anonymous - no identifying details are shared."
        
        lblTitleShowAllowAlert.stringValue = "Safe URL allowed notification:"
        lblCheckBoxShowAllowAlert.stringValue = "Show alert with reason when AI automatically allows a url"
        
        if let aISettingVcInfo = configjson.value(forKey: "aISettingVcInfo") as? NSDictionary{
            lblTitleMorningMotivation.stringValue = aISettingVcInfo.value(forKey: "titleMotivation") as? String ?? lblTitleMorningMotivation.stringValue
            lblCheckBoxMorningMotivation.stringValue = aISettingVcInfo.value(forKey: "checkBoxMorningMotivationText") as? String ?? lblCheckBoxMorningMotivation.stringValue
            lblDescriptionMorningMotivation.stringValue = aISettingVcInfo.value(forKey: "descriptionMorningMotivationText") as? String ?? lblDescriptionMorningMotivation.stringValue
            lblTitleWhichWebsiteAllow.stringValue = aISettingVcInfo.value(forKey: "titleWebsiteAllow") as? String ?? lblTitleWhichWebsiteAllow.stringValue
            lblCheckBoxWhichWebsiteAllow.stringValue = aISettingVcInfo.value(forKey: "checkBoxWebsiteAllowText") as? String ?? lblCheckBoxWhichWebsiteAllow.stringValue
            lblDescriptionWhichWebsiteAllow.stringValue = aISettingVcInfo.value(forKey: "descriptionWebsiteAllowText") as? String ?? lblDescriptionWhichWebsiteAllow.stringValue
            lblTitleShowAllowAlert.stringValue = aISettingVcInfo.value(forKey: "titleShowAllowAlert") as? String ?? lblTitleShowAllowAlert.stringValue
            lblCheckBoxShowAllowAlert.stringValue = aISettingVcInfo.value(forKey: "checkBoxShowAllowAlertText") as? String ?? lblCheckBoxShowAllowAlert.stringValue
        }
        
        
        arrForSearchFromSettings.append(["title": lblTitleMorningMotivation.stringValue, "tabId": idAi, "object": lblTitleMorningMotivation as Any])
        arrForSearchFromSettings.append(["title": lblCheckBoxMorningMotivation.stringValue, "tabId": idAi, "object": lblCheckBoxMorningMotivation as Any])
        arrForSearchFromSettings.append(["title": lblTitleWhichWebsiteAllow.stringValue, "tabId": idAi, "object": lblTitleWhichWebsiteAllow as Any])
        arrForSearchFromSettings.append(["title": lblCheckBoxWhichWebsiteAllow.stringValue, "tabId": idAi, "object": lblCheckBoxWhichWebsiteAllow as Any])
        arrForSearchFromSettings.append(["title": lblTitleShowAllowAlert.stringValue, "tabId": idAi, "object": lblTitleShowAllowAlert as Any])
        arrForSearchFromSettings.append(["title": lblCheckBoxShowAllowAlert.stringValue, "tabId": idAi, "object": lblCheckBoxShowAllowAlert as Any])
        
        
        
        checkBoxMorningMotivation.toolTip = lblCheckBoxMorningMotivation.stringValue
        checkBoxWhichWebsiteAllow.toolTip = lblCheckBoxWhichWebsiteAllow.stringValue
        checkBoxShowAllowAlert.toolTip = lblCheckBoxShowAllowAlert.stringValue
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.isMotivationalMessageEnabled{
            checkBoxMorningMotivation.state = .on
        }else{
            checkBoxMorningMotivation.state = .off
        }
        
        if SettingsManagerObject.isAiCheckUrlEnabled{
            checkBoxWhichWebsiteAllow.state = .on
        }else{
            checkBoxWhichWebsiteAllow.state = .off
        }
        
//        if SettingsManagerObject.isAiAllowUrlShowAlertEnabled{
//            checkBoxShowAllowAlert.state = .on
//        }else{
//            checkBoxShowAllowAlert.state = .off
//        }
        
    }
    @IBAction func checkBoxMorningMotivationClicked(_ sender: Any) {
        if checkBoxMorningMotivation.state == .on{
            SettingsManagerObject.isMotivationalMessageEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-ai-motivation-enabled", metadata: [:])
        }else{
            SettingsManagerObject.isMotivationalMessageEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-ai-motivation-disabled", metadata: [:])
        }
        SettingsManagerObject.isSettingsChanged = true
    }
    @IBAction func checkBoxWhichWebsiteAllowClicked(_ sender: Any) {
        if checkBoxWhichWebsiteAllow.state == .on{
            SettingsManagerObject.isAiCheckUrlEnabled = true
            allApiObject.capturePosthog(event: "settings-changed-ai-check-website-enabled", metadata: [:])
        }else{
            SettingsManagerObject.isAiCheckUrlEnabled = false
            allApiObject.capturePosthog(event: "settings-changed-ai-check-website-disabled", metadata: [:])
        }
        SettingsManagerObject.isSettingsChanged = true
    }
//    @IBAction func checkBoxShowAllowAlertClicked(_ sender: Any) {
//        if checkBoxShowAllowAlert.state == .on{
//            SettingsManagerObject.isAiAllowUrlShowAlertEnabled = true
//            allApiObject.capturePosthog(event: "settings-changed-ai-allow-website-alert-enabled", metadata: [:])
//        }else{
//            SettingsManagerObject.isAiAllowUrlShowAlertEnabled = false
//            allApiObject.capturePosthog(event: "settings-changed-ai-allow-website-alert-disabled", metadata: [:])
//        }
//        SettingsManagerObject.isSettingsChanged = true
//    }
}
