//
//  systemEventsPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 23/09/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class systemEventsPermissionVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var btnContinue: underLineButton!
    @IBOutlet weak var btnGrantPermission: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
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
        lblTitle.stringValue = "Grant permissions to block distractions"
        lblSubTitle.stringValue = "Focus Bear requires access to System events to block distracting websites."
        btnGrantPermission.title = "Grant System Events permission now"
        
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            lblTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = systemEventsPermissionVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnGrantPermission.title = systemEventsPermissionVcInfo.value(forKey: "buttonGrantPermissionText") as? String ?? btnGrantPermission.title
            btnContinue.title = systemEventsPermissionVcInfo.value(forKey: "buttonCantGrantPermissionText") as? String ?? btnContinue.title
        }
        allApiObject.capturePosthog(event: "system-events-permission-shown", metadata: [:])
        addLog(text: "[user-action] system-events-permission-shown")
    }
    
    override func viewWillAppear() {
        btnContinue.isHidden = true
        lblDescription.isHidden = true
    }
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 18)
        showOnboardingBellIcon(view: self.view, screen: "system-events-permission-screen")
        welcomeOnboardingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
        welcomeOnboardingWcObj?.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.modalPanelWindow)))
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] systemEventsPermissionVc:- Button can't grant System Events Permissions clicked")
        var titlePermissionsNotGranted = "Got it! We'll look into this for you."
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            titlePermissionsNotGranted = systemEventsPermissionVcInfo.value(forKey: "titlePermissionsNotGranted") as? String ?? titlePermissionsNotGranted
        }
        self.showAlert(title: titlePermissionsNotGranted)
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
        DispatchQueue.main.async {
            if checkAutomationPermissionWithAppleScript() {
                self.timer?.invalidate()
                var titlePermissionsGranted = "Great, you just allowed System Events permissions."
                if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
                    titlePermissionsGranted = systemEventsPermissionVcInfo.value(forKey: "titlePermissionsGranted") as? String ?? titlePermissionsGranted
                }
                self.showAlert(title: titlePermissionsGranted)
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
    
    func showAlert(title:String){
        let alert = NSAlert()
        alert.setSharingType()
        
        var infoText = "On the next screen we will ask permissions to block distractions in browsers."
        
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            infoText = systemEventsPermissionVcInfo.value(forKey: "nextViewInfoText") as? String ?? infoText
        }
        
        alert.messageText = title + "\n" + infoText
        alert.addButton(withTitle: buttonOkText)
        NSApplication.shared.activate(ignoringOtherApps: true)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { result in
            if !self.btnContinue.isHidden{
                allApiObject.capturePosthog(event: "system-events-permission-not-granted", metadata: [:])
            }
            self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
        })
    }
    
    @IBAction func btnInfoClicked(_ sender: hoverInfoButton) {
        var msg = "We need System Events permission to: block distractions from full screen apps and to show a blur over distracting sites"
        if let systemEventsPermissionVcInfo = configjson.value(forKey: "systemEventsPermissionVcInfo") as? NSDictionary{
            msg = systemEventsPermissionVcInfo.value(forKey: "toolTipText") as? String ?? msg
        }
        showTooltip(sender: sender, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
    
    @IBAction func btnGrantPermissionClicked(_ sender: Any) {
        addLog(text: "[user-action] systemEventsPermissionVc:- Button Grant Permission clicked")
        startTimer()
        if checkAutomationPermissionWithAppleScript() {
            print("Automation permission for System Events is granted.")
        } else {
            print("Automation permission for System Events is not granted.")
        }
    }
}
