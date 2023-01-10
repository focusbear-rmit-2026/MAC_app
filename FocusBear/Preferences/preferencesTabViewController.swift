//
//  preferencesTabViewController.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class preferencesTabViewController: NSTabViewController {

    @IBOutlet weak var tabGeneral: NSTabViewItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        var tabSettingsText = "Settings"
        var tabFocusText = "Focus"
        var tabEditHabitsText = "Edit Habits"
        var tabPasswordText = "Password"
        var tabBlockedURLsText = "Blocked URLs"
        var tabUninstallText = "Uninstall"
        var tabAccountsText = "Accounts"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            tabSettingsText = common.value(forKey: "tabSettingsText") as? String ?? tabSettingsText
            tabFocusText = common.value(forKey: "tabFocusText") as? String ?? tabFocusText
            tabEditHabitsText = common.value(forKey: "tabEditHabitsText") as? String ?? tabEditHabitsText
            tabPasswordText = common.value(forKey: "tabPasswordText") as? String ?? tabPasswordText
            tabBlockedURLsText = common.value(forKey: "tabBlockedURLsText") as? String ?? tabBlockedURLsText
            tabUninstallText = common.value(forKey: "tabUninstallText") as? String ?? tabUninstallText
            tabAccountsText = common.value(forKey: "tabAccountsText") as? String ?? tabAccountsText
        }
        print(self.tabViewItems.count)
      
        DispatchQueue.global().async {//using this thread because we are getting  tabview items count is 1 but after implement lobal thread we are getting right count 
            DispatchQueue.main.async {
                for i in 0..<self.tabViewItems.count{
                    let tab = self.tabViewItems[i]
                    let id = tab.identifier as? String ?? ""
                    if id == "Settings"{
                        self.tabViewItems[i].label = tabSettingsText
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "NSSmartBadgeTemplate")
                        }
                    }else if id == "Focus"{
                        self.tabViewItems[i].label = tabFocusText
                        self.tabViewItems[i].image = NSImage(named: "NSTouchBarQuickLookTemplate")
                    }else if id == "EditHabits"{
                        self.tabViewItems[i].label = tabEditHabitsText
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "checkmark.rectangle", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "checkmark")
                        }
                    }else if id == "Password"{
                        self.tabViewItems[i].label = tabPasswordText
                        self.tabViewItems[i].image = NSImage(named: "NSLockLockedTemplate")
                    }else if id == "Blocked URLs"{
                        self.tabViewItems[i].label = tabBlockedURLsText
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "NSNetwork")
                        }
                    }else if id == "Uninstall"{
                        self.tabViewItems[i].label = tabUninstallText
                        self.tabViewItems[i].image = NSImage(named: "NSMenuMixedStateTemplate")
                    }else if id  == "Accounts"{
                        self.tabViewItems[i].label = tabAccountsText
                        if #available(macOS 11.0, *) {
                            self.tabViewItems[i].image = NSImage(systemSymbolName: "person", accessibilityDescription: nil)
                        } else {
                            self.tabViewItems[i].image = NSImage(named: "NSTouchBarUserTemplate")
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear() {
        self.view.window?.title = "Preferences"
        if let menuInfo = configjson.value(forKey: "menuInfo") as? NSDictionary{
            self.view.window?.title = menuInfo.value(forKey: "menuItemPreferencesTitle") as? String ?? "Preferences"
        }
    }
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("tab view selection change")
        print(self.selectedTabViewItemIndex)
        let id = tabViewItem?.identifier as? String ?? ""
        if id == "EditHabits"{
            selectJsonVcObj?.setData()
        }else if id == "Password"{// ask password for password tab when PasswordRequireInChangeSettings is false
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
                if !SettingsManagerObject.isPasswordRequireInChangeSettings{
                    self.view.addSubview(enterPasswordVcObj!.view)
                    self.view.addConstraints(subView: enterPasswordVcObj!.view)
                    enterPasswordVcObj?.parentVc = nil
                    addLog(text: "Showing enter password view inside preferences")
                }
            }
        }
    }
    
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                return false
            }
        }
        if isPurchased == false && daysLeft <= 0{// if UserDefaults.standard.object(forKey: "trialExpired") != nil{
            let id = tabViewItem?.identifier as? String ?? ""
            if id != "Uninstall" && id != "Accounts"{
                return false
            }
        }
        return true
    }
}

