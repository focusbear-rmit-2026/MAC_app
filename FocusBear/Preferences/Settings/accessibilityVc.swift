//
//  accessibilityVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class accessibilityVc: NSViewController {
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let reduceMotionItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let soundItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let verbalAnnouncementItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let selectFontItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingPopUpButtonItemVc")) as? settingPopUpButtonItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        stackView.subviews.removeAll()
        
        var accessibility_ReduceMotion = "We show animated Bear GIFs after you complete habits. If you don’t like these animations or experience physical discomfort, you can turn off the animations."
        var accessibility_PlaySound = "We play video game style sound effects (ding!) after you complete habits to make you feel good about your progress. If you don’t like these sound effects, you can turn them off. You can also email us: support@focusbear.io if you’d like to be able to customize the sound effects."
        var accessibility_Announcement = "This feature is helpful if you have trouble reading from a screen. If you turn it on, it will use a Siri style voice to read out the next habit in your routine and let you know when you’ve finished the current habit."
        var accessibility_Font = "We’ve chosen some dyslexic friendly fonts to help you read the text in the Focus Bear app."
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            accessibility_ReduceMotion = tooltips.value(forKey: "accessibility_ReduceMotion") as? String ?? accessibility_ReduceMotion
            accessibility_PlaySound = tooltips.value(forKey: "accessibility_PlaySound") as? String ?? accessibility_PlaySound
            accessibility_Announcement = tooltips.value(forKey: "accessibility_Announcement") as? String ?? accessibility_Announcement
            accessibility_Font = tooltips.value(forKey: "accessibility_Font") as? String ?? accessibility_Font
        }
        
        var checkBoxReduceMotionText = "Prefer reduced motion (don't show animated bears)"
        var checkBoxSoundText = "Play sound effects"
        var checkBoxAnnouncementText = "Announcement after each activity"
        var titleFont = "Application Font:"
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxReduceMotionText = preferencesInfo.value(forKey: "checkBoxReduceMotionText") as? String ?? checkBoxReduceMotionText
            checkBoxSoundText = preferencesInfo.value(forKey: "checkBoxSoundText") as? String ?? checkBoxSoundText
            checkBoxAnnouncementText = preferencesInfo.value(forKey: "checkBoxAnnouncementText") as? String ?? checkBoxAnnouncementText
            titleFont = preferencesInfo.value(forKey: "titleFont") as? String ?? titleFont
        }
        
        
        stackView.addView(reduceMotionItemVcObj!.view, in: .bottom)
        reduceMotionItemVcObj?.lblTitle.stringValue = checkBoxReduceMotionText
        reduceMotionItemVcObj?.lblSubTitle.isHidden = true
        reduceMotionItemVcObj?.delegate = self
        reduceMotionItemVcObj?.toolTip = accessibility_ReduceMotion

        stackView.addView(soundItemVcObj!.view, in: .bottom)
        soundItemVcObj?.lblTitle.stringValue = checkBoxSoundText
        soundItemVcObj?.lblSubTitle.isHidden = true
        soundItemVcObj?.delegate = self
        soundItemVcObj?.toolTip = accessibility_PlaySound
        
        stackView.addView(verbalAnnouncementItemVcObj!.view, in: .bottom)
        verbalAnnouncementItemVcObj?.lblTitle.stringValue = checkBoxAnnouncementText
        verbalAnnouncementItemVcObj?.lblSubTitle.isHidden = true
        verbalAnnouncementItemVcObj?.delegate = self
        verbalAnnouncementItemVcObj?.toolTip = accessibility_Announcement
        
        stackView.addView(selectFontItemVcObj!.view, in: .bottom)
        selectFontItemVcObj?.lblTitle.stringValue = titleFont
        selectFontItemVcObj?.lblSubTitle.isHidden = true
        selectFontItemVcObj?.delegate = self
        selectFontItemVcObj?.lineBottom.isHidden = true
        selectFontItemVcObj?.popUpBtn.removeAllItems()
        selectFontItemVcObj?.toolTip = accessibility_Font
        
        var fontTitles = [String]()
        for font in arrFont{
            fontTitles.append(font.name)
        }
        selectFontItemVcObj?.popUpBtn.addItems(withTitles: fontTitles)
        
        
        arrForSearchFromSettings.append(["title": checkBoxReduceMotionText, "tabId": idAccesibility, "object": reduceMotionItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxSoundText, "tabId": idAccesibility, "object": soundItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxAnnouncementText, "tabId": idAccesibility, "object": verbalAnnouncementItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleFont, "tabId": idAccesibility, "object": selectFontItemVcObj!.bgBox as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxReduceMotionText, "tabId": idAccesibility, "object": reduceMotionItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxSoundText, "tabId": idAccesibility, "object": soundItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxAnnouncementText, "tabId": idAccesibility, "object": verbalAnnouncementItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleFont, "tabId": idAccesibility, "object": selectFontItemVcObj!.bgBox as Any])
        
        
        
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.kIsReducedMotion{
            reduceMotionItemVcObj?.btnSwitch.state = .on
        }else{
            reduceMotionItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isSoundEnabled{
            soundItemVcObj?.btnSwitch.state = .on
        }else{
            soundItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isAnnouncementEnabled{
            verbalAnnouncementItemVcObj?.btnSwitch.state = .on
        }else{
            verbalAnnouncementItemVcObj?.btnSwitch.state = .off
        }
        selectFontItemVcObj?.popUpBtn.selectItem(at: SettingsManagerObject.selectedFontIndex)
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
    }

}

