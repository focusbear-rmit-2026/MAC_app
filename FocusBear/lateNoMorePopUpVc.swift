//
//  lateNoMorePopUpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 20/12/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class lateNoMorePopUpVc: NSViewController {
    
    @IBOutlet weak var btnCancel: underLineButton!
    @IBOutlet weak var btnEnable: Button!
    @IBOutlet weak var lblPointFourth: NSTextField!
    @IBOutlet weak var lblPointThird: NSTextField!
    @IBOutlet weak var lblPointSecond: NSTextField!
    @IBOutlet weak var lblPointFirst: NSTextField!
    @IBOutlet weak var lblSubTitle: NSTextField!
    @IBOutlet weak var lblTitle: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Introducing Late No More."
        lblSubTitle.stringValue = "Download Late No More, our ADHD friendly calendar notification app. Being late sucks. Most calendar apps don't give notifications that stand out to ADHD brains. Late No More gives notifications that escalate in intensity as it gets closer to the start time. If you ignore the popups, you'll get verbal alerts (or a song)."
      
        lblPointFirst.stringValue = "Privacy first: data is stored locally on your Mac"
        lblPointSecond.stringValue = "Notifications starting 2 minutes before the appointment"
        lblPointThird.stringValue = "Progressively more obnoxious alerts the closer it gets to the meeting start time"
        lblPointFourth.stringValue = "Verbal alerts (or play Spotify song) once you're late"
        
        btnEnable.title = "Get Late No More"
        btnCancel.title = "No thanks"
        
        
        if let lateNoMorePopUpVcInfo = configjson.value(forKey: "lateNoMorePopUpVcInfo") as? NSDictionary{
            lblTitle.stringValue = lateNoMorePopUpVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            lblSubTitle.stringValue = lateNoMorePopUpVcInfo.value(forKey: "description") as? String ?? lblSubTitle.stringValue
            lblPointFirst.stringValue = lateNoMorePopUpVcInfo.value(forKey: "pointFirstText") as? String ?? lblPointFirst.stringValue
            lblPointSecond.stringValue = lateNoMorePopUpVcInfo.value(forKey: "pointSecondText") as? String ?? lblPointSecond.stringValue
            lblPointThird.stringValue = lateNoMorePopUpVcInfo.value(forKey: "pointThirdText") as? String ?? lblPointThird.stringValue
            lblPointFourth.stringValue = lateNoMorePopUpVcInfo.value(forKey: "pointFourthText") as? String ?? lblPointFourth.stringValue
            btnEnable.title = lateNoMorePopUpVcInfo.value(forKey: "buttonEnableText") as? String ?? btnEnable.title
            btnCancel.title = lateNoMorePopUpVcInfo.value(forKey: "buttonCancelText") as? String ?? btnCancel.title
        }
        
    }
    @IBAction func btnEnableClicked(_ sender: Any) {
        if let url = URL(string: "https://www.focusbear.io/late-no-more"){
            NSWorkspace.shared.open(url)
        }
        self.view.window?.close()
    }
    
    @IBAction func btnCancelClicked(_ sender: Any) {
        self.view.window?.close()
    }
}

