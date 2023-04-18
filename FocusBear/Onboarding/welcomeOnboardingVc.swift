//
//  welcomeOnboardingVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 24/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class welcomeOnboardingVc: NSViewController {

    @IBOutlet weak var btnNoThanks: underLineButton!
    @IBOutlet weak var boxSmallInfo: NSBox!
    @IBOutlet weak var boxAllInfo: NSBox!
    @IBOutlet weak var lblAllRights: NSTextField!
    @IBOutlet weak var btnLetsDoIt: Button!
    @IBOutlet weak var btnLater: Button!
    @IBOutlet weak var lblDescriptionSecond: NSTextField!
    @IBOutlet weak var lblDescriptionFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
//    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var lblTitleAppName: NSTextField!
    @IBOutlet weak var lblGotTwoMinutes: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnLater.buttonColor = NSColor.white.cgColor
        //lblTitleAppName.stringValue = appName
        //lblSubTitle.stringValue = "Welcome aboard!"
        btnNoThanks.title = "No Thanks"
        
        lblDescriptionFirst.stringValue = "Looking forward to helping you form healthy habits and get more deep work done. The onboarding process takes 5 minutes and requires 100% attention from you."
        lblDescriptionSecond.stringValue = "You won't be able to use other apps during the onboarding. Do you have time now or shall we do it a bit later?"
        btnLater.title = "A bit later please"
        btnLetsDoIt.title = "Let's do it"
        lblAllRights.stringValue = "© 2022-2023 Focus Bear All Rights Reserved."
        
        lblGotTwoMinutes.stringValue = "Got two minutes to try out our habit guide feature?"
        
        lblSubTitle.stringValue = "Next Up: Building habits to support focus"
        
        if let welcomeOnboardingVcInfo = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            //lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblDescriptionFirst.stringValue = welcomeOnboardingVcInfo.value(forKey: "descriptionFirstText") as? String ?? lblDescriptionFirst.stringValue
            lblDescriptionSecond.stringValue = welcomeOnboardingVcInfo.value(forKey: "descriptionSecondText") as? String ?? lblDescriptionSecond.stringValue
            btnLater.title = welcomeOnboardingVcInfo.value(forKey: "buttonLaterText") as? String ?? btnLater.title
            btnLetsDoIt.title = welcomeOnboardingVcInfo.value(forKey: "buttonLetsDoItText") as? String ?? btnLetsDoIt.title
            lblAllRights.stringValue = welcomeOnboardingVcInfo.value(forKey: "allRightsReservedText") as? String ?? lblAllRights.stringValue
            lblGotTwoMinutes.stringValue = welcomeOnboardingVcInfo.value(forKey: "gotTwoMinutesText") as? String ?? lblGotTwoMinutes.stringValue
            lblSubTitle.stringValue = welcomeOnboardingVcInfo.value(forKey: "subTitleNewText") as? String ?? lblSubTitle.stringValue
            btnNoThanks.title = welcomeOnboardingVcInfo.value(forKey: "buttonNoText") as? String ?? btnNoThanks.title
        }
        
        
        
        allApiObject.capturePosthog(event: "onboarding-habit-start-view-shown", metadata: [:])
        
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        boxSmallInfo.isHidden = true
        boxAllInfo.isHidden = false
    }
    var isURlBlockedSuccessfully = false
    override func viewWillAppear() {
        
        if isURlBlockedSuccessfully{
            lblTitleAppName.stringValue = "Awesome! We look forward to helping you block distractions."
            
            if let dic = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
                lblTitleAppName.stringValue = dic.value(forKey: "titleBlockedSuccessfully") as? String ?? lblTitleAppName.stringValue
            }
            
        }else{
            lblTitleAppName.stringValue = "We'll be in touch shortly to get that fixed.\n\nIn the meantime, we can show you the habit features."
            
            if let dic = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
                lblTitleAppName.stringValue = dic.value(forKey: "titleBlockedFailed") as? String ?? lblTitleAppName.stringValue
            }
        }
        
        
        boxSmallInfo.isHidden = false
        boxAllInfo.isHidden = true
    }
    @IBAction func btnLaterClicked(_ sender: Any) {
        addLog(text: "btnLaterClicked.")
        self.presentAsSheet(getOnboardingPostponeVcObject())
    }
    
    @IBAction func btnLetsDoItClicked(_ sender: Any) {
        addLog(text: "btnLetsDoItClicked.")
        allApiObject.capturePosthog(event: "button-lets-do-it-clicked", metadata: [:])
        let alert = NSAlert()
        alert.setSharingType()
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
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        allApiObject.capturePosthog(event: "button-no-thanks-clicked", metadata: [:])
        let alert = NSAlert()
        alert.setSharingType()
        var alertText = "Are you sure? You can start with really tiny habits like 2 minutes of meditation in the morning.\nFocus Bear was built by a neurodiverse team (a few of us have ADHD) and we find the habit features make a huge difference to how the rest of the day goes."
        
        var buttonOkShowHabitText = "OK fine - show me the habit feature"
        var buttonCancelHabitText = "No I'm not interested right now"
        
        
        if let dic = configjson.value(forKey: "welcomeOnboardingVcInfo") as? NSDictionary{
            alertText = dic.value(forKey: "alertConfirmText") as? String ?? alertText
            buttonOkShowHabitText = dic.value(forKey: "buttonOkShowHabitText") as? String ?? buttonOkShowHabitText
            buttonCancelHabitText = dic.value(forKey: "buttonCancelHabitText") as? String ?? buttonCancelHabitText
        }

        alert.messageText = alertText
        alert.addButton(withTitle: buttonOkShowHabitText)
        alert.addButton(withTitle: buttonCancelHabitText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.btnLetsDoItClicked(self)
            }else if(modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn){
                
                
                isHabitsDisabled = false
                UserDefaults.standard.set(false, forKey: kUserdefaultsIsHabitsDisabled)
                allApiObject.getHabitPacksInfo(breaks_only: false, completionHandler: {arrDic in
                    
                    if arrDic != nil{
                        print(arrDic)
                        DispatchQueue.main.async {
                            if habitPacksData != nil{
                                if habitPacksData!.count != 0{
                                    let pack = habitPacksData![0]
                                    let id = pack["id"] as? String ?? ""
                                    if !id.isEmpty{
                                        UserDefaults.standard.set(id, forKey: kUserdefaultsPackIdSelected)
                                    }
                                }
                            }
                            UserDefaults.standard.set("05:15", forKey: kUserdefaultsStartupTimeFromOnboarding)
                            UserDefaults.standard.set("20:30", forKey: kUserdefaultsShutOffTimeFromOnboarding)
                            
                            UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
                            UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                        }
                    }
                })
                
                
                self.view.window?.contentViewController = getAskAccountVcObject()
            }
        })
    }
    
}
