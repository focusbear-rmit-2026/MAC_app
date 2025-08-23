//
//  nudgeFocusAlignmentScoreDippingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/01/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class nudgeFocusAlignmentScoreDippingVc: NSViewController {

    @IBOutlet weak var btnExpandTaskPlayer: NSButton!
    @IBOutlet weak var lblDescriptionText: NSTextField!
    @IBOutlet weak var boxButton: NSBox!
    @IBOutlet weak var btnClose: NSButton!
    @IBOutlet weak var lblFocusAlignmentScore: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblCurrentTask: NSTextField!
    
    var trackingArea: NSTrackingArea?
    var trackingAreaExpandButton: NSTrackingArea?
    var timerStopAniumation:Timer?
    var isScoreLow = true
    var lastScoreShown:Double = -1
    var isScoreFallingDown = true
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
        
        if let info = configjson.value(forKey: "nudgeFocusAlignmentScoreDippingVcInfo") as? NSDictionary{
            arrAlignmentScoreDown = info.value(forKey: "arrayAlignmentScoreDown") as? [String] ?? arrAlignmentScoreDown
            arrAlignmentScoreUp = info.value(forKey: "arrayAlignmentScoreUp") as? [String] ?? arrAlignmentScoreUp
            lblFocusAlignmentScore.stringValue = info.value(forKey: "focusAlignmentScoreText") as? String ?? lblFocusAlignmentScore.stringValue
        }
        
    }
    
    override func viewWillAppear() {
        
    }
    
    @objc func stopAnimatingImageview(){
        imgView.animates = false
    }
    
    override func mouseEntered(with event: NSEvent) {
        if event.trackingArea == self.trackingArea{
            boxButton.isHidden = false
        }else if event.trackingArea == self.trackingAreaExpandButton{
            showTooltip(sender: btnExpandTaskPlayer, msg: "Show To Do Player", preferredEdge: .maxY, maxWidthVal: 200) // todo text
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if event.trackingArea == self.trackingArea{
            boxButton.isHidden = true
        }else if event.trackingArea == self.trackingAreaExpandButton{
            closePopoverTooltipIfVisible()
        }
    }
    
    func reloadData(score:Double, isNudgeVisible:Bool){
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
        var currentTaskText = "Current task is \"<TASK>\"" // todo text
        if let currentTaskInToDoPlayer = getCurrentTaskInFocusMode(){
            lblCurrentTask.stringValue = currentTaskText.replacingOccurrences(of: "<TASK>", with: currentTaskInToDoPlayer)
        }else{
            lblCurrentTask.stringValue = "No Current Task"
        }
        
        
        if !isCuddlyModeEnabled() || !SettingsManagerObject.isAiCheckUrlEnabled || isBlockSuperDistractingFocusModeOn(){
            lblDescriptionText.stringValue = "AI is not enabled." // todo text
        }
    }
    
    func setTimerStopAniumation(){
        timerStopAniumation?.invalidate()
        timerStopAniumation = nil
        boxButton.isHidden = true
        imgView.animates = true
        
        timerStopAniumation = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(stopAnimatingImageview), userInfo: nil, repeats: false)
    }
    
    @IBAction func btnClicked(_ sender: Any) {
        nudgeFocusAlignmentScoreDippingWcObject?.toggleMenu()
        
//        /If the big floating bear is open, I don’t think we need the little one as well.
        if floatingTopBarWcObj != nil && !isFocusBearMenuVisible(){
            if getFloatingTopBarWObject().window?.isVisible ?? false{
                getFloatingTopBarVObject().boxMain.isHidden = false
                getFloatingTopBarVObject().boxMoreItems.isHidden = false
            }
        }
    }
    @IBAction func btnExpandTaskPlayerClicked(_ sender: Any) {
        menuViewControllerObj?.openToDoListClicked()
    }
}
