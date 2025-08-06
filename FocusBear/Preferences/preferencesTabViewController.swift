//
//  preferencesTabViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa


class preferencesTabViewController: NSTabViewController {

    
    //@IBOutlet weak var tabGeneral: NSTabViewItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        addLog(text: "preferencesTabViewController viewdidload start")
        arrForSearchFromSettings.removeAll()
        arrForSearchFromSimpleModeSettings.removeAll()
        var tabSettingsText = "Settings"
        var tabFocusText = "Focus"
        var tabEditHabitsText = "Edit Habits"
        var tabPasswordText = "Password"
        var tabBlockedURLsText = "Blocked URLs"
        var tabUninstallText = "Uninstall"
        var tabAccountsText = "Accounts"
        var tabStatsText = "Motivation"
        var tabHelpText = "Help"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            tabSettingsText = common.value(forKey: "tabSettingsText") as? String ?? tabSettingsText
            tabFocusText = common.value(forKey: "tabFocusText") as? String ?? tabFocusText
            tabEditHabitsText = common.value(forKey: "tabEditHabitsText") as? String ?? tabEditHabitsText
            tabPasswordText = common.value(forKey: "tabPasswordText") as? String ?? tabPasswordText
            tabBlockedURLsText = common.value(forKey: "tabBlockedURLsText") as? String ?? tabBlockedURLsText
            tabUninstallText = common.value(forKey: "tabUninstallText") as? String ?? tabUninstallText
            tabAccountsText = common.value(forKey: "tabAccountsText") as? String ?? tabAccountsText
            tabStatsText = common.value(forKey: "tabStatsText") as? String ?? tabStatsText
            tabHelpText = common.value(forKey: "tabHelpText") as? String ?? tabHelpText
        }
        print(self.tabViewItems.count)
      
        DispatchQueue.global().async {//using this thread because we are getting  tabview items count is 1 but after implement lobal thread we are getting right count 
            DispatchQueue.main.async {
                for i in 0..<self.tabViewItems.count{
                    let tab = self.tabViewItems[i]
                    let id = tab.identifier as? String ?? ""
                    if id == idSettings{
                        self.tabViewItems[i].label = tabSettingsText
                        arrForSearchFromSettings.append(["title": tabSettingsText, "tabId": idSettings])
                        arrForSearchFromSimpleModeSettings.append(["title": tabSettingsText, "tabId": idSettings])
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "NSSmartBadgeTemplate")
                        }
                    }else if id == idFocus{
                        self.tabViewItems[i].label = tabFocusText
                        arrForSearchFromSettings.append(["title": tabFocusText, "tabId": idFocus])
                        self.tabViewItems[i].image = NSImage(named: "NSTouchBarQuickLookTemplate")
                    }else if id == idEditHabits{
                        self.tabViewItems[i].label = tabEditHabitsText
                        arrForSearchFromSettings.append(["title": tabEditHabitsText, "tabId": idEditHabits])
                        arrForSearchFromSimpleModeSettings.append(["title": tabEditHabitsText, "tabId": idEditHabits])
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "checkmark.rectangle", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "checkmark")
                        }
                    }
                    else if id  == idStats{
                        self.tabViewItems[i].label = tabStatsText
                        arrForSearchFromSettings.append(["title": tabStatsText, "tabId": idStats])
                        arrForSearchFromSimpleModeSettings.append(["title": tabStatsText, "tabId": idStats])
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "person", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "NSTouchBarUserTemplate")
                        }
                    }else if id  == idHelp{
                        self.tabViewItems[i].label = tabHelpText
                        arrForSearchFromSettings.append(["title": tabHelpText, "tabId": idHelp])
                        arrForSearchFromSimpleModeSettings.append(["title": tabHelpText, "tabId": idHelp])
                    }
                }
            }
        }
        addTabBlocks()
        addLog(text: "preferencesTabViewController viewdidload end")
    }
    
    override func viewWillAppear() {
        self.view.window?.title = "Preferences"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            self.view.window?.title = menuInfo.value(forKey: "menuItemPreferencesTitle") as? String ?? "Preferences"
        }
        reloadDataForAppMode()
    }
    override func viewDidAppear() {
        if SettingsManagerObject.isStrictnessLevelSuperGentle(){
            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
        }else{
            self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
        }
    }
    var tabViewItemFocus:NSTabViewItem?
    var tabViewItemStrictnesss:NSTabViewItem?

    
    func addTabBlocks(){
        if tabViewItemStrictnesss == nil{
            tabViewItemStrictnesss = NSTabViewItem(identifier: "newTab")
            var tabBlockedListText = "Blocks"
            if let common = configjson.value(forKey: "common") as? NSDictionary{
                tabBlockedListText = common.value(forKey: "tabBlocksText") as? String ?? tabBlockedListText
            }
            
            tabViewItemStrictnesss!.label = tabBlockedListText
            arrForSearchFromSimpleModeSettings.append(["title": tabBlockedListText, "tabId": idTabStrictness])
            if #available(macOS 11.0, *) {
                tabViewItemStrictnesss!.image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: nil)
            } else {
                tabViewItemStrictnesss!.image = NSImage(named: NSImage.stopProgressTemplateName)
            }
            tabViewItemStrictnesss?.identifier = idTabStrictness
            tabViewItemStrictnesss!.viewController = getTabStrictnessContainerVcObject()
        }
        
        self.insertTabViewItem(tabViewItemStrictnesss!, at: 2)
    }
    
    func newUrlOrAppAdded(){// show permissions if not added
        if UserDefaults.standard.object(forKey: kUserdefaultsIsAnyDistractionSetByUser) == nil{
            UserDefaults.standard.set(true, forKey: kUserdefaultsIsAnyDistractionSetByUser)
        }
        if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
            let alertWarning = NSAlert()
            alertWarning.setSharingType()
            alertWarning.messageText = "Do you want to block distractions?"
            alertWarning.informativeText = "You can block distracting websites and distracting apps. You will need to allow permissions to block distracting websites."
            var buttonBlockText = "Yeah - block them!"
            var buttonNoText = "No thanks"

            if let simplePomodoroVcInfo = configjson.value(forKey: "simplePomodoroVcInfo") as? NSDictionary{
                alertWarning.messageText = simplePomodoroVcInfo.value(forKey: "alertWarningPermissionsTitle") as? String ?? alertWarning.messageText
                alertWarning.informativeText = simplePomodoroVcInfo.value(forKey: "alertWarningSetDistractionsInfo") as? String ?? alertWarning.informativeText
                buttonBlockText = simplePomodoroVcInfo.value(forKey: "buttonBlockText") as? String ?? buttonBlockText
                buttonNoText = simplePomodoroVcInfo.value(forKey: "buttonNoText") as? String ?? buttonNoText
            }
            
            alertWarning.addButton(withTitle: buttonBlockText)
            alertWarning.addButton(withTitle: buttonNoText)
            
            alertWarning.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                
                if modalResponse == .alertFirstButtonReturn{
                    showExplainingPermissionsWindow(showingFromPomodoro: false)
                    self.view.window?.close()
                }
                
            })
            UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            return;
        }
    }
    
    func reloadDataForAppMode(){
        if SettingsManagerObject.isGeekModeEnabled{
            var isFocusTabAdded = false
            let items = tabViewItems
            for item in items {
                if item.identifier as? String == idFocus{
                    isFocusTabAdded = true
                }else if item.identifier as? String == idTabStrictness{
                    if tabViewItemStrictnesss == nil{
                        tabViewItemStrictnesss = item
                    }
//                    self.removeTabViewItem(item)
                }
            }
            if !isFocusTabAdded && tabViewItemFocus != nil{
                self.insertTabViewItem(tabViewItemFocus!, at: 1)
            }
            
            
            
        }else{
            var isStrictnesssTabAdded = false
            let items = tabViewItems
            for item in items {
                if item.identifier as? String == idFocus{
                    tabViewItemFocus = item
                    self.removeTabViewItem(item)
                }else if item.identifier as? String == idTabStrictness{
                    isStrictnesssTabAdded = true
                }
            }
            if !isStrictnesssTabAdded{
                addTabBlocks()
            }
            
        }
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("tab view selection change")
        print(self.selectedTabViewItemIndex)
        let id = tabViewItem?.identifier as? String ?? ""
        if id != idHelp && id != idStats{
            if isPasswordRequireInOpenSettings(){
                self.view.addSubview(getEnterPasswordVcObjForPreferences().view)
                self.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
                getEnterPasswordVcObjForPreferences().parentVc = nil
                enterPasswordVcObjForPreferences?.removeConstraints()
                addLog(text: "Showing enter password view inside edit habits")
            }
        }
    }
    
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if areSettingsEdited{
            preferencesWindowControllerObj!.showAlertSettingsEdited()
            areSettingsEdited = false
            return false
        }
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(getEnterPasswordVcObjForPreferences().view){
                return false
            }
        }
        return true
    }
}
 


var idGeneral = "General"
//var idPomodoro = "Pomodoro"
//var idAdvanced = "Advanced"
//var idBlockedUrls = "BlockedUrls"
//var idBlockedApps = "BlockedApps"
//var idPassword = "Password"
//var idAccount = "Account"
//var idAi = "Ai"
//var idUninstall = "Uninstall"
var idStats = "Stats"
var idFocus = "Focus"
var idEditHabits = "EditHabits"
var idSettings = "Settings"
var idHelp = "Help"
var idTabStrictness = "tabStrictness"
