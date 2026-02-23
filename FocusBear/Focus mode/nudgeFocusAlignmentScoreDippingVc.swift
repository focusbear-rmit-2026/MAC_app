//
//  nudgeFocusAlignmentScoreDippingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class nudgeFocusAlignmentScoreDippingVc: NSViewController {

    @IBOutlet weak var boxTimer: NSBox!
    @IBOutlet weak var lblTimer: NSTextField!
    @IBOutlet weak var btnExpandTaskPlayer: NSButton!
    @IBOutlet weak var lblDescriptionText: NSTextField!
    @IBOutlet weak var boxButton: NSBox!
    @IBOutlet weak var btnClose: NSButton!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblCurrentTask: NSTextField!
    
    var trackingArea: NSTrackingArea?
    var trackingAreaExpandButton: NSTrackingArea?
    var trackingAreaAlignmentScore: NSTrackingArea?
    var timerStopAniumation:Timer?
    var isScoreLow = true
    var lastScoreShown:Double = -1
    var isScoreFallingDown = true
    var isFloatingTopBarRemovedByNudge = false
    var arrAlignmentScoreDown = ["Drifting off track—let’s bring it back.",
                "That’s a detour, but your focus is still within reach.",
                "Distraction’s creeping in—time to reset.",
                "Looks like your attention is slipping—let’s refocus.",
                "That wasn’t part of the plan—time to lock back in.",
                "Your momentum’s slowing—time to get back in the zone.",
                "A little off course, but you can still steer it back.",
                "Your focus is wavering—let’s steady it.",
                "Distractions are pulling you away—let’s get back on track.",
                "That’s not where your attention needs to be—time to reset."]
    
    var arrAlignmentScoreUp = ["Solid comeback—back in the zone.",
                                 "That’s the way—focus mode activated.",
                                 "You’re locked in again—keep it going.",
                                 "Momentum restored—great job.",
                                 "That’s how it’s done—keep crushing it.",
                                 "Smooth recovery—right back on track.",
                                 "You snapped back into focus—love to see it.",
                                 "Distraction defeated—you’re in control.",
                                 "Nice reset—you’re making progress again.",
                                 "Back in the groove—stay with it."]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblFocusAlignmentScore.stringValue = "Focus Alignment Score: 95%"
        boxButton.wantsLayer = true
        boxButton.layer?.cornerRadius = 9
        
        trackingArea = NSTrackingArea.init(rect: self.view.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.view.addTrackingArea(trackingArea!)
        
        trackingAreaExpandButton = NSTrackingArea.init(rect: self.btnExpandTaskPlayer.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.btnExpandTaskPlayer.addTrackingArea(trackingAreaExpandButton!)
        
        
        trackingAreaAlignmentScore = NSTrackingArea.init(rect: self.lblFocusAlignmentScore.bounds, options: [NSTrackingArea.Options.mouseEnteredAndExited, NSTrackingArea.Options.activeAlways], owner: self, userInfo: nil)
        self.lblFocusAlignmentScore.addTrackingArea(trackingAreaAlignmentScore!)
        
        
        if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
            arrAlignmentScoreDown = info.value(forKey: "arrayAlignmentScoreDown") as? [String] ?? arrAlignmentScoreDown
            arrAlignmentScoreUp = info.value(forKey: "arrayAlignmentScoreUp") as? [String] ?? arrAlignmentScoreUp
            lblFocusAlignmentScore.stringValue = info.value(forKey: "focusAlignmentScoreText") as? String ?? lblFocusAlignmentScore.stringValue
        }
        boxButton.isHidden = false
    }
    
    override func viewWillAppear() {
        
    }
    
    @objc func stopAnimatingImageview(){
        imgView.animates = false
    }
    
    override func mouseEntered(with event: NSEvent) {
//        if event.trackingArea == self.trackingArea{
//            boxButton.isHidden = false
//        }else
        //Floating bear tooltip appears on mouseover when popup is closed #1604
        if self.view.window?.alphaValue == 0{ //v 2.28.447
            return;
        }
        if event.trackingArea == self.trackingAreaExpandButton{
            var toolTipShowToDoPlayer = "Show To Do Player"
            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
                toolTipShowToDoPlayer = info.value(forKey: "toolTipShowToDoPlayer") as? String ?? toolTipShowToDoPlayer
            }
            showTooltip(sender: btnExpandTaskPlayer, msg: toolTipShowToDoPlayer, preferredEdge: .maxY, maxWidthVal: 200, autoCloseOnMouseExit: true)
        }else if event.trackingArea == self.trackingAreaAlignmentScore{
            var toolTipAlignmentScore = "This shows what % of the time you've been on websites/apps that are relevant to your focus goal. We use AI to check the relevance."
            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
                toolTipAlignmentScore = info.value(forKey: "toolTipAlignmentScore") as? String ?? toolTipAlignmentScore
            }
            showTooltip(sender: lblFocusAlignmentScore, msg: toolTipAlignmentScore, preferredEdge: .maxY, maxWidthVal: 200, autoCloseOnMouseExit: true)
        }
    }
    
    override func mouseExited(with event: NSEvent) {
//        if event.trackingArea == self.trackingArea{
//            boxButton.isHidden = true
//        }else
        if event.trackingArea == self.trackingAreaExpandButton{
            closePopoverTooltipIfVisible()
        }else if event.trackingArea == self.trackingAreaAlignmentScore{
            closePopoverTooltipIfVisible()
        }
    }
    
    func reloadData(score:Double, isNudgeVisible:Bool){////if isFocusModeRunning || isAnyAllowedFocusModeActivityRunning || customBlockingScheduleManagerObj.isAnyCustomScheduleOn{
        var scoreText = "Focus Alignment Score: \(score)%"
        if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
            scoreText = info.value(forKey: "focusAlignmentScoreText") as? String ?? scoreText
        }
        lblFocusAlignmentScore.stringValue = scoreText.replacingOccurrences(of: "<SCORE>", with: "\(score)")
        
        
        if score < minFocusAlignmentScoreToShowDistractingPopUp{
            imgView.image = NSImage(named: "Glasses-Bear-250-px_V3")
            isScoreLow = true
        }else{
            imgView.image = NSImage(named: "cheer_250px_trans_centered")
            if isScoreLow{
                isScoreLow = false
                setTimerStopAniumation()
            }
        }
        
        if isNudgeVisible{
            if score == lastScoreShown{
                /// do nothing 
            }else if score <= lastScoreShown && score < minFocusAlignmentScoreToShowDistractingPopUp{
                if !isScoreFallingDown{
                    lblDescriptionText.stringValue = arrAlignmentScoreDown.randomElement() ?? ""
                    isScoreFallingDown = true
                }
            }else{
                if isScoreFallingDown{
                    lblDescriptionText.stringValue = arrAlignmentScoreUp.randomElement() ?? ""
                    isScoreFallingDown = false
                }
            }
        }else{
            isScoreFallingDown = true
            if score < minFocusAlignmentScoreToShowDistractingPopUp{
                lblDescriptionText.stringValue = arrAlignmentScoreDown.randomElement() ?? ""
            }else{
                lblDescriptionText.stringValue = "You're back on track."
            }
        }
        
        lastScoreShown = score
        var currentTaskText = "Current task is \"<TASK>\""
        if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
                currentTaskText = info.value(forKey: "currentTaskText") as? String ?? currentTaskText
            }
            lblCurrentTask.stringValue = currentTaskText.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
        }else{
            lblCurrentTask.stringValue = "No Current Task"
            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
                lblCurrentTask.stringValue = info.value(forKey: "noCurrentTaskText") as? String ?? lblCurrentTask.stringValue
            }
        }
        
        if !SettingsManagerObject.isAIBlockingEnabled() || isBlockSuperDistractingFocusModeOn(){
            lblDescriptionText.stringValue = "AI is not enabled."
            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
                lblDescriptionText.stringValue = info.value(forKey: "aiIsDisabledText") as? String ?? lblDescriptionText.stringValue
            }
        }
