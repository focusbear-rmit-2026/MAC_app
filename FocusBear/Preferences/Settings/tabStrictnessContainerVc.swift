//
//  tabStrictnessContainerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/04/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class tabStrictnessContainerVc: NSViewController {

    @IBOutlet weak var segmentControlGeekMode: GeekModeSegmentedControl!
    @IBOutlet weak var containerView: NSView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLog(text: "tabStrictnessContainerVc viewdidload")
    }
    
    override func viewWillAppear() {
        showStrictnessView()
    }
    
    override func viewWillDisappear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
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
    
    func showStrictnessView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getStrictnessVcObject().view)
        self.containerView.addConstraints(subView: getStrictnessVcObject().view)
    }

    func showBrowserTabLimiterView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getBrowserTabLimiterVcObject().view)
        self.containerView.addConstraints(subView: getBrowserTabLimiterVcObject().view)
    }
    
    func showBlockedUrlsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getBlockedUrlsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedUrlsVcObject().view)
    }
    
    func showBlockedAppsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getBlockedAppsVcObject().view)
        self.containerView.addConstraints(subView: getBlockedAppsVcObject().view)
    }
    
    func showAlwaysAllowedAppsView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getAlwaysAllowedAppsVcObject().view)
        self.containerView.addConstraints(subView: getAlwaysAllowedAppsVcObject().view)
    }
    
    func showCustomBlockingSchedulesView(){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getCustomBlockingSchedulesVcObject().view)
        self.containerView.addConstraints(subView: getCustomBlockingSchedulesVcObject().view)
        getCustomBlockingSchedulesVcObject().tblView.reloadData()
        getCustomBlockingSchedulesVcObject().refreshData()
    }

    func showBlockingSchedulesView(index:Int, shouldCreateNew:Bool){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        removeSubViews()
        self.containerView.addSubview(getBlockingScheduleEditorVCObject().view)
        self.containerView.addConstraints(subView: getBlockingScheduleEditorVCObject().view)
        getBlockingScheduleEditorVCObject().resetData(index: index, shouldCreateNew: shouldCreateNew)
    }

    /// Open the editor pre-filled for a schedule drag-created on the calendar.
    func showBlockingScheduleEditorPrefilled(weekday:Int, startMinutes:Int, endMinutes:Int){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        let editor = getBlockingScheduleEditorVCObject()
        editor.prefillDays = [weekday]
        editor.prefillStart = customBlockingSchedule.parseTime(BlockingScheduleStore.hhmm(fromMinutes: startMinutes))
        editor.prefillEnd = customBlockingSchedule.parseTime(BlockingScheduleStore.hhmm(fromMinutes: endMinutes))
        removeSubViews()
        self.containerView.addSubview(editor.view)
        self.containerView.addConstraints(subView: editor.view)
        editor.resetData(index: -1, shouldCreateNew: true)
    }

    /// Open the editor pre-filled from a Quick-Start preset.
    func showBlockingScheduleEditorPreset(_ preset: SchedulePreset){
        if ManagedBlockingRuntime.shared.isSettingsLocked { showFocusPreferences(); return }
        let editor = getBlockingScheduleEditorVCObject()
        if !preset.isCustom {
            editor.prefillName = preset.name
            editor.prefillDays = preset.days
            editor.prefillStart = customBlockingSchedule.parseTime(BlockingScheduleStore.hhmm(fromMinutes: preset.startMinutes))
            editor.prefillEnd = customBlockingSchedule.parseTime(BlockingScheduleStore.hhmm(fromMinutes: preset.endMinutes))
            editor.prefillStrictness = preset.strictness
            editor.prefillEmoji = preset.emoji
        }
        removeSubViews()
        self.containerView.addSubview(editor.view)
        self.containerView.addConstraints(subView: editor.view)
        editor.resetData(index: -1, shouldCreateNew: true)
    }
    
    func showFocusPreferences(){
        removeSubViews()
        if focusPreferencesVcObj == nil{
            getFocusPreferencesVcObject().loadView()
        }
        getFocusPreferencesVcObject().btnBackToCustomBlocking.isHidden = true
        getFocusPreferencesVcObject().btnBack.isHidden = false
        self.containerView.addSubview(getFocusPreferencesVcObject().view)
        self.containerView.addConstraints(subView: getFocusPreferencesVcObject().view)
    }
}

