//
//  askBuildHabitsVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 10/04/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class askBuildHabitsVc: NSViewController { //  not in use

    @IBOutlet weak var btnYeah: Button!
    @IBOutlet weak var btnNoThanks: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblDescription: NSTextField!
    var isURlBlockedSuccessfully = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblSubTitle.stringValue = "Next Up: Building habits to support focus"
        lblDescription.stringValue = "One other thing that we find really helps is building habits to support focus. For example, even a small amount of aerobic exercise + meditation in the morning has been shown to boost concentration during the day.\nWould you like to try out the habit features?"
        btnNoThanks.title = "No Thanks"
        btnYeah.title = "Yeah!"
        
        if let dic = configjson.value(forKey: "askBuildHabitsVcInfo") as? NSDictionary{
            lblSubTitle.stringValue = dic.value(forKey: "subTitle") as? String ?? lblSubTitle.stringValue
            lblDescription.stringValue = dic.value(forKey: "description") as? String ?? lblDescription.stringValue
            btnNoThanks.title = dic.value(forKey: "buttonNoText") as? String ?? btnNoThanks.title
            btnYeah.title = dic.value(forKey: "buttonYesText") as? String ?? btnYeah.title
        }
        btnNoThanks.buttonColor = NSColor.white.cgColor
    }
    
    override func viewWillAppear() {
        if isURlBlockedSuccessfully{
            lblTitle.stringValue = "Awesome! We look forward to helping you block distractions."
            
            if let dic = configjson.value(forKey: "askBuildHabitsVcInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "titleBlockedSuccessfully") as? String ?? lblTitle.stringValue
            }
            
        }else{
            lblTitle.stringValue = "We'll be in touch shortly to get that fixed.\n\nIn the meantime, we can show you the habit features."
            
            if let dic = configjson.value(forKey: "askBuildHabitsVcInfo") as? NSDictionary{
                lblTitle.stringValue = dic.value(forKey: "titleBlockedFailed") as? String ?? lblTitle.stringValue
            }
        }
    }
    
    @IBAction func btnNoThanksClicked(_ sender: Any) {
        let alert = NSAlert()
        alert.setSharingType()
        var alertText = "Are you sure? You can start with really tiny habits like 2 minutes of meditation in the morning.\nFocus Bear was built by a neurodiverse team (a few of us have ADHD) and we find the habit features make a huge difference to how the rest of the day goes."
        
        var buttonOkShowHabitText = "OK fine - show me the habit feature"
        var buttonCancelHabitText = "No I'm not interested right now"
        
        
        if let dic = configjson.value(forKey: "askBuildHabitsVcInfo") as? NSDictionary{
            alertText = dic.value(forKey: "alertConfirmText") as? String ?? alertText
            buttonOkShowHabitText = dic.value(forKey: "buttonOkShowHabitText") as? String ?? buttonOkShowHabitText
            buttonCancelHabitText = dic.value(forKey: "buttonCancelHabitText") as? String ?? buttonCancelHabitText
        }

        alert.messageText = alertText
        alert.addButton(withTitle: buttonOkShowHabitText)
        alert.addButton(withTitle: buttonCancelHabitText)
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.doOnboardingSetup()
            }else if(modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn){
                
                UserDefaults.standard.set(true, forKey: kUserdefaultsFirstRun)
                UserDefaults.standard.set(Date(), forKey: kUserdefaultsLastHabitShowDate)
                
                
                self.view.window?.contentViewController = getAskAccountVcObject()
            }
        })
    }
    
    @IBAction func btnYeahClicked(_ sender: Any) {
        doOnboardingSetup()
    }
    
    func doOnboardingSetup(){
        self.view.window?.contentViewController = getWelcomeOnboardingVcObject()
    }
}
