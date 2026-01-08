//
//  uIVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class uIVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    
    let fullScreenEnabledItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let showDockIconItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let hideDockBarItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    let darkModeItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingPopUpButtonItemVc")) as? settingPopUpButtonItemVc
    let selectLanguageItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingPopUpButtonItemVc")) as? settingPopUpButtonItemVc
    let enablePopoverMenuItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    let focusVisualIndicatorSettingVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingToggleItemVc")) as? settingToggleItemVc
    
    
    let copySystemPreferencesIndex = 0
    let alwaysDarkModeIndex = 1
    let neverDarkModeIndex = 2
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        stackView.subviews.removeAll()
        
        var ui_ActivitiesFullScreen = "Minimize distractions by doing your habits in full screen mode so you can’t see notifications or other apps while you’re doing your routines. If you enable this setting, you won’t be able to switch to other apps via cmd-tab. You can still deactivate Focus Bear if you have an emergency."
        var ui_ShowDockIcon = "Enable this setting to show the Focus Bear app icon in your Dock. If you click on the dock icon, it will open the Focus Bear menu."
        var ui_SelectLanguage = "We’ve translated the app into a few languages. Choose your preferred language here. Let us know if you need a different language by emailing support@focusbear.io"
        var ui_DarkMode = "Eye-friendly option! Opt for Dark Mode to reduce screen brightness and eye strain."
        var ui_HideDockInAllowedAppActivities = "Distraction-free mode! Sometimes app icons in the dock are distracting. Toggle this setting on to hide the dock while you’re doing habits with allowed apps. For example, you could have a journaling habit that only gives you access to your journaling app. If you enable this setting, you won’t see the dock with all its temptations."
        var ui_EnablePopoverMenu = "Enable this option to display the Focus Bear menu as a popover."
        
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            ui_ActivitiesFullScreen = tooltips.value(forKey: "ui_ActivitiesFullScreen") as? String ?? ui_ActivitiesFullScreen
            ui_ShowDockIcon = tooltips.value(forKey: "ui_ShowDockIcon") as? String ?? ui_ShowDockIcon
            ui_SelectLanguage = tooltips.value(forKey: "ui_SelectLanguage") as? String ?? ui_SelectLanguage
            ui_DarkMode = tooltips.value(forKey: "ui_DarkMode") as? String ?? ui_DarkMode
            ui_HideDockInAllowedAppActivities = tooltips.value(forKey: "ui_HideDockInAllowedAppActivities") as? String ?? ui_HideDockInAllowedAppActivities
            ui_EnablePopoverMenu = tooltips.value(forKey: "ui_EnablePopoverMenu") as? String ?? ui_EnablePopoverMenu
        }

        
        
        
        var checkBoxFullScreenEnabledText = "Play activities in full screen mode"
        var checkBoxShowDockIconText = "Show Dock icon"
        var titleSelectLanguage = "Select Language:"
        var titleDarkMode = "Dark Mode:"

        var popUpBtnDarkModeItems = ["Copy system preferences", "Always Dark Mode", "Never Dark Mode"]
        
        var descriptionHideDockText = "Enable this to hide dock during allowed apps activities to minimize distractions. \"System Events\" permission will be required for this."
        var checkBoxHideDockText = "Hide dock during activities having allowed apps."
        var switchButtonEnablePopoverMenuText = "Show Focus Bear menu as popover"
        
        
        var titleFocusVisualIndicator = "Show focus visual indicator"
        var descriptionFocusVisualIndicator = "Display a visual indicator when the focus alignment score drops."
        
        
        if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
            checkBoxFullScreenEnabledText = preferencesInfo.value(forKey: "checkBoxFullScreenEnabledText") as? String ?? checkBoxFullScreenEnabledText
            checkBoxShowDockIconText = preferencesInfo.value(forKey: "checkBoxShowDockIconText") as? String ?? checkBoxShowDockIconText
            titleSelectLanguage = preferencesInfo.value(forKey: "titleSelectLanguage") as? String ?? titleSelectLanguage
            titleDarkMode = preferencesInfo.value(forKey: "titleDarkMode") as? String ?? titleDarkMode
            
            if let appAppearanceOptions = preferencesInfo.value(forKey: "appAppearanceOptions") as? [String]{
                if appAppearanceOptions.count != 0{
                    popUpBtnDarkModeItems =  appAppearanceOptions
                }
            }
            
            descriptionHideDockText = preferencesInfo.value(forKey: "descriptionHideDockText") as? String ?? descriptionHideDockText
            checkBoxHideDockText = preferencesInfo.value(forKey: "checkBoxHideDockText") as? String ?? checkBoxHideDockText
            switchButtonEnablePopoverMenuText = preferencesInfo.value(forKey: "switchButtonEnablePopoverMenuText") as? String ?? switchButtonEnablePopoverMenuText
            
            titleFocusVisualIndicator = preferencesInfo.value(forKey: "switchButtonFocusVisualIndicatoText") as? String ?? titleFocusVisualIndicator
            descriptionFocusVisualIndicator = preferencesInfo.value(forKey: "descriptionFocusVisualIndicatorText") as? String ?? descriptionFocusVisualIndicator
        }

        stackView.addView(fullScreenEnabledItemVcObj!.view, in: .bottom)
        fullScreenEnabledItemVcObj?.lblTitle.stringValue = checkBoxFullScreenEnabledText
        fullScreenEnabledItemVcObj?.lblSubTitle.isHidden = true
        fullScreenEnabledItemVcObj?.delegate = self
        fullScreenEnabledItemVcObj?.toolTip = ui_ActivitiesFullScreen

        stackView.addView(showDockIconItemVcObj!.view, in: .bottom)
        showDockIconItemVcObj?.lblTitle.stringValue = checkBoxShowDockIconText
        showDockIconItemVcObj?.lblSubTitle.isHidden = true
        showDockIconItemVcObj?.delegate = self
        showDockIconItemVcObj?.toolTip = ui_ShowDockIcon
        
        stackView.addView(selectLanguageItemVcObj!.view, in: .bottom)
        selectLanguageItemVcObj?.lblTitle.stringValue = titleSelectLanguage
        selectLanguageItemVcObj?.lblSubTitle.isHidden = true
        selectLanguageItemVcObj?.delegate = self
        selectLanguageItemVcObj?.popUpBtn.removeAllItems()
        for language in arrLanguageDic{
            selectLanguageItemVcObj?.popUpBtn.addItem(withTitle: language["name"] ?? "")
        }
        selectLanguageItemVcObj?.toolTip = ui_SelectLanguage
        
        
        stackView.addView(darkModeItemVcObj!.view, in: .bottom)
        darkModeItemVcObj?.lblTitle.stringValue = titleDarkMode
        darkModeItemVcObj?.lblSubTitle.isHidden = true
        darkModeItemVcObj?.delegate = self
        darkModeItemVcObj?.popUpBtn.removeAllItems()
        darkModeItemVcObj?.popUpBtn.addItems(withTitles: popUpBtnDarkModeItems)
        darkModeItemVcObj?.toolTip = ui_DarkMode
        
        
        
        
        stackView.addView(focusVisualIndicatorSettingVcObj!.view, in: .bottom)
        focusVisualIndicatorSettingVcObj?.lblTitle.stringValue = titleFocusVisualIndicator
        focusVisualIndicatorSettingVcObj?.lblSubTitle.stringValue = descriptionFocusVisualIndicator
        focusVisualIndicatorSettingVcObj?.lblSubTitle.isHidden = false
        focusVisualIndicatorSettingVcObj?.delegate = self
        focusVisualIndicatorSettingVcObj?.lineBottom.isHidden = false
