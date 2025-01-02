//
//  meetingDetactionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class meetingDetactionVc: NSViewController {

    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let meetingDetactionItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    let meetingDetactionAlertItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc

    let blockUrlsDuringMeetingsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Meetings"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "meetingsSettingTitle") as? String ?? lblTitle.stringValue
        }
        
        stackView.subviews.removeAll()

        var descriptionMeetingDetectionText = "Enable meeting detection to automatically suggest starting \"Meetings\" focus mode when Focus Bear detects you are in a call."
        var checkBoxMeetingDetectionText = "Enable meeting detection"
        var checkBoxShowMeetingDetectionPopupText = "Automatically suggest starting \"Meetings\" focus mode"
        var blockUrlsDuringMeetingsText = "Block \"Super Distracting Sites\" during Meetings"
        
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            descriptionMeetingDetectionText = preferencesInfo.value(forKey: "descriptionMeetingDetectionText") as? String ?? descriptionMeetingDetectionText
            checkBoxMeetingDetectionText = preferencesInfo.value(forKey: "checkBoxMeetingDetectionText") as? String ?? checkBoxMeetingDetectionText
            checkBoxShowMeetingDetectionPopupText = preferencesInfo.value(forKey: "checkBoxShowMeetingDetectionPopupText") as? String ?? checkBoxShowMeetingDetectionPopupText
            blockUrlsDuringMeetingsText = preferencesInfo.value(forKey: "blockUrlsDuringMeetingsText") as? String ?? blockUrlsDuringMeetingsText
        }
        
        var descriptionSuggestMeetingsFocusMode = "When you start a video call, Focus Bear can prompt you to start the Meeting focus mode to help you stay focused during the meeting"
        var descriptionBlockUrlsDuringMeetings = "Avoid awkward screensharing moments. Turn this setting off if you don’t want blocking to happen while you’re in meetings."
        
        if let settingsMeetingDetactionVcInfo = configjson.value(forKey: "settingsMeetingDetactionVcInfo") as? NSDictionary{
            descriptionSuggestMeetingsFocusMode = settingsMeetingDetactionVcInfo.value(forKey: "descriptionSuggestMeetingsFocusMode") as? String ?? descriptionSuggestMeetingsFocusMode
            descriptionBlockUrlsDuringMeetings = settingsMeetingDetactionVcInfo.value(forKey: "descriptionBlockUrlsDuringMeetings") as? String ?? descriptionBlockUrlsDuringMeetings
        }
        
        stackView.addView(meetingDetactionItemVcObj!.view, in: .bottom)
        meetingDetactionItemVcObj?.lblTitle.stringValue = checkBoxMeetingDetectionText
        meetingDetactionItemVcObj?.lblSubTitle.stringValue = descriptionMeetingDetectionText
        meetingDetactionItemVcObj?.delegate = self
        
        
        stackView.addView(meetingDetactionAlertItemVcObj!.view, in: .bottom)
        meetingDetactionAlertItemVcObj?.lblTitle.stringValue = checkBoxShowMeetingDetectionPopupText
        meetingDetactionAlertItemVcObj?.lblSubTitle.stringValue = descriptionSuggestMeetingsFocusMode
        meetingDetactionAlertItemVcObj?.delegate = self
        meetingDetactionAlertItemVcObj?.lineBottom.isHidden = false
        
        stackView.addView(blockUrlsDuringMeetingsItemVcObj!.view, in: .bottom)
        blockUrlsDuringMeetingsItemVcObj?.lblTitle.stringValue = blockUrlsDuringMeetingsText
        blockUrlsDuringMeetingsItemVcObj?.lblSubTitle.stringValue = descriptionBlockUrlsDuringMeetings
        blockUrlsDuringMeetingsItemVcObj?.delegate = self
        blockUrlsDuringMeetingsItemVcObj?.lineBottom.isHidden = true
        
        
        
        arrForSearchFromSettings.append(["title": checkBoxMeetingDetectionText, "tabId": idMeetings, "object": meetingDetactionItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxShowMeetingDetectionPopupText, "tabId": idMeetings, "object": meetingDetactionAlertItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": blockUrlsDuringMeetingsText, "tabId": idMeetings, "object": blockUrlsDuringMeetingsItemVcObj!.bgBox as Any])
        
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.isMeetingDetectionEnabled{
            meetingDetactionItemVcObj?.btnSwitch.state = .on
            meetingDetactionAlertItemVcObj?.btnSwitch.isEnabled = true
        }else{
            meetingDetactionItemVcObj?.btnSwitch.state = .off
            meetingDetactionAlertItemVcObj?.btnSwitch.isEnabled = false
        }
        if SettingsManagerObject.showMeetingDetectionAlert{
            meetingDetactionAlertItemVcObj?.btnSwitch.state = .on
        }else{
            meetingDetactionAlertItemVcObj?.btnSwitch.state = .off
        }
        
        if SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled{
            blockUrlsDuringMeetingsItemVcObj?.btnSwitch.state = .on
        }else{
            blockUrlsDuringMeetingsItemVcObj?.btnSwitch.state = .off
        }
    }

    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}
extension meetingDetactionVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == meetingDetactionItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                meetingDetactionAlertItemVcObj?.btnSwitch.isEnabled = true
                SettingsManagerObject.isMeetingDetectionEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-meeting-detection", metadata: [:])//#490
            }else{
                meetingDetactionAlertItemVcObj?.btnSwitch.isEnabled = false
                SettingsManagerObject.isMeetingDetectionEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-meeting-detection", metadata: [:])//#490
            }
        }else if object == meetingDetactionAlertItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.showMeetingDetectionAlert = true
                allApiObject.capturePosthog(event: "settings-changed-enable-meeting-popup", metadata: [:])//#490
            }else{
                SettingsManagerObject.showMeetingDetectionAlert = false
                allApiObject.capturePosthog(event: "settings-changed-disable-meeting-popup", metadata: [:])//#490
            }
        }else if object == blockUrlsDuringMeetingsItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-blocking-during-meetings", metadata: [:])//#490
            }else{
                SettingsManagerObject.isBlockDistractingSitesDuringMeetingsEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-blocking-during-meetings", metadata: [:])//#490
            }
        }
    }
}
