//
//  welcomeOnboardingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeOnboardingVc: NSViewController {

    @IBOutlet weak var lblAllRights: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var btnLater: Button!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
       
        lblTitleAppName.stringValue = appName
        lblSubTitle.stringValue = "Welcome aboard!"
        lblDescriptionFirst.stringValue = "Looking forward to helping you form healthy habits and get more deep work done. The onboarding process takes 5 minutes and requires 100% attention from you."
        lblDescriptionSecond.stringValue = "You won't be able to use other apps during the onboarding. Do you have time now or shall we do it a bit later?"
        btnLater.title = "A bit later please"
        btnLetsDoIt.title = "Let's do it"
        lblAllRights.stringValue = "© 2022 Focus Bear All Rights Reserved."
        
        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblDescriptionFirst.stringValue = welcomeOnboardingVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            lblDescriptionSecond.stringValue = welcomeOnboardingVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            btnLater.title = welcomeOnboardingVcInfo.value(forKey: "buttonLaterText") as? String ?? btnLater.title
            btnLetsDoIt.title = welcomeOnboardingVcInfo.value(forKey: "buttonLetsDoItText") as? String ?? btnLetsDoIt.title
            lblAllRights.stringValue = welcomeOnboardingVcInfo.value(forKey: "allRightsReservedText") as? String ?? lblAllRights.stringValue
            
        }
        
        btnLater.buttonColor = NSColor.white.cgColor
    }
    
    @IBAction func btnLaterClicked(_ sender: Any) {
        addLog(text: "btnLaterClicked.")
        self.presentAsSheet(getOnboardingPostponeVcObject())
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "btnLetsDoItClicked.")
        
        let alert = NSAlert()
        
        var messageText = "Just want to double check you are ok to focus 100% on onboarding for the next 2 minutes. The next step is full screen - you won't be able to use any other apps during this time."
        var buttonConfirmLetsDoItText = "You have my full attention"
        var buttonLaterText = "Uhh I need a few more minutes"

        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            messageText = welcomeOnboardingVcInfo.value(forKey: "confirmText") as? String ?? messageText
            buttonConfirmLetsDoItText = welcomeOnboardingVcInfo.value(forKey: "buttonConfirmLetsDoItText") as? String ?? buttonConfirmLetsDoItText
            buttonLaterText = welcomeOnboardingVcInfo.value(forKey: "buttonNeedMoreTimeText") as? String ?? buttonLaterText
        }
        
        alert.messageText = messageText
        alert.addButton(withTitle: buttonConfirmLetsDoItText)
        alert.addButton(withTitle: buttonLaterText)
        
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: {result in
            if result == .alertFirstButtonReturn{
                addLog(text: "Alert:- btnLetsDoItClicked.")
                self.view.window?.close()
                appdelegate!.showAskAppWork()//showOnbardingHabit()
            }else {
                addLog(text: "Alert:- btnLaterClicked.")
                self.presentAsSheet(getOnboardingPostponeVcObject())
            }
        })

    }
    
}
