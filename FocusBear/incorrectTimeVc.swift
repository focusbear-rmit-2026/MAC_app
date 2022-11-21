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
        addLog(text: "incorrectTimeVc:- btnIAmReadyClicked")
        self.view.window?.close()
        NSApplication.shared.stopModal()
    }
    override func viewWillAppear() {
        btnIAmReady.keyEquivalent = "\r"
    }
    @IBAction func btnInstructionsClicked(_ sender: Any) {
        addLog(text: "incorrectTimeVc:- btnInstructionsClicked")
        if let url = URL(string: "https://support.apple.com/en-in/guide/mac-help/mchlp2996/mac"){
            NSWorkspace.shared.open(url)
        }
    }
}
