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
        
        var tabGeneralText = "General"
        var tabFocusText = "Focus"
        var tabSettingsText = "Settings"
        var tabPasswordText = "Password"
        var tabBlockedURLsText = "Blocked URLs"
        var tabUninstallText = "Uninstall"
        
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            tabGeneralText = common.value(forKey: "tabGeneralText") as? String ?? tabGeneralText
            tabFocusText = common.value(forKey: "tabFocusText") as? String ?? tabFocusText
            tabSettingsText = common.value(forKey: "tabSettingsText") as? String ?? tabSettingsText
            tabPasswordText = common.value(forKey: "tabPasswordText") as? String ?? tabPasswordText
            tabBlockedURLsText = common.value(forKey: "tabBlockedURLsText") as? String ?? tabBlockedURLsText
            tabUninstallText = common.value(forKey: "tabUninstallText") as? String ?? tabUninstallText
        }
        print(self.tabViewItems.count)
        
        DispatchQueue.global().async {//using this thread because we are getting  tabview items count is 1 but after implement lobal thread we are getting right count 
            DispatchQueue.main.async {
                for i in 0..<self.tabViewItems.count{
                    let tab = self.tabViewItems[i]
                    let id = tab.identifier as? String ?? ""
                    if id == "General"{
                        self.tabViewItems[i].label = tabGeneralText
                    }else if id == "Focus"{
                        self.tabViewItems[i].label = tabFocusText
                    }else if id == "Settings"{
                        self.tabViewItems[i].label = tabSettingsText
                    }else if id == "Password"{
                        self.tabViewItems[i].label = tabPasswordText
                    }else if id == "Blocked URLs"{
                        self.tabViewItems[i].label = tabBlockedURLsText
                    }else if id == "Uninstall"{
                        self.tabViewItems[i].label = tabUninstallText
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
        if UserDefaults.standard.object(forKey: kUserdefaultsAppPassword) != nil{
            if self.view.subviews.contains(enterPasswordVcObj!.view){
                return false
            }
        }
        
        return true
    }
}