extension accessibilityVc: SettingToggleItemDelegate, SettingPopUpButtonItemDelegate{
    func popUpButtonClicked(index: Int, object: settingPopUpButtonItemVc) {
        if object == selectFontItemVcObj{
            if SettingsManagerObject.selectedFontIndex == object.popUpBtn.indexOfSelectedItem{
                return;
            }

            let alert = NSAlert()
            alert.setSharingType()
            var alertChangeLanguageInfoText = "Focus Bear will restart for the changes to take effect."
            
            if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                alertChangeLanguageInfoText = preferencesInfo.value(forKey: "alertChangeLanguageInfoText") as? String ?? alertChangeLanguageInfoText
            }
            
            alert.messageText = alertChangeLanguageInfoText
            alert.addButton(withTitle: buttonOkText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                addLog(text: "font changed by user to \(object.popUpBtn.title)")
                
                SettingsManagerObject.isSettingsChanged = true
                SettingsManagerObject.selectedFontIndex = object.popUpBtn.indexOfSelectedItem
                allApiObject.capturePosthog(event: "settings-changed-font-\"\(object.popUpBtn.title)\"", metadata: [:])
                
                self.view.window?.close()
                DispatchQueue.global().async {
                    sleep(1)
                    DispatchQueue.main.async {
                        appdelegate?.quitAndRestartApp()
                    }
                }
            })
        }
    }
    
    
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == reduceMotionItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.kIsReducedMotion = true
                allApiObject.capturePosthog(event: "settings-changed-enable-reduce-motion", metadata: [:])//#490
            }else{
                SettingsManagerObject.kIsReducedMotion = false
                allApiObject.capturePosthog(event: "settings-changed-disable-reduce-motion", metadata: [:])//#490
            }
        }else if object == soundItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isSoundEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-sound-enabled", metadata: [:])//#490
            }else{
                SettingsManagerObject.isSoundEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-sound-disabled", metadata: [:])//#490
            }
        }else if object == verbalAnnouncementItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isAnnouncementEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-announcement-enabled", metadata: [:])//#490
            }else{
                SettingsManagerObject.isAnnouncementEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-announcement-disabled", metadata: [:])//#490
            }
        }
    }
}

