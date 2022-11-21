//
//  customNotificationVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 21/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class customNotificationVc: NSViewController {

    @IBOutlet weak var bgBox: customBoxBg!
    @IBOutlet weak var lblTitle: NSTextField!
    
    var timer:Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        bgBox.wantsLayer = true
        bgBox.cornerRadius = bgBox.frame.height / 5
    }
    
    func resetView(msg:String){
        lblTitle.stringValue = msg
        if timer != nil{
            timer?.invalidate()
            timer = nil
        }
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(closeWindow), userInfo: nil, repeats: false)
    }
    
    @objc func closeWindow(){
        self.view.window?.close()
    }
}
