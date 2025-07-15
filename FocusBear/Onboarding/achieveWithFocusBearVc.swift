//
//  achieveWithFocusBearVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 16/08/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class achieveWithFocusBearVc: NSViewController, NSTextViewDelegate {

    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        btnContinue.title = "Continue"
        lblTitle.stringValue = "What do you want to achieve with Focus Bear?"
        //lblSubTitle.stringValue = "How do you want your life to change from using Focus Bear?"
        
        if let achieveWithFocusBearVcInfo = configjson.value(forKey: "achieveWithFocusBearVcInfo") as? NSDictionary{
            lblTitle.stringValue = achieveWithFocusBearVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
           // lblSubTitle.stringValue = achieveWithFocusBearVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            btnContinue.title = achieveWithFocusBearVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        textView.delegate = self
        btnContinue.isEnabled = false
    }
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "what-to-achieve-with-focus-bear-screen")
        textView.window?.makeFirstResponder(textView)
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        var msg = "We’ll save this as a long term goal for you - it will also help us understand what you’re expecting so we can improve the app"
        if let askOccupationVcInfo = configjson.value(forKey: "achieveWithFocusBearVcInfo") as? NSDictionary{
            msg = askOccupationVcInfo.value(forKey: "infoText") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:300)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] achieve With FocusBear view:- button Continue clicked.")
        allApiObject.capturePosthog(event: "custom-goal-selected", metadata: ["custom-goal":textView.string])
        UserDefaults.standard.set(textView.string, forKey: kUserDefaultsCustomGoals)
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showAskAppWorkVc()
    }
    func textDidChange(_ notification: Notification) {
        if let textView = notification.object as? NSTextView{
            if textView == self.textView{
                if textView.string.isEmpty{
                    btnContinue.isEnabled = false
                }else{
                    btnContinue.isEnabled = true
                }
            }
        }
    }
}
