//
//  loginComingSoonMsgVc.swift
//  Focus Bear
//
//  Created by Prashant Sawnani on 07/08/23.
//  Copyright © 2023 Focus Bear. All rights reserved.
//

import Cocoa

class loginComingSoonMsgVc: NSViewController {

    @IBOutlet weak var btnInfo: hoverInfoButton!
    @IBOutlet weak var btnOk: Button!
    @IBOutlet weak var lblTitle: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblTitle.stringValue = "Coming Soon - for now register again with a password to link your existing account."
        btnOk.title = buttonOkText
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            lblTitle.stringValue = askLogInVcInfo.value(forKey: "loginComingSoonTitle") as? String ?? lblTitle.stringValue
        }
    }
    
    @IBAction func btnOkClicked(_ sender: Any) {
        self.dismiss(self)
    }
    
    @IBAction func btnInfoClicked(_ sender: Any) {
        var msg = "We don't have support for single sign on yet on desktop. If you've already registered for an account via Google/Apple on mobile, you'll need to register again with an email and password and it will link to the existing account you have."
        if let askLogInVcInfo = configjson.value(forKey: "askLogInVcInfo") as? NSDictionary{
            msg = askLogInVcInfo.value(forKey: "loginComingSoonDescription") as? String ?? msg
        }
        showTooltip(sender: btnInfo, msg: msg, preferredEdge: NSRectEdge.maxX, maxWidthVal:230)
    }
}
