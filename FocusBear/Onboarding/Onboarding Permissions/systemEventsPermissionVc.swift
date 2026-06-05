//
//  systemEventsPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 23/09/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

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
    
    var currentTimer = 0
    var totalDuration = 0
    var timer:Timer?
    func startTimer() {
        totalDuration = 10
        self.timer?.invalidate()
        self.timer = nil
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCount), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
    }
    @objc func performTimerCount() {
        currentTimer += 1
        DispatchQueue.main.async { [self] in
            if checkAutomationPermissionWithAppleScript() {
                self.timer?.invalidate()
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
            } else {
                print("Automation permission for System Events is not granted.")
            }
        }
        if currentTimer >= 5{
            self.lblDescription.isHidden = false
        }
        if currentTimer >= totalDuration{
            DispatchQueue.main.async {
                self.timer?.invalidate()
                self.btnContinue.isHidden = false
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
            startTimer()
            if checkAutomationPermissionWithAppleScript() {
                print("Automation permission for System Events is granted.")
            } else {
                print("Automation permission for System Events is not granted.")
            }
        }
        
    }
    
    @IBAction func btnImagePermissionClicked(_ sender: Any) {
        if imgViewTick.isHidden{
            btnGrantPermissionClicked(self)
        }
    }
    
}
