//
//  allSetVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 30/03/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class allSetVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    @IBOutlet weak var customViewProgress: NSView!
    
    var distractionBlockingProgressVcObj:distractionBlockingProgressVc?
    var settingsWaitTimer: Timer?
    var settingsWaitTicks = 0
    var loaderMessage = "Getting things ready…"

    override func viewDidLoad() {
        super.viewDidLoad()
       
        lblTitle.stringValue = "Fantastic! We are all set."
        lblSubTitle.stringValue = "You are now ready to become a creature of habit."
        btnContinue.title = "Start using Focus Bear"
        
        // Load localized text
        if let allSetVcInfo = configjson["allSetVcInfo"] as? [String: Any] {
            lblTitle.stringValue = allSetVcInfo["title"] as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = allSetVcInfo["subTitle"] as? String ?? lblSubTitle.stringValue
            btnContinue.title = allSetVcInfo["buttonContinue"] as? String ?? btnContinue.title
            loaderMessage = allSetVcInfo["loaderMessage"] as? String ?? loaderMessage
        }
        
        //progress
        self.customViewProgress.addSubview(getDistractionBlockingProgressVcObj().view)
        self.customViewProgress.addConstraints(subView: getDistractionBlockingProgressVcObj().view)
        getDistractionBlockingProgressVcObj().setCompletedAll()
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "all-set-screen-shown", metadata: [:])
    }
    
    func getDistractionBlockingProgressVcObj()->distractionBlockingProgressVc{
        if distractionBlockingProgressVcObj == nil{
            distractionBlockingProgressVcObj = onboardingStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("distractionBlockingProgressVc")) as? distractionBlockingProgressVc
        }
        return distractionBlockingProgressVcObj!
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] allSetVc:- btnContinueClicked")
        
        // Apply the new-user setting defaults up-front so the app can initialise correctly while we wait.
        mainViewControllerObj?.onboardingFinishedGoAhedForSettings()
        // Don't drop the user into the main window until checkWindowState() has run loadAllWindows()
        // and populated startTime/shutOffTime. Onboarding now lands on the Pomodoro/main view, and
        // jumping to the Day Plan before that init completes crashes getNextRoutineInfo on a nil
        // shutOffTime. Show a loader until isCheckWindowStateDone, then finish (hard cap 100×0.3s ≈ 30s
        // so a slow network can't strand the user — getNextRoutineInfo is also guarded defensively).
        if appdelegate?.isCheckWindowStateDone == true {
            finishOnboarding()
            return
        }
        // Disable the button (title stays "Start using Focus Bear") and show the loader overlay
        // with a caption while we wait for the app to finish initialising.
        btnContinue.isEnabled = false
        getLoaderVcObj().message = loaderMessage
        mainViewControllerObj?.showLoaderView()
        settingsWaitTicks = 0
        settingsWaitTimer?.invalidate()
        settingsWaitTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.settingsWaitTicks += 1
            if appdelegate?.isCheckWindowStateDone == true || self.settingsWaitTicks >= 100 {
                timer.invalidate()
                self.settingsWaitTimer = nil
                self.finishOnboarding()
            }
        }
    }

    func finishOnboarding() {
        settingsWaitTimer?.invalidate()
        settingsWaitTimer = nil
        mainViewControllerObj?.hideLoaderView()
        getLoaderVcObj().message = "" // reset so other plain showLoaderView() callers don't inherit it
        btnContinue.isEnabled = true
        getOnboardingVcObject().onboardingFinished()
    }
}
