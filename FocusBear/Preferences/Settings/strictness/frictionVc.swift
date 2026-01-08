//
//  frictionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class frictionVc: NSViewController {

    @IBOutlet weak var bgBox: NSBox!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var lblQuestionSkipHabit: NSTextField!
    @IBOutlet weak var radioButtonEasySkip: NSButton!
    @IBOutlet weak var radioButtonHardSkip: NSButton!
    
    let reloadAppAfterForceQuitItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    let nextHabitRemainderItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let allowOutOfOrderHabitsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let requireIntentionInpostponeItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
  //  let accountabilityBuddiesVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Friction"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            lblTitle.stringValue = settingsNew.value(forKey: "frictionSettingTitle") as? String ?? lblTitle.stringValue
        }
        var checkBoxPromptToAskNextHabitText = "Occasionally prompt me to remember the next habit"
        var checkBoxAllowOutOfOrderHabitsText = "allow doing habits out of order"
        var settingRequireIntentionText = "Require intention when postponing"
        var descriptionSettingRequireIntention = "If this is set, when you try to postpone, Focus Bear will ask you to type in your plans for what you will do while postponing your habits. You must enter at least 10 characters."
        
        //var accountabilityBuddiesText = "Accountability buddies"

        var checkBoxReloadAppAfterForceQuitText = "Reload after Force Quit"
        lblQuestionSkipHabit.stringValue = "How easy do you want it to be to skip your habits?"
        radioButtonEasySkip.title = "Really easy - I want to be able to skip habits/breaks in a hurry"
        radioButtonHardSkip.title = "Make it hard to skip - otherwise I'll end up skipping habits + breaks most of the time"
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            lblQuestionSkipHabit.stringValue = preferencesInfo.value(forKey: "questionSkipHabitText") as? String ?? lblQuestionSkipHabit.stringValue
            radioButtonEasySkip.title = preferencesInfo.value(forKey: "radioButtonEasySkipText") as? String ?? radioButtonEasySkip.title
            radioButtonHardSkip.title = preferencesInfo.value(forKey: "radioButtonHardSkipText") as? String ?? radioButtonHardSkip.title
            checkBoxReloadAppAfterForceQuitText = preferencesInfo.value(forKey: "checkBoxReloadAppAfterForceQuitText") as? String ?? checkBoxReloadAppAfterForceQuitText
            checkBoxPromptToAskNextHabitText = preferencesInfo.value(forKey: "checkBoxPromptToAskNextHabitText") as? String ?? checkBoxPromptToAskNextHabitText
            checkBoxAllowOutOfOrderHabitsText = preferencesInfo.value(forKey: "allowOutOfOrderHabitsText") as? String ?? checkBoxAllowOutOfOrderHabitsText
            settingRequireIntentionText = preferencesInfo.value(forKey: "settingRequireIntentionText") as? String ?? settingRequireIntentionText
            descriptionSettingRequireIntention = preferencesInfo.value(forKey: "descriptionSettingRequireIntention") as? String ?? descriptionSettingRequireIntention
            //accountabilityBuddiesText = preferencesInfo.value(forKey: "accountabilityBuddiesText") as? String ?? accountabilityBuddiesText
        }
        var strictness_Friction_ReloadAfterForceQuit = "Effortless bounce back! Activate this convenient feature to automatically reload Focus Bear after a force quit, ensuring a swift and seamless experience for uninterrupted productivity."
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            strictness_Friction_ReloadAfterForceQuit = tooltips.value(forKey: "strictness_Friction_ReloadAfterForceQuit") as? String ?? strictness_Friction_ReloadAfterForceQuit
        }
        
        stackView.addView(reloadAppAfterForceQuitItemVcObj!.view, in: .bottom)
        reloadAppAfterForceQuitItemVcObj?.lblTitle.stringValue = checkBoxReloadAppAfterForceQuitText
        reloadAppAfterForceQuitItemVcObj?.lblSubTitle.isHidden = true
        reloadAppAfterForceQuitItemVcObj?.delegate = self
        reloadAppAfterForceQuitItemVcObj?.lineBottom.isHidden = false
        reloadAppAfterForceQuitItemVcObj?.toolTip = strictness_Friction_ReloadAfterForceQuit
        
        stackView.addView(nextHabitRemainderItemVcObj!.view, in: .bottom)
        nextHabitRemainderItemVcObj?.lblTitle.stringValue = checkBoxPromptToAskNextHabitText
        nextHabitRemainderItemVcObj?.lblSubTitle.isHidden = true
        nextHabitRemainderItemVcObj?.delegate = self
        nextHabitRemainderItemVcObj?.lineBottom.isHidden = false
        
        stackView.addView(allowOutOfOrderHabitsItemVcObj!.view, in: .bottom)
        allowOutOfOrderHabitsItemVcObj?.lblTitle.stringValue = checkBoxAllowOutOfOrderHabitsText
        allowOutOfOrderHabitsItemVcObj?.lblSubTitle.isHidden = true
        allowOutOfOrderHabitsItemVcObj?.delegate = self
        allowOutOfOrderHabitsItemVcObj?.lineBottom.isHidden = false
        
        stackView.addView(requireIntentionInpostponeItemVcObj!.view, in: .bottom)
        requireIntentionInpostponeItemVcObj?.lblTitle.stringValue = settingRequireIntentionText
        requireIntentionInpostponeItemVcObj?.lblSubTitle.stringValue = descriptionSettingRequireIntention
        requireIntentionInpostponeItemVcObj?.lblSubTitle.isHidden = false
        requireIntentionInpostponeItemVcObj?.delegate = self
        requireIntentionInpostponeItemVcObj?.lineBottom.isHidden = true
        
        