//        focusVisualIndicatorSettingVcObj?.toolTip = ui_EnablePopoverMenu
        
        
        stackView.addView(enablePopoverMenuItemVcObj!.view, in: .bottom)
        enablePopoverMenuItemVcObj?.lblTitle.stringValue = switchButtonEnablePopoverMenuText
        enablePopoverMenuItemVcObj?.lblSubTitle.isHidden = true
        enablePopoverMenuItemVcObj?.delegate = self
        enablePopoverMenuItemVcObj?.lineBottom.isHidden = false
        enablePopoverMenuItemVcObj?.toolTip = ui_EnablePopoverMenu
        
        
        
        stackView.addView(hideDockBarItemVcObj!.view, in: .bottom)
        hideDockBarItemVcObj?.lblTitle.stringValue = checkBoxHideDockText
        hideDockBarItemVcObj?.lblSubTitle.stringValue = descriptionHideDockText
        hideDockBarItemVcObj?.delegate = self
        hideDockBarItemVcObj?.lineBottom.isHidden = true
        hideDockBarItemVcObj?.toolTip = ui_HideDockInAllowedAppActivities
        

        
        arrForSearchFromSettings.append(["title": checkBoxFullScreenEnabledText, "tabId": idUi, "object": fullScreenEnabledItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxShowDockIconText, "tabId": idUi, "object": showDockIconItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleSelectLanguage, "tabId": idUi, "object": selectLanguageItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": titleDarkMode, "tabId": idUi, "object": darkModeItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": checkBoxHideDockText, "tabId": idUi, "object": hideDockBarItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": switchButtonEnablePopoverMenuText, "tabId": idUi, "object": enablePopoverMenuItemVcObj!.bgBox as Any])
        
        arrForSearchFromSettings.append(["title": titleFocusVisualIndicator, "tabId": idUi, "object": focusVisualIndicatorSettingVcObj!.bgBox as Any])
        
        
        arrForSearchFromSimpleModeSettings.append(["title": titleSelectLanguage, "tabId": idUi, "object": selectLanguageItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleDarkMode, "tabId": idUi, "object": darkModeItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": switchButtonEnablePopoverMenuText, "tabId": idUi, "object": enablePopoverMenuItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": titleFocusVisualIndicator, "tabId": idUi, "object": focusVisualIndicatorSettingVcObj!.bgBox as Any])
        
    }
    
    override func viewWillAppear() {
        if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
            for i in 0..<arrLanguageDic.count{
                if arrLanguageDic[i]["id"]  == language{
                    selectLanguageItemVcObj?.popUpBtn.selectItem(at: i)
                    break;
                }
            }
        }
        darkModeItemVcObj?.popUpBtn.selectItem(at: SettingsManagerObject.selectedAppAppearanceIndex)
        if settingsSideBarVcObj != nil{
            if settingsSideBarVcObj!.tblView.selectedRow == -1{
                lblTitle.stringValue = ""
            }else{
                lblTitle.stringValue = settingsSideBarVcObj!.arrSettingsList[settingsSideBarVcObj!.tblView.selectedRow]["title"] as? String ?? ""
            }
        }else{
            lblTitle.stringValue = ""
        }
        
        if SettingsManagerObject.isMenuPopoverEnabled{
            enablePopoverMenuItemVcObj?.btnSwitch.state = .on
        }else{
            enablePopoverMenuItemVcObj?.btnSwitch.state = .off
        }
        
        if SettingsManagerObject.isFocusVisualIndicatorEnabled{
            focusVisualIndicatorSettingVcObj?.btnSwitch.state = .on
        }else{
            focusVisualIndicatorSettingVcObj?.btnSwitch.state = .off
        }
        
        reloadDataForAppMode()
    }
    
    func reloadDataForAppMode(){
        if SettingsManagerObject.isGeekModeEnabled{
            hideDockBarItemVcObj?.view.isHidden = false
            showDockIconItemVcObj?.view.isHidden = false
            fullScreenEnabledItemVcObj?.view.isHidden = false
            enablePopoverMenuItemVcObj?.lineBottom.isHidden = false
            if SettingsManagerObject.isFullScreenEnabled{
                fullScreenEnabledItemVcObj?.btnSwitch.state = .on
            }else{
                fullScreenEnabledItemVcObj?.btnSwitch.state = .off
            }
            if let state = UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool{
                if state{
                    showDockIconItemVcObj?.btnSwitch.state = .on
                }else{
                    showDockIconItemVcObj?.btnSwitch.state = .off
                }
            }
            if SettingsManagerObject.isHideDockInActivity{
                hideDockBarItemVcObj?.btnSwitch.state = .on
            }else{
                hideDockBarItemVcObj?.btnSwitch.state = .off
            }
        }else{
            hideDockBarItemVcObj?.view.isHidden = true
            showDockIconItemVcObj?.view.isHidden = true
            fullScreenEnabledItemVcObj?.view.isHidden = true
            enablePopoverMenuItemVcObj?.lineBottom.isHidden = true
        }
    }
    
}
extension uIVc: SettingToggleItemDelegate, SettingPopUpButtonItemDelegate{
    func popUpButtonClicked(index: Int, object: settingPopUpButtonItemVc) {
        if object == selectLanguageItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            var oldSelectedIndex = 0
            if let language = UserDefaults.standard.object(forKey: kUserdefaultsSelectedLanguage) as? String{
                for i in 0..<arrLanguageDic.count{
                    if arrLanguageDic[i]["id"]  == language{
                        oldSelectedIndex = i
                        break;
                    }
                }
            }
            if object.popUpBtn.indexOfSelectedItem == oldSelectedIndex{
                return;
            }
            let alert = NSAlert()
            alert.setSharingType()
            var alertChangeLanguageMessageText = "Are you sure you want to change the language to <LANGUAGE>?"
            var alertChangeLanguageInfoText = "Focus Bear will restart for the changes to take effect."
            
            if let preferencesInfo = configjson.value(forKey: "preferencesInfo") as? NSDictionary{
                alertChangeLanguageMessageText = preferencesInfo.value(forKey: "alertChangeLanguageMessageText") as? String ?? alertChangeLanguageMessageText
                alertChangeLanguageInfoText = preferencesInfo.value(forKey: "alertChangeLanguageInfoText") as? String ?? alertChangeLanguageInfoText
            }
            alertChangeLanguageMessageText = alertChangeLanguageMessageText.replacingOccurrences(of: "<LANGUAGE>", with: object.popUpBtn.title)
            alert.messageText = alertChangeLanguageMessageText
            alert.informativeText = alertChangeLanguageInfoText
            alert.addButton(withTitle: buttonYesText)
            alert.addButton(withTitle: buttonNoText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                    
                    
                    addLog(text: "language changed by user to \(object.popUpBtn.title)")
                    UserDefaults.standard.set(arrLanguageDic[object.popUpBtn.indexOfSelectedItem]["id"], forKey: kUserdefaultsSelectedLanguage)
                    var languageName = arrLanguageDic[object.popUpBtn.indexOfSelectedItem]["languageName"] ?? ""
                    languageName = languageName.lowercased()
                    
                    self.view.window?.close()
                    allApiObject.capturePosthog(event: "settings-changed-language", metadata: ["language":languageName])//#490//
                    DispatchQueue.global().async {
                        sleep(1)
                        DispatchQueue.main.async {
                            appdelegate?.quitAndRestartApp()
                        }
                    }
                }else{
                    object.popUpBtn.selectItem(at: oldSelectedIndex)
                }
            })
        }else if object == darkModeItemVcObj{
            if object.popUpBtn.indexOfSelectedItem == SettingsManagerObject.selectedAppAppearanceIndex{
                return;
            }
            SettingsManagerObject.isSettingsChanged = true
            SettingsManagerObject.selectedAppAppearanceIndex = object.popUpBtn.indexOfSelectedItem
            
            var appearance: NSAppearance?
            
            switch SettingsManagerObject.selectedAppAppearanceIndex {
            case copySystemPreferencesIndex:
                allApiObject.capturePosthog(event: "settings-changed-app-mode", metadata: ["mode":"copy_system_preferences"])
                appearance = NSApp!.appearance
            case alwaysDarkModeIndex:
                allApiObject.capturePosthog(event: "settings-changed-app-mode", metadata: ["mode":"always_dark_mode"])
                appearance = NSAppearance(named: .darkAqua)
            case neverDarkModeIndex:
                allApiObject.capturePosthog(event: "settings-changed-app-mode", metadata: ["mode":"never_dark_mode"])
                appearance = NSAppearance(named: .aqua)
            default:
                break;
            }
            
            
            let windows = NSApp.windows
            for win in windows{
                print(win)
                win.appearance = appearance
            }
            
        }
        
        
    }
    func settingsChangegShowDockIcon(){
        UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
        NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        allApiObject.capturePosthog(event: "settings-changed-show-dock-icon", metadata: [:])//#490
    }
    
    func switchClicked(state: NSControl.StateValue, object: settingToggleItemVc) {
        if object == fullScreenEnabledItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isFullScreenEnabled = true
                allApiObject.capturePosthog(event: "settings-changed-enable-full-screen", metadata: [:])
                if isMainWindowLoaded{
//                    mainWindowControllerObj?.showFullSizeWindow()
                }
            }else{
                SettingsManagerObject.isFullScreenEnabled = false
                allApiObject.capturePosthog(event: "settings-changed-disable-full-screen", metadata: [:])
                if isMainWindowLoaded{
//                    mainWindowControllerObj?.showSmallSizeWindow()
                }
            }
        }else if object == showDockIconItemVcObj{
            if state == .on{
                if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil && SettingsManagerObject.isPasswordRequireInCircumventingBlocks{
                    if isPasswordRequireInOpenSettings(){
                        mainViewControllerObj?.askPasswordForSettingsIfNeeded()
                    }else{
                        settingsChangegShowDockIcon()
                    }
                   
                    addLog(text: "Showing enter password view inside preferences:- uivc")
                }else{
                    settingsChangegShowDockIcon()
                }
            }else{
                UserDefaults.standard.set(false, forKey: kUserdefaultsShowDockIcon)
                NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
                NSApplication.shared.activate(ignoringOtherApps: true)
                allApiObject.capturePosthog(event: "settings-changed-hide-dock-icon", metadata: [:])//#490
            }
        }else if object == hideDockBarItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isHideDockInActivity = true
                let _ = checkDocBarState()
                allApiObject.capturePosthog(event: "settings-changed-hide-dock-enabled", metadata: [:])//#490
            }else{
                SettingsManagerObject.isHideDockInActivity = false
                allApiObject.capturePosthog(event: "settings-changed-hide-dock-disabled", metadata: [:])//#490
            }
        }else if object == enablePopoverMenuItemVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                enableMenuPopover()
            }else{
                disableMenuPopover()
            }
        }else if object == focusVisualIndicatorSettingVcObj{
            SettingsManagerObject.isSettingsChanged = true
            if state == .on{
                SettingsManagerObject.isFocusVisualIndicatorEnabled = true
            }else{
                SettingsManagerObject.isFocusVisualIndicatorEnabled = false
            }
        }
    }
}



