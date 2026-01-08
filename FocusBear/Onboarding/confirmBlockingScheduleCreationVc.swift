//
//  confirmBlockingScheduleCreationVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 06/01/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class confirmBlockingScheduleCreationVc: NSViewController {

    @IBOutlet weak var btnYes: Button!
    @IBOutlet weak var btnNo: Button!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Do you want to set up scheduled distraction blocking?"
        lblSubTitle.stringValue = "You can have distracting sites and apps blocked during work hours/at night"
        btnNo.title = "No thanks"
        btnYes.title = "Yes! Save my focus"
        
        
        if let confirmBlockingScheduleCreationVcInfo =
            configjson.value(forKey: "confirmBlockingScheduleCreationVcInfo") as? NSDictionary {

            lblTitle.stringValue =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "title") as? String
                ?? lblTitle.stringValue

            lblSubTitle.stringValue =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "subTitle") as? String
                ?? lblSubTitle.stringValue

            btnNo.title =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "buttonNo") as? String
                ?? btnNo.title

            btnYes.title =
            confirmBlockingScheduleCreationVcInfo.value(forKey: "buttonYes") as? String
                ?? btnYes.title
        }

        
        btnNo.buttonColor = NSColor.white.cgColor
    }
    
    @IBAction func btnNoClicked(_ sender: Any) {
        getHabitsVcObject().breathingFinishedUnlockMachine()
        // delete blockinmg schedule
        appdelegate?.menuShowSimplePomodoroModeView()
        mainWindowControllerObj?.window?.center()
    }
    
    @IBAction func btnYesClicked(_ sender: Any) {
        getHabitsVcObject().breathingFinishedUnlockMachine()
        // move to blocking schdeule
        if mainWindowControllerObj?.window?.isVisible ?? false{
            leftMenuVcObj?.showBlocksView()
            mainWindowControllerObj?.window?.center()
        }else{
            mainWindowControllerObj?.showWindow(self)
            leftMenuVcObj?.showBlocksView()
            mainWindowControllerObj?.window?.center()
        }
        addLog(text: "Showing preferences")
        tabStrictnessContainerVcObj?.showCustomBlockingSchedulesView()
    }
}
