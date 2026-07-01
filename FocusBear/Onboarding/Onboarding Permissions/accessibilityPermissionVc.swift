//
//  accessibilityPermissionVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 08/07/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa
import AVKit


class accessibilityPermissionVc: NSViewController {
    
    @IBOutlet weak var imgViewPermission: NSImageView!
    @IBOutlet weak var imgViewTick: NSImageView!
    @IBOutlet weak var imgViewBear: NSImageView!
    @IBOutlet weak var customViewProgress: NSView!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var btnSkip: underLineButton!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var bubbleView:BubbleView?
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    var moveToNextViewEnabled = false
    var timer:Timer?
    var accessibilityIndexinSubTitle = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        lblTitle.stringValue = "Grant Accessibility Permissions"
        if #available(macOS 13.0, *) {
            lblSubTitle.stringValue = "In order to interact with other browsers, you need to authorise Focus bear through System Preferences:\nSystem Preferences > Privacy & Security > Accessibility"
            accessibilityIndexinSubTitle = 2
        }else {
            lblSubTitle.stringValue = "In order to interact with other browsers, you need to authorise Focus bear through System Preferences:\nSystem Preferences > Security & Privacy > Privacy > Accessibility"
            accessibilityIndexinSubTitle = 3
        }
        
        lblDescription.stringValue = "Toggle Focus bear on."
        btnContinue.title = "Proceed"
        btnSkip.title = "Skip"
        
        
        
        if let info = configjson["accessibilityPermissionVcInfoNew"] as? [String: Any] {
            lblTitle.stringValue = info["title"] as? String ?? lblTitle.stringValue
            if #available(macOS 13.0, *) {
                lblSubTitle.stringValue = info["subTitleMacOS13"] as? String ?? lblSubTitle.stringValue
                accessibilityIndexinSubTitle = 2
            } else {
                lblSubTitle.stringValue = info["subTitleLegacy"] as? String ?? lblSubTitle.stringValue
                accessibilityIndexinSubTitle = 3
            }
            lblDescription.stringValue = info["description"] as? String ?? lblDescription.stringValue
            btnContinue.title = info["buttonContinue"] as? String ?? btnContinue.title
            btnSkip.title = info["buttonSkip"] as? String ?? btnSkip.title
        }
        
        
        //------------------------------------------------// bold Accessibility
        let pointFirstText = lblSubTitle.stringValue
        let startLocation = (getOccurrence(of: ">", in: pointFirstText, occurrenceCount: accessibilityIndexinSubTitle) ?? 5) + 1
        let endLocation = pointFirstText.count

        let attributedString = NSMutableAttributedString(string: pointFirstText)

        // Bold part
        let font = getBoldFont(size: lblSubTitle.font?.pointSize ?? 20)
        attributedString.addAttribute(.font, value: font, range: NSRange(location: startLocation, length: endLocation - startLocation))

        // Center alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

        lblSubTitle.attributedStringValue = attributedString
        
        //------------------------------------------------//
        
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.25)

        imgViewTick.isHidden = true

        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.5)

        // Make the System-Settings mock image a shortcut: clicking it opens the Accessibility pane
        // directly so the user doesn't have to navigate System Settings by hand. Tooltip + pointing-
        // hand cursor signal that it's clickable.
        imgViewPermission.toolTip = "Open Accessibility settings"
        imgViewPermission.addGestureRecognizer(
            NSClickGestureRecognizer(target: self, action: #selector(imgPermissionClicked)))
        imgViewPermission.addTrackingArea(
            NSTrackingArea(rect: .zero, options: [.activeAlways, .mouseEnteredAndExited, .inVisibleRect],
                           owner: self, userInfo: nil))

        // Explicit text link below the image — same action — for users who don't realise the image
        // itself is clickable.
        let linkText = (configjson["accessibilityPermissionVcInfoNew"] as? [String: Any])?["openSettingsLink"] as? String
            ?? "Open Accessibility settings"
        let openSettingsLink = NSButton(title: linkText, target: self, action: #selector(imgPermissionClicked))
        openSettingsLink.isBordered = false
        openSettingsLink.bezelStyle = .inline
        openSettingsLink.translatesAutoresizingMaskIntoConstraints = false
        openSettingsLink.attributedTitle = NSAttributedString(string: linkText, attributes: [
            .foregroundColor: NSColor(named: "dark_OrangeColor") ?? NSColor.systemOrange,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
        ])
        view.addSubview(openSettingsLink)
        NSLayoutConstraint.activate([
            openSettingsLink.centerXAnchor.constraint(equalTo: imgViewPermission.centerXAnchor),
            openSettingsLink.topAnchor.constraint(equalTo: imgViewPermission.bottomAnchor, constant: 8),
        ])
    }

    override func mouseEntered(with event: NSEvent) { NSCursor.pointingHand.set() }
    override func mouseExited(with event: NSEvent) { NSCursor.arrow.set() }

    /// Opens System Settings → Privacy & Security → Accessibility (matches firefoxPermissionsVc).
    @objc func imgPermissionClicked() {
        addLog(text: "[user-action] accessibilityPermissionVc:- permission image clicked → open Accessibility settings")
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "accessibility-permission-shown", metadata: [:])
        startTimerCheckPermission()
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "accessibility-permission-screen")
        
        // Show bubble
        
        var bubbleText = "We need this to block distractions in a browser while in Full Screen mode!"

        if let info = configjson["accessibilityPermissionVcInfoNew"] as? [String: Any] {
            bubbleText = info["bubbleText"] as? String ?? bubbleText
        }
        if bubbleView == nil{
            bubbleView = PopupManager.showPopup(for: imgViewBear, edge: .minX, selfView: self.view, text: bubbleText, verticalOffset: 30, horizontalOffset: 25, fontSize: 13)
        }
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    
    func getOccurrence(of char: Character, in string: String, occurrenceCount:Int) -> Int? {
        var count = 0
        
        for (index, currentChar) in string.enumerated() {
            if currentChar == char {
                count += 1
            }
            if count == occurrenceCount {
                return index
            }
        }
        
        // If the character doesn't appear twice
        return nil
    }
    
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] accessibilityPermissionVc:- Button Proceed clicked")
        if currentState == ._ONBOARDING_{
            getOnboardingVcObject().navigate(to: ._BROWSERS_PERMISSION_)
        }else{
            if !(menuViewControllerObj?.browserPermissionGiven ?? true){
                self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
            }else{
                self.view.window?.close()
            }
        }
    }
    
    func startTimerCheckPermission() {
        self.timer?.invalidate()
        self.timer = nil
        DispatchQueue.global().sync {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.performTimerCountCheckPermission), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timer!), forMode: RunLoop.Mode.common)
        }
        btnContinue.isEnabled = false
        checkPermission()
    }
    
    @objc func performTimerCountCheckPermission() {
        checkPermission()
    }
    
    func checkPermission(){
        if isAccessibilityEnabled(isPrompt: false){
            self.timer?.invalidate()
            menuViewControllerObj?.accessibilityPermissionGiven = true
            
            lblTitle.stringValue = "That was beary impressive!"
            lblSubTitle.stringValue = "Accessibility permissions have been granted."
            
            if let info = configjson["accessibilityPermissionVcInfoNew"] as? [String: Any] {
                lblTitle.stringValue = info["successTitle"] as? String ?? lblTitle.stringValue
                lblSubTitle.stringValue = info["successSubTitle"] as? String ?? lblSubTitle.stringValue
            }
            
            imgViewBear.isHidden = true
            bubbleView?.isHidden = true
            imgViewTick.isHidden = false
            imgViewPermission.alphaValue = 0.5
            lblDescription.isHidden = true
            moveToNextViewEnabled = true
            getDistractionBlockingProgressVcObj().setProgress(level: 3, progress: 0.75)
            btnContinue.isEnabled = true
            return;
        }
    }

    @IBAction func btnSkipClicked(_ sender: Any) {
        addLog(text: "[user-action] accessibilityPermissionVc:- btnSkipClicked")
        allApiObject.capturePosthog(event: "accessibility-permission-skipped", metadata: [:])
        if currentState == ._ONBOARDING_{
            getOnboardingVcObject().navigate(to: ._BROWSERS_PERMISSION_)
        }else{
            if !(menuViewControllerObj?.browserPermissionGiven ?? true){
                self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
            }else{
                self.view.window?.close()
                reloadPermissionsIfNeeded()
            }
        }
    }
}

