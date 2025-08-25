//
//  settingsContainerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class settingsContainerVc: NSViewController {

    @IBOutlet weak var segmentControlGeekMode: GeekModeSegmentedControl!
    @IBOutlet weak var containerView: NSView!
    var isPermissionsViewVisible = false
    override func viewDidLoad() {
        super.viewDidLoad()
        addLog(text: "settingsContainerVc viewdidload start")        
        settingsContainerVcObj = self
        
        getUIVcObject().loadView()
        
        getAccessibilityVcObject().loadView()
        
        getAiSettingNewVcObject().loadView()
        
        getPomodoroSettingsVcObject().loadView()
        
        getStrictnessVcObject().loadView()
        getFrictionVcObject().loadView()
        getPasswordVcObject().loadView()
        getfocusBearModeVcObject().loadView()
        getBrowserTabLimiterVcObject().loadView()
        getBlockedUrlsVcObject().loadView()
        getBlockedAppsVcObject().loadView()
        
        getAdvancedVcObject().loadView()
        getMeetingDetactionVcObject().loadView()
        getPrivacyVcObject().loadView()
        getMicroBreaksSettingsVcObject().loadView()
        getAddOnsVcObject().loadView()
        getResearchVcObject().loadView()
        
        getAccountVcObject().loadView()
        getUninstallVcObject().loadView()
        
        getToDoListSettingsVcObject().loadView()
        addLog(text: "settingsContainerVc viewdidload end")
    }
    @IBAction func btnSegmentControlGeekModeClicked(_ sender: Any) {
        if segmentControlGeekMode.selectedSegment == 0{
            if SettingsManagerObject.isGeekModeEnabled{
                return;
            }
            segmentControlGeekMode.changeAppModeTo(geekMode: true)
        }else{
            if !SettingsManagerObject.isGeekModeEnabled{
                return;
            }
            segmentControlGeekMode.changeAppModeTo(geekMode: false)
        }
    }
    func removeSubViews(){
        for subView in self.containerView.subviews{
            subView.removeFromSuperview()
        }
    }
    
    override func viewDidAppear() {
       // if let tabview = preferencesWindowControllerObj?.contentViewController as? NSTabViewController{
//            if passwordVcObj != nil{
//                if containerView.subviews.contains(passwordVcObj!.view){
//                    if shouldAskPassword(){
//                        if !isPasswordRequireInOpenSettingsEnabled(){
////                            tabview.view.addSubview(getEnterPasswordVcObjForPreferences().view)
////                            tabview.view.addConstraints(subView: getEnterPasswordVcObjForPreferences().view)
////                            getEnterPasswordVcObjForPreferences().parentVc = nil
////                            enterPasswordVcObjForPreferences?.removeConstraints()
//                            
//                            mainViewControllerObj?.askPasswordForSettingsIfNeeded()
//                            addLog(text: "Showing enter password view inside preferences")
//                        }
//                    }
//                }
//            }
       // }
        
        if SettingsManagerObject.isGeekModeEnabled{
            segmentControlGeekMode.setSelected(true, forSegment: 0)
        }else{
            segmentControlGeekMode.setSelected(true, forSegment: 1)
        }
    }
    func showUiView(){
        removeSubViews()
        self.containerView.addSubview(getUIVcObject().view)
        self.containerView.addConstraints(subView: getUIVcObject().view)
    }
    
    func showAccesibilityView(){
        removeSubViews()
        self.containerView.addSubview(getAccessibilityVcObject().view)
        self.containerView.addConstraints(subView: getAccessibilityVcObject().view)
    }
    
    func showPomodoroSettingsView(){
        removeSubViews()
        self.containerView.addSubview(getPomodoroSettingsVcObject().view)
        self.containerView.addConstraints(subView: getPomodoroSettingsVcObject().view)
    }
    func showStrictnessView(){
        // for simple mode if strictness tab is selected and back button is clicked
//        if !SettingsManagerObject.isGeekModeEnabled{
            
        
//        if self.view.window?.windowController == preferencesWindowControllerObj{
//            if let tabview = preferencesWindowControllerObj?.contentViewController as? preferencesTabViewController{
//                let selectedTabViewItem = tabview.tabViewItems[tabview.selectedTabViewItemIndex]
//                if selectedTabViewItem.identifier as? String == idTabStrictness && tabview.tabViewItemStrictnesss != nil{
//                    tabStrictnessContainerVcObj?.showStrictnessView()
//                    return;
//                }
//            }
//        }else{
            if leftMenuVcObj?.boxBlocks.isSelected ?? false{
                tabStrictnessContainerVcObj?.showStrictnessView()
                return;
            }
//        }
        
//        }
        //----------------------------------------------------//
        removeSubViews()
        self.containerView.addSubview(getStrictnessVcObject().view)
        self.containerView.addConstraints(subView: getStrictnessVcObject().view)
    }
    func showPasswordView(){
        removeSubViews()
        self.containerView.addSubview(getPasswordVcObject().view)
        self.containerView.addConstraints(subView: getPasswordVcObject().view)
    }
    
    func showFrictionView(){
        removeSubViews()
        self.containerView.addSubview(getFrictionVcObject().view)
        self.containerView.addConstraints(subView: getFrictionVcObject().view)
    }
    
    func showFocusBearModeView(){
        removeSubViews()
        self.containerView.addSubview(getfocusBearModeVcObject().view)
        self.containerView.addConstraints(subView: getfocusBearModeVcObject().view)
    }
    
    
    func showBrowserTabLimiterView(){
        removeSubViews()
        self.containerView.addSubview(getBrowserTabLimiterVcObject().view)
        self.containerView.addConstraints(subView: getBrowserTabLimiterVcObject().view)
    }
    
    func showBlockedUrlsView(){
        removeSubViews()
        self.containerView.addSubview(getBlockedUrlsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedUrlsVcObject().view)
    }
    
    func showBlockedAppsView(){
        removeSubViews()
        self.containerView.addSubview(getBlockedAppsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedAppsVcObject().view)
    }
    
    func showAiView(){
        removeSubViews()
        self.containerView.addSubview(getAiSettingNewVcObject().view)
        self.containerView.addConstraints(subView: getAiSettingNewVcObject().view)
    }
    
    func showAccountView(){
        removeSubViews()
        self.containerView.addSubview(getAccountVcObject().view)
        self.containerView.addConstraints(subView: getAccountVcObject().view)
    }
    
    func showUninstallView(){
        removeSubViews()
        self.containerView.addSubview(getUninstallVcObject().view)
        self.containerView.addConstraints(subView: getUninstallVcObject().view)
    }
    func showPermissionsView(){
        removeSubViews()
        self.containerView.addSubview(getPermissionsVcObject().view)
        self.containerView.addConstraints(subView: getPermissionsVcObject().view)
    }
    func showAdvancedView(){
        removeSubViews()
        self.containerView.addSubview(getAdvancedVcObject().view)
        self.containerView.addConstraints(subView: getAdvancedVcObject().view)
    }

    func showMeetingDetactionView(){
        removeSubViews()
        self.containerView.addSubview(getMeetingDetactionVcObject().view)
        self.containerView.addConstraints(subView: getMeetingDetactionVcObject().view)
    }

    func showPrivacyView(){
        removeSubViews()
        self.containerView.addSubview(getPrivacyVcObject().view)
        self.containerView.addConstraints(subView: getPrivacyVcObject().view)
    }
    
    
    func showMicroBreaksView(){
        removeSubViews()
        self.containerView.addSubview(getMicroBreaksSettingsVcObject().view)
        self.containerView.addConstraints(subView: getMicroBreaksSettingsVcObject().view)
    }
    
    func showAddOnsView(){
        removeSubViews()
        self.containerView.addSubview(getAddOnsVcObject().view)
        self.containerView.addConstraints(subView: getAddOnsVcObject().view)
    }
    
    func showTodoListSettingView(){
        removeSubViews()
        self.containerView.addSubview(getToDoListSettingsVcObject().view)
        self.containerView.addConstraints(subView: getToDoListSettingsVcObject().view)
    }
    
    func showResearchSettingView(){
        removeSubViews()
        self.containerView.addSubview(getResearchVcObject().view)
        self.containerView.addConstraints(subView: getResearchVcObject().view)
    }
}
