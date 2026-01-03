//
//  createBlockingProfileVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 02/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class createBlockingProfileVc: NSViewController {
// todo text
    @IBOutlet weak var btnContinue: Button!
    @IBOutlet var textViewSecond: NSTextView!
    @IBOutlet weak var lblHeadingSecond: NSTextField!
    @IBOutlet var textViewFirst: NSTextView!
    @IBOutlet weak var lblHeadingFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear() {
        allApiObject.capturePosthog(event: "create-blocking-profile-screen-shown", metadata: [:])
    }
    
    @IBAction func btnContinueClicked(_ sender: Any) {
        addLog(text: "[user-action] create blocking profile view:- button Continue clicked.")
        allApiObject.capturePosthog(event: "blocking-profile-created", metadata: [:])
        if !getInstallHabitPacksVcObj().isViewLoaded{
            getInstallHabitPacksVcObj().loadView()
        }
        mainViewControllerObj?.showAskAppWorkVc()
        UserDefaults.standard.set(textViewFirst.string, forKey: kUserDefaultsUserJobDetails)
        UserDefaults.standard.set(textViewSecond.string, forKey: kUserDefaultsUserDistractions)
    }
}

