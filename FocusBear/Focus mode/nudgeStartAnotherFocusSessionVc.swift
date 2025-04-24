//
//  nudgeStartAnotherFocusSessionVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 18/04/25.
//  Copyright © 2025 Focus Bear. All rights reserved.
//

import Cocoa

class nudgeStartAnotherFocusSessionVc: NSViewController {

    @IBOutlet weak var mainBgView: NSView!
    @IBOutlet weak var boxMessage: NSBox!
    @IBOutlet weak var boxCircle: NSBox!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var btnCancel: cursorButton!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Want to start another focus session?"
        btnOk.title = "Start a Focus Fiesta"
        if let nudgeStartAnotherFocusSessionVcInfo = configjson.value(forKey: "nudgeStartAnotherFocusSessionVcInfo") as? NSDictionary{
            lblTitle.stringValue = nudgeStartAnotherFocusSessionVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnOk.title = nudgeStartAnotherFocusSessionVcInfo.value(forKey: "buttonStartFocusText") as? String ?? btnOk.title
        }
    }

    
    @IBAction func btnCancelClicked(_ sender: Any) {
        if endingFocusWindowControllerObj != nil{
            if endingFocusWindowControllerObj?.window?.isVisible ?? false{
                addLog(text: "focus mode completed Window close")
                focusCompletedVcObj!.btnTakeBreakClicked(self)
            }
        }
        self.view.window?.close()
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        if endingFocusWindowControllerObj != nil{
            if endingFocusWindowControllerObj?.window?.isVisible ?? false{
                addLog(text: "focus mode completed Window close")
                focusCompletedVcObj!.btnStartAnotherFocusBlockClicked(self)
            }
        }
        self.view.window?.close()
    }
}
