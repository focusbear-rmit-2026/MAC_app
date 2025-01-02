//
//  pomodoroTooltipVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 06/01/24.
//  Copyright © 2024 Focus Bear. All rights reserved.
//

import Cocoa

class pomodoroTooltipVc: NSViewController {

    @IBOutlet weak var btnLearnMore: underLineButton!
    @IBOutlet weak var lblMsg: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        btnLearnMore.titleColor = NSColor.systemBlue
        lblMsg.stringValue = "Pomodoro mode is a productivity technique where you focus intensely (normally for 25 minutes) and then take a break (normally for 5 minutes)."
        btnLearnMore.title = "Learn more"
        if let pomodoroInfo = configjson.value(forKey: "pomodoroInfo") as? NSDictionary{
            lblMsg.stringValue = pomodoroInfo.value(forKey: "pomodoroTooltipText") as? String ?? lblMsg.stringValue
            btnLearnMore.title = pomodoroInfo.value(forKey: "buttonLearnMoreText") as? String ?? btnLearnMore.title
        }
        
    }
    
    @IBAction func btnLearnMoreClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/blog-post/studying-on-tomato-oclock-a-students-guide-to-using-the-pomodoro-technique-efficiently"){
            NSWorkspace.shared.open(url)
        }
    }
}
