//
//  strictnessVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class strictnessVc: NSViewController {
    
    @IBOutlet weak var boxStrictnessLevel: NSBox!
    @IBOutlet weak var lblSupergentle: NSTextField!
    @IBOutlet weak var lblTitleStrictnessLevel: NSTextField!
    @IBOutlet weak var sliderStrictness: NSSlider!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var stackView: NSStackView!
    @IBOutlet weak var lblGentle: NSTextField!
    @IBOutlet weak var lblSlightlyStrict: NSTextField!
    @IBOutlet weak var lblStrict: NSTextField!
    @IBOutlet weak var lblSuperStrict: NSTextField!
    
    let frictionItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let passwordItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let focusModeItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let browserTabLimiterItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let blockedURLsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let blockedAppsItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    let customBlockingVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    
    let blockListItemVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("settingListItemVc")) as? settingListItemVc
    
    var currentStrictnessLevel = 1
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        stackView.subviews.removeAll()
        
        lblTitleStrictnessLevel.stringValue = "Strictness level:"
        lblSupergentle.stringValue = "Super gentle"
        lblGentle.stringValue = "Gentle"
        lblSlightlyStrict.stringValue = "Slightly strict"
        lblStrict.stringValue = "Strict"
        lblSuperStrict.stringValue = "Super strict"

        var frictionSettingTitle = "Friction"
        var passwordSettingTitle = "Password"
        var focusModeSettingTitle = "Focus Mode"
        var blockingScheduleTitle = "Blocking Schedule"
        var tabLimiterSettingTitle = "Browser tab limiter"
        var blockedUrlsSettingTitle = "Super Distracting Sites"
        var blockedAppsSettingTitle = "Super Distracting Apps"
        var titleBlockLists = "Block Lists"
        if let settingsNew = configjson.value(forKey: "settingsNew") as? NSDictionary{
            frictionSettingTitle = settingsNew.value(forKey: "frictionSettingTitle") as? String ?? frictionSettingTitle
            passwordSettingTitle = settingsNew.value(forKey: "passwordSettingTitle") as? String ?? passwordSettingTitle
            focusModeSettingTitle = settingsNew.value(forKey: "focusModeSettingTitle") as? String ?? focusModeSettingTitle
            tabLimiterSettingTitle = settingsNew.value(forKey: "tabLimiterSettingTitle") as? String ?? tabLimiterSettingTitle
            
            lblTitleStrictnessLevel.stringValue = settingsNew.value(forKey: "titleStrictnessLevel") as? String ?? lblTitleStrictnessLevel.stringValue
            lblSupergentle.stringValue = settingsNew.value(forKey: "titleSuperGentle") as? String ?? lblSupergentle.stringValue
            lblGentle.stringValue = settingsNew.value(forKey: "titleGentle") as? String ?? lblGentle.stringValue
            lblSlightlyStrict.stringValue = settingsNew.value(forKey: "titleSlightlyStrict") as? String ?? lblSlightlyStrict.stringValue
            lblStrict.stringValue = settingsNew.value(forKey: "titleStrict") as? String ?? lblStrict.stringValue
            lblSuperStrict.stringValue = settingsNew.value(forKey: "titleSuperStrict") as? String ?? lblSuperStrict.stringValue
            blockingScheduleTitle = settingsNew.value(forKey: "blockingScheduleSettingTitle") as? String ?? blockingScheduleTitle
            titleBlockLists = settingsNew.value(forKey: "titleBlockLists") as? String ?? titleBlockLists
        }
        
        if let blockedUrlsViewInfo = configjson.value(forKey: "blockedUrlsViewInfo") as? NSDictionary{
            blockedUrlsSettingTitle = blockedUrlsViewInfo.value(forKey: "title") as? String ?? blockedUrlsSettingTitle
        }
        if let blockedAppsViewInfo = configjson.value(forKey: "blockedAppsViewInfo") as? NSDictionary{
            blockedAppsSettingTitle = blockedAppsViewInfo.value(forKey: "title") as? String ?? blockedAppsSettingTitle
        }

        if let alwaysAllowedAppsViewInfo = configjson.value(forKey: "alwaysAllowedAppsViewInfo") as? NSDictionary{
            alwaysAllowedAppsSettingTitle = alwaysAllowedAppsViewInfo.value(forKey: "title") as? String ?? alwaysAllowedAppsSettingTitle// todo text
        }
        
        var strictness_Friction = "Change how hard it is to unlock Focus Bear."
        var strictness_Password = "If you find you keep cheating, you can have someone else set a password to prevent you from easily unlocking Focus Bear."
        var strictness_DistractingSites = "Stay focused! Designate specific sites as 'Super Distracting' to proactively prevent access during crucial work periods, ensuring an undisturbed and concentrated workflow."
        var strictness_DistractingApps = "Minimize app distractions! Label select apps as 'Super Distracting' to strategically enhance your concentration, creating a refined digital environment tailored to your productivity needs."
        var strictness_Block_Lists = "Use Block Lists to stay focused on a certain type of work. Start a focus session from the focus bear menu or use a blocking schedule."
        var strictness_Blocking_Schedules = "Create your own schedules to automatically block distractions. Pick the days and times when distractions should be blocked. Stay focused without needing to start blocking manually."
        
        if let tooltips = configjson.value(forKey: "tooltips") as? NSDictionary{
            strictness_Friction = tooltips.value(forKey: "strictness_Friction") as? String ?? strictness_Friction
            strictness_Password = tooltips.value(forKey: "strictness_Password") as? String ?? strictness_Password
            strictness_DistractingSites = tooltips.value(forKey: "strictness_DistractingSites") as? String ?? strictness_DistractingSites
            strictness_DistractingApps = tooltips.value(forKey: "strictness_DistractingApps") as? String ?? strictness_DistractingApps
            strictness_Block_Lists = tooltips.value(forKey: "strictness_Block_Lists") as? String ?? strictness_Block_Lists
            strictness_Blocking_Schedules = tooltips.value(forKey: "strictness_Blocking_Schedules") as? String ?? strictness_Blocking_Schedules
        }
        
        
        
        stackView.addView(frictionItemVcObj!.view, in: .bottom)
        frictionItemVcObj?.lblTitle.stringValue = frictionSettingTitle
        if #available(macOS 11.0, *) {
            frictionItemVcObj?.imgViewIcon.image = NSImage(systemSymbolName: "slider.horizontal.below.rectangle", accessibilityDescription: nil)
        } else {
            frictionItemVcObj?.imgViewIcon.image = NSImage(named: NSImage.slideshowTemplateName)
        }
        frictionItemVcObj?.lblDescription.isHidden = true
        frictionItemVcObj?.delegate = self
        frictionItemVcObj?.toolTip = strictness_Friction
        
        //---password----
        
        stackView.addView(passwordItemVcObj!.view, in: .bottom)
        passwordItemVcObj?.lblTitle.stringValue = passwordSettingTitle
        passwordItemVcObj?.imgViewIcon.image = NSImage(named: NSImage.lockLockedTemplateName)
        passwordItemVcObj?.lblDescription.isHidden = true
        passwordItemVcObj?.delegate = self
        passwordItemVcObj?.toolTip = strictness_Password
        
        
        //---Focus mode blocking mode----
        
        stackView.addView(focusModeItemVcObj!.view, in: .bottom)
        focusModeItemVcObj?.lblTitle.stringValue = focusModeSettingTitle
        focusModeItemVcObj?.imgViewIcon.image = NSImage(named: NSImage.bookmarksTemplateName)
        focusModeItemVcObj?.lblDescription.isHidden = true
        focusModeItemVcObj?.delegate = self
        
        
        //---Block list----
        
        stackView.addView(blockListItemVcObj!.view, in: .bottom)
        blockListItemVcObj?.lblTitle.stringValue = titleBlockLists
        blockListItemVcObj?.imgViewIcon.image = NSImage(named: "NSTouchBarQuickLookTemplate")
        blockListItemVcObj?.lblDescription.isHidden = true
        blockListItemVcObj?.toolTip = strictness_Block_Lists
        blockListItemVcObj?.delegate = self
        
        
        //---Custom Blocking----
        stackView.addView(customBlockingVcObj!.view, in: .bottom)
        customBlockingVcObj?.lblTitle.stringValue = blockingScheduleTitle
        if #available(macOS 11.0, *) {
            customBlockingVcObj?.imgViewIcon.image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
        } else {
            customBlockingVcObj?.imgViewIcon.image = NSImage(named: NSImage.stopProgressTemplateName)
        }
        customBlockingVcObj?.lblDescription.isHidden = true
        customBlockingVcObj?.delegate = self
        customBlockingVcObj?.toolTip = strictness_Blocking_Schedules

        stackView.addView(blockedURLsItemVcObj!.view, in: .bottom)
        blockedURLsItemVcObj?.lblTitle.stringValue = blockedUrlsSettingTitle
        if #available(macOS 11.0, *) {
            blockedURLsItemVcObj?.imgViewIcon.image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
        } else {
            blockedURLsItemVcObj?.imgViewIcon.image = NSImage(named: "NSNetwork")
        } 
        blockedURLsItemVcObj?.lblDescription.isHidden = true
        blockedURLsItemVcObj?.delegate = self
        blockedURLsItemVcObj?.toolTip = strictness_DistractingSites
        
        
        stackView.addView(blockedAppsItemVcObj!.view, in: .bottom)
        blockedAppsItemVcObj?.lblTitle.stringValue = blockedAppsSettingTitle
        if #available(macOS 11.0, *) {
            blockedAppsItemVcObj?.imgViewIcon.image = NSImage(systemSymbolName: "app.badge", accessibilityDescription: nil)
        } else {
            blockedAppsItemVcObj?.imgViewIcon.image = NSImage(named: NSImage.quickLookTemplateName)
        }
        blockedAppsItemVcObj?.lblDescription.isHidden = true
        blockedAppsItemVcObj?.delegate = self
        blockedAppsItemVcObj?.toolTip = strictness_DistractingApps

        stackView.addView(browserTabLimiterItemVcObj!.view, in: .bottom)
        browserTabLimiterItemVcObj?.lblTitle.stringValue = tabLimiterSettingTitle
        browserTabLimiterItemVcObj?.imgViewIcon.image = NSImage(named: NSImage.touchBarOpenInBrowserTemplateName)
        browserTabLimiterItemVcObj?.lblDescription.isHidden = true
        browserTabLimiterItemVcObj?.delegate = self
        browserTabLimiterItemVcObj?.lineBottom.isHidden = true

        arrForSearchFromSettings.append(["title": frictionItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": frictionItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": passwordItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": passwordItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": focusModeItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": focusModeItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": browserTabLimiterItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": browserTabLimiterItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": blockedURLsItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockedURLsItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": blockedAppsItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockedAppsItemVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": customBlockingVcObj!.lblTitle.stringValue, "tabId": idTabStrictness, "object": customBlockingVcObj!.bgBox as Any])
        arrForSearchFromSettings.append(["title": blockListItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockListItemVcObj!.bgBox as Any])
        
        arrForSearchFromSimpleModeSettings.append(["title": browserTabLimiterItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": browserTabLimiterItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": blockedURLsItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockedURLsItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": blockedAppsItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockedAppsItemVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": customBlockingVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": customBlockingVcObj!.bgBox as Any])
        arrForSearchFromSimpleModeSettings.append(["title": blockListItemVcObj!.lblTitle.stringValue, "tabId": idStrictness, "object": blockListItemVcObj!.bgBox as Any])
    }
    
    override func viewWillAppear() {
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            lblTitle.stringValue = "Blocking"
            if let leftMenuVcInfo = configjson.value(forKey: "leftMenuVcInfo") as? NSDictionary{
                lblTitle.stringValue = leftMenuVcInfo.value(forKey: "menuBlocksPreferences") as? String ?? lblTitle.stringValue
            }
        }else{
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
        
        
        reloadDataForAppMode()
    }
    
    func reloadDataForAppMode(){
        if SettingsManagerObject.isGeekModeEnabled{
            reloadStrictnessLevelState()
            boxStrictnessLevel.isHidden = false
            frictionItemVcObj?.view.isHidden = false
            passwordItemVcObj?.view.isHidden = false
            focusModeItemVcObj?.view.isHidden = false
        }else{
            boxStrictnessLevel.isHidden = true
            frictionItemVcObj?.view.isHidden = true
            passwordItemVcObj?.view.isHidden = true
            focusModeItemVcObj?.view.isHidden = true
        }
        
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            boxStrictnessLevel.isHidden = true
            frictionItemVcObj?.view.isHidden = true
            passwordItemVcObj?.view.isHidden = true
            focusModeItemVcObj?.view.isHidden = true
            customBlockingVcObj?.view.isHidden = false
            blockListItemVcObj?.view.isHidden = false
        }else{
            customBlockingVcObj?.view.isHidden = true
            blockListItemVcObj?.view.isHidden = true
        }
    }
    
    func reloadStrictnessLevelState(){
        let strictnessLevel = SettingsManagerObject.getCurrentStrictnessLevel()
        sliderStrictness.integerValue = strictnessLevel
        currentStrictnessLevel = strictnessLevel
    }
 
    @IBAction func sliderStrictnessClicked(_ sender: Any) {
        print("sliderStrictnessClicked")
        self.presentAsSheet(getChangeFrictionLevelVcObj())
        getChangeFrictionLevelVcObj().slider.integerValue = sliderStrictness.integerValue
    }
}

