//
//  floatingTopBarVc.swift
//  FocusBear
//
//  Created by Manish Jain on 21/08/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//


import Cocoa

class floatingTopBarVc: NSViewController {

    @IBOutlet weak var imgViewSmallAppIcon: NSImageView!
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

        boxTimer.isHidden = true
        boxCustomBlockingSchedule.isHidden = true
        normalWidth = self.view.frame.width
        
        imgViewSmallAppIcon.image = NSImage(named: "Bear-Small")
        describeControlsForAccessibility()
    }

    /// The bar's buttons come from the storyboard with no titles, so VoiceOver announced them only as
    /// "button". The whole bar and the round bear-icon group both open the menu, and each is named:
    /// the accessibility audit still reached the icon group's button, unnamed, when it was only
    /// excluded. The bear image under it is decoration — VoiceOver read its asset name — and the
    /// "↓" is drawing only (it has no action).
    private func describeControlsForAccessibility() {
        hideFromAccessibility(imgViewSmallAppIcon)
        for button in buttons(in: view) {
            switch button.action {
            case #selector(btnBarClicked(_:)):
                button.setAccessibilityLabel(menuLocalized(Self.openMenuLabelKey, Self.openMenuLabelFallback))
            case #selector(btnCloseClicked(_:)):
                button.setAccessibilityLabel(menuLocalized(Self.hideBarLabelKey, Self.hideBarLabelFallback))
            case nil:
                hideFromAccessibility(button)
            default:
                break
            }
        }
    }

    /// AppKit can expose a storyboard control through its cell as well as the view, so both are excluded.
    private func hideFromAccessibility(_ control: NSControl) {
        control.setAccessibilityElement(false)
        control.cell?.setAccessibilityElement(false)
    }

    private func buttons(in root: NSView) -> [NSButton] {
        root.subviews.flatMap { ([$0 as? NSButton].compactMap { $0 }) + buttons(in: $0) }
    }

    private static let openMenuLabelKey = "a11yOpenFocusBearMenu"
    private static let openMenuLabelFallback = "Open Focus Bear menu"   // i18n-ignore: last-resort default; the real string comes from config
    private static let hideBarLabelKey = "a11yHideFloatingBar"
    private static let hideBarLabelFallback = "Hide this bar"   // i18n-ignore: last-resort default; the real string comes from config
    
    @IBAction func btnBarClicked(_ sender: Any) {
        appdelegate!.togglePopover(false)
        appdelegate!.menuOpenedFromFloatingBar = true// always next to togglepopover
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
    
    func showTimerWindow(durationSeconds: Int, msg: String, isFocusBreak:Bool, currentTimerValue:Int, hideWindow: Bool = false){
        if !getsmallCountDownVcObject().isViewLoaded{
            getsmallCountDownVcObject().loadView()
        }
        if !boxTimerSmall.subviews.contains(getsmallCountDownVcObject().view){
            boxTimerSmall.addSubview(getsmallCountDownVcObject().view)
            boxTimerSmall.addConstraints(subView: getsmallCountDownVcObject().view)
        }
        smallCountDownVcObj?.suppressPopupForAllowedAppHabit = hideWindow
        // Allowed-app habits show their progress + Skip/Postpone in the menu now, so keep the floating
        // timer popup hidden DURING the habit. It's only made invisible (alpha 0, still on-screen) — not
        // ordered out — so the 2-minutes-left reminder in performTimerCount can reveal it again. The
        // timer keeps running the whole time (drives completion + return to routine).
        boxTimer.isHidden = false
        smallCountDownVcObj?.isFocusBreak = isFocusBreak
        smallCountDownVcObj?.startTimerHabit(durationSeconds: durationSeconds, msg: msg, currentTimerValue:currentTimerValue)
        timerBoxShown()
    }
    
    func showRecordingGif(){
        imgViewSmallAppIcon.image = NSImage(named: "fb_recording")
    }
    
    func hideRecordingGif(){
        imgViewSmallAppIcon.image = NSImage(named: "Bear-Small")
    }
}
