//
//  settingsContainerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 14/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine

class settingsContainerVc: NSViewController {
    private var managedSettingsObserver: AnyCancellable?


    @IBOutlet weak var segmentControlGeekMode: GeekModeSegmentedControl!
    @IBOutlet weak var containerView: NSView!
    var isPermissionsViewVisible = false
    override func viewDidLoad() {
        managedSettingsObserver = ManagedBlockingRuntime.shared.$isSettingsLocked.removeDuplicates().receive(on: RunLoop.main).sink { [weak self] locked in
            if locked, self?.isViewLoaded == true { self?.showManagedPolicyInspection() }
        }
        super.viewDidLoad()
        addLog(text: "settingsContainerVc viewdidload start")        
        settingsContainerVcObj = self
        
        getUIVcObject().loadView()
        
        getAccessibilityVcObject().loadView()
        
        getAiSettingNewVcObject().loadView()
        
        getPomodoroSettingsVcObject().loadView()
        if !getStrictnessVcObject().isViewLoaded{
            getStrictnessVcObject().loadView()
        }
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
        getTalkingClockSettingsVcObject().loadView()
        getResearchVcObject().loadView()
        
        getAccountVcObject().loadView()
        getUninstallVcObject().loadView()
        
        
        _ = getKeyboardShortcutsSettingsVcObject()// The getKeyboardShortcutsSettingsVcObject function is already calling the loadView() function from within.
        
        
        getToDoListSettingsVcObject().loadView()
        addLog(text: "settingsContainerVc viewdidload end")
    }
    @IBAction func btnSegmentControlGeekModeClicked(_ sender: Any) {
        guard ManagedBlockingRuntime.shared.allowLegacySettingsMutation() else { return }
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
    func showManagedPolicyInspection() {
        removeSubViews()
        let inspector = NSHostingView(rootView: ManagedPolicyInspector(runtime: .shared))
        if #available(macOS 13.0, *) { inspector.sizingOptions = [] }
        for axis in [NSLayoutConstraint.Orientation.horizontal, .vertical] {
            inspector.setContentHuggingPriority(.defaultLow, for: axis)
            inspector.setContentCompressionResistancePriority(.defaultLow, for: axis)
        }
        containerView.addSubview(inspector)
        containerView.addConstraints(subView: inspector)
    }

    func removeSubViews(){
        for subView in self.containerView.subviews{
            subView.removeFromSuperview()
        }
    }
    
    override func viewDidAppear() {
        
        if SettingsManagerObject.isGeekModeEnabled{
            segmentControlGeekMode.setSelected(true, forSegment: 0)
        }else{
            segmentControlGeekMode.setSelected(true, forSegment: 1)
        }
    }
    func showUiView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getUIVcObject().view)
        self.containerView.addConstraints(subView: getUIVcObject().view)
    }
    
    func showAccesibilityView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAccessibilityVcObject().view)
        self.containerView.addConstraints(subView: getAccessibilityVcObject().view)
    }
    
    func showPomodoroSettingsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getPomodoroSettingsVcObject().view)
        self.containerView.addConstraints(subView: getPomodoroSettingsVcObject().view)
    }
    
    func showStrictnessView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        // for simple mode if strictness tab is selected and back button is clicked
        if leftMenuVcObj?.boxBlocks.isSelected ?? false{
            tabStrictnessContainerVcObj?.showStrictnessView()
            return;
        }
        //----------------------------------------------------//
        removeSubViews()
        self.containerView.addSubview(getStrictnessVcObject().view)
        self.containerView.addConstraints(subView: getStrictnessVcObject().view)
    }
    
    func showPasswordView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getPasswordVcObject().view)
        self.containerView.addConstraints(subView: getPasswordVcObject().view)
    }
    
    func showFrictionView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getFrictionVcObject().view)
        self.containerView.addConstraints(subView: getFrictionVcObject().view)
    }
    
    func showFocusBearModeView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getfocusBearModeVcObject().view)
        self.containerView.addConstraints(subView: getfocusBearModeVcObject().view)
    }
    
    
    func showBrowserTabLimiterView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getBrowserTabLimiterVcObject().view)
        self.containerView.addConstraints(subView: getBrowserTabLimiterVcObject().view)
    }
    
    func showBlockedUrlsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getBlockedUrlsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedUrlsVcObject().view)
    }
    
    func showBlockedAppsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getBlockedAppsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedAppsVcObject().view)
    }
    
    func showAlwaysAllowedAppsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAlwaysAllowedAppsVcObject().view)
        self.containerView.addConstraints(subView: getAlwaysAllowedAppsVcObject().view)
    }
    
    func showAiView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAiSettingNewVcObject().view)
        self.containerView.addConstraints(subView: getAiSettingNewVcObject().view)
    }
    
    func showAccountView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAccountVcObject().view)
        self.containerView.addConstraints(subView: getAccountVcObject().view)
    }
    
    func showUninstallView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
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
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAdvancedVcObject().view)
        self.containerView.addConstraints(subView: getAdvancedVcObject().view)
    }

    func showMeetingDetactionView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getMeetingDetactionVcObject().view)
        self.containerView.addConstraints(subView: getMeetingDetactionVcObject().view)
    }

    func showPrivacyView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getPrivacyVcObject().view)
        self.containerView.addConstraints(subView: getPrivacyVcObject().view)
    }
    
    
    func showMicroBreaksView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getMicroBreaksSettingsVcObject().view)
        self.containerView.addConstraints(subView: getMicroBreaksSettingsVcObject().view)
    }
    
    func showAddOnsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getAddOnsVcObject().view)
        self.containerView.addConstraints(subView: getAddOnsVcObject().view)
    }
    
    func showTodoListSettingView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getToDoListSettingsVcObject().view)
        self.containerView.addConstraints(subView: getToDoListSettingsVcObject().view)
    }
    
    func showResearchSettingView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getResearchVcObject().view)
        self.containerView.addConstraints(subView: getResearchVcObject().view)
    }

    func showTalkingClockView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getTalkingClockSettingsVcObject().view)
        self.containerView.addConstraints(subView: getTalkingClockSettingsVcObject().view)
    }

    func showKeyboardShortcutsView() {
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        let vc = getKeyboardShortcutsSettingsVcObject()
        vc.refreshLabels()
        self.containerView.addSubview(vc.view)
        self.containerView.addConstraints(subView: vc.view)
    }

    func showOfficeModeSettingsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showManagedPolicyInspection(); return }
        removeSubViews()
        self.containerView.addSubview(getOfficeModeSettingsVcObject().view)
        self.containerView.addConstraints(subView: getOfficeModeSettingsVcObject().view)
    }
}
