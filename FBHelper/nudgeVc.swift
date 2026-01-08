//
//  ViewController.swift
//  FBHelper
//
//  Created by Prashant Sawnani on 25/06/24.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class nudgeVc: NSViewController {

    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var checkBoxDontAskAgain: NSButton!
    @IBOutlet weak var btnNotNow: Button!
    @IBOutlet weak var btnDoIt: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    var showingForOnboarding = false
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        checkBoxDontAskAgain.title = "Don't ask again"
        btnNotNow.title = "Not Today"
        btnDoIt.title = "Let's do it!"
        btnNotNow.buttonColor = NSColor.white.cgColor
        lblSubTitle.isHidden = true
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func resetData(dayCount:Int){
        
        addLog(text: "resetData \(dayCount)")
        lblSubTitle.isHidden = true
        
        let isOnboardingIncompleted = sharedDefaults?.object(forKey: kUserdefaultsOnboardingIncompleted) as? Bool ?? false
        
        if isOnboardingIncompleted{
            capturePosthog(event: "daily-nudge-onboarding-shown", metadata: ["shown-after-days":dayCount])
            showingForOnboarding = true
            checkBoxDontAskAgain.isHidden = false
            checkBoxDontAskAgain.state = .off
            lblSubTitle.isHidden = false
            lblTitle.stringValue = "Finish setting up Focus Bear?"
            lblSubTitle.stringValue = "Take 5 minutes to set up your focus modes and habits."
        }else{
            capturePosthog(event: "show-nudge", metadata: ["shown-after-days":dayCount])
            showingForOnboarding = false
            if dayCount == 1{
                lblTitle.stringValue = "Hello there! 👋 Ready to boost your executive functioning? Start your day with your morning habits to kickstart productivity."
                checkBoxDontAskAgain.isHidden = true
            }else if dayCount == 2{
                let noHabitFound = sharedDefaults?.object(forKey: kUserdefaultsNoHabitFound) as? Bool ?? false
                if noHabitFound{
                    lblTitle.stringValue = "Gentle nudge to see if you still want to use Focus Bear to block distractions 🌞 ?"
                }else{
                    lblTitle.stringValue = "Gentle nudge to see if you still want to use Focus Bear to block distractions and build habits 🌞 ?"
                }
                
                checkBoxDontAskAgain.isHidden = false
            }else{
                lblTitle.stringValue = "Hello! 🌟 We hope you had a restful break. Your habits are a step towards a better you. Ready to pick up where you left off?"
                checkBoxDontAskAgain.isHidden = false
            }
            checkBoxDontAskAgain.state = .off
            sharedDefaults?.setValue(dayCount, forKeyPath: kUserdefaultsStartHabitNagCount)
        }
        
        sharedDefaults?.setValue(Date(), forKeyPath: kUserdefaultsLastNagShowDate)
        sharedDefaults?.synchronize()
        addLog(text: "resetData end")
    }
    
    @IBAction func btnDoItClicked(_ sender: Any) {
        if showingForOnboarding{
            capturePosthog(event: "daily-nudge-onboarding-lets-doit-clicked", metadata: [:])
        }else{
            capturePosthog(event: "nudge-button-lets-doit-clicked", metadata: [:])
        }
        addLog(text: "[user-action] btnDoItClicked")
        sharedDefaults?.removeObject(forKey: kUserdefaultsDontShowNudgeView)
        sharedDefaults?.removeObject(forKey: kUserdefaultsAppQuitForUser)
        sharedDefaults?.removeObject(forKey: kUserdefaultsStartHabitNagCount)
        sharedDefaults?.removeObject(forKey: kUserdefaultsLastNagShowDate)
        sharedDefaults?.removeObject(forKey: kUserdefaultsOnboardingIncompleted)
        
        sharedDefaults?.synchronize()
        appdelegate?.timerBackgroundThread?.invalidate()
        appdelegate?.timerBackgroundThread = nil
        self.view.window?.close()
        let path = Bundle.main.bundlePath as NSString
        var components = path.pathComponents
        components.removeLast()
        components.removeLast()
        components.removeLast()
        
        let newPath = NSString.path(withComponents: components)
        NSWorkspace.shared.launchApplication(newPath)
    }
    
    @IBAction func btnNotNowClicked(_ sender: Any) {
        addLog(text: "[user-action] btnNotNowClicked")
        if !checkBoxDontAskAgain.isHidden && checkBoxDontAskAgain.state == .on{
            addLog(text: "checkBoxDontAskAgain is on")
            sharedDefaults?.setValue(true, forKeyPath: kUserdefaultsDontShowNudgeView)
            sharedDefaults?.synchronize()
            appdelegate?.timerBackgroundThread?.invalidate()
            appdelegate?.timerBackgroundThread = nil
            if showingForOnboarding{
                capturePosthog(event: "daily-nudge-onboarding-dont-ask-again-clicked", metadata: [:])
            }else{
                capturePosthog(event: "nudge-button-dont-ask-again-clicked", metadata: [:])
            }
        }
        if showingForOnboarding{
            capturePosthog(event: "daily-nudge-onboarding-not-today-clicked", metadata: [:])
        }else{
            capturePosthog(event: "nudge-button-not-today-clicked", metadata: [:])
        }
        self.view.window?.close()
    }
    
    @IBAction func checkBoxDontAskAgainClicked(_ sender: Any) {
        
    }
}

