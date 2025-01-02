//
//  selectHabitsLaterInfoVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 05/03/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class selectHabitsLaterInfoVc: NSViewController {

    @IBOutlet weak var btnContinue: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = appName
        
        lblSubTitle.stringValue = "If you ever decide you want to activate habits in the future, you can open Preferences from the menu bar and click Edit Habits"
        btnContinue.title = "Continue"
        if let selectHabitsLaterInfo = configjson.value(forKey: "selectHabitsLaterInfo") as? NSDictionary{
            lblSubTitle.stringValue = selectHabitsLaterInfo.value(forKey: "title") as? String ?? lblSubTitle.stringValue
            btnContinue.title = selectHabitsLaterInfo.value(forKey: "buttonContinueText") as? String ?? btnContinue.title
        }
            
        allApiObject.capturePosthog(event: "set-habits-later-info-screen-shown", metadata: [:])
    }
    
    override func viewDidAppear() {
        showOnboardingProgress(view: self.view, progress: 10)
        showOnboardingBellIcon(view: self.view, screen: "set-habits-later-info-screen")
    }
    override func viewWillDisappear() {
        hideOnboardingProgress(view: self.view)
        hideOnboardingBellIcon(view: self.view)
    }
    @IBAction func btnContinueClicked(_ sender: Any) {
        mainViewControllerObj!.abortOboardingWorkTime()
    }
    
}
