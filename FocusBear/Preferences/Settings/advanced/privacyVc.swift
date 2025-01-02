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
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxSurveillanceText = preferencesInfo.value(forKey: "checkBoxSurveillanceText") as? String ?? checkBoxSurveillanceText
            descriptionSurveillanceText = preferencesInfo.value(forKey: "descriptionSurveillanceText") as? String ?? descriptionSurveillanceText
        }

        var advanced_Privacy_Surveillance = "If you work on platforms like Upwork.com or Time Doctor which automatically take a screenshot of your computer every few minutes, turn this on so that Focus Bear windows won’t appear in the screenshots."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            advanced_Privacy_Surveillance = tooltips.value(forKey: "advanced_Privacy_Surveillance") as? String ?? advanced_Privacy_Surveillance
        }
        
        stackView.addView(surveillanceDetactionItemVcObj!.view, in: .bottom)
        surveillanceDetactionItemVcObj?.lblTitle.stringValue = checkBoxSurveillanceText
        surveillanceDetactionItemVcObj?.lblSubTitle.stringValue = descriptionSurveillanceText
        surveillanceDetactionItemVcObj?.delegate = self
        surveillanceDetactionItemVcObj?.lineBottom.isHidden = true
        surveillanceDetactionItemVcObj?.toolTip = advanced_Privacy_Surveillance
        
        arrForSearchFromSettings.append(["title": checkBoxSurveillanceText, "tabId": idPrivacy, "object": surveillanceDetactionItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": descriptionSurveillanceText, "tabId": idPrivacy, "object": surveillanceDetactionItemVcObj!.bgBox as Any])
    }
    
    override func viewWillAppear() {
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsHideAllWindowInScreenShots) as? Bool{
            if state{
                surveillanceDetactionItemVcObj?.btnSwitch.state = .on
            }else{
                surveillanceDetactionItemVcObj?.btnSwitch.state = .off
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
        }
    }
}
