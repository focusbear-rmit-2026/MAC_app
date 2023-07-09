//
//  chooseFrictionLevelVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class chooseFrictionLevelVc: NSViewController {

    @IBOutlet weak var lblSuperGentle: NSTextField!
    @IBOutlet weak var lblGentle: NSTextField!
    @IBOutlet weak var lblSlightlyStrict: NSTextField!
    @IBOutlet weak var lblStrict: NSTextField!
    @IBOutlet weak var lblSuperStrict: NSTextField!
    @IBOutlet weak var lblUnderneath: NSTextField!
    
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var slider: NSSlider!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "How strict do you want Focus Bear to be?"
        btnContinue.title = "Continue"
        
        lblSuperGentle.stringValue = "Super gentle (non-full screen, instantly postpone habits)"
        lblGentle.stringValue = "Gentle (Full screen, instantly postpone habits)"
        lblSlightlyStrict.stringValue = "Slightly strict (Full screen with countdown timers for postponing habits)"
        lblStrict.stringValue = "Strict (Password required to postpone habits)"
        lblSuperStrict.stringValue = "Super strict (Password to postpone/skip habits + Instantly block non-allowed websites)"
        lblUnderneath.stringValue = "(You can change this later)"
        
        
        
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            lblTitle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSuperGentle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "superGentleText") as? String ?? lblSuperGentle.stringValue
            lblGentle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "gentleText") as? String ?? lblGentle.stringValue
            lblSlightlyStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "slightlyStrictText") as? String ?? lblSlightlyStrict.stringValue
            lblStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "strictText") as? String ?? lblStrict.stringValue
            lblSuperStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "superStrictText") as? String ?? lblSuperStrict.stringValue
            lblUnderneath.stringValue = chooseFrictionLevelVcInfo.value(forKey: "underneathText") as? String ?? lblUnderneath.stringValue
            btnContinue.title = chooseFrictionLevelVcInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
        
        //slider.tint = NSColor.blue
        UserDefaults.standard.removeObject(forKey: kUserdefaultsPasswordSetInOnboarding)
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        switch slider.integerValue {
        case 1:
            alertDoubleConfirm()
            break;
        case 2:
            alertDoubleConfirm()
            break;
        case 3:
            allApiObject.capturePosthog(event: "choose-friction-level", metadata: ["friction-level":"slightly_strict"])
            SettingsManagerObject.isFullScreenEnabled = true
            SettingsManagerObject.isCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = false
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            showHowHeardWindow()
            break;
        case 4:
            allApiObject.capturePosthog(event: "choose-friction-level", metadata: ["friction-level":"gentle"])
            SettingsManagerObject.isFullScreenEnabled = true
            SettingsManagerObject.isCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = true
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            showHowHeardWindow()
            break;
        case 5:
            allApiObject.capturePosthog(event: "choose-friction-level", metadata: ["friction-level":"super_gentle"])
            SettingsManagerObject.isFullScreenEnabled = false
            SettingsManagerObject.isCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = true
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            showHowHeardWindow()
            break;
        default:
            break;
        }
        
        
    }
    
    func alertDoubleConfirm(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var messageText = "Are you sure? We recommend starting with a less strict mode initially and gradually amp up the strictness if you need it."
        
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            messageText = chooseFrictionLevelVcInfo.value(forKey: "alertDoubleConfirmText") as? String ?? messageText
        }
        
        alert.messageText = messageText
        alert.addButton(withTitle: buttonYesText)
        alert.addButton(withTitle: buttonNoText)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                switch self.slider.integerValue {
                case 1:
                    allApiObject.capturePosthog(event: "choose-friction-level", metadata: ["friction-level":"super_strict"])
                    showOnboardingSetPasswordWindow()
                    SettingsManagerObject.isFullScreenEnabled = true
                    SettingsManagerObject.isCuddlyModeEnabled = false
                    SettingsManagerObject.isEasySkipEnabled = false
                    SettingsManagerObject.shouldReloadAfterForceQuitEnabled = true
                    break;
                case 2:
                    allApiObject.capturePosthog(event: "choose-friction-level", metadata: ["friction-level":"strict"])
                    showOnboardingSetPasswordWindow()
                    SettingsManagerObject.isFullScreenEnabled = true
                    SettingsManagerObject.isCuddlyModeEnabled = true
                    SettingsManagerObject.isEasySkipEnabled = false
                    SettingsManagerObject.shouldReloadAfterForceQuitEnabled = true
                    break;
                default:
                    break;
                }
                
            }
            
        })
    }
}
