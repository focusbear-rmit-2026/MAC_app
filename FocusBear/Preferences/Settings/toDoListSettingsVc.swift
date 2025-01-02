//
//  privacyVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class toDoListSettingsVc: NSViewController {
    
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let showToDoPlayerItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let brainDumpSettingItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnBack.isHidden = true
        lblTitle.stringValue = "To Do List"
        var showToDoPlayerSettingTitle = "Launch To Do player automatically"
        var brainDumpSettingTitle = "Start brain dump after morning routine"

        
        
        
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "toDoListSettingTitle") as? String ?? lblTitle.stringValue
        }
        
        if let toDoListSettingsVcInfo = configjson.value(forKey: "toDoListSettingsVcInfo") as? NSDictionary{
            showToDoPlayerSettingTitle = toDoListSettingsVcInfo.value(forKey: "showToDoPlayerSettingTitle") as? String ?? showToDoPlayerSettingTitle
            brainDumpSettingTitle = toDoListSettingsVcInfo.value(forKey: "brainDumpSettingTitle") as? String ?? brainDumpSettingTitle
        }
        
        
        stackView.subviews.removeAll()

        
        stackView.addView(showToDoPlayerItemVcObj!.view, in: .bottom)
        showToDoPlayerItemVcObj?.lblTitle.stringValue = showToDoPlayerSettingTitle
        showToDoPlayerItemVcObj?.lblSubTitle.isHidden = true
        showToDoPlayerItemVcObj?.delegate = self
        
        
        stackView.addView(brainDumpSettingItemVcObj!.view, in: .bottom)
        brainDumpSettingItemVcObj?.lblTitle.stringValue = brainDumpSettingTitle
        brainDumpSettingItemVcObj?.lblSubTitle.isHidden = true
        brainDumpSettingItemVcObj?.delegate = self
        brainDumpSettingItemVcObj?.lineBottom.isHidden = true
        

        arrForSearchFromSettings.append(["title": showToDoPlayerItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": showToDoPlayerItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": brainDumpSettingItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": brainDumpSettingItemVcObj!.bgBox as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": showToDoPlayerItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": showToDoPlayerItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": brainDumpSettingItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": brainDumpSettingItemVcObj!.bgBox as Any])
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.showToDoPlayerAutomaticallyEnabled{
            showToDoPlayerItemVcObj?.btnSwitch.state = .on
        }else{
            showToDoPlayerItemVcObj?.btnSwitch.state = .off
        }
        
        if SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled{
            brainDumpSettingItemVcObj?.btnSwitch.state = .on
        }else{
            brainDumpSettingItemVcObj?.btnSwitch.state = .off
        }
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}
extension toDoListSettingsVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == showToDoPlayerItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = true
//                allApiObject.capturePosthog(event: "settings-changed-enable-reload-after-force-quit", metadata: [:])
            }else{
                SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
//                allApiObject.capturePosthog(event: "settings-changed-disable-reload-after-force-quit", metadata: [:])
            }
        }else if object == brainDumpSettingItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled = true
//                allApiObject.capturePosthog(event: "settings-changed-enable-next-habit-reminder", metadata: [:])//#490
            }else{
                SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled = false
//                allApiObject.capturePosthog(event: "settings-changed-disable-next-habit-reminder", metadata: [:])//#490
            }
        }
    }
}
