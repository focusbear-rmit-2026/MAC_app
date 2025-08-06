//
//  microBreaksVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class microBreaksSettingsVc: NSViewController {
    @IBOutlet weak var btnBack: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let showBreaksInCallItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let showBreaksInPostponeItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let enableBreaksItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let doNotBlockUrlsInPomodoroVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let detectNatualBreakEnabledVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnBack.isHidden = true
        lblTitle.stringValue = "Micro Breaks"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "breaksSettingTitle") as? String ?? lblTitle.stringValue
        }
        stackView.subviews.removeAll()

        var titleNaturalBreaks = "Detect natual breaks"
        var descriptionNaturalBreaks = "Notifies you when a natural break is detected after being idle for more than 10 minutes, helping you maintain focus and productivity."
        
        var titleDoNotBlockSuperDistractingUrls = "Do not block \"Super Distracting Sites\" during breaks"
        
        var checkBoxShowBreaksInCallText = "Show breaks while in call"
        var checkBoxShowBreaksInPostponeText = "Show breaks while postponing routine"
        var enableBreaksText = "Enable Breaks"
        var pomodoro_DoNotBlockDistractingSites = "We actually recommend you turn this off because breaks are much better if you get away from the computer. You could go for a walk instead :) However, if you don’t feel like giving your brain a break, you can turn off blocking and enjoy unrestricted breaks where you can access all of those distracting sites."

        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxShowBreaksInCallText = preferencesInfo.value(forKey: "checkBoxShowBreaksInCallText") as? String ?? checkBoxShowBreaksInCallText
            checkBoxShowBreaksInPostponeText = preferencesInfo.value(forKey: "checkBoxShowBreaksInPostponeText") as? String ?? checkBoxShowBreaksInPostponeText
        }
        if let microBreaksSettingsVcInfo = configjson.value(forKey: "microBreaksSettingsVcInfo") as? NSDictionary{
            enableBreaksText = microBreaksSettingsVcInfo.value(forKey: "enableBreaksText") as? String ?? enableBreaksText
            titleDoNotBlockSuperDistractingUrls = microBreaksSettingsVcInfo.value(forKey: "titleDoNotBlockSuperDistractingUrls") as? String ?? titleDoNotBlockSuperDistractingUrls
            titleNaturalBreaks = microBreaksSettingsVcInfo.value(forKey: "titleNaturalBreaks") as? String ?? titleNaturalBreaks
        }
        var advanced_MicroBreak_ShowBreaksInPostpone = "When you postpone your morning/evening routine, you can choose to keep getting break reminders while you’re using your computer. This is helpful because often when you postpone, it’s because something bad has happened (otherwise you would’ve done your habits) and short breaks can help reduce stress."
        var advanced_MicroBreak_ShowBreaksInCall = "In large meetings where you’re not actively participating, it can be helpful to still have break reminders. We’ll choose office friendly break activities (e.g. chair stretches) and won’t play sound effects."
        var breaks_EnableBreaks = "Enable taking breaks at regular intervals. Breaks help your productivity, energy levels, and ability to focus."
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            advanced_MicroBreak_ShowBreaksInPostpone = tooltips.value(forKey: "advanced_MicroBreak_ShowBreaksInPostpone") as? String ?? advanced_MicroBreak_ShowBreaksInPostpone
            advanced_MicroBreak_ShowBreaksInCall = tooltips.value(forKey: "advanced_MicroBreak_ShowBreaksInCall") as? String ?? advanced_MicroBreak_ShowBreaksInCall
            breaks_EnableBreaks = tooltips.value(forKey: "breaks_EnableBreaks") as? String ?? breaks_EnableBreaks
            pomodoro_DoNotBlockDistractingSites = tooltips.value(forKey: "pomodoro_DoNotBlockDistractingSites") as? String ?? pomodoro_DoNotBlockDistractingSites
            descriptionNaturalBreaks = tooltips.value(forKey: "breaks_NaturalBreaks") as? String ?? descriptionNaturalBreaks
        }
        
        
        stackView.addView(showBreaksInPostponeItemVcObj!.view, in: .bottom)
        showBreaksInPostponeItemVcObj?.lblTitle.stringValue = checkBoxShowBreaksInPostponeText
        showBreaksInPostponeItemVcObj?.lblSubTitle.isHidden = true
        showBreaksInPostponeItemVcObj?.delegate = self
        showBreaksInPostponeItemVcObj?.toolTip = advanced_MicroBreak_ShowBreaksInPostpone
        
        stackView.addView(showBreaksInCallItemVcObj!.view, in: .bottom)
        showBreaksInCallItemVcObj?.lblTitle.stringValue = checkBoxShowBreaksInCallText
        showBreaksInCallItemVcObj?.lblSubTitle.isHidden = true
        showBreaksInCallItemVcObj?.delegate = self
        showBreaksInCallItemVcObj?.toolTip = advanced_MicroBreak_ShowBreaksInCall
        
        stackView.addView(enableBreaksItemVcObj!.view, in: .bottom)
        enableBreaksItemVcObj?.lblTitle.stringValue = enableBreaksText
        enableBreaksItemVcObj?.lblSubTitle.isHidden = true
        enableBreaksItemVcObj?.delegate = self
        enableBreaksItemVcObj?.toolTip = breaks_EnableBreaks
        
        stackView.addView(doNotBlockUrlsInPomodoroVcObj!.view, in: .bottom)
        doNotBlockUrlsInPomodoroVcObj?.lblTitle.stringValue = titleDoNotBlockSuperDistractingUrls
        doNotBlockUrlsInPomodoroVcObj?.lblSubTitle.isHidden = true
        doNotBlockUrlsInPomodoroVcObj?.delegate = self
        doNotBlockUrlsInPomodoroVcObj?.toolTip = pomodoro_DoNotBlockDistractingSites
        
        stackView.addView(detectNatualBreakEnabledVcObj!.view, in: .bottom)
        detectNatualBreakEnabledVcObj?.lblTitle.stringValue = titleNaturalBreaks
        detectNatualBreakEnabledVcObj?.lblSubTitle.isHidden = true
        detectNatualBreakEnabledVcObj?.delegate = self
        detectNatualBreakEnabledVcObj?.lineBottom.isHidden = true
        detectNatualBreakEnabledVcObj?.toolTip = descriptionNaturalBreaks
        
        
        arrForSearchFromSettings.append(["title": checkBoxShowBreaksInPostponeText, "tabId": idMicroBreaks, "object": showBreaksInPostponeItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxShowBreaksInCallText, "tabId": idMicroBreaks, "object": showBreaksInCallItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": enableBreaksText, "tabId": idMicroBreaks, "object": enableBreaksItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleDoNotBlockSuperDistractingUrls, "tabId": idMicroBreaks, "object": doNotBlockUrlsInPomodoroVcObj?.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleNaturalBreaks, "tabId": idMicroBreaks, "object": detectNatualBreakEnabledVcObj?.bgBox as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxShowBreaksInPostponeText, "tabId": idMicroBreaks, "object": showBreaksInPostponeItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": checkBoxShowBreaksInCallText, "tabId": idMicroBreaks, "object": showBreaksInCallItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": enableBreaksText, "tabId": idMicroBreaks, "object": enableBreaksItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleDoNotBlockSuperDistractingUrls, "tabId": idMicroBreaks, "object": doNotBlockUrlsInPomodoroVcObj?.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleNaturalBreaks, "tabId": idMicroBreaks, "object": detectNatualBreakEnabledVcObj?.bgBox as Any])
    }
    
    override func viewWillAppear() {
        if SettingsManagerObject.IsShowBreaksInPostponeEnabled{
            showBreaksInPostponeItemVcObj?.btnSwitch.state = .on
        }else{
            showBreaksInPostponeItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.IsShowBreaksInCallEnabled{
            showBreaksInCallItemVcObj?.btnSwitch.state = .on
        }else{
            showBreaksInCallItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isMicroBreaksEnabled{
            enableBreaksItemVcObj?.btnSwitch.state = .on
        }else{
            enableBreaksItemVcObj?.btnSwitch.state = .off
        }
        if let state = UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks) as? Bool{
            if state{
                doNotBlockUrlsInPomodoroVcObj?.btnSwitch.state = .on
            }else{
                doNotBlockUrlsInPomodoroVcObj?.btnSwitch.state = .off
            }
        }
        if SettingsManagerObject.isDetectNatualBreaksEnabled{
            detectNatualBreakEnabledVcObj?.btnSwitch.state = .on
        }else{
            detectNatualBreakEnabledVcObj?.btnSwitch.state = .off
        }
        
    }

    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showAdvancedView()
    }
}
extension microBreaksSettingsVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == showBreaksInPostponeItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.IsShowBreaksInPostponeEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-breaks-while-postponing", metadata: [:])
            }else{
                SettingsManagerObject.IsShowBreaksInPostponeEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-breaks-while-postponing", metadata: [:])
            }
        }else if object == showBreaksInCallItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.IsShowBreaksInCallEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-breaks-while-call", metadata: [:])
            }else{
                SettingsManagerObject.IsShowBreaksInCallEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-breaks-while-call", metadata: [:])
            }
        }else if object == enableBreaksItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isMicroBreaksEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-breaks", metadata: [:])
            }else{
                SettingsManagerObject.isMicroBreaksEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-breaks", metadata: [:])
            }
        }else if object == doNotBlockUrlsInPomodoroVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            }else{
                UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            }
        }else if object == detectNatualBreakEnabledVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isDetectNatualBreaksEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-natual-breaks", metadata: [:])
            }else{
                SettingsManagerObject.isDetectNatualBreaksEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-natual-breaks", metadata: [:])
            }
        }
    }
}
