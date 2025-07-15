//
//  researchVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 30/05/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class researchVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var btnBack: NSButton!
    
    let dataCollectionModeItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Research"
        stackView.subviews.removeAll()
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "researchSettingTitle") as? String ?? lblTitle.stringValue
        }
        
        var titleDataCollectionMode = "Data Collection Mode"
        var descriptionDataCollectionMode = "All interventions turned off for research purposes"
        if let researchSettingsVcInfo = configjson.value(forKey: "researchSettingsVcInfo") as? NSDictionary{
            titleDataCollectionMode = researchSettingsVcInfo.value(forKey: "titleDataCollectionMode") as? String ?? titleDataCollectionMode
            descriptionDataCollectionMode = researchSettingsVcInfo.value(forKey: "descriptionDataCollectionMode") as? String ?? descriptionDataCollectionMode
        }
        
        stackView.addView(dataCollectionModeItemVcObj!.view, in: .bottom)
        dataCollectionModeItemVcObj?.lblTitle.stringValue = titleDataCollectionMode
        dataCollectionModeItemVcObj?.lblSubTitle.stringValue = descriptionDataCollectionMode
        dataCollectionModeItemVcObj?.delegate = self
        dataCollectionModeItemVcObj?.lineBottom.isHidden = true
        
        arrForSearchFromSettings.append(["title": dataCollectionModeItemVcObj?.lblTitle.stringValue ?? "", "tabId": idResearch, "object": dataCollectionModeItemVcObj!.bgBox as Any])
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.isDataCollectionModeEnabled{
            dataCollectionModeItemVcObj?.btnSwitch.state = .on
        }else{
            dataCollectionModeItemVcObj?.btnSwitch.state = .off
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}
extension researchVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == dataCollectionModeItemVcObj{
            let windows = NSApp.windows
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isDataCollectionModeEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-data-collection-mode", metadata: [:])
            }else{
                SettingsManagerObject.isDataCollectionModeEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-data-collection-mode", metadata: [:])
            }
        }
    }
}
