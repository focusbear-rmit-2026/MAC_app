//
//  aiSettingNewVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 18/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class aiSettingNewVc: NSViewController {

    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let enableMotivationalMessageItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let allowSitesByAiItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
//    let aiShowAllowAlertItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        stackView.subviews.removeAll()

        var checkBoxMorningMotivationText = "Use AI to generate a personalised motivational message each morning"
        var descriptionMorningMotivationText = "Your routine streak and your morning routine activities will be sent to Open AI. No other details will be shared but if you have anything in the habit titles that would identify you, we recommend not to have any personally identifiable information in habit titles."

        var checkBoxWebsiteAllowText = "Use AI to decide if websites should be allowed"
        var descriptionWebsiteAllowText = "We'll use Open AI to decide if the site is valid based on your current focus mode, intention, the URL, the website title and the first 100 characters of the content. This is anonymous - no identifying details are shared."

//        var checkBoxShowAllowAlertText = "Show alert with reason when AI automatically allows a url"
        
        if let aISettingVcInfo = configjson.value(forKey: "aISettingVcInfo") as? NSDictionary{
            checkBoxMorningMotivationText = aISettingVcInfo.value(forKey: "checkBoxMorningMotivationText") as? String ?? checkBoxMorningMotivationText
            descriptionMorningMotivationText = aISettingVcInfo.value(forKey: "descriptionMorningMotivationText") as? String ?? descriptionMorningMotivationText
            checkBoxWebsiteAllowText = aISettingVcInfo.value(forKey: "checkBoxWebsiteAllowText") as? String ?? checkBoxWebsiteAllowText
            descriptionWebsiteAllowText = aISettingVcInfo.value(forKey: "descriptionWebsiteAllowText") as? String ?? descriptionWebsiteAllowText
//            checkBoxShowAllowAlertText = aISettingVcInfo.value(forKey: "checkBoxShowAllowAlertText") as? String ?? checkBoxShowAllowAlertText
        }

        var ai_MotivationalMessage = "Start your day inspired! Enable this setting to receive a unique motivational message crafted just for you every morning. We use AI (in a privacy safe manner) to generate the message."
        var ai_AllowSites = "When you open a website that you haven’t explicitly allowed or blocked, we’ll use AI to check whether it seems relevant. For example, facebook.com would not be relevant if you’re working on writing a business case for earthmoving equipment but would be relevant if you’re doing social media marketing. Your personal details are not shared with AI, just the website URL and your focus intention."
//        var ai_ShowAllowSitesAlert = "If you turn this setting on, you’ll see a little popup when you visit a new website telling you why AI allowed you access to it. Turn it off if you find the extra popup annoying."
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            ai_MotivationalMessage = tooltips.value(forKey: "ai_MotivationalMessage") as? String ?? ai_MotivationalMessage
            ai_AllowSites = tooltips.value(forKey: "ai_AllowSites") as? String ?? ai_AllowSites
//            ai_ShowAllowSitesAlert = tooltips.value(forKey: "ai_ShowAllowSitesAlert") as? String ?? ai_ShowAllowSitesAlert
        }
       
        
        stackView.addView(enableMotivationalMessageItemVcObj!.view, in: .bottom)
        enableMotivationalMessageItemVcObj?.lblTitle.stringValue = checkBoxMorningMotivationText
        enableMotivationalMessageItemVcObj?.lblSubTitle.stringValue = descriptionMorningMotivationText
        enableMotivationalMessageItemVcObj?.delegate = self
        enableMotivationalMessageItemVcObj?.toolTip = ai_MotivationalMessage
        
        stackView.addView(allowSitesByAiItemVcObj!.view, in: .bottom)
        allowSitesByAiItemVcObj?.lblTitle.stringValue = checkBoxWebsiteAllowText
        allowSitesByAiItemVcObj?.lblSubTitle.stringValue = descriptionWebsiteAllowText
        allowSitesByAiItemVcObj?.delegate = self
        allowSitesByAiItemVcObj?.toolTip = ai_AllowSites
        allowSitesByAiItemVcObj?.lineBottom.isHidden = true
        
//        stackView.addView(aiShowAllowAlertItemVcObj!.view, in: .bottom)
//        aiShowAllowAlertItemVcObj?.lblTitle.stringValue = checkBoxShowAllowAlertText
//        aiShowAllowAlertItemVcObj?.lblSubTitle.isHidden = true
//        aiShowAllowAlertItemVcObj?.delegate = self
//        aiShowAllowAlertItemVcObj?.toolTip = ai_ShowAllowSitesAlert
//        aiShowAllowAlertItemVcObj?.lineBottom.isHidden = true
        
        arrForSearchFromSettings.append(["title": checkBoxMorningMotivationText, "tabId": idAi, "object": enableMotivationalMessageItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxWebsiteAllowText, "tabId": idAi, "object": allowSitesByAiItemVcObj!.bgBox as Any])
//        arrForSearchFromSettings.append(["title": checkBoxShowAllowAlertText, "tabId": idAi, "object": aiShowAllowAlertItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxMorningMotivationText, "tabId": idAi, "object": enableMotivationalMessageItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxWebsiteAllowText, "tabId": idAi, "object": allowSitesByAiItemVcObj!.bgBox as Any])
        
        
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.isMotivationalMessageEnabled{
            enableMotivationalMessageItemVcObj?.btnSwitch.state = .on
        }else{
            enableMotivationalMessageItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isAiCheckUrlEnabled{
            allowSitesByAiItemVcObj?.btnSwitch.state = .on
        }else{
            allowSitesByAiItemVcObj?.btnSwitch.state = .off
        }
//        if SettingsManagerObject.isAiAllowUrlShowAlertEnabled{
//            aiShowAllowAlertItemVcObj?.btnSwitch.state = .on
//        }else{
//            aiShowAllowAlertItemVcObj?.btnSwitch.state = .off
//        }
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
        reloadDataForAppMode()
    }
    
    func reloadDataForAppMode(){
        if SettingsManagerObject.isGeekModeEnabled{
            allowSitesByAiItemVcObj?.view.isHidden = false
            enableMotivationalMessageItemVcObj?.lineBottom.isHidden = false
        }else{
            allowSitesByAiItemVcObj?.view.isHidden = true
            enableMotivationalMessageItemVcObj?.lineBottom.isHidden = true
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
}


extension aiSettingNewVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == enableMotivationalMessageItemVcObj{
            if state == .on{
                SettingsManagerObject.isMotivationalMessageEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-ai-motivation-enabled", metadata: [:])
            }else{
                SettingsManagerObject.isMotivationalMessageEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-ai-motivation-disabled", metadata: [:])
            }
            SettingsManagerObject.isSettingsChanged = true
        }else if object == allowSitesByAiItemVcObj{
            if state == .on{
                SettingsManagerObject.isAiCheckUrlEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-ai-check-website-enabled", metadata: [:])
            }else{
                SettingsManagerObject.isAiCheckUrlEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-ai-check-website-disabled", metadata: [:])
            }
            SettingsManagerObject.isSettingsChanged = true
        }
//        else if object == aiShowAllowAlertItemVcObj{
//            if state == .on{
//                SettingsManagerObject.isAiAllowUrlShowAlertEnabled = true
//                allApiObject.capturePosthog(event: "settings-changed-ai-allow-website-alert-enabled", metadata: [:])
//            }else{
//                SettingsManagerObject.isAiAllowUrlShowAlertEnabled = false
//                allApiObject.capturePosthog(event: "settings-changed-ai-allow-website-alert-disabled", metadata: [:])
//            }
//            SettingsManagerObject.isSettingsChanged = true
//        }
    }
}
