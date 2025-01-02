//
//  explainingPermissionsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 03/10/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class explainingPermissionsVc: NSViewController {

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
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 10)
        showOnboardingBellIcon(view: self.view, screen: "explaining-permissions-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] explainingPermissionsVc:- Button Continue clicked")
        self.view.window?.contentViewController = getAccessibilityPermissionVcObject()
    }
}