//        else if !isCuddlyModeEnabled(){
//            lblDescriptionText.stringValue = "AI score not calculated."
//            if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
//                lblDescriptionText.stringValue = info.value(forKey: "aiScoreNotCalculatedText") as? String ?? lblDescriptionText.stringValue
//            }
//        }
        
        if isFocusModeRunning && endFocusModeTime != nil{
            boxTimer.isHidden = false
        }else{
            boxTimer.isHidden = true
        }
    }
    
    func setTimerStopAniumation(){
        timerStopAniumation?.invalidate()
        timerStopAniumation = nil
        imgView.animates = true
        
        timerStopAniumation = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(stopAnimatingImageview), userInfo: nil, repeats: false)
    }
    
    @IBAction func btnClicked(_ sender: Any) {
        nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
        
//        /If the big floating bear is open, I don’t think we need the little one as well.
        
        //check AnyNotificationVisible
        var anyNotificationVisibleInFloatingBear = false
        if floatingTopBarVcObj != nil{
            let visibleViews = floatingTopBarVcObj!.stackViewMoreItems.arrangedSubviews.filter { !$0.isHidden }
            if visibleViews.count != 0{
                anyNotificationVisibleInFloatingBear = true
            }
        }
        
//        Floating bear shouldn't show when you close the bigger bear with focus alignment score #1574
        if anyNotificationVisibleInFloatingBear || isFloatingTopBarRemovedByNudge{// check added in v2.28.440
            if floatingTopBarWcObj != nil && !isFocusBearMenuVisible(){
                if getFloatingTopBarWObject().window?.isVisible ?? false{
                    getFloatingTopBarVObject().boxMain.isHidden = false
                    getFloatingTopBarVObject().boxMoreItems.isHidden = false
                }
            }
        }
        isFloatingTopBarRemovedByNudge = false
    }
    
    @IBAction func btnExpandTaskPlayerClicked(_ sender: Any) {
        menuViewControllerObj?.openToDoListClicked()
    }
}