extension strictnessVc: SettingListItemDelegate{
    func buttonClicked(object:settingListItemVc) {
        if object == passwordItemVcObj{
            settingsContainerVcObj?.showPasswordView()
            if shouldAskPassword(){
                if !isPasswordRequireInOpenSettingsEnabled(){
                    mainViewControllerObj?.askPasswordForSettings()
                    addLog(text: "Showing enter password view inside preferences")
                }
            }
        }else if object == frictionItemVcObj{
            settingsContainerVcObj?.showFrictionView()
        }else if object == focusModeItemVcObj{
            settingsContainerVcObj?.showFocusBearModeView()
        }else if object == browserTabLimiterItemVcObj{
            if leftMenuVcObj?.boxBlocks.isSelected ?? false{
                tabStrictnessContainerVcObj?.showBrowserTabLimiterView()
                return;
            }
            //----------------------------------------------------//
            settingsContainerVcObj?.showBrowserTabLimiterView()
        }else if object == blockedURLsItemVcObj{
            // for simple mode if strictness tab is selected
            if leftMenuVcObj?.boxBlocks.isSelected ?? false{
                tabStrictnessContainerVcObj?.showBlockedUrlsView()
                return;
            }
            //----------------------------------------------------//
            settingsContainerVcObj?.showBlockedUrlsView()
        }else if object == blockedAppsItemVcObj{
            // for simple mode if strictness tab is selected
            
            if leftMenuVcObj?.boxBlocks.isSelected ?? false{
                tabStrictnessContainerVcObj?.showBlockedAppsView()
                return;
            }
            //----------------------------------------------------//
            settingsContainerVcObj?.showBlockedAppsView()
        }
        else if object == customBlockingVcObj{
            tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()
        }else if object == blockListItemVcObj{
            tabStrictnessContainerVcObj?.showFocusPreferences()
        }
    }
}


