//
//  explainingPermissionsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/10/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class explainingPermissionsVc: NSViewController {

    @IBOutlet weak var imgViewBrowserPermission: NSImageView!
    @IBOutlet weak var imgViewSystemEventPermission: NSImageView!
    @IBOutlet weak var imgViewAccessibilityPermission: NSImageView!
    @IBOutlet weak var lblInfoBanner: NSTextField!
    @IBOutlet weak var lblPointBrowserPermission: NSTextField!
    @IBOutlet weak var lblPointSystemEventPermission: NSTextField!
    @IBOutlet weak var lblPointAccessibilityPermission: NSTextField!
    @IBOutlet weak var lblDescriptionBrowserPermission: NSTextField!
    @IBOutlet weak var lblDescriptionSystemEventPermission: NSTextField!
    @IBOutlet weak var lblDescriptionAccessibilityPermission: NSTextField!
    
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Grant permissions for distraction blocking"
        lblSubTitle.stringValue = "Focus Bear needs system permissions to enable distraction blocking:"
        lblPointAccessibilityPermission.stringValue = "Accessibility permissions:"
        lblDescriptionAccessibilityPermission.stringValue = "needed for Firefox support and to block distractions while a browser is in full screen mode."
        lblPointSystemEventPermission.stringValue = "System events permission:"
        lblDescriptionSystemEventPermission.stringValue = "needed to blur out distractions"
        lblPointBrowserPermission.stringValue = "Browser specific permissions:"
        lblDescriptionBrowserPermission.stringValue = "needed to redirect the browser to the blocked page when you visit a distracting site"
        lblInfoBanner.stringValue = "Your privacy is preserved (more on the next screen)"
        btnContinue.title = buttonContinueText
        
        if let dic = configjson.value(forKey: "explainingPermissionsVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblPointAccessibilityPermission.stringValue = dic.value(forKey: "pointAccessibilityPermission") as? String ?? lblPointAccessibilityPermission.stringValue
            lblDescriptionAccessibilityPermission.stringValue = dic.value(forKey: "descriptionAccessibilityPermission") as? String ?? lblDescriptionAccessibilityPermission.stringValue
            lblPointSystemEventPermission.stringValue = dic.value(forKey: "pointSystemEventPermission") as? String ?? lblPointSystemEventPermission.stringValue
            lblDescriptionSystemEventPermission.stringValue = dic.value(forKey: "descriptionSystemEventPermission") as? String ?? lblDescriptionSystemEventPermission.stringValue
            lblPointBrowserPermission.stringValue = dic.value(forKey: "pointBrowserPermission") as? String ?? lblPointBrowserPermission.stringValue
            lblDescriptionBrowserPermission.stringValue = dic.value(forKey: "descriptionBrowserPermission") as? String ?? lblDescriptionBrowserPermission.stringValue
            lblInfoBanner.stringValue = dic.value(forKey: "infoBannerText") as? String ?? lblInfoBanner.stringValue
        }
        
        allApiObject.capturePosthog(event: "explaining-permissions-shown", metadata: [:])
        addLog(text: "[user-action] explaining-permissions-shown")
    }
    
    var isBrowserPermissionGiven = false
    var isAccessibilityPermissionGiven = true
    var isSystemEventsPermissionGiven = true
    
    override func viewWillAppear() {
        isBrowserPermissionGiven = false
        isAccessibilityPermissionGiven = false
        isSystemEventsPermissionGiven = false
        
        imgViewBrowserPermission.image = NSImage(named: "validIconGray")
        imgViewAccessibilityPermission.image = NSImage(named: "validIconGray")
        imgViewSystemEventPermission.image = NSImage(named: "validIconGray")
        
        DispatchQueue.global().async { [self] in
            if let arrBrowsersInfo = UserDefaults.standard.object(forKey: kUserdefaultsAllBrowsersPermissionInfo) as? [[String : Any]]{
                for i in 0..<arrBrowsersInfo.count{
                    let info = arrBrowsersInfo[i]
                    let isEnabled = info["isEnabled"] as? Bool ?? false
                    if isEnabled{
                        isBrowserPermissionGiven = true
                        break;
                    }
                }
            }
            if isBrowserPermissionGiven{
                DispatchQueue.main.async {
                    self.imgViewBrowserPermission.image = NSImage(named: "validIcon")
                }
            }
            
            
            if !isAccessibilityEnabled(isPrompt: false){
                isAccessibilityPermissionGiven = false
            }else{
                isAccessibilityPermissionGiven = true
                DispatchQueue.main.async {
                    self.imgViewAccessibilityPermission.image = NSImage(named: "validIcon")
                }
            }
            
            if !checkAutomationPermissionWithAppleScript(){
                isSystemEventsPermissionGiven = false
            }else{
                isSystemEventsPermissionGiven = true
                DispatchQueue.main.async {
                    self.imgViewSystemEventPermission.image = NSImage(named: "validIcon")
                }
            }

        }
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "explaining-permissions-screen")
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] explainingPermissionsVc:- Button Continue clicked")
        menuViewControllerObj?.accessibilityPermissionGiven = isAccessibilityPermissionGiven
        menuViewControllerObj?.systemEventsPermissionGiven = isSystemEventsPermissionGiven
        menuViewControllerObj?.browserPermissionGiven = isBrowserPermissionGiven
        
        addLog(text: "Accessibility Permission Given:- \(isAccessibilityPermissionGiven)")
        addLog(text: "System Events Permission Given:- \(isSystemEventsPermissionGiven)")
        addLog(text: "Any Browser Permission Given:- \(isBrowserPermissionGiven)")
        
        if !self.isAccessibilityPermissionGiven{
            self.view.window?.contentViewController = getAccessibilityPermissionVcObject()
        }else if !self.isSystemEventsPermissionGiven{
            self.view.window?.contentViewController = getSystemEventsPermissionVcObject()
        }else if !self.isBrowserPermissionGiven{
            self.view.window?.contentViewController = getOnboardingControllingBrowserVcObject()
        }else{
            self.view.window?.contentViewController = getTryBlockUrlVcObject()
        }
    }
}

