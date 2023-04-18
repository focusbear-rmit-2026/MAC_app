//
//  tryBlockUrlVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class tryBlockUrlVc: NSViewController {

    @IBOutlet weak var btnLeft: Button!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    
    enum CURRENTBLOCKSTATE:Int{
        case _NOTHING_ = 111, _DID_NOT_WORKED_
    }
    var tryBlockState:CURRENTBLOCKSTATE = ._NOTHING_
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Distraction Shield activated!"
        var description = "Try it out - Please attemp to access <BLOCKED_URL> through your web browser. It should block the site."

        btnContinue.title = "It blocked it!"
        btnLeft.title = "It didn't block it 😒"
        imgView.image = #imageLiteral(resourceName: "img_BlockedPage")
        tryBlockState = ._NOTHING_
        
        if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
            lblTitle.stringValue = dic.value(forKey: "titleShieldActivated") as? String ?? lblTitle.stringValue
            description = dic.value(forKey: "descriptionTryBlockText") as? String ?? description
            btnContinue.title = dic.value(forKey: "buttonItBlockedText") as? String ?? btnContinue.title
            btnLeft.title = dic.value(forKey: "buttonDidNotBlockedText") as? String ?? btnLeft.title
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
        
        lblDescription.stringValue = description.replacingOccurrences(of: "<BLOCKED_URL>", with: url)
        
        
        if let blockedUrls = UserDefaults.standard.object(forKey: kUserdefaultsBlockedUrlsFromOnboarding) as? [[String:Any]]{
            SettingsManagerObject.arrBlockedUrls.removeAll()
            for i in 0..<blockedUrls.count{
                if let isSelected = blockedUrls[i]["isSelected"] as? Bool {
                    if isSelected{
                        SettingsManagerObject.arrBlockedUrls.append(blockedUrls[i]["url"] as? String ?? "")
                    }
                }
            }
//            UserDefaults.standard.set(SettingsManagerObject.arrBlockedUrls, forKey: SettingsManagerObject.kUserdefaultsArrBlockedUrls)
//            UserDefaults.standard.removeObject(forKey: kUserdefaultsBlockedUrlsFromOnboarding)
        }
        btnLeft.buttonColor = NSColor.white.cgColor
        
        allApiObject.capturePosthog(event: "distraction-shield-activated-shown", metadata: [:])
    }
    
    
    @IBAction func btnLeftClicked(_ sender: Any) {
        if tryBlockState == ._NOTHING_{
            allApiObject.capturePosthog(event: "button-didnt-blocked-clicked", metadata: [:])
            
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
            allApiObject.capturePosthog(event: "button-still-not-working-clicked", metadata: [:])
            let alert = NSAlert()
            alert.setSharingType()
            var messageText = "Sorry about that 😓 Any chance you could email us (team@focusbear.io) and we'll try and fix it for you?"
            

            if let dic = configjson.value(forKey: "tryBlockUrlVcInfo") as? NSDictionary{
                messageText = dic.value(forKey: "emailUsText") as? String ?? messageText
            }
            
            alert.messageText = messageText
            alert.addButton(withTitle: buttonOkText)
            
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
                getWelcomeOnboardingVcObject().isURlBlockedSuccessfully = false
                self.view.window?.contentViewController = getWelcomeOnboardingVcObject()
            })
        }
    }
    @IBAction func btnRightClicked(_ sender: Any) {
        if tryBlockState == ._NOTHING_{
            allApiObject.capturePosthog(event: "button-blocked-clicked", metadata: [:])
        }else{
            allApiObject.capturePosthog(event: "button-just-tried-those-browsers-clicked", metadata: [:])
        }
        getWelcomeOnboardingVcObject().isURlBlockedSuccessfully = true
        self.view.window?.contentViewController = getWelcomeOnboardingVcObject()
    }
    
}
