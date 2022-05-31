//
//  preferencesTabViewController.swift
//  Earn Your Screentime
//
//  Created by Prashant Sawnani on 26/02/22.


import Cocoa

class preferencesTabViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
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

