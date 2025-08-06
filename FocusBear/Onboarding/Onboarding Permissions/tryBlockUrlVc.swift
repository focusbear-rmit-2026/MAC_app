//
//  tryBlockUrlVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class tryBlockUrlVc: NSViewController {

    @IBOutlet weak var btnClickOpenUrl: underLineButton!
    @IBOutlet weak var btnLeft: Button!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    
    enum CURRENTBLOCKSTATE:Int{
        case _NOTHING_ = 111, _DID_NOT_WORKED_
    }
    var tryBlockState:CURRENTBLOCKSTATE = ._NOTHING_
    var blockedUrlString = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Distraction Shield activated!"
        var description = "Try opening <BLOCKED_URL>. Focus Bear will help you be more intentional with how you use the site."
        var buttonOpenUrlText = "Click here to open <BLOCKED_URL> now"
        
        
        btnContinue.title = "It didn't stop me at all"
        btnLeft.title = "It made me more intentional"
        imgView.image = #imageLiteral(resourceName: "img_BlockedPageIntention")
        tryBlockState = ._NOTHING_
        
        if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "titleShieldActivated") as? String ?? lblTitle.stringValue
            description = dic.value(forKey: "descriptionTryIntentionText") as? String ?? description
            btnContinue.title = dic.value(forKey: "buttonItBlockedNewText") as? String ?? btnContinue.title
            btnLeft.title = dic.value(forKey: "buttonDidNotBlockedNewText") as? String ?? btnLeft.title
            buttonOpenUrlText = dic.value(forKey: "buttonOpenUrlText") as? String ?? buttonOpenUrlText
        }
        
        
        
        var url = ""
        if let urlsInfo = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
            for info in urlsInfo{
                if let isSelected = info["isSelected"] as? Bool {
                    if isSelected{
                        url = info["url"] as? String ?? ""
                        break;
                    }
                }
            }
        }
        if url.isEmpty{
            url = "facebook.com"
        }
        blockedUrlString = url
        let descriptionText = description.replacingOccurrences(of: "<BLOCKED_URL>", with: url)
        buttonOpenUrlText = buttonOpenUrlText.replacingOccurrences(of: "<BLOCKED_URL>", with: url)
        btnClickOpenUrl.title = buttonOpenUrlText
        
        lblDescription.stringValue = descriptionText
        if let location = description.indexOf(target: "<BLOCKED_URL>"){
            let attributedString = NSMutableAttributedString(string: descriptionText)
            
            
            if let font: NSFont = NSFontManager.shared.font(
                withFamily: "Verdana",
                traits: NSFontTraitMask(rawValue: NSFontTraitMask.RawValue(NSFontItalicTrait)),
                weight: 3,
                size: lblDescription.font?.pointSize ?? 20
            ){
                
                attributedString.addAttribute(NSAttributedString.Key.font, value: font, range: NSRange(location:location,length:(url.count)))
                lblDescription.attributedStringValue = attributedString
            }
        }
        
        
        
//        if let blockedUrls = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
//            SettingsManagerObject.arrBlockedUrls.removeAll()
//            for i in 0..<blockedUrls.count{
//                if let isSelected = blockedUrls[i]["isSelected"] as? Bool {
//                    if isSelected{
//                        SettingsManagerObject.arrBlockedUrls.append(blockedUrls[i]["url"] as? String ?? "")
//                    }
//                }
//            }
//        }
        btnLeft.buttonColor = NSColor.white.cgColor
        btnClickOpenUrl.isHidden = false
        
        allApiObject.capturePosthog(event: "distraction-shield-activated-shown", metadata: [:])
        addLog(text: "[user-action] distraction-shield-activated-shown")
    }
    
    override func viewDidAppear() {
        showOnboardingBellIcon(view: self.view, screen: "distraction-shield-activated-screen")
        tryBlockingVcShownInOnboarding = true
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.normalWindow)))
    }
    
    override func viewWillDisappear() {
        hideOnboardingBellIcon(view: self.view)
        self.view.window?.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(CGWindowLevelKey.assistiveTechHighWindow)))
    }

    @IBAction func btnLeftClicked(_ sender: Any) {
        btnClickOpenUrl.isHidden = true
        if tryBlockState == ._NOTHING_{
            allApiObject.capturePosthog(event: "button-didnt-blocked-clicked", metadata: [:])
            addLog(text: "[user-action] tryBlockUrlVc:- button didnt blocked clicked")
            lblTitle.stringValue = "Oops! Which browser did you try?"
            lblDescription.stringValue = "Did you use Safari or Chrome?\nWe can only block if you use those browsers." 
            btnLeft.title = "Still not working"
            btnContinue.title = "I just tried those browsers and it worked!"
            
            if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "titleWhichBrowser") as? String ?? lblTitle.stringValue
                lblDescription.stringValue = dic.value(forKey: "tryBrowsersBlockText") as? String ?? lblDescription.stringValue
                btnContinue.title = dic.value(forKey: "buttonNowBlockedText") as? String ?? btnContinue.title
                btnLeft.title = dic.value(forKey: "buttonStillNotBlockedText") as? String ?? btnLeft.title
            }
            
            tryBlockState = ._DID_NOT_WORKED_
            imgView.image = #imageLiteral(resourceName: "img_browsers")
        }else if tryBlockState == ._DID_NOT_WORKED_{
            addLog(text: "[user-action] tryBlockUrlVc:- button still not working clicked")
            allApiObject.capturePosthog(event: "button-still-not-working-clicked", metadata: [:])
            self.presentAsSheet(getAskDetailsNotBlockingVcObject())
        }
    }
    @IBAction func btnRightClicked(_ sender: Any) {
        btnClickOpenUrl.isHidden = true
        if tryBlockState == ._NOTHING_{
            addLog(text: "[user-action] tryBlockUrlVc:- button blocked clicked")
            allApiObject.capturePosthog(event: "button-blocked-clicked", metadata: [:])
        }else{
            addLog(text: "[user-action] tryBlockUrlVc:- button just tried those browsers clicked")
            allApiObject.capturePosthog(event: "button-just-tried-those-browsers-clicked", metadata: [:])
        }
        self.view.window?.close()
        if isExplainingPermissionsWindowShowingFromPomodoro{
            if SettingsManagerObject.isGeekModeEnabled{
                appdelegate?.menuShowPomodoroModeView()
                pomodoroVcObj?.textViewAchieve.string = pomodoroVcObj?.intentionToShowAgain ?? ""
            }else{
                appdelegate?.menuShowSimplePomodoroModeView()
                simplePomodoroVcObj?.textViewAchieve.string = simplePomodoroVcObj?.intentionToShowAgain ?? ""
            }
        }
    }
    
    @IBAction func btnOpenUrlClicked(_ sender: Any) {
        addLog(text: "[user-action] tryBlockUrlVc:- btnOpenUrlClicked")
        if !blockedUrlString.lowercased().contains("http://") && !blockedUrlString.lowercased().contains("https://"){
            blockedUrlString = "http://"+blockedUrlString
        }
        if let url = URL(string: blockedUrlString){
            NSWorkspace.shared.open(url)
        }
    }
}

