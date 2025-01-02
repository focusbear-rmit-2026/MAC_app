//
//  timeTrackerVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 17/11/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class timeTrackerVc: NSViewController {

    @IBOutlet weak var btnCancel: underLineButton!
    @IBOutlet weak var btnEnable: Button!
    @IBOutlet weak var lblPointFourth: NSTextField!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var showingAutomatically = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Introducing Focus Bear Time Tracker"
        lblSubTitle.stringValue = "Focus Bear Time Tracker helps you analyse your productivity by tracking how much time you spend on different websites and apps. You can automatically categorise time logs into different projects (helpful for timesheets)."
      
        lblPointFirst.stringValue = "Privacy first: data is stored locally on your Mac"
        lblPointSecond.stringValue = "Assign time logs to different projects (helpful for timesheets)"
        lblPointThird.stringValue = "Discover where you're wasting time (you can block it with Focus Bear 😉)"
        lblPointFourth.stringValue = "Track time on meetings and when you're away from your Mac"
        
        btnEnable.title = "Enable Focus Bear Time Tracker"
        btnCancel.title = "No thanks"
        
        
        if let timeTrackerVcInfo = configjson.value(forKey: "timeTrackerVcInfo") as? NSDictionary{
            lblTitle.stringValue = timeTrackerVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = timeTrackerVcInfo.value(forKey: "description") as? String ?? lblSubTitle.stringValue
            lblPointFirst.stringValue = timeTrackerVcInfo.value(forKey: "pointFirstText") as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = timeTrackerVcInfo.value(forKey: "pointSecondText") as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = timeTrackerVcInfo.value(forKey: "pointThirdText") as? String ?? lblPointThird.stringValue
            lblPointFourth.stringValue = timeTrackerVcInfo.value(forKey: "pointFourthText") as? String ?? lblPointFourth.stringValue
            btnEnable.title = timeTrackerVcInfo.value(forKey: "buttonEnableText") as? String ?? btnEnable.title
            btnCancel.title = timeTrackerVcInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
        }
        
    }
    
    override func viewWillAppear() {
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app"){
            btnEnable.title = "Enable Focus Bear Time Tracker"
            if let timeTrackerVcInfo = configjson.value(forKey: "timeTrackerVcInfo") as? NSDictionary{
                btnEnable.title = timeTrackerVcInfo.value(forKey: "buttonEnableText") as? String ?? btnEnable.title
            }
        }else{
            btnEnable.title = "Download Focus Bear Time Tracker"
            if let timeTrackerVcInfo = configjson.value(forKey: "timeTrackerVcInfo") as? NSDictionary{
                btnEnable.title = timeTrackerVcInfo.value(forKey: "buttonDownloadText") as? String ?? btnEnable.title
            }
        }
    }
    @IBAction func btnEnableClicked(_ sender: Any) {
        if FileManager.default.fileExists(atPath: "/Applications/Focus Bear Time Tracker.app"){
            enableTimeTracker()
            if !showingAutomatically{
                addOnsVcObj?.timeTrackerEnabledItemVcObj?.btnSwitch.state = .on
            }
        }else{
            if let url = URL(string: "https://downloads.focusbear.io/fbtt/FocusBearTimeTracker.dmg"){
                NSWorkspace.shared.open(url)
            }
        }
        self.view.window?.close()
    }
    //https://www.focusbear.io/#
    @IBAction func btnCancelClicked(_ sender: Any) {
        if showingAutomatically{
            let alert = NSAlert()
            alert.setSharingType()
            alert.alertStyle = .informational
            alert.messageText = "You can always enable Focus Bear Time Tracker from Focus Bear prefrences later."
            if let timeTrackerVcInfo = configjson.value(forKey: "timeTrackerVcInfo") as? NSDictionary{
                alert.messageText = timeTrackerVcInfo.value(forKey: "alertInfoText") as? String ?? alert.messageText
            }
            
            alert.addButton(withTitle: buttonOkText)
            
            alert.beginSheetModal(for: self.view.window!, completionHandler: { (modalResponse) in
                if(modalResponse == NSApplication.ModalResponse.alertFirstButtonReturn){
                }
                
                self.view.window?.close()
            })
        }else{
            self.view.window?.close()
        }
    }
}
