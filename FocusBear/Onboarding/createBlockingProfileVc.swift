//
//  createBlockingProfileVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 02/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class createBlockingProfileVc: NSViewController {

    @IBOutlet weak var lblExampleSecond: NSTextField!
    @IBOutlet weak var lblExampleFirst: NSTextField!
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
        lblTitle.stringValue = "Create your distraction blocking profile"
        lblSubTitle.stringValue = "Give the AI a little more context so it’s better at detecting distractions"
        lblHeadingFirst.stringValue = "What type of sites are relevant for your work?"
        lblExampleFirst.stringValue = "(Eg. Project management tools, Code repositories)"
        lblHeadingSecond.stringValue = "What type of things are distracting?"
        lblExampleSecond.stringValue = "(Eg. Social media, Video streaming)"
        btnContinue.title = buttonContinueText
        
        
        if let createBlockingProfileVcInfo =
            configjson.value(forKey: "createBlockingProfileVcInfo") as? NSDictionary {

            lblTitle.stringValue =
                createBlockingProfileVcInfo.value(forKey: "title") as? String
                ?? lblTitle.stringValue

            lblSubTitle.stringValue =
                createBlockingProfileVcInfo.value(forKey: "subTitle") as? String
                ?? lblSubTitle.stringValue

            lblHeadingFirst.stringValue =
                createBlockingProfileVcInfo.value(forKey: "headingFirst") as? String
                ?? lblHeadingFirst.stringValue

            lblExampleFirst.stringValue =
                createBlockingProfileVcInfo.value(forKey: "exampleFirst") as? String
                ?? lblExampleFirst.stringValue

            lblHeadingSecond.stringValue =
                createBlockingProfileVcInfo.value(forKey: "headingSecond") as? String
                ?? lblHeadingSecond.stringValue

            lblExampleSecond.stringValue =
                createBlockingProfileVcInfo.value(forKey: "exampleSecond") as? String
                ?? lblExampleSecond.stringValue
        }

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

