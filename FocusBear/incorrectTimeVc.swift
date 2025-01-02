//
//  incorrectTimeVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 19/10/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class incorrectTimeVc: NSViewController {

    @IBOutlet weak var btnInstructions: underLineButton!
    @IBOutlet weak var btnIAmReady: cursorButton!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        btnIAmReady.title = "I am ready to start my habits"
//        btnInstructions.titleColor = NSColor.systemBlue
        btnInstructions.title = "Click Here to see instructions for fixing your time settings"
        
        if let common = configjson.value(forKey: "common") as? NSDictionary{
            btnIAmReady.title = common.value(forKey: "buttonIAmReadyText") as? String ?? btnIAmReady.title
            btnInstructions.title = common.value(forKey: "buttonInstructionsText") as? String ?? btnInstructions.title
        }
        
    }
    
    @IBAction func btnIAmReadyClicked(_ sender: Any) {
        addLog(text: "[user-action] incorrectTimeVc:- btnIAmReadyClicked")
        self.view.window?.close()
        NSApplication.shared.stopModal()
    }
    var timerCheckTime:Timer?
    override func viewWillAppear() {
        btnIAmReady.keyEquivalent = "\r"
       // DispatchQueue.global().sync {//async {
            self.timerCheckTime = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.checkTime), userInfo: nil, repeats: true)
            RunLoop.main.add((self.timerCheckTime!), forMode: RunLoop.Mode.common)
        //}
    }
    override func viewWillDisappear() {
        self.timerCheckTime?.invalidate()
        self.timerCheckTime = nil
    }
    @objc func checkTime(){
        if let now = appdelegate!.client.referenceTime?.now(){
            print(now)
            let currentDate = Date()
            let diffHours = Calendar.current.dateComponents([.hour], from: now, to: currentDate).hour ?? 0
            if diffHours > 24 || diffHours < -24{

            }else{
              //  DispatchQueue.main.async {
                    self.view.window?.close()
                    NSApplication.shared.stopModal()
                    self.timerCheckTime?.invalidate()
                    self.timerCheckTime = nil
                //}
            }
        }
    }
    @IBAction func btnInstructionsClicked(_ sender: Any) {
        addLog(text: "[user-action] incorrectTimeVc:- btnInstructionsClicked")
        if let url = URL(string: "https://support.apple.com/en-in/guide/mac-help/mchlp2996/mac"){
            NSWorkspace.shared.open(url)
        }
    }
}
