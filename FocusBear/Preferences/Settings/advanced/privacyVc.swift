//
//  privacyVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class privacyVc: NSViewController {
    
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let surveillanceDetactionItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let advanceAanalyticsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Privacy"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "privacySettingTitle") as? String ?? lblTitle.stringValue
        }
        stackView.subviews.removeAll()

        var checkBoxSurveillanceText = "I'm under employer surveillance"
        var descriptionSurveillanceText = "Hide Focus Bear in screenshots"
        
        var switchButtonAdvanceAanalytics = "Enable advanced analytics while using focus mode"
        var descriptionAdvanceAanalytics = "Track the exact time you spend on each app and browser tab during focus mode. Gain deeper insights into your productivity by understanding how your attention is distributed."
        var privacyAdvanceAanalytics = "Data is only stored on your computer and not sent to our servers."
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxSurveillanceText = preferencesInfo.value(forKey: "checkBoxSurveillanceText") as? String ?? checkBoxSurveillanceText
            descriptionSurveillanceText = preferencesInfo.value(forKey: "descriptionSurveillanceText") as? String ?? descriptionSurveillanceText
            switchButtonAdvanceAanalytics = preferencesInfo.value(forKey: "switchButtonAdvanceAanalyticsText") as? String ?? switchButtonAdvanceAanalytics
            descriptionAdvanceAanalytics = preferencesInfo.value(forKey: "descriptionAdvanceAanalytics") as? String ?? descriptionAdvanceAanalytics
            privacyAdvanceAanalytics = preferencesInfo.value(forKey: "privacyAdvanceAanalytics") as? String ?? privacyAdvanceAanalytics
        }

        var advanced_Privacy_Surveillance = "If you work on platforms like Upwork.com or Time Doctor which automatically take a screenshot of your computer every few minutes, turn this on so that Focus Bear windows won’t appear in the screenshots."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            advanced_Privacy_Surveillance = tooltips.value(forKey: "advanced_Privacy_Surveillance") as? String ?? advanced_Privacy_Surveillance
        }
        
        stackView.addView(surveillanceDetactionItemVcObj!.view, in: .bottom)
        surveillanceDetactionItemVcObj?.lblTitle.stringValue = checkBoxSurveillanceText
        surveillanceDetactionItemVcObj?.lblSubTitle.stringValue = descriptionSurveillanceText
        surveillanceDetactionItemVcObj?.delegate = self
        surveillanceDetactionItemVcObj?.toolTip = advanced_Privacy_Surveillance
        
        
        stackView.addView(advanceAanalyticsItemVcObj!.view, in: .bottom)
        advanceAanalyticsItemVcObj?.lblTitle.stringValue = switchButtonAdvanceAanalytics
        advanceAanalyticsItemVcObj?.lblSubTitle.stringValue = descriptionAdvanceAanalytics
        
        
        let label = NSTextField(labelWithString: privacyAdvanceAanalytics)
        label.lineBreakMode = .byWordWrapping
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        label.font = NSFont.boldSystemFont(ofSize: advanceAanalyticsItemVcObj?.lblSubTitle.font?.pointSize ?? 13)
        advanceAanalyticsItemVcObj?.stackViewMain.addArrangedSubview(label)
        advanceAanalyticsItemVcObj?.delegate = self
        advanceAanalyticsItemVcObj?.lineBottom.isHidden = true
        
        
        arrForSearchFromSettings.append(["title": checkBoxSurveillanceText, "tabId": idPrivacy, "object": surveillanceDetactionItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": descriptionSurveillanceText, "tabId": idPrivacy, "object": surveillanceDetactionItemVcObj!.bgBox as Any])
        
        arrForSearchFromSettings.append(["title": switchButtonAdvanceAanalytics, "tabId": idPrivacy, "object": advanceAanalyticsItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": descriptionAdvanceAanalytics, "tabId": idPrivacy, "object": advanceAanalyticsItemVcObj!.bgBox as Any])
        
    }
    
    override func viewWillAppear() {
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                surveillanceDetactionItemVcObj?.btnSwitch.state = .on
            }else{
                surveillanceDetactionItemVcObj?.btnSwitch.state = .off
            }
        }
        if SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled{
            advanceAanalyticsItemVcObj?.btnSwitch.state = .on
        }else{
            advanceAanalyticsItemVcObj?.btnSwitch.state = .off
        }
    }
    
    func highlightAdvanceAanalyticsItemBox(){
        if let object = advanceAanalyticsItemVcObj?.bgBox{
            object.wantsLayer = true
            object.layer?.cornerRadius = 3
            object.layer?.borderWidth = 1
            object.layer?.borderColor = NSColor.labelColor.cgColor
            DispatchQueue.global().async {
                sleep(2)
                DispatchQueue.main.async {
                    object.layer?.cornerRadius = 0
                    object.layer?.borderWidth = 0
                    object.layer?.borderColor = NSColor.clear.cgColor
                    object.wantsLayer = false
                }
            }
        }
    }
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}
extension privacyVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == surveillanceDetactionItemVcObj{
            let windows = NSApp.windows
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots)
                for win in windows{
                    print(win)
                    win.sharingType = .none
                }
                appdelegate?.statusItem.button?.window?.sharingType = .none
                allApiObject.capturePosthog(event: "settings-changed-disable-app-screenshots", metadata: [:])//#490/
            }else{
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots)
                for win in windows{
                    print(win)
                    win.sharingType = .readOnly
                }
                appdelegate?.statusItem.button?.window?.sharingType = .readOnly
                allApiObject.capturePosthog(event: "settings-changed-enable-app-screenshots", metadata: [:])//#490
            }
        }else if object == advanceAanalyticsItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-advance-analytics", metadata: [:])
            }else{
                SettingsManagerObject.isAdvancedAnalyticsInFocusModeEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-advance-analytics", metadata: [:])
            }
        }
    }
}
