//
//  onboardingDistractionTypesVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 28/11/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class onboardingDistractionTypesVc: NSViewController {

    @IBOutlet weak var lblDescription: NSTextField!
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var checkBoxThird: NSButton!
    @IBOutlet weak var checkBoxSecond: NSButton!
    @IBOutlet weak var checkBoxFirst: NSButton!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "What distracts you from your work?"
        checkBoxFirst.title  = "Websites on my computer (e.g. Reddit, Youtube, Instagram)"
        checkBoxSecond.title  = "Apps on my computer (e.g. games, messaging apps)"
        checkBoxThird.title  = "My phone"
        lblDescription.stringValue = "The Focus Bear mobile app can help. Get it from focusbear.io on your phone."
        btnContinue.title = buttonContinueText

        if let onboardingDistractionTypesVcInfo = configjson.value(forKey: "onboardingDistractionTypesVcInfo") as? NSDictionary{
            lblTitle.stringValue = onboardingDistractionTypesVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            checkBoxFirst.title = onboardingDistractionTypesVcInfo.value(forKey: "optionWebsitesText") as? String ?? checkBoxFirst.title
            checkBoxSecond.title = onboardingDistractionTypesVcInfo.value(forKey: "optionAppsText") as? String ?? checkBoxSecond.title
            checkBoxThird.title = onboardingDistractionTypesVcInfo.value(forKey: "optionPhoneText") as? String ?? checkBoxThird.title
            lblDescription.stringValue = onboardingDistractionTypesVcInfo.value(forKey: "descriptionPhoneText") as? String ?? lblDescription.stringValue
        }

        lblDescription.isHidden = true
        checkBoxFirst.state = .off
        checkBoxSecond.state = .off
        checkBoxThird.state = .off
        btnContinue.isEnabled = false
        addLog(text: "onboardingDistractionTypesVc shown")
        allApiObject.capturePosthog(event: "onboarding-distraction-types-view-shown", metadata: [:])
    }
    
    func checkContinueButtonState(){
        if checkBoxFirst.state == .on || checkBoxSecond.state == .on || checkBoxThird.state == .on{
            btnContinue.isEnabled = true
        }else{
            btnContinue.isEnabled = false
        }
    }
    
    @IBAction func checkBoxFirstClicked(_ sender: Any) {
        if checkBoxFirst.state == .on{
            addLog(text: "checkBox Websites checked")
            allApiObject.capturePosthog(event: "checkBox-websites-checked", metadata: [:])
        }else{
            addLog(text: "checkBox Websites unchecked")
            allApiObject.capturePosthog(event: "checkBox-websites-unchecked", metadata: [:])
        }
        checkContinueButtonState()
    }
    
    @IBAction func checkBoxSecondClicked(_ sender: Any) {
        if checkBoxSecond.state == .on{
            addLog(text: "checkBox Apps checked")
            allApiObject.capturePosthog(event: "checkBox-apps-checked", metadata: [:])
        }else{
            addLog(text: "checkBox Apps unchecked")
            allApiObject.capturePosthog(event: "checkBox-apps-unchecked", metadata: [:])
        }
        checkContinueButtonState()
    }
    
    @IBAction func checkBoxThirdClicked(_ sender: Any) {
        if checkBoxThird.state == .on{
            addLog(text: "checkBox My phone checked")
            allApiObject.capturePosthog(event: "checkBox-phone-checked", metadata: [:])
            lblDescription.isHidden = false
        }else{
            addLog(text: "checkBox My phone unchecked")
            allApiObject.capturePosthog(event: "checkBox-phone-unchecked", metadata: [:])
            lblDescription.isHidden = true
        }
        checkContinueButtonState()
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] onboarding Distraction Types view:- button Continue clicked.")
        if checkBoxFirst.state == .on{
            self.view.window?.contentViewController = getOnboardingBlockedUrlsVcObject()
        }else if checkBoxSecond.state == .on{
            self.view.window?.contentViewController = getOnboardingBlockedAppsVcObject()
        }else {
            if UserDefaults.standard.object(forKey: kUserdefaultsBrowsersPermissionsSetByUser) == nil{
                self.view.window?.contentViewController = getExplainingPermissionsVcObject()
                explainingPermissionsVcObj?.showingFromPomodoro = true
                UserDefaults.standard.set(true, forKey: kUserdefaultsBrowsersPermissionsSetByUser)
            }else{
                self.view.window?.close()
                if SettingsManagerObject.isGeekModeEnabled{
                    appdelegate?.menuShowPomodoroModeView()
                    pomodoroVcObj?.textViewAchieve.string = pomodoroVcObj?.intentionToShowAgain ?? ""
                }else{
                    appdelegate?.menuShowSimplePomodoroModeView()
                    simplePomodoroVcObj?.textViewAchieve.string = simplePomodoroVcObj?.intentionToShowAgain ?? ""
                }
            }
        }
        
    }
}
