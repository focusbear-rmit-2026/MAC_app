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
        removeSubViews()
        self.containerView.addSubview(getStrictnessVcObject().view)
        self.containerView.addConstraints(subView: getStrictnessVcObject().view)
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
    
//    func showBlockingScheduleView(){
//        removeSubViews()
//        self.containerView.addSubview(getBlockingScheduleVcObject().view)
//        self.containerView.addConstraints(subView: getBlockingScheduleVcObject().view)
//    }
    
    func showCustomBlockingSchedulesView(){
        removeSubViews()
        self.containerView.addSubview(getCustomBlockingSchedulesVcObject().view)
        self.containerView.addConstraints(subView: getCustomBlockingSchedulesVcObject().view)
        getCustomBlockingSchedulesVcObject().tblView.reloadData()
    }
    
    func showBlockingSchedulesView(index:Int, shouldCreateNew:Bool){
        removeSubViews()
        self.containerView.addSubview(getBlockingScheduleEditorVCObject().view)
        self.containerView.addConstraints(subView: getBlockingScheduleEditorVCObject().view)
        getBlockingScheduleEditorVCObject().resetData(index: index, shouldCreateNew: shouldCreateNew)
    }
}

