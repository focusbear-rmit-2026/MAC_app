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
                    }else if id == "Focus"{
                        self.tabViewItems[i].label = tabFocusText
                    }else if id == "EditHabits"{
                        self.tabViewItems[i].label = tabEditHabitsText
                    }else if id == "Password"{
                        self.tabViewItems[i].label = tabPasswordText
                    }else if id == "Blocked URLs"{
                        self.tabViewItems[i].label = tabBlockedURLsText
                    }else if id == "Uninstall"{
                        self.tabViewItems[i].label = tabUninstallText
                    }else if id  == "Accounts"{
                        self.tabViewItems[i].label = tabAccountsText
                    }
                }
            }
        }
    }
    
    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        print("tab view selection change")
        print(self.selectedTabViewItemIndex)
        if self.selectedTabViewItemIndex == 2{
            selectJsonVcObj?.setData()
        }
    }
    
    override func tabView(_ tabView: NSTabView, shouldSelect tabViewItem: NSTabViewItem?) -> Bool {
        if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                return false
            }
        }
        return true
    }
}

