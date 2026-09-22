//
//  systemEventsPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 23/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

// Why the consent-prompt loop happened here:
//
// This screen used to detect the System Events Automation grant by polling
// checkAutomationPermissionWithAppleScript() on a 1-second repeating timer. That helper runs an
// AppleScript against System Events, and the AppleScript layer was switched to runAppleScriptSafely
// (which enforces a ~5s timeout). With the OS consent dialog still pending, each poll's script
// blocks, times out after ~5s, and the next tick fires another one — so the dialog kept being
// re-triggered / torn down, appearing then vanishing every couple of seconds in a loop.
//
// Fix: don't poll. Request the grant with a single BLOCKING
// AEDeterminePermissionToAutomateTarget(com.apple.systemevents, askUserIfNeeded: true) — it shows
// the dialog once and waits for the user's answer, no AppleScript involved. (Same fix as the
// browser-permission screen; see onboardingControllingBrowserVc.) System Events must be launched
// first or that call returns procNotFound (-600) — see ensureSystemEventsRunningForAutomation().
class systemEventsPermissionVc: NSViewController {
    
    @IBOutlet weak var btnImagePermission: cursorButton!
    @IBOutlet weak var imgViewPermission: NSImageView!
    @IBOutlet weak var imgViewTick: NSImageView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var btnContinue: underLineButton!
    @IBOutlet weak var btnGrantPermission: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    var permissionSet = false
    /// True while the blocking System-Events consent prompt is on screen — guards against
    /// re-requesting (which would stack/loop dialogs) on repeated taps.
    var isRequestInFlight = false
    /// After a denial we poll (non-prompting) so a manual toggle in System Settings reflects here.
    var grantPollTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        if #available(macOS 13.0, *) {
            lblDescription.stringValue = "If you've previously denied permission for system events, please open System Preferences, locate the Focus Bear icon under System Preferences > Privacy & Security > Automation, and toggle its checkbox on."
            if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
                lblDescription.stringValue = systemEventsPermissionVcInfo.value(forKey: "descriptionNewOs") as? String ?? lblDescription.stringValue
            }
        }else {
            lblDescription.stringValue = "If you've previously denied permission for system events, please open System Preferences, locate the Focus Bear icon under System Preferences > Security & Privacy > Privacy > Automation, and toggle its checkbox on."
            if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
                lblDescription.stringValue = systemEventsPermissionVcInfo.value(forKey: "descriptionOldOs") as? String ?? lblDescription.stringValue
            }
        }
        
        
        btnContinue.title = "I can't grant System Events Permissions"
        lblTitle.stringValue = "Grant System Events Permission"
        lblSubTitle.stringValue = "Clicking on the button below to bring up the prompt. Click on the allow button to grant permissions."
        btnGrantPermission.title = "Open System Events Permissions"
        
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            lblTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "titleNew") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "subTitleNew") as? String ?? lblSubTitle.stringValue
            btnGrantPermission.title = systemEventsPermissionVcInfo.value(forKey: "buttonOpenSettings") as? String ?? btnGrantPermission.title
            btnContinue.title = systemEventsPermissionVcInfo.value(forKey: "buttonCantGrantPermissionText") as? String ?? btnContinue.title
        }
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.25)

        imgViewTick.isHidden = true
        btnImagePermission.isHidden = false
    }
    
    override func viewWillAppear() {
        btnContinue.isHidden = true
        lblDescription.isHidden = true
        allApiObject.capturePosthog(event: "system-events-permission-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        // A granted background agent may have exited idle before this screen opened. Detect its
        // actual status without requiring another click or opening another consent dialog.
        startGrantPolling()
        showOnboardingBellIcon(view: self.view, screen: "system-events-permission-screen")
        
        // Show bubble
        var bubbleText = "We need this to blur out distractions!"
        if let info = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            bubbleText = info.value(forKey: "bubbleText") as? String ?? bubbleText
        }
        
        
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: 30, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    override func viewWillDisappear() {
        stopGrantPolling()
        hideOnboardingBellIcon(view: self.view)
    }
    
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "system-events-permission-not-granted", metadata: [:])
        addLog(text: "[user-action] systemEventsPermissionVc:- Button can't grant System Events Permissions clicked")
        var titlePermissionsNotGranted = "Got it! We'll look into this for you."
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            titlePermissionsNotGranted = systemEventsPermissionVcInfo.value(forKey: "titlePermissionsNotGranted") as? String ?? titlePermissionsNotGranted
        }
        
        if currentState == ._ONBOARDING_{
            getOnboardingVcObject().navigate(to: ._ACCESSIBILITY_PERMISSION_)
        }else{
            if !(menuViewControllerObj?.accessibilityPermissionGiven ?? true){
                self.view.window?.contentViewController = getAccessibilityPermissionVcObject()
            }else if !(menuViewControllerObj?.browserPermissionGiven ?? true){
                self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
            }else{
                self.view.window?.close()
                reloadPermissionsIfNeeded()
            }
        }
    }
    
    @IBAction func btnInfoClicked(_ sender: hoverInfoButton) {
        var msg = "We need System Events permission to: block distractions from full screen apps and to show a blur over distracting sites"
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            msg = systemEventsPermissionVcInfo.value(forKey: "toolTipText") as? String ?? msg
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230, autoCloseOnMouseExit: true)
    }
    
    @IBAction func btnGrantPermissionClicked(_ sender: Any) {
        if permissionSet{
            addLog(text: "[user-action] systemEventsPermissionVc:- Button Proceed clicked")
            if currentState == ._ONBOARDING_{
                getOnboardingVcObject().navigate(to: ._ACCESSIBILITY_PERMISSION_)
            }else{
                if !(menuViewControllerObj?.accessibilityPermissionGiven ?? true){
                    self.view.window?.contentViewController = getAccessibilityPermissionVcObject()
                }else if !(menuViewControllerObj?.browserPermissionGiven ?? true){
                    self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
                }else{
                    self.view.window?.close()
                    reloadPermissionsIfNeeded()
                }
            }
        }else{
            addLog(text: "[user-action] systemEventsPermissionVc:- Button Grant Permission clicked")
            requestSystemEventsPermission()
        }

    }

    /// Request System Events Automation permission with a single BLOCKING prompt: shows the OS
    /// consent dialog once and waits for the user's answer. Mirrors the browser-permission fix —
    /// polling with checkAutomationPermissionWithAppleScript() re-triggered/cancelled the dialog
    /// every tick (it runs AppleScript via runAppleScriptSafely, ~5s timeout), so the prompt kept
    /// showing then vanishing in a loop. isRequestInFlight guards against double-taps.
    func requestSystemEventsPermission() {
        guard !isRequestInFlight, beginSystemEventsAutomationRequest() else { return }
        stopGrantPolling()
        isRequestInFlight = true
        let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
        DispatchQueue.global().async {
            // AEDeterminePermissionToAutomateTarget returns procNotFound (-600) if the target app
            // isn't running. System Events is a faceless agent, so launch it and wait first.
            ensureSystemEventsRunningForAutomation()
            let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, true)
            DispatchQueue.main.async {
                self.isRequestInFlight = false
                finishSystemEventsAutomationRequest(status: status)
                guard self.isViewLoaded, self.view.window != nil else { return }
                if status == noErr {
                    addLog(text: "System Events automation granted")
                    self.applyGrantedState()
                } else {
                    addLog(text: "System Events explicit request completed: status=\(status) result=\(SystemEventsAutomationResult(status: status).rawValue)")
                    // Surface the help text + the "I can't grant" escape button, and start polling
                    // so a manual grant in System Settings (after this denial) reflects here.
                    self.lblDescription.isHidden = false
                    self.btnContinue.isHidden = false
                    self.startGrantPolling()
                }
            }
        }
    }

    /// After a denial, poll (WITHOUT prompting) so a manual toggle in System Settings > Privacy &
    /// Security > Automation is picked up here. This is safe — there is no consent dialog pending at
    /// this point (the blocking request already resolved), so AEDetermine(askUserIfNeeded:false)
    /// only reads the status and can't dismiss anything. The poll is skipped while another blocking
    /// request is in flight.
    func startGrantPolling() {
        stopGrantPolling()
        grantPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isRequestInFlight || isSystemEventsAutomationRequestInFlight || self.permissionSet { return }
            DispatchQueue.global().async {
                ensureSystemEventsRunningForAutomation()
                guard !isSystemEventsAutomationRequestInFlight else { return }
                let target = NSAppleEventDescriptor(bundleIdentifier: "com.apple.systemevents")
                let status = AEDeterminePermissionToAutomateTarget(target.aeDesc, typeWildCard, typeWildCard, false)
                recordSystemEventsAutomationStatus(status)
                if status == noErr {
                    DispatchQueue.main.async {
                        guard !self.permissionSet, !self.isRequestInFlight, self.isViewLoaded, self.view.window != nil else { return }
                        addLog(text: "System Events automation granted (detected via polling after manual change)")
                        self.applyGrantedState()
                    }
                }
            }
        }
    }

    func stopGrantPolling() {
        grantPollTimer?.invalidate()
        grantPollTimer = nil
    }

    /// Apply the "granted" UI (tick over the screenshot, progress, Proceed). Shared by the
    /// blocking request above (and previously the polling timer).
    func applyGrantedState() {
        stopGrantPolling()
        menuViewControllerObj?.systemEventsPermissionGiven = true
        self.getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.5)
        self.btnGrantPermission.title = "Proceed"
        lblTitle.stringValue = "Well done, sorting that with your bear hands!"
        lblSubTitle.stringValue = "Systems events permissions have been granted."

        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            lblTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "titlePermissionsGrantedNew") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "subTitlePermissionsGrantedNew") as? String ?? lblSubTitle.stringValue
            btnGrantPermission.title = systemEventsPermissionVcInfo.value(forKey: "buttonProceed") as? String ?? btnGrantPermission.title
        }

        imgViewTick.isHidden = false
        btnImagePermission.isHidden = true
        imgViewPermission.alphaValue = 0.5
        permissionSet = true
        imgViewBear.isHidden = true
        bubbleView?.isHidden = true
        btnInfo.isHidden = true
    }
    
    @IBAction func btnImagePermissionClicked(_ sender: Any) {
        if imgViewTick.isHidden{
            btnGrantPermissionClicked(self)
        }
    }
    
}
