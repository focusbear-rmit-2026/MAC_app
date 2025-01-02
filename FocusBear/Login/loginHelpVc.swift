//
//  loginHelpVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 29/09/22.
//  Copyright © 2022 Focus Bear. All rights reserved.
//

import Cocoa

class loginHelpVc: NSViewController {//not in use 

    @IBOutlet weak var btnClickHere: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        lblTitle.stringValue = "An incognito window should open where you can Login or Register. If you don't see it, please try opening Safari manually. If you still can't see it"
        btnClickHere.title = "Click Here"
        
        if let loginHelpVcInfo = configjson.value(forKey: "loginHelpVcInfo") as? NSDictionary{
            lblTitle.stringValue = loginHelpVcInfo.value(forKey: "title") as? String ?? lblTitle.stringValue
            btnClickHere.title = loginHelpVcInfo.value(forKey: "buttonClickHereText") as? String ?? btnClickHere.title
        }
        
        
    }
}
