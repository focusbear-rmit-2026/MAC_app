//
//  changeFrictionLevelVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/05/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class changeFrictionLevelVc: NSViewController {

    @IBOutlet weak var btnCancel: Button!
    @IBOutlet weak var lblSuperGentle: NSTextField!
    @IBOutlet weak var lblGentle: NSTextField!
    @IBOutlet weak var lblSlightlyStrict: NSTextField!
    @IBOutlet weak var lblStrict: NSTextField!
    @IBOutlet weak var lblSuperStrict: NSTextField!
    
    
    @IBOutlet weak var btnSuperGentle: hoverInfoButton!
    @IBOutlet weak var btnGentle: hoverInfoButton!
    @IBOutlet weak var btnSlightlyStrict: hoverInfoButton!
    @IBOutlet weak var btnStrict: hoverInfoButton!
    @IBOutlet weak var btnSuperStrict: hoverInfoButton!

    
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var slider: CustomSlider!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var frictionSetPasswordVcObj:frictionSetPasswordVc?
    func getFrictionSetPasswordVcObj()->frictionSetPasswordVc{
        if frictionSetPasswordVcObj == nil{
            frictionSetPasswordVcObj = settingsStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("frictionSetPasswordVc")) as? frictionSetPasswordVc
        }
        return frictionSetPasswordVcObj!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        btnCancel.title = buttonCancelText
        
        
        lblTitle.stringValue = "How strict do you want Focus Bear to be?"
        btnContinue.title = "Apply changes"
        
        lblSuperGentle.stringValue = "Super gentle (non-full screen, instantly postpone habits)"
        lblGentle.stringValue = "Gentle (Full screen, instantly postpone habits)"
        lblSlightlyStrict.stringValue = "Slightly strict (Full screen with countdown timers for postponing habits)"
        lblStrict.stringValue = "Strict (Password required to postpone habits)"
        lblSuperStrict.stringValue = "Super strict (Password to postpone/skip habits + Instantly block non-allowed websites)"

        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            lblTitle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSuperGentle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "superGentleText") as? String ?? lblSuperGentle.stringValue
            lblGentle.stringValue = chooseFrictionLevelVcInfo.value(forKey: "gentleText") as? String ?? lblGentle.stringValue
            lblSlightlyStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "slightlyStrictText") as? String ?? lblSlightlyStrict.stringValue
            lblStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "strictText") as? String ?? lblStrict.stringValue
            lblSuperStrict.stringValue = chooseFrictionLevelVcInfo.value(forKey: "superStrictText") as? String ?? lblSuperStrict.stringValue
            btnContinue.title = chooseFrictionLevelVcInfo.value(forKey: "buttonApplyText") as? String ?? btnContinue.title
        }
        
        btnCancel.isSecondaryButton = true
    }
    override func viewDidAppear() {
        SettingsManagerObject.putUserLocalDeviceSettings()
    }
    @IBAction func btnSuperGentleClicked(_ sender: Any) {
        var msg = "- Activates Cuddly mode for a gentle user experience\n- Habits can be done without going full screen\n- Allows quick and easy habit postponement\n- App does not restart upon force quit"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            msg = chooseFrictionLevelVcInfo.value(forKey: "descriptionSuperGentle") as? String ?? msg
        }
        showTooltip(sender: btnSuperGentle, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:600)
    }
    @IBAction func btnGentleClicked(_ sender: Any) {
        var msg = "- Incorporates Cuddly mode for a user-friendly approach\n- Habits run in full screen, maintaining focus\n- Enables instant habit postponement\n- App does not restart upon force quit"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            msg = chooseFrictionLevelVcInfo.value(forKey: "descriptionGentle") as? String ?? msg
        }
        showTooltip(sender: btnGentle, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:600)
    }
    @IBAction func btnSlightlyStrictClicked(_ sender: Any) {
        var msg = "- Retains Cuddly mode for user comfort\n- Introduces countdown timers for controlled habit postponement within full screen\n- App restarts upon force quit to uphold commitment to established habits"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            msg = chooseFrictionLevelVcInfo.value(forKey: "descriptionSlightlyStrict") as? String ?? msg
        }
        showTooltip(sender: btnSlightlyStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:600)
    }
    @IBAction func btnStrictClicked(_ sender: Any) {
        var msg = "- Upholds Cuddly mode for a friendly interface\n- Requires a password for habit postponement, promoting commitment\n- App restarts upon force quit, emphasizing the importance of adherence to habits"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            msg = chooseFrictionLevelVcInfo.value(forKey: "descriptionStrict") as? String ?? msg
        }
        showTooltip(sender: btnStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:600)
    }
    @IBAction func btnSuperStrictClicked(_ sender: Any) {
        var msg = "- Activates Grizzly mode for enhanced security measures\n- Implements a password system for habit postponement/skipping, ensuring accountability\n- App restarts upon force quit, reinforcing unwavering commitment\n- Immediately blocks distracting websites for an undistracted working environment"
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            msg = chooseFrictionLevelVcInfo.value(forKey: "descriptionSuperStrict") as? String ?? msg
        }
        showTooltip(sender: btnSuperStrict, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:600)
    }
    func hideDockIcon(){
        if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == true{
            UserDefaults.standard.set(false, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.accessory)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    func showDockIcon(){
        if UserDefaults.standard.object(forKey: kUserdefaultsShowDockIcon) as? Bool == false{
            UserDefaults.standard.set(true, forKey: kUserdefaultsShowDockIcon)
            NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        }
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        switch slider.integerValue {
        case 5:
            allApiObject.capturePosthog(event: "change-friction-level", metadata: ["friction-level":"super_strict"])
            if !SettingsManagerObject.isFullScreenEnabled{
                SettingsManagerObject.isFullScreenEnabled = true
            }
            SettingsManagerObject.storedCuddlyModeEnabled = false
            SettingsManagerObject.isEasySkipEnabled = false
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = true
            SettingsManagerObject.isRequiredIntentionInPostpone = true
            startMainAppForceQuitMonitoring()
            hideDockIcon()
            SettingsManagerObject.immediatelyBlockDistractingSites = true
            SettingsManagerObject.immediatelyBlockDistractingApps = true
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
                alertSetPasswordConfirm()
            }else{
                self.dismiss(self)
            }
            strictnessVcObj?.reloadStrictnessLevelState()
            break;
        case 4:
            allApiObject.capturePosthog(event: "change-friction-level", metadata: ["friction-level":"strict"])
            if !SettingsManagerObject.isFullScreenEnabled{
                SettingsManagerObject.isFullScreenEnabled = true
            }
            SettingsManagerObject.storedCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = false
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = true
            SettingsManagerObject.isRequiredIntentionInPostpone = true
            startMainAppForceQuitMonitoring()
            hideDockIcon()
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            SettingsManagerObject.isSettingsChanged = true
            if UserDefaults.standard.object(forKey: SettingsManagerObject.kUserdefaultsAppPassword) == nil{
                alertSetPasswordConfirm()
            }else{
                self.dismiss(self)
            }
            strictnessVcObj?.reloadStrictnessLevelState()
            break;
        case 3:
            allApiObject.capturePosthog(event: "change-friction-level", metadata: ["friction-level":"slightly_strict"])
            if !SettingsManagerObject.isFullScreenEnabled{
                SettingsManagerObject.isFullScreenEnabled = true
            }
            SettingsManagerObject.storedCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = false
            UserDefaults.standard.set(false, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            SettingsManagerObject.isRequiredIntentionInPostpone = false
            stopMainAppForceQuitMonitoring()
            showDockIcon()
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            SettingsManagerObject.isSettingsChanged = true
            strictnessVcObj?.reloadStrictnessLevelState()
            self.dismiss(self)
            break;
        case 2:
            allApiObject.capturePosthog(event: "change-friction-level", metadata: ["friction-level":"gentle"])
            if !SettingsManagerObject.isFullScreenEnabled{
                SettingsManagerObject.isFullScreenEnabled = true
            }
            SettingsManagerObject.storedCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = true
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            SettingsManagerObject.isRequiredIntentionInPostpone = false
            stopMainAppForceQuitMonitoring()
            showDockIcon()
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            SettingsManagerObject.isSettingsChanged = true
            strictnessVcObj?.reloadStrictnessLevelState()
            self.dismiss(self)
            break;
        case 1:
            allApiObject.capturePosthog(event: "change-friction-level", metadata: ["friction-level":"super_gentle"])
            if SettingsManagerObject.isFullScreenEnabled{
                SettingsManagerObject.isFullScreenEnabled = false
            }
            SettingsManagerObject.storedCuddlyModeEnabled = true
            SettingsManagerObject.isEasySkipEnabled = true
            UserDefaults.standard.set(true, forKey: SettingsManagerObject.kUserdefaultsDoNotBlockUrlsDuringSuperPomodoroBreaks)
            
            SettingsManagerObject.shouldReloadAfterForceQuitEnabled = false
            SettingsManagerObject.isRequiredIntentionInPostpone = false
            stopMainAppForceQuitMonitoring()
            showDockIcon()
            SettingsManagerObject.immediatelyBlockDistractingSites = false
            SettingsManagerObject.immediatelyBlockDistractingApps = false
            SettingsManagerObject.isSettingsChanged = true
            strictnessVcObj?.reloadStrictnessLevelState()
            self.dismiss(self)
            break;
        default:
            break;
        }
        
        
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.dismiss(self)
        strictnessVcObj?.reloadStrictnessLevelState()
    }
    func alertSetPasswordConfirm(){
        let alert = NSAlert()
        alert.setSharingType()
        alert.alertStyle = .informational
        
        var messageText = "It is recommended that you set a password for the Strict/Super strict modes."
        var buttonSetPasswordText = "Set password"
        var buttonDoNotSetPasswordText = "Do not set password"
        
        if let chooseFrictionLevelVcInfo = configjson.value(forKey: "chooseFrictionLevelVcInfo") as? NSDictionary{
            messageText = chooseFrictionLevelVcInfo.value(forKey: "alertSetPasswordText") as? String ?? messageText
            buttonSetPasswordText = chooseFrictionLevelVcInfo.value(forKey: "buttonSetPasswordText") as? String ?? buttonSetPasswordText
            buttonDoNotSetPasswordText = chooseFrictionLevelVcInfo.value(forKey: "buttonDoNotSetPasswordText") as? String ?? buttonDoNotSetPasswordText
        }
        
        alert.messageText = messageText
        alert.addButton(withTitle: buttonSetPasswordText)
        alert.addButton(withTitle: buttonDoNotSetPasswordText)
        alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
            if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                self.dismiss(self)
                strictnessVcObj?.presentAsSheet(self.getFrictionSetPasswordVcObj())
            }else{
                self.dismiss(self)
            }
            
        })
    }
}

