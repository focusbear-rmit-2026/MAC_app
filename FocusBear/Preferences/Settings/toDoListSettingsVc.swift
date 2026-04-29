//
//  privacyVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class toDoListSettingsVc: NSViewController {
    
    @IBOutlet weak var textFieldUrl: NSTextField!
    @IBOutlet weak var btnSwitchUseBrainDumpUrl: NSSwitch!
    @IBOutlet weak var boxBrainDumpUrl: NSBox!
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    @IBOutlet weak var lblTitleUseSpecificUrl: NSTextField!
    let showToDoPlayerItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let brainDumpSettingItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    var isViewVisible = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnBack.isHidden = true
        lblTitle.stringValue = "To Do List"
        lblTitleUseSpecificUrl.stringValue = "Use specific url for brain dump"
        var showToDoPlayerSettingTitle = "Launch To Do player automatically"
        var brainDumpSettingTitle = "Start brain dump after morning routine"

        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "toDoListSettingTitle") as? String ?? lblTitle.stringValue
        }
        
        if let toDoListSettingsVcInfo = configjson.value(forKey: "toDoListSettingsVcInfo") as? NSDictionary{
            showToDoPlayerSettingTitle = toDoListSettingsVcInfo.value(forKey: "showToDoPlayerSettingTitle") as? String ?? showToDoPlayerSettingTitle
            brainDumpSettingTitle = toDoListSettingsVcInfo.value(forKey: "brainDumpSettingTitle") as? String ?? brainDumpSettingTitle
            lblTitleUseSpecificUrl.stringValue = toDoListSettingsVcInfo.value(forKey: "useSpecificUrlBrainDumpTitle") as? String ?? lblTitleUseSpecificUrl.stringValue
        }


        stackView.insertView(showToDoPlayerItemVcObj!.view, at: 0, in: .top)
        showToDoPlayerItemVcObj?.lblTitle.stringValue = showToDoPlayerSettingTitle
        showToDoPlayerItemVcObj?.lblSubTitle.isHidden = true
        showToDoPlayerItemVcObj?.delegate = self
        
        stackView.insertView(brainDumpSettingItemVcObj!.view, at: 1, in: .top)
        brainDumpSettingItemVcObj?.lblTitle.stringValue = brainDumpSettingTitle
        brainDumpSettingItemVcObj?.lblSubTitle.isHidden = true
        brainDumpSettingItemVcObj?.delegate = self
        brainDumpSettingItemVcObj?.lineBottom.isHidden = false
        

        arrForSearchFromSettings.append(["title": showToDoPlayerItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": showToDoPlayerItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": brainDumpSettingItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": brainDumpSettingItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": lblTitleUseSpecificUrl.stringValue, "tabId": idToDoList, "object": boxBrainDumpUrl as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": showToDoPlayerItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": showToDoPlayerItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": brainDumpSettingItemVcObj!.lblTitle.stringValue, "tabId": idToDoList, "object": brainDumpSettingItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": lblTitleUseSpecificUrl.stringValue, "tabId": idToDoList, "object": boxBrainDumpUrl as Any])
        

        textFieldUrl.delegate = self
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
        
        reloadSettingsForBrainDump()
        isViewVisible = true
    }
    func reloadSettingsForBrainDump(){
        if SettingsManagerObject.brainDumpCustomUrlEnabled{
            btnSwitchUseBrainDumpUrl.state = .on
            textFieldUrl.isHidden = false
        }else{
            btnSwitchUseBrainDumpUrl.state = .off
            textFieldUrl.isHidden = true
        }
        textFieldUrl.stringValue = SettingsManagerObject.brainDumpCustomUrlValue
    }
    
    override func viewWillDisappear() {
        isViewVisible = false
    }
    
    @IBAction func btnSwitchUseBrainDumpUrlbtnSwitchUseBrainDumpUrlClicked(_ sender: Any) { 
        if btnSwitchUseBrainDumpUrl.state == .on{
            SettingsManagerObject.brainDumpCustomUrlEnabled = true
            textFieldUrl.isHidden = false
            allApiObject.capturePosthog(event: "settings-changed-enable-specific-url-for-brain-dump", metadata: [:])
        }else{
            SettingsManagerObject.brainDumpCustomUrlEnabled = false
            textFieldUrl.isHidden = true
            allApiObject.capturePosthog(event: "settings-changed-disable-specific-url-for-brain-dump", metadata: [:])
        }
        SettingsManagerObject.isSettingsChanged = true
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
                allApiObject.capturePosthog(event: "settings-changed-enable-launch-to-do-player-automatically", metadata: [:])
            }else{
                SettingsManagerObject.showToDoPlayerAutomaticallyEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-launch-to-do-player-automatically", metadata: [:])
            }
        }else if object == brainDumpSettingItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-start-brain-dump-after-morning-routine", metadata: [:])
            }else{
                SettingsManagerObject.showBrainDumpAfterMorningRoutineEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-start-brain-dump-after-morning-routine", metadata: [:])
            }
        }
    }
}

extension toDoListSettingsVc: NSTextFieldDelegate{
    func controlTextDidChange(_ obj: Notification) {
        if let textField = obj.object as? NSTextField{
            if self.textFieldUrl == textField{
                SettingsManagerObject.brainDumpCustomUrlValue = textField.stringValue
                SettingsManagerObject.isSettingsChanged = true
            }
        }
    }
}
