//
//  floatingTopBarVc.swift
//  FocusBear
//
//  Created by Manish Jain on 21/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class floatingTopBarVc: NSViewController {

    @IBOutlet weak var stackViewMoreItems: NSStackView!
    @IBOutlet weak var lblScheduleTime: NSTextField!
    @IBOutlet weak var lblScheduleName: NSTextField!
    @IBOutlet weak var boxCustomBlockingSchedule: customBoxBg!
    @IBOutlet weak var widthBoxMain: NSLayoutConstraint!
    @IBOutlet weak var boxTimerSmall: NSBox!
    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var boxMain: NSBox!
    @IBOutlet weak var topSpaceMainBox: NSLayoutConstraint!
    @IBOutlet weak var boxFakeView: NSBox!
    @IBOutlet weak var boxMoreItems: NSBox!
    
    
    var normalWidth:CGFloat = 205
    var boxMainTrackingArea: NSTrackingArea?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        boxMainTrackingArea = NSTrackingArea.init(rect: boxMain.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        boxMain.addTrackingArea(boxMainTrackingArea!)
        boxTimer.isHidden = true
        boxCustomBlockingSchedule.isHidden = true
        normalWidth = self.view.frame.width
    }
    
    @IBAction func btnBarClicked(_ sender: Any) {
        appdelegate!.togglePopover(false)
        appdelegate!.menuOpenedFromFloatingBar = true// always next to togglepopover
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == boxMainTrackingArea{
//            isCustomBarIsInFocus = true
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == boxMainTrackingArea{
//            isCustomBarIsInFocus = false
        }
    }
    @IBAction func btnCloseClicked(_ sender: Any) {
        boxMain.isHidden = true
        boxMoreItems.isHidden = true
    }
    
    func timerBoxClosed(){
        widthBoxMain.constant = normalWidth
    }
    
    func timerBoxShown(){
        widthBoxMain.constant = normalWidth + 100
    }
    
    func showTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool, currentTimerValue:Int){
        if !getsmallCountDownVcObject().isViewLoaded{
            getsmallCountDownVcObject().loadView()
        }
        if !boxTimerSmall.subviews.contains(getsmallCountDownVcObject().view){
            boxTimerSmall.addSubview(getsmallCountDownVcObject().view)
            boxTimerSmall.addConstraints(subView: getsmallCountDownVcObject().view)
        }
        boxTimer.isHidden = false
        smallCountDownVcObj?.isFocusBreak = isFocusBreak
        smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, msg: msg, currentTimerValue:currentTimerValue)
        timerBoxShown()
    }
}