//        stackView.addView(accountabilityBuddiesVcObj!.view, in: .bottom)
//        accountabilityBuddiesVcObj?.lblTitle.stringValue = accountabilityBuddiesText
//        accountabilityBuddiesVcObj?.imgViewIcon.image = NSImage(named: NSImage.userGroupName)
//        accountabilityBuddiesVcObj?.lblDescription.isHidden = true
//        accountabilityBuddiesVcObj?.delegate = self
//        accountabilityBuddiesVcObj?.lineBottom.isHidden = true
        
        arrForSearchFromSettings.append(["title": lblQuestionSkipHabit.stringValue, "tabId": idFriction, "object": bgBox as Any])
        arrForSearchFromSettings.append(["title": radioButtonEasySkip.title, "tabId": idFriction, "object": bgBox as Any])
        arrForSearchFromSettings.append(["title": radioButtonHardSkip.title, "tabId": idFriction, "object": bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxReloadAppAfterForceQuitText, "tabId": idFriction, "object": reloadAppAfterForceQuitItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxPromptToAskNextHabitText, "tabId": idFriction, "object": nextHabitRemainderItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxAllowOutOfOrderHabitsText, "tabId": idFriction, "object": allowOutOfOrderHabitsItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": settingRequireIntentionText, "tabId": idFriction, "object": requireIntentionInpostponeItemVcObj!.bgBox as Any])
       // arrForSearchFromSettings.append(["title": accountabilityBuddiesText, "tabId": idFriction, "object": accountabilityBuddiesVcObj!.bgBox as Any])
    }
    override func viewWillAppear() {
        if SettingsManagerObject.isEasySkipEnabled{
            radioButtonEasySkip.state = .on
            radioButtonHardSkip.state = .off
        }else{
            radioButtonEasySkip.state = .off
            radioButtonHardSkip.state = .on
        }
        
        if SettingsManagerObject.shouldReloadAfterForceQuitEnabled{
            reloadAppAfterForceQuitItemVcObj?.btnSwitch.state = .on
        }else{
            reloadAppAfterForceQuitItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isPromptToRememberHabit{
            nextHabitRemainderItemVcObj?.btnSwitch.state = .on
        }else{
            nextHabitRemainderItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isOutOfOrderHabitsAllowed{
            allowOutOfOrderHabitsItemVcObj?.btnSwitch.state = .on
        }else{
            allowOutOfOrderHabitsItemVcObj?.btnSwitch.state = .off
        }
        if SettingsManagerObject.isRequiredIntentionInPostpone{
            requireIntentionInpostponeItemVcObj?.btnSwitch.state = .on
        }else{
            requireIntentionInpostponeItemVcObj?.btnSwitch.state = .off
        }
    }
    @IBAction func radioBtnEasySkipClick(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isEasySkipEnabled = true
        radioButtonHardSkip.state = .off
        allApiObject.capturePosthog(event: "settings-changed-friction-for-skipping-easy", metadata: [:])//#490
    }
    
    @IBAction func radioBtnHardSkipClick(_ sender: Any) {
        SettingsManagerObject.isSettingsChanged = true
        SettingsManagerObject.isEasySkipEnabled = false
        radioButtonEasySkip.state = .off
        allApiObject.capturePosthog(event: "settings-changed-friction-for-skipping-hard", metadata: [:])//#490
    }
    
    @IBAction func btnBackClicked(_ sender: Any) {
        settingsContainerVcObj?.showStrictnessView()
    }
    
    func turnOffReloadAfterForceQuit(){
        SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
//        deleteLaunchAgent()
        stopMainAppForceQuitMonitoring()
        allApiObject.capturePosthog(event: "settings-changed-disable-reload-after-force-quit", metadata: [:])
    }
}
extension frictionVc: SettingToggleItemDelegate{
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == reloadAppAfterForceQuitItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.shouldReloadAfterForceQuitEnabled = true
                startMainAppForceQuitMonitoring()
                allApiObject.capturePosthog(event: "settings-changed-enable-reload-after-force-quit", metadata: [:])
            }else{
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil && SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                    
                    if isPasswordRequireInOpenSettings(){
                        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
                    }else{
                        turnOffReloadAfterForceQuit()
                    }
                }else{
                    turnOffReloadAfterForceQuit()
                }
            }
        }else if object == nextHabitRemainderItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isPromptToRememberHabit = true
                allApiObject.capturePosthog(event: "settings-changed-enable-next-habit-reminder", metadata: [:])//#490
            }else{
                SettingsManagerObject.isPromptToRememberHabit = false
                allApiObject.capturePosthog(event: "settings-changed-disable-next-habit-reminder", metadata: [:])//#490
            }
        }else if object == allowOutOfOrderHabitsItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isOutOfOrderHabitsAllowed = true
                allApiObject.capturePosthog(event: "settings-changed-enable-out-of-order-habits", metadata: [:])
            }else{
                SettingsManagerObject.isOutOfOrderHabitsAllowed = false
                allApiObject.capturePosthog(event: "settings-changed-disable-out-of-order-habits", metadata: [:])
            }
        }else if object == requireIntentionInpostponeItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isRequiredIntentionInPostpone = true
                allApiObject.capturePosthog(event: "settings-changed-enable-required-intention-in-postpone", metadata: [:])
            }else{
                SettingsManagerObject.isRequiredIntentionInPostpone = false
                allApiObject.capturePosthog(event: "settings-changed-disable-required-intention-in-postpone", metadata: [:])
            }
        }
    }
}



//extension frictionVc: SettingListItemDelegate{
//    func buttonClicked(object:settingListItemVc) {
//        if object == accountabilityBuddiesVcObj{
//            var comingSoonText = "Coming Soon"
//            if let common = configjson.value(forKey: "common") as? NSDictionary{
//                comingSoonText = common.value(forKey: "comingSoonText") as? String ?? comingSoonText
//            }
//            allApiObject.capturePosthog(event: "interested-in-accountability-buddies", metadata: [:])
//            showTooltip(sender: accountabilityBuddiesVcObj!.view, msg: comingSoonText, preferredEdge: NSRectEdge.maxY, maxWidthVal:230)
//        }
//    }
//}
