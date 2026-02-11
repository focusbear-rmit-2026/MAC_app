//
//  messageBoxVc.swift
//  Focus Bear
//
//  Created by Manish Jain on 05/02/26.
//  Copyright © 2026 Focus Bear. All rights reserved.
//

import Cocoa

class messageBoxVc: NSViewController {

    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "Continue in your browser"
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "continueInBrowser") as? String ?? lblTitle.stringValue
        }
    }
    
}
